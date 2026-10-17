-- Independent correspondence procedures and bounded list query.
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread
 @Actor int,@Brand int,@Recipients xml,@Title nvarchar(200),@Brief nvarchar(2000),@Body nvarchar(4000),@RequiresCompletion bit,@DueDate datetime,@Files xml
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
  IF EXISTS(SELECT 1 FROM @Targets r WHERE NOT EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) a WHERE a.ID=r.ID))
  BEGIN ROLLBACK; THROW 51400,N'أحد المستلمين خارج نطاق المراسلة المسموح لك.',1; END;
  DECLARE @Created TABLE(ID int);
  DECLARE recipients CURSOR LOCAL FAST_FORWARD FOR SELECT ID FROM @Targets;
  OPEN recipients;FETCH NEXT FROM recipients INTO @Target;
  WHILE @@FETCH_STATUS=0
  BEGIN
   INSERT dbo.Correspondence_Threads(Title,Brief,SenderID,ReceiverID,RequiresCompletion,DueDate,Status,CreatedDate,CreatedBy,IsDeleted,IsBroadcast,BroadcastID)
    VALUES(@Title,@Brief,@Actor,@Target,@RequiresCompletion,@DueDate,1,@Now,@Actor,0,CASE WHEN @Count>1 THEN 1 ELSE 0 END,@Batch);
   SET @ThreadID=SCOPE_IDENTITY(); INSERT @Created VALUES(@ThreadID);
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
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread_Message
 @Actor int,@ThreadID int,@Body nvarchar(4000),@Files xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=CloseDate,@Required=RequiresCompletion
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
 @Actor int,@ThreadID int,@IsCompleted bit
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=CloseDate,@Required=RequiresCompletion
 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ThreadID AND ISNULL(IsDeleted,0)=0 AND @Actor IN(SenderID,ReceiverID);
 IF @Sender IS NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة غير متاحة لك.',1;END;
 IF @Closed IS NOT NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة منتهية؛ لا يمكن إضافة ردود أو إغلاقها مرة أخرى.',1;END;
 SET @Target=CASE WHEN @Actor=@Sender THEN @Receiver ELSE @Sender END;
  IF @Actor<>@Creator BEGIN ROLLBACK;THROW 51400,N'منشئ المحادثة فقط يستطيع إغلاقها.',1;END;
  IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=@ThreadID AND SenderID<>@Creator AND ReceivedID=@Creator)
  BEGIN ROLLBACK;THROW 51400,N'يمكن الإغلاق بعد تلقي رد من الطرف الآخر.',1;END;
  IF @Required=1 AND @IsCompleted IS NULL BEGIN ROLLBACK;THROW 51400,N'حدد هل تم الإنجاز أم لا.',1;END;
  UPDATE dbo.Correspondence_Threads SET CloseDate=@Now,Status=3,IsCompleted=CASE WHEN @Required=1 THEN @IsCompleted ELSE NULL END,ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
  INSERT dbo.Correspondence_Notifications(UserID,ThreadID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Now,0);
  COMMIT;RETURN;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Update_Correspondence_Messages_Read
 @Actor int,@ThreadID int,@MessageIDs xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 BEGIN TRANSACTION;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=CloseDate,@Required=RequiresCompletion
 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ThreadID AND ISNULL(IsDeleted,0)=0 AND @Actor IN(SenderID,ReceiverID);
 IF @Sender IS NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة غير متاحة لك.',1;END;
  UPDATE dbo.Correspondence_Thread_Messages SET IsRead=1,ReadDate=ISNULL(ReadDate,@Now)
   WHERE ThreadID=@ThreadID AND ReceivedID=@Actor AND ISNULL(IsRead,0)=0
   AND ID IN(SELECT x.n.value('@id','int') FROM @MessageIDs.nodes('/items/item') x(n));
  -- Notification viewing is deliberately independent of message reading.
  COMMIT;RETURN;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Threads_ByUserID
 @Actor int,@Search nvarchar(200)=NULL,@Filter varchar(10)='all',@Page int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF @Page<1 SET @Page=1;
 -- Count/filter/page narrow keys first. Do not spool or sort all message bodies,
 -- summaries and image paths for COUNT(*) OVER().
 CREATE TABLE #Matches(ID int NOT NULL PRIMARY KEY,LastMessageDate datetime NULL);
 INSERT #Matches(ID,LastMessageDate)
 SELECT t.ID,ISNULL((SELECT MAX(m.CreatedDate) FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID),t.CreatedDate)
 FROM dbo.Correspondence_Threads t
 JOIN dbo.UsersMembers actor ON actor.ID=@Actor AND actor.IsActive=1 AND ISNULL(actor.IsDeleted,0)=0
 JOIN dbo.UsersMembers otherUser ON otherUser.ID=CASE WHEN t.SenderID=@Actor THEN t.ReceiverID ELSE t.SenderID END
 WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)
 AND (NULLIF(@Search,'') IS NULL OR t.Title LIKE N'%'+@Search+N'%' OR t.Brief LIKE N'%'+@Search+N'%' OR otherUser.FullName_Ar LIKE N'%'+@Search+N'%')
 AND (@Filter='all' OR (@Filter='closed' AND t.CloseDate IS NOT NULL)
 OR (@Filter='unread' AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0))
 OR (@Filter='overdue' AND t.CloseDate IS NULL AND t.DueDate<GETUTCDATE())
 OR (@Filter='active' AND t.CloseDate IS NULL AND (t.DueDate IS NULL OR t.DueDate>=GETUTCDATE())));
 DECLARE @TotalRows int=(SELECT COUNT(*) FROM #Matches);
 CREATE TABLE #Page(ID int NOT NULL PRIMARY KEY,LastMessageDate datetime NULL);
 INSERT #Page SELECT ID,LastMessageDate FROM #Matches ORDER BY LastMessageDate DESC,ID DESC OFFSET (@Page-1)*30 ROWS FETCH NEXT 30 ROWS ONLY;
 SELECT s.*,@TotalRows TotalRows FROM #Page p JOIN dbo.Correspondence_ThreadSummary(@Actor) s ON s.ID=p.ID
 -- Presentation orders the bounded (at most 30) result rows; avoid a wide SQL sort grant.
 OPTION(RECOMPILE, LOOP JOIN);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_UnreadCount @Actor int
AS
BEGIN
 SET NOCOUNT ON;
 SELECT COUNT(*) UnreadThreads FROM dbo.Correspondence_Threads t
 WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)
 AND EXISTS(SELECT 1 FROM dbo.UsersMembers u WHERE u.ID=@Actor AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0)
 AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Thread_ByID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Threads t JOIN dbo.UsersMembers u ON u.ID=@Actor AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 WHERE t.ID=@ThreadID AND ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT * FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE ID=@ThreadID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Messages_ByThreadID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Threads t JOIN dbo.UsersMembers u ON u.ID=@Actor AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 WHERE t.ID=@ThreadID AND ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT m.ID,m.ThreadID,m.SenderID,m.ReceivedID,m.Body,m.CreatedDate,ISNULL(m.IsRead,0) IsRead,m.ReadDate,u.FullName_Ar SenderName
 FROM dbo.Correspondence_Thread_Messages m JOIN dbo.UsersMembers u ON u.ID=m.SenderID WHERE m.ThreadID=@ThreadID ORDER BY m.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Attachments_ByThreadID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Threads t JOIN dbo.UsersMembers u ON u.ID=@Actor AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 WHERE t.ID=@ThreadID AND ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT a.ID,a.MessageID,a.FileName,a.File_Type,a.FileSize FROM dbo.Correspondence_Message_Attachments a
 JOIN dbo.Correspondence_Thread_Messages m ON m.ID=a.MessageID WHERE m.ThreadID=@ThreadID ORDER BY a.ID;
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Thread_Messages') AND name='IX_Correspondence_Messages_Receipt')
 CREATE INDEX IX_Correspondence_Messages_Receipt ON dbo.Correspondence_Thread_Messages(ReceivedID,IsRead,ThreadID) INCLUDE(ReadDate);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Thread_Messages') AND name='IX_Correspondence_Messages_Date')
 CREATE INDEX IX_Correspondence_Messages_Date ON dbo.Correspondence_Thread_Messages(ThreadID,CreatedDate DESC) INCLUDE(SenderID,ReceivedID,IsRead);
GO
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id=OBJECT_ID('dbo.Correspondence_Page') AND referencing_id<>OBJECT_ID('dbo.Correspondence_Page'))
 THROW 51400,N'لا يمكن إزالة الإجراء القديم قبل إزالة جميع الاعتمادات عليه.',1;
DROP PROCEDURE IF EXISTS dbo.Correspondence_Page;
GO
