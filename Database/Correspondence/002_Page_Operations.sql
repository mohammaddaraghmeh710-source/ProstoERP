SET XACT_ABORT ON;
GO
CREATE OR ALTER FUNCTION dbo.Correspondence_AllowedRecipients(@Actor int,@Brand int)
RETURNS TABLE AS RETURN
SELECT b.ID,b.FullName_Ar,b.User_Image,b.Type,b.Brand_ID,b.Branch_ID,b.Shif_ID
FROM dbo.UsersMembers a JOIN dbo.UsersMembers b ON a.ID<>b.ID
WHERE a.ID=@Actor AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0
AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 AND b.Type<>1
AND (
 (a.Type=1 AND @Brand>0 AND b.Brand_ID=@Brand AND EXISTS(SELECT 1 FROM dbo.Brands br WHERE br.ID=@Brand AND ISNULL(br.IsDeleted,0)=0 AND ISNULL(br.IsActive,1)=1))
 OR (a.Type=2 AND ((b.Type IN(3,4) AND b.Branch_ID=a.Branch_ID) OR (b.Type=2 AND b.Brand_ID=a.Brand_ID)))
 OR (a.Type=3 AND b.Branch_ID=a.Branch_ID AND (b.Type=2 OR (b.Type=4 AND b.Shif_ID=a.Shif_ID)))
 OR (a.Type=4 AND b.Branch_ID=a.Branch_ID AND (b.Type=2 OR (b.Type=3 AND b.Shif_ID=a.Shif_ID)))
);
GO
CREATE OR ALTER PROCEDURE dbo.Correspondence_Page
 @Actor int, @Action varchar(20), @ThreadID int=0, @Brand int=0, @Branch int=0, @Shift int=0,
 @Recipients xml=NULL, @Title nvarchar(200)=NULL, @Brief nvarchar(2000)=NULL, @Body nvarchar(4000)=NULL,
 @RequiresCompletion bit=0, @DueDate datetime=NULL, @IsCompleted bit=NULL,
 @Files xml=NULL, @MessageIDs xml=NULL, @NotificationID int=0,
 @Search nvarchar(200)=NULL, @Filter varchar(10)='all', @Page int=1,
 @ActiveStatus int=1, @ClosedStatus int=3
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Type int,@Now datetime=GETUTCDATE(),@Sender int,@Receiver int,@Creator int,@Closed datetime,@Required bit,@Message int,@Target int;
 SELECT @Type=Type FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Type IS NULL THROW 51400,N'الحساب غير متاح لاستخدام المراسلات.',1;
 IF @Action='count'
 BEGIN
  SELECT COUNT(*) UnreadThreads FROM dbo.Correspondence_Threads t
  WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)
  AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0);
  RETURN;
 END;
 IF @Action='options'
 BEGIN
  SELECT @Actor ActorID,@Type ActorType;
  SELECT ID,Title_Ar FROM dbo.Brands WHERE @Type=1 AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsActive,1)=1 ORDER BY Title_Ar;
  SELECT ID,Title_Ar FROM dbo.Branches WHERE @Type=1 AND BrandID=@Brand AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsActive,1)=1 ORDER BY Title_Ar;
  SELECT s.ID,s.Title_Ar FROM dbo.Shift s WHERE @Type=1 AND ISNULL(s.IsDeleted,0)=0 AND ISNULL(s.IsActive,1)=1
   AND EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) u WHERE u.Shif_ID=s.ID AND (@Branch=0 OR u.Branch_ID=@Branch)) ORDER BY s.Title_Ar;
  SELECT * FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) WHERE (@Branch=0 OR Branch_ID=@Branch) AND (@Shift=0 OR Shif_ID=@Shift) ORDER BY FullName_Ar;
  RETURN;
 END;
 IF @Action='list'
 BEGIN
  IF @Page<1 SET @Page=1;
  SELECT t.*,u.FullName_Ar OtherName,u.User_Image OtherImage,
   CASE WHEN t.SenderID=@Actor THEN t.ReceiverID ELSE t.SenderID END OtherID,
   ISNULL(a.MessageCount,0) MessageCount,ISNULL(a.UnreadMessages,0) UnreadMessages,a.LastMessageDate,
   CASE WHEN t.CloseDate IS NOT NULL THEN 'closed' WHEN t.DueDate<@Now THEN 'overdue' ELSE 'active' END DisplayState,
   CAST(CASE WHEN t.CloseDate>t.DueDate THEN 1 ELSE 0 END AS bit) ClosedLate
  INTO #threads FROM dbo.Correspondence_Threads t
  JOIN dbo.UsersMembers u ON u.ID=CASE WHEN t.SenderID=@Actor THEN t.ReceiverID ELSE t.SenderID END
  OUTER APPLY(SELECT COUNT(*) MessageCount,MAX(m.CreatedDate) LastMessageDate,
   SUM(CASE WHEN m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0 THEN 1 ELSE 0 END) UnreadMessages
   FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID) a
  WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID);
  SELECT * INTO #filtered FROM #threads WHERE
   (@Filter='all' OR (@Filter='unread' AND UnreadMessages>0) OR @Filter=DisplayState)
   AND (NULLIF(@Search,'') IS NULL OR Title LIKE N'%'+@Search+N'%' OR Brief LIKE N'%'+@Search+N'%' OR OtherName LIKE N'%'+@Search+N'%');
  SELECT * FROM #filtered ORDER BY ISNULL(LastMessageDate,CreatedDate) DESC,ID DESC OFFSET (@Page-1)*12 ROWS FETCH NEXT 12 ROWS ONLY;
  SELECT (SELECT COUNT(*) FROM #filtered) FilteredCount,COUNT(*) TotalCount,
   COUNT(CASE WHEN UnreadMessages>0 THEN 1 END) UnreadThreads,
   COUNT(CASE WHEN DisplayState='active' THEN 1 END) ActiveCount,
   COUNT(CASE WHEN DisplayState='overdue' THEN 1 END) OverdueCount,
   COUNT(CASE WHEN DisplayState='closed' THEN 1 END) ClosedCount FROM #threads;
  RETURN;
 END;
 IF @Action='notifications'
 BEGIN
  SELECT TOP(100) n.*,t.Title FROM dbo.Correspondence_Notifications n JOIN dbo.Correspondence_Threads t ON t.ID=n.ThreadID
  WHERE n.UserID=@Actor AND ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID) ORDER BY n.ID DESC;
  RETURN;
 END;
 IF @Action='noticeSeen'
 BEGIN UPDATE dbo.Correspondence_Notifications SET IsRead=1,ReadDate=ISNULL(ReadDate,@Now) WHERE ID=@NotificationID AND UserID=@Actor; RETURN; END;
 IF @Action='create'
 BEGIN
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
    VALUES(@Title,@Brief,@Actor,@Target,@RequiresCompletion,@DueDate,@ActiveStatus,@Now,@Actor,0,CASE WHEN @Count>1 THEN 1 ELSE 0 END,@Batch);
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
 BEGIN TRANSACTION;
 SELECT @Sender=SenderID,@Receiver=ReceiverID,@Creator=CreatedBy,@Closed=CloseDate,@Required=RequiresCompletion
 FROM dbo.Correspondence_Threads WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ThreadID AND ISNULL(IsDeleted,0)=0 AND @Actor IN(SenderID,ReceiverID);
 IF @Sender IS NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة غير متاحة لك.',1;END;
 IF @Action='thread'
 BEGIN
  SELECT t.*,u.FullName_Ar OtherName,u.User_Image OtherImage,
   CASE WHEN t.CloseDate IS NOT NULL THEN 'closed' WHEN t.DueDate<@Now THEN 'overdue' ELSE 'active' END DisplayState,
   CAST(CASE WHEN t.CloseDate>t.DueDate THEN 1 ELSE 0 END AS bit) ClosedLate,
   CAST(CASE WHEN @Actor=@Creator AND @Closed IS NULL AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=@ThreadID AND m.SenderID<>@Creator AND m.ReceivedID=@Creator) THEN 1 ELSE 0 END AS bit) CanClose
   FROM dbo.Correspondence_Threads t JOIN dbo.UsersMembers u ON u.ID=CASE WHEN @Actor=t.SenderID THEN t.ReceiverID ELSE t.SenderID END WHERE t.ID=@ThreadID;
  SELECT m.*,u.FullName_Ar SenderName FROM dbo.Correspondence_Thread_Messages m JOIN dbo.UsersMembers u ON u.ID=m.SenderID WHERE m.ThreadID=@ThreadID ORDER BY m.ID;
  SELECT a.ID,a.MessageID,a.FileName,a.File_Type,a.FileSize FROM dbo.Correspondence_Message_Attachments a JOIN dbo.Correspondence_Thread_Messages m ON m.ID=a.MessageID WHERE m.ThreadID=@ThreadID ORDER BY a.ID;
  COMMIT;RETURN;
 END;
 IF @Action='read'
 BEGIN
  UPDATE dbo.Correspondence_Thread_Messages SET IsRead=1,ReadDate=ISNULL(ReadDate,@Now)
   WHERE ThreadID=@ThreadID AND ReceivedID=@Actor AND ISNULL(IsRead,0)=0
   AND ID IN(SELECT x.n.value('@id','int') FROM @MessageIDs.nodes('/items/item') x(n));
  -- Notification viewing is deliberately independent of message reading.
  COMMIT;RETURN;
 END;
 IF @Action NOT IN('reply','close') BEGIN ROLLBACK;THROW 51400,N'العملية غير صحيحة.',1;END;
 IF @Closed IS NOT NULL BEGIN ROLLBACK;THROW 51400,N'المحادثة منتهية؛ لا يمكن إضافة ردود أو إغلاقها مرة أخرى.',1;END;
 SET @Target=CASE WHEN @Actor=@Sender THEN @Receiver ELSE @Sender END;
 IF @Action='close'
 BEGIN
  IF @Actor<>@Creator BEGIN ROLLBACK;THROW 51400,N'منشئ المحادثة فقط يستطيع إغلاقها.',1;END;
  IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=@ThreadID AND SenderID<>@Creator AND ReceivedID=@Creator)
  BEGIN ROLLBACK;THROW 51400,N'يمكن الإغلاق بعد تلقي رد من الطرف الآخر.',1;END;
  IF @Required=1 AND @IsCompleted IS NULL BEGIN ROLLBACK;THROW 51400,N'حدد هل تم الإنجاز أم لا.',1;END;
  UPDATE dbo.Correspondence_Threads SET CloseDate=@Now,Status=@ClosedStatus,IsCompleted=CASE WHEN @Required=1 THEN @IsCompleted ELSE NULL END,ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
  INSERT dbo.Correspondence_Notifications(UserID,ThreadID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Now,0);
  COMMIT;RETURN;
 END;
 IF NULLIF(LTRIM(RTRIM(@Body)),'') IS NULL AND ISNULL(@Files.exist('/files/file'),0)=0 BEGIN ROLLBACK;THROW 51400,N'اكتب الرد أو أرفق ملفًا.',1;END;
 INSERT dbo.Correspondence_Thread_Messages(ThreadID,SenderID,ReceivedID,Body,CreatedDate,IsRead) VALUES(@ThreadID,@Actor,@Target,@Body,@Now,0);
 SET @Message=SCOPE_IDENTITY();
 INSERT dbo.Correspondence_Message_Attachments(MessageID,FileName,File_Type,FileSize,CreatedDate)
  SELECT @Message,x.n.value('@name','nvarchar(255)'),x.n.value('@type','nvarchar(100)'),x.n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') x(n);
 INSERT dbo.Correspondence_Notifications(UserID,ThreadID,MessageID,SendDate,IsRead) VALUES(@Target,@ThreadID,@Message,@Now,0);
 UPDATE dbo.Correspondence_Threads SET ModifyUser=@Actor,ModifyDate=@Now WHERE ID=@ThreadID;
 COMMIT;SELECT @Message ID;
END;
