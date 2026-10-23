-- Canonical many-brand / optional many-branch CRM account membership.
-- Legacy scalar columns and supplier coverage remain compatibility projections only.
IF OBJECT_ID('dbo.CRM_Account_Brands','U') IS NULL BEGIN
 IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts a LEFT JOIN dbo.Brands b ON b.ID=a.Brand_ID WHERE a.Brand_ID IS NOT NULL AND b.ID IS NULL) THROW 51201,N'يوجد عميل مرتبط بعلامة غير موجودة؛ راجع الربط قبل الترحيل.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts a LEFT JOIN dbo.Branches b ON b.ID=a.Branch_ID WHERE a.Branch_ID IS NOT NULL AND (b.ID IS NULL OR a.Brand_ID IS NULL OR b.BrandID<>a.Brand_ID)) THROW 51201,N'يوجد فرع عميل غير تابع لعلامته؛ راجع الربط قبل الترحيل.',1;
 CREATE TABLE dbo.CRM_Account_Brands(Account_ID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),Brand_ID int NOT NULL REFERENCES dbo.Brands(ID),AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime2 NOT NULL DEFAULT SYSDATETIME(),CONSTRAINT PK_CRM_Account_Brands PRIMARY KEY(Account_ID,Brand_ID));
 INSERT dbo.CRM_Account_Brands(Account_ID,Brand_ID,AddedUser)
 SELECT a.ID,a.Brand_ID,a.AddedUser FROM dbo.CRM_Accounts a WHERE a.Brand_ID IS NOT NULL
 UNION SELECT sb.Account_ID,sb.Brand_ID,sb.AddedUser FROM dbo.CRM_Supplier_Brands sb WHERE NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.ID=sb.Account_ID AND a.Brand_ID=sb.Brand_ID);
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Branches') AND name='UX_Branches_ID_BrandID') CREATE UNIQUE INDEX UX_Branches_ID_BrandID ON dbo.Branches(ID,BrandID);
IF OBJECT_ID('dbo.CRM_Account_Branches','U') IS NULL BEGIN
 CREATE TABLE dbo.CRM_Account_Branches(Account_ID int NOT NULL,Brand_ID int NOT NULL,Branch_ID int NOT NULL,AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime2 NOT NULL DEFAULT SYSDATETIME(),CONSTRAINT PK_CRM_Account_Branches PRIMARY KEY(Account_ID,Branch_ID),CONSTRAINT FK_CRM_Account_Branches_Membership FOREIGN KEY(Account_ID,Brand_ID) REFERENCES dbo.CRM_Account_Brands(Account_ID,Brand_ID),CONSTRAINT FK_CRM_Account_Branches_Branch FOREIGN KEY(Branch_ID,Brand_ID) REFERENCES dbo.Branches(ID,BrandID));
 INSERT dbo.CRM_Account_Branches(Account_ID,Brand_ID,Branch_ID,AddedUser) SELECT ID,Brand_ID,Branch_ID,AddedUser FROM dbo.CRM_Accounts WHERE Branch_ID IS NOT NULL;
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Account_Brands') AND name='IX_CRM_Account_Brands_Brand') CREATE INDEX IX_CRM_Account_Brands_Brand ON dbo.CRM_Account_Brands(Brand_ID,Account_ID);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Account_Branches') AND name='IX_CRM_Account_Branches_Branch') CREATE INDEX IX_CRM_Account_Branches_Branch ON dbo.CRM_Account_Branches(Branch_ID,Account_ID);
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Account_Organization @Actor_ID int,@Account_ID int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF @Account_ID<0 OR (@Account_ID>0 AND dbo.CRM_CanAccess(@Actor_ID,@Account_ID)=0) OR (@Account_ID=0 AND dbo.CRM_CanAccess(@Actor_ID,NULL)=0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a JOIN dbo.UsersMembers u ON u.ID=a.Owner_ID WHERE a.Owner_ID=@Actor_ID AND a.Is_Deleted=0 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0)) THROW 51200,N'ليس لديك صلاحية لهذه العملية.',1;
 SELECT 'Brand' Kind,b.ID,b.ID Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN,b.Title_Ar BrandName,CONVERT(bit,CASE WHEN b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 THEN 1 ELSE 0 END) Is_Active,CONVERT(bit,CASE WHEN ab.Brand_ID IS NOT NULL THEN 1 ELSE 0 END) Is_Selected
 FROM dbo.Brands b LEFT JOIN dbo.CRM_Account_Brands ab ON ab.Brand_ID=b.ID AND ab.Account_ID=@Account_ID
 WHERE (b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR ab.Brand_ID IS NOT NULL
 UNION ALL
 SELECT 'Branch',br.ID,br.BrandID,br.Title_Ar,br.Title_En,b.Title_Ar,CONVERT(bit,CASE WHEN br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 THEN 1 ELSE 0 END),CONVERT(bit,CASE WHEN abr.Branch_ID IS NOT NULL THEN 1 ELSE 0 END)
 FROM dbo.Branches br JOIN dbo.Brands b ON b.ID=br.BrandID LEFT JOIN dbo.CRM_Account_Branches abr ON abr.Branch_ID=br.ID AND abr.Account_ID=@Account_ID
 WHERE (br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR abr.Branch_ID IS NOT NULL ORDER BY Kind,BrandName,Name_AR,ID;
END;
GO
CREATE OR ALTER VIEW dbo.CRM_v_Accounts AS
SELECT t.ID,t.Name_AR,t.Name_EN,t.Account_Type_ID,t.Owner_ID,t.Phone,t.Email,t.Address,t.Country,t.Website,t.Registration_Number,t.Notes,t.Normalized_Name,t.Is_Active,t.Is_Deleted,t.AddedUser,t.AddedDate,t.Modified_User,t.Modified_Date,t.Row_Version,t.Brand_ID,t.Branch_ID,o.FullName_Ar Owner_Name,at.Name_AR Type_Name,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),b.Title_Ar),N'، ') WITHIN GROUP(ORDER BY ab.Brand_ID) FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID WHERE ab.Account_ID=t.ID) Brand_Name,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),b.Title_Ar+N' / '+br.Title_Ar),N'، ') WITHIN GROUP(ORDER BY abr.Brand_ID,abr.Branch_ID) FROM dbo.CRM_Account_Branches abr JOIN dbo.Brands b ON b.ID=abr.Brand_ID JOIN dbo.Branches br ON br.ID=abr.Branch_ID WHERE abr.Account_ID=t.ID) Branch_Name,
 ISNULL((SELECT STRING_AGG(CONVERT(varchar(max),ab.Brand_ID),',') WITHIN GROUP(ORDER BY ab.Brand_ID) FROM dbo.CRM_Account_Brands ab WHERE ab.Account_ID=t.ID),'') Brand_IDs,
 ISNULL((SELECT STRING_AGG(CONVERT(varchar(max),abr.Branch_ID),',') WITHIN GROUP(ORDER BY abr.Brand_ID,abr.Branch_ID) FROM dbo.CRM_Account_Branches abr WHERE abr.Account_ID=t.ID),'') Branch_IDs,
 CONVERT(bit,CASE WHEN at.System_Code='SUPPLIER' THEN 1 ELSE 0 END) Is_Supplier,
 (SELECT COUNT(*) FROM dbo.CRM_Account_Brands ab WHERE ab.Account_ID=t.ID) Supplier_Brand_Count,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),b.Title_Ar),N'، ') FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID WHERE ab.Account_ID=t.ID) Supplier_Brand_Names_AR,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),b.Title_En),N', ') FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID WHERE ab.Account_ID=t.ID) Supplier_Brand_Names_EN
FROM dbo.CRM_Accounts t LEFT JOIN dbo.UsersMembers o ON o.ID=t.Owner_ID LEFT JOIN dbo.CRM_Account_Types at ON at.ID=t.Account_Type_ID;
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
IF @Data.exist('/row/Brand_ID')=1 AND @Brand_ID IS NOT NULL AND @Brand_ID<=0 THROW 51201,N'العلامة التجارية غير صحيحة.',1;
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
SELECT @Before=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version,(SELECT sb.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN FROM dbo.CRM_Account_Brands sb JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE sb.Account_ID=@ID ORDER BY sb.Brand_ID FOR XML PATH('Brand'),ROOT('Account_Brands'),TYPE),(SELECT br.Branch_ID,br.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN,bb.Title_Ar BrandName FROM dbo.CRM_Account_Branches br JOIN dbo.Branches b ON b.ID=br.Branch_ID JOIN dbo.Brands bb ON bb.ID=br.Brand_ID WHERE br.Account_ID=@ID ORDER BY br.Brand_ID,br.Branch_ID FOR XML PATH('Branch'),ROOT('Account_Branches'),TYPE) FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE); END;
IF @Account_Type_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@Account_Type_ID AND Is_Active=1 AND ISNULL(Is_Deleted,0)=0) AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@ID AND Account_Type_ID=@Account_Type_ID) THROW 51201,N'نوع العميل: العنصر غير متاح أو غير فعال.',1;
DECLARE @Supplier bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@Account_Type_ID AND System_Code='SUPPLIER' AND Is_Deleted=0) THEN 1 ELSE 0 END;
DECLARE @OldType int=(SELECT Account_Type_ID FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID);
DECLARE @WasSupplier bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WHERE ID=@OldType AND System_Code='SUPPLIER') THEN 1 ELSE 0 END;
DECLARE @BrandData bit=CASE WHEN @Data.exist('/row/Account_Brands')=1 OR @Data.exist('/row/Supplier_Brands')=1 THEN 1 ELSE 0 END;
IF @Admin=0 AND (@Supplier<>@WasSupplier OR ((@Supplier=1 OR @WasSupplier=1) AND @BrandData=1)) THROW 51200,N'تغيير نوع المورد وعلاماته متاح لمدير النظام فقط.',1;
IF @WasSupplier=1 AND @Supplier=0 AND EXISTS(SELECT 1 FROM dbo.JobTitle_Items WHERE Supplier_Account_ID=@ID) THROW 51201,N'لا يمكن تغيير نوع مورد مرتبط بأدوات.',1;
DECLARE @Coverage table(ID int PRIMARY KEY);
IF @Data.exist('/row/Account_Brands')=1 BEGIN
 IF EXISTS(SELECT 1 FROM @Data.nodes('/row/Account_Brands/Brand') x(n) WHERE TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) IS NULL OR TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)'))<=0) THROW 51201,N'العلامة التجارية غير صحيحة.',1;
 INSERT @Coverage SELECT DISTINCT TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) FROM @Data.nodes('/row/Account_Brands/Brand') x(n);
END ELSE BEGIN
 IF @Brand_ID IS NOT NULL INSERT @Coverage VALUES(@Brand_ID);
 IF @Data.exist('/row/Supplier_Brands')=1 BEGIN
  IF @Supplier=0 THROW 51201,N'علامات المورد غير صالحة لهذا النوع.',1;
  IF EXISTS(SELECT 1 FROM @Data.nodes('/row/Supplier_Brands/Brand') x(n) WHERE TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) IS NULL OR TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)'))<=0) THROW 51201,N'علامة المورد غير صحيحة.',1;
  INSERT @Coverage SELECT DISTINCT TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) FROM @Data.nodes('/row/Supplier_Brands/Brand') x(n) WHERE NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')));
 END ELSE IF @Data.exist('/row/Brand_ID')=0 INSERT @Coverage SELECT Brand_ID FROM dbo.CRM_Account_Brands WHERE Account_ID=@ID;
END;
IF NOT EXISTS(SELECT 1 FROM @Coverage) THROW 51201,N'اختر علامة تجارية واحدة على الأقل للعميل.',1;
IF EXISTS(SELECT 1 FROM @Coverage c LEFT JOIN dbo.Brands b WITH(UPDLOCK,HOLDLOCK) ON b.ID=c.ID WHERE b.ID IS NULL OR ((ISNULL(b.IsActive,0)=0 OR ISNULL(b.IsDeleted,0)=1) AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands s WHERE s.Account_ID=@ID AND s.Brand_ID=c.ID))) THROW 51201,N'علامة تجارية غير متاحة أو غير فعالة.',1;
DECLARE @Branches table(ID int PRIMARY KEY,Brand_ID int NOT NULL);
IF @Data.exist('/row/Account_Branches')=1 BEGIN
 IF EXISTS(SELECT 1 FROM @Data.nodes('/row/Account_Branches/Branch') x(n) WHERE TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')) IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Branches b WHERE b.ID=TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)')))) THROW 51201,N'الفرع غير صحيح.',1;
 INSERT @Branches SELECT DISTINCT b.ID,b.BrandID FROM @Data.nodes('/row/Account_Branches/Branch') x(n) JOIN dbo.Branches b WITH(UPDLOCK,HOLDLOCK) ON b.ID=TRY_CONVERT(int,x.n.value('@ID','nvarchar(30)'));
END ELSE IF @Data.exist('/row/Branch_ID')=1 BEGIN
 IF @Branch_ID IS NOT NULL BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Branches WHERE ID=@Branch_ID) THROW 51201,N'الفرع غير صحيح.',1;
  INSERT @Branches SELECT ID,BrandID FROM dbo.Branches WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Branch_ID;
 END;
END ELSE INSERT @Branches SELECT Branch_ID,Brand_ID FROM dbo.CRM_Account_Branches WHERE Account_ID=@ID AND Brand_ID IN(SELECT ID FROM @Coverage);
IF EXISTS(SELECT 1 FROM @Branches br JOIN dbo.Branches b ON b.ID=br.ID WHERE NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=br.Brand_ID) OR ((ISNULL(b.IsActive,0)=0 OR ISNULL(b.IsDeleted,0)=1) AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Branches old WHERE old.Account_ID=@ID AND old.Branch_ID=br.ID))) THROW 51201,N'اختر فروعًا فعالة تابعة للعلامات المحددة فقط.',1;
IF @Supplier=1 AND EXISTS(SELECT 1 FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID WHERE i.Supplier_Account_ID=@ID AND NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=b.BrandID)) THROW 51201,N'لا يمكن إزالة علامة تجارية للمورد مرتبطة بأدوات.',1;
IF @Admin=0 AND @WasSupplier=1 AND (EXISTS(SELECT ID FROM @Coverage EXCEPT SELECT Brand_ID FROM dbo.CRM_Account_Brands WHERE Account_ID=@ID) OR EXISTS(SELECT Brand_ID FROM dbo.CRM_Account_Brands WHERE Account_ID=@ID EXCEPT SELECT ID FROM @Coverage)) THROW 51200,N'تغيير علامات المورد متاح لمدير النظام فقط.',1;
-- Scalars remain a compatibility projection; membership tables authorize all customer content.
SELECT @Brand_ID=MIN(ID) FROM @Coverage;
SELECT @Branch_ID=MIN(ID) FROM @Branches WHERE Brand_ID=@Brand_ID;
IF @Owner_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Owner_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'مسؤول العميل: العنصر غير متاح أو غير فعال.',1;
IF @Admin=0 BEGIN IF @ID=0 SET @Owner_ID=@Actor_ID; ELSE SELECT @Owner_ID=Owner_ID FROM dbo.CRM_Accounts WHERE ID=@ID; END;
IF @ID=0 BEGIN INSERT dbo.CRM_Accounts([Brand_ID],[Branch_ID],[Name_AR],[Name_EN],[Account_Type_ID],[Owner_ID],[Phone],[Email],[Address],[Country],[Website],[Registration_Number],[Notes],Is_Active,AddedUser) VALUES(@Brand_ID,@Branch_ID,@Name_AR,@Name_EN,@Account_Type_ID,@Owner_ID,@Phone,@Email,@Address,@Country,@Website,@Registration_Number,@Notes,@Active,@Actor_ID); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END ELSE BEGIN UPDATE dbo.CRM_Accounts SET [Brand_ID]=@Brand_ID,[Branch_ID]=@Branch_ID,[Name_AR]=@Name_AR,[Name_EN]=@Name_EN,[Account_Type_ID]=@Account_Type_ID,[Owner_ID]=@Owner_ID,[Phone]=@Phone,[Email]=@Email,[Address]=@Address,[Country]=@Country,[Website]=@Website,[Registration_Number]=@Registration_Number,[Notes]=@Notes,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID; END;
DELETE br FROM dbo.CRM_Account_Branches br WHERE br.Account_ID=@ID AND NOT EXISTS(SELECT 1 FROM @Branches x WHERE x.ID=br.Branch_ID);
DELETE ab FROM dbo.CRM_Account_Brands ab WHERE ab.Account_ID=@ID AND NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=ab.Brand_ID);
INSERT dbo.CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) SELECT @ID,c.ID,@Actor_ID FROM @Coverage c WHERE NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands s WHERE s.Account_ID=@ID AND s.Brand_ID=c.ID);
INSERT dbo.CRM_Account_Branches(Account_ID,Brand_ID,Branch_ID,AddedUser) SELECT @ID,x.Brand_ID,x.ID,@Actor_ID FROM @Branches x WHERE NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Branches br WHERE br.Account_ID=@ID AND br.Branch_ID=x.ID);
-- Retain the former supplier table only as a compatibility projection for tool writers.
DELETE sb FROM dbo.CRM_Supplier_Brands sb WHERE sb.Account_ID=@ID AND (@Supplier=0 OR NOT EXISTS(SELECT 1 FROM @Coverage c WHERE c.ID=sb.Brand_ID));
IF @Supplier=1 INSERT dbo.CRM_Supplier_Brands(Account_ID,Brand_ID,AddedUser) SELECT @ID,c.ID,@Actor_ID FROM @Coverage c WHERE NOT EXISTS(SELECT 1 FROM dbo.CRM_Supplier_Brands s WHERE s.Account_ID=@ID AND s.Brand_ID=c.ID);
SET @Scope=@ID;
SELECT @After=(SELECT ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Branch_ID,Owner_ID,Phone,Email,Address,Country,Website,Registration_Number,Notes,Normalized_Name,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date,Row_Version,(SELECT sb.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN FROM dbo.CRM_Account_Brands sb JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE sb.Account_ID=@ID ORDER BY sb.Brand_ID FOR XML PATH('Brand'),ROOT('Account_Brands'),TYPE),(SELECT br.Branch_ID,br.Brand_ID,b.Title_Ar Name_AR,b.Title_En Name_EN,bb.Title_Ar BrandName FROM dbo.CRM_Account_Branches br JOIN dbo.Branches b ON b.ID=br.Branch_ID JOIN dbo.Brands bb ON bb.ID=br.Brand_ID WHERE br.Account_ID=@ID ORDER BY br.Brand_ID,br.Branch_ID FOR XML PATH('Branch'),ROOT('Account_Branches'),TYPE) FROM dbo.CRM_Accounts WHERE ID=@ID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Scope,N'Accounts',@ID,CASE WHEN @Before IS NULL THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
COMMIT; SELECT ID,Row_Version FROM dbo.CRM_Accounts WHERE ID=@ID;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Supplier_Options @Actor_ID int,@Current_Account_ID int=NULL,@Include_Unavailable bit=0 AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'اختيار موردي الأدوات متاح لمدير النظام فقط.',1;
 SELECT a.ID,a.Name_AR,a.Name_EN,CONVERT(bit,CASE WHEN a.Is_Active=1 AND a.Is_Deleted=0 AND t.Is_Active=1 AND t.Is_Deleted=0 THEN 1 ELSE 0 END) Is_Available,
  ISNULL((SELECT STRING_AGG(CONVERT(varchar(max),s.Brand_ID),',') FROM dbo.CRM_Account_Brands s JOIN dbo.Brands b ON b.ID=s.Brand_ID WHERE s.Account_ID=a.ID AND ((b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR a.ID=@Current_Account_ID OR @Include_Unavailable=1)),'') Brand_IDs
 FROM dbo.CRM_Accounts a JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 WHERE t.System_Code='SUPPLIER' AND ((a.Is_Deleted=0 AND (@Include_Unavailable=1 OR (a.Is_Active=1 AND t.Is_Active=1 AND t.Is_Deleted=0))) OR a.ID=@Current_Account_ID)
 ORDER BY a.Name_AR,a.ID;
END;
GO
-- File URLs replace binary logo payloads. Apply CRM/012 first.
CREATE OR ALTER PROCEDURE dbo.Customer_Dashboard @AccountID int,@Stamp uniqueidentifier,@Section varchar(16)='profile' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0)
 THROW 51911,N'انتهت صلاحية الدخول؛ سجل الدخول مجددًا.',1;
 IF @Section='profile'
 SELECT a.Name_AR,a.Name_EN,a.Phone,a.Email,t.Name_AR TypeName,v.Brand_Name BrandName,v.Branch_Name BranchName,
 (SELECT COUNT(*) FROM dbo.CRM_Contacts c WHERE c.Account_ID=a.ID AND c.Is_Deleted=0) ContactCount
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 LEFT JOIN dbo.CRM_v_Accounts v ON v.ID=a.ID WHERE a.ID=@AccountID;
 ELSE IF @Section='contacts'
 SELECT ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Row_Version FROM dbo.CRM_Contacts WHERE Account_ID=@AccountID AND Is_Deleted=0 ORDER BY Name_AR,ID;
 ELSE IF @Section='editor'
 SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 ELSE IF @Section='logo'
 SELECT Logo_Url FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Logo_Url IS NOT NULL;
 ELSE THROW 51910,N'الطلب غير متاح.',1;
END;

GO

CREATE OR ALTER PROCEDURE dbo.CRM_Require_Tool_Supplier @Actor_ID int,@Supplier_Account_ID int,@JobTitle_ID int,@Current_Item_ID int=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'إدارة الأدوات متاحة لمدير النظام فقط.',1;
 DECLARE @Brand int=(SELECT b.BrandID FROM dbo.JobTitles j JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID WHERE j.ID=@JobTitle_ID);
 IF @Brand IS NULL OR @Supplier_Account_ID IS NULL THROW 51201,N'اختر محطة تعريفية وموردًا صحيحين.',1;
 IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID JOIN dbo.CRM_Account_Brands sb ON sb.Account_ID=i.Supplier_Account_ID AND sb.Brand_ID=@Brand WHERE i.ID=@Current_Item_ID AND i.Supplier_Account_ID=@Supplier_Account_ID AND b.BrandID=@Brand) RETURN;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID JOIN dbo.CRM_Account_Brands sb ON sb.Account_ID=a.ID AND sb.Brand_ID=@Brand JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE a.ID=@Supplier_Account_ID AND a.Is_Active=1 AND a.Is_Deleted=0 AND t.System_Code='SUPPLIER' AND t.Is_Active=1 AND t.Is_Deleted=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) THROW 51201,N'المورد غير فعال أو غير مرتبط بالعلامة التجارية الخاصة بالأداة.',1;
END;
GO
