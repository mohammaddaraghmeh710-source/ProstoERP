-- Authenticated customers submit only for their explicitly linked active branches.
-- Public customer intake and employee identities retain their existing contracts.
SET XACT_ABORT ON;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_FeedbackOptions @AccountID int,@Stamp uniqueidentifier,@Section varchar(16),@Brand int=0,@Type int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Section='types' SELECT ID,Title_Ar Title FROM dbo.Employee_Feedback_Types WHERE IsActive=1 AND IsDeleted=0 ORDER BY Item_Order,ID;
 IF @Section='brands' SELECT b.ID,b.Title_Ar Title FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID WHERE ab.Account_ID=@AccountID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 ORDER BY b.Title_Ar,b.ID;
 IF @Section IN('branches','allbranches') SELECT br.ID,br.Title_Ar Title,br.BrandID FROM dbo.CRM_Account_Branches x JOIN dbo.CRM_Account_Brands ab ON ab.Account_ID=x.Account_ID AND ab.Brand_ID=x.Brand_ID JOIN dbo.Branches br ON br.ID=x.Branch_ID AND br.BrandID=x.Brand_ID JOIN dbo.Brands b ON b.ID=br.BrandID WHERE x.Account_ID=@AccountID AND br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 AND (@Section='allbranches' OR br.BrandID=@Brand) ORDER BY br.Title_Ar,br.ID;
 IF @Section IN('topics','alltopics') SELECT t.ID,t.Title_Ar Title,t.Brand_ID BrandID,t.Type TypeID FROM dbo.Employee_Feedback_Topics t JOIN dbo.Employee_Feedback_Types k ON k.ID=t.Type AND k.IsActive=1 AND k.IsDeleted=0 JOIN dbo.CRM_Account_Brands ab ON ab.Brand_ID=t.Brand_ID AND ab.Account_ID=@AccountID JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE t.IsActive=1 AND t.IsDeleted=0 AND (@Section='alltopics' OR (t.Brand_ID=@Brand AND t.Type=@Type)) ORDER BY t.Item_Order,t.ID;
 IF @Section='recipients' SELECT u.ID,u.FullName_Ar Title FROM dbo.UsersMembers u JOIN dbo.Users_Types t ON t.ID=u.Type WHERE u.Type=1 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND t.IsActive=1 AND ISNULL(t.IsDeleted,0)=0 ORDER BY u.FullName_Ar,u.ID;
 IF @Section='history' SELECT r.ID,r.Title,r.Status,r.Type,r.Brand_ID,r.Branch_ID,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,r.Branch_Title_Ar,t.Title_Ar TypeName FROM dbo.Customer_Portal_Feedback c JOIN dbo.Employee_Feedback_Requests r ON r.ID=c.RequestID JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type WHERE c.AccountID=@AccountID ORDER BY r.ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SubmitFeedback @AccountID int,@Stamp uniqueidentifier,@OperationID uniqueidentifier,@Type int,@Topic int,@Brand int,@Branch int,@Mobile nvarchar(30),@Title nvarchar(300),@Details nvarchar(max),@Files xml AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 IF @OperationID IS NULL THROW 51910,N'رقم الطلب مطلوب.',1;
 BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l WITH(HOLDLOCK) JOIN dbo.CRM_Accounts a WITH(HOLDLOCK) ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 DECLARE @ID int,@Name nvarchar(200),@Email nvarchar(254),@Lock int,@Group uniqueidentifier;
 DECLARE @Key nvarchar(255)=CONCAT('customer-feedback:',@AccountID,':',@OperationID);
 EXEC @Lock=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51910,N'الطلب قيد المعالجة؛ أعد المحاولة.',1;
 SELECT @ID=RequestID FROM dbo.Customer_Portal_Feedback WHERE AccountID=@AccountID AND OperationID=@OperationID;
 IF @ID IS NOT NULL BEGIN COMMIT;SELECT @ID ID,CAST(1 AS bit) Replay;RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WITH(HOLDLOCK) JOIN dbo.CRM_Account_Branches x WITH(HOLDLOCK) ON x.Account_ID=ab.Account_ID AND x.Brand_ID=ab.Brand_ID JOIN dbo.Brands b WITH(HOLDLOCK) ON b.ID=ab.Brand_ID JOIN dbo.Branches br WITH(HOLDLOCK) ON br.ID=x.Branch_ID AND br.BrandID=x.Brand_ID WHERE ab.Account_ID=@AccountID AND ab.Brand_ID=@Brand AND x.Branch_ID=@Branch AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 AND br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0) THROW 51910,N'اختر فرعًا فعالًا مرتبطًا بحسابك ضمن العلامة التجارية المحددة. إذا لم يظهر فرع، تواصل مع إدارة النظام لربطه بحسابك.',1;
 SELECT @Name=Name_AR,@Email=Email FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 EXEC dbo.Insert_Customer_Feedback_Request @Type=@Type,@Topic=@Topic,@Brand=@Brand,@Branch=@Branch,@Name=@Name,@Mobile=@Mobile,@Email=@Email,@Title=@Title,@Details=@Details,@Disclose=1,@Files=@Files,@CreatedID=@ID OUTPUT,@ReturnResult=0;
 INSERT dbo.Customer_Portal_Feedback(RequestID,AccountID,OperationID) VALUES(@ID,@AccountID,@OperationID);
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Note,FeedbackTypeTitle) SELECT @AccountID,'feedback',CONCAT(N'تم تقديم ',Title_Ar,N' رقم ',@ID),Title_Ar FROM dbo.Employee_Feedback_Types WHERE ID=@Type;
 SELECT TOP(1) @Group=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC;
 IF OBJECT_ID('dbo.Feedback_PublishNotifications','P') IS NOT NULL EXEC dbo.Feedback_PublishNotifications @RequestID=@ID,@GroupID=@Group;
 COMMIT;SELECT @ID ID,CAST(0 AS bit) Replay;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_FeedbackDetail @AccountID int,@Stamp uniqueidentifier,@ID int=0,@AttachmentID int=0,@Section varchar(16)='detail' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @AttachmentID>0 BEGIN SELECT f.ID,f.FileName,f.File_Type,f.FileSize FROM dbo.Employee_Feedback_Attachments f JOIN dbo.Customer_Portal_Feedback c ON c.RequestID=f.Request_ID WHERE c.AccountID=@AccountID AND f.ID=@AttachmentID;RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Portal_Feedback WHERE AccountID=@AccountID AND RequestID=@ID) THROW 51912,N'الطلب غير متاح.',1;
 IF @Section='attachments' BEGIN SELECT ID,File_Type,FileSize FROM dbo.Employee_Feedback_Attachments WHERE Request_ID=@ID AND Workflow_ID IS NULL ORDER BY ID;RETURN;END;
 IF @Section='actionfiles' BEGIN SELECT f.ID,f.File_Type,f.FileSize,w.GroupID FROM dbo.Employee_Feedback_Attachments f JOIN dbo.Employee_Feedback_Workflow w ON w.ID=f.Workflow_ID AND w.Request_ID=f.Request_ID WHERE f.Request_ID=@ID ORDER BY f.ID;RETURN;END;
 IF @Section='workflow' BEGIN
  SELECT w.GroupID,w.ActionType,MIN(w.AddedDate) AddedDate,MAX(w.Comment) Comment,
  MAX(CASE WHEN w.SenderID IS NULL THEN r.ApplicantName ELSE u.FullName_Ar END) SenderName,
  STRING_AGG(CONVERT(nvarchar(max),CASE WHEN w.ReceiverID IS NULL THEN r.ApplicantName ELSE v.FullName_Ar END),N'، ') ReceiverNames
  FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID LEFT JOIN dbo.UsersMembers u ON u.ID=w.SenderID LEFT JOIN dbo.UsersMembers v ON v.ID=w.ReceiverID WHERE w.Request_ID=@ID GROUP BY w.GroupID,w.ActionType ORDER BY MIN(w.ID);RETURN;
 END;
 IF OBJECT_ID('dbo.Customer_Feedback_NoticeRead','P') IS NOT NULL EXEC dbo.Customer_Feedback_NoticeRead @AccountID=@AccountID,@Stamp=@Stamp,@RequestID=@ID;
 SELECT r.ID,r.Title,r.Details,r.Status,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,r.Branch_Title_Ar,r.Topic_Title_Ar,t.Title_Ar TypeName,r.ApplicantName,r.ApplicantMobile,r.ApplicantEmail FROM dbo.Employee_Feedback_Requests r JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type WHERE r.ID=@ID;
END;
GO
