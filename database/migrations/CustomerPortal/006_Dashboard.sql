IF COL_LENGTH('dbo.CRM_Accounts','Logo_Url') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Logo_Url nvarchar(260) NULL;
GO
IF COL_LENGTH('dbo.CRM_Contacts','Job_Title_EN') IS NULL ALTER TABLE dbo.CRM_Contacts ADD Job_Title_EN nvarchar(200) NULL;
GO
-- Customer profile and authorized editor data. Identity is always supplied by the authenticated server session.
CREATE OR ALTER PROCEDURE dbo.Customer_Dashboard @AccountID int,@Stamp uniqueidentifier,@Section varchar(16)='profile' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0)
 THROW 51911,N'انتهت صلاحية الدخول؛ سجل الدخول مجددًا.',1;
 IF @Section='profile'
 SELECT a.Name_AR,a.Name_EN,a.Phone,a.Email,t.Name_AR TypeName,b.Title_Ar BrandName,br.Title_Ar BranchName,
 (SELECT COUNT(*) FROM dbo.CRM_Contacts c WHERE c.Account_ID=a.ID AND c.Is_Deleted=0) ContactCount
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 LEFT JOIN dbo.Brands b ON b.ID=a.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=a.Branch_ID WHERE a.ID=@AccountID;
 ELSE IF @Section='contacts'
 SELECT ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Row_Version FROM dbo.CRM_Contacts WHERE Account_ID=@AccountID AND Is_Deleted=0 ORDER BY Name_AR,ID;
 ELSE IF @Section='editor'
 SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 ELSE IF @Section='logo'
 SELECT Logo_Url FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Logo_Url IS NOT NULL;
 ELSE THROW 51910,N'الطلب غير متاح.',1;
END;
GO
