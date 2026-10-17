-- Official correspondence governance. Apply after 005; existing snapshots stay unknown.
SET XACT_ABORT ON;
GO
IF COL_LENGTH('dbo.Correspondence_Threads','Priority') IS NULL
 ALTER TABLE dbo.Correspondence_Threads ADD Priority tinyint NOT NULL CONSTRAINT DF_Correspondence_Priority DEFAULT(1),
 ArchivedAt datetime NULL, ArchivedBy int NULL, ArchiveReason nvarchar(1000) NULL,
 CloseReason nvarchar(1000) NULL, ClosureKind varchar(12) NULL, RelatedThreadID int NULL;
GO
IF OBJECT_ID('dbo.Correspondence_Parties','U') IS NULL
CREATE TABLE dbo.Correspondence_Parties(
 ThreadID int NOT NULL REFERENCES dbo.Correspondence_Threads(ID), UserID int NOT NULL,
 FullName nvarchar(500) NULL, UserType int NULL,
 BrandID int NULL, BrandName nvarchar(500) NULL, BranchID int NULL, BranchName nvarchar(500) NULL,
 DepartmentID int NULL, DepartmentName nvarchar(500) NULL, JobTitleID int NULL, JobTitleName nvarchar(500) NULL,
 ShiftID int NULL, ShiftName nvarchar(500) NULL, CapturedAt datetime NOT NULL,
 CONSTRAINT PK_Correspondence_Parties PRIMARY KEY(ThreadID,UserID));
IF OBJECT_ID('dbo.Correspondence_Audit','U') IS NULL
CREATE TABLE dbo.Correspondence_Audit(
 ID bigint IDENTITY PRIMARY KEY, ThreadID int NOT NULL REFERENCES dbo.Correspondence_Threads(ID),
 ActorID int NOT NULL, ActorName nvarchar(500) NULL, Action varchar(20) NOT NULL,
 EventID uniqueidentifier NOT NULL, CreatedAt datetime NOT NULL DEFAULT(GETUTCDATE()), Note nvarchar(1000) NULL,
 CONSTRAINT UQ_Correspondence_Audit_Event UNIQUE(ActorID,ThreadID,Action,EventID));
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread
 @Actor int,@Brand int,@Recipients xml,@Title nvarchar(200),@Brief nvarchar(2000),@Body nvarchar(4000),@RequiresCompletion bit,@DueDate datetime,@Files xml,@Priority tinyint=1,@RelatedThreadID int=NULL
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
  IF @Priority NOT IN(1,2) OR @Priority IS NULL THROW 51400,N'الأولوية غير صحيحة.',1;
  BEGIN TRANSACTION;
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
   INSERT dbo.Correspondence_Threads(Title,Brief,SenderID,ReceiverID,RequiresCompletion,DueDate,Status,CreatedDate,CreatedBy,IsDeleted,IsBroadcast,BroadcastID,Priority,RelatedThreadID)
    VALUES(@Title,@Brief,@Actor,@Target,@RequiresCompletion,@DueDate,1,@Now,@Actor,0,CASE WHEN @Count>1 THEN 1 ELSE 0 END,@Batch,@Priority,@RelatedThreadID);
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
CREATE OR ALTER FUNCTION dbo.Correspondence_Access(@Actor int)
RETURNS TABLE AS RETURN
 SELECT t.ID,CAST(CASE WHEN @Actor IN(t.SenderID,t.ReceiverID) THEN 1 ELSE 0 END AS bit) IsParticipant,
 CAST(CASE WHEN u.Type=1 THEN 1 ELSE 0 END AS bit) IsAdmin
 FROM dbo.Correspondence_Threads t JOIN dbo.UsersMembers u ON u.ID=@Actor AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0
 WHERE ISNULL(t.IsDeleted,0)=0 AND (u.Type=1 OR @Actor IN(t.SenderID,t.ReceiverID));
GO
CREATE OR ALTER VIEW dbo.Correspondence_Overview AS
 SELECT t.*,COALESCE(ps.FullName,s.FullName_Ar) SenderName,COALESCE(pr.FullName,r.FullName_Ar) ReceiverName,
 s.User_Image SenderImage,r.User_Image ReceiverImage,
 ps.BrandID SenderBrandID,ps.BranchID SenderBranchID,pr.BrandID ReceiverBrandID,pr.BranchID ReceiverBranchID,
 ps.BrandName SenderBrandName,ps.BranchName SenderBranchName,pr.BrandName ReceiverBrandName,pr.BranchName ReceiverBranchName,
 CAST(CASE WHEN ps.ThreadID IS NULL OR pr.ThreadID IS NULL THEN 1 ELSE 0 END AS bit) LegacyOrganization,
 CAST(CASE WHEN ISNULL(s.IsActive,0)=0 OR ISNULL(s.IsDeleted,0)=1 OR ISNULL(r.IsActive,0)=0 OR ISNULL(r.IsDeleted,0)=1 THEN 1 ELSE 0 END AS bit) InactiveParty,
 CAST(CASE WHEN ISNULL(c.IsActive,0)=0 OR ISNULL(c.IsDeleted,0)=1 THEN 1 ELSE 0 END AS bit) InactiveCreator,
 m.MessageCount,m.LastMessageDate,reply.FirstReplyDate,
 DATEDIFF_BIG(second,t.CreatedDate,reply.FirstReplyDate) FirstReplySeconds,
 CASE WHEN t.ArchivedAt IS NOT NULL THEN 'archived' WHEN t.CloseDate IS NOT NULL THEN 'closed'
 WHEN t.DueDate<GETUTCDATE() THEN 'overdue' ELSE 'active' END State
 FROM dbo.Correspondence_Threads t LEFT JOIN dbo.UsersMembers s ON s.ID=t.SenderID
 LEFT JOIN dbo.UsersMembers r ON r.ID=t.ReceiverID LEFT JOIN dbo.UsersMembers c ON c.ID=t.CreatedBy
 LEFT JOIN dbo.Correspondence_Parties ps ON ps.ThreadID=t.ID AND ps.UserID=t.SenderID
 LEFT JOIN dbo.Correspondence_Parties pr ON pr.ThreadID=t.ID AND pr.UserID=t.ReceiverID
 OUTER APPLY(SELECT COUNT(*) MessageCount,MAX(CreatedDate) LastMessageDate FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=t.ID) m
 OUTER APPLY(SELECT MIN(CreatedDate) FirstReplyDate FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=t.ID AND SenderID<>t.CreatedBy) reply;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Browse
 @Actor int,@All bit=0,@Person nvarchar(200)=NULL,@Title nvarchar(200)=NULL,@Filter varchar(16)='all',
 @Brand int=0,@Branch int=0,@Sender nvarchar(200)=NULL,@Receiver nvarchar(200)=NULL,
 @From datetime=NULL,@To datetime=NULL,@Kind int=0,@Priority int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@All=0 OR Type=1))
  THROW 51400,N'غير مسموح بالاطلاع على المراسلات.',1;
 SELECT o.*,a.IsParticipant,a.IsAdmin,
 CASE WHEN @All=1 THEN o.SenderName+N' ← '+o.ReceiverName WHEN o.SenderID=@Actor THEN o.ReceiverName ELSE o.SenderName END OtherName,
 CASE WHEN o.SenderID=@Actor THEN o.ReceiverImage ELSE o.SenderImage END OtherImage,
 (SELECT COUNT(*) FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=o.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0) UnreadCount
 FROM dbo.Correspondence_Overview o JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=o.ID
 WHERE (@All=1 OR a.IsParticipant=1)
 AND (NULLIF(@Person,'') IS NULL OR o.SenderName LIKE N'%'+@Person+N'%' OR o.ReceiverName LIKE N'%'+@Person+N'%')
 AND (NULLIF(@Title,'') IS NULL OR o.Title LIKE N'%'+@Title+N'%')
 AND (NULLIF(@Sender,'') IS NULL OR o.SenderName LIKE N'%'+@Sender+N'%')
 AND (NULLIF(@Receiver,'') IS NULL OR o.ReceiverName LIKE N'%'+@Receiver+N'%')
 AND (@Brand=0 OR o.SenderBrandID=@Brand OR o.ReceiverBrandID=@Brand)
 AND (@Branch=0 OR o.SenderBranchID=@Branch OR o.ReceiverBranchID=@Branch)
 AND (@From IS NULL OR o.CreatedDate>=@From) AND (@To IS NULL OR o.CreatedDate<@To)
 AND (@Kind=0 OR (@Kind=1 AND ISNULL(o.RequiresCompletion,0)=0) OR (@Kind=2 AND o.RequiresCompletion=1))
 AND (@Priority=0 OR o.Priority=@Priority)
 AND (@Filter='all' OR @Filter=o.State
  OR (@Filter='noReply' AND o.FirstReplyDate IS NULL AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL)
  OR (@Filter='followup' AND o.InactiveParty=1 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL)
  OR (@Filter='legacy' AND o.LegacyOrganization=1)
  OR (@Filter='unread' AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=o.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0)))
 OPTION(RECOMPILE, LOOP JOIN);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Detail @Actor int,@ThreadID int,@Supervisory bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID AND (@Supervisory=0 OR IsAdmin=1))
  THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT o.*,a.IsParticipant,a.IsAdmin,
 CAST(CASE WHEN a.IsParticipant=1 AND @Supervisory=0 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL THEN 1 ELSE 0 END AS bit) CanReply,
 CAST(CASE WHEN o.CreatedBy=@Actor AND @Supervisory=0 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL AND (o.FirstReplyDate IS NOT NULL OR o.RequiresCompletion=1) THEN 1 ELSE 0 END AS bit) CanClose,
 CAST(CASE WHEN a.IsAdmin=1 AND o.InactiveCreator=1 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL THEN 1 ELSE 0 END AS bit) CanArchive,
 CASE WHEN @Supervisory=1 OR a.IsParticipant=0 THEN o.SenderName+N' ← '+o.ReceiverName WHEN o.SenderID=@Actor THEN o.ReceiverName ELSE o.SenderName END OtherName,
 CASE WHEN o.SenderID=@Actor THEN o.ReceiverImage ELSE o.SenderImage END OtherImage
 FROM dbo.Correspondence_Overview o JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=o.ID WHERE o.ID=@ThreadID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Messages @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT m.ID,m.ThreadID,m.SenderID,m.ReceivedID,m.Body,m.CreatedDate,ISNULL(m.IsRead,0) IsRead,m.ReadDate,
 COALESCE(p.FullName,u.FullName_Ar) SenderName FROM dbo.Correspondence_Thread_Messages m
 LEFT JOIN dbo.UsersMembers u ON u.ID=m.SenderID LEFT JOIN dbo.Correspondence_Parties p ON p.ThreadID=m.ThreadID AND p.UserID=m.SenderID
 WHERE m.ThreadID=@ThreadID ORDER BY m.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Files @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT a.* FROM dbo.Correspondence_Message_Attachments a JOIN dbo.Correspondence_Thread_Messages m ON m.ID=a.MessageID WHERE m.ThreadID=@ThreadID ORDER BY a.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Organization @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT p.*,u.FullName_Ar CurrentName,b.Title_Ar CurrentBrand,br.Title_Ar CurrentBranch,d.Title_Ar CurrentDepartment,
 j.Title_Ar CurrentJobTitle,s.Title_Ar CurrentShift
 FROM dbo.Correspondence_Parties p LEFT JOIN dbo.UsersMembers u ON u.ID=p.UserID
 LEFT JOIN dbo.Brands b ON b.ID=u.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=u.Branch_ID
 LEFT JOIN dbo.Departments d ON d.ID=u.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=u.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=u.Shif_ID
 WHERE p.ThreadID=@ThreadID ORDER BY p.UserID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_LogView @Actor int,@ThreadID int,@EventID uniqueidentifier
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @EventID IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID AND IsAdmin=1)
  THROW 51400,N'غير مسموح بالاطلاع الإداري.',1;
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Audit WITH(UPDLOCK,HOLDLOCK) WHERE ThreadID=@ThreadID AND ActorID=@Actor AND Action='view' AND EventID=@EventID)
 INSERT dbo.Correspondence_Audit(ThreadID,ActorID,ActorName,Action,EventID)
 SELECT @ThreadID,ID,FullName_Ar,'view',@EventID FROM dbo.UsersMembers WHERE ID=@Actor;
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_AuditList @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID AND IsAdmin=1) THROW 51400,N'سجل الاطلاع متاح لمدير النظام فقط.',1;
 SELECT TOP(100) ActorName,Action,CreatedAt,Note FROM dbo.Correspondence_Audit WHERE ThreadID=@ThreadID ORDER BY ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Archive @Actor int,@ThreadID int,@Reason nvarchar(1000)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NULLIF(LTRIM(RTRIM(@Reason)),'') IS NULL THROW 51400,N'سبب الأرشفة الإدارية مطلوب.',1;
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
  BEGIN ROLLBACK;THROW 51400,N'الأرشفة متاحة لمدير النظام فقط.',1;END;
 DECLARE @Creator int;
 SELECT @Creator=CreatedBy FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK)
 WHERE ID=@ThreadID AND CloseDate IS NULL AND ArchivedAt IS NULL AND ISNULL(IsDeleted,0)=0;
 IF @Creator IS NULL OR EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Creator AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
  BEGIN ROLLBACK;THROW 51400,N'الأرشفة متاحة للمراسلة المفتوحة إذا كان حساب منشئها معطلاً فقط.',1;END;
 UPDATE dbo.Correspondence_Threads SET ArchivedAt=GETUTCDATE(),ArchivedBy=@Actor,ArchiveReason=@Reason,IsCompleted=NULL,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE ID=@ThreadID;
 INSERT dbo.Correspondence_Audit(ThreadID,ActorID,ActorName,Action,EventID,Note)
 SELECT @ThreadID,ID,FullName_Ar,'archive',NEWID(),@Reason FROM dbo.UsersMembers WHERE ID=@Actor;
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Related @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT t.ID,t.Title FROM dbo.Correspondence_Threads t JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=t.ID
 WHERE t.RelatedThreadID=@ThreadID OR t.ID=(SELECT RelatedThreadID FROM dbo.Correspondence_Threads WHERE ID=@ThreadID);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Options @Actor int,@IncludeOrganization bit=1
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Type int=(SELECT Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0);
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح.',1;
 SELECT 'role' Kind,@Type ID,CAST(N'' AS nvarchar(500)) Title,CAST(0 AS int) ParentID
 UNION ALL
 SELECT DISTINCT 'brand',p.BrandID,p.BrandName,0 FROM dbo.Correspondence_Parties p
 WHERE @Type=1 AND @IncludeOrganization=1 AND p.BrandID IS NOT NULL
 UNION ALL
 SELECT DISTINCT 'branch',p.BranchID,p.BranchName,p.BrandID FROM dbo.Correspondence_Parties p
 WHERE @Type=1 AND @IncludeOrganization=1 AND p.BranchID IS NOT NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread_Message
 @Actor int,@ThreadID int,@Body nvarchar(4000),@Files xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=COALESCE(CloseDate,ArchivedAt),@Required=RequiresCompletion
 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ThreadID AND ISNULL(IsDeleted,0)=0 AND @Actor IN(SenderID,ReceiverID);
 IF @Sender IS NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة غير متاحة لك.',1;END;
 IF @Closed IS NOT NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة منتهية؛ لا يمكن إضافة ردود أو إغلاقها مرة أخرى.',1;END;
 SET @Target=CASE WHEN @Actor=@Sender THEN @Receiver ELSE @Sender END;
 IF NULLIF(LTRIM(RTRIM(@Body)),'') IS NULL AND ISNULL(@Files.exist('/files/file'),0)=0 BEGIN ROLLBACK;THROW 51400,N'اكتب الرد أو أرفق ملفًا.',1;END;
 INSERT dbo.Correspondence_Thread_Messages(ThreadID,SenderID,ReceivedID,Body,CreatedDate,IsRead) VALUES(@ThreadID,@Actor,@Target,@Body,@Now,0);
 SET @Message=SCOPE_IDENTITY();
 INSERT dbo.Correspondence_Message_Attachments(MessageID,FileName,File_Type,FileSize,CreatedDate)
  SELECT @Message,x.n.value('@name','nvarchar(255)'),x.n.value('@type','nvarchar(100)'),x.n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') x(n);
 INSERT dbo.Correspondence_Notifications(UserID,ThreadID,MessageID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Message,@Now,0);
 UPDATE dbo.Correspondence_Threads SET ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
 COMMIT;SELECT @Message ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Update_Correspondence_Thread_Close
 @Actor int,@ThreadID int,@IsCompleted bit,@ClosureKind varchar(12)='normal',@CloseReason nvarchar(1000)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
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
  UPDATE dbo.Correspondence_Threads SET ClosureKind=@ClosureKind,CloseReason=@CloseReason,CloseDate=@Now,Status=3,IsCompleted=CASE WHEN @Required=1 THEN @IsCompleted ELSE NULL END,ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
  INSERT dbo.Correspondence_Notifications(UserID,ThreadID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Now,0);
  COMMIT;RETURN;
END;
GO
