-- Customer organization and overview. Apply after 001/002/006.
-- Existing customers retain NULL Brand_ID until explicitly assigned; all saves require a brand.
IF COL_LENGTH('dbo.CRM_Accounts','Brand_ID') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Brand_ID int NULL;
IF COL_LENGTH('dbo.CRM_Accounts','Branch_ID') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Branch_ID int NULL;
GO
IF OBJECT_ID('dbo.FK_CRM_Accounts_Brand_ID','F') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT FK_CRM_Accounts_Brand_ID FOREIGN KEY(Brand_ID) REFERENCES dbo.Brands(ID);
IF OBJECT_ID('dbo.FK_CRM_Accounts_Branch_ID','F') IS NULL ALTER TABLE dbo.CRM_Accounts ADD CONSTRAINT FK_CRM_Accounts_Branch_ID FOREIGN KEY(Branch_ID) REFERENCES dbo.Branches(ID);
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
CREATE OR ALTER PROCEDURE dbo.CRM_Dashboard_Counts @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'هذه الصفحة متاحة لمدير النظام فقط.',1;
 SELECT (SELECT COUNT_BIG(*) FROM dbo.CRM_Account_Types WHERE Is_Deleted=0) AS Account_Types,
 (SELECT COUNT_BIG(*) FROM dbo.CRM_Accounts WHERE Is_Deleted=0) AS Accounts,
 (SELECT COUNT_BIG(*) FROM dbo.CRM_Contacts c WHERE c.Is_Deleted=0 AND dbo.CRM_CanAccess(@Actor_ID,c.Account_ID)=1) AS Contacts;
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Activity_Count @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF OBJECT_ID('dbo.CRM_v_Activity','V') IS NOT NULL
 BEGIN
  EXEC sys.sp_executesql N'SELECT COUNT_BIG(*) Activity_Count FROM dbo.CRM_v_Activity l WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1 AND (l.Entity<>N''Customer_Session'' OR EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0))',N'@Actor_ID int',@Actor_ID;
  RETURN;
 END;
 SELECT COUNT_BIG(*) Activity_Count FROM dbo.CRM_Activity_Logs l WHERE dbo.CRM_CanAccess(@Actor_ID,l.Account_ID)=1;
END;
GO
