-- Apply after 006. Catalog edits never rewrite thread snapshots.
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dbo.Correspondence_Catalog','U') IS NULL
BEGIN
 CREATE TABLE dbo.Correspondence_Catalog(
  ID int IDENTITY PRIMARY KEY,Kind char(1) NOT NULL CHECK(Kind IN('P','R')),
  Title nvarchar(200) NOT NULL,SortOrder int NOT NULL DEFAULT(10),IsUrgent bit NOT NULL DEFAULT(0),
  Behavior varchar(12) NOT NULL DEFAULT('normal') CHECK(Behavior IN('normal','transfer')),
  IsActive bit NOT NULL DEFAULT(1),IsDeleted bit NOT NULL DEFAULT(0),
  ModifiedBy int NULL,ModifiedAt datetime2 NOT NULL DEFAULT(SYSUTCDATETIME()),Version rowversion);
 CREATE UNIQUE INDEX UX_Correspondence_Catalog_Title ON dbo.Correspondence_Catalog(Kind,Title) WHERE IsDeleted=0;
 SET IDENTITY_INSERT dbo.Correspondence_Catalog ON;
 INSERT dbo.Correspondence_Catalog(ID,Kind,Title,SortOrder,IsUrgent,Behavior) VALUES
 (1,'P',N'عادية',10,0,'normal'),(2,'P',N'عاجلة',20,1,'normal'),
 (3,'R',N'إنهاء المراسلة',10,0,'normal'),(4,'R',N'نقل المسؤولية إلى تكليف جديد',20,0,'transfer');
 SET IDENTITY_INSERT dbo.Correspondence_Catalog OFF;
END;
IF OBJECT_ID('dbo.Correspondence_CatalogAudit','U') IS NULL
 CREATE TABLE dbo.Correspondence_CatalogAudit(ID bigint IDENTITY PRIMARY KEY,CatalogID int NOT NULL,ActorID int NOT NULL,
 Action varchar(12) NOT NULL,BeforeData nvarchar(max) NULL,AfterData nvarchar(max) NULL,CreatedAt datetime2 NOT NULL DEFAULT(SYSUTCDATETIME()));
GO
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.Correspondence_Threads') AND name='Priority' AND system_type_id<>56)
BEGIN
 DECLARE @DefaultName sysname,@DropDefault nvarchar(max);
 SELECT @DefaultName=d.name FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE c.object_id=OBJECT_ID('dbo.Correspondence_Threads') AND c.name='Priority';
 IF @DefaultName IS NOT NULL BEGIN SET @DropDefault=N'ALTER TABLE dbo.Correspondence_Threads DROP CONSTRAINT '+QUOTENAME(@DefaultName);EXEC sys.sp_executesql @DropDefault;END;
 ALTER TABLE dbo.Correspondence_Threads ALTER COLUMN Priority int NOT NULL;
 ALTER TABLE dbo.Correspondence_Threads ADD CONSTRAINT DF_Correspondence_Priority DEFAULT(1) FOR Priority;
END;
IF COL_LENGTH('dbo.Correspondence_Threads','PriorityName') IS NULL
 ALTER TABLE dbo.Correspondence_Threads ADD PriorityName nvarchar(200) NULL,PriorityRank int NULL,PriorityUrgent bit NULL,
 ClosureReasonID int NULL,ClosureReasonName nvarchar(200) NULL;
GO
UPDATE dbo.Correspondence_Threads SET PriorityName=CASE Priority WHEN 2 THEN N'عاجلة' ELSE N'عادية' END,
 PriorityRank=CASE Priority WHEN 2 THEN 20 ELSE 10 END,PriorityUrgent=CASE Priority WHEN 2 THEN 1 ELSE 0 END WHERE PriorityName IS NULL;
UPDATE dbo.Correspondence_Threads SET ClosureReasonID=CASE WHEN ClosureKind='transfer' THEN 4 ELSE 3 END,
 ClosureReasonName=CASE WHEN ClosureKind='transfer' THEN N'نقل المسؤولية إلى تكليف جديد' ELSE N'إنهاء المراسلة' END
 WHERE CloseDate IS NOT NULL AND ClosureReasonID IS NULL;
GO
EXEC sys.sp_refreshview N'dbo.Correspondence_Overview';
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_CatalogList @Actor int,@Kind char(1),@Mode int=0,@Task bit=1
AS
BEGIN
 SET NOCOUNT ON;
 IF @Kind NOT IN('P','R') OR @Mode NOT IN(0,1,2) OR NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Mode<>2 OR Type=1))
 THROW 51400,N'غير مسموح بإدارة تعريفات المراسلات.',1;
 SELECT c.*,CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.Correspondence_Threads t WHERE (c.Kind='P' AND t.Priority=c.ID) OR (c.Kind='R' AND t.ClosureReasonID=c.ID)) THEN 1 ELSE 0 END AS bit) IsUsed
 FROM dbo.Correspondence_Catalog c WHERE Kind=@Kind AND IsDeleted=0
 AND (@Mode<>0 OR (IsActive=1 AND (@Kind='P' OR @Task=1 OR Behavior='normal')))
 ORDER BY SortOrder DESC,ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_CatalogSave
 @Actor int,@Kind char(1),@ID int=0,@Title nvarchar(200),@SortOrder int=10,@IsUrgent bit=0,@Behavior varchar(12)='normal',@IsActive bit=1,@Version binary(8)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51400,N'إدارة التعريفات متاحة لمدير النظام فقط.',1;
 SET @Title=LTRIM(RTRIM(@Title));
 IF @Kind NOT IN('P','R') OR @Kind IS NULL OR NULLIF(@Title,'') IS NULL OR @SortOrder NOT BETWEEN 0 AND 999 OR @SortOrder IS NULL OR @Behavior NOT IN('normal','transfer') OR @Behavior IS NULL
 THROW 51400,N'أدخل اسمًا صحيحًا ودرجة ترتيب بين 0 و999.',1;
 IF @Kind='P' SET @Behavior='normal';
 IF @Kind='R' SET @IsUrgent=0;
 BEGIN TRAN;
 DECLARE @Before nvarchar(max),@After nvarchar(max);
 IF @ID<>0
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Catalog WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Kind=@Kind AND IsDeleted=0 AND Version=@Version)
   BEGIN ROLLBACK;THROW 51400,N'تغير التعريف أو حُذف؛ حدّث الصفحة قبل الحفظ.',1;END;
  SET @Before=(SELECT Title,SortOrder,IsUrgent,Behavior,IsActive,IsDeleted FROM dbo.Correspondence_Catalog WHERE ID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END;
 IF EXISTS(SELECT 1 FROM dbo.Correspondence_Catalog WITH(UPDLOCK,HOLDLOCK) WHERE Kind=@Kind AND Title=@Title AND IsDeleted=0 AND ID<>@ID)
  BEGIN ROLLBACK;THROW 51400,N'الاسم مستخدم بالفعل ضمن هذه القائمة.',1;END;
 IF @ID=0
 BEGIN
  INSERT dbo.Correspondence_Catalog(Kind,Title,SortOrder,IsUrgent,Behavior,IsActive,ModifiedBy) VALUES(@Kind,@Title,@SortOrder,@IsUrgent,@Behavior,@IsActive,@Actor);
  SET @ID=SCOPE_IDENTITY();
 END
 ELSE UPDATE dbo.Correspondence_Catalog SET Title=@Title,SortOrder=@SortOrder,IsUrgent=@IsUrgent,Behavior=@Behavior,IsActive=@IsActive,ModifiedBy=@Actor,ModifiedAt=SYSUTCDATETIME() WHERE ID=@ID;
 SET @After=(SELECT Title,SortOrder,IsUrgent,Behavior,IsActive,IsDeleted FROM dbo.Correspondence_Catalog WHERE ID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT dbo.Correspondence_CatalogAudit(CatalogID,ActorID,Action,BeforeData,AfterData) VALUES(@ID,@Actor,CASE WHEN @Before IS NULL THEN 'create' ELSE 'edit' END,@Before,@After);
 COMMIT;SELECT @ID ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_CatalogState @Actor int,@ID int,@Action varchar(12),@Version binary(8)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51400,N'إدارة التعريفات متاحة لمدير النظام فقط.',1;
 IF @Action NOT IN('activate','deactivate','delete') OR @Action IS NULL THROW 51400,N'الإجراء غير صحيح.',1;
 BEGIN TRAN;
 DECLARE @Kind char(1),@Before nvarchar(max),@After nvarchar(max);
 SELECT @Kind=Kind FROM dbo.Correspondence_Catalog WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0 AND Version=@Version;
 IF @Kind IS NULL BEGIN ROLLBACK;THROW 51400,N'تغير التعريف؛ حدّث الصفحة وأعد المحاولة.',1;END;
 IF @Action='delete' AND EXISTS(SELECT 1 FROM dbo.Correspondence_Threads WHERE (@Kind='P' AND Priority=@ID) OR (@Kind='R' AND ClosureReasonID=@ID))
  BEGIN ROLLBACK;THROW 51400,N'لا يمكن حذف خيار مرتبط بمراسلات سابقة؛ يمكنك إيقافه لمنع استخدامه مستقبلًا.',1;END;
 SET @Before=(SELECT Title,SortOrder,IsUrgent,Behavior,IsActive,IsDeleted FROM dbo.Correspondence_Catalog WHERE ID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 UPDATE dbo.Correspondence_Catalog SET IsActive=CASE WHEN @Action='activate' THEN 1 ELSE 0 END,IsDeleted=CASE WHEN @Action='delete' THEN 1 ELSE 0 END,ModifiedBy=@Actor,ModifiedAt=SYSUTCDATETIME() WHERE ID=@ID;
 SET @After=(SELECT Title,SortOrder,IsUrgent,Behavior,IsActive,IsDeleted FROM dbo.Correspondence_Catalog WHERE ID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT dbo.Correspondence_CatalogAudit(CatalogID,ActorID,Action,BeforeData,AfterData) VALUES(@ID,@Actor,@Action,@Before,@After);
 COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread
 @Actor int,@Brand int,@Recipients xml,@Title nvarchar(200),@Brief nvarchar(2000),@Body nvarchar(4000),@RequiresCompletion bit,@DueDate datetime,@Files xml,@Priority int=1,@RelatedThreadID int=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 DECLARE @ThreadID int;
  IF @Type NOT IN(1,2,3,4) THROW 51400,N'يمكنك الرد على المحادثات الواردة فقط.',1;
  IF NULLIF(LTRIM(RTRIM(@Title)),'') IS NULL THROW 51400,N'أدخل عنوان المحادثة.',1;
  IF NULLIF(LTRIM(RTRIM(@Body)),'') IS NULL AND ISNULL(@Files.exist('/files/file'),0)=0 THROW 51400,N'أدخل الرسالة الأولى أو أرفق ملفًا.',1;
  IF @Type=4 AND (@RequiresCompletion=1 OR @DueDate IS NOT NULL) THROW 51400,N'تحديد الإنجاز والموعد متاح للمدير فقط.',1;
  IF @DueDate IS NOT NULL AND @DueDate<=@Now THROW 51400,N'يجب أن يكون الموعد المحدد في المستقبل.',1;
  DECLARE @Targets TABLE(ID int PRIMARY KEY);
  INSERT @Targets SELECT DISTINCT x.n.value('@id','int') FROM @Recipients.nodes('/items/item') x(n);
  DECLARE @Count int=(SELECT COUNT(*) FROM @Targets),@Batch uniqueidentifier=NULL;
  IF @Count=0 OR (@Type=4 AND @Count<>1) THROW 51400,N'اختر المستلم المناسب.',1;
  IF @Count>1 SET @Batch=NEWID();

  BEGIN TRANSACTION;
  DECLARE @PriorityName nvarchar(200),@PriorityRank int,@PriorityUrgent bit;
  SELECT @PriorityName=Title,@PriorityRank=SortOrder,@PriorityUrgent=IsUrgent FROM dbo.Correspondence_Catalog WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Priority AND Kind='P' AND IsActive=1 AND IsDeleted=0;
  IF @PriorityName IS NULL BEGIN ROLLBACK;THROW 51400,N'اختر أولوية فعالة؛ قد تكون الخيارات قد تغيرت.',1;END;
  IF @RelatedThreadID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK)
   WHERE ID=@RelatedThreadID AND CreatedBy=@Actor AND RequiresCompletion=1 AND CloseDate IS NOT NULL
    AND ArchivedAt IS NULL AND ClosureKind='transfer' AND ISNULL(IsDeleted,0)=0)
   BEGIN ROLLBACK;THROW 51400,N'التكليف السابق غير متاح لنقل المسؤولية.',1;END;
  IF @RelatedThreadID IS NOT NULL AND @RequiresCompletion<>1
   BEGIN ROLLBACK;THROW 51400,N'نقل المسؤولية يتطلب تكليفًا جديدًا.',1;END;
  IF EXISTS(SELECT 1 FROM @Targets r WHERE NOT EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) a WHERE a.ID=r.ID))
  BEGIN ROLLBACK; THROW 51400,N'أحد المستلمين خارج نطاق المراسلة المسموح لك.',1; END;
  DECLARE @Created TABLE(ID int);
  DECLARE recipients CURSOR LOCAL FAST_FORWARD FOR SELECT ID FROM @Targets;
  OPEN recipients;FETCH NEXT FROM recipients INTO @Target;
  WHILE @@FETCH_STATUS=0
  BEGIN
   INSERT dbo.Correspondence_Threads(Title,Brief,SenderID,ReceiverID,RequiresCompletion,DueDate,Status,CreatedDate,CreatedBy,IsDeleted,IsBroadcast,BroadcastID,Priority,RelatedThreadID,PriorityName,PriorityRank,PriorityUrgent)
    VALUES(@Title,@Brief,@Actor,@Target,@RequiresCompletion,@DueDate,1,@Now,@Actor,0,CASE WHEN @Count>1 THEN 1 ELSE 0 END,@Batch,@Priority,@RelatedThreadID,@PriorityName,@PriorityRank,@PriorityUrgent);
   SET @ThreadID=SCOPE_IDENTITY(); INSERT @Created VALUES(@ThreadID);
   INSERT dbo.Correspondence_Parties(ThreadID,UserID,FullName,UserType,BrandID,BrandName,BranchID,BranchName,DepartmentID,DepartmentName,JobTitleID,JobTitleName,ShiftID,ShiftName,CapturedAt)
   SELECT @ThreadID,u.ID,u.FullName_Ar,u.Type,u.Brand_ID,b.Title_Ar,u.Branch_ID,br.Title_Ar,u.Department_ID,d.Title_Ar,u.JobTitle_ID,j.Title_Ar,u.Shif_ID,s.Title_Ar,@Now
   FROM dbo.UsersMembers u LEFT JOIN dbo.Brands b ON b.ID=u.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=u.Branch_ID
   LEFT JOIN dbo.Departments d ON d.ID=u.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=u.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=u.Shif_ID
   WHERE u.ID IN(@Actor,@Target);
   INSERT dbo.Correspondence_Thread_Messages(ThreadID,SenderID,ReceivedID,Body,CreatedDate,IsRead) VALUES(@ThreadID,@Actor,@Target,@Body,@Now,0);
   SET @Message=SCOPE_IDENTITY();
   INSERT dbo.Correspondence_Message_Attachments(MessageID,FileName,File_Type,FileSize,CreatedDate)
    SELECT @Message,x.n.value('@name','nvarchar(255)'),x.n.value('@type','nvarchar(100)'),x.n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') x(n);
   INSERT dbo.Correspondence_Notifications(UserID,ThreadID,MessageID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Message,@Now,0);
   FETCH NEXT FROM recipients INTO @Target;
  END;
  CLOSE recipients;DEALLOCATE recipients;COMMIT;
  SELECT ID FROM @Created;RETURN;
END;

GO

CREATE OR ALTER PROCEDURE dbo.Update_Correspondence_Thread_Close
 @Actor int,@ThreadID int,@IsCompleted bit,@ClosureKind varchar(12)='normal',@CloseReason nvarchar(1000)=NULL,@ClosureReasonID int=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
 DECLARE @ClosureReasonName nvarchar(200);
 IF @ClosureReasonID IS NULL SET @ClosureReasonID=CASE @ClosureKind WHEN 'normal' THEN 3 WHEN 'transfer' THEN 4 END;
 SELECT @ClosureReasonName=Title,@ClosureKind=Behavior FROM dbo.Correspondence_Catalog WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ClosureReasonID AND Kind='R' AND IsActive=1 AND IsDeleted=0;
 IF @ClosureReasonName IS NULL BEGIN ROLLBACK;THROW 51400,N'اختر سبب إنهاء فعالًا؛ قد تكون الخيارات قد تغيرت.',1;END;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=COALESCE(CloseDate,ArchivedAt),@Required=RequiresCompletion
 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ThreadID AND ISNULL(IsDeleted,0)=0 AND @Actor IN(SenderID,ReceiverID);
 IF @Sender IS NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة غير متاحة لك.',1;END;
 IF @Closed IS NOT NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة منتهية؛ لا يمكن إضافة ردود أو إغلاقها مرة أخرى.',1;END;
 SET @Target=CASE WHEN @Actor=@Sender THEN @Receiver ELSE @Sender END;
  IF @Actor<>@Creator BEGIN ROLLBACK;THROW 51400,N'منشئ المحادثة فقط يستطيع إغلاقها.',1;END;
  IF ISNULL(@ClosureKind,'normal')<>'transfer' AND NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=@ThreadID AND SenderID<>@Creator AND ReceivedID=@Creator)
  BEGIN ROLLBACK;THROW 51400,N'يمكن الإغلاق بعد تلقي رد من الطرف الآخر.',1;END;
  IF @Required=1 AND @IsCompleted IS NULL BEGIN ROLLBACK;THROW 51400,N'حدد هل تم الإنجاز أم لا.',1;END;
  IF @ClosureKind NOT IN('normal','transfer') OR @ClosureKind IS NULL
   BEGIN ROLLBACK;THROW 51400,N'سبب الإغلاق غير صحيح.',1;END;
  IF @ClosureKind='transfer' AND (@Required<>1 OR NULLIF(LTRIM(RTRIM(@CloseReason)),'') IS NULL)
   BEGIN ROLLBACK;THROW 51400,N'نقل المسؤولية خاص بالتكليف ويتطلب توضيح السبب.',1;END;
  UPDATE dbo.Correspondence_Threads SET ClosureReasonID=@ClosureReasonID,ClosureReasonName=@ClosureReasonName,ClosureKind=@ClosureKind,CloseReason=@CloseReason,CloseDate=@Now,Status=3,IsCompleted=CASE WHEN @Required=1 THEN @IsCompleted ELSE NULL END,ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
  INSERT dbo.Correspondence_Notifications(UserID,ThreadID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Now,0);
  COMMIT;RETURN;
END;

GO
