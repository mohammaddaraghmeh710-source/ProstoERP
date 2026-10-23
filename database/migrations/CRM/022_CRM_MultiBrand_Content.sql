-- Customer content uses every assigned active brand. Membership predicates use EXISTS to avoid duplicate content, notices and mail.
GO

-- Customer news is selected only through the authenticated account's current active brand.
CREATE OR ALTER PROCEDURE dbo.Customer_ContentBrands @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 SELECT b.ID BrandID,b.Title_Ar Name_AR,b.Title_En Name_EN FROM dbo.CRM_Account_Brands ab WITH(HOLDLOCK)
 JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 WHERE ab.Account_ID=@AccountID ORDER BY b.Title_Ar,b.ID;
 COMMIT;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Customer_News @AccountID int,@Stamp uniqueidentifier,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;

 IF @ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.News WITH(HOLDLOCK) WHERE PID=@ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=@AccountID AND ab.Brand_ID=News.Brand_ID))
  THROW 51912,N'الخبر غير متاح.',1;
 SELECT n.PID,n.Title_AR,n.Title_En,n.Brief_Ar,n.Brief_En,n.Image,n.[Date],n.Brand_ID,b.Title_Ar Brand_Name,b.Title_En Brand_Name_EN,CASE WHEN @ID IS NULL THEN NULL ELSE n.Details END Details,CASE WHEN @ID IS NULL THEN NULL ELSE n.Details_EN END Details_EN
 FROM dbo.News n WITH(HOLDLOCK) JOIN dbo.Brands b ON b.ID=n.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE n.IsActive=1 AND ISNULL(n.IsDeleted,0)=0 AND (@ID IS NULL OR PID=@ID) AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WHERE ab.Account_ID=@AccountID AND ab.Brand_ID=n.Brand_ID)
 ORDER BY n.Item_Order,n.[Date] DESC,n.PID DESC;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note)
 VALUES(@AccountID,CASE WHEN @ID IS NULL THEN 'news-list' ELSE 'news-details' END,N'News',@ID,CASE WHEN @ID IS NULL THEN N'عرض أخبار العلامة التجارية' ELSE N'عرض تفاصيل خبر العلامة التجارية' END);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_Customers @Actor int,@ID int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51600,N'إدارة الصلاحيات لمدير النظام فقط.',1;
 SELECT a.ID,a.Name_AR,a.Brand_ID,
 (SELECT STRING_AGG(CONVERT(varchar(max),ab.Brand_ID),',') FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID) Brand_IDs,
 (SELECT STRING_AGG(CONVERT(nvarchar(max),b.Title_Ar),N'، ') FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID) BrandName,
 CONVERT(bit,CASE WHEN a.Is_Active=1 AND a.Is_Deleted=0 AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID) THEN 1 ELSE 0 END) IsAvailable,
 CONVERT(bit,CASE WHEN c.AccountID IS NULL THEN 0 ELSE 1 END) IsSelected
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.Information_Page_Customers c ON c.PageID=@ID AND c.AccountID=a.ID
 WHERE (a.Is_Active=1 AND a.Is_Deleted=0 AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID)) OR c.AccountID IS NOT NULL ORDER BY a.Name_AR,a.ID;
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
  IF EXISTS(SELECT 1 FROM @SelectedCustomers s LEFT JOIN dbo.CRM_Accounts a WITH(HOLDLOCK) ON a.ID=s.ID WHERE a.ID IS NULL OR a.Is_Active<>1 OR a.Is_Deleted<>0 OR NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WITH(HOLDLOCK) JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 JOIN @SelectedBrands x ON x.ID=ab.Brand_ID WHERE ab.Account_ID=a.ID)) THROW 51600,N'اختر عملاء فعالين ضمن العلامات التجارية المحددة.',1;
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
 DECLARE @Name nvarchar(500),@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Name=Name_AR FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 SELECT p.ID,p.Title_Ar,p.Title_En,p.Summary_Ar,p.Summary_En,p.VersionNumber,p.Item_Order,v.OccurredUtc,
 CASE WHEN @ID IS NULL THEN N'' ELSE p.Details_Ar END Details_Ar,CASE WHEN @ID IS NULL THEN N'' ELSE p.Details_En END Details_En INTO #Available
 FROM dbo.Information_Pages p WITH(HOLDLOCK) JOIN dbo.Information_Page_Versions v ON v.PageID=p.ID AND v.VersionNumber=p.VersionNumber
 WHERE p.IsDeleted=0 AND p.IsPublished=1 AND p.Audience IN('customers','all') AND (@ID IS NULL OR p.ID=@ID)
 AND (p.PublishMode='immediate' OR (@Now>=p.StartUtc AND @Now<p.EndUtc))
 AND EXISTS(SELECT 1 FROM dbo.Information_Page_Brands x JOIN dbo.Brands b ON b.ID=x.BrandID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE x.PageID=p.ID AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WITH(HOLDLOCK) WHERE ab.Account_ID=@AccountID AND ab.Brand_ID=x.BrandID))
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

CREATE OR ALTER FUNCTION dbo.Circular_CustomerVisible(@AccountID int,@Now datetime2(0)) RETURNS TABLE AS RETURN(
 SELECT c.ID FROM dbo.Circulars c JOIN dbo.CRM_Accounts a ON a.ID=@AccountID AND a.Is_Active=1 AND a.Is_Deleted=0
 JOIN dbo.Customer_Logins l ON l.AccountID=a.ID AND l.IsActive=1
 WHERE EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID AND ab.Brand_ID=c.BrandID) AND c.IsEnabled=1 AND c.StartUtc<=@Now AND @Now<c.EndUtc
 AND ((c.Audience='customers' AND EXISTS(SELECT 1 FROM dbo.Circular_CustomerTargets t WHERE t.CircularID=c.ID AND t.Kind='customer' AND t.TargetID=a.ID))
 OR (c.Audience='customerTypes' AND EXISTS(SELECT 1 FROM dbo.Circular_CustomerTargets t JOIN dbo.CRM_Account_Types ct ON ct.ID=t.TargetID AND ct.Is_Active=1 AND ct.Is_Deleted=0 WHERE t.CircularID=c.ID AND t.Kind='customerType' AND t.TargetID=a.Account_Type_ID))))
;
GO

CREATE OR ALTER PROCEDURE dbo.Circular_AdminSave @Actor int,@ID int=0,@ExpectedVersion int=0,@BrandID int,@Title nvarchar(250),@Title_EN nvarchar(250),@Summary nvarchar(2000),@Summary_EN nvarchar(2000),@CircularDate date,@HasPeriod bit,@StartUtc datetime2(0)=NULL,@EndUtc datetime2(0)=NULL,@IsEnabled bit,@AllowDownload bit,@Audience varchar(16),@Targets xml,@FileName nvarchar(250)=NULL,@FileBytes varbinary(max)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @BrandID IS NULL OR @HasPeriod IS NULL OR @IsEnabled IS NULL OR @AllowDownload IS NULL OR NULLIF(LTRIM(RTRIM(@Title_EN)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Summary_EN)),N'') IS NULL OR @Audience NOT IN('all','roles','organization','customers','customerTypes') OR @Audience IS NULL THROW 51800,'Invalid circular fields.',1;
 IF @HasPeriod=1 AND (@StartUtc IS NULL OR @EndUtc IS NULL OR @EndUtc<=@StartUtc) THROW 51800,'A start and end are required.',1;
 IF @HasPeriod=0 SELECT @StartUtc=CONVERT(datetime2(0),'19000101'),@EndUtc=CONVERT(datetime2(0),'99991231');
 DECLARE @Selected TABLE(Kind varchar(16),TargetID int,PRIMARY KEY(Kind,TargetID));
 INSERT @Selected SELECT DISTINCT n.value('@kind','varchar(16)'),n.value('@id','int') FROM @Targets.nodes('/targets/item') x(n);
 IF EXISTS(SELECT 1 FROM @Selected WHERE (@Audience='all') OR (@Audience='roles' AND Kind<>'role') OR (@Audience='organization' AND Kind NOT IN('branch','department','shift')) OR (@Audience='customers' AND Kind<>'customer') OR (@Audience='customerTypes' AND Kind<>'customerType')) OR (@Audience<>'all' AND NOT EXISTS(SELECT 1 FROM @Selected)) THROW 51800,'Choose the required audience.',1;
 BEGIN TRY BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51800,'Select an active brand.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='branch' AND NOT EXISTS(SELECT 1 FROM dbo.Branches WITH(HOLDLOCK) WHERE ID=t.TargetID AND BrandID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) THROW 51800,'Cross-brand branch.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='customer' AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WITH(HOLDLOCK) WHERE a.ID=t.TargetID AND a.Is_Active=1 AND a.Is_Deleted=0 AND EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WITH(HOLDLOCK) WHERE ab.Account_ID=a.ID AND ab.Brand_ID=@BrandID))) THROW 51800,'Cross-brand customer.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE t.Kind='customerType' AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Types WITH(HOLDLOCK) WHERE ID=t.TargetID AND Is_Active=1 AND Is_Deleted=0)) THROW 51800,'Invalid customer type.',1;
 IF NULLIF(LTRIM(RTRIM(@Title)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Summary)),N'') IS NULL OR @CircularDate IS NULL OR @ExpectedVersion IS NULL OR @ID IS NULL OR @ID<0 THROW 51800,'Invalid circular fields.',1;
 IF (@ID=0 AND @FileBytes IS NULL) OR (@FileBytes IS NULL AND @FileName IS NOT NULL) OR (@FileBytes IS NOT NULL AND (@FileName IS NULL OR DATALENGTH(@FileBytes) NOT BETWEEN 8 AND 10485760 OR SUBSTRING(@FileBytes,1,5)<>0x255044462D OR LOWER(RIGHT(@FileName,4))<>'.pdf')) THROW 51800,'A PDF up to 10MB is required.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE (t.Kind='role' AND NOT EXISTS(SELECT 1 FROM dbo.Users_Types WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) OR (t.Kind='department' AND NOT EXISTS(SELECT 1 FROM dbo.Departments WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) OR (t.Kind='shift' AND NOT EXISTS(SELECT 1 FROM dbo.Shift WITH(HOLDLOCK) WHERE ID=t.TargetID AND IsActive=1 AND ISNULL(IsDeleted,0)=0))) THROW 51800,'Inactive audience target.',1;
 DECLARE @Version int,@Now datetime2(0)=SYSUTCDATETIME();
 IF @ID=0 BEGIN
  INSERT dbo.Circulars(Title,Summary,CircularDate,StartUtc,EndUtc,IsEnabled,AllowDownload,Audience,FileName,FileBytes,CreatedBy,ModifiedBy,BrandID,Title_EN,Summary_EN,HasPeriod)
  VALUES(@Title,@Summary,@CircularDate,@StartUtc,@EndUtc,@IsEnabled,@AllowDownload,@Audience,@FileName,@FileBytes,@Actor,@Actor,@BrandID,@Title_EN,@Summary_EN,@HasPeriod);
  SELECT @ID=SCOPE_IDENTITY(),@Version=1;
 END ELSE BEGIN
  SELECT @Version=Version FROM dbo.Circulars WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID;
  IF @Version IS NULL THROW 51804,'Circular unavailable.',1;
  IF @Version<>@ExpectedVersion THROW 51809,'Circular changed. Reload before saving.',1;
  SET @Version=@Version+1;
  UPDATE dbo.Circulars SET BrandID=@BrandID,Title=@Title,Title_EN=@Title_EN,Summary=@Summary,Summary_EN=@Summary_EN,CircularDate=@CircularDate,HasPeriod=@HasPeriod,StartUtc=@StartUtc,EndUtc=@EndUtc,IsEnabled=@IsEnabled,AllowDownload=@AllowDownload,Audience=@Audience,
   FileName=COALESCE(@FileName,FileName),FileBytes=COALESCE(@FileBytes,FileBytes),Version=@Version,ModifiedBy=@Actor,ModifiedUtc=@Now WHERE ID=@ID;
 END;
 DELETE dbo.Circular_Targets WHERE CircularID=@ID;
 INSERT dbo.Circular_Targets SELECT @ID,Kind,TargetID FROM @Selected WHERE Kind IN('role','branch','department','shift');
 IF @Audience='organization' INSERT dbo.Circular_Targets VALUES(@ID,'brand',@BrandID);
 DELETE dbo.Circular_CustomerTargets WHERE CircularID=@ID;
 INSERT dbo.Circular_CustomerTargets SELECT @ID,Kind,TargetID FROM @Selected WHERE Kind IN('customer','customerType');
 INSERT dbo.Circular_Logs(CircularID,Version,TitleSnapshot,UserID,EmployeeNumber,Action,Source,EventID)
 SELECT @ID,@Version,@Title,@Actor,Employee_Number,CASE WHEN @Version=1 THEN 'create' ELSE 'update' END,'Portal',NEWID() FROM dbo.UsersMembers WHERE ID=@Actor;
 UPDATE dbo.Circular_Mail SET Status='cancelled',CompletedUtc=@Now,ErrorCode='SUPERSEDED' WHERE CircularID=@ID AND Status='pending';
 SELECT @ID ID,@Version Version;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Customer_Circulars @AccountID int,@Stamp uniqueidentifier,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRANSACTION; EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 IF @ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) WHERE ID=@ID) THROW 51804,'Circular unavailable.',1;
 SELECT c.ID,c.Title,c.Title_EN,c.Summary,c.Summary_EN,c.BrandID,b.Title_Ar BrandName,b.Title_En BrandName_EN,c.CircularDate,c.HasPeriod,c.StartUtc,c.EndUtc,c.AllowDownload,c.FileName,c.Version,CAST(CASE WHEN r.AccountID IS NULL THEN 0 ELSE 1 END AS bit) IsRead
 FROM dbo.Circulars c JOIN dbo.Brands b ON b.ID=c.BrandID JOIN dbo.Circular_CustomerVisible(@AccountID,SYSUTCDATETIME()) v ON v.ID=c.ID LEFT JOIN dbo.Circular_CustomerReads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.AccountID=@AccountID WHERE @ID IS NULL OR c.ID=@ID ORDER BY c.CircularDate DESC,c.ID DESC;
 COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Circular_AdminData @Actor int,@Mode varchar(10)='list',@ID int=0,@Page int=1 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF @Mode='list' BEGIN
  SELECT c.ID,c.BrandID,b.Title_Ar BrandName,c.Title,c.Title_EN,c.Summary,c.Summary_EN,c.CircularDate,c.HasPeriod,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,c.Version,
   CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>SYSUTCDATETIME() THEN 'scheduled' WHEN c.EndUtc<=SYSUTCDATETIME() THEN 'expired' ELSE 'active' END Status,
   (SELECT COUNT(*) FROM dbo.Circular_Reads r WHERE r.CircularID=c.ID AND r.Version=c.Version)+(SELECT COUNT(*) FROM dbo.Circular_CustomerReads r WHERE r.CircularID=c.ID AND r.Version=c.Version) ReadCount,
   (SELECT COUNT(*) FROM dbo.Circular_Mail m WHERE m.CircularID=c.ID AND m.Version=c.Version AND m.Status='submitted') MailSubmitted,
   (SELECT COUNT(*) FROM dbo.Circular_Mail m WHERE m.CircularID=c.ID AND m.Version=c.Version AND m.Status IN('failed','unknown')) MailFailed
  FROM dbo.Circulars c LEFT JOIN dbo.Brands b ON b.ID=c.BrandID ORDER BY c.CircularDate DESC,c.ID DESC;
  RETURN;
 END;
 IF @Mode='editor' BEGIN
  SELECT ID,BrandID,Title,Title_EN,Summary,Summary_EN,CircularDate,HasPeriod,StartUtc,EndUtc,IsEnabled,AllowDownload,Audience,FileName,Version FROM dbo.Circulars WHERE ID=@ID;
  SELECT Kind,TargetID FROM dbo.Circular_Targets WHERE CircularID=@ID AND Kind<>'brand' UNION ALL SELECT Kind,TargetID FROM dbo.Circular_CustomerTargets WHERE CircularID=@ID;
  SELECT 'brand' Kind,ID,Title_Ar Title,CAST(NULL AS int) BrandID,CAST(NULL AS varchar(max)) BrandIDs FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'role',ID,Title_Ar,NULL,NULL FROM dbo.Users_Types WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'branch',ID,Title_Ar,BrandID,NULL FROM dbo.Branches WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'department',ID,Title_Ar,NULL,NULL FROM dbo.Departments WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'shift',ID,Title_Ar,NULL,NULL FROM dbo.Shift WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
  UNION ALL SELECT 'customer',a.ID,a.Name_AR,a.Brand_ID,(SELECT STRING_AGG(CONVERT(varchar(max),ab.Brand_ID),',') FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=a.ID) FROM dbo.CRM_Accounts a WHERE a.Is_Active=1 AND a.Is_Deleted=0
  UNION ALL SELECT 'customerType',ID,Name_AR,NULL,NULL FROM dbo.CRM_Account_Types WHERE Is_Active=1 AND Is_Deleted=0;
  RETURN;
 END;
 IF @Mode='logs' BEGIN
  IF @Page<1 OR @Page>100000 THROW 51800,'Invalid page.',1;
  SELECT l.ID,l.Version,l.TitleSnapshot,l.Action,CAST(l.Source AS varchar(20)) Source,l.RecordedUtc,CAST(u.FullName_Ar AS nvarchar(500)) ActorName,'employee' ActorKind,l.UserID ActorID,l.EmployeeNumber,l.DeviceID,l.AppVersion,l.OccurredAtUtc,
   CAST(NULL AS varchar(16)) MailStatus,CAST(NULL AS varchar(40)) ErrorCode INTO #Logs FROM dbo.Circular_Logs l JOIN dbo.UsersMembers u ON u.ID=l.UserID WHERE l.CircularID=@ID;
  INSERT #Logs SELECT ID,Version,TitleSnapshot,Action,'CustomerPortal',RecordedUtc,ActorName,'customer',AccountID,NULL,NULL,NULL,NULL,NULL,NULL FROM dbo.Circular_CustomerLogs WHERE CircularID=@ID;
  INSERT #Logs SELECT m.ID,m.Version,c.Title,'email','Service',COALESCE(m.CompletedUtc,m.ClaimedUtc,n.CreatedUtc),COALESCE(u.FullName_Ar,a.Name_AR),m.RecipientKind,m.RecipientID,u.Employee_Number,NULL,NULL,NULL,m.Status,m.ErrorCode
   FROM dbo.Circular_Mail m JOIN dbo.Circular_Notices n ON n.CircularID=m.CircularID AND n.Version=m.Version AND n.RecipientKind=m.RecipientKind AND n.RecipientID=m.RecipientID JOIN dbo.Circulars c ON c.ID=m.CircularID
   LEFT JOIN dbo.UsersMembers u ON m.RecipientKind='employee' AND u.ID=m.RecipientID LEFT JOIN dbo.CRM_Accounts a ON m.RecipientKind='customer' AND a.ID=m.RecipientID WHERE m.CircularID=@ID;
  SELECT COUNT(*) Total FROM #Logs;
  SELECT * FROM #Logs ORDER BY RecordedUtc DESC,ID DESC OFFSET (@Page-1)*50 ROWS FETCH NEXT 50 ROWS ONLY;
  RETURN;
 END;
 THROW 51800,'Invalid operation.',1;
END;
GO

-- Customer_CircularFile, Customer_CircularNotifications and Circular_CurrentRecipients deliberately reuse Circular_CustomerVisible; the EXISTS predicate returns each circular once across all memberships.
