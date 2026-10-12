SET XACT_ABORT ON;
IF OBJECT_ID('dbo.CustomerApi_Sessions','U') IS NULL
BEGIN
 CREATE TABLE dbo.CustomerApi_Sessions(TokenHash binary(32) PRIMARY KEY,AccountID int NOT NULL REFERENCES dbo.Customer_Logins(AccountID),SecurityStamp uniqueidentifier NOT NULL,CreatedUtc datetime2 NOT NULL,LastUsedUtc datetime2 NOT NULL,ExpiresUtc datetime2 NOT NULL,RevokedUtc datetime2 NULL);
 CREATE INDEX IX_CustomerApi_Account ON dbo.CustomerApi_Sessions(AccountID,ExpiresUtc);
 CREATE TABLE dbo.CustomerApi_LoginRate(ClientHash binary(32) PRIMARY KEY,WindowUtc datetime2 NOT NULL,Attempts int NOT NULL);
 CREATE TABLE dbo.CustomerApi_FeedbackOperations(AccountID int NOT NULL,OperationID uniqueidentifier NOT NULL,PayloadHash binary(32) NOT NULL,PRIMARY KEY(AccountID,OperationID),FOREIGN KEY(AccountID,OperationID) REFERENCES dbo.Customer_Portal_Feedback(AccountID,OperationID));
END;
IF OBJECT_ID('dbo.CustomerApi_GuideOperations','U') IS NULL
 CREATE TABLE dbo.CustomerApi_GuideOperations(AccountID int NOT NULL REFERENCES dbo.Customer_Logins(AccountID),OperationID uniqueidentifier NOT NULL,PayloadHash binary(32) NOT NULL,BatchID uniqueidentifier NOT NULL,PRIMARY KEY(AccountID,OperationID));
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_CheckLoginRate @ClientHash binary(32) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRAN;
 DECLARE @Now datetime2=SYSUTCDATETIME(),@Start datetime2,@Count int;
 SELECT @Start=WindowUtc,@Count=Attempts FROM dbo.CustomerApi_LoginRate WITH(UPDLOCK,HOLDLOCK) WHERE ClientHash=@ClientHash;
 IF @Start IS NULL BEGIN INSERT dbo.CustomerApi_LoginRate VALUES(@ClientHash,@Now,1);SET @Count=1;SET @Start=@Now;END
 ELSE IF @Start<=DATEADD(minute,-15,@Now) BEGIN UPDATE dbo.CustomerApi_LoginRate SET WindowUtc=@Now,Attempts=1 WHERE ClientHash=@ClientHash;SET @Count=1;SET @Start=@Now;END
 ELSE BEGIN SET @Count=@Count+1;UPDATE dbo.CustomerApi_LoginRate SET Attempts=@Count WHERE ClientHash=@ClientHash;END;
 COMMIT;
 SELECT CAST(CASE WHEN @Count<=30 THEN 1 ELSE 0 END AS bit) Allowed,CASE WHEN @Count<=30 THEN 0 ELSE DATEDIFF(second,@Now,DATEADD(minute,15,@Start))+1 END RetryAfterSeconds;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_CreateSession @AccountID int,@Stamp uniqueidentifier,@TokenHash binary(32) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l WITH(HOLDLOCK) JOIN dbo.CRM_Accounts a WITH(HOLDLOCK) ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0 AND (LockedUntil IS NULL OR LockedUntil<=SYSUTCDATETIME())) BEGIN ROLLBACK;THROW 51911,N'تعذر تسجيل الدخول.',1;END;
 DECLARE @Now datetime2=SYSUTCDATETIME(),@Expires datetime2=DATEADD(day,30,SYSUTCDATETIME());
 INSERT dbo.CustomerApi_Sessions VALUES(@TokenHash,@AccountID,@Stamp,@Now,@Now,@Expires,NULL);
 COMMIT;SELECT @Expires ExpiresUtc;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_Authenticate @TokenHash binary(32) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 DECLARE @Now datetime2=SYSUTCDATETIME();
 UPDATE s SET LastUsedUtc=@Now OUTPUT inserted.AccountID,inserted.SecurityStamp,inserted.ExpiresUtc
 FROM dbo.CustomerApi_Sessions s JOIN dbo.Customer_Logins l ON l.AccountID=s.AccountID AND l.SecurityStamp=s.SecurityStamp JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.LastUsedUtc>DATEADD(hour,-8,@Now) AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_Logout @TokenHash binary(32) AS
BEGIN SET NOCOUNT ON;UPDATE dbo.CustomerApi_Sessions SET RevokedUtc=SYSUTCDATETIME() WHERE TokenHash=@TokenHash AND RevokedUtc IS NULL;END;
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_Guide @AccountID int,@Stamp uniqueidentifier,@Brand int,@Category int=0,@Search nvarchar(200)=N'',@Page int=1,@PageSize int=20,@Section varchar(16)='documents' AS
BEGIN
 SET NOCOUNT ON;
 IF @Page<1 OR @Page>1000000 OR @PageSize<1 OR @PageSize>100 THROW 51910,N'قيم التصفح غير صحيحة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Section='categories'
 SELECT ID,Parent_ID,Title_Ar,Full_Path_Ar,Can_View_Document,Can_Print_Document,Can_Download_Document FROM dbo.Customer_Guide_Effective(@AccountID,@Brand) WHERE Can_View_Category=1 OR Can_View_Document=1 ORDER BY Sort_Path OPTION(MAXRECURSION 100);
 ELSE BEGIN
 SELECT d.ID,d.Title_Ar,d.Description_Ar,d.AddedDate,d.Brand_ID,d.Category_ID,c.Full_Path_Ar CategoryName,c.Can_Print_Document,
 CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) Can_Download_Document
 INTO #Documents FROM dbo.Work_Guide_Documents d JOIN dbo.Customer_Guide_Effective(@AccountID,@Brand)c ON c.ID=d.Category_ID
 WHERE d.Brand_ID=@Brand AND (@Category=0 OR d.Category_ID=@Category) AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1
 AND (@Search=N'' OR CHARINDEX(@Search,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Search,c.Full_Path_Ar)>0) OPTION(MAXRECURSION 100);
 SELECT COUNT(*) Total FROM #Documents;
 SELECT * FROM #Documents ORDER BY AddedDate DESC,ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
 END;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CustomerApi_Feedback @AccountID int,@Stamp uniqueidentifier,@ID int=0,@AttachmentID int=0,@Page int=1,@PageSize int=20,@Status int=0,@Search nvarchar(200)=N'' AS
BEGIN
 SET NOCOUNT ON;
 IF @Page<1 OR @Page>1000000 OR @PageSize<1 OR @PageSize>100 OR @Status NOT IN(0,1,2,3) THROW 51910,N'قيم التصفح غير صحيحة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @AttachmentID>0 BEGIN
  SELECT f.ID,f.FileName,f.File_Type,f.FileSize FROM dbo.Employee_Feedback_Attachments f JOIN dbo.Customer_Portal_Feedback c ON c.RequestID=f.Request_ID
  WHERE c.AccountID=@AccountID AND f.ID=@AttachmentID AND f.Workflow_ID IS NULL;RETURN;
 END;
 IF @ID>0 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Portal_Feedback WHERE AccountID=@AccountID AND RequestID=@ID) THROW 51912,N'الطلب غير متاح.',1;
  SELECT r.ID,r.Type,r.Topic_ID,r.Brand_ID,r.Branch_ID,r.Title,r.Details,r.Status,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,r.Branch_Title_Ar,r.Topic_Title_Ar,r.ApplicantName,r.ApplicantMobile,r.ApplicantEmail
  FROM dbo.Employee_Feedback_Requests r WHERE r.ID=@ID;
  SELECT ID,File_Type,FileSize,AddedDate FROM dbo.Employee_Feedback_Attachments WHERE Request_ID=@ID AND Workflow_ID IS NULL ORDER BY ID;RETURN;
 END;
 SELECT r.ID,r.Type,r.Title,r.Status,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,t.Title_Ar TypeName INTO #Requests
 FROM dbo.Customer_Portal_Feedback c JOIN dbo.Employee_Feedback_Requests r ON r.ID=c.RequestID JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type
 WHERE c.AccountID=@AccountID AND (@Status=0 OR r.Status=@Status) AND (@Search=N'' OR CHARINDEX(@Search,r.Title)>0);
 SELECT COUNT(*) Total FROM #Requests;
 SELECT * FROM #Requests ORDER BY ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
