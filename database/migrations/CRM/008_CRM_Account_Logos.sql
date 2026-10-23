-- One optional logo per customer, stored on the customer row.
IF COL_LENGTH('dbo.CRM_Accounts','Logo_Data') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Logo_Data varbinary(max) NULL;
GO
IF OBJECT_ID('dbo.CK_CRM_Accounts_Logo','C') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT CK_CRM_Accounts_Logo CHECK(Logo_Data IS NULL OR (DATALENGTH(Logo_Data) BETWEEN 8 AND 2097152 AND SUBSTRING(Logo_Data,1,8)=0x89504E470D0A1A0A));
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Account_Logos @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 SELECT a.ID Account_ID,a.Row_Version FROM dbo.CRM_Accounts a
 WHERE a.Logo_Data IS NOT NULL AND a.Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,a.ID)=1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Account_Logo @Actor_ID int,@Account_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,ID)=1)
  THROW 51201,N'شعار العميل غير متاح.',1;
 SELECT Logo_Data Image_Data FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Logo_Data IS NOT NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Account_Logo @Actor_ID int,@Account_ID int,@Image_Data varbinary(max),@Version binary(8) AS
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
  IF @Image_Data IS NULL OR DATALENGTH(@Image_Data) NOT BETWEEN 8 AND 2097152 OR SUBSTRING(@Image_Data,1,8)<>0x89504E470D0A1A0A
   THROW 51201,N'الشعار يجب أن يكون صورة PNG صالحة بحجم لا يتجاوز 2 ميجابايت.',1;
  DECLARE @Before xml=(SELECT ID Account_ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@Account_ID FOR XML PATH('logo'),BINARY BASE64,TYPE);
  UPDATE dbo.CRM_Accounts SET Logo_Data=@Image_Data,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@Account_ID;
  DECLARE @After xml=(SELECT ID Account_ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@Account_ID FOR XML PATH('logo'),BINARY BASE64,TYPE);
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
