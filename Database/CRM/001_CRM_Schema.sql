IF OBJECT_ID('dbo.CRM_Account_Types','U') IS NULL
CREATE TABLE dbo.CRM_Account_Types(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Name_AR] nvarchar(200) NULL,
[Name_EN] nvarchar(200) NULL,
[Notes] nvarchar(2000) NULL,
Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
Is_Active bit NOT NULL DEFAULT(1), Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID), AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NULL, Row_Version rowversion);

GO

IF OBJECT_ID('dbo.CRM_Contract_Types','U') IS NULL
CREATE TABLE dbo.CRM_Contract_Types(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Name_AR] nvarchar(200) NULL,
[Name_EN] nvarchar(200) NULL,
[Notes] nvarchar(2000) NULL,
Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
Is_Active bit NOT NULL DEFAULT(1), Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID), AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NULL, Row_Version rowversion);

GO

IF OBJECT_ID('dbo.CRM_Payment_Methods','U') IS NULL
CREATE TABLE dbo.CRM_Payment_Methods(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Name_AR] nvarchar(200) NULL,
[Name_EN] nvarchar(200) NULL,
[Notes] nvarchar(2000) NULL,
Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
Is_Active bit NOT NULL DEFAULT(1), Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID), AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NULL, Row_Version rowversion);

GO

IF OBJECT_ID('dbo.CRM_Accounts','U') IS NULL
CREATE TABLE dbo.CRM_Accounts(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Name_AR] nvarchar(200) NULL,
[Name_EN] nvarchar(200) NULL,
[Account_Type_ID] int NULL,
[Owner_ID] int NULL,
[Phone] nvarchar(50) NULL,
[Email] nvarchar(254) NULL,
[Address] nvarchar(500) NULL,
[Country] nvarchar(100) NULL,
[Website] nvarchar(500) NULL,
[Registration_Number] nvarchar(100) NULL,
[Notes] nvarchar(2000) NULL,
Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
Is_Active bit NOT NULL DEFAULT(1), Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID), AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NULL, Row_Version rowversion);

GO

IF OBJECT_ID('dbo.CRM_Contacts','U') IS NULL
CREATE TABLE dbo.CRM_Contacts(ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
[Account_ID] int NULL,
[Name_AR] nvarchar(200) NULL,
[Job_Title] nvarchar(200) NULL,
[Phone] nvarchar(50) NULL,
[Email] nvarchar(254) NULL,
[Gender] nvarchar(20) NULL,
[Notes] nvarchar(2000) NULL,
Is_Active bit NOT NULL DEFAULT(1), Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID), AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NULL, Row_Version rowversion);

GO

IF OBJECT_ID('dbo.FK_CRM_Accounts_Account_Type_ID','F') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT FK_CRM_Accounts_Account_Type_ID FOREIGN KEY([Account_Type_ID]) REFERENCES dbo.CRM_Account_Types(ID);

GO

IF OBJECT_ID('dbo.FK_CRM_Accounts_Owner_ID','F') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT FK_CRM_Accounts_Owner_ID FOREIGN KEY([Owner_ID]) REFERENCES dbo.UsersMembers(ID);

GO

IF OBJECT_ID('dbo.FK_CRM_Contacts_Account_ID','F') IS NULL ALTER TABLE dbo.CRM_Contacts ADD CONSTRAINT FK_CRM_Contacts_Account_ID FOREIGN KEY([Account_ID]) REFERENCES dbo.CRM_Accounts(ID);

GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Payment_Methods') AND name='UX_CRM_Payment_Methods_Name') CREATE UNIQUE INDEX UX_CRM_Payment_Methods_Name ON dbo.CRM_Payment_Methods(Normalized_Name) ;

GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Contract_Types') AND name='UX_CRM_Contract_Types_Name') CREATE UNIQUE INDEX UX_CRM_Contract_Types_Name ON dbo.CRM_Contract_Types(Normalized_Name) ;

GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Account_Types') AND name='UX_CRM_Account_Types_Name') CREATE UNIQUE INDEX UX_CRM_Account_Types_Name ON dbo.CRM_Account_Types(Normalized_Name) ;

GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Accounts') AND name='UX_CRM_Accounts_Name') CREATE UNIQUE INDEX UX_CRM_Accounts_Name ON dbo.CRM_Accounts(Normalized_Name) ;

GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Accounts') AND name='UX_CRM_Accounts_Registration') CREATE UNIQUE INDEX UX_CRM_Accounts_Registration ON dbo.CRM_Accounts(Registration_Number) WHERE Registration_Number IS NOT NULL;

GO

IF OBJECT_ID('dbo.CRM_Activity_Logs','U') IS NULL
CREATE TABLE dbo.CRM_Activity_Logs(ID bigint IDENTITY PRIMARY KEY, Actor_ID int NOT NULL REFERENCES dbo.UsersMembers(ID), Account_ID int NULL REFERENCES dbo.CRM_Accounts(ID), Entity nvarchar(80) NOT NULL, Record_ID int NULL, Action nvarchar(30) NOT NULL, Before_Data xml NULL, After_Data xml NULL, Note nvarchar(1000) NULL, AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()));

GO

CREATE OR ALTER FUNCTION dbo.CRM_CanAccess(@Actor_ID int,@Account_ID int) RETURNS bit AS
BEGIN
 DECLARE @ok bit=0;
 IF EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.ID=@Account_ID AND a.Owner_ID=u.ID AND a.Is_Deleted=0))) SET @ok=1;
 RETURN @ok;
END

GO

CREATE OR ALTER PROCEDURE dbo.CRM_CheckUser @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) THROW 51200,N'ليس لديك صلاحية الوصول إلى إدارة العملاء.',1;
 SELECT CONVERT(bit,CASE WHEN Type=1 THEN 1 ELSE 0 END) AS Is_Admin FROM dbo.UsersMembers WHERE ID=@Actor_ID;
END

GO

CREATE OR ALTER VIEW dbo.CRM_v_Account_Types AS
SELECT * FROM dbo.CRM_Account_Types;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Select_Account_Types @Actor_ID int,@ID int=NULL,@Include_Deleted bit=0 AS
BEGIN SET NOCOUNT ON;
 SELECT t.* FROM dbo.CRM_v_Account_Types t WHERE EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) AND (@ID IS NULL OR t.ID=@ID) AND (t.Is_Deleted=0 OR @Include_Deleted=1) ORDER BY t.ID DESC;
END

GO

CREATE OR ALTER VIEW dbo.CRM_v_Contract_Types AS
SELECT * FROM dbo.CRM_Contract_Types;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Select_Contract_Types @Actor_ID int,@ID int=NULL,@Include_Deleted bit=0 AS
BEGIN SET NOCOUNT ON;
 SELECT t.* FROM dbo.CRM_v_Contract_Types t WHERE EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) AND (@ID IS NULL OR t.ID=@ID) AND (t.Is_Deleted=0 OR @Include_Deleted=1) ORDER BY t.ID DESC;
END

GO

CREATE OR ALTER VIEW dbo.CRM_v_Payment_Methods AS
SELECT * FROM dbo.CRM_Payment_Methods;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Select_Payment_Methods @Actor_ID int,@ID int=NULL,@Include_Deleted bit=0 AS
BEGIN SET NOCOUNT ON;
 SELECT t.* FROM dbo.CRM_v_Payment_Methods t WHERE EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) AND (@ID IS NULL OR t.ID=@ID) AND (t.Is_Deleted=0 OR @Include_Deleted=1) ORDER BY t.ID DESC;
END

GO

CREATE OR ALTER VIEW dbo.CRM_v_Accounts AS
SELECT t.*, o.FullName_Ar AS Owner_Name, at.Name_AR AS Type_Name FROM dbo.CRM_Accounts t LEFT JOIN dbo.UsersMembers o ON o.ID=t.Owner_ID LEFT JOIN dbo.CRM_Account_Types at ON at.ID=t.Account_Type_ID;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Select_Accounts @Actor_ID int,@ID int=NULL,@Include_Deleted bit=0 AS
BEGIN SET NOCOUNT ON;
 SELECT t.* FROM dbo.CRM_v_Accounts t WHERE dbo.CRM_CanAccess(@Actor_ID,t.ID)=1 AND (@ID IS NULL OR t.ID=@ID) AND (t.Is_Deleted=0 OR @Include_Deleted=1) ORDER BY t.ID DESC;
END

GO

CREATE OR ALTER VIEW dbo.CRM_v_Contacts AS
SELECT t.*,a.Name_AR AS Account_Name FROM dbo.CRM_Contacts t JOIN dbo.CRM_Accounts a ON a.ID=t.Account_ID;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Select_Contacts @Actor_ID int,@ID int=NULL,@Include_Deleted bit=0 AS
BEGIN SET NOCOUNT ON;
 SELECT t.* FROM dbo.CRM_v_Contacts t WHERE dbo.CRM_CanAccess(@Actor_ID,t.Account_ID)=1 AND (@ID IS NULL OR t.ID=@ID) AND (t.Is_Deleted=0 OR @Include_Deleted=1) ORDER BY t.ID DESC;
END

GO

GO
