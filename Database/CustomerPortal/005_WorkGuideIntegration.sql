SET XACT_ABORT ON;
IF COL_LENGTH('dbo.Work_Guide_Access_Requests','Customer_ID') IS NULL
BEGIN
 DROP INDEX UX_WG_Request_Pending ON dbo.Work_Guide_Access_Requests;
 ALTER TABLE dbo.Work_Guide_Access_Requests ALTER COLUMN User_ID int NULL;
 ALTER TABLE dbo.Work_Guide_Access_Requests ADD Customer_ID int NULL REFERENCES dbo.CRM_Accounts(ID);
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Work_Guide_Access_Requests') AND name='UX_WG_Request_CustomerPending')
BEGIN
 CREATE UNIQUE INDEX UX_WG_Request_CustomerPending ON dbo.Work_Guide_Access_Requests(Customer_ID,Brand_ID,Category_ID) WHERE Status='P' AND Customer_ID IS NOT NULL;
 CREATE UNIQUE INDEX UX_WG_Request_Pending ON dbo.Work_Guide_Access_Requests(User_ID,Brand_ID,Category_ID) WHERE Status='P' AND User_ID IS NOT NULL;
 ALTER TABLE dbo.Work_Guide_Access_Requests ADD CONSTRAINT CK_WG_Request_Identity CHECK((User_ID IS NULL AND Customer_ID IS NOT NULL) OR (User_ID IS NOT NULL AND Customer_ID IS NULL));
END;
IF COL_LENGTH('dbo.Customer_Guide_Grants','AddedDate') IS NULL ALTER TABLE dbo.Customer_Guide_Grants ADD AddedDate datetime NOT NULL DEFAULT GETDATE();
IF COL_LENGTH('dbo.Customer_Portal_Activity','FeedbackTypeTitle') IS NULL ALTER TABLE dbo.Customer_Portal_Activity ADD FeedbackTypeTitle nvarchar(200) NULL;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuideAdmin @Actor int,@Section varchar(20),@AccountID int=0,@Brand int=0,@Role int=0,@OldRole int=0,@Categories xml=NULL,@Active bit=1 AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.Customer_AdminCheck @Actor;
 IF @Section='customers' BEGIN SELECT a.ID,a.Name_AR Title FROM dbo.CRM_Accounts a WHERE a.Is_Deleted=0 ORDER BY a.Name_AR;RETURN;END;
 IF @Section='groups' BEGIN
 SELECT g.AccountID User_ID,g.Brand_ID,g.Role_ID,a.Name_AR User_FullName_Ar,b.Title_Ar Brand_Title_Ar,r.Title_Ar Role_Title_Ar,COUNT(*) Categories_Count,CAST(MAX(CAST(g.IsActive AS int)) AS bit) IsActive,MIN(g.AddedDate) AddedDate
 FROM dbo.Customer_Guide_Grants g JOIN dbo.CRM_Accounts a ON a.ID=g.AccountID JOIN dbo.Brands b ON b.ID=g.Brand_ID JOIN dbo.Work_Guide_Roles r ON r.ID=g.Role_ID
 WHERE (@AccountID=0 OR g.AccountID=@AccountID) AND (@Brand=0 OR g.Brand_ID=@Brand) AND (@Role=0 OR g.Role_ID=@Role)
 GROUP BY g.AccountID,g.Brand_ID,g.Role_ID,a.Name_AR,b.Title_Ar,r.Title_Ar;RETURN;
 END;
 IF @Section='details' BEGIN SELECT * FROM dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Brand_ID=@Brand AND Role_ID=@Role;RETURN;END;
 IF @Section NOT IN('add','edit','delete') THROW 51910,N'عملية غير صحيحة.',1;
 BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@AccountID AND Is_Deleted=0) THROW 51910,N'العميل غير متاح.',1;
 IF @Section='delete' BEGIN
  DELETE dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Brand_ID=@Brand AND Role_ID=@Role;
  INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) VALUES(@AccountID,@Actor,'grant',CONCAT(N'إلغاء صلاحيات الدور ',@Role,N' على العلامة ',@Brand));
  COMMIT;RETURN;
 END;
 DECLARE @Selected TABLE(ID int PRIMARY KEY);
 INSERT @Selected SELECT DISTINCT n.value('@id','int') FROM @Categories.nodes('/items/item')x(n);
 IF (SELECT COUNT(*) FROM @Selected) NOT BETWEEN 1 AND 200 THROW 51910,N'اختر من تصنيف واحد إلى 200 تصنيف.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0) OR NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Roles WHERE ID=@Role AND ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0) THROW 51910,N'اختر علامة ودورًا فعالين.',1;
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.Work_Guide_Categories c ON c.ID=s.ID AND c.Brand_ID=@Brand AND ISNULL(c.IsActive,1)=1 AND ISNULL(c.IsDeleted,0)=0 WHERE c.ID IS NULL) THROW 51910,N'التصنيفات لا تطابق العلامة التجارية.',1;
 IF EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants g WITH(UPDLOCK,HOLDLOCK) JOIN @Selected s ON s.ID=g.Category_ID WHERE g.AccountID=@AccountID AND (@Section='add' OR g.Role_ID<>@OldRole)) THROW 51910,N'أحد التصنيفات مرتبط بتفويض آخر؛ عدّل التفويض الحالي أولًا.',1;
 IF @Section='edit' BEGIN
  DELETE dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Brand_ID=@Brand AND Role_ID=@OldRole AND Category_ID NOT IN(SELECT ID FROM @Selected);
  UPDATE dbo.Customer_Guide_Grants SET Role_ID=@Role,IsActive=@Active,ModifiedBy=@Actor WHERE AccountID=@AccountID AND Brand_ID=@Brand AND Role_ID=@OldRole;
 END;
 INSERT dbo.Customer_Guide_Grants(AccountID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,IsActive,ModifiedBy)
 SELECT @AccountID,@Brand,s.ID,@Role,0,@Active,@Actor FROM @Selected s WHERE NOT EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants WHERE AccountID=@AccountID AND Category_ID=s.ID);
 INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) VALUES(@AccountID,@Actor,'grant',CONCAT(N'تحديث صلاحيات دليل العمل: العلامة ',@Brand,N'، الدور ',@Role));
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide @AccountID int,@Stamp uniqueidentifier,@Brand int=0,@Section varchar(20),@Status char(1)='P',@Categories xml=NULL,@Search nvarchar(500)=N'',@Reason nvarchar(1000)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Section='brands' BEGIN SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;RETURN;END;
 IF @Section IN('categories','request-categories') BEGIN
 SELECT c.*,REPLICATE(N'— ',c.Level_No)+c.Title_Ar Tree_Title_Ar,q.ID Pending_Request_ID,CAST(CASE WHEN c.Can_View_Document=0 AND q.ID IS NULL THEN 1 ELSE 0 END AS bit) Can_Request
 FROM dbo.Customer_Guide_Effective(@AccountID,@Brand)c LEFT JOIN dbo.Work_Guide_Access_Requests q ON q.Customer_ID=@AccountID AND q.Brand_ID=@Brand AND q.Category_ID=c.ID AND q.Status='P'
 WHERE @Section='request-categories' OR c.Can_View_Category=1 OR c.Can_View_Document=1 ORDER BY c.Sort_Path OPTION(MAXRECURSION 100);RETURN;
 END;
 IF @Section='documents' BEGIN
 SELECT d.ID,d.Title_Ar,c.Full_Path_Ar Category_Title_Ar,d.File_Size,d.AddedDate,c.Can_View_Document,c.Can_Print_Document,CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) Can_Download_Document
 FROM dbo.Work_Guide_Documents d JOIN dbo.Customer_Guide_Effective(@AccountID,@Brand)c ON c.ID=d.Category_ID
 WHERE d.Brand_ID=@Brand AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1
 AND (@Categories IS NULL OR @Categories.exist('/items/item')=0 OR d.Category_ID IN(SELECT n.value('@id','int') FROM @Categories.nodes('/items/item')x(n)))
 AND (@Search=N'' OR CHARINDEX(@Search,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Search,ISNULL(d.Description_Ar,N''))>0 OR CHARINDEX(@Search,c.Full_Path_Ar)>0) ORDER BY d.AddedDate DESC,d.ID DESC OPTION(MAXRECURSION 100);RETURN;
 END;
 IF @Section='requests' BEGIN
 SELECT q.ID,q.Batch_ID,q.Brand_ID,b.Title_Ar Brand_Name,COALESCE(q.Category_Path,c.Title_Ar) Category_Name,q.Reason,q.AddedDate,q.Status,r.Title_Ar Role_Name,q.ReviewNote,q.ReviewedDate
 FROM dbo.Work_Guide_Access_Requests q JOIN dbo.Brands b ON b.ID=q.Brand_ID JOIN dbo.Work_Guide_Categories c ON c.ID=q.Category_ID LEFT JOIN dbo.Work_Guide_Roles r ON r.ID=q.Assigned_Role_ID
 WHERE q.Customer_ID=@AccountID AND (@Brand=0 OR q.Brand_ID=@Brand) AND (q.Status=@Status OR (@Status='H' AND q.Status IN('A','R'))) ORDER BY q.ID DESC;RETURN;
 END;
 IF @Section<>'submit' THROW 51910,N'عملية غير صحيحة.',1;
 IF NULLIF(LTRIM(RTRIM(@Reason)),N'') IS NULL THROW 51102,N'اكتب سبب الطلب.',1;
 DECLARE @Selected TABLE(ID int PRIMARY KEY);INSERT @Selected SELECT DISTINCT n.value('@id','int') FROM @Categories.nodes('/items/item')x(n);
 IF (SELECT COUNT(*) FROM @Selected) NOT BETWEEN 1 AND 200 THROW 51102,N'حدد التصنيفات المطلوبة.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l WITH(UPDLOCK,HOLDLOCK) JOIN dbo.CRM_Accounts a WITH(HOLDLOCK) ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.Customer_Guide_Effective(@AccountID,@Brand)c ON c.ID=s.ID WHERE c.ID IS NULL OR c.Can_View_Document=1) THROW 51103,N'اختر تصنيفات غير متاحة لك ضمن العلامة المحددة.',1;
 IF EXISTS(SELECT 1 FROM dbo.Work_Guide_Access_Requests q WITH(UPDLOCK,HOLDLOCK) JOIN @Selected s ON s.ID=q.Category_ID WHERE q.Customer_ID=@AccountID AND q.Status='P') THROW 51104,N'يوجد طلب معلق لأحد التصنيفات.',1;
 DECLARE @Batch uniqueidentifier=NEWID();
 INSERT dbo.Work_Guide_Access_Requests(Batch_ID,Customer_ID,Brand_ID,Category_ID,Category_Path,Reason)
 SELECT @Batch,@AccountID,@Brand,s.ID,c.Full_Path_Ar,@Reason FROM @Selected s JOIN dbo.Customer_Guide_Effective(@AccountID,@Brand)c ON c.ID=s.ID;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Note) VALUES(@AccountID,'access-request',CONCAT(N'طلب صلاحية دليل العمل، العلامة ',@Brand));
 COMMIT;SELECT @Batch Batch_ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_FeedbackDetail @AccountID int,@Stamp uniqueidentifier,@ID int=0,@AttachmentID int=0,@Section varchar(16)='detail' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @AttachmentID>0 BEGIN SELECT f.ID,f.FileName,f.File_Type,f.FileSize FROM dbo.Employee_Feedback_Attachments f JOIN dbo.Customer_Portal_Feedback c ON c.RequestID=f.Request_ID WHERE c.AccountID=@AccountID AND f.ID=@AttachmentID AND f.Workflow_ID IS NULL;RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Portal_Feedback WHERE AccountID=@AccountID AND RequestID=@ID) THROW 51912,N'الطلب غير متاح.',1;
 IF @Section='attachments' BEGIN SELECT ID,File_Type,FileSize FROM dbo.Employee_Feedback_Attachments WHERE Request_ID=@ID AND Workflow_ID IS NULL ORDER BY ID;RETURN;END;
 SELECT r.ID,r.Title,r.Details,r.Status,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,r.Branch_Title_Ar,r.Topic_Title_Ar,t.Title_Ar TypeName
 FROM dbo.Employee_Feedback_Requests r JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type WHERE r.ID=@ID;
END;
GO

-- Extends request history without changing the existing procedure signature.
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Access_Requests
    @Actor_ID int, @Status char(1)=NULL, @Brand_ID int=NULL, @Keyword nvarchar(200)=NULL,
    @Batch_ID uniqueidentifier=NULL, @PageNumber int=1, @PageSize int=50, @All_Rows bit=0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Type int;
    SELECT @Type=[Type] FROM dbo.UsersMembers WHERE ID=@Actor_ID AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0;
    IF @Type IS NULL OR @Type NOT IN(1,7) THROW 51100,N'غير مخوّل بعرض الطلبات.',1;
    IF @All_Rows=1 AND @Type<>1 THROW 51100,N'غير مخوّل بعرض جميع الطلبات.',1;
    SET @Keyword=NULLIF(LTRIM(RTRIM(@Keyword)),N'');
    IF @PageNumber IS NULL OR @PageNumber<1 SET @PageNumber=1;
    IF @PageSize IS NULL OR @PageSize<1 OR @PageSize>200 SET @PageSize=50;
    SELECT q.ID,q.Batch_ID,q.User_ID,q.Brand_ID,q.Category_ID,q.Reason,q.Status,q.Assigned_Role_ID,q.AddedDate,q.ReviewedBy,q.ReviewedDate,q.ReviewNote,
           COALESCE(a.Name_AR,u.FullName_Ar) AS User_Name,b.Title_Ar AS Brand_Name,COALESCE(q.Category_Path,c.Title_Ar) AS Category_Name,r.Title_Ar AS Role_Name,
           COUNT(*) OVER() AS TotalRows
    FROM dbo.Work_Guide_Access_Requests q
    LEFT JOIN dbo.UsersMembers u ON u.ID=q.User_ID
    LEFT JOIN dbo.CRM_Accounts a ON a.ID=q.Customer_ID
    JOIN dbo.Brands b ON b.ID=q.Brand_ID
    JOIN dbo.Work_Guide_Categories c ON c.ID=q.Category_ID
    LEFT JOIN dbo.Work_Guide_Roles r ON r.ID=q.Assigned_Role_ID
    WHERE (@Type=1 OR q.User_ID=@Actor_ID)
      AND (@Status IS NULL OR q.Status=@Status OR (@Status='H' AND q.Status IN('A','R')))
      AND (@Brand_ID IS NULL OR q.Brand_ID=@Brand_ID) AND (@Batch_ID IS NULL OR q.Batch_ID=@Batch_ID)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword,COALESCE(a.Name_AR,u.FullName_Ar,N''))>0 OR CHARINDEX(@Keyword,ISNULL(c.Title_Ar,N''))>0)
    ORDER BY q.AddedDate DESC,q.ID DESC OFFSET (CASE WHEN @All_Rows=1 THEN CONVERT(bigint,0) ELSE (CONVERT(bigint,@PageNumber)-1)*@PageSize END) ROWS FETCH NEXT (CASE WHEN @All_Rows=1 THEN 2147483647 ELSE @PageSize END) ROWS ONLY;
END;

GO
CREATE OR ALTER PROCEDURE dbo.Review_Work_Guide_Access_Request
    @Admin_ID int, @Batch_ID uniqueidentifier, @Decisions xml
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    DECLARE @Items TABLE(ID int PRIMARY KEY,Decision char(1),Role_ID int NULL,Note nvarchar(1000));
    INSERT @Items SELECT n.value('@id','int'),n.value('@status','char(1)'),NULLIF(n.value('@role','int'),0),NULLIF(LTRIM(RTRIM(n.value('@note','nvarchar(1000)'))),N'') FROM @Decisions.nodes('/items/item') x(n);
    IF (SELECT COUNT(*) FROM @Items) NOT BETWEEN 1 AND 200 OR EXISTS(SELECT 1 FROM @Items WHERE Decision IS NULL OR Decision NOT IN('A','R') OR (Decision='A' AND Role_ID IS NULL) OR (Decision='R' AND Note IS NULL))
        THROW 51105,N'حدد دورًا لكل موافقة وسببًا لكل رفض.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH (HOLDLOCK) WHERE ID=@Admin_ID AND [Type]=1 AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0)
            THROW 51100,N'غير مخوّل بمراجعة الطلبات.',1;
        DECLARE @Locked TABLE(ID int PRIMARY KEY,Customer_ID int,User_ID int,Brand_ID int,Category_ID int,Status char(1));
        INSERT @Locked SELECT q.ID,q.Customer_ID,q.User_ID,q.Brand_ID,q.Category_ID,q.Status FROM dbo.Work_Guide_Access_Requests q WITH(UPDLOCK,HOLDLOCK) JOIN @Items i ON i.ID=q.ID WHERE q.Batch_ID=@Batch_ID;
        IF (SELECT COUNT(*) FROM @Locked)<>(SELECT COUNT(*) FROM @Items) OR EXISTS(SELECT 1 FROM @Locked WHERE Status<>'P')
            THROW 51106,N'تغيّرت حالة أحد الطلبات أو لا ينتمي لهذه المجموعة. حدّث الصفحة.',1;
        IF EXISTS(SELECT 1 FROM @Locked q JOIN @Items i ON i.ID=q.ID LEFT JOIN dbo.UsersMembers u ON u.ID=q.User_ID AND u.Brand_ID=q.Brand_ID AND u.[Type]=7 AND ISNULL(u.IsActive,0)=1 AND ISNULL(u.IsDeleted,0)=0 LEFT JOIN dbo.CRM_Accounts a ON a.ID=q.Customer_ID AND a.Is_Active=1 AND a.Is_Deleted=0 LEFT JOIN dbo.Customer_Logins l ON l.AccountID=a.ID AND l.IsActive=1 WHERE i.Decision='A' AND u.ID IS NULL AND l.AccountID IS NULL)
            THROW 51107,N'الحساب غير فعال أو تغيّرت علامته التجارية؛ لا يمكن منح الصلاحية.',1;
        IF EXISTS(SELECT 1 FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Effective_Categories(q.User_ID,q.Brand_ID) c WHERE c.ID=q.Category_ID) AND NOT EXISTS(SELECT 1 FROM dbo.Customer_Guide_Effective(q.Customer_ID,q.Brand_ID)c WHERE c.ID=q.Category_ID))
            THROW 51108,N'أحد التصنيفات غير فعال أو لم يعد ضمن العلامة التجارية.',1;
        IF EXISTS(SELECT 1 FROM @Items i WHERE i.Decision='A' AND NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Roles r WITH(HOLDLOCK) JOIN dbo.Work_Guide_Role_Permissions p WITH(HOLDLOCK) ON p.Role_ID=r.ID WHERE r.ID=i.Role_ID AND ISNULL(r.IsDeleted,0)=0 AND ISNULL(r.IsActive,1)=1 AND p.Can_View_Document=1 AND p.ID=(SELECT MAX(p2.ID) FROM dbo.Work_Guide_Role_Permissions p2 WHERE p2.Role_ID=r.ID)))
            THROW 51109,N'اختر دورًا فعالًا يسمح بعرض الوثائق.',1;
        -- Replace the direct grant for each approved category. Ancestors and siblings are unchanged.
        UPDATE g SET IsActive=0,ModifyUser=@Admin_ID,ModifyDate=GETDATE()
        FROM dbo.Work_Guide_User_Category_Roles g WITH(UPDLOCK,HOLDLOCK)
        JOIN @Locked q ON q.User_ID=g.User_ID AND q.Brand_ID=g.Brand_ID AND q.Category_ID=g.Category_ID
        JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND ISNULL(g.IsDeleted,0)=0;
        INSERT dbo.Work_Guide_User_Category_Roles(User_ID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,AddedUser,AddedDate,IsDeleted,IsActive)
        SELECT q.User_ID,q.Brand_ID,q.Category_ID,i.Role_ID,0,@Admin_ID,GETDATE(),0,1 FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND q.User_ID IS NOT NULL;
        UPDATE g SET Role_ID=i.Role_ID,IsActive=1,Apply_To_Children=0,Start_Date=NULL,End_Date=NULL,ModifiedBy=@Admin_ID FROM dbo.Customer_Guide_Grants g WITH(UPDLOCK,HOLDLOCK) JOIN @Locked q ON q.Customer_ID=g.AccountID AND q.Category_ID=g.Category_ID JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A';
        INSERT dbo.Customer_Guide_Grants(AccountID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,IsActive,ModifiedBy) SELECT q.Customer_ID,q.Brand_ID,q.Category_ID,i.Role_ID,0,1,@Admin_ID FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND q.Customer_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Customer_Guide_Grants WHERE AccountID=q.Customer_ID AND Category_ID=q.Category_ID);
        INSERT dbo.Customer_Portal_Activity(AccountID,ActorID,Action,Note) SELECT q.Customer_ID,@Admin_ID,'access-review',CONCAT(N'طلب ',q.ID,N': ',CASE i.Decision WHEN 'A' THEN N'موافقة' ELSE N'رفض' END,N'، ',i.Note) FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE q.Customer_ID IS NOT NULL;
        UPDATE q SET Status=i.Decision,Assigned_Role_ID=CASE WHEN i.Decision='A' THEN i.Role_ID END,ReviewedBy=@Admin_ID,ReviewedDate=GETDATE(),ReviewNote=i.Note
        FROM dbo.Work_Guide_Access_Requests q JOIN @Items i ON i.ID=q.ID;
        INSERT dbo.Work_Guide_Activity_Logs(User_ID,Brand_ID,Category_ID,Action_Type,Action_Details,AddedDate)
        SELECT @Admin_ID,q.Brand_ID,q.Category_ID,N'AccessRequestReview',CONCAT(N'Request ',q.ID,N': ',i.Decision,N'; role ',i.Role_ID,N'; ',i.Note),GETDATE()
        FROM @Locked q JOIN @Items i ON i.ID=q.ID;
        COMMIT;
        SELECT COUNT(*) AS Reviewed_Count FROM @Items;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SubmitFeedback @AccountID int,@Stamp uniqueidentifier,@OperationID uniqueidentifier,@Type int,@Topic int,@Brand int,@Branch int,@Mobile nvarchar(30),@Title nvarchar(300),@Details nvarchar(max),@Files xml AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @OperationID IS NULL THROW 51910,N'رقم الطلب مطلوب.',1;
 BEGIN TRAN;
 DECLARE @ID int,@Name nvarchar(200),@Email nvarchar(254),@Lock int;
 DECLARE @Key nvarchar(255)=CONCAT('customer-feedback:',@AccountID,':',@OperationID);
 EXEC @Lock=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 BEGIN ROLLBACK;THROW 51910,N'الطلب قيد المعالجة؛ أعد المحاولة.',1;END;
 SELECT @ID=RequestID FROM dbo.Customer_Portal_Feedback WHERE AccountID=@AccountID AND OperationID=@OperationID;
 IF @ID IS NOT NULL BEGIN COMMIT;SELECT @ID ID,CAST(1 AS bit) Replay;RETURN;END;
 SELECT @Name=Name_AR,@Email=Email FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 EXEC dbo.Insert_Customer_Feedback_Request @Type=@Type,@Topic=@Topic,@Brand=@Brand,@Branch=@Branch,@Name=@Name,@Mobile=@Mobile,@Email=@Email,@Title=@Title,@Details=@Details,@Disclose=1,@Files=@Files,@CreatedID=@ID OUTPUT,@ReturnResult=0;
 INSERT dbo.Customer_Portal_Feedback(RequestID,AccountID,OperationID) VALUES(@ID,@AccountID,@OperationID);
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Note,FeedbackTypeTitle) SELECT @AccountID,'feedback',CONCAT(N'تم تقديم ',Title_Ar,N' رقم ',@ID),Title_Ar FROM dbo.Employee_Feedback_Types WHERE ID=@Type;
 COMMIT; SELECT @ID ID,CAST(0 AS bit) Replay;
END;
GO

CREATE OR ALTER PROCEDURE dbo.Customer_AdminData @Actor int,@AccountID int,@Section varchar(20)='login',@Brand int=0 AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.Customer_AdminCheck @Actor;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Is_Deleted=0) THROW 51910,N'العميل غير متاح.',1;
 IF @Section='login' SELECT a.Name_AR,l.AccountID,l.Username,l.IsActive,l.LastLoginUtc,l.Version FROM dbo.CRM_Accounts a LEFT JOIN dbo.Customer_Logins l ON l.AccountID=a.ID WHERE a.ID=@AccountID;
 IF @Section='grants' SELECT g.*,b.Title_Ar BrandName,c.Title_Ar CategoryName,r.Title_Ar RoleName FROM dbo.Customer_Guide_Grants g JOIN dbo.Brands b ON b.ID=g.Brand_ID JOIN dbo.Work_Guide_Categories c ON c.ID=g.Category_ID JOIN dbo.Work_Guide_Roles r ON r.ID=g.Role_ID WHERE AccountID=@AccountID ORDER BY b.ID,c.ID;
 IF @Section='brands' SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='categories' SELECT ID,Title_Ar Title FROM dbo.Work_Guide_Categories WHERE Brand_ID=@Brand AND ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='roles' SELECT ID,Title_Ar Title FROM dbo.Work_Guide_Roles WHERE ISNULL(IsActive,1)=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='activity' SELECT TOP(100) x.CreatedUtc,CASE x.Action WHEN 'credentials' THEN N'بيانات الدخول' WHEN 'grant' THEN N'صلاحيات الدليل' WHEN 'login' THEN N'تسجيل الدخول' WHEN 'view' THEN N'عرض دليل' WHEN 'download' THEN N'تنزيل دليل' WHEN 'feedback' THEN CONCAT(N'تقديم ',COALESCE(x.FeedbackTypeTitle,N'طلب')) WHEN 'access-request' THEN N'طلب صلاحية دليل العمل' WHEN 'access-review' THEN N'مراجعة طلب صلاحية' ELSE x.Action END Action,x.Note,x.DocumentID,u.FullName_Ar ActorName FROM dbo.Customer_Portal_Activity x LEFT JOIN dbo.UsersMembers u ON u.ID=x.ActorID WHERE x.AccountID=@AccountID ORDER BY x.ID DESC;
END;
GO
UPDATE x SET FeedbackTypeTitle=t.Title_Ar,Note=CONCAT(N'تم تقديم ',t.Title_Ar,N' رقم ',r.ID)
FROM dbo.Customer_Portal_Activity x JOIN dbo.Customer_Portal_Feedback f ON f.AccountID=x.AccountID AND x.Note=CONCAT(N'طلب رقم ',f.RequestID) JOIN dbo.Employee_Feedback_Requests r ON r.ID=f.RequestID JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type WHERE x.Action='feedback' AND x.FeedbackTypeTitle IS NULL;
GO
