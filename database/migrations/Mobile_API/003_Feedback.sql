-- Additive mobile adapter. Shared feedback procedures remain the source of business rules.
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Employee_Feedback_RequestTargets') IS NULL
 THROW 51800,'Apply Employee_Feedback migrations through 007 first.',1;
IF OBJECT_ID('dbo.MobileApi_FeedbackEvents','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileApi_FeedbackEvents(
  ActorID int NOT NULL REFERENCES dbo.UsersMembers(ID),
  OperationID uniqueidentifier NOT NULL,
  PayloadHash binary(32) NOT NULL,
  RequestID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),
  EventType varchar(10) NOT NULL CHECK(EventType IN('submit','open','transfer','close')),
  OccurredAt datetimeoffset(3) NOT NULL,
  ReceivedUtc datetime2(3) NOT NULL,
  WorkflowGroupID uniqueidentifier NULL,
  ViewID bigint NULL REFERENCES dbo.Employee_Feedback_Views(ID),
  PRIMARY KEY(ActorID,OperationID)
 );
 CREATE INDEX IX_MobileFeedbackEvents_Request ON dbo.MobileApi_FeedbackEvents(RequestID,ReceivedUtc);
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_FeedbackActor @Actor int,@EmployeeNumber int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Employee_Number=@EmployeeNumber
 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51801,N'الرقم الوظيفي لا يطابق الحساب المسجل.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_FeedbackRequests
 @Actor int,@Search nvarchar(300)=N'',@Type int=0,@Status int=0,@Scope varchar(12)='all',@Page int=1,@PageSize int=20
AS
BEGIN
 SET NOCOUNT ON;
 CREATE TABLE #Rows(ID int,Type int,Title nvarchar(300),Status int,AddedDate datetime,CloseDate datetime,
 SourceType int,EmployeeName nvarchar(max),BranchName nvarchar(max),BrandName nvarchar(max),CurrentRecipient nvarchar(50),UnreadCount int);
 -- These projections and permissions are shared with the portal.
 INSERT #Rows EXEC dbo.Select_Employee_Feedback_Requests @Actor=@Actor,@Mode=0,@Search=@Search,@Type=@Type,@Status=@Status;
 INSERT #Rows EXEC dbo.Select_Employee_Feedback_Requests @Actor=@Actor,@Mode=1,@Search=@Search,@Type=@Type,@Status=@Status;
 SELECT DISTINCT * INTO #All FROM #Rows;
 TRUNCATE TABLE #Rows;
 INSERT #Rows EXEC dbo.Select_Employee_Feedback_Requests @Actor=@Actor,@Mode=3,@Search=@Search,@Type=@Type,@Status=@Status;
 SELECT a.*,CONVERT(bit,CASE WHEN r.EmployeeID=@Actor THEN 1 ELSE 0 END) IsMine,
 CONVERT(bit,CASE WHEN x.ID IS NOT NULL THEN 1 ELSE 0 END) CanAct,t.Title_Ar TypeName,t.Title_En TypeNameEn
 INTO #Result FROM #All a JOIN dbo.Employee_Feedback_Requests r ON r.ID=a.ID
 JOIN dbo.Employee_Feedback_Types t ON t.ID=a.Type LEFT JOIN #Rows x ON x.ID=a.ID;
 SELECT COUNT(*) TotalRequests,COALESCE(SUM(CONVERT(int,IsMine)),0) SentRequests,
 COALESCE(SUM(CASE WHEN Status<>3 THEN 1 ELSE 0 END),0) ActiveRequests,
 COALESCE(SUM(CASE WHEN Status=3 THEN 1 ELSE 0 END),0) ClosedRequests,
 COALESCE(SUM(CONVERT(int,CanAct)),0) ActionRequiredRequests FROM #Result;
 SELECT * INTO #Filtered FROM #Result WHERE @Scope='all' OR (@Scope='sent' AND IsMine=1)
 OR (@Scope='action' AND CanAct=1) OR (@Scope='active' AND Status<>3) OR (@Scope='closed' AND Status=3);
 SELECT COUNT(*) TotalItems FROM #Filtered;
 SELECT * FROM #Filtered ORDER BY CASE WHEN CanAct=1 THEN 0 WHEN Status<>3 THEN 1 ELSE 2 END,AddedDate DESC,ID DESC
 OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
