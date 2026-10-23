
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
 INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,NotificationType,SendDate) SELECT ID,@ID,1,@Now FROM @Targets;
 COMMIT; IF @ReturnResult=1 SELECT @ID ID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;

GO
