SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Customer_Logins','U') IS NULL
BEGIN
 CREATE TABLE dbo.Customer_Logins(AccountID int PRIMARY KEY REFERENCES dbo.CRM_Accounts(ID),Username nvarchar(100) NOT NULL,
 NormalizedUsername AS UPPER(LTRIM(RTRIM(Username))) PERSISTED,PasswordHash varbinary(32) NOT NULL,Salt varbinary(32) NOT NULL,
 Iterations int NOT NULL,IsActive bit NOT NULL DEFAULT(1),SecurityStamp uniqueidentifier NOT NULL DEFAULT NEWID(),
 FailedAttempts int NOT NULL DEFAULT(0),LockedUntil datetime2 NULL,LastLoginUtc datetime2 NULL,ModifiedBy int NOT NULL REFERENCES dbo.UsersMembers(ID),ModifiedUtc datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),Version rowversion);
 CREATE UNIQUE INDEX UX_Customer_Username ON dbo.Customer_Logins(NormalizedUsername);
 CREATE TABLE dbo.Customer_Guide_Grants(ID int IDENTITY PRIMARY KEY,AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),Brand_ID int NOT NULL REFERENCES dbo.Brands(ID),
 Category_ID int NOT NULL REFERENCES dbo.Work_Guide_Categories(ID),Role_ID int NOT NULL REFERENCES dbo.Work_Guide_Roles(ID),Apply_To_Children bit NOT NULL,
 Start_Date datetime NULL,End_Date datetime NULL,IsActive bit NOT NULL DEFAULT(1),ModifiedBy int NOT NULL REFERENCES dbo.UsersMembers(ID),Version rowversion,
 CONSTRAINT UX_Customer_Grant UNIQUE(AccountID,Category_ID));
 CREATE TABLE dbo.Customer_Portal_Activity(ID bigint IDENTITY PRIMARY KEY,AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),ActorID int NULL,
 Action varchar(30) NOT NULL,DocumentID int NULL,Note nvarchar(1000) NULL,CreatedUtc datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
 CREATE TABLE dbo.Customer_Portal_Feedback(RequestID int PRIMARY KEY REFERENCES dbo.Employee_Feedback_Requests(ID),AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),OperationID uniqueidentifier NOT NULL,
 CONSTRAINT UX_Customer_Feedback_Operation UNIQUE(AccountID,OperationID));
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_AdminCheck @Actor int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51910,N'هذه الإدارة متاحة لمدير النظام فقط.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SaveLogin @Actor int,@AccountID int,@Username nvarchar(100),@Hash varbinary(32)=NULL,@Salt varbinary(32)=NULL,@Iterations int=210000,@Active bit=1,@Version binary(8)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.Customer_AdminCheck @Actor;
 SET @Username=LTRIM(RTRIM(@Username));
 IF NULLIF(@Username,'') IS NULL OR LEN(@Username)<3 OR @Iterations<100000 THROW 51910,N'أدخل اسم مستخدم من 3 إلى 100 حرف.',1;
 IF @Hash IS NOT NULL AND (DATALENGTH(@Hash)<>32 OR @Salt IS NULL OR DATALENGTH(@Salt)<>32) THROW 51910,N'بيانات كلمة المرور غير صحيحة.',1;
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@AccountID AND Is_Deleted=0) BEGIN ROLLBACK;THROW 51910,N'العميل غير متاح.',1;END;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Logins WITH(UPDLOCK,HOLDLOCK) WHERE NormalizedUsername=UPPER(@Username) AND AccountID<>@AccountID) BEGIN ROLLBACK;THROW 51910,N'اسم المستخدم محجوز لعميل آخر.',1;END;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Logins WITH(UPDLOCK,HOLDLOCK) WHERE AccountID=@AccountID)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins WHERE AccountID=@AccountID AND Version=@Version) BEGIN ROLLBACK;THROW 51910,N'تغير الحساب؛ حدّث الصفحة قبل الحفظ.',1;END;
  UPDATE dbo.Customer_Logins SET Username=@Username,PasswordHash=COALESCE(@Hash,PasswordHash),Salt=CASE WHEN @Hash IS NULL THEN Salt ELSE @Salt END,
  Iterations=CASE WHEN @Hash IS NULL THEN Iterations ELSE @Iterations END,IsActive=@Active,SecurityStamp=NEWID(),FailedAttempts=0,LockedUntil=NULL,ModifiedBy=@Actor,ModifiedUtc=SYSUTCDATETIME() WHERE AccountID=@AccountID;
 END
 ELSE BEGIN
  IF @Hash IS NULL BEGIN ROLLBACK;THROW 51910,N'كلمة المرور مطلوبة للحساب الجديد.',1;END;
  INSERT dbo.Customer_Logins(AccountID,Username,PasswordHash,Salt,Iterations,IsActive,ModifiedBy) VALUES(@AccountID,@Username,@Hash,@Salt,@Iterations,@Active,@Actor);
 END;
 INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) VALUES(@AccountID,@Actor,'credentials',N'تم تحديث اسم الدخول أو حالة الحساب أو إعادة تعيين كلمة المرور.');
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_Credentials @Username nvarchar(100) AS
BEGIN
 SET NOCOUNT ON;
 SELECT l.AccountID,l.PasswordHash,l.Salt,l.Iterations,l.SecurityStamp FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE l.NormalizedUsername=UPPER(LTRIM(RTRIM(@Username))) AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0 AND (l.LockedUntil IS NULL OR l.LockedUntil<=SYSUTCDATETIME());
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_LoginResult @AccountID int,@Stamp uniqueidentifier,@Success bit AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l WITH(UPDLOCK,HOLDLOCK) JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0 AND (LockedUntil IS NULL OR LockedUntil<=SYSUTCDATETIME())) BEGIN ROLLBACK;RETURN;END;
 IF @Success=0
 BEGIN
  UPDATE dbo.Customer_Logins SET LockedUntil=CASE WHEN FailedAttempts>=4 THEN DATEADD(minute,15,SYSUTCDATETIME()) ELSE NULL END,FailedAttempts=CASE WHEN FailedAttempts>=4 THEN 0 ELSE FailedAttempts+1 END WHERE AccountID=@AccountID;
 END
 ELSE BEGIN
  UPDATE dbo.Customer_Logins SET LastLoginUtc=SYSUTCDATETIME(),FailedAttempts=0,LockedUntil=NULL WHERE AccountID=@AccountID;
  INSERT dbo.Customer_Portal_Activity(AccountID,Action) VALUES(@AccountID,'login');
  SELECT a.ID AccountID,a.Name_AR,l.SecurityStamp FROM dbo.CRM_Accounts a JOIN dbo.Customer_Logins l ON l.AccountID=a.ID WHERE a.ID=@AccountID;
 END;
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_Session @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول؛ سجل الدخول مجددًا.',1;
 SELECT a.ID AccountID,a.Name_AR,a.Phone,a.Email FROM dbo.CRM_Accounts a WHERE ID=@AccountID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_AdminData @Actor int,@AccountID int,@Section varchar(20)='login',@Brand int=0 AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.Customer_AdminCheck @Actor;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Is_Deleted=0) THROW 51910,N'العميل غير متاح.',1;
 IF @Section='login' SELECT a.Name_AR,l.AccountID,l.Username,l.IsActive,l.LastLoginUtc,l.Version FROM dbo.CRM_Accounts a LEFT JOIN dbo.Customer_Logins l ON l.AccountID=a.ID WHERE a.ID=@AccountID;
 IF @Section='grants' SELECT g.*,b.Title_Ar BrandName,c.Title_Ar CategoryName,r.Title_Ar RoleName FROM dbo.Customer_Guide_Grants g JOIN dbo.Brands b ON b.ID=g.Brand_ID JOIN dbo.Work_Guide_Categories c ON c.ID=g.Category_ID JOIN dbo.Work_Guide_Roles r ON r.ID=g.Role_ID WHERE AccountID=@AccountID ORDER BY b.ID,c.ID;
 IF @Section='brands' SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='categories' SELECT ID,Title_Ar Title FROM dbo.Work_Guide_Categories WHERE Brand_ID=@Brand AND ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='roles' SELECT ID,Title_Ar Title FROM dbo.Work_Guide_Roles WHERE ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='activity' SELECT TOP(100) x.CreatedUtc,CASE x.Action WHEN 'credentials' THEN N'بيانات الدخول' WHEN 'grant' THEN N'صلاحيات الدليل' WHEN 'login' THEN N'تسجيل الدخول' WHEN 'view' THEN N'عرض دليل' WHEN 'download' THEN N'تنزيل دليل' WHEN 'feedback' THEN N'تقديم طلب' ELSE x.Action END Action,x.Note,x.DocumentID,u.FullName_Ar ActorName FROM dbo.Customer_Portal_Activity x LEFT JOIN dbo.UsersMembers u ON u.ID=x.ActorID WHERE x.AccountID=@AccountID ORDER BY x.ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SaveGrant @Actor int,@AccountID int,@CategoryID int,@RoleID int,@Children bit,@Start datetime=NULL,@End datetime=NULL,@Active bit=1,@Version binary(8)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.Customer_AdminCheck @Actor;
 IF @Start IS NOT NULL AND @End IS NOT NULL AND @Start>@End THROW 51910,N'تاريخ النهاية يسبق البداية.',1;
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@AccountID AND Is_Deleted=0) BEGIN ROLLBACK;THROW 51910,N'العميل غير متاح.',1;END;
 DECLARE @Brand int=(SELECT c.Brand_ID FROM dbo.Work_Guide_Categories c JOIN dbo.Brands b ON b.ID=c.Brand_ID WHERE c.ID=@CategoryID AND ISNULL(c.IsDeleted,0)=0 AND ISNULL(c.IsActive,1)=1 AND ISNULL(b.IsDeleted,0)=0 AND b.IsActive=1);
 IF @Active=0 AND EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Category_ID=@CategoryID AND Role_ID=@RoleID AND Version=@Version)
 BEGIN
  UPDATE dbo.Customer_Guide_Grants SET IsActive=0,ModifiedBy=@Actor WHERE AccountID=@AccountID AND Category_ID=@CategoryID;
  INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) VALUES(@AccountID,@Actor,'grant',CONCAT(N'إيقاف تفويض التصنيف ',@CategoryID));
  COMMIT; RETURN;
 END;
 IF @Brand IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Roles WHERE ID=@RoleID AND ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0) BEGIN ROLLBACK;THROW 51910,N'اختر تصنيفًا ودورًا فعالين.',1;END;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants WITH(UPDLOCK,HOLDLOCK) WHERE AccountID=@AccountID AND Category_ID=@CategoryID)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Category_ID=@CategoryID AND Version=@Version) BEGIN ROLLBACK;THROW 51910,N'يوجد تفويض لهذا التصنيف؛ افتحه للتعديل أولًا.',1;END;
  UPDATE dbo.Customer_Guide_Grants SET Role_ID=@RoleID,Apply_To_Children=@Children,Start_Date=@Start,End_Date=@End,IsActive=@Active,ModifiedBy=@Actor WHERE AccountID=@AccountID AND Category_ID=@CategoryID;
 END
 ELSE INSERT dbo.Customer_Guide_Grants(AccountID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,Start_Date,End_Date,IsActive,ModifiedBy) VALUES(@AccountID,@Brand,@CategoryID,@RoleID,@Children,@Start,@End,@Active,@Actor);
 INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) VALUES(@AccountID,@Actor,'grant',CONCAT(N'التصنيف ',@CategoryID,N'، الدور ',@RoleID,N'، فعال ',@Active));
 COMMIT;
END;
GO
-- Retire the old employee identity while preserving users, grants, requests and audit history.
UPDATE dbo.UsersMembers SET IsActive=0 WHERE Type=7 AND ISNULL(IsActive,0)<>0;
UPDATE dbo.Users_Types SET IsActive=0,IsDeleted=1 WHERE ID=7;
GO
CREATE OR ALTER TRIGGER dbo.Customer_RetiredExternalType ON dbo.UsersMembers AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.ID=i.ID WHERE i.Type=7 AND (ISNULL(i.IsActive,0)=1 OR d.ID IS NULL OR ISNULL(d.Type,0)<>7))
 THROW 51910,N'أُلغي المستخدم الخارجي؛ أنشئ حساب دخول من إدارة العملاء.',1;
END;
GO
