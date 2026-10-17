SET XACT_ABORT ON;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_EF_Requests_Target') ALTER TABLE dbo.Employee_Feedback_Requests DROP CONSTRAINT CK_EF_Requests_Target;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_EF_Requests_TargetType') ALTER TABLE dbo.Employee_Feedback_Requests ADD CONSTRAINT FK_EF_Requests_TargetType FOREIGN KEY(RequestedRecipientType) REFERENCES dbo.Users_Types(ID);
IF OBJECT_ID('dbo.Employee_Feedback_Views','U') IS NULL BEGIN
 CREATE TABLE dbo.Employee_Feedback_Views(ID bigint IDENTITY PRIMARY KEY,Request_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),ViewedDate datetime NOT NULL DEFAULT(GETUTCDATE()));
 CREATE INDEX IX_EF_Views_Request ON dbo.Employee_Feedback_Views(Request_ID,ViewedDate);
END;
GO
CREATE OR ALTER FUNCTION dbo.Employee_Feedback_Access(@Actor int,@Report bit)
RETURNS TABLE AS RETURN
 SELECT r.ID FROM dbo.Employee_Feedback_Requests r
 JOIN dbo.UsersMembers a ON a.ID=@Actor AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0
 WHERE r.EmployeeID=@Actor OR (@Report=1 AND a.Type=1)
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor);
GO
CREATE OR ALTER FUNCTION dbo.Employee_Feedback_RoutedTargets(@Employee int,@Target int,@Exclude int)
RETURNS TABLE AS RETURN
 WITH candidates AS (
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.UsersMembers e JOIN dbo.UsersMembers m ON m.ID<>e.ID AND m.ID<>@Exclude
 WHERE e.ID=@Employee AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0
 AND EXISTS(SELECT 1 FROM dbo.Users_Types WHERE ID=@Target AND IsActive=1 AND ISNULL(IsDeleted,0)=0) AND m.Type=@Target AND (@Target=1 OR (m.Brand_ID=e.Brand_ID AND m.Branch_ID=e.Branch_ID AND (@Target NOT IN(3,6) OR (@Target=3 AND m.Shif_ID=e.Shif_ID) OR (@Target=6 AND m.Department_ID=e.Department_ID))))
 )
 SELECT ID,Type,FullName_Ar FROM candidates
 UNION ALL
 SELECT ID,Type,FullName_Ar FROM dbo.UsersMembers WHERE Type=1 AND ID<>@Employee AND ID<>@Exclude AND IsActive=1 AND ISNULL(IsDeleted,0)=0
 AND @Target<>1 AND NOT EXISTS(SELECT 1 FROM candidates);
GO
CREATE OR ALTER FUNCTION dbo.Employee_Feedback_Targets(@Employee int,@Target int)
RETURNS TABLE AS RETURN
 WITH candidates AS (
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.UsersMembers e JOIN dbo.UsersMembers m ON m.ID<>e.ID
 WHERE e.ID=@Employee AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0
 AND m.Type=@Target AND (@Target=1 OR (m.Brand_ID=e.Brand_ID AND m.Branch_ID=e.Branch_ID AND (@Target NOT IN(3,6) OR (@Target=3 AND m.Shif_ID=e.Shif_ID) OR (@Target=6 AND m.Department_ID=e.Department_ID))))
 )
 SELECT ID,Type,FullName_Ar FROM candidates
 UNION ALL
 SELECT ID,Type,FullName_Ar FROM dbo.UsersMembers WHERE Type=1 AND ID<>@Employee AND IsActive=1 AND ISNULL(IsDeleted,0)=0
 AND @Target<>1 AND NOT EXISTS(SELECT 1 FROM candidates);
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Topics
 @Actor int,@ID int=0,@Type int=0,@Brand int=0,@Manage bit=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Role int,@EmployeeBrand int;
 SELECT @Role=Type,@EmployeeBrand=Brand_ID FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @Role IS NULL OR (@Manage=1 AND @Role<>1) THROW 51500,N'لا تملك صلاحية إدارة المواضيع.',1;
 SELECT t.ID,t.Type,t.Brand_ID,t.Title_Ar,t.Title_En,t.Item_Order,t.IsActive,t.AddedDate,b.Title_Ar BrandName
 FROM dbo.Employee_Feedback_Topics t JOIN dbo.Brands b ON b.ID=t.Brand_ID
 WHERE t.IsDeleted=0 AND (@ID=0 OR t.ID=@ID) AND (@Type=0 OR t.Type=@Type)
 AND ((@Manage=1 AND (@Brand=0 OR t.Brand_ID=@Brand)) OR (@Manage=0 AND (t.Brand_ID=@EmployeeBrand OR (@EmployeeBrand IS NULL AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions WHERE UserTypeID=@Role AND CanSubmit=1))) AND t.IsActive=1))
 ORDER BY t.Item_Order,t.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Save_Employee_Feedback_Topic
 @Actor int,@ID int,@Type int,@Brand int,@TitleAr nvarchar(200),@TitleEn nvarchar(200),@Order int,@Active bit
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'لا تملك صلاحية إدارة المواضيع.',1;
 IF @Type NOT IN(1,2) OR NULLIF(LTRIM(RTRIM(@TitleAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@TitleEn)),N'') IS NULL THROW 51500,N'أدخل نوع الموضوع واسمه بالعربية والإنجليزية.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'اختر علامة تجارية فعالة.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF @ID=0 BEGIN
 INSERT dbo.Employee_Feedback_Topics(Type,Brand_ID,Title_Ar,Title_En,Item_Order,AddedUser,IsActive)
 VALUES(@Type,@Brand,@TitleAr,@TitleEn,@Order,@Actor,@Active); SET @ID=CONVERT(int,SCOPE_IDENTITY()); END
 ELSE BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0) THROW 51500,N'الموضوع غير موجود.',1;
 IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE Topic_ID=@ID AND (Type<>@Type OR Brand_ID<>@Brand)) THROW 51500,N'لا يمكن تغيير نوع أو علامة موضوع مرتبط بطلبات. يمكنك تعطيله وإنشاء موضوع جديد.',1;
 UPDATE dbo.Employee_Feedback_Topics SET Type=@Type,Brand_ID=@Brand,Title_Ar=@TitleAr,Title_En=@TitleEn,Item_Order=@Order,IsActive=@Active,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE ID=@ID;
 END;
 COMMIT; SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Delete_Employee_Feedback_Topic @Actor int,@ID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'لا تملك صلاحية إدارة المواضيع.',1;
 UPDATE dbo.Employee_Feedback_Topics SET IsDeleted=1,IsActive=0,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE ID=@ID AND IsDeleted=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Recipients @Actor int,@Target int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type JOIN dbo.Employee_Feedback_AllowedRecipients r ON r.SenderUserTypeID=a.Type AND r.RecipientUserTypeID=@Target JOIN dbo.Users_Types t ON t.ID=r.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE a.ID=@Actor AND (p.CanSubmit=1 OR p.CanTransfer=1) AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0) THROW 51500,N'حساب الموظف أو الجهة غير متاح.',1;
 SELECT ID,Type,FullName_Ar,CONVERT(bit,CASE WHEN Type<>@Target THEN 1 ELSE 0 END) IsFallback FROM dbo.Employee_Feedback_Targets(@Actor,@Target);
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
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WITH(HOLDLOCK) WHERE ID=@Topic AND Type=@Type AND Brand_ID=@Brand AND IsActive=1 AND IsDeleted=0) THROW 51500,N'اختر موضوعًا فعالًا يطابق نوع الطلب وعلامتك التجارية.',1;
 DECLARE @Targets TABLE(ID int PRIMARY KEY,Type int);
 INSERT @Targets SELECT ID,Type FROM dbo.Employee_Feedback_Targets(@Actor,@Target);
 IF NOT EXISTS(SELECT 1 FROM @Targets) THROW 51500,N'لا يوجد مدير متاح لاستلام الطلب.',1;
 INSERT dbo.Employee_Feedback_Requests(EmployeeID,Type,Topic_ID,Brand_ID,Topic_Title_Ar,Topic_Title_En,Title,Details,DiscloseIdentity,RequestedRecipientType,AddedDate)
 SELECT @Actor,@Type,ID,@Brand,Title_Ar,Title_En,@Title,@Details,@Disclose,@Target,@Now FROM dbo.Employee_Feedback_Topics WHERE ID=@Topic;
 SET @ID=CONVERT(int,SCOPE_IDENTITY());
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate)
 SELECT @ID,@Actor,ID,CASE WHEN Type<>@Target THEN N'تقديم الطلب إلى مدير النظام لعدم وجود المدير المطلوب.' ELSE N'تم تقديم الطلب.' END,1,@Group,@Now FROM @Targets;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,NotificationType,SendDate) SELECT ID,@ID,1,@Now FROM @Targets;
 COMMIT; SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Requests
 @Actor int,@Mode int,@Search nvarchar(300),@Type int=0,@Status int=0,@Brand int=0,@Branch int=0,@Shift int=0,@From date=NULL,@To date=NULL,@Identity int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF @Mode NOT IN(0,1,2,3) OR NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Mode<>2 OR Type=1)) THROW 51500,N'لا تملك صلاحية الاطلاع على التقرير.',1;
 SELECT r.ID,r.Type,r.Title,r.Status,r.AddedDate,r.CloseDate,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN e.FullName_Ar ELSE N'هوية غير معلنة' END) EmployeeName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN b.Title_Ar ELSE N'—' END) BranchName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN br.Title_Ar ELSE N'—' END) BrandName,
 CONVERT(nvarchar(50),ISNULL((SELECT Title_Ar FROM dbo.Users_Types WHERE ID=m.Type),N'—')) CurrentRecipient,
 CONVERT(int,(SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications n WHERE n.Request_ID=r.ID AND n.UserID=@Actor AND n.IsRead=0)) UnreadCount
 FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
 LEFT JOIN dbo.Branches b ON b.ID=e.Branch_ID LEFT JOIN dbo.Brands br ON br.ID=r.Brand_ID
 OUTER APPLY(SELECT TOP(1) w.ReceiverID FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ActionType IN(1,2) ORDER BY w.ID DESC) lastw
 LEFT JOIN dbo.UsersMembers m ON m.ID=lastw.ReceiverID
 WHERE (@Mode=2 OR (@Mode=3 AND r.Status<>3 AND r.EmployeeID<>@Actor AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.UsersMembers a ON a.ID=@Actor JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.GroupID=(SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=r.ID ORDER BY ID DESC) AND w.ActionType IN(1,2) AND (p.CanTransfer=1 OR p.CanClose=1))) OR (@Mode=1 AND r.EmployeeID=@Actor) OR (@Mode=0 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.ActionType IN(1,2))))
 AND (@Search=N'' OR CHARINDEX(@Search,r.Title)>0 OR CONVERT(nvarchar(20),r.ID)=@Search)
 AND (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To)
 AND ((@Brand=0 AND @Branch=0 AND @Shift=0) OR ((r.DiscloseIdentity=1 OR r.EmployeeID=@Actor) AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR e.Branch_ID=@Branch) AND (@Shift=0 OR e.Shif_ID=@Shift)));
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Request @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT r.ID,r.Type,r.Title,r.Details,r.Status,r.AddedDate,r.CloseDate,r.RowVersion,r.DiscloseIdentity,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN e.FullName_Ar ELSE N'هوية غير معلنة' END) EmployeeName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN r.Topic_Title_Ar ELSE N'موضوع غير معلن' END) TopicName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN b.Title_Ar ELSE N'' END) BranchName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN br.Title_Ar ELSE N'' END) BrandName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN d.Title_Ar ELSE N'' END) DepartmentName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN j.Title_Ar ELSE N'' END) JobTitleName,
 CONVERT(nvarchar(max),CASE WHEN r.DiscloseIdentity=1 OR r.EmployeeID=@Actor THEN s.Title_Ar ELSE N'' END) ShiftName,
 CONVERT(bit,CASE WHEN @Report=0 AND r.Status<>3 AND r.EmployeeID<>@Actor AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions p WHERE p.UserTypeID=a.Type AND (p.CanTransfer=1 OR p.CanClose=1))
 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.GroupID=lastw.GroupID AND w.ReceiverID=@Actor AND w.ActionType IN(1,2))
  THEN 1 ELSE 0 END) CanAct,
 CONVERT(int,a.Type) ActorType
 FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID JOIN dbo.UsersMembers a ON a.ID=@Actor
 LEFT JOIN dbo.Branches b ON b.ID=e.Branch_ID LEFT JOIN dbo.Brands br ON br.ID=r.Brand_ID LEFT JOIN dbo.Departments d ON d.ID=e.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=e.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=e.Shif_ID
 OUTER APPLY(SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=r.ID ORDER BY ID DESC) lastw
 WHERE r.ID=@ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Workflow @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT w.GroupID,w.ActionType,MIN(w.AddedDate) AddedDate,MAX(w.Comment) Comment,
 MAX(CONVERT(nvarchar(max),CASE WHEN w.SenderID=r.EmployeeID AND r.DiscloseIdentity=0 AND @Actor<>r.EmployeeID THEN N'هوية غير معلنة' ELSE a.FullName_Ar END)) SenderName,
 STRING_AGG(CONVERT(nvarchar(max),CASE WHEN w.ReceiverID=r.EmployeeID AND r.DiscloseIdentity=0 AND @Actor<>r.EmployeeID THEN N'هوية غير معلنة' ELSE b.FullName_Ar END),N'، ') ReceiverNames
 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID JOIN dbo.UsersMembers a ON a.ID=w.SenderID JOIN dbo.UsersMembers b ON b.ID=w.ReceiverID
 WHERE r.ID=@ID GROUP BY w.GroupID,w.ActionType ORDER BY MIN(w.ID);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Attachments @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT a.ID,a.File_Type,a.FileSize,w.GroupID FROM dbo.Employee_Feedback_Attachments a LEFT JOIN dbo.Employee_Feedback_Workflow w ON w.ID=a.Workflow_ID WHERE a.Request_ID=@ID ORDER BY a.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Download @Actor int,@File int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT a.ID,a.FileName,a.File_Type FROM dbo.Employee_Feedback_Attachments a JOIN dbo.Employee_Feedback_Access(@Actor,@Report) x ON x.ID=a.Request_ID WHERE a.ID=@File;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Update_Employee_Feedback_Read @Actor int,@ID int,@Report bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Status int,@Group uniqueidentifier;
 SELECT @Status=Status FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID;
 SELECT TOP(1) @Group=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC;
 IF @Report=0 AND @Status=1 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group AND ReceiverID=@Actor AND ActionType IN(1,2))
 UPDATE dbo.Employee_Feedback_Requests SET Status=2 WHERE ID=@ID;
 UPDATE dbo.Employee_Feedback_Notifications SET IsRead=1,ReadDate=GETUTCDATE() WHERE UserID=@Actor AND Request_ID=@ID AND IsRead=0;
 INSERT dbo.Employee_Feedback_Views(Request_ID,UserID,ViewedDate) VALUES(@ID,@Actor,GETUTCDATE());
 COMMIT;
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
 IF @Employee IS NULL OR @Status=3 OR @Current<>@Version THROW 51500,N'تم اتخاذ إجراء أو تحديث الطلب. أعد فتحه للاطلاع على آخر حالة.',1;
 SELECT @Role=Type,@Brand=Brand_ID,@Branch=Branch_ID,@Shift=Shif_ID FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 SELECT TOP(1) @Group=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC;
 IF @Role IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions WHERE UserTypeID=@Role AND ((@Action=2 AND CanTransfer=1) OR (@Action=3 AND CanClose=1))) OR @Actor=@Employee OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group AND ReceiverID=@Actor AND ActionType IN(1,2)) THROW 51500,N'لا تملك صلاحية اتخاذ إجراء على الطلب.',1;


 DECLARE @Targets TABLE(ID int PRIMARY KEY,Type int);
 IF @Action=2 BEGIN
 SET @Target=@TargetType;
 IF @Target IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_AllowedRecipients rt JOIN dbo.Users_Types t ON t.ID=rt.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE SenderUserTypeID=@Role AND RecipientUserTypeID=@Target) THROW 51500,N'اختر نوع مستلم مسموحًا به للتحويل.',1;
 INSERT @Targets SELECT ID,Type FROM dbo.Employee_Feedback_RoutedTargets(@Employee,@Target,@Actor);
 IF NOT EXISTS(SELECT 1 FROM @Targets) THROW 51500,N'لا يوجد مدير متاح لاستلام التحويل.',1;
 IF EXISTS(SELECT 1 FROM @Targets WHERE Type<>@Target) SET @Comment=@Comment+NCHAR(10)+N'تم التوجيه إلى مدير النظام لعدم وجود المدير المطلوب.';
 END ELSE INSERT @Targets VALUES(@Employee,4);
 SET @Group=NEWID();
 INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID,AddedDate) SELECT @ID,@Actor,ID,@Comment,@Action,@Group,@Now FROM @Targets;
 SELECT @Flow=MIN(ID) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group;
 INSERT dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,FileName,OriginalFileName,File_Type,FileSize,AddedDate)
 SELECT @ID,@Flow,n.value('@name','nvarchar(260)'),n.value('@original','nvarchar(260)'),n.value('@type','nvarchar(10)'),n.value('@size','bigint'),@Now FROM @Files.nodes('/files/file') f(n);
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate)
 SELECT ReceiverID,@ID,ID,@Action,@Now FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group;
 IF @Action=2 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate) VALUES(@Employee,@ID,@Flow,2,@Now);
 UPDATE dbo.Employee_Feedback_Requests SET Status=CASE WHEN @Action=3 THEN 3 ELSE 2 END,CloseDate=CASE WHEN @Action=3 THEN @Now ELSE NULL END WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_UnreadCount @Actor int
AS
BEGIN
 SET NOCOUNT ON;
 SELECT COUNT(DISTINCT n.Request_ID) UnreadRequests FROM dbo.Employee_Feedback_Notifications n
 JOIN dbo.UsersMembers a ON a.ID=@Actor AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0
 WHERE n.UserID=@Actor AND n.IsRead=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Notifications @Actor int
AS
BEGIN
 SET NOCOUNT ON;
 SELECT n.ID,n.Request_ID,n.NotificationType,n.SendDate,n.IsRead,r.Title
 FROM dbo.Employee_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.Request_ID
 JOIN dbo.UsersMembers a ON a.ID=@Actor AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0
 WHERE n.UserID=@Actor ORDER BY n.SendDate DESC,n.ID DESC;
END;
GO
IF COL_LENGTH('dbo.Employee_Feedback_Permissions','RowVersion') IS NULL
 ALTER TABLE dbo.Employee_Feedback_Permissions ADD RowVersion rowversion;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Permissions @Actor int,@Manage bit=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Manage=0 OR Type=1)) THROW 51500,N'غير مسموح بإدارة الصلاحيات.',1;
 SELECT t.ID UserTypeID,t.Title_Ar Title,ISNULL(p.CanSubmit,0) CanSubmit,ISNULL(p.CanTransfer,0) CanTransfer,ISNULL(p.CanClose,0) CanClose,p.RowVersion,
 ISNULL(STUFF((SELECT ','+CONVERT(varchar(12),RecipientUserTypeID) FROM dbo.Employee_Feedback_AllowedRecipients WHERE SenderUserTypeID=t.ID ORDER BY RecipientUserTypeID FOR XML PATH('')),1,1,''),'') Targets
 FROM dbo.Users_Types t LEFT JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=t.ID
 WHERE t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 AND (@Manage=1 OR t.ID=(SELECT Type FROM dbo.UsersMembers WHERE ID=@Actor)) ORDER BY t.Item_Order,t.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Save_Employee_Feedback_Permissions @Actor int,@Role int,@Submit bit,@Transfer bit,@Close bit,@Targets xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'غير مسموح بإدارة الصلاحيات.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Users_Types WHERE ID=@Role AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'نوع المستخدم غير فعال.',1;
 DECLARE @T TABLE(ID int PRIMARY KEY);
 INSERT @T SELECT DISTINCT n.value('@id','int') FROM @Targets.nodes('/targets/target') f(n);
 IF EXISTS(SELECT 1 FROM @T t WHERE NOT EXISTS(SELECT 1 FROM dbo.Users_Types WHERE ID=t.ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)) THROW 51500,N'نوع المستلم غير فعال.',1;
 IF (@Submit=1 OR @Transfer=1) AND NOT EXISTS(SELECT 1 FROM @T) THROW 51500,N'اختر نوع مستلم واحدًا على الأقل.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Current binary(8);
 SELECT @Current=RowVersion FROM dbo.Employee_Feedback_Permissions WITH(UPDLOCK,HOLDLOCK) WHERE UserTypeID=@Role;
 IF @Current IS NOT NULL AND (@Version IS NULL OR @Version<>@Current) THROW 51500,N'تم تحديث الصلاحيات؛ أعد تحميل الصفحة.',1;
 IF @Current IS NULL INSERT dbo.Employee_Feedback_Permissions(UserTypeID) VALUES(@Role);
 UPDATE dbo.Employee_Feedback_Permissions SET CanSubmit=@Submit,CanTransfer=@Transfer,CanClose=@Close,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE UserTypeID=@Role;
 DELETE dbo.Employee_Feedback_AllowedRecipients WHERE SenderUserTypeID=@Role;
 INSERT dbo.Employee_Feedback_AllowedRecipients SELECT @Role,ID FROM @T;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_TargetTypes @Actor int AS
BEGIN
 SET NOCOUNT ON;
 SELECT t.ID,t.Title_Ar Title FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_AllowedRecipients r ON r.SenderUserTypeID=a.Type JOIN dbo.Users_Types t ON t.ID=r.RecipientUserTypeID
 WHERE a.ID=@Actor AND a.IsActive=1 AND ISNULL(a.IsDeleted,0)=0 AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 ORDER BY t.Item_Order,t.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_TransferTargets @Actor int,@ID int,@Target int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,0) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type JOIN dbo.Employee_Feedback_AllowedRecipients r ON r.SenderUserTypeID=a.Type AND r.RecipientUserTypeID=@Target JOIN dbo.Users_Types t ON t.ID=r.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE a.ID=@Actor AND p.CanTransfer=1) THROW 51500,N'التحويل غير مسموح.',1;
 DECLARE @Employee int=(SELECT EmployeeID FROM dbo.Employee_Feedback_Requests WHERE ID=@ID);
 SELECT ID,Type,FullName_Ar,CONVERT(bit,CASE WHEN Type<>@Target THEN 1 ELSE 0 END) IsFallback FROM dbo.Employee_Feedback_RoutedTargets(@Employee,@Target,@Actor);
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
 MAX(CASE WHEN r.DiscloseIdentity=0 AND w.SenderID=r.EmployeeID THEN N'هوية غير معلنة' ELSE u.FullName_Ar END)
 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID JOIN dbo.UsersMembers u ON u.ID=w.SenderID WHERE @ID=0 OR r.ID=@ID GROUP BY w.Request_ID,w.GroupID,w.ActionType
 ) l ORDER BY l.EventDate DESC,l.Request_ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Statistics @Actor int,@Type int=0,@Status int=0,@Identity int=0,@Brand int=0,@Branch int=0,@From date=NULL,@To date=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'الإحصائيات لمدير النظام فقط.',1;
 SELECT r.Type,r.Status,r.DiscloseIdentity,r.Brand_ID,e.Branch_ID,r.AddedDate,r.CloseDate INTO #R
 FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
 WHERE (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR e.Branch_ID=@Branch)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To);
 SELECT CAST('type' AS varchar(20)) Dimension,Type Value,CAST(CASE Type WHEN 1 THEN N'شكوى' ELSE N'اقتراح' END AS nvarchar(300)) Label,COUNT(*) Total FROM #R GROUP BY Type
 UNION ALL SELECT 'status',CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END,COUNT(*) FROM #R GROUP BY CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END
 UNION ALL SELECT 'identity',CASE WHEN DiscloseIdentity=1 THEN 1 ELSE 2 END,CASE WHEN DiscloseIdentity=1 THEN N'معروف الهوية' ELSE N'مجهول الهوية' END,COUNT(*) FROM #R GROUP BY DiscloseIdentity
 UNION ALL SELECT 'brand',ISNULL(r.Brand_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Brands b ON b.ID=r.Brand_ID GROUP BY r.Brand_ID,b.Title_Ar
 UNION ALL SELECT 'branch',ISNULL(r.Branch_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Branches b ON b.ID=r.Branch_ID GROUP BY r.Branch_ID,b.Title_Ar
 UNION ALL SELECT 'month',CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126),COUNT(*) FROM #R GROUP BY CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126);
END;
GO
