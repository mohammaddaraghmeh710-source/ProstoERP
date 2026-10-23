CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_Customers @Actor int,@ID int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51600,N'إدارة الصلاحيات لمدير النظام فقط.',1;
 SELECT a.ID,a.Name_AR,b.Title_Ar BrandName,a.Brand_ID,
 CONVERT(bit,CASE WHEN a.Is_Active=1 AND a.Is_Deleted=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 THEN 1 ELSE 0 END) IsAvailable,
 CONVERT(bit,CASE WHEN c.AccountID IS NULL THEN 0 ELSE 1 END) IsSelected
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.Brands b ON b.ID=a.Brand_ID
 LEFT JOIN dbo.Information_Page_Customers c ON c.PageID=@ID AND c.AccountID=a.ID
 WHERE (a.Is_Active=1 AND a.Is_Deleted=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR c.AccountID IS NOT NULL ORDER BY a.Name_AR,a.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Save_Information_Page_Access
 @Actor int,@ID int,@ExpectedRevision int,@AllTypes bit,@Roles xml,@Brands xml=NULL,
 @Audience varchar(10)=NULL,@AllCustomers bit=NULL,@Customers xml=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Revision int,@OldAll bit,@Version int,@OldAudience varchar(10),@OldCustomers bit;
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID)) FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'إدارة الصلاحيات لمدير النظام فقط.',1;
 IF @AllTypes IS NULL THROW 51600,N'اختر صلاحيات الاطلاع.',1;
 BEGIN TRY BEGIN TRANSACTION;
 SELECT @Revision=AccessRevision,@OldAll=AllUserTypes,@Version=VersionNumber,@OldAudience=Audience,@OldCustomers=AllCustomers FROM dbo.Information_Pages WITH(XLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0;
 IF @Revision IS NULL THROW 51600,N'الصفحة غير موجودة أو محذوفة.',1;
 IF @ExpectedRevision IS NULL OR @Revision<>@ExpectedRevision THROW 51600,N'تغيرت صلاحيات الصفحة. أعد فتحها قبل الحفظ.',1;
 SET @Audience=COALESCE(@Audience,@OldAudience);SET @AllCustomers=COALESCE(@AllCustomers,@OldCustomers);
 IF @Audience NOT IN('employees','customers','all') THROW 51600,N'اختر جمهور الصفحة.',1;
 DECLARE @Selected TABLE(ID int PRIMARY KEY);DECLARE @SelectedBrands TABLE(ID int PRIMARY KEY);DECLARE @SelectedCustomers TABLE(ID int PRIMARY KEY);
 IF @Brands IS NULL INSERT @SelectedBrands SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=@ID;
 ELSE INSERT @SelectedBrands SELECT DISTINCT n.value('@id','int') FROM @Brands.nodes('/brands/brand') x(n);
 IF NOT EXISTS(SELECT 1 FROM @SelectedBrands) THROW 51600,N'اختر علامة تجارية واحدة على الأقل.',1;
 IF @Brands IS NOT NULL AND EXISTS(SELECT 1 FROM @SelectedBrands s LEFT JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=s.ID WHERE b.ID IS NULL OR ISNULL(b.IsActive,0)<>1 OR ISNULL(b.IsDeleted,0)<>0) THROW 51600,N'اختر علامات تجارية فعالة وغير محذوفة.',1;
 IF @Audience='all' BEGIN SET @AllTypes=1;SET @AllCustomers=1;END;
 IF @Audience='employees' SET @AllCustomers=0;
 IF @Audience='customers' SET @AllTypes=1;
 IF @Audience='employees' AND @AllTypes=0
 BEGIN
  INSERT @Selected SELECT DISTINCT n.value('@id','int') FROM @Roles.nodes('/roles/role') x(n);
  IF NOT EXISTS(SELECT 1 FROM @Selected) THROW 51600,N'اختر نوع موظف واحدًا على الأقل.',1;
  IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.Users_Types t ON t.ID=s.ID WHERE t.ID IS NULL OR t.IsActive<>1 OR ISNULL(t.IsDeleted,0)<>0) THROW 51600,N'اختر أنواع موظفين فعالة وغير محذوفة.',1;
 END;
 IF @Audience='customers' AND @AllCustomers=0
 BEGIN
  IF @Customers IS NULL INSERT @SelectedCustomers SELECT AccountID FROM dbo.Information_Page_Customers WHERE PageID=@ID;
  ELSE INSERT @SelectedCustomers SELECT DISTINCT n.value('@id','int') FROM @Customers.nodes('/customers/customer') x(n);
  IF NOT EXISTS(SELECT 1 FROM @SelectedCustomers) THROW 51600,N'اختر عميلًا واحدًا على الأقل.',1;
  IF EXISTS(SELECT 1 FROM @SelectedCustomers s LEFT JOIN dbo.CRM_Accounts a WITH(HOLDLOCK) ON a.ID=s.ID LEFT JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=a.Brand_ID WHERE a.ID IS NULL OR a.Is_Active<>1 OR a.Is_Deleted<>0 OR b.IsActive<>1 OR ISNULL(b.IsDeleted,0)<>0 OR NOT EXISTS(SELECT 1 FROM @SelectedBrands x WHERE x.ID=a.Brand_ID)) THROW 51600,N'اختر عملاء فعالين ضمن العلامات التجارية المحددة.',1;
 END;
 IF @OldAudience<>@Audience OR @OldAll<>@AllTypes OR @OldCustomers<>@AllCustomers
 OR EXISTS(SELECT UserTypeID FROM dbo.Information_Page_Roles WHERE PageID=@ID EXCEPT SELECT ID FROM @Selected)
 OR EXISTS(SELECT ID FROM @Selected EXCEPT SELECT UserTypeID FROM dbo.Information_Page_Roles WHERE PageID=@ID)
 OR EXISTS(SELECT AccountID FROM dbo.Information_Page_Customers WHERE PageID=@ID EXCEPT SELECT ID FROM @SelectedCustomers)
 OR EXISTS(SELECT ID FROM @SelectedCustomers EXCEPT SELECT AccountID FROM dbo.Information_Page_Customers WHERE PageID=@ID)
 OR EXISTS(SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=@ID EXCEPT SELECT ID FROM @SelectedBrands)
 OR EXISTS(SELECT ID FROM @SelectedBrands EXCEPT SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=@ID)
 BEGIN
  DECLARE @Before nvarchar(max),@After nvarchar(max);
  SET @Before=CONCAT(N'الجمهور: ',@OldAudience,N'؛ كل أنواع الموظفين: ',@OldAll,N'؛ كل العملاء: ',@OldCustomers,N'؛ الأنواع: ',
   (SELECT t.Title_Ar+N'، ' FROM dbo.Information_Page_Roles r JOIN dbo.Users_Types t ON t.ID=r.UserTypeID WHERE r.PageID=@ID ORDER BY t.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),N'؛ العملاء: ',
   (SELECT a.Name_AR+N'، ' FROM dbo.Information_Page_Customers c JOIN dbo.CRM_Accounts a ON a.ID=c.AccountID WHERE c.PageID=@ID ORDER BY a.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),N'؛ العلامات: ',
   (SELECT b.Title_Ar+N'، ' FROM dbo.Information_Page_Brands x JOIN dbo.Brands b ON b.ID=x.BrandID WHERE x.PageID=@ID ORDER BY b.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'));
  SET @After=CONCAT(N'الجمهور: ',@Audience,N'؛ كل أنواع الموظفين: ',@AllTypes,N'؛ كل العملاء: ',@AllCustomers,N'؛ الأنواع: ',
   (SELECT t.Title_Ar+N'، ' FROM @Selected x JOIN dbo.Users_Types t ON t.ID=x.ID ORDER BY t.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),N'؛ العملاء: ',
   (SELECT a.Name_AR+N'، ' FROM @SelectedCustomers x JOIN dbo.CRM_Accounts a ON a.ID=x.ID ORDER BY a.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),N'؛ العلامات: ',
   (SELECT b.Title_Ar+N'، ' FROM @SelectedBrands x JOIN dbo.Brands b ON b.ID=x.ID ORDER BY b.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'));
  DELETE dbo.Information_Page_Brands WHERE PageID=@ID;INSERT dbo.Information_Page_Brands SELECT @ID,ID FROM @SelectedBrands;
  DELETE dbo.Information_Page_Roles WHERE PageID=@ID;INSERT dbo.Information_Page_Roles SELECT @ID,ID FROM @Selected;
  DELETE dbo.Information_Page_Customers WHERE PageID=@ID;INSERT dbo.Information_Page_Customers SELECT @ID,ID FROM @SelectedCustomers;
  UPDATE dbo.Information_Pages SET Audience=@Audience,AllUserTypes=@AllTypes,AllCustomers=@AllCustomers,AccessRevision=AccessRevision+1 WHERE ID=@ID;
  INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Details) VALUES(@ID,@Version,'access',@Actor,@Name,SYSUTCDATETIME(),N'صلاحيات الاطلاع: من ['+@Before+N'] إلى ['+@After+N'].');
 END;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_InformationPages @AccountID int,@Stamp uniqueidentifier,@ID int=NULL,@Language varchar(2)='ar',@LogVisit bit=0 AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @Language NOT IN('ar','en') THROW 51912,N'الطلب غير متاح.',1;
 BEGIN TRY BEGIN TRANSACTION;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brand int,@Name nvarchar(500),@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Brand=Brand_ID,@Name=Name_AR FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 SELECT p.ID,p.Title_Ar,p.Title_En,p.Summary_Ar,p.Summary_En,p.VersionNumber,p.Item_Order,v.OccurredUtc,
 CASE WHEN @ID IS NULL THEN N'' ELSE p.Details_Ar END Details_Ar,CASE WHEN @ID IS NULL THEN N'' ELSE p.Details_En END Details_En INTO #Available
 FROM dbo.Information_Pages p WITH(HOLDLOCK) JOIN dbo.Information_Page_Versions v ON v.PageID=p.ID AND v.VersionNumber=p.VersionNumber
 WHERE p.IsDeleted=0 AND p.IsPublished=1 AND p.Audience IN('customers','all') AND (@ID IS NULL OR p.ID=@ID)
 AND (p.PublishMode='immediate' OR (@Now>=p.StartUtc AND @Now<p.EndUtc))
 AND EXISTS(SELECT 1 FROM dbo.Information_Page_Brands x JOIN dbo.Brands b ON b.ID=x.BrandID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE x.PageID=p.ID AND x.BrandID=@Brand)
 AND (p.AllCustomers=1 OR EXISTS(SELECT 1 FROM dbo.Information_Page_Customers c WHERE c.PageID=p.ID AND c.AccountID=@AccountID));
 IF @ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM #Available) THROW 51912,N'الصفحة غير متاحة.',1;
 IF @ID IS NOT NULL AND @LogVisit=1 BEGIN
  INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Language,CustomerAccountID) SELECT ID,VersionNumber,'view',0,@Name,@Now,@Language,@AccountID FROM #Available;
  INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note) VALUES(@AccountID,'information-view',N'Information_Pages',@ID,CONCAT(N'عرض صفحة معلوماتية؛ اللغة: ',@Language));
 END;
 SELECT * FROM #Available ORDER BY Item_Order,ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Save_Information_Page
 @Actor int,@ID int,@ExpectedVersion int,
 @TitleAr nvarchar(250),@TitleEn nvarchar(250),@SummaryAr nvarchar(2000),@SummaryEn nvarchar(2000),
 @DetailsAr nvarchar(max),@DetailsEn nvarchar(max),@Order int,@Published bit,
 @Mode varchar(10),@StartUtc datetime2(0)=NULL,@EndUtc datetime2(0)=NULL,
 @AllTypes bit=NULL,@Roles xml=NULL,@ExpectedAccessRevision int=NULL,@Brands xml=NULL,
 @Audience varchar(10)=NULL,@AllCustomers bit=NULL,@Customers xml=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Now datetime2(0)=SYSUTCDATETIME(),@Version int,@Action varchar(10),@WriteVersion bit=1;
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'إدارة الصفحات لمدير النظام فقط.',1;
 IF @Audience IS NOT NULL AND (@AllTypes IS NULL OR @AllCustomers IS NULL OR @ExpectedAccessRevision IS NULL) THROW 51600,N'أعد تحميل إعدادات الجمهور قبل الحفظ.',1;
 IF @ID=0 AND @Brands IS NULL THROW 51600,N'اختر علامة تجارية واحدة على الأقل.',1;
 IF @Brands IS NOT NULL AND (@AllTypes IS NULL OR @ExpectedAccessRevision IS NULL)
  THROW 51600,N'أعد تحميل إعدادات صلاحيات الاطلاع قبل الحفظ.',1;
 IF NULLIF(LTRIM(RTRIM(@TitleAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@TitleEn)),N'') IS NULL
 OR NULLIF(LTRIM(RTRIM(@SummaryAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@SummaryEn)),N'') IS NULL
 OR NULLIF(LTRIM(RTRIM(@DetailsAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@DetailsEn)),N'') IS NULL
 OR LEN(@DetailsAr)>100000 OR LEN(@DetailsEn)>100000 OR @Order IS NULL OR @Order<0 OR @Published IS NULL
 THROW 51600,N'أدخل العنوان والملخص والتفاصيل باللغتين وترتيبًا صحيحًا.',1;
 IF @Mode IS NULL OR @Mode NOT IN('immediate','scheduled') THROW 51600,N'اختر طريقة النشر.',1;
 IF @Mode='scheduled' AND (@StartUtc IS NULL OR @EndUtc IS NULL OR @EndUtc<=@StartUtc)
 THROW 51600,N'النشر المجدول يتطلب تاريخ بداية ونهاية لاحقًا للبداية.',1;
 IF @Mode='immediate' BEGIN SET @StartUtc=NULL; SET @EndUtc=NULL; END;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF @ID=0
 BEGIN
  IF @ExpectedVersion IS NULL OR @ExpectedVersion<>0 THROW 51600,N'رقم الإصدار غير صحيح.',1;
  SET @Version=1; SET @Action='create';
  INSERT dbo.Information_Pages(Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,
  IsPublished,PublishMode,StartUtc,EndUtc,VersionNumber,CreatedBy,CreatedUtc)
  VALUES(@TitleAr,@TitleEn,@SummaryAr,@SummaryEn,@DetailsAr,@DetailsEn,@Order,@Published,@Mode,@StartUtc,@EndUtc,1,@Actor,@Now);
  SET @ID=CONVERT(int,SCOPE_IDENTITY());
 END
 ELSE
 BEGIN
  SELECT @Version=VersionNumber FROM dbo.Information_Pages WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0;
  IF @Version IS NULL THROW 51600,N'الصفحة غير موجودة أو محذوفة.',1;
  IF @ExpectedVersion IS NULL OR @Version<>@ExpectedVersion THROW 51600,N'تم تعديل الصفحة بواسطة مستخدم آخر. أعد فتحها قبل الحفظ.',1;
  IF NOT EXISTS(SELECT CONVERT(varbinary(max),@TitleAr),CONVERT(varbinary(max),@TitleEn),CONVERT(varbinary(max),@SummaryAr),CONVERT(varbinary(max),@SummaryEn),CONVERT(varbinary(max),@DetailsAr),CONVERT(varbinary(max),@DetailsEn),@Order,@Published,@Mode,@StartUtc,@EndUtc
    EXCEPT SELECT CONVERT(varbinary(max),Title_Ar),CONVERT(varbinary(max),Title_En),CONVERT(varbinary(max),Summary_Ar),CONVERT(varbinary(max),Summary_En),CONVERT(varbinary(max),Details_Ar),CONVERT(varbinary(max),Details_En),Item_Order,IsPublished,PublishMode,StartUtc,EndUtc
    FROM dbo.Information_Pages WHERE ID=@ID) SET @WriteVersion=0;
  IF @WriteVersion=1 BEGIN
  SET @Version=@Version+1; SET @Action='update';
  UPDATE dbo.Information_Pages SET Title_Ar=@TitleAr,Title_En=@TitleEn,Summary_Ar=@SummaryAr,Summary_En=@SummaryEn,
  Details_Ar=@DetailsAr,Details_En=@DetailsEn,Item_Order=@Order,IsPublished=@Published,PublishMode=@Mode,
  StartUtc=@StartUtc,EndUtc=@EndUtc,VersionNumber=@Version,ModifiedBy=@Actor,ModifiedUtc=@Now WHERE ID=@ID;
  END;
 END;
 IF @WriteVersion=1 BEGIN
 INSERT dbo.Information_Page_Versions
 (PageID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,Action,ActorID,ActorName,OccurredUtc)
 SELECT ID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,@Action,@Actor,@Name,@Now
 FROM dbo.Information_Pages WHERE ID=@ID;
 INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc)
 VALUES(@ID,@Version,@Action,@Actor,@Name,@Now);
 END;
 IF @AllTypes IS NOT NULL
 EXEC dbo.Save_Information_Page_Access @Actor=@Actor,@ID=@ID,@ExpectedRevision=@ExpectedAccessRevision,@AllTypes=@AllTypes,@Roles=@Roles,@Brands=@Brands,@Audience=@Audience,@AllCustomers=@AllCustomers,@Customers=@Customers;
 COMMIT;
 SELECT @ID ID,@Version VersionNumber;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Select_Information_Page
 @Actor int,@ID int,@Admin bit=0,@Version int=0,@LogVisit bit=0,@Language varchar(2)='ar'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Role int,@Brand int,@Name nvarchar(500),@Current int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Role=Type,@Brand=Brand_ID,@Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Role IS NULL OR (@Admin=1 AND @Role<>1) OR (@Version<>0 AND @Admin=0)
 THROW 51600,N'غير مسموح بالوصول.',1;
 IF @Language NOT IN('ar','en') THROW 51600,N'اللغة غير صحيحة.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 SELECT @Current=VersionNumber FROM dbo.Information_Pages p WITH(HOLDLOCK)
 WHERE ID=@ID AND (@Admin=1 OR (IsDeleted=0 AND IsPublished=1
 AND (PublishMode='immediate' OR (@Now>=StartUtc AND @Now<EndUtc))
 AND EXISTS(SELECT 1 FROM dbo.Information_Pages_ForBrand(@Brand) bp WHERE bp.PageID=p.ID)
 AND (@Role=1 OR AllUserTypes=1 OR EXISTS(SELECT 1 FROM dbo.Information_Page_Roles r
 JOIN dbo.Users_Types t ON t.ID=r.UserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0
 WHERE r.PageID=p.ID AND r.UserTypeID=@Role))));
 IF @Current IS NULL THROW 51604,N'الصفحة غير متاحة.',1;
 IF @Version=0 SET @Version=@Current;
 IF NOT EXISTS(SELECT 1 FROM dbo.Information_Page_Versions WHERE PageID=@ID AND VersionNumber=@Version)
 THROW 51604,N'الإصدار غير موجود.',1;
 IF @LogVisit=1
 INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Language)
 VALUES(@ID,@Version,CASE WHEN @Admin=1 THEN 'preview' ELSE 'view' END,@Actor,@Name,@Now,@Language);
 SELECT v.*,p.CreatedUtc,p.ModifiedUtc,p.DeletedUtc,p.AllUserTypes,p.AccessRevision,p.Audience,p.AllCustomers FROM dbo.Information_Page_Versions v
 JOIN dbo.Information_Pages p ON p.ID=v.PageID WHERE v.PageID=@ID AND v.VersionNumber=@Version;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Select_Information_Pages
 @Actor int,@Manage bit=0,@Deleted bit=0,@Search nvarchar(250)=N''
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Role int,@Brand int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Role=Type,@Brand=Brand_ID FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Role IS NULL OR (@Manage=1 AND @Role<>1) THROW 51600,N'غير مسموح بالوصول.',1;
 SELECT Audience,ID,Title_Ar,Title_En,Summary_Ar,Summary_En,Item_Order,IsPublished,PublishMode,
 StartUtc,EndUtc,IsDeleted,VersionNumber,CreatedUtc,ModifiedUtc,DeletedUtc,
 STUFF((SELECT N'، '+COALESCE(NULLIF(b.Title_Ar,N''),b.Title_En,CONVERT(nvarchar(20),b.ID))
 FROM dbo.Information_Page_Brands pb JOIN dbo.Brands b ON b.ID=pb.BrandID
 WHERE pb.PageID=p.ID ORDER BY b.Title_Ar,b.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'') BrandNames,
 CASE WHEN IsDeleted=1 THEN 'deleted' WHEN IsPublished=0 THEN 'draft'
 WHEN PublishMode='scheduled' AND @Now<StartUtc THEN 'scheduled'
 WHEN PublishMode='scheduled' AND @Now>=EndUtc THEN 'expired' ELSE 'published' END DisplayStatus
 FROM dbo.Information_Pages p
 WHERE ((@Manage=1 AND IsDeleted=@Deleted) OR (@Manage=0 AND IsDeleted=0 AND IsPublished=1
 AND (PublishMode='immediate' OR (@Now>=StartUtc AND @Now<EndUtc))
 AND EXISTS(SELECT 1 FROM dbo.Information_Pages_ForBrand(@Brand) bp WHERE bp.PageID=p.ID)
 AND (@Role=1 OR AllUserTypes=1 OR EXISTS(SELECT 1 FROM dbo.Information_Page_Roles r
 JOIN dbo.Users_Types t ON t.ID=r.UserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0
 WHERE r.PageID=p.ID AND r.UserTypeID=@Role))))
 AND (@Search=N'' OR CHARINDEX(@Search,Title_Ar)>0 OR CHARINDEX(@Search,Title_En)>0)
 ORDER BY Item_Order,ID;
END;
GO
