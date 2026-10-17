CREATE OR ALTER PROCEDURE dbo.Customer_Guide @AccountID int,@Stamp uniqueidentifier,@Brand int=0,@Section varchar(16)='documents',@Search nvarchar(200)=N'',@DocumentID int=0 AS
BEGIN
 SET NOCOUNT ON;
 -- Session validation without adding a result set to the consumer contract.
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID WHERE a.ID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0) THROW 51911,N'انتهت صلاحية الدخول.',1;
 IF @Section='brands'
 SELECT DISTINCT b.ID,b.Title_Ar Title FROM dbo.Brands b CROSS APPLY dbo.Customer_Guide_Effective(@AccountID,b.ID) c WHERE c.Can_View_Category=1 OR c.Can_View_Document=1 OPTION(MAXRECURSION 100);
 IF @Section='documents'
 SELECT d.ID,d.Title_Ar,d.Description_Ar,d.AddedDate,c.Full_Path_Ar CategoryName,c.Can_Print_Document,
 CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) Can_Download_Document
 FROM dbo.Work_Guide_Documents d JOIN dbo.Customer_Guide_Effective(@AccountID,@Brand) c ON c.ID=d.Category_ID
 WHERE d.Brand_ID=@Brand AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1
 AND (@Search=N'' OR CHARINDEX(@Search,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Search,c.Full_Path_Ar)>0)
 ORDER BY d.AddedDate DESC,d.ID DESC OPTION(MAXRECURSION 100);
 IF @Section='file'
 SELECT d.ID,d.Title_Ar,d.File_Path,d.Brand_ID,d.Category_ID,c.Can_View_Document,c.Can_Print_Document,
 CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) Can_Download_Document
 FROM dbo.Work_Guide_Documents d CROSS APPLY dbo.Customer_Guide_Effective(@AccountID,d.Brand_ID) c
 WHERE d.ID=@DocumentID AND c.ID=d.Category_ID AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1 OPTION(MAXRECURSION 100);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_LogDocument @AccountID int,@Stamp uniqueidentifier,@DocumentID int,@Action varchar(30) AS
BEGIN
 SET NOCOUNT ON;
 IF @Action NOT IN('view','download') OR NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins WHERE AccountID=@AccountID AND SecurityStamp=@Stamp AND IsActive=1) THROW 51911,N'غير مسموح.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Documents d CROSS APPLY dbo.Customer_Guide_Effective(@AccountID,d.Brand_ID)c WHERE d.ID=@DocumentID AND c.ID=d.Category_ID AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1 AND (@Action='view' OR (c.Can_Download_Document=1 AND ISNULL(d.Is_Download_Allowed,1)=1))) THROW 51910,N'الملف غير متاح لك.',1;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,DocumentID) VALUES(@AccountID,@Action,@DocumentID);
END;
GO
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
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Note) VALUES(@AccountID,'feedback',CONCAT(N'طلب رقم ',@ID));
 COMMIT; SELECT @ID ID,CAST(0 AS bit) Replay;
END;
GO
