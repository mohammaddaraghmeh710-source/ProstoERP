-- Supplier accounts reuse CRM identity; coverage does not grant portal access to another brand.
IF COL_LENGTH('dbo.CRM_Account_Types','System_Code') IS NULL ALTER TABLE dbo.CRM_Account_Types ADD System_Code varchar(30) NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Account_Types') AND name='UX_CRM_Account_Types_SystemCode')
 CREATE UNIQUE INDEX UX_CRM_Account_Types_SystemCode ON dbo.CRM_Account_Types(System_Code) WHERE System_Code IS NOT NULL;
IF OBJECT_ID('dbo.CRM_Supplier_Brands','U') IS NULL
 CREATE TABLE dbo.CRM_Supplier_Brands(Account_ID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),Brand_ID int NOT NULL REFERENCES dbo.Brands(ID),AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime2 NOT NULL DEFAULT SYSDATETIME(),CONSTRAINT PK_CRM_Supplier_Brands PRIMARY KEY(Account_ID,Brand_ID));
GO
IF COL_LENGTH('dbo.JobTitle_Items','Supplier_Account_ID') IS NULL ALTER TABLE dbo.JobTitle_Items ADD Supplier_Account_ID int NULL;
GO
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE System_Code='SUPPLIER')
BEGIN
 DECLARE @Actor int=(SELECT TOP(1) ID FROM dbo.UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID);
 IF @Actor IS NULL THROW 51201,N'يجب وجود مدير نظام فعال قبل تهيئة الموردين.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE Normalized_Name=UPPER(N'موردين') AND Is_Deleted=1) THROW 51201,N'نوع الموردين موجود ضمن المحذوفات. راجع النوع قبل الترحيل.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE Normalized_Name=UPPER(N'موردين') AND System_Code IS NULL)
  UPDATE dbo.CRM_Account_Types SET System_Code='SUPPLIER' WHERE Normalized_Name=UPPER(N'موردين');
 ELSE INSERT dbo.CRM_Account_Types(Name_AR,Name_EN,System_Code,AddedUser) VALUES(N'موردين',N'Suppliers','SUPPLIER',@Actor);
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Supplier_Type @Actor_ID int AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'هذه العملية متاحة لمدير النظام فقط.',1;
 SELECT ID FROM dbo.CRM_Account_Types WHERE System_Code='SUPPLIER' AND Is_Deleted=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Supplier_Brand_Options @Actor_ID int,@Account_ID int=0 AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'إدارة علامات المورد متاحة لمدير النظام فقط.',1;
 SELECT b.ID Brand_ID,b.Title_Ar Name_AR,CONVERT(bit,CASE WHEN b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 THEN 1 ELSE 0 END) Is_Active,CONVERT(bit,CASE WHEN s.Brand_ID IS NOT NULL THEN 1 ELSE 0 END) Is_Selected
 FROM dbo.Brands b LEFT JOIN dbo.CRM_Supplier_Brands s ON s.Brand_ID=b.ID AND s.Account_ID=@Account_ID
 WHERE (b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR s.Brand_ID IS NOT NULL ORDER BY b.Title_Ar,b.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Supplier_Options @Actor_ID int,@Current_Account_ID int=NULL,@Include_Unavailable bit=0 AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'اختيار موردي الأدوات متاح لمدير النظام فقط.',1;
 SELECT a.ID,a.Name_AR,a.Name_EN,CONVERT(bit,CASE WHEN a.Is_Active=1 AND a.Is_Deleted=0 AND t.Is_Active=1 AND t.Is_Deleted=0 THEN 1 ELSE 0 END) Is_Available,
  ISNULL((SELECT STRING_AGG(CONVERT(varchar(max),s.Brand_ID),',') FROM dbo.CRM_Supplier_Brands s JOIN dbo.Brands b ON b.ID=s.Brand_ID WHERE s.Account_ID=a.ID AND ((b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR a.ID=@Current_Account_ID OR @Include_Unavailable=1)),'') Brand_IDs
 FROM dbo.CRM_Accounts a JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 WHERE t.System_Code='SUPPLIER' AND ((a.Is_Deleted=0 AND (@Include_Unavailable=1 OR (a.Is_Active=1 AND t.Is_Active=1 AND t.Is_Deleted=0))) OR a.ID=@Current_Account_ID)
 ORDER BY a.Name_AR,a.ID;
END;
GO
CREATE OR ALTER VIEW dbo.CRM_v_Accounts AS
SELECT t.ID,t.Name_AR,t.Name_EN,t.Account_Type_ID,t.Owner_ID,t.Phone,t.Email,t.Address,t.Country,t.Website,t.Registration_Number,t.Notes,t.Normalized_Name,t.Is_Active,t.Is_Deleted,t.AddedUser,t.AddedDate,t.Modified_User,t.Modified_Date,t.Row_Version,t.Brand_ID,t.Branch_ID, o.FullName_Ar AS Owner_Name, at.Name_AR AS Type_Name, b.Title_Ar AS Brand_Name, br.Title_Ar AS Branch_Name,CONVERT(bit,CASE WHEN at.System_Code='SUPPLIER' THEN 1 ELSE 0 END) Is_Supplier, (SELECT COUNT(*) FROM dbo.CRM_Supplier_Brands sb WHERE sb.Account_ID=t.ID) Supplier_Brand_Count, (SELECT STRING_AGG(CONVERT(nvarchar(max),bb.Title_Ar),N'، ') FROM dbo.CRM_Supplier_Brands sb JOIN dbo.Brands bb ON bb.ID=sb.Brand_ID WHERE sb.Account_ID=t.ID) Supplier_Brand_Names_AR,(SELECT STRING_AGG(CONVERT(nvarchar(max),bb.Title_En),N', ') FROM dbo.CRM_Supplier_Brands sb JOIN dbo.Brands bb ON bb.ID=sb.Brand_ID WHERE sb.Account_ID=t.ID) Supplier_Brand_Names_EN
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
SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version,(SELECT sb.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN FROM dbo.CRM_Supplier_Brands sb JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE sb.Account_ID=@ID ORDER BY sb.Brand_ID FOR XML PATH('Brand'),ROOT('Supplier_Brands'),TYPE) FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @Account_Type_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@Account_Type_ID AND Is_Active=1 AND ISNULL(Is_Deleted,0)=0) AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@ID AND Account_Type_ID=@Account_Type_ID) THROW 51201,N'نوع العميل: العنصر غير متاح أو غير فعال.',1;
DECLARE @Supplier bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@Account_Type_ID AND System_Code='SUPPLIER' AND Is_Deleted=0) THEN 1 ELSE 0 END;
DECLARE @OldType int=(SELECT Account_Type_ID FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID);
DECLARE @WasSupplier bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@OldType AND System_Code='SUPPLIER') THEN 1 ELSE 0 END;
DECLARE @BrandData bit=@Data.exist('/row/Supplier_Brands');
IF @Admin=0 AND (@BrandData=1 OR (@Supplier<>@WasSupplier)) THROW 51200,N'تغيير نوع المورد وعلامات التوريد متاح لمدير النظام فقط.',1;
IF @WasSupplier=1 AND @Supplier=0 AND EXISTS(SELECT 1 FROM dbo.JobTitle_Items WHERE Supplier_Account_ID=@ID) THROW 51201,N'لا يمكن تغيير نوع مورد مرتبط بأدوات.',1;
DECLARE @Coverage table(ID int PRIMARY KEY);
IF @Supplier=1 BEGIN
 IF @BrandData=1 BEGIN
  IF EXISTS(SELECT 1 FROM @Data.nodes('/row/Supplier_Brands/Brand') x(n) WHERE TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) IS NULL OR TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)'))<=0) THROW 51201,N'العلامة التجارية للمورد غير صحيحة.',1;
  INSERT @Coverage SELECT DISTINCT TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) FROM @Data.nodes('/row/Supplier_Brands/Brand') x(n);
 END ELSE INSERT @Coverage SELECT Brand_ID FROM dbo.CRM_Supplier_Brands WHERE Account_ID=@ID;
 IF NOT EXISTS(SELECT 1 FROM @Coverage) THROW 51201,N'اختر علامة تجارية واحدة على الأقل للمورد.',1;
 IF EXISTS(SELECT 1 FROM @Coverage c LEFT JOIN dbo.Brands b WITH(UPDLOCK,HOLDLOCK) ON b.ID=c.ID WHERE b.ID IS NULL OR ((ISNULL(b.IsActive,0)=0 OR ISNULL(b.IsDeleted,0)=1) AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Supplier_Brands s WHERE s.Account_ID=@ID AND s.Brand_ID=c.ID))) THROW 51201,N'علامة توريد غير متاحة أو غير فعالة.',1;
 IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID WHERE i.Supplier_Account_ID=@ID AND NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=b.BrandID)) THROW 51201,N'لا يمكن إزالة علامة تجارية للمورد مرتبطة بأدوات.',1;
END;
IF @Owner_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Owner_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'مسؤول العميل: العنصر غير متاح أو غير فعال.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH (UPDLOCK,HOLDLOCK) WHERE ID=@Brand_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'العلامة التجارية: العنصر غير متاح أو غير فعال.',1;
IF @Branch_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Branches WITH (UPDLOCK,HOLDLOCK) WHERE ID=@Branch_ID AND BrandID=@Brand_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'الفرع: يجب اختيار فرع فعال تابع للعلامة التجارية المحددة.',1;
IF @Admin=0 BEGIN IF @ID=0 SET @Owner_ID=@Actor_ID; ELSE SELECT @Owner_ID=Owner_ID FROM dbo.CRM_Accounts WHERE ID=@ID; END;
IF @ID=0 BEGIN INSERT dbo.CRM_Accounts([Brand_ID],[Branch_ID],[Name_AR],[Name_EN],[Account_Type_ID],[Owner_ID],[Phone],[Email],[Address],[Country],[Website],[Registration_Number],[Notes],Is_Active,AddedUser) VALUES(@Brand_ID,@Branch_ID,@Name_AR,@Name_EN,@Account_Type_ID,@Owner_ID,@Phone,@Email,@Address,@Country,@Website,@Registration_Number,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Accounts SET [Brand_ID]=@Brand_ID,[Branch_ID]=@Branch_ID,[Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Account_Type_ID]=@Account_Type_ID,[Owner_ID]=@Owner_ID,[Phone]=@Phone,[Email]=@Email,[Address]=@Address,[Country]=@Country,[Website]=@Website,[Registration_Number]=@Registration_Number,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
DELETE sb FROM dbo.CRM_Supplier_Brands sb WHERE sb.Account_ID=@ID AND NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=sb.Brand_ID);
IF @Supplier=1 INSERT dbo.CRM_Supplier_Brands(Account_ID,Brand_ID,AddedUser) SELECT @ID,c.ID,@Actor_ID FROM @Coverage c WHERE NOT EXISTS(SELECT 1 FROM dbo.CRM_Supplier_Brands s WHERE s.Account_ID=@ID AND s.Brand_ID=c.ID);
SET @Scope=@ID;
SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version,(SELECT sb.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN FROM dbo.CRM_Supplier_Brands sb JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE sb.Account_ID=@ID ORDER BY sb.Brand_ID FOR XML PATH('Brand'),ROOT('Supplier_Brands'),TYPE) FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Accounts',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
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
 IF EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@ID AND System_Code='SUPPLIER') THROW 51201,N'نوع الموردين مستخدم من النظام ولا يمكن حذفه. يمكن إيقافه.',1;
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
 IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items WHERE Supplier_Account_ID=@ID) THROW 51201,N'لا يمكن حذف مورد مرتبط بأدوات. يمكن إيقافه.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Contacts WHERE Account_ID=@ID AND Is_Deleted=0) THROW 51201,N'لا يمكن حذف عميل لديه جهات اتصال. احذف جهات الاتصال أو انقلها إلى عميل آخر أولًا.',1;
 SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
 UPDATE dbo.CRM_Accounts SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); SET @Found=1;
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
