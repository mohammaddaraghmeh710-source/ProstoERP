-- Additive circular audiences. Existing rows, read receipts and audit IDs are retained.
SET XACT_ABORT ON;
IF COL_LENGTH('dbo.Circulars','BrandID') IS NULL ALTER TABLE dbo.Circulars ADD BrandID int NULL REFERENCES dbo.Brands(ID),Title_EN nvarchar(250) NULL,Summary_EN nvarchar(2000) NULL,HasPeriod bit NOT NULL CONSTRAINT DF_Circular_HasPeriod DEFAULT(1);
IF OBJECT_ID('dbo.Circular_CustomerTargets','U') IS NULL
BEGIN
 CREATE TABLE dbo.Circular_CustomerTargets(CircularID int NOT NULL REFERENCES dbo.Circulars(ID),Kind varchar(16) NOT NULL CHECK(Kind IN('customer','customerType')),TargetID int NOT NULL,PRIMARY KEY(CircularID,Kind,TargetID));
 CREATE TABLE dbo.Circular_CustomerReads(CircularID int NOT NULL REFERENCES dbo.Circulars(ID),Version int NOT NULL,AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),FirstReadUtc datetime2(0) NOT NULL,LastReadUtc datetime2(0) NOT NULL,PRIMARY KEY(CircularID,Version,AccountID));
 CREATE TABLE dbo.Circular_CustomerLogs(ID bigint IDENTITY PRIMARY KEY,CircularID int NOT NULL REFERENCES dbo.Circulars(ID),Version int NOT NULL,AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),ActorName nvarchar(500) NOT NULL,TitleSnapshot nvarchar(250) NOT NULL,Action varchar(16) NOT NULL CHECK(Action IN('view','download')),EventID uniqueidentifier NOT NULL,RecordedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),UNIQUE(AccountID,EventID));
 CREATE TABLE dbo.Circular_Notices(CircularID int NOT NULL REFERENCES dbo.Circulars(ID),Version int NOT NULL,RecipientKind varchar(10) NOT NULL CHECK(RecipientKind IN('employee','customer')),RecipientID int NOT NULL,CreatedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),PRIMARY KEY(CircularID,Version,RecipientKind,RecipientID));
 CREATE TABLE dbo.Circular_Mail(ID bigint IDENTITY PRIMARY KEY,CircularID int NOT NULL,Version int NOT NULL,RecipientKind varchar(10) NOT NULL,RecipientID int NOT NULL,Status varchar(16) NOT NULL DEFAULT 'pending' CHECK(Status IN('pending','sending','submitted','failed','cancelled','unknown')),ClaimedUtc datetime2(0) NULL,CompletedUtc datetime2(0) NULL,ErrorCode varchar(40) NULL,
 FOREIGN KEY(CircularID,Version,RecipientKind,RecipientID) REFERENCES dbo.Circular_Notices(CircularID,Version,RecipientKind,RecipientID),UNIQUE(CircularID,Version,RecipientKind,RecipientID));
 CREATE INDEX IX_Circular_Mail_Status ON dbo.Circular_Mail(Status,ID);
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Circulars') AND name='IX_Circular_BrandPublication') CREATE INDEX IX_Circular_BrandPublication ON dbo.Circulars(BrandID,IsEnabled,StartUtc,EndUtc) INCLUDE(Version,Audience);
GO
-- Expand only the audience enum; no existing row is assigned a guessed brand or translation.
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Circular_Audience') ALTER TABLE dbo.Circulars DROP CONSTRAINT CK_Circular_Audience;
ALTER TABLE dbo.Circulars ADD CONSTRAINT CK_Circular_Audience CHECK(Audience IN('all','roles','organization','customers','customerTypes'));
GO
CREATE OR ALTER FUNCTION dbo.Circular_Visible(@Actor int,@Now datetime2(0))
RETURNS TABLE AS RETURN(
 SELECT c.ID FROM dbo.Circulars c JOIN dbo.UsersMembers u ON u.ID=@Actor
 WHERE u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND c.IsEnabled=1 AND c.StartUtc<=@Now AND @Now<c.EndUtc
 AND (c.BrandID IS NULL OR (u.Brand_ID=c.BrandID AND EXISTS(SELECT 1 FROM dbo.Brands b WHERE b.ID=c.BrandID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0)))
 AND (c.Audience='all' OR (c.Audience='roles' AND EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind='role' AND t.TargetID=u.Type))
 OR (c.Audience='organization' AND NOT EXISTS(
 SELECT 1 FROM (VALUES('brand',u.Brand_ID),('branch',u.Branch_ID),('department',u.Department_ID),('shift',u.Shif_ID)) v(Kind,Value)
 WHERE EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind=v.Kind)
 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind=v.Kind AND t.TargetID=v.Value))))
);
GO

CREATE OR ALTER FUNCTION dbo.Circular_CustomerVisible(@AccountID int,@Now datetime2(0)) RETURNS TABLE AS RETURN(
 SELECT c.ID FROM dbo.Circulars c JOIN dbo.CRM_Accounts a ON a.ID=@AccountID AND a.Is_Active=1 AND a.Is_Deleted=0
 JOIN dbo.Customer_Logins l ON l.AccountID=a.ID AND l.IsActive=1 JOIN dbo.Brands b ON b.ID=a.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 WHERE c.BrandID=a.Brand_ID AND c.IsEnabled=1 AND c.StartUtc<=@Now AND @Now<c.EndUtc
 AND ((c.Audience='customers' AND EXISTS(SELECT 1 FROM dbo.Circular_CustomerTargets t WHERE t.CircularID=c.ID AND t.Kind='customer' AND t.TargetID=a.ID))
 OR (c.Audience='customerTypes' AND EXISTS(SELECT 1 FROM dbo.Circular_CustomerTargets t JOIN dbo.CRM_Account_Types ct ON ct.ID=t.TargetID AND ct.Is_Active=1 AND ct.Is_Deleted=0 WHERE t.CircularID=c.ID AND t.Kind='customerType' AND t.TargetID=a.Account_Type_ID))))
;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_AdminSave @Actor int,@ID int=0,@ExpectedVersion int=0,@BrandID int,@Title nvarchar(250),@Title_EN nvarchar(250),@Summary nvarchar(2000),@Summary_EN nvarchar(2000),@CircularDate date,@HasPeriod bit,@StartUtc datetime2(0)=NULL,@EndUtc datetime2(0)=NULL,@IsEnabled bit,@AllowDownload bit,@Audience varchar(16),@Targets xml,@FileName nvarchar(250)=NULL,@FileBytes varbinary(max)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @BrandID IS NULL OR @HasPeriod IS NULL OR @IsEnabled IS NULL OR @AllowDownload IS NULL OR NULLIF(LTRIM(RTRIM(@Title_EN)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Summary_EN)),N'') IS NULL OR @Audience NOT IN('all','roles','organization','customers','customerTypes') OR @Audience IS NULL THROW 51800,'Invalid circular fields.',1;
 IF @HasPeriod=1 AND (@StartUtc IS NULL OR @EndUtc IS NULL OR @EndUtc<=@StartUtc) THROW 51800,'A start and end are required.',1;
 IF @HasPeriod=0 SELECT @StartUtc=CONVERT(datetime2(0),'19000101'),@EndUtc=CONVERT(datetime2(0),'99991231');
 DECLARE @Selected TABLE(Kind varchar(16),TargetID int,PRIMARY KEY(Kind,TargetID));
 INSERT @Selected SELECT DISTINCT n.value('@kind','varchar(16)'),n.value('@id','int') FROM @Targets.nodes('/targets/item') x(n);
 IF EXISTS(SELECT 1 FROM @Selected WHERE (@Audience='all') OR (@Audience='roles' AND Kind<>'role') OR (@Audience='organization' AND Kind NOT IN('branch','department','shift')) OR (@Audience='customers' AND Kind<>'customer') OR (@Audience='customerTypes' AND Kind<>'customerType')) OR (@Audience<>'all' AND NOT EXISTS(SELECT 1 FROM @Selected)) THROW 51800,'Choose the required audience.',1;
 BEGIN TRY BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51800,'Select an active brand.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='branch' AND NOT EXISTS(SELECT 1 FROM dbo.Branches WITH(HOLDLOCK) WHERE ID=t.TargetID AND BrandID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) THROW 51800,'Cross-brand branch.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='customer' AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(HOLDLOCK) WHERE ID=t.TargetID AND Brand_ID=@BrandID AND Is_Active=1 AND Is_Deleted=0)) THROW 51800,'Cross-brand customer.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='customerType' AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WITH(HOLDLOCK) WHERE ID=t.TargetID AND Is_Active=1 AND Is_Deleted=0)) THROW 51800,'Invalid customer type.',1;
 IF NULLIF(LTRIM(RTRIM(@Title)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Summary)),N'') IS NULL OR @CircularDate IS NULL OR @ExpectedVersion IS NULL OR @ID IS NULL OR @ID<0 THROW 51800,'Invalid circular fields.',1;
 IF (@ID=0 AND @FileBytes IS NULL) OR (@FileBytes IS NULL AND @FileName IS NOT NULL) OR (@FileBytes IS NOT NULL AND (@FileName IS NULL OR DATALENGTH(@FileBytes) NOT BETWEEN 8 AND 10485760 OR SUBSTRING(@FileBytes,1,5)<>0x255044462D OR LOWER(RIGHT(@FileName,4))<>'.pdf')) THROW 51800,'A PDF up to 10MB is required.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE (t.Kind='role' AND NOT EXISTS(SELECT 1 FROM dbo.Users_Types WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) OR (t.Kind='department' AND NOT EXISTS(SELECT 1 FROM dbo.Departments WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) OR (t.Kind='shift' AND NOT EXISTS(SELECT 1 FROM dbo.Shift WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0))) THROW 51800,'Inactive audience target.',1;
 DECLARE @Version int,@Now datetime2(0)=SYSUTCDATETIME();
 IF @ID=0 BEGIN
  INSERT dbo.Circulars(Title,Summary,CircularDate,StartUtc,EndUtc,IsEnabled,AllowDownload,Audience,FileName,FileBytes,CreatedBy,ModifiedBy,BrandID,Title_EN,Summary_EN,HasPeriod)
  VALUES(@Title,@Summary,@CircularDate,@StartUtc,@EndUtc,@IsEnabled,@AllowDownload,@Audience,@FileName,@FileBytes,@Actor,@Actor,@BrandID,@Title_EN,@Summary_EN,@HasPeriod);
  SELECT @ID=SCOPE_IDENTITY(),@Version=1;
 END ELSE BEGIN
  SELECT @Version=Version FROM dbo.Circulars WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID;
  IF @Version IS NULL THROW 51804,'Circular unavailable.',1;
  IF @Version<>@ExpectedVersion THROW 51809,'Circular changed. Reload before saving.',1;
  SET @Version=@Version+1;
  UPDATE dbo.Circulars SET BrandID=@BrandID,Title=@Title,Title_EN=@Title_EN,Summary=@Summary,Summary_EN=@Summary_EN,CircularDate=@CircularDate,HasPeriod=@HasPeriod,StartUtc=@StartUtc,EndUtc=@EndUtc,IsEnabled=@IsEnabled,AllowDownload=@AllowDownload,Audience=@Audience,
   FileName=COALESCE(@FileName,FileName),FileBytes=COALESCE(@FileBytes,FileBytes),Version=@Version,ModifiedBy=@Actor,ModifiedUtc=@Now WHERE ID=@ID;
 END;
 DELETE dbo.Circular_Targets WHERE CircularID=@ID;
 INSERT dbo.Circular_Targets SELECT @ID,Kind,TargetID FROM @Selected WHERE Kind IN('role','branch','department','shift');
 IF @Audience='organization' INSERT dbo.Circular_Targets VALUES(@ID,'brand',@BrandID);
 DELETE dbo.Circular_CustomerTargets WHERE CircularID=@ID;
 INSERT dbo.Circular_CustomerTargets SELECT @ID,Kind,TargetID FROM @Selected WHERE Kind IN('customer','customerType');
 INSERT dbo.Circular_Logs(CircularID,Version,TitleSnapshot,UserID,EmployeeNumber,Action,Source,EventID)
 SELECT @ID,@Version,@Title,@Actor,Employee_Number,CASE WHEN @Version=1 THEN 'create' ELSE 'update' END,'Portal',NEWID() FROM dbo.UsersMembers WHERE ID=@Actor;
 UPDATE dbo.Circular_Mail SET Status='cancelled',CompletedUtc=@Now,ErrorCode='SUPERSEDED' WHERE CircularID=@ID AND Status='pending';
 SELECT @ID ID,@Version Version;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_Circulars @AccountID int,@Stamp uniqueidentifier,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION; EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 IF @ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) WHERE ID=@ID) THROW 51804,'Circular unavailable.',1;
 SELECT c.ID,c.Title,c.Title_EN,c.Summary,c.Summary_EN,c.CircularDate,c.HasPeriod,c.StartUtc,c.EndUtc,c.AllowDownload,c.FileName,c.Version,CAST(CASE WHEN r.AccountID IS NULL THEN 0 ELSE 1 END AS bit) IsRead
 FROM dbo.Circulars c JOIN dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) v ON v.ID=c.ID LEFT JOIN dbo.Circular_CustomerReads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.AccountID=@AccountID WHERE @ID IS NULL OR c.ID=@ID ORDER BY c.CircularDate DESC,c.ID DESC;
 COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_CircularFile @AccountID int,@Stamp uniqueidentifier,@ID int,@Action varchar(16),@EventID uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Action NOT IN('view','download') OR @Action IS NULL OR @EventID IS NULL THROW 51800,'Invalid event.',1;
 BEGIN TRY BEGIN TRANSACTION; EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Version int,@Title nvarchar(250),@Allow bit;
 SELECT @Version=Version,@Title=Title,@Allow=AllowDownload FROM dbo.Circulars WITH(HOLDLOCK) WHERE ID=@ID;
 IF @Version IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) WHERE ID=@ID) THROW 51804,'Circular unavailable.',1;
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
CREATE OR ALTER VIEW dbo.Circular_CurrentRecipients AS
 SELECT c.ID CircularID,c.Version,'employee' RecipientKind,u.ID RecipientID,u.Email,c.BrandID FROM dbo.Circulars c CROSS JOIN dbo.UsersMembers u CROSS APPLY dbo.Circular_Visible(u.ID,SYSUTCDATETIME()) v WHERE v.ID=c.ID AND c.BrandID IS NOT NULL
 UNION ALL
 SELECT c.ID,c.Version,'customer',a.ID,a.Email,c.BrandID FROM dbo.Circulars c CROSS JOIN dbo.CRM_Accounts a CROSS APPLY dbo.Circular_CustomerVisible(a.ID,SYSUTCDATETIME()) v WHERE v.ID=c.ID;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_Dispatch AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource='Circular_Dispatch',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=0;
 IF @Lock<0 BEGIN ROLLBACK;RETURN;END;
 INSERT dbo.Circular_Notices(CircularID,Version,RecipientKind,RecipientID) SELECT r.CircularID,r.Version,r.RecipientKind,r.RecipientID FROM dbo.Circular_CurrentRecipients r WHERE NOT EXISTS(SELECT 1 FROM dbo.Circular_Notices n WHERE n.CircularID=r.CircularID AND n.Version=r.Version AND n.RecipientKind=r.RecipientKind AND n.RecipientID=r.RecipientID);
 INSERT dbo.Circular_Mail(CircularID,Version,RecipientKind,RecipientID) SELECT n.CircularID,n.Version,n.RecipientKind,n.RecipientID FROM dbo.Circular_Notices n WHERE EXISTS(SELECT 1 FROM dbo.Circular_CurrentRecipients r WHERE r.CircularID=n.CircularID AND r.Version=n.Version AND r.RecipientKind=n.RecipientKind AND r.RecipientID=n.RecipientID) AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Mail m WHERE m.CircularID=n.CircularID AND m.Version=n.Version AND m.RecipientKind=n.RecipientKind AND m.RecipientID=n.RecipientID);
 UPDATE dbo.Circular_Mail SET Status='cancelled',CompletedUtc=SYSUTCDATETIME(),ErrorCode='UNAVAILABLE' WHERE Status='pending' AND NOT EXISTS(SELECT 1 FROM dbo.Circular_CurrentRecipients r WHERE r.CircularID=Circular_Mail.CircularID AND r.Version=Circular_Mail.Version AND r.RecipientKind=Circular_Mail.RecipientKind AND r.RecipientID=Circular_Mail.RecipientID);
 UPDATE dbo.Circular_Mail SET Status='unknown',CompletedUtc=SYSUTCDATETIME(),ErrorCode='WORKER_INTERRUPTED' WHERE Status='sending' AND ClaimedUtc<DATEADD(minute,-5,SYSUTCDATETIME());
 COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_MailClaim AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @ID bigint;
 SELECT TOP(1) @ID=m.ID FROM dbo.Circular_Mail m WITH(UPDLOCK,READPAST,ROWLOCK) JOIN dbo.Circular_CurrentRecipients r ON r.CircularID=m.CircularID AND r.Version=m.Version AND r.RecipientKind=m.RecipientKind AND r.RecipientID=m.RecipientID WHERE m.Status='pending' ORDER BY m.ID;
 UPDATE dbo.Circular_Mail SET Status='sending',ClaimedUtc=SYSUTCDATETIME() WHERE ID=@ID;
 SELECT m.ID,m.CircularID,m.Version,m.RecipientKind,r.Email,r.BrandID,c.Title,c.Title_EN,c.Summary,c.Summary_EN FROM dbo.Circular_Mail m JOIN dbo.Circular_CurrentRecipients r ON r.CircularID=m.CircularID AND r.Version=m.Version AND r.RecipientKind=m.RecipientKind AND r.RecipientID=m.RecipientID JOIN dbo.Circulars c ON c.ID=m.CircularID WHERE m.ID=@ID;
 COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_MailComplete @ID bigint,@Status varchar(16),@ErrorCode varchar(40)=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF @Status NOT IN('submitted','failed','cancelled','unknown') THROW 51800,'Invalid delivery state.',1;
 UPDATE dbo.Circular_Mail SET Status=@Status,CompletedUtc=SYSUTCDATETIME(),ErrorCode=@ErrorCode WHERE ID=@ID AND Status='sending';
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_Notifications @Actor int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Access denied.',1;
 SELECT c.ID,c.Title,c.Version,c.ModifiedUtc FROM dbo.Circulars c JOIN dbo.Circular_Visible(@Actor,SYSUTCDATETIME()) v ON v.ID=c.ID WHERE c.BrandID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Reads r WHERE r.CircularID=c.ID AND r.Version=c.Version AND r.UserID=@Actor) ORDER BY c.ModifiedUtc DESC,c.ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_CircularNotifications @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 SELECT c.ID,c.Title,c.Version,c.ModifiedUtc FROM dbo.Circulars c JOIN dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) v ON v.ID=c.ID WHERE NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerReads r WHERE r.CircularID=c.ID AND r.Version=c.Version AND r.AccountID=@AccountID) ORDER BY c.ModifiedUtc DESC,c.ID DESC;
 COMMIT;END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Circular_List @Actor int,@Admin bit=0,@Search nvarchar(250)=N'',@UnreadOnly bit=0,@Page int=1,@PageSize int=20
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1)) THROW 51801,'Access denied.',1;
 IF @Page<1 OR @Page>100000 OR @PageSize<1 OR @PageSize>100 THROW 51800,'Invalid paging.',1;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 SELECT c.ID,c.Title,c.Summary,c.Title_EN,c.Summary_EN,c.BrandID,c.HasPeriod,c.CircularDate,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,
 DATALENGTH(c.FileBytes) FileSizeBytes,c.Version,c.ModifiedUtc,
 CAST(CASE WHEN r.UserID IS NULL THEN 0 ELSE 1 END AS bit) IsRead,r.FirstReadUtc,r.LastReadUtc,
 CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>@Now THEN 'scheduled' WHEN c.EndUtc<=@Now THEN 'expired' ELSE 'active' END Status
 INTO #Items FROM dbo.Circulars c LEFT JOIN dbo.Circular_Reads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.UserID=@Actor
 WHERE (@Admin=1 OR EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) v WHERE v.ID=c.ID))
 AND (@Search=N'' OR CHARINDEX(@Search,c.Title)>0 OR CHARINDEX(@Search,c.Summary)>0 OR CHARINDEX(@Search,c.Title_EN)>0 OR CHARINDEX(@Search,c.Summary_EN)>0);
 SELECT COUNT(*) Total,COALESCE(SUM(CASE WHEN IsRead=0 THEN 1 ELSE 0 END),0) Unread,COALESCE(SUM(CASE WHEN Status='active' THEN 1 ELSE 0 END),0) Active FROM #Items;
 SELECT COUNT(*) TotalItems FROM #Items WHERE @UnreadOnly=0 OR IsRead=0;
 SELECT * FROM #Items WHERE @UnreadOnly=0 OR IsRead=0 ORDER BY IsRead,CircularDate DESC,ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Circular_Detail @Actor int,@ID int,@Admin bit=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1)) THROW 51801,'Access denied.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Circulars WHERE ID=@ID) OR (@Admin=0 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) WHERE ID=@ID)) THROW 51804,'Circular unavailable.',1;
 SELECT c.ID,c.Title,c.Summary,c.Title_EN,c.Summary_EN,c.BrandID,c.HasPeriod,c.CircularDate,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,
 DATALENGTH(c.FileBytes) FileSizeBytes,c.Version,c.CreatedUtc,c.ModifiedUtc,
 CAST(CASE WHEN r.UserID IS NULL THEN 0 ELSE 1 END AS bit) IsRead,r.FirstReadUtc,r.LastReadUtc,
 CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>@Now THEN 'scheduled' WHEN c.EndUtc<=@Now THEN 'expired' ELSE 'active' END Status
 FROM dbo.Circulars c LEFT JOIN dbo.Circular_Reads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.UserID=@Actor WHERE c.ID=@ID;
 IF @Admin=1 BEGIN
  SELECT t.Kind,t.TargetID,CASE t.Kind WHEN 'role' THEN r.Title_Ar WHEN 'brand' THEN b.Title_Ar WHEN 'branch' THEN br.Title_Ar WHEN 'department' THEN d.Title_Ar WHEN 'shift' THEN s.Title_Ar END Title
  FROM dbo.Circular_Targets t LEFT JOIN dbo.Users_Types r ON t.Kind='role' AND r.ID=t.TargetID
  LEFT JOIN dbo.Brands b ON t.Kind='brand' AND b.ID=t.TargetID LEFT JOIN dbo.Branches br ON t.Kind='branch' AND br.ID=t.TargetID
  LEFT JOIN dbo.Departments d ON t.Kind='department' AND d.ID=t.TargetID LEFT JOIN dbo.Shift s ON t.Kind='shift' AND s.ID=t.TargetID WHERE t.CircularID=@ID;
 END;
END;
GO


CREATE OR ALTER PROCEDURE dbo.Circular_AdminData @Actor int,@Mode varchar(10)='list',@ID int=0,@Page int=1 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF @Mode='list' BEGIN
  SELECT c.ID,c.BrandID,b.Title_Ar BrandName,c.Title,c.Title_EN,c.Summary,c.Summary_EN,c.CircularDate,c.HasPeriod,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,c.Version,
   CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>SYSUTCDATETIME() THEN 'scheduled' WHEN c.EndUtc<=SYSUTCDATETIME() THEN 'expired' ELSE 'active' END Status,
   (SELECT COUNT(*) FROM dbo.Circular_Reads r WHERE r.CircularID=c.ID AND r.Version=c.Version)+(SELECT COUNT(*) FROM dbo.Circular_CustomerReads r WHERE r.CircularID=c.ID AND r.Version=c.Version) ReadCount,
   (SELECT COUNT(*) FROM dbo.Circular_Mail m WHERE m.CircularID=c.ID AND m.Version=c.Version AND m.Status='submitted') MailSubmitted,
   (SELECT COUNT(*) FROM dbo.Circular_Mail m WHERE m.CircularID=c.ID AND m.Version=c.Version AND m.Status IN('failed','unknown')) MailFailed
  FROM dbo.Circulars c LEFT JOIN dbo.Brands b ON b.ID=c.BrandID ORDER BY c.CircularDate DESC,c.ID DESC;
  RETURN;
 END;
 IF @Mode='editor' BEGIN
  SELECT ID,BrandID,Title,Title_EN,Summary,Summary_EN,CircularDate,HasPeriod,StartUtc,EndUtc,IsEnabled,AllowDownload,Audience,FileName,Version FROM dbo.Circulars WHERE ID=@ID;
  SELECT Kind,TargetID FROM dbo.Circular_Targets WHERE CircularID=@ID AND Kind<>'brand' UNION ALL SELECT Kind,TargetID FROM dbo.Circular_CustomerTargets WHERE CircularID=@ID;
  SELECT 'brand' Kind,ID,Title_Ar Title,CAST(NULL AS int) BrandID FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'role',ID,Title_Ar,NULL FROM dbo.Users_Types WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'branch',ID,Title_Ar,BrandID FROM dbo.Branches WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'department',ID,Title_Ar,NULL FROM dbo.Departments WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'shift',ID,Title_Ar,NULL FROM dbo.Shift WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'customer',ID,Name_AR,Brand_ID FROM dbo.CRM_Accounts WHERE Is_Active=1 AND Is_Deleted=0
  UNION ALL SELECT 'customerType',ID,Name_AR,NULL FROM dbo.CRM_Account_Types WHERE Is_Active=1 AND Is_Deleted=0;
  RETURN;
 END;
 IF @Mode='logs' BEGIN
  IF @Page<1 OR @Page>100000 THROW 51800,'Invalid page.',1;
  SELECT l.ID,l.Version,l.TitleSnapshot,l.Action,CAST(l.Source AS varchar(20)) Source,l.RecordedUtc,CAST(u.FullName_Ar AS nvarchar(500)) ActorName,'employee' ActorKind,l.UserID ActorID,l.EmployeeNumber,l.DeviceID,l.AppVersion,l.OccurredAtUtc,
   CAST(NULL AS varchar(16)) MailStatus,CAST(NULL AS varchar(40)) ErrorCode INTO #Logs FROM dbo.Circular_Logs l JOIN dbo.UsersMembers u ON u.ID=l.UserID WHERE l.CircularID=@ID;
  INSERT #Logs SELECT ID,Version,TitleSnapshot,Action,'CustomerPortal',RecordedUtc,ActorName,'customer',AccountID,NULL,NULL,NULL,NULL,NULL,NULL FROM dbo.Circular_CustomerLogs WHERE CircularID=@ID;
  INSERT #Logs SELECT m.ID,m.Version,c.Title,'email','Service',COALESCE(m.CompletedUtc,m.ClaimedUtc,n.CreatedUtc),COALESCE(u.FullName_Ar,a.Name_AR),m.RecipientKind,m.RecipientID,u.Employee_Number,NULL,NULL,NULL,m.Status,m.ErrorCode
   FROM dbo.Circular_Mail m JOIN dbo.Circular_Notices n ON n.CircularID=m.CircularID AND n.Version=m.Version AND n.RecipientKind=m.RecipientKind AND n.RecipientID=m.RecipientID JOIN dbo.Circulars c ON c.ID=m.CircularID
   LEFT JOIN dbo.UsersMembers u ON m.RecipientKind='employee' AND u.ID=m.RecipientID LEFT JOIN dbo.CRM_Accounts a ON m.RecipientKind='customer' AND a.ID=m.RecipientID WHERE m.CircularID=@ID;
  SELECT COUNT(*) Total FROM #Logs;
  SELECT * FROM #Logs ORDER BY RecordedUtc DESC,ID DESC OFFSET (@Page-1)*50 ROWS FETCH NEXT 50 ROWS ONLY;
  RETURN;
 END;
 THROW 51800,'Invalid operation.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_AdminToggle @Actor int,@ID int,@ExpectedVersion int,@Enabled bit AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Brand int,@Title nvarchar(250),@English nvarchar(250),@Summary nvarchar(2000),@SummaryEn nvarchar(2000),@Date date,@Period bit,@Start datetime2(0),@End datetime2(0),@Download bit,@Audience varchar(16),@Targets xml;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 SELECT @Brand=BrandID,@Title=Title,@English=Title_EN,@Summary=Summary,@SummaryEn=Summary_EN,@Date=CircularDate,@Period=HasPeriod,@Start=StartUtc,@End=EndUtc,@Download=AllowDownload,@Audience=Audience FROM dbo.Circulars WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Version=@ExpectedVersion;
 IF @Brand IS NULL THROW 51809,'Reload and assign a brand before changing the state.',1;
 SET @Targets=(SELECT Kind [@kind],TargetID [@id] FROM (SELECT Kind,TargetID FROM dbo.Circular_Targets WHERE CircularID=@ID AND Kind<>'brand' UNION ALL SELECT Kind,TargetID FROM dbo.Circular_CustomerTargets WHERE CircularID=@ID) t FOR XML PATH('item'),ROOT('targets'));
 EXEC dbo.Circular_AdminSave @Actor,@ID,@ExpectedVersion,@Brand,@Title,@English,@Summary,@SummaryEn,@Date,@Period,@Start,@End,@Enabled,@Download,@Audience,@Targets;
 COMMIT;END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Circular_MailValidate @ID bigint,@Email nvarchar(254) AS
BEGIN
 SET NOCOUNT ON;
 SELECT m.ID FROM dbo.Circular_Mail m JOIN dbo.Circular_CurrentRecipients r ON r.CircularID=m.CircularID AND r.Version=m.Version AND r.RecipientKind=m.RecipientKind AND r.RecipientID=m.RecipientID WHERE m.ID=@ID AND m.Status='sending' AND LTRIM(RTRIM(r.Email))=@Email;
END;
GO
