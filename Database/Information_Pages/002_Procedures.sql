CREATE OR ALTER PROCEDURE dbo.Select_Information_Pages
 @Actor int,@Manage bit=0,@Deleted bit=0,@Search nvarchar(250)=N''
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Role int,@Brand int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Role=Type,@Brand=Brand_ID FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Role IS NULL OR (@Manage=1 AND @Role<>1) THROW 51600,N'غير مسموح بالوصول.',1;
 SELECT ID,Title_Ar,Title_En,Summary_Ar,Summary_En,Item_Order,IsPublished,PublishMode,
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
CREATE OR ALTER PROCEDURE dbo.Save_Information_Page
 @Actor int,@ID int,@ExpectedVersion int,
 @TitleAr nvarchar(250),@TitleEn nvarchar(250),@SummaryAr nvarchar(2000),@SummaryEn nvarchar(2000),
 @DetailsAr nvarchar(max),@DetailsEn nvarchar(max),@Order int,@Published bit,
 @Mode varchar(10),@StartUtc datetime2(0)=NULL,@EndUtc datetime2(0)=NULL,
 @AllTypes bit=NULL,@Roles xml=NULL,@ExpectedAccessRevision int=NULL,@Brands xml=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Now datetime2(0)=SYSUTCDATETIME(),@Version int,@Action varchar(10),@WriteVersion bit=1;
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'إدارة الصفحات لمدير النظام فقط.',1;
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
 EXEC dbo.Save_Information_Page_Access @Actor=@Actor,@ID=@ID,@ExpectedRevision=@ExpectedAccessRevision,@AllTypes=@AllTypes,@Roles=@Roles,@Brands=@Brands;
 COMMIT;
 SELECT @ID ID,@Version VersionNumber;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Delete_Information_Page @Actor int,@ID int,@ExpectedVersion int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Version int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'إدارة الصفحات لمدير النظام فقط.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 SELECT @Version=VersionNumber FROM dbo.Information_Pages WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0;
 IF @Version IS NULL THROW 51600,N'الصفحة غير موجودة أو محذوفة.',1;
 IF @ExpectedVersion IS NULL OR @Version<>@ExpectedVersion THROW 51600,N'تم تعديل الصفحة. حدّث القائمة قبل الحذف.',1;
 SET @Version=@Version+1;
 UPDATE dbo.Information_Pages SET IsDeleted=1,IsPublished=0,VersionNumber=@Version,
 DeletedBy=@Actor,DeletedUtc=@Now,ModifiedBy=@Actor,ModifiedUtc=@Now WHERE ID=@ID;
 INSERT dbo.Information_Page_Versions
 (PageID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,Action,ActorID,ActorName,OccurredUtc)
 SELECT ID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,'delete',@Actor,@Name,@Now
 FROM dbo.Information_Pages WHERE ID=@ID;
 INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc)
 VALUES(@ID,@Version,'delete',@Actor,@Name,@Now);
 COMMIT;
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
 SELECT v.*,p.CreatedUtc,p.ModifiedUtc,p.DeletedUtc,p.AllUserTypes,p.AccessRevision FROM dbo.Information_Page_Versions v
 JOIN dbo.Information_Pages p ON p.ID=v.PageID WHERE v.PageID=@ID AND v.VersionNumber=@Version;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_History @Actor int,@ID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51600,N'السجلات لمدير النظام فقط.',1;
 SELECT v.PageID,v.VersionNumber,v.Title_Ar,v.Title_En,v.Action,v.ActorID,v.ActorName,v.OccurredUtc,
 v.IsPublished,v.PublishMode,v.StartUtc,v.EndUtc,v.IsDeleted,v.RestoredFromVersion,p.VersionNumber CurrentVersion,
 CONVERT(bit,CASE WHEN p.IsDeleted=0 AND v.IsDeleted=0 AND v.VersionNumber<p.VersionNumber THEN 1 ELSE 0 END) CanRestore
 FROM dbo.Information_Page_Versions v JOIN dbo.Information_Pages p ON p.ID=v.PageID
 WHERE v.PageID=@ID ORDER BY v.VersionNumber DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_Logs
 @Actor int,@ID int=0,@Action varchar(10)='',@Search nvarchar(250)=N'',@Offset int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51600,N'السجلات لمدير النظام فقط.',1;
 IF @Offset<0 THROW 51600,N'رقم الصفحة غير صحيح.',1;
 SELECT l.*,v.Title_Ar,v.Title_En,COUNT(*) OVER() TotalRows FROM dbo.Information_Page_Logs l
 JOIN dbo.Information_Page_Versions v ON v.PageID=l.PageID AND v.VersionNumber=l.VersionNumber
 WHERE (@ID=0 OR l.PageID=@ID) AND (@Action='' OR l.Action=@Action)
 AND (@Search=N'' OR CHARINDEX(@Search,l.ActorName)>0)
 ORDER BY l.OccurredUtc DESC,l.ID DESC OFFSET @Offset ROWS FETCH NEXT 50 ROWS ONLY;
END;
