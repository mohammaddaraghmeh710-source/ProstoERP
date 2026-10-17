SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Employee_Feedback_Types','U') IS NULL BEGIN
 CREATE TABLE dbo.Employee_Feedback_Types(ID int IDENTITY PRIMARY KEY,Title_Ar nvarchar(200) NOT NULL,Title_En nvarchar(200) NOT NULL,Item_Order int NOT NULL DEFAULT(0),IsActive bit NOT NULL DEFAULT(1),IsDeleted bit NOT NULL DEFAULT(0),AddedUser int NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime NOT NULL DEFAULT(GETUTCDATE()),ModifyUser int NULL REFERENCES dbo.UsersMembers(ID),ModifyDate datetime NULL,RowVersion rowversion,
 CONSTRAINT CK_EF_Types_Titles CHECK(LEN(LTRIM(RTRIM(Title_Ar)))>0 AND LEN(LTRIM(RTRIM(Title_En)))>0),CONSTRAINT CK_EF_Types_Order CHECK(Item_Order>=0));
 SET IDENTITY_INSERT dbo.Employee_Feedback_Types ON;
 INSERT dbo.Employee_Feedback_Types(ID,Title_Ar,Title_En,Item_Order) VALUES(1,N'شكوى',N'Complaint',1),(2,N'اقتراح',N'Suggestion',2);
 SET IDENTITY_INSERT dbo.Employee_Feedback_Types OFF;
END;
GO
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_EF_Topics_Type') ALTER TABLE dbo.Employee_Feedback_Topics DROP CONSTRAINT CK_EF_Topics_Type;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_EF_Topics_Type') ALTER TABLE dbo.Employee_Feedback_Topics ADD CONSTRAINT FK_EF_Topics_Type FOREIGN KEY(Type) REFERENCES dbo.Employee_Feedback_Types(ID);
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_EF_Requests_Type') ALTER TABLE dbo.Employee_Feedback_Requests ADD CONSTRAINT FK_EF_Requests_Type FOREIGN KEY(Type) REFERENCES dbo.Employee_Feedback_Types(ID);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Branch_ID') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Branch_ID int NULL REFERENCES dbo.Branches(ID);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Department_ID') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Department_ID int NULL REFERENCES dbo.Departments(ID);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','JobTitle_ID') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD JobTitle_ID int NULL REFERENCES dbo.JobTitles(ID);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Shift_ID') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Shift_ID int NULL REFERENCES dbo.Shift(ID);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Brand_Title_Ar') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Brand_Title_Ar nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Brand_Title_En') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Brand_Title_En nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Branch_Title_Ar') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Branch_Title_Ar nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Branch_Title_En') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Branch_Title_En nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Department_Title_Ar') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Department_Title_Ar nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','JobTitle_Title_Ar') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD JobTitle_Title_Ar nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','Shift_Title_Ar') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD Shift_Title_Ar nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantName') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantName nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantNameEn') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantNameEn nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantEmployeeNumber') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantEmployeeNumber int NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantPhone') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantPhone nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantMobile') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantMobile nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantEmail') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantEmail nvarchar(max) NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantDataCapturedAt') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantDataCapturedAt datetime NULL;
IF COL_LENGTH('dbo.Employee_Feedback_Requests','ApplicantDataIsBackfilled') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD ApplicantDataIsBackfilled bit NOT NULL CONSTRAINT DF_EF_Applicant_Backfilled DEFAULT(0);
IF COL_LENGTH('dbo.Employee_Feedback_Requests','SourceType') IS NULL ALTER TABLE dbo.Employee_Feedback_Requests ADD SourceType int NOT NULL CONSTRAINT DF_EF_Request_Source DEFAULT(1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_EF_Request_Source') ALTER TABLE dbo.Employee_Feedback_Requests ADD CONSTRAINT CK_EF_Request_Source CHECK(SourceType IN(1,2));
-- Backfill from current account data exactly once; not historical reconstruction.
UPDATE r SET Branch_ID=e.Branch_ID,Department_ID=e.Department_ID,JobTitle_ID=e.JobTitle_ID,Shift_ID=e.Shif_ID,
 Brand_Title_Ar=b.Title_Ar,Brand_Title_En=b.Title_En,Branch_Title_Ar=br.Title_Ar,Branch_Title_En=br.Title_En,
 Department_Title_Ar=d.Title_Ar,JobTitle_Title_Ar=j.Title_Ar,Shift_Title_Ar=s.Title_Ar,
 ApplicantName=e.FullName_Ar,ApplicantNameEn=e.Fullname_En,ApplicantEmployeeNumber=e.Employee_Number,
 ApplicantPhone=e.PhoneNumber,ApplicantMobile=e.MobileNumber,ApplicantEmail=e.Email,
 ApplicantDataCapturedAt=GETUTCDATE(),ApplicantDataIsBackfilled=1
FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
LEFT JOIN dbo.Brands b ON b.ID=r.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=e.Branch_ID
LEFT JOIN dbo.Departments d ON d.ID=e.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=e.JobTitle_ID LEFT JOIN dbo.Shift s ON s.ID=e.Shif_ID
WHERE r.ApplicantDataCapturedAt IS NULL;
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
 WHERE (@Manage=1 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types k WHERE k.ID=t.Type AND k.IsActive=1 AND k.IsDeleted=0)) AND t.IsDeleted=0 AND (@ID=0 OR t.ID=@ID) AND (@Type=0 OR t.Type=@Type)
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
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WHERE ID=@Type AND IsDeleted=0 AND (IsActive=1 OR (@ID>0 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WHERE ID=@ID AND Type=@Type)))) OR NULLIF(LTRIM(RTRIM(@TitleAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@TitleEn)),N'') IS NULL THROW 51500,N'أدخل نوع الموضوع واسمه بالعربية والإنجليزية.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'اختر علامة تجارية فعالة.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(HOLDLOCK) WHERE ID=@Type AND IsDeleted=0 AND (IsActive=1 OR (@ID>0 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WHERE ID=@ID AND Type=@Type)))) THROW 51500,N'نوع الموضوع غير متاح.',1;
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
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,NotificationType,SendDate) SELECT ID,@ID,1,@Now FROM @Targets;
 COMMIT; SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
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
 WHERE (@Mode=2 OR (@Mode=3 AND r.Status<>3 AND r.EmployeeID<>@Actor AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.UsersMembers a ON a.ID=@Actor JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.GroupID=(SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=r.ID ORDER BY ID DESC) AND w.ActionType IN(1,2) AND (p.CanTransfer=1 OR p.CanClose=1))) OR (@Mode=1 AND r.EmployeeID=@Actor) OR (@Mode=0 AND EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w WHERE w.Request_ID=r.ID AND w.ReceiverID=@Actor AND w.ActionType IN(1,2))))
 AND (@Search=N'' OR CHARINDEX(@Search,r.Title)>0 OR CONVERT(nvarchar(20),r.ID)=@Search)
 AND (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To)
 AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR r.Branch_ID=@Branch)
 AND (@Shift=0 OR ((r.DiscloseIdentity=1 OR r.EmployeeID=@Actor) AND r.Shift_ID=@Shift)) AND (@Source=0 OR r.SourceType=@Source);
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
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Statistics @Actor int,@Type int=0,@Status int=0,@Identity int=0,@Brand int=0,@Branch int=0,@From date=NULL,@To date=NULL,@Source int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'الإحصائيات لمدير النظام فقط.',1;
 SELECT r.Type,r.Status,r.DiscloseIdentity,r.Brand_ID,r.Branch_ID,r.AddedDate,r.CloseDate,r.SourceType INTO #R
 FROM dbo.Employee_Feedback_Requests r LEFT JOIN dbo.UsersMembers e ON e.ID=r.EmployeeID
 WHERE (@Type=0 OR r.Type=@Type) AND (@Status=0 OR r.Status=@Status OR (@Status=4 AND r.Status<>3))
 AND (@Identity=0 OR r.DiscloseIdentity=CASE WHEN @Identity=1 THEN 1 ELSE 0 END)
 AND (@Brand=0 OR r.Brand_ID=@Brand) AND (@Branch=0 OR r.Branch_ID=@Branch) AND (@Source=0 OR r.SourceType=@Source)
 AND (@From IS NULL OR r.AddedDate>=@From) AND (@To IS NULL OR CONVERT(date,r.AddedDate)<=@To);
 SELECT CAST('type' AS varchar(20)) Dimension,r.Type Value,CAST(t.Title_Ar AS nvarchar(300)) Label,COUNT(*) Total FROM #R r JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type GROUP BY r.Type,t.Title_Ar
 UNION ALL SELECT 'status',CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END,COUNT(*) FROM #R GROUP BY CASE WHEN Status=3 THEN 3 ELSE 4 END,CASE WHEN Status=3 THEN N'منتهي' ELSE N'فعال' END
 UNION ALL SELECT 'identity',CASE WHEN DiscloseIdentity=1 THEN 1 ELSE 2 END,CASE WHEN DiscloseIdentity=1 THEN N'معروف الهوية' ELSE N'مجهول الهوية' END,COUNT(*) FROM #R GROUP BY DiscloseIdentity
 UNION ALL SELECT 'brand',ISNULL(r.Brand_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Brands b ON b.ID=r.Brand_ID GROUP BY r.Brand_ID,b.Title_Ar
 UNION ALL SELECT 'branch',ISNULL(r.Branch_ID,0),ISNULL(b.Title_Ar,N'غير محدد'),COUNT(*) FROM #R r LEFT JOIN dbo.Branches b ON b.ID=r.Branch_ID GROUP BY r.Branch_ID,b.Title_Ar
 UNION ALL SELECT 'source',SourceType,CASE SourceType WHEN 1 THEN N'موظف' ELSE N'زبون' END,COUNT(*) FROM #R GROUP BY SourceType
 UNION ALL SELECT 'month',CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126),COUNT(*) FROM #R GROUP BY CONVERT(int,CONVERT(char(6),AddedDate,112)),CONVERT(nvarchar(7),AddedDate,126);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Types @Actor int,@Mode int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF @Mode NOT IN(0,1,2) OR NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Mode<>1 OR Type=1)) THROW 51500,N'غير مسموح بإدارة أنواع الطلبات.',1;
 SELECT ID,Title_Ar,Title_En,Item_Order,IsActive,IsDeleted,RowVersion FROM dbo.Employee_Feedback_Types
 WHERE (@Mode=2 OR IsDeleted=0) AND (@Mode<>0 OR IsActive=1) ORDER BY Item_Order,ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Save_Employee_Feedback_Type @Actor int,@ID int,@TitleAr nvarchar(200),@TitleEn nvarchar(200),@Order int,@Active bit,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'غير مسموح بإدارة أنواع الطلبات.',1;
 IF NULLIF(LTRIM(RTRIM(@TitleAr)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@TitleEn)),N'') IS NULL OR @Order<0 OR @Order IS NULL OR @Active IS NULL THROW 51500,N'أدخل اسم النوع بالعربية والإنجليزية وترتيب عرض صحيحًا.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(UPDLOCK,HOLDLOCK) WHERE IsDeleted=0 AND ID<>@ID AND (Title_Ar=LTRIM(RTRIM(@TitleAr)) OR Title_En=LTRIM(RTRIM(@TitleEn)))) THROW 51500,N'اسم النوع مستخدم بالفعل.',1;
 IF @ID=0 BEGIN
 INSERT dbo.Employee_Feedback_Types(Title_Ar,Title_En,Item_Order,IsActive,AddedUser) VALUES(LTRIM(RTRIM(@TitleAr)),LTRIM(RTRIM(@TitleEn)),@Order,@Active,@Actor);
 SET @ID=CONVERT(int,SCOPE_IDENTITY());
 END ELSE BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND IsDeleted=0 AND RowVersion=@Version) THROW 51500,N'النوع غير متاح أو تم تعديله؛ أعد تحميل الصفحة.',1;
 UPDATE dbo.Employee_Feedback_Types SET Title_Ar=LTRIM(RTRIM(@TitleAr)),Title_En=LTRIM(RTRIM(@TitleEn)),Item_Order=@Order,IsActive=@Active,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE ID=@ID;
 END;
 COMMIT;
 SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Delete_Employee_Feedback_Type @Actor int,@ID int,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51500,N'غير مسموح بإدارة أنواع الطلبات.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Types WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND RowVersion=@Version AND IsDeleted=0) THROW 51500,N'النوع غير متاح أو تم تعديله؛ أعد تحميل الصفحة.',1;
 IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Topics WHERE Type=@ID) OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE Type=@ID) THROW 51500,N'النوع مرتبط بمواضيع أو طلبات؛ يمكنك تعطيله بدلًا من حذفه.',1;
 UPDATE dbo.Employee_Feedback_Types SET IsDeleted=1,IsActive=0,ModifyUser=@Actor,ModifyDate=GETUTCDATE() WHERE ID=@ID AND RowVersion=@Version AND IsDeleted=0;
 IF @@ROWCOUNT<>1 THROW 51500,N'النوع غير متاح أو تم تعديله؛ أعد تحميل الصفحة.',1;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Applicant @Actor int AS
BEGIN
 SET NOCOUNT ON;
 SELECT CONVERT(int,1) SourceType,e.FullName_Ar ApplicantName,e.Fullname_En ApplicantNameEn,e.Employee_Number ApplicantEmployeeNumber,
 e.PhoneNumber ApplicantPhone,e.MobileNumber ApplicantMobile,e.Email ApplicantEmail,b.Title_Ar BrandName,br.Title_Ar BranchName,
 CAST(NULL AS datetime) CapturedAt,CONVERT(bit,0) IsBackfilled,CONVERT(bit,1) CanViewContact
 FROM dbo.UsersMembers e LEFT JOIN dbo.Brands b ON b.ID=e.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=e.Branch_ID
 WHERE e.ID=@Actor AND e.IsActive=1 AND ISNULL(e.IsDeleted,0)=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_ApplicantSummary @Actor int,@ID int,@Report bit=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT r.SourceType,r.Brand_Title_Ar BrandName,r.Branch_Title_Ar BranchName,r.ApplicantDataCapturedAt CapturedAt,r.ApplicantDataIsBackfilled IsBackfilled
 FROM dbo.Employee_Feedback_Requests r WHERE r.ID=@ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_Contact @Actor int,@ID int,@Report bit=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,@Report) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح لك.',1;
 SELECT r.SourceType,r.Brand_Title_Ar BrandName,r.Branch_Title_Ar BranchName,r.ApplicantDataCapturedAt CapturedAt,r.ApplicantDataIsBackfilled IsBackfilled,
 CONVERT(bit,CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN 1 ELSE 0 END) CanViewContact,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantName ELSE N'هوية غير معلنة' END ApplicantName,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantNameEn ELSE NULL END ApplicantNameEn,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantEmployeeNumber ELSE NULL END ApplicantEmployeeNumber,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantPhone ELSE NULL END ApplicantPhone,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantMobile ELSE NULL END ApplicantMobile,
 CASE WHEN DiscloseIdentity=1 OR EmployeeID=@Actor THEN ApplicantEmail ELSE NULL END ApplicantEmail
 FROM dbo.Employee_Feedback_Requests r WHERE r.ID=@ID;
END;
GO
CREATE OR ALTER FUNCTION dbo.Employee_Feedback_RequestTargets(@ID int,@Target int,@Exclude int)
RETURNS TABLE AS RETURN
 WITH candidates AS (
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.Employee_Feedback_Requests r JOIN dbo.UsersMembers m ON m.ID<>r.EmployeeID AND m.ID<>@Exclude
 WHERE r.ID=@ID AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0 AND m.Type=@Target
 AND (@Target=1 OR (m.Brand_ID=r.Brand_ID AND m.Branch_ID=r.Branch_ID AND (@Target NOT IN(3,6) OR (@Target=3 AND m.Shif_ID=r.Shift_ID) OR (@Target=6 AND m.Department_ID=r.Department_ID))))
 )
 SELECT ID,Type,FullName_Ar FROM candidates
 UNION ALL
 SELECT m.ID,m.Type,m.FullName_Ar FROM dbo.UsersMembers m JOIN dbo.Employee_Feedback_Requests r ON r.ID=@ID WHERE m.Type=1 AND m.ID<>r.EmployeeID AND m.ID<>@Exclude AND m.IsActive=1 AND ISNULL(m.IsDeleted,0)=0 AND @Target<>1 AND NOT EXISTS(SELECT 1 FROM candidates);
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
 SELECT ReceiverID,@ID,ID,@Action,@Now FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND GroupID=@Group;
 IF @Action=2 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType,SendDate) VALUES(@Employee,@ID,@Flow,2,@Now);
 UPDATE dbo.Employee_Feedback_Requests SET Status=CASE WHEN @Action=3 THEN 3 ELSE 2 END,CloseDate=CASE WHEN @Action=3 THEN @Now ELSE NULL END WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Employee_Feedback_TransferTargets @Actor int,@ID int,@Target int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Access(@Actor,0) WHERE ID=@ID) THROW 51500,N'الطلب غير متاح.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers a JOIN dbo.Employee_Feedback_Permissions p ON p.UserTypeID=a.Type JOIN dbo.Employee_Feedback_AllowedRecipients r ON r.SenderUserTypeID=a.Type AND r.RecipientUserTypeID=@Target JOIN dbo.Users_Types t ON t.ID=r.RecipientUserTypeID AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 WHERE a.ID=@Actor AND p.CanTransfer=1) THROW 51500,N'التحويل غير مسموح.',1;
 DECLARE @Employee int=(SELECT EmployeeID FROM dbo.Employee_Feedback_Requests WHERE ID=@ID);
 SELECT ID,Type,FullName_Ar,CONVERT(bit,CASE WHEN Type<>@Target THEN 1 ELSE 0 END) IsFallback FROM dbo.Employee_Feedback_RequestTargets(@ID,@Target,@Actor);
END;
GO
