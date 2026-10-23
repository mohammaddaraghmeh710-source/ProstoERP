SET ANSI_NULLS ON;SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Account_Types @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم: النص أطول من الحد المسموح.',1;
IF @Name_AR IS NULL THROW 51201,N'الاسم: هذا الحقل مطلوب.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم الإنجليزي: النص أطول من الحد المسموح.',1;
DECLARE @Notes nvarchar(2000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N''))>2000 THROW 51201,N'ملاحظات: النص أطول من الحد المسموح.',1;
DECLARE @lock int; EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
IF @lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THEN 1 ELSE 0 END;
IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;
 DECLARE @Active bit=TRY_CONVERT(bit,NULLIF(@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'),''));
 IF @Active IS NULL SET @Active=1;
 DECLARE @Scope int=NULL,@OldScope int=NULL,@Before xml=NULL,@After xml=NULL;
SET @Scope=NULL;
IF @Admin=0 THROW 51201,N'ليس لديك صلاحية لهذه العملية.',1;
IF @ID<>0 BEGIN
 SELECT @OldScope=NULL FROM dbo.CRM_v_Account_Types WHERE ID=@ID;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
SELECT @Before=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @ID=0 BEGIN INSERT dbo.CRM_Account_Types([Name_AR],[Name_EN],[Notes],Is_Active,AddedUser) VALUES(@Name_AR,@Name_EN,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Account_Types SET [Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SELECT @After=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Account_Types',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Account_Types WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Contract_Types @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم: النص أطول من الحد المسموح.',1;
IF @Name_AR IS NULL THROW 51201,N'الاسم: هذا الحقل مطلوب.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم الإنجليزي: النص أطول من الحد المسموح.',1;
DECLARE @Notes nvarchar(2000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N''))>2000 THROW 51201,N'ملاحظات: النص أطول من الحد المسموح.',1;
DECLARE @lock int; EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
IF @lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THEN 1 ELSE 0 END;
IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;
 DECLARE @Active bit=TRY_CONVERT(bit,NULLIF(@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'),''));
 IF @Active IS NULL SET @Active=1;
 DECLARE @Scope int=NULL,@OldScope int=NULL,@Before xml=NULL,@After xml=NULL;
SET @Scope=NULL;
IF @Admin=0 THROW 51201,N'ليس لديك صلاحية لهذه العملية.',1;
IF @ID<>0 BEGIN
 SELECT @OldScope=NULL FROM dbo.CRM_v_Contract_Types WHERE ID=@ID;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contract_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
SELECT @Before=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @ID=0 BEGIN INSERT dbo.CRM_Contract_Types([Name_AR],[Name_EN],[Notes],Is_Active,AddedUser) VALUES(@Name_AR,@Name_EN,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Contract_Types SET [Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SELECT @After=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Contract_Types',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Contract_Types WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Payment_Methods @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم: النص أطول من الحد المسموح.',1;
IF @Name_AR IS NULL THROW 51201,N'الاسم: هذا الحقل مطلوب.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم الإنجليزي: النص أطول من الحد المسموح.',1;
DECLARE @Notes nvarchar(2000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N''))>2000 THROW 51201,N'ملاحظات: النص أطول من الحد المسموح.',1;
DECLARE @lock int; EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
IF @lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THEN 1 ELSE 0 END;
IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;
 DECLARE @Active bit=TRY_CONVERT(bit,NULLIF(@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'),''));
 IF @Active IS NULL SET @Active=1;
 DECLARE @Scope int=NULL,@OldScope int=NULL,@Before xml=NULL,@After xml=NULL;
SET @Scope=NULL;
IF @Admin=0 THROW 51201,N'ليس لديك صلاحية لهذه العملية.',1;
IF @ID<>0 BEGIN
 SELECT @OldScope=NULL FROM dbo.CRM_v_Payment_Methods WHERE ID=@ID;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Payment_Methods WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
SELECT @Before=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @ID=0 BEGIN INSERT dbo.CRM_Payment_Methods([Name_AR],[Name_EN],[Notes],Is_Active,AddedUser) VALUES(@Name_AR,@Name_EN,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Payment_Methods SET [Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SELECT @After=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Payment_Methods',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Payment_Methods WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_Accounts @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'اسم العميل: النص أطول من الحد المسموح.',1;
IF @Name_AR IS NULL THROW 51201,N'اسم العميل: هذا الحقل مطلوب.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N''))>200 THROW 51201,N'الاسم الإنجليزي: النص أطول من الحد المسموح.',1;
DECLARE @Account_Type_ID int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Account_Type_ID/text())[1]','nvarchar(max)'))),N''));
IF NULLIF(LTRIM(RTRIM(@Data.value('(/row/Account_Type_ID/text())[1]','nvarchar(max)'))),N'') IS NOT NULL AND @Account_Type_ID IS NULL THROW 51201,N'نوع العميل: القيمة غير صحيحة.',1;
DECLARE @Owner_ID int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Owner_ID/text())[1]','nvarchar(max)'))),N''));
IF NULLIF(LTRIM(RTRIM(@Data.value('(/row/Owner_ID/text())[1]','nvarchar(max)'))),N'') IS NOT NULL AND @Owner_ID IS NULL THROW 51201,N'مسؤول العميل: القيمة غير صحيحة.',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N''))>50 THROW 51201,N'هاتف الشركة: النص أطول من الحد المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N''))>254 THROW 51201,N'بريد الشركة: النص أطول من الحد المسموح.',1;
DECLARE @Address nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))),N''))>500 THROW 51201,N'العنوان: النص أطول من الحد المسموح.',1;
DECLARE @Country nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))),N''))>100 THROW 51201,N'البلد: النص أطول من الحد المسموح.',1;
DECLARE @Website nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))),N''))>500 THROW 51201,N'الموقع الإلكتروني: النص أطول من الحد المسموح.',1;
DECLARE @Registration_Number nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))),N''))>100 THROW 51201,N'رقم تسجيل الشركة: النص أطول من الحد المسموح.',1;
DECLARE @Notes nvarchar(2000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N'');
IF LEN(NULLIF(LTRIM(RTRIM(@Data.value('(/row/Notes/text())[1]','nvarchar(max)'))),N''))>2000 THROW 51201,N'ملاحظات: النص أطول من الحد المسموح.',1;
DECLARE @lock int; EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
IF @lock<0 THROW 51201,N'السجل مشغول، أعد المحاولة.',1;
DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THEN 1 ELSE 0 END;
IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;
 DECLARE @Active bit=TRY_CONVERT(bit,NULLIF(@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'),''));
 IF @Active IS NULL SET @Active=1;
 DECLARE @Scope int=NULL,@OldScope int=NULL,@Before xml=NULL,@After xml=NULL;
SET @Scope=@ID;
IF (@ID=0 AND @Admin=0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a JOIN dbo.UsersMembers u ON u.ID=a.Owner_ID WHERE a.Owner_ID=@Actor_ID AND a.Is_Deleted=0 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0)) OR (@ID<>0 AND dbo.CRM_CanAccess(@Actor_ID,@ID)=0) THROW 51201,N'ليس لديك صلاحية لهذه العملية.',1;
IF @ID<>0 BEGIN
 SELECT @OldScope=ID FROM dbo.CRM_v_Accounts WHERE ID=@ID;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'تم تعديل السجل أو إلغاؤه. حدّث الصفحة قبل الحفظ.',1;
IF dbo.CRM_CanAccess(@Actor_ID,@OldScope)=0 THROW 51201,N'ليس لديك صلاحية للسجل السابق.',1;
SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @Account_Type_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@Account_Type_ID AND Is_Active=1 AND ISNULL(Is_Deleted,0)=0) THROW 51201,N'نوع العميل: العنصر غير متاح أو غير فعال.',1;
IF @Owner_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Owner_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'مسؤول العميل: العنصر غير متاح أو غير فعال.',1;
IF @Admin=0 BEGIN IF @ID=0 SET @Owner_ID=@Actor_ID; ELSE SELECT @Owner_ID=Owner_ID FROM dbo.CRM_Accounts WHERE ID=@ID; END;
IF @ID=0 BEGIN INSERT dbo.CRM_Accounts([Name_AR],[Name_EN],[Account_Type_ID],[Owner_ID],[Phone],[Email],[Address],[Country],[Website],[Registration_Number],[Notes],Is_Active,AddedUser) VALUES(@Name_AR,@Name_EN,@Account_Type_ID,@Owner_ID,@Phone,@Email,@Address,@Country,@Website,@Registration_Number,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Accounts SET [Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Account_Type_ID]=@Account_Type_ID,[Owner_ID]=@Owner_ID,[Phone]=@Phone,[Email]=@Email,[Address]=@Address,[Country]=@Country,[Website]=@Website,[Registration_Number]=@Registration_Number,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SET @Scope=@ID;
SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Accounts',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
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
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Options @Actor_ID int,@Kind nvarchar(30) AS
BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) THROW 51200,N'غير مسموح.',1;
 IF @Kind='Users' SELECT ID,FullName_Ar AS Name_AR FROM dbo.UsersMembers WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (ID=@Actor_ID OR dbo.CRM_CanAccess(@Actor_ID,NULL)=1) ORDER BY FullName_Ar;
 IF @Kind='Brands' SELECT ID,Title_Ar AS Name_AR FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Kind='Branches' SELECT ID,CONCAT((SELECT Title_Ar FROM dbo.Brands WHERE ID=b.BrandID),N' / ',Title_Ar) AS Name_AR,BrandID FROM dbo.Branches b WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_Logs @Actor_ID int,@User_ID int=NULL,@From date=NULL,@To date=NULL,@Entity nvarchar(80)=NULL,@Account_ID int=NULL AS
BEGIN SET NOCOUNT ON;
 IF OBJECT_ID('dbo.CRM_v_Activity','V') IS NOT NULL BEGIN EXEC sys.sp_executesql N'SELECT * FROM dbo.CRM_v_Activity l WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1 AND (l.Entity<>N''Customer_Session'' OR EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) AND (@User_ID IS NULL OR l.Actor_ID=@User_ID) AND (@From IS NULL OR l.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,l.AddedDate)<=@To) AND (@Entity IS NULL OR l.Entity=@Entity) AND (@Account_ID IS NULL OR l.Account_ID=@Account_ID) ORDER BY l.AddedDate DESC,l.ID DESC;',N'@Actor_ID int,@User_ID int,@From date,@To date,@Entity nvarchar(80),@Account_ID int',@Actor_ID,@User_ID,@From,@To,@Entity,@Account_ID;RETURN;END;
 SELECT l.*,u.FullName_Ar AS User_Name,a.Name_AR AS Account_Name,CONVERT(nvarchar(40),N'إدارة النظام') Source_Name FROM dbo.CRM_Activity_Logs l JOIN dbo.UsersMembers u ON u.ID=l.Actor_ID LEFT JOIN dbo.CRM_Accounts a ON a.ID=l.Account_ID
 WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1 AND (@User_ID IS NULL OR l.Actor_ID=@User_ID) AND (@From IS NULL OR l.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,l.AddedDate)<=@To) AND (@Entity IS NULL OR l.Entity=@Entity) AND (@Account_ID IS NULL OR l.Account_ID=@Account_ID) ORDER BY l.ID DESC;
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Set_Active @Actor_ID int,@Entity nvarchar(80),@ID int,@Is_Active bit,@Version binary(8) AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @lock int;EXEC @lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @lock<0 THROW 51201,N'أعد المحاولة.',1;
 DECLARE @Scope int,@Before xml,@After xml,@Found bit=0;
 IF @Entity=N'Account_Types' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Account_Types WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Account_Types SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Account_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Contract_Types' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Contract_Types WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contract_Types WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Contract_Types SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Contract_Types WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Payment_Methods' BEGIN
 SELECT @Scope=NULL FROM dbo.CRM_Payment_Methods WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Payment_Methods WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Payment_Methods SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Payment_Methods WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Accounts' BEGIN
 SELECT @Scope=ID FROM dbo.CRM_Accounts WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Accounts SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Entity=N'Contacts' BEGIN
 SELECT @Scope=Account_ID FROM dbo.CRM_Contacts WHERE ID=@ID;
 IF dbo.CRM_CanAccess(@Actor_ID,@Scope)=0 THROW 51200,N'لا تملك صلاحية هذا السجل.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير. حدّث الصفحة وأعد المحاولة.',1;
 SELECT @Before=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Contacts SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT * FROM dbo.CRM_Contacts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
 END;
 IF @Found=0 THROW 51201,N'نوع السجل غير صحيح.',1;
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,@Entity,@ID,CASE WHEN @Is_Active=1 THEN N'تفعيل' ELSE N'إيقاف' END,@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Log_Read @Actor_ID int,@Entity nvarchar(80),@ID int=NULL,@Account_ID int=NULL AS
BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor_ID AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND (u.Type=1 OR EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Owner_ID=u.ID AND a.Is_Deleted=0))) RETURN;
 IF @Account_ID IS NOT NULL AND dbo.CRM_CanAccess(@Actor_ID,@Account_ID)=0 RETURN;
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action) VALUES(@Actor_ID,@Account_ID,@Entity,@ID,CASE WHEN @ID IS NULL THEN N'استعراض القائمة' ELSE N'مشاهدة' END);
END

GO
