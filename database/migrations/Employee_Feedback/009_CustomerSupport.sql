-- Customers share the existing feedback tables; no synthetic employee account is created.
-- Apply in one transaction. Compatible with existing employee API and portal signatures.
SET XACT_ABORT ON;
ALTER TABLE dbo.Employee_Feedback_Requests ALTER COLUMN EmployeeID int NULL;
ALTER TABLE dbo.Employee_Feedback_Workflow ALTER COLUMN SenderID int NULL;
ALTER TABLE dbo.Employee_Feedback_Workflow ALTER COLUMN ReceiverID int NULL;
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_EF_Request_ApplicantSource')
 ALTER TABLE dbo.Employee_Feedback_Requests WITH CHECK ADD CONSTRAINT CK_EF_Request_ApplicantSource
 CHECK((SourceType=1 AND EmployeeID IS NOT NULL) OR
 (SourceType=2 AND EmployeeID IS NULL AND ApplicantEmployeeNumber IS NULL AND Branch_ID IS NOT NULL
 AND NULLIF(LTRIM(RTRIM(ApplicantName)),N'') IS NOT NULL
 AND NULLIF(LTRIM(RTRIM(ApplicantMobile)),N'') IS NOT NULL));
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_EF_Workflow_Participants')
 ALTER TABLE dbo.Employee_Feedback_Workflow WITH CHECK ADD CONSTRAINT CK_EF_Workflow_Participants
 CHECK((ActionType=1 AND ReceiverID IS NOT NULL) OR
 (ActionType=2 AND SenderID IS NOT NULL AND ReceiverID IS NOT NULL) OR
 (ActionType=3 AND SenderID IS NOT NULL));
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Requests
 @Actor int,@Mode int,@Search nvarchar(300),@Type int=0,@Status int=0,@Brand int=0,@Branch int=0,@Shift int=0,@From date=NULL,@To date=NULL,@Identity int=0,@Source int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF @Mode NOT IN(0,1,2,3) OR NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Mode<>2 OR Type=1)) THROW 51500,N'لا تملك صلاحية الاطلاع على التقرير.',1;
 SELECT r.ID,r.Type,r.Title,r.Status,r.AddedDate,r.CloseDate,r.SourceType,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.ApplicantName ELSE N'هوية غير معلنة' END) EmployeeName,
 CONVERT(nvarchar(max),r.Branch_Title_Ar) BranchName,
 CONVERT(nvarchar(max),r.Brand_Title_Ar) BrandName,
 CONVERT(nvarchar(50),ISNULL((SELECT Title_Ar FROM dbo.Users_Types WHERE ID=m.Type),N'—')) CurrentRecipient,
 CONVERT(int,(SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications n WHERE n.Request_ID=r.ID AND n.UserID=@Actor AND n.IsRead=0)) UnreadCount
 FROM dbo.Employee_Feedback_Requests r LEFT JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
 LEFT JOIN dbo.Branches b ON b.ID=e.Branch_ID LEFT JOIN dbo.Brands br ON br.ID=r.Brand_ID
 OUTER APPLY(SELECT TOP(1) w.ReceiverID FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ActionType IN(1,2) ORDER BY w.ID DESC) lastw
 LEFT JOIN dbo.UsersMembers m ON m.ID=lastw.ReceiverID
 WHERE (@Mode=2 OR (@Mode=3 AND r.Status<>3 AND (r.EmployeeID IS NULL OR r.EmployeeID<>@Actor) AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.UsersMembers a ON a.ID=@Actor JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.GroupID=(SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=r.ID ORDER BY ID DESC) AND w.ActionType IN(1,2) AND (p.CanTransfer=1 OR p.CanClose=1))) OR (@Mode=1 AND r.EmployeeID=@Actor) OR (@Mode=0 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.ActionType IN(1,2))))
 AND (@Search=N'' OR CHARINDEX(@Search,r.Title)>0 OR CONVERT(nvarchar(20),r.ID)=@Search)
 AND (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To)
 AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR r.Branch_ID=@Branch)
 AND (@Shift=0 OR ((r.DiscloseIdentity=1 OR r.EmployeeID=@Actor) AND r.Shift_ID=@Shift)) AND (@Source=0 OR r.SourceType=@Source);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Customer_Feedback_Options @Brand int=0,@Type int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF @Brand<0 OR @Type<0 THROW 51500,N'اختيار غير صحيح.',1;
 IF @Brand>0 AND NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51500,N'العلامة التجارية غير متاحة.',1;
 SELECT ID,Title_Ar,Title_En FROM dbo.Employee_Feedback_Types WHERE IsActive=1 AND IsDeleted=0 ORDER BY Item_Order,ID;
 SELECT b.ID,b.Title_Ar,b.Title_En FROM dbo.Brands b WHERE b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 AND EXISTS(SELECT 1 FROM dbo.Branches br WHERE br.BrandID=b.ID AND br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0) ORDER BY b.ID;
 SELECT ID,BrandID,Title_Ar,Title_En FROM dbo.Branches WHERE BrandID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID;
 SELECT t.ID,t.Type,t.Brand_ID BrandID,t.Title_Ar,t.Title_En FROM dbo.Employee_Feedback_Topics t
 JOIN dbo.Employee_Feedback_Types k ON k.ID=t.Type AND k.IsActive=1 AND k.IsDeleted=0
 WHERE t.Brand_ID=@Brand AND t.IsActive=1 AND t.IsDeleted=0 AND (@Type=0 OR t.Type=@Type) ORDER BY t.Item_Order,t.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Customer_Feedback_Request
 @Type int,@Topic int,@Brand int,@Branch int,@Name nvarchar(200),@Mobile nvarchar(30),@Email nvarchar(254)=NULL,
 @Title nvarchar(300),@Details nvarchar(max),@Disclose bit,@Files xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NULLIF(LTRIM(RTRIM(@Name)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Mobile)),N'') IS NULL
 OR NULLIF(LTRIM(RTRIM(@Title)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Details)),N'') IS NULL
 OR LEN(@Details)>10000 OR @Disclose IS NULL OR @Files IS NULL OR @Files.value('count(/files/file)','int')>5
 THROW 51500,N'أدخل اسم الزبون ورقم التواصل والعنوان والتفاصيل بشكل صحيح.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 OR NOT EXISTS(SELECT 1 FROM dbo.Branches WITH(HOLDLOCK) WHERE ID=@Branch AND BrandID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51500,N'اختر فرعًا فعالًا يتبع العلامة التجارية المحددة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(HOLDLOCK) WHERE ID=@Type AND IsActive=1 AND IsDeleted=0)
 OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WITH(HOLDLOCK) WHERE ID=@Topic AND Type=@Type AND Brand_ID=@Brand AND IsActive=1 AND IsDeleted=0)
 THROW 51500,N'اختر نوعًا وموضوعًا فعالين يطابقان العلامة التجارية.',1;
 DECLARE @Targets TABLE(ID int PRIMARY KEY);
 INSERT @Targets SELECT u.ID FROM dbo.UsersMembers u WITH(HOLDLOCK) JOIN dbo.Users_Types t ON t.ID=u.Type
 WHERE u.Type=1 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0;
 IF NOT EXISTS(SELECT 1 FROM @Targets) THROW 51500,N'لا يوجد مدير نظام متاح لاستلام الطلب.',1;
 DECLARE @Now datetime=GETUTCDATE(),@Group uniqueidentifier=NEWID(),@ID int;
 INSERT dbo.Employee_Feedback_Requests(EmployeeID,SourceType,Type,Topic_ID,Brand_ID,Branch_ID,Topic_Title_Ar,Topic_Title_En,
 Title,Details,DiscloseIdentity,RequestedRecipientType,AddedDate,Brand_Title_Ar,Brand_Title_En,Branch_Title_Ar,Branch_Title_En,
 ApplicantName,ApplicantMobile,ApplicantEmail,ApplicantDataCapturedAt,ApplicantDataIsBackfilled)
 SELECT NULL,2,@Type,@Topic,@Brand,@Branch,t.Title_Ar,t.Title_En,LTRIM(RTRIM(@Title)),@Details,@Disclose,1,@Now,
 b.Title_Ar,b.Title_En,br.Title_Ar,br.Title_En,LTRIM(RTRIM(@Name)),LTRIM(RTRIM(@Mobile)),NULLIF(LTRIM(RTRIM(@Email)),N''),@Now,0
 FROM dbo.Employee_Feedback_Topics t JOIN dbo.Brands b ON b.ID=@Brand JOIN dbo.Branches br ON br.ID=@Branch WHERE t.ID=@Topic;
 SET @ID=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
 SELECT @ID,NULL,ID,N'تم تقديم الطلب من قبل زبون.',1,@Group,@Now FROM @Targets;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,NotificationType,SendDate) SELECT ID,@ID,1,@Now FROM @Targets;
 COMMIT; SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Request @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT r.ID,r.Type,r.Title,r.Details,r.Status,r.AddedDate,r.CloseDate,r.RowVersion,r.DiscloseIdentity,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.ApplicantName ELSE N'هوية غير معلنة' END) EmployeeName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.Topic_Title_Ar ELSE N'موضوع غير معلن' END) TopicName,
 CONVERT(nvarchar(max),r.Branch_Title_Ar) BranchName,
 CONVERT(nvarchar(max),r.Brand_Title_Ar) BrandName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.Department_Title_Ar ELSE N'' END) DepartmentName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.JobTitle_Title_Ar ELSE N'' END) JobTitleName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.Shift_Title_Ar ELSE N'' END) ShiftName,
 CONVERT(bit,CASE WHEN @Report=0 AND r.Status<>3 AND (r.EmployeeID IS NULL OR r.EmployeeID<>@Actor) AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions p WHERE p.UserTypeID=a.Type AND (p.CanTransfer=1 OR p.CanClose=1))
 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.GroupID=lastw.GroupID AND w.ReceiverID=@Actor AND w.ActionType IN(1,2))
  THEN 1 ELSE 0 END) CanAct,
 CONVERT(int,a.Type) ActorType
 FROM dbo.Employee_Feedback_Requests r LEFT JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID JOIN dbo.UsersMembers a ON a.ID=@Actor
 LEFT JOIN dbo.Branches b ON b.ID=e.Branch_ID LEFT JOIN dbo.Brands br ON br.ID=r.Brand_ID LEFT JOIN dbo.Departments d ON d.ID=e.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=e.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=e.Shif_ID
 OUTER APPLY(SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=r.ID ORDER BY ID DESC) lastw
 WHERE r.ID=@ID;
END;
GO
CREATE OR ALTER FUNCTION dbo.Employee_Feedback_RequestTargets(@ID int,@Target int,@Exclude int)
RETURNS TABLE AS RETURN
 WITH candidates AS (
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers m ON (r.EmployeeID IS NULL OR m.ID<>r.EmployeeID) AND m.ID<>@Exclude
 WHERE r.ID=@ID AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0 AND m.Type=@Target
 AND (@Target=1 OR (m.Brand_ID=r.Brand_ID AND m.Branch_ID=r.Branch_ID AND (@Target NOT IN(3,6) OR (@Target=3 AND m.Shif_ID=r.Shift_ID) OR (@Target=6 AND m.Department_ID=r.Department_ID))))
 )
 SELECT ID,Type,FullName_Ar FROM candidates
 UNION ALL
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.UsersMembers m JOIN dbo.Employee_Feedback_Requests r ON r.ID=@ID WHERE m.Type=1 AND (r.EmployeeID IS NULL OR m.ID<>r.EmployeeID) AND m.ID<>@Exclude AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0 AND @Target<>1 AND NOT EXISTS(SELECT 1 FROM candidates);
GO
CREATE OR ALTER PROCEDURE dbo.Update_Employee_Feedback_Action
 @Actor int,@ID int,@Version binary(8),@Action int,@Comment nvarchar(max),@Files xml,@TargetType int=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @Action NOT IN(2,3) OR @Version IS NULL OR NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@Comment,CHAR(9),' '),CHAR(10),' '),CHAR(13),' '))),N'') IS NULL OR LEN(@Comment)>10000 THROW 51500,N'اختر التحويل أو الإغلاق وأدخل الشروحات، بحد أقصى 10000 حرف.',1;
 IF @Files.value('count(/files/file)','int')>5 THROW 51500,N'الحد الأقصى خمسة مرفقات.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Employee int,@Status int,@Current binary(8),@Group uniqueidentifier,@Role int,@Brand int,@Branch int,@Shift int,@Target int,@Flow int,@Now datetime=GETUTCDATE();
 SELECT @Employee=EmployeeID,@Status=Status,@Current=RowVersion FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID;
 IF @Current IS NULL OR @Status=3 OR @Current<>@Version THROW 51500,N'تم اتخاذ إجراء أو تحديث الطلب. أعد فتحه للاطلاع على آخر حالة.',1;
 SELECT @Role=Type,@Brand=Brand_ID,@Branch=Branch_ID,@Shift=Shif_ID FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 SELECT TOP(1) @Group=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC;
 IF @Role IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions WHERE UserTypeID=@Role AND ((@Action=2 AND CanTransfer=1) OR (@Action=3 AND CanClose=1))) OR @Actor=@Employee OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group AND ReceiverID=@Actor AND ActionType IN(1,2)) THROW 51500,N'لا تملك صلاحية اتخاذ إجراء على الطلب.',1;


 DECLARE @Targets TABLE(ID int NULL,Type int);
 IF @Action=2 BEGIN
 SET @Target=@TargetType;
 IF @Target IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_AllowedRecipients rt JOIN dbo.Users_Types t ON t.ID=rt.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE SenderUserTypeID=@Role AND RecipientUserTypeID=@Target) THROW 51500,N'اختر نوع مستلم مسموحًا به للتحويل.',1;
 INSERT @Targets SELECT ID,Type FROM dbo.Employee_Feedback_RequestTargets(@ID,@Target,@Actor);
 IF NOT EXISTS(SELECT 1 FROM @Targets) THROW 51500,N'لا يوجد مدير متاح لاستلام التحويل.',1;
 IF EXISTS(SELECT 1 FROM @Targets WHERE Type<>@Target) SET @Comment=@Comment+NCHAR(10)+N'تم التوجيه إلى مدير النظام لعدم وجود المدير المطلوب.';
 END ELSE INSERT @Targets VALUES(@Employee,4);
 SET @Group=NEWID();
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate) SELECT @ID,@Actor,ID,@Comment,@Action,@Group,@Now FROM @Targets;
 SELECT @Flow=MIN(ID) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,@Flow,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate)
 SELECT ReceiverID,@ID,ID,@Action,@Now FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group AND ReceiverID IS NOT NULL;
 IF @Action=2 AND @Employee IS NOT NULL INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate) VALUES(@Employee,@ID,@Flow,2,@Now);
 UPDATE dbo.Employee_Feedback_Requests SET Status=CASE WHEN @Action=3 THEN 3 ELSE 2 END,CloseDate=CASE WHEN @Action=3 THEN @Now ELSE NULL END WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Workflow @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT w.GroupID,w.ActionType,MIN(w.AddedDate) AddedDate,MAX(w.Comment) Comment,
 MAX(CONVERT(nvarchar(max),CASE WHEN (w.SenderID IS NULL OR w.SenderID=r.EmployeeID) AND r.DiscloseIdentity=0 AND (r.EmployeeID IS NULL OR @Actor<>r.EmployeeID) THEN N'هوية غير معلنة' WHEN w.SenderID IS NULL THEN r.ApplicantName ELSE a.FullName_Ar END)) SenderName,
 STRING_AGG(CONVERT(nvarchar(max),CASE WHEN (w.ReceiverID IS NULL OR w.ReceiverID=r.EmployeeID) AND r.DiscloseIdentity=0 AND (r.EmployeeID IS NULL OR @Actor<>r.EmployeeID) THEN N'هوية غير معلنة' WHEN w.ReceiverID IS NULL THEN r.ApplicantName ELSE b.FullName_Ar END),N'، ') ReceiverNames
 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID LEFT JOIN dbo.UsersMembers a ON a.ID=w.SenderID LEFT JOIN dbo.UsersMembers b ON b.ID=w.ReceiverID
 WHERE r.ID=@ID GROUP BY w.GroupID,w.ActionType ORDER BY MIN(w.ID);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Logs @Actor int,@ID int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'السجلات لمدير النظام فقط.',1;
 SELECT l.Request_ID,l.EventDate,l.EventType,l.ActorName FROM (
 SELECT v.Request_ID,v.ViewedDate EventDate,N'مشاهدة' EventType,
 CASE WHEN r.DiscloseIdentity=0 AND v.UserID=r.EmployeeID THEN N'هوية غير معلنة' ELSE u.FullName_Ar END ActorName
 FROM dbo.Employee_Feedback_Views v JOIN dbo.Employee_Feedback_Requests r ON r.ID=v.Request_ID JOIN dbo.UsersMembers u ON u.ID=v.UserID WHERE @ID=0 OR r.ID=@ID
 UNION ALL
 SELECT w.Request_ID,MIN(w.AddedDate),CASE w.ActionType WHEN 1 THEN N'تقديم' WHEN 2 THEN N'تحويل' ELSE N'إغلاق' END,
 MAX(CASE WHEN r.DiscloseIdentity=0 AND (w.SenderID IS NULL OR w.SenderID=r.EmployeeID) THEN N'هوية غير معلنة' WHEN w.SenderID IS NULL THEN r.ApplicantName ELSE u.FullName_Ar END)
 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID LEFT JOIN dbo.UsersMembers u ON u.ID=w.SenderID WHERE @ID=0 OR r.ID=@ID GROUP BY w.Request_ID,w.GroupID,w.ActionType
 ) l ORDER BY l.EventDate DESC,l.Request_ID DESC;
END;
GO
