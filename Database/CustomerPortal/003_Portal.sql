CREATE OR ALTER PROCEDURE dbo.Customer_FeedbackOptions @AccountID int,@Stamp uniqueidentifier,@Section varchar(16),@Brand int=0,@Type int=0 AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Section='types' SELECT ID,Title_Ar Title FROM dbo.Employee_Feedback_Types WHERE IsActive=1 AND IsDeleted=0 ORDER BY Item_Order,ID;
 IF @Section='brands' SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='branches' SELECT ID,Title_Ar Title FROM dbo.Branches WHERE BrandID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar;
 IF @Section='topics' SELECT ID,Title_Ar Title FROM dbo.Employee_Feedback_Topics WHERE Brand_ID=@Brand AND Type=@Type AND IsActive=1 AND IsDeleted=0 ORDER BY Item_Order,ID;
 IF @Section='history' SELECT r.ID,r.Title,r.Status,r.AddedDate,r.CloseDate,r.Brand_Title_Ar,t.Title_Ar TypeName
 FROM dbo.Customer_Portal_Feedback c JOIN dbo.Employee_Feedback_Requests r ON r.ID=c.RequestID JOIN dbo.Employee_Feedback_Types t ON t.ID=r.Type WHERE c.AccountID=@AccountID ORDER BY r.ID DESC;
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
