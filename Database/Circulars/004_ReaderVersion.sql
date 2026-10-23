-- Optional reader version prevents a modal from pairing old metadata with a newer PDF.
-- Existing mobile/legacy callers omit it; receipts and audit remain unchanged.
CREATE OR ALTER PROCEDURE dbo.Customer_CircularFile @AccountID int,@Stamp uniqueidentifier,@ID int,@Action varchar(16),@EventID uniqueidentifier,@ExpectedVersion int=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Action NOT IN('view','download') OR @Action IS NULL OR @EventID IS NULL THROW 51800,'Invalid event.',1;
 BEGIN TRY BEGIN TRANSACTION; EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Version int,@Title nvarchar(250),@Allow bit;
 SELECT @Version=Version,@Title=Title,@Allow=AllowDownload FROM dbo.Circulars WITH(HOLDLOCK) WHERE ID=@ID;
 IF @Version IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) WHERE ID=@ID) THROW 51804,'Circular unavailable.',1;
 IF @ExpectedVersion IS NOT NULL AND (@ExpectedVersion<1 OR @ExpectedVersion<>@Version) THROW 51809,'Circular changed. Reopen before reading.',1;
 IF @Action='download' AND @Allow=0 THROW 51803,'Download denied.',1;
 IF EXISTS(SELECT 1 FROM dbo.Circular_CustomerLogs WHERE AccountID=@AccountID AND EventID=@EventID AND (CircularID<>@ID OR Version<>@Version OR Action<>@Action)) THROW 51809,'Event conflict.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerLogs WHERE AccountID=@AccountID AND EventID=@EventID)
 BEGIN
  INSERT dbo.Circular_CustomerLogs(CircularID,Version,AccountID,ActorName,TitleSnapshot,Action,EventID) SELECT @ID,@Version,@AccountID,Name_AR,@Title,@Action,@EventID FROM dbo.CRM_Accounts WHERE ID=@AccountID;
  UPDATE dbo.Circular_CustomerReads SET LastReadUtc=SYSUTCDATETIME() WHERE CircularID=@ID AND Version=@Version AND AccountID=@AccountID;
  IF @@ROWCOUNT=0 INSERT dbo.Circular_CustomerReads VALUES(@ID,@Version,@AccountID,SYSUTCDATETIME(),SYSUTCDATETIME());
  INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note) VALUES(@AccountID,'circular-'+@Action,N'Circulars',@ID,CONCAT(N'الإصدار ',@Version));
 END;
 SELECT FileName,FileBytes,@Version Version FROM dbo.Circulars WHERE ID=@ID;
 COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_File @Actor int,@ID int,@Action varchar(16),@Source varchar(10),@EventID uniqueidentifier,
 @OccurredAtUtc datetime2(0)=NULL,@TokenHash binary(32)=NULL,@Admin bit=0,@ExpectedVersion int=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@Version int,@Title nvarchar(250),@Allow bit,@Employee int,@Device nvarchar(128),@App nvarchar(50);
 IF @Action IS NULL OR @Action NOT IN('view','download') OR @Source IS NULL OR @Source NOT IN('Portal','Mobile') OR @EventID IS NULL OR (@Source='Mobile' AND @Admin=1) THROW 51800,'Invalid file event.',1;
 IF @OccurredAtUtc>DATEADD(minute,5,@Now) OR @OccurredAtUtc<DATEADD(day,-30,@Now) THROW 51800,'Invalid event time.',1;
 BEGIN TRY
 BEGIN TRAN;
 SELECT @Employee=Employee_Number FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1);
 IF @@ROWCOUNT=0 THROW 51801,'Access denied.',1;
 IF @Source='Mobile' BEGIN
  SELECT @Device=s.DeviceID,@App=s.AppVersion FROM dbo.MobileApi_Sessions s JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.IsApproved=1
  JOIN dbo.UsersMembers u ON u.ID=s.UserID WHERE s.UserID=@Actor AND s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
  AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password));
  IF @@ROWCOUNT=0 THROW 51801,'Invalid device session.',1;
 END;
 SELECT @Version=Version,@Title=Title,@Allow=AllowDownload FROM dbo.Circulars WITH(HOLDLOCK) WHERE ID=@ID;
 IF @Version IS NULL OR (@Admin=0 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) WHERE ID=@ID)) THROW 51804,'Circular unavailable.',1;
 IF @ExpectedVersion IS NOT NULL AND (@ExpectedVersion<1 OR @ExpectedVersion<>@Version) THROW 51809,'Circular changed. Reopen before reading.',1;
 IF @Action='download' AND @Allow=0 THROW 51803,'Download is not permitted.',1;
 IF @Admin=1 AND @Action='view' SET @Action='preview';
 IF EXISTS(SELECT 1 FROM dbo.Circular_Logs WHERE UserID=@Actor AND EventID=@EventID AND (CircularID<>@ID OR Version<>@Version OR Action<>@Action OR Source<>@Source)) THROW 51809,'EventID already used for another operation.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Circular_Logs WHERE UserID=@Actor AND EventID=@EventID)
 BEGIN
  INSERT dbo.Circular_Logs(CircularID,Version,TitleSnapshot,UserID,EmployeeNumber,Action,Source,EventID,OccurredAtUtc,DeviceID,AppVersion)
  VALUES(@ID,@Version,@Title,@Actor,@Employee,@Action,@Source,@EventID,@OccurredAtUtc,@Device,@App);
  IF @Admin=0 BEGIN
   UPDATE dbo.Circular_Reads SET LastReadUtc=@Now WHERE CircularID=@ID AND Version=@Version AND UserID=@Actor;
   IF @@ROWCOUNT=0 INSERT dbo.Circular_Reads VALUES(@ID,@Version,@Actor,@Now,@Now);
  END;
 END;
 SELECT FileName,FileBytes,@Version Version FROM dbo.Circulars WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
