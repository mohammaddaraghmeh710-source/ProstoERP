-- Copy and verify every existing logo before removing the obsolete table.
IF OBJECT_ID('dbo.CRM_Account_Logos','U') IS NOT NULL
BEGIN
 EXEC(N'UPDATE a SET Logo_Data=l.Image_Data FROM dbo.CRM_Accounts a JOIN dbo.CRM_Account_Logos l ON l.Account_ID=a.ID WHERE a.Logo_Data IS NULL;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Account_Logos l LEFT JOIN dbo.CRM_Accounts a ON a.ID=l.Account_ID WHERE a.ID IS NULL OR a.Logo_Data IS NULL OR DATALENGTH(a.Logo_Data)<>DATALENGTH(l.Image_Data) OR a.Logo_Data<>l.Image_Data) THROW 51990,''Logo copy verification failed.'',1;');
END;
GO
CREATE OR ALTER VIEW dbo.CRM_v_Accounts AS
SELECT t.ID,t.Name_AR,t.Name_EN,t.Account_Type_ID,t.Owner_ID,t.Phone,t.Email,t.Address,t.Country,t.Website,t.Registration_Number,t.Notes,t.Normalized_Name,t.Is_Active,t.Is_Deleted,t.AddedUser,t.AddedDate,t.Modified_User,t.Modified_Date,t.Row_Version,t.Brand_ID,t.Branch_ID, o.FullName_Ar AS Owner_Name, at.Name_AR AS Type_Name, b.Title_Ar AS Brand_Name, br.Title_Ar AS Branch_Name
FROM dbo.CRM_Accounts t LEFT JOIN dbo.UsersMembers o ON o.ID=t.Owner_ID
LEFT JOIN dbo.CRM_Account_Types at ON at.ID=t.Account_Type_ID
LEFT JOIN dbo.Brands b ON b.ID=t.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=t.Branch_ID;
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
DECLARE @Brand_ID int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Brand_ID/text())[1]','nvarchar(max)'))),N''));
IF @Brand_ID IS NULL OR @Brand_ID<=0 THROW 51201,N'العلامة التجارية: هذا الحقل مطلوب وقيمته يجب أن تكون صحيحة.',1;
DECLARE @BranchText nvarchar(max)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Branch_ID/text())[1]','nvarchar(max)'))),N'');
DECLARE @Branch_ID int=TRY_CONVERT(int,@BranchText);
IF @BranchText IS NOT NULL AND (@Branch_ID IS NULL OR @Branch_ID<=0) THROW 51201,N'الفرع: القيمة غير صحيحة.',1;
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
IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH (UPDLOCK,HOLDLOCK) WHERE ID=@Brand_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'العلامة التجارية: العنصر غير متاح أو غير فعال.',1;
IF @Branch_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Branches WITH (UPDLOCK,HOLDLOCK) WHERE ID=@Branch_ID AND BrandID=@Brand_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'الفرع: يجب اختيار فرع فعال تابع للعلامة التجارية المحددة.',1;
IF @Admin=0 BEGIN IF @ID=0 SET @Owner_ID=@Actor_ID; ELSE SELECT @Owner_ID=Owner_ID FROM dbo.CRM_Accounts WHERE ID=@ID; END;
IF @ID=0 BEGIN INSERT dbo.CRM_Accounts([Brand_ID],[Branch_ID],[Name_AR],[Name_EN],[Account_Type_ID],[Owner_ID],[Phone],[Email],[Address],[Country],[Website],[Registration_Number],[Notes],Is_Active,AddedUser) VALUES(@Brand_ID,@Branch_ID,@Name_AR,@Name_EN,@Account_Type_ID,@Owner_ID,@Phone,@Email,@Address,@Country,@Website,@Registration_Number,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Accounts SET [Brand_ID]=@Brand_ID,[Branch_ID]=@Branch_ID,[Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Account_Type_ID]=@Account_Type_ID,[Owner_ID]=@Owner_ID,[Phone]=@Phone,[Email]=@Email,[Address]=@Address,[Country]=@Country,[Website]=@Website,[Registration_Number]=@Registration_Number,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
SET @Scope=@ID;
SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Accounts',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
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
 SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Accounts SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
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
IF OBJECT_ID('dbo.Customer_Dashboard','P') IS NOT NULL EXEC(N'CREATE OR ALTER PROCEDURE dbo.Customer_Dashboard @AccountID int,@Stamp uniqueidentifier,@Section varchar(16)=''profile'' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0)
 THROW 51911,N''انتهت صلاحية الدخول؛ سجل الدخول مجددًا.'',1;
 IF @Section=''profile''
 SELECT a.Name_AR,a.Name_EN,a.Phone,a.Email,t.Name_AR TypeName,b.Title_Ar BrandName,br.Title_Ar BranchName,
 (SELECT COUNT(*) FROM dbo.CRM_Contacts c WHERE c.Account_ID=a.ID AND c.Is_Deleted=0) ContactCount
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 LEFT JOIN dbo.Brands b ON b.ID=a.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=a.Branch_ID WHERE a.ID=@AccountID;
 ELSE IF @Section=''contacts''
 SELECT ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Row_Version FROM dbo.CRM_Contacts WHERE Account_ID=@AccountID AND Is_Deleted=0 ORDER BY Name_AR,ID;
 ELSE IF @Section=''editor''
 SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 ELSE IF @Section=''logo''
 SELECT Logo_Data Image_Data FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Logo_Data IS NOT NULL;
 ELSE THROW 51910,N''الطلب غير متاح.'',1;
END;');
GO
IF OBJECT_ID('dbo.CRM_Account_Logos','U') IS NOT NULL
BEGIN
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects o ON o.object_id=d.referencing_id WHERE d.referenced_id=OBJECT_ID('dbo.CRM_Account_Logos') AND o.parent_object_id<>OBJECT_ID('dbo.CRM_Account_Logos')) OR EXISTS(SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id=OBJECT_ID('dbo.CRM_Account_Logos'))
 THROW 51990,'Unexpected consumer of the old logo table; migration rolled back.',1;
 DROP TABLE dbo.CRM_Account_Logos;
END;
GO
