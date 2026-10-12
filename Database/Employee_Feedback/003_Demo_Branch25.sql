-- Synthetic scenarios only. Applied atomically by SeedDemo.ps1.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE Title LIKE N'[[]تجريبي EF25]%')
    THROW 51000,'Branch 25 demo already exists; refusing duplicates.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Branches WHERE ID=25 AND BrandID=29 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
    THROW 51001,'Expected active branch 25 and brand 29.',1;
IF (SELECT COUNT(*) FROM dbo.UsersMembers WHERE ID BETWEEN 151 AND 159 AND Branch_ID=25 AND Brand_ID=29 AND Type=4 AND Shif_ID IN(1,2,3) AND IsActive=1 AND ISNULL(IsDeleted,0)=0)<>9
    THROW 51002,'Demo employee assignments changed.',1;
DECLARE @Admin int=(SELECT MIN(ID) FROM dbo.UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0);
DECLARE @BranchManager int=(SELECT MIN(ID) FROM dbo.UsersMembers WHERE Type=2 AND Branch_ID=25 AND IsActive=1 AND ISNULL(IsDeleted,0)=0);
IF @Admin IS NULL OR @BranchManager IS NULL THROW 51003,'Missing managers.',1;
DECLARE @Topics TABLE(N int,Type int,TitleAr nvarchar(200),TitleEn nvarchar(200),ID int);
INSERT @Topics(N,Type,TitleAr,TitleEn) VALUES
(1,1,N'[تجريبي EF25] تنظيم الورديات',N'[Demo EF25] Shift scheduling'),
(2,1,N'[تجريبي EF25] تجهيزات العمل',N'[Demo EF25] Workplace equipment'),
(3,1,N'[تجريبي EF25] الخدمات الداخلية',N'[Demo EF25] Internal services'),
(4,2,N'[تجريبي EF25] تحسين إجراءات العمل',N'[Demo EF25] Process improvement'),
(5,2,N'[تجريبي EF25] التدريب والتطوير',N'[Demo EF25] Training'),
(6,2,N'[تجريبي EF25] بيئة العمل',N'[Demo EF25] Work environment');
DECLARE @n int=1,@Topic int,@Type int,@TitleAr nvarchar(200),@TitleEn nvarchar(200);
WHILE @n<=6
BEGIN
 SELECT @Type=Type,@TitleAr=TitleAr,@TitleEn=TitleEn FROM @Topics WHERE N=@n;
 INSERT dbo.Employee_Feedback_Topics(Type,Brand_ID,Title_Ar,Title_En,Item_Order,AddedUser)
 VALUES(@Type,29,@TitleAr,@TitleEn,@n,@Admin);
 UPDATE @Topics SET ID=CONVERT(int,SCOPE_IDENTITY()) WHERE N=@n;
 SET @n+=1;
END;
DECLARE @Scenarios TABLE(N int,TopicN int,Target int,TransferTarget int NULL,Closed bit,Title nvarchar(300));
INSERT @Scenarios VALUES
(1,1,3,NULL,0,N'مراجعة توقيت الاستراحة'),
(2,4,2,NULL,0,N'تبسيط تسليم الوردية'),
(3,2,1,NULL,0,N'متابعة تجهيزات العمل'),
(4,3,3,2,0,N'متابعة الخدمات الداخلية'),
(5,5,3,2,0,N'تدريب قصير قبل بدء الوردية'),
(6,6,2,1,0,N'تحسين مساحة الاستراحة'),
(7,1,3,NULL,1,N'توضيح جدول الاستراحات'),
(8,4,2,NULL,1,N'اعتماد قائمة تسليم موحدة'),
(9,2,2,1,1,N'مراجعة احتياجات التجهيز');
DECLARE @Employee int,@Shift int,@Request int,@Target int,@Next int,@Closed bit,@Title nvarchar(300),
 @Sender int,@Group uniqueidentifier,@At datetime,@Start datetime,@Flow int,@Receiver int;
DECLARE @Recipients TABLE(ID int PRIMARY KEY);
SET @n=1;
WHILE @n<=9
BEGIN
 SELECT @Employee=150+@n,@Target=s.Target,@Next=s.TransferTarget,@Closed=s.Closed,
 @Title=N'[تجريبي EF25] '+s.Title,@Topic=t.ID,@Type=t.Type,@TitleAr=t.TitleAr,@TitleEn=t.TitleEn
 FROM @Scenarios s JOIN @Topics t ON t.N=s.TopicN WHERE s.N=@n;
 SELECT @Shift=Shif_ID FROM dbo.UsersMembers WHERE ID=@Employee;
 SET @Start=DATEADD(DAY,-(10-@n),GETUTCDATE()); SET @At=@Start;
 INSERT dbo.Employee_Feedback_Requests(EmployeeID,Type,Topic_ID,Brand_ID,Topic_Title_Ar,Topic_Title_En,Title,Details,DiscloseIdentity,RequestedRecipientType,AddedDate)
 VALUES(@Employee,@Type,@Topic,29,@TitleAr,@TitleEn,@Title,
 N'بيانات تجريبية مصطنعة لا تمثل شكوى فعلية أو تصريحًا من الموظف. الغرض اختبار العرض ومسار المعالجة لفرع عبدالله غوشة.',@n%2,@Target,@At);
 SET @Request=CONVERT(int,SCOPE_IDENTITY()); SET @Group=NEWID();
 DELETE FROM @Recipients;
 INSERT @Recipients SELECT ID FROM dbo.UsersMembers WHERE Type=@Target AND IsActive=1 AND ISNULL(IsDeleted,0)=0
 AND (@Target=1 OR (Branch_ID=25 AND (@Target=2 OR Shif_ID=@Shift)));
 IF NOT EXISTS(SELECT 1 FROM @Recipients) THROW 51004,'Missing demo recipients.',1;
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
 SELECT @Request,@Employee,ID,N'تقديم تجريبي لطلب الموظف لاختبار النظام فقط.',1,@Group,@At FROM @Recipients;
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,NotificationType,SendDate)
 SELECT ID,@Request,1,@At FROM @Recipients;
 IF @Next IS NOT NULL
 BEGIN
  SELECT @Sender=MIN(ID) FROM @Recipients;
  DELETE FROM @Recipients;
  INSERT @Recipients SELECT ID FROM dbo.UsersMembers WHERE Type=@Next AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Next=1 OR Branch_ID=25);
  IF NOT EXISTS(SELECT 1 FROM @Recipients) THROW 51005,'Missing transfer recipients.',1;
  SET @Group=NEWID(); SET @At=DATEADD(HOUR,1,@At);
  INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
  SELECT @Request,@Sender,ID,N'تحويل تجريبي للمستوى التالي لدراسة الطلب واتخاذ الإجراء المناسب.',2,@Group,@At FROM @Recipients;
  INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate)
  SELECT ReceiverID,@Request,ID,2,@At FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@Request AND GroupID=@Group;
  SELECT @Flow=MIN(ID) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@Request AND GroupID=@Group;
  INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate) VALUES(@Employee,@Request,@Flow,2,@At);
  UPDATE dbo.Employee_Feedback_Requests SET Status=2 WHERE ID=@Request;
 END;
 IF @Closed=1
 BEGIN
  SELECT @Sender=MIN(ID) FROM @Recipients;
  SET @At=DATEADD(HOUR,1,@At); SET @Group=NEWID();
  INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
  VALUES(@Request,@Sender,@Employee,N'إغلاق تجريبي بعد مراجعة الطلب وتوثيق النتيجة. لا يمثل معالجة واقعة فعلية.',3,@Group,@At);
  SET @Flow=CONVERT(int,SCOPE_IDENTITY());
  INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate) VALUES(@Employee,@Request,@Flow,3,@At);
  UPDATE dbo.Employee_Feedback_Requests SET Status=3,CloseDate=@At WHERE ID=@Request;
 END;
 -- Real PNG fixtures supplied by SeedDemo.ps1, one submission and one transfer attachment.
 IF @n=1
  INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
  VALUES(@Request,@SubmissionFile,N'demo-submission.png','png',@SubmissionSize,@Start);
 IF @n=4
  INSERT dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
  VALUES(@Request,@Flow,@TransferFile,N'demo-transfer.png','png',@TransferSize,@At);
 SET @n+=1;
END;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Requests WHERE Title LIKE N'[[]تجريبي EF25]%')<>9
 THROW 51006,'Demo request count mismatch.',1;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers u ON u.ID=r.EmployeeID
 WHERE r.Title LIKE N'[[]تجريبي EF25]%' AND (u.Branch_ID<>25 OR r.Brand_ID<>29))
 THROW 51007,'Demo branch mismatch.',1;
