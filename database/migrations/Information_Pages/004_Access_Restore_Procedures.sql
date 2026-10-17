CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_Roles @Actor int,@ID int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51600,N'إدارة الصلاحيات لمدير النظام فقط.',1;
 SELECT t.ID,t.Title_Ar,t.IsActive,
 CONVERT(bit,CASE WHEN r.UserTypeID IS NULL THEN 0 ELSE 1 END) IsSelected
 FROM dbo.Users_Types t LEFT JOIN dbo.Information_Page_Roles r ON r.PageID=@ID AND r.UserTypeID=t.ID
 WHERE (ISNULL(t.IsDeleted,0)=0 AND t.IsActive=1) OR r.UserTypeID IS NOT NULL
 ORDER BY t.Item_Order,t.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Save_Information_Page_Access
 @Actor int,@ID int,@ExpectedRevision int,@AllTypes bit,@Roles xml,@Brands xml=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Revision int,@OldAll bit,@Version int,@Before nvarchar(max),@After nvarchar(max);
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'إدارة الصلاحيات لمدير النظام فقط.',1;
 IF @AllTypes IS NULL THROW 51600,N'اختر صلاحيات الاطلاع.',1;
 DECLARE @Selected TABLE(ID int PRIMARY KEY);
 IF @AllTypes=0
 BEGIN
  INSERT @Selected SELECT DISTINCT n.value('@id','int') FROM @Roles.nodes('/roles/role') x(n);
  IF NOT EXISTS(SELECT 1 FROM @Selected) THROW 51600,N'اختر نوع مستخدم واحدًا على الأقل.',1;
  IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.Users_Types t ON t.ID=s.ID
    WHERE t.ID IS NULL OR t.IsActive<>1 OR ISNULL(t.IsDeleted,0)<>0)
   THROW 51600,N'اختر أنواع مستخدمين فعالة وغير محذوفة.',1;
 END;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @SelectedBrands TABLE(ID int PRIMARY KEY);
 IF @Brands IS NOT NULL
 BEGIN
  INSERT @SelectedBrands SELECT DISTINCT n.value('@id','int') FROM @Brands.nodes('/brands/brand') x(n);
  IF NOT EXISTS(SELECT 1 FROM @SelectedBrands) THROW 51600,N'اختر علامة تجارية واحدة على الأقل.',1;
  IF EXISTS(SELECT 1 FROM @SelectedBrands s LEFT JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=s.ID
    WHERE b.ID IS NULL OR ISNULL(b.IsActive,0)<>1 OR ISNULL(b.IsDeleted,0)<>0)
   THROW 51600,N'اختر علامات تجارية فعالة وغير محذوفة.',1;
 END;
 SELECT @Revision=AccessRevision,@OldAll=AllUserTypes,@Version=VersionNumber
 FROM dbo.Information_Pages WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0;
 IF @Revision IS NULL THROW 51600,N'الصفحة غير موجودة أو محذوفة.',1;
 IF @ExpectedRevision IS NULL OR @Revision<>@ExpectedRevision THROW 51600,N'تغيرت صلاحيات الصفحة. أعد فتحها قبل الحفظ.',1;
 IF @OldAll<>@AllTypes
 OR EXISTS(SELECT UserTypeID FROM dbo.Information_Page_Roles WHERE PageID=@ID EXCEPT SELECT ID FROM @Selected)
 OR EXISTS(SELECT ID FROM @Selected EXCEPT SELECT UserTypeID FROM dbo.Information_Page_Roles WHERE PageID=@ID)
 OR (@Brands IS NOT NULL AND (
 EXISTS(SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=@ID EXCEPT SELECT ID FROM @SelectedBrands)
 OR EXISTS(SELECT ID FROM @SelectedBrands EXCEPT SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=@ID)))
 BEGIN
  SET @Before=CASE WHEN @OldAll=1 THEN N'جميع المستخدمين' ELSE
   STUFF((SELECT N'، '+COALESCE(t.Title_Ar,CONVERT(nvarchar(20),r.UserTypeID))
   FROM dbo.Information_Page_Roles r LEFT JOIN dbo.Users_Types t ON t.ID=r.UserTypeID
   WHERE r.PageID=@ID ORDER BY r.UserTypeID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'') END;
  SET @After=CASE WHEN @AllTypes=1 THEN N'جميع المستخدمين' ELSE
   STUFF((SELECT N'، '+COALESCE(t.Title_Ar,CONVERT(nvarchar(20),s.ID)) FROM @Selected s JOIN dbo.Users_Types t ON t.ID=s.ID
  ORDER BY s.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'') END;
  IF @Brands IS NOT NULL
  BEGIN
   SET @Before=COALESCE(@Before,N'')+N'؛ العلامات: '+COALESCE(STUFF((SELECT N'، '+COALESCE(b.Title_Ar,b.Title_En,CONVERT(nvarchar(20),b.ID))
    FROM dbo.Information_Page_Brands pb JOIN dbo.Brands b ON b.ID=pb.BrandID WHERE pb.PageID=@ID
    ORDER BY b.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N''),N'لا توجد');
   SET @After=COALESCE(@After,N'')+N'؛ العلامات: '+STUFF((SELECT N'، '+COALESCE(b.Title_Ar,b.Title_En,CONVERT(nvarchar(20),b.ID))
    FROM @SelectedBrands s JOIN dbo.Brands b ON b.ID=s.ID
    ORDER BY b.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'');
   DELETE dbo.Information_Page_Brands WHERE PageID=@ID;
   INSERT dbo.Information_Page_Brands(PageID,BrandID) SELECT @ID,ID FROM @SelectedBrands;
  END;
  DELETE dbo.Information_Page_Roles WHERE PageID=@ID;
  INSERT dbo.Information_Page_Roles(PageID,UserTypeID) SELECT @ID,ID FROM @Selected;
  UPDATE dbo.Information_Pages SET AllUserTypes=@AllTypes,AccessRevision=AccessRevision+1 WHERE ID=@ID;
  INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Details)
  VALUES(@ID,@Version,'access',@Actor,@Name,SYSUTCDATETIME(),N'صلاحيات الاطلاع: من ['+COALESCE(@Before,N'')+N'] إلى ['+@After+N'].');
 END;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Restore_Information_Page
 @Actor int,@ID int,@SourceVersion int,@ExpectedVersion int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Name nvarchar(500),@Current int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @Name=COALESCE(NULLIF(FullName_Ar,N''),NULLIF(FullName_En,N''),CONVERT(nvarchar(20),ID))
 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Name IS NULL THROW 51600,N'استرجاع الإصدارات لمدير النظام فقط.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 SELECT @Current=VersionNumber FROM dbo.Information_Pages WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0;
 IF @Current IS NULL THROW 51600,N'الصفحة غير موجودة أو محذوفة.',1;
 IF @ExpectedVersion IS NULL OR @Current<>@ExpectedVersion THROW 51600,N'تم تعديل الصفحة. حدّث سجل الإصدارات قبل الاسترجاع.',1;
 IF @SourceVersion IS NULL OR @SourceVersion>=@Current OR NOT EXISTS(
  SELECT 1 FROM dbo.Information_Page_Versions WHERE PageID=@ID AND VersionNumber=@SourceVersion AND IsDeleted=0)
 THROW 51600,N'اختر إصدارًا سابقًا غير محذوف من هذه الصفحة.',1;
 UPDATE p SET Title_Ar=v.Title_Ar,Title_En=v.Title_En,Summary_Ar=v.Summary_Ar,Summary_En=v.Summary_En,
 Details_Ar=v.Details_Ar,Details_En=v.Details_En,Item_Order=v.Item_Order,IsPublished=v.IsPublished,
 PublishMode=v.PublishMode,StartUtc=v.StartUtc,EndUtc=v.EndUtc,VersionNumber=@Current+1,
 ModifiedBy=@Actor,ModifiedUtc=@Now
 FROM dbo.Information_Pages p JOIN dbo.Information_Page_Versions v ON v.PageID=p.ID
 WHERE p.ID=@ID AND v.VersionNumber=@SourceVersion;
 INSERT dbo.Information_Page_Versions
 (PageID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,Action,ActorID,ActorName,OccurredUtc,RestoredFromVersion)
 SELECT ID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,StartUtc,EndUtc,IsDeleted,'restore',@Actor,@Name,@Now,@SourceVersion
 FROM dbo.Information_Pages WHERE ID=@ID;
 INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Details)
 VALUES(@ID,@Current+1,'restore',@Actor,@Name,@Now,N'استرجاع الإصدار '+CONVERT(nvarchar(20),@SourceVersion)+N' كإصدار جديد؛ صلاحيات الاطلاع الحالية لم تتغير.');
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
