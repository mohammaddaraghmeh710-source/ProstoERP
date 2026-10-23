IF COL_LENGTH('dbo.CRM_Contacts','Job_Title_EN') IS NULL ALTER TABLE dbo.CRM_Contacts ADD Job_Title_EN nvarchar(200) NULL;
GO
-- Legacy contacts retain NULL English names; both names are required on create/edit.
IF COL_LENGTH('dbo.CRM_Contacts','Name_EN') IS NULL ALTER TABLE dbo.CRM_Contacts ADD Name_EN nvarchar(200) NULL;
GO
CREATE OR ALTER VIEW dbo.CRM_v_Contacts AS
SELECT t.*,a.Name_AR Account_Name FROM dbo.CRM_Contacts t JOIN dbo.CRM_Accounts a ON a.ID=t.Account_ID;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Contacts @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Account_ID int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Account_ID/text())[1]','nvarchar(max)'))),N''));
IF NULLIF(LTRIM(RTRIM(@Data.value('(/row/Account_ID/text())[1]','nvarchar(max)'))),N'') IS NOT NULL AND @Account_ID IS NULL THROW 51201,N'العميل: القيمة غير صحيحة.',1;
IF @Account_ID IS NULL THROW 51201,N'العميل: هذا الحقل مطلوب.',1;
DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم: النص أطول من الحد المسموح.',1;
IF @Name_AR IS NULL THROW 51201,N'الاسم: هذا الحقل مطلوب.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF @Name_EN IS NULL OR LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل الاسم الإنجليزي لجهة الاتصال (حتى 200 حرف).',1;
DECLARE @Job_Title nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'المسمى الوظيفي: النص أطول من الحد المسموح.',1;
IF @Job_Title IS NULL THROW 51201,N'أدخل المسمى الوظيفي بالعربية.',1;
DECLARE @Job_Title_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))),N'');
IF @Job_Title_EN IS NULL OR LEN(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل المسمى الوظيفي بالإنجليزية (حتى 200 حرف).',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N''))>50 THROW 51201,N'الهاتف: النص أطول من الحد المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N''))>254 THROW 51201,N'البريد الإلكتروني: النص أطول من الحد المسموح.',1;
DECLARE @Gender nvarchar(20)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))),N''))>20 THROW 51201,N'الجنس: النص أطول من الحد المسموح.',1;
DECLARE @Notes nvarchar(2000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N''))>2000 THROW 51201,N'ملاحظات: النص أطول من الحد المسموح.',1;
IF @Gender IS NOT NULL AND @Gender NOT IN ('M','F') THROW 51201,N'الجنس غير صحيح.',1;
DECLARE @lock int; EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
IF @lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THEN 1 ELSE 0 END;
IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;
 DECLARE @Active bit=TRY_CONVERT(bit,NULLIF(@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'),''));
 IF @Active IS NULL SET @Active=1;
 DECLARE @Scope int=NULL,@OldScope int=NULL,@Before xml=NULL,@After xml=NULL;
SET @Scope=@Account_ID;
IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51201,N'ليس لديك صلاحية لهذه العملية.',1;
IF @ID<>0 BEGIN
 SELECT @OldScope=Account_ID FROM dbo.CRM_v_Contacts WHERE ID=@ID;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
IF dbo.CRM_CanAccess(@Actor_ID,@OldScope)=0 THROW 51201,N'ليس لديك صلاحية للسجل السابق.',1;
SELECT @Before=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @Account_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Active=1 AND ISNULL(Is_Deleted,0)=0) THROW 51201,N'العميل: العنصر غير متاح أو غير فعال.',1;
IF @ID=0 BEGIN INSERT dbo.CRM_Contacts([Account_ID],[Name_AR],[Name_EN],[Job_Title],[Job_Title_EN],[Phone],[Email],[Gender],[Notes],Is_Active,AddedUser) VALUES(@Account_ID,@Name_AR,@Name_EN,@Job_Title,@Job_Title_EN,@Phone,@Email,@Gender,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Contacts SET [Account_ID]=@Account_ID,[Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Job_Title]=@Job_Title,[Job_Title_EN]=@Job_Title_EN,[Phone]=@Phone,[Email]=@Email,[Gender]=@Gender,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SELECT @After=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Contacts',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
GO
