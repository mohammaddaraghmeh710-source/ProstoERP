-- Existing pages remain employee-only. Audience is access state, never content/version state.
IF COL_LENGTH('dbo.Information_Pages','Audience') IS NULL
 ALTER TABLE dbo.Information_Pages ADD Audience varchar(10) NOT NULL CONSTRAINT DF_InformationPages_Audience DEFAULT('employees'),AllCustomers bit NOT NULL CONSTRAINT DF_InformationPages_AllCustomers DEFAULT(0);
GO
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_InformationPages_Audience')
 ALTER TABLE dbo.Information_Pages ADD CONSTRAINT CK_InformationPages_Audience CHECK(Audience IN('employees','customers','all'));
IF OBJECT_ID('dbo.Information_Page_Customers','U') IS NULL
 CREATE TABLE dbo.Information_Page_Customers(PageID int NOT NULL REFERENCES dbo.Information_Pages(ID),AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),CONSTRAINT PK_Information_Page_Customers PRIMARY KEY(PageID,AccountID));
IF COL_LENGTH('dbo.Information_Page_Logs','CustomerAccountID') IS NULL
 ALTER TABLE dbo.Information_Page_Logs ADD CustomerAccountID int NULL CONSTRAINT FK_InformationPageLog_Customer REFERENCES dbo.CRM_Accounts(ID);
GO
-- Existing portal and employee-mobile consumers share this eligibility boundary.
CREATE OR ALTER FUNCTION dbo.Information_Pages_ForBrand(@Brand int)
RETURNS TABLE AS RETURN
 SELECT pb.PageID FROM dbo.Information_Page_Brands pb JOIN dbo.Brands b ON b.ID=pb.BrandID
 JOIN dbo.Information_Pages p ON p.ID=pb.PageID
 WHERE pb.BrandID=@Brand AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 AND p.Audience IN('employees','all');
GO
