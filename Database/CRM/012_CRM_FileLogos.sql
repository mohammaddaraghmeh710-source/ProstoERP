-- Export and verify legacy bytes using FileLogoMigration.ps1 before this migration.
IF COL_LENGTH('dbo.CRM_Accounts','Logo_Url') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Logo_Url nvarchar(260) NULL;
GO
IF COL_LENGTH('dbo.CRM_Accounts','Logo_Data') IS NOT NULL
 EXEC(N'IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE Logo_Data IS NOT NULL AND Logo_Url IS NULL) THROW 51990,''Export and verify existing logos before removing binary storage.'',1;');
IF OBJECT_ID('dbo.CRM_Account_Logos','U') IS NOT NULL THROW 51990,'Apply the verified legacy logo consolidation first.',1;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Account_Logos @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 SELECT a.ID Account_ID,a.Row_Version FROM dbo.CRM_Accounts a
 WHERE a.Logo_Url IS NOT NULL AND a.Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,a.ID)=1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Account_Logo @Actor_ID int,@Account_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,ID)=1)
  THROW 51201,N'شعار العميل غير متاح.',1;
 SELECT Logo_Url FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Logo_Url IS NOT NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Account_Logo @Actor_ID int,@Account_ID int,@Logo_Url nvarchar(260),@Version binary(8) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @Lock int;
  EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
  IF @Lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Account_ID AND Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,ID)=1)
   THROW 51201,N'ليس لديك صلاحية لتغيير شعار هذا العميل.',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Row_Version=@Version)
   THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
  IF @Logo_Url IS NULL OR (@Logo_Url COLLATE Latin1_General_100_BIN2 NOT LIKE N'/FileManager/CustomerLogos/'+REPLICATE(N'[0-9a-f]',32)+N'.png' OR DATALENGTH(@Logo_Url)<>126)
   THROW 51201,N'مسار الشعار غير صحيح.',1;
  DECLARE @Before xml=(SELECT ID Account_ID,Logo_Url,Row_Version FROM dbo.CRM_Accounts WHERE ID=@Account_ID FOR XML PATH('logo'),BINARY BASE64,TYPE);
  UPDATE dbo.CRM_Accounts SET Logo_Url=@Logo_Url,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@Account_ID;
  DECLARE @After xml=(SELECT ID Account_ID,Logo_Url,Row_Version FROM dbo.CRM_Accounts WHERE ID=@Account_ID FOR XML PATH('logo'),BINARY BASE64,TYPE);
  INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data)
   VALUES(@Actor_ID,@Account_ID,N'Accounts',@Account_ID,N'تحديث الشعار',@Before,@After);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH
END;
GO
IF OBJECT_ID('dbo.CK_CRM_Accounts_Logo','C') IS NOT NULL ALTER TABLE dbo.CRM_Accounts DROP CONSTRAINT CK_CRM_Accounts_Logo;
IF COL_LENGTH('dbo.CRM_Accounts','Logo_Data') IS NOT NULL ALTER TABLE dbo.CRM_Accounts DROP COLUMN Logo_Data;
GO
IF OBJECT_ID('dbo.CK_CRM_Accounts_LogoUrl','C') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT CK_CRM_Accounts_LogoUrl CHECK(Logo_Url IS NULL OR (Logo_Url COLLATE Latin1_General_100_BIN2 LIKE N'/FileManager/CustomerLogos/'+REPLICATE(N'[0-9a-f]',32)+N'.png' AND DATALENGTH(Logo_Url)=126));
GO
