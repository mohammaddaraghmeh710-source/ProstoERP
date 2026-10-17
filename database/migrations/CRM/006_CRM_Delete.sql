-- Soft deletion follows the existing administration modules and preserves audit history.
CREATE OR ALTER PROCEDURE dbo.CRM_Delete @Actor_ID int,@Entity nvarchar(80),@ID int,@Version binary(8) AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @lock int;EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @lock<0 THROW 51201,N'أعد المحاولة.',1;
 DECLARE @Scope int=NULL,@Before xml,@After xml,@Found bit=0;
 IF @Entity=N'Account_Types' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Account_Types WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف. حدّث الصفحة وأعد المحاولة.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE Account_Type_ID=@ID AND Is_Deleted=0) THROW 51201,N'لا يمكن حذف نوع عميل مرتبط بعملاء. عدّل ارتباط العملاء أولًا أو أوقف النوع.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Account_Types SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Contract_Types' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Contract_Types WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contract_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Contract_Types SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Payment_Methods' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Payment_Methods WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Payment_Methods WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Payment_Methods SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Accounts' BEGIN
 SELECT @Scope=ID FROM dbo.CRM_Accounts WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف. حدّث الصفحة وأعد المحاولة.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE Account_ID=@ID AND Is_Deleted=0) THROW 51201,N'لا يمكن حذف عميل لديه جهات اتصال. احذف جهات الاتصال أو انقلها إلى عميل آخر أولًا.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Accounts SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Contacts' BEGIN
 SELECT @Scope=Account_ID FROM dbo.CRM_Contacts WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Contacts SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Found=0 THROW 51201,N'نوع السجل غير صحيح.',1;
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,@Entity,@ID,N'حذف',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END
GO
