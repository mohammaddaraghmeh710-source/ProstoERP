-- Workflow-scoped in-system notices. Customer identity never uses UsersMembers IDs.
IF COL_LENGTH('dbo.Employee_Feedback_Notifications','WorkflowGroup') IS NULL ALTER TABLE dbo.Employee_Feedback_Notifications ADD WorkflowGroup uniqueidentifier NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Employee_Feedback_Notifications') AND name='UX_EF_Notification_WorkflowRecipient')
 CREATE UNIQUE INDEX UX_EF_Notification_WorkflowRecipient ON dbo.Employee_Feedback_Notifications(Request_ID,WorkflowGroup,UserID) WHERE WorkflowGroup IS NOT NULL;
IF OBJECT_ID('dbo.Customer_Feedback_Notifications','U') IS NULL
 CREATE TABLE dbo.Customer_Feedback_Notifications(AccountID int NOT NULL REFERENCES dbo.CRM_Accounts(ID),RequestID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),WorkflowGroup uniqueidentifier NOT NULL,NotificationType int NOT NULL CHECK(NotificationType IN(1,2,3)),SendDate datetime NOT NULL,IsRead bit NOT NULL DEFAULT(0),ReadDate datetime NULL,CONSTRAINT PK_Customer_Feedback_Notifications PRIMARY KEY(AccountID,RequestID,WorkflowGroup));
GO
CREATE OR ALTER PROCEDURE dbo.Feedback_PublishNotifications @RequestID int,@GroupID uniqueidentifier=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT=0 THROW 51500,N'تسجيل الإشعارات يتطلب معاملة الطلب.',1;
 DECLARE @Employee int,@Action int,@Flow int,@FirstFlow int,@Previous uniqueidentifier,@Now datetime;
 SELECT @Employee=EmployeeID FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE ID=@RequestID;
 IF @GroupID IS NULL SELECT TOP(1) @GroupID=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@RequestID ORDER BY ID DESC;
 SELECT @Action=MAX(ActionType),@Flow=MIN(ID),@FirstFlow=MIN(ID),@Now=MIN(AddedDate) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@RequestID AND GroupID=@GroupID;
 IF @Flow IS NULL THROW 51500,N'حدث الطلب غير موجود.',1;
 SELECT TOP(1) @Previous=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@RequestID AND ID<@FirstFlow ORDER BY ID DESC;
 DECLARE @Recipients table(ID int PRIMARY KEY);
 INSERT @Recipients SELECT @Employee WHERE @Employee IS NOT NULL
 UNION SELECT ReceiverID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@RequestID AND GroupID=@GroupID AND ReceiverID IS NOT NULL
 UNION SELECT ReceiverID FROM dbo.Employee_Feedback_Workflow WHERE @Action=2 AND Request_ID=@RequestID AND GroupID=@Previous AND ReceiverID IS NOT NULL
 UNION SELECT ReceiverID FROM dbo.Employee_Feedback_Workflow WHERE @Action=3 AND Request_ID=@RequestID AND ReceiverID IS NOT NULL
 UNION SELECT SenderID FROM dbo.Employee_Feedback_Workflow WHERE @Action=3 AND Request_ID=@RequestID AND SenderID IS NOT NULL;
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate,WorkflowGroup)
 SELECT u.ID,@RequestID,CASE WHEN @Action=1 THEN NULL ELSE @Flow END,@Action,@Now,@GroupID FROM @Recipients x JOIN dbo.UsersMembers u ON u.ID=x.ID AND u.Type<>7 AND ISNULL(u.IsDeleted,0)=0
 WHERE NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications n WITH(UPDLOCK,HOLDLOCK) WHERE n.Request_ID=@RequestID AND n.WorkflowGroup=@GroupID AND n.UserID=u.ID);
 INSERT dbo.Customer_Feedback_Notifications(AccountID,RequestID,WorkflowGroup,NotificationType,SendDate)
 SELECT c.AccountID,@RequestID,@GroupID,@Action,@Now FROM dbo.Customer_Portal_Feedback c
 WHERE c.RequestID=@RequestID AND NOT EXISTS(SELECT 1 FROM dbo.Customer_Feedback_Notifications n WITH(UPDLOCK,HOLDLOCK) WHERE n.AccountID=c.AccountID AND n.RequestID=@RequestID AND n.WorkflowGroup=@GroupID);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Feedback_WorkspaceNotifications @Actor int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type<>7 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'ليس لديك صلاحية الوصول.',1;
 SELECT n.ID NotificationID,n.Request_ID ID,r.Title,COALESCE(t.Title_Ar,N'طلب') TypeName,n.NotificationType,n.SendDate
 FROM dbo.Employee_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.Request_ID
 LEFT JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type
 JOIN dbo.Employee_Feedback_Access(@Actor,0) access ON access.ID=r.ID
 WHERE n.UserID=@Actor AND n.IsRead=0 ORDER BY n.SendDate DESC,n.ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_FeedbackNotifications @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 SELECT n.RequestID ID,r.Title,COALESCE(t.Title_Ar,N'طلب') TypeName,n.NotificationType,n.SendDate FROM dbo.Customer_Feedback_Notifications n
 JOIN dbo.Customer_Portal_Feedback c ON c.AccountID=n.AccountID AND c.RequestID=n.RequestID JOIN dbo.Employee_Feedback_Requests r ON r.ID=c.RequestID
 LEFT JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type
 WHERE n.AccountID=@AccountID AND n.IsRead=0 ORDER BY n.SendDate DESC,n.RequestID DESC;
 COMMIT;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_Feedback_NoticeRead @AccountID int,@Stamp uniqueidentifier,@RequestID int AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Portal_Feedback WITH(HOLDLOCK) WHERE AccountID=@AccountID AND RequestID=@RequestID) THROW 51912,N'الطلب غير متاح.',1;
 UPDATE dbo.Customer_Feedback_Notifications SET IsRead=1,ReadDate=GETUTCDATE() WHERE AccountID=@AccountID AND RequestID=@RequestID AND IsRead=0;
 COMMIT;END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Employee_Feedback_Request
 @Actor int,@Type int,@Topic int,@Title nvarchar(300),@Details nvarchar(max),@Disclose bit,@Target int,@Files xml
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Brand int,@ID int,@Now datetime=GETUTCDATE(),@Group uniqueidentifier=NEWID();
 SELECT @Brand=a.Brand_ID FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type WHERE a.ID=@Actor AND p.CanSubmit=1 AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type JOIN dbo.Employee_Feedback_AllowedRecipients rt ON rt.SenderUserTypeID=a.Type AND rt.RecipientUserTypeID=@Target JOIN dbo.Users_Types t ON t.ID=rt.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE a.ID=@Actor AND p.CanSubmit=1 AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0) THROW 51500,N'غير مسموح بتقديم الطلب إلى هذه الجهة.',1;
 IF @Brand IS NULL SELECT @Brand=Brand_ID FROM dbo.Employee_Feedback_Topics WHERE ID=@Topic;
 IF @Brand IS NULL OR @Disclose IS NULL THROW 51500,N'بيانات الموظف أو جهة الطلب غير صحيحة.',1;
 IF NULLIF(LTRIM(RTRIM(@Title)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@Details,CHAR(9),' '),CHAR(10),' '),CHAR(13),' '))),N'') IS NULL OR LEN(@Details)>10000 THROW 51500,N'أدخل العنوان والتفاصيل؛ الحد الأقصى للتفاصيل 10000 حرف.',1;
 IF @Files.value('count(/files/file)','int')>5 THROW 51500,N'الحد الأقصى خمسة مرفقات.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(HOLDLOCK) WHERE ID=@Type AND IsActive=1 AND IsDeleted=0) THROW 51500,N'نوع الطلب غير فعال.',1;
 SELECT @Brand=Brand_ID FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor;
 IF @Brand IS NULL SELECT @Brand=Brand_ID FROM dbo.Employee_Feedback_Topics WHERE ID=@Topic;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WITH(HOLDLOCK) WHERE ID=@Topic AND Type=@Type AND Brand_ID=@Brand AND IsActive=1 AND IsDeleted=0) THROW 51500,N'اختر موضوعًا فعالًا يطابق نوع الطلب وعلامتك التجارية.',1;
 DECLARE @Targets TABLE(ID int PRIMARY KEY,Type int);
 INSERT @Targets SELECT ID,Type FROM dbo.Employee_Feedback_Targets(@Actor,@Target);
 IF NOT EXISTS(SELECT 1 FROM @Targets) THROW 51500,N'لا يوجد مدير متاح لاستلام الطلب.',1;
 INSERT dbo.Employee_Feedback_Requests(EmployeeID,Type,Topic_ID,Brand_ID,Topic_Title_Ar,Topic_Title_En,Title,Details,DiscloseIdentity,RequestedRecipientType,AddedDate)
 SELECT @Actor,@Type,ID,@Brand,Title_Ar,Title_En,@Title,@Details,@Disclose,@Target,@Now FROM dbo.Employee_Feedback_Topics WHERE ID=@Topic;
 SET @ID=CONVERT(int,SCOPE_IDENTITY());
 UPDATE r SET SourceType=1,Branch_ID=e.Branch_ID,Department_ID=e.Department_ID,JobTitle_ID=e.JobTitle_ID,Shift_ID=e.Shif_ID,
 Brand_Title_Ar=b.Title_Ar,Brand_Title_En=b.Title_En,Branch_Title_Ar=br.Title_Ar,Branch_Title_En=br.Title_En,
 Department_Title_Ar=d.Title_Ar,JobTitle_Title_Ar=j.Title_Ar,Shift_Title_Ar=s.Title_Ar,
 ApplicantName=e.FullName_Ar,ApplicantNameEn=e.Fullname_En,ApplicantEmployeeNumber=e.Employee_Number,
 ApplicantPhone=e.PhoneNumber,ApplicantMobile=e.MobileNumber,ApplicantEmail=e.Email,ApplicantDataCapturedAt=@Now,ApplicantDataIsBackfilled=0
 FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers e ON e.ID=@Actor LEFT JOIN dbo.Brands b ON b.ID=r.Brand_ID
 LEFT JOIN dbo.Branches br ON br.ID=e.Branch_ID LEFT JOIN dbo.Departments d ON d.ID=e.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=e.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=e.Shif_ID WHERE r.ID=@ID;
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
 SELECT @ID,@Actor,ID,CASE WHEN Type<>@Target THEN N'تقديم الطلب إلى مدير النظام لعدم وجود المدير المطلوب.' ELSE N'تم تقديم الطلب.' END,1,@Group,@Now FROM @Targets;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 EXEC dbo.Feedback_PublishNotifications @RequestID=@ID,@GroupID=@Group;
 COMMIT; SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Customer_Feedback_Request
 @Type int,@Topic int,@Brand int,@Branch int,@Name nvarchar(200),@Mobile nvarchar(30),@Email nvarchar(254)=NULL,
 @Title nvarchar(300),@Details nvarchar(max),@Disclose bit,@Files xml,@CreatedID int=NULL OUTPUT,@ReturnResult bit=1
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
 SET @ID=CONVERT(int,SCOPE_IDENTITY()); SET @CreatedID=@ID;
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
 SELECT @ID,NULL,ID,N'تم تقديم الطلب من قبل زبون.',1,@Group,@Now FROM @Targets;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 EXEC dbo.Feedback_PublishNotifications @RequestID=@ID,@GroupID=@Group;
 COMMIT; IF @ReturnResult=1 SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
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
 IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE ID=@ID AND SourceType=2) AND ISNULL(@Target,0)<>1 THROW 51500,N'طلبات العملاء تُحوّل إلى مدير النظام فقط.',1;
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
 UPDATE dbo.Employee_Feedback_Requests SET Status=CASE WHEN @Action=3 THEN 3 ELSE 2 END,CloseDate=CASE WHEN @Action=3 THEN @Now ELSE NULL END WHERE ID=@ID;
 EXEC dbo.Feedback_PublishNotifications @RequestID=@ID,@GroupID=@Group;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
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
 UNION ALL
 SELECT n.Request_ID,n.SendDate,CONCAT(N'تنبيه: ',CASE n.NotificationType WHEN 1 THEN N'تقديم' WHEN 2 THEN N'تحويل' ELSE N'إغلاق' END),
 CASE WHEN r.DiscloseIdentity=0 AND n.UserID=r.EmployeeID THEN N'هوية غير معلنة' ELSE u.FullName_Ar END
 FROM dbo.Employee_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.Request_ID JOIN dbo.UsersMembers u ON u.ID=n.UserID WHERE @ID=0 OR r.ID=@ID
 UNION ALL
 SELECT n.Request_ID,n.ReadDate,N'قراءة تنبيه',CASE WHEN r.DiscloseIdentity=0 AND n.UserID=r.EmployeeID THEN N'هوية غير معلنة' ELSE u.FullName_Ar END
 FROM dbo.Employee_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.Request_ID JOIN dbo.UsersMembers u ON u.ID=n.UserID WHERE n.IsRead=1 AND n.ReadDate IS NOT NULL AND (@ID=0 OR r.ID=@ID)
 UNION ALL
 SELECT n.RequestID,n.SendDate,CONCAT(N'تنبيه عميل: ',CASE n.NotificationType WHEN 1 THEN N'تقديم' WHEN 2 THEN N'تحويل' ELSE N'إغلاق' END),CASE WHEN r.DiscloseIdentity=0 THEN N'هوية غير معلنة' ELSE a.Name_AR END
 FROM dbo.Customer_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.RequestID JOIN dbo.CRM_Accounts a ON a.ID=n.AccountID WHERE @ID=0 OR r.ID=@ID
 UNION ALL
 SELECT n.RequestID,n.ReadDate,N'قراءة تنبيه عميل',CASE WHEN r.DiscloseIdentity=0 THEN N'هوية غير معلنة' ELSE a.Name_AR END
 FROM dbo.Customer_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.RequestID JOIN dbo.CRM_Accounts a ON a.ID=n.AccountID WHERE n.IsRead=1 AND n.ReadDate IS NOT NULL AND (@ID=0 OR r.ID=@ID)
 ) l ORDER BY l.EventDate DESC,l.Request_ID DESC;
END;
GO
