-- Apply after 007_Catalogs and Mobile_API/006_DeviceAccess. Additive API adapter.
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Correspondence_Catalog','U') IS NULL THROW 51400,'Apply correspondence 007 first.',1;
IF OBJECT_ID('dbo.MobileApi_CorrespondenceEvents','U') IS NULL
 CREATE TABLE dbo.MobileApi_CorrespondenceEvents(
  ActorID int NOT NULL REFERENCES dbo.UsersMembers(ID),OperationID uniqueidentifier NOT NULL,
  PayloadHash binary(32) NOT NULL,Action varchar(20) NOT NULL,ResultJson nvarchar(max) NOT NULL,
  OccurredAt datetimeoffset(3) NOT NULL,ReceivedUtc datetime2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  PRIMARY KEY(ActorID,OperationID));
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_CorrespondenceActor @Actor int,@EmployeeNumber int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Employee_Number=@EmployeeNumber AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
 THROW 51801,N'الرقم الوظيفي لا يطابق الحساب المسجل.',1;
 SELECT ID UserID,Type UserType FROM dbo.UsersMembers WHERE ID=@Actor;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_CorrespondenceMessages
 @Actor int,@ThreadID int,@AfterID int=0,@BeforeID int=0,@PageSize int=30
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 IF @PageSize NOT BETWEEN 1 AND 100 OR @AfterID<0 OR @BeforeID<0 OR (@AfterID>0 AND @BeforeID>0) THROW 51400,N'خيارات التصفح غير صحيحة.',1;
 SELECT TOP(@PageSize+1) m.ID INTO #MessageIDs FROM dbo.Correspondence_Thread_Messages m
 WHERE m.ThreadID=@ThreadID AND (@AfterID=0 OR m.ID>@AfterID) AND (@BeforeID=0 OR m.ID<@BeforeID)
 ORDER BY CASE WHEN @AfterID>0 THEN m.ID END ASC,CASE WHEN @AfterID=0 THEN m.ID END DESC;
 SELECT CAST(CASE WHEN COUNT(*)>@PageSize THEN 1 ELSE 0 END AS bit) HasMore FROM #MessageIDs;
 IF (SELECT COUNT(*) FROM #MessageIDs)>@PageSize
 DELETE #MessageIDs WHERE ID=(SELECT CASE WHEN @AfterID>0 THEN MAX(ID) ELSE MIN(ID) END FROM #MessageIDs);
 SELECT m.ID,m.ThreadID,m.SenderID,m.ReceivedID,m.Body,m.CreatedDate,ISNULL(m.IsRead,0) IsRead,m.ReadDate,
 COALESCE(p.FullName,u.FullName_Ar) SenderName
 FROM #MessageIDs i JOIN dbo.Correspondence_Thread_Messages m ON m.ID=i.ID
 LEFT JOIN dbo.UsersMembers u ON u.ID=m.SenderID LEFT JOIN dbo.Correspondence_Parties p ON p.ThreadID=m.ThreadID AND p.UserID=m.SenderID ORDER BY m.ID;
 SELECT a.ID,a.MessageID,a.FileName,a.File_Type,a.FileSize FROM dbo.Correspondence_Message_Attachments a JOIN #MessageIDs i ON i.ID=a.MessageID ORDER BY a.ID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.MobileApi_CorrespondenceList
 @Actor int,@All bit=0,@Person nvarchar(200)=NULL,@Title nvarchar(200)=NULL,@Filter varchar(16)='all',
 @Brand int=0,@Branch int=0,@Sender nvarchar(200)=NULL,@Receiver nvarchar(200)=NULL,
 @From datetime=NULL,@To datetime=NULL,@Kind int=0,@Priority int=0,@Page int=1,@PageSize int=20
AS
BEGIN
 SET NOCOUNT ON;
 IF @Page NOT BETWEEN 1 AND 100000 OR @PageSize NOT BETWEEN 1 AND 100 THROW 51400,N'Invalid pagination.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@All=0 OR Type=1))
  THROW 51400,N'غير مسموح بالاطلاع على المراسلات.',1;
 SELECT o.ID,o.PriorityRank,o.LastMessageDate INTO #Matches
 FROM dbo.Correspondence_Overview o JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=o.ID
 WHERE (@All=1 OR a.IsParticipant=1)
 AND (NULLIF(@Person,'') IS NULL OR o.SenderName LIKE N'%'+@Person+N'%' OR o.ReceiverName LIKE N'%'+@Person+N'%')
 AND (NULLIF(@Title,'') IS NULL OR o.Title LIKE N'%'+@Title+N'%')
 AND (NULLIF(@Sender,'') IS NULL OR o.SenderName LIKE N'%'+@Sender+N'%')
 AND (NULLIF(@Receiver,'') IS NULL OR o.ReceiverName LIKE N'%'+@Receiver+N'%')
 AND (@Brand=0 OR o.SenderBrandID=@Brand OR o.ReceiverBrandID=@Brand)
 AND (@Branch=0 OR o.SenderBranchID=@Branch OR o.ReceiverBranchID=@Branch)
 AND (@From IS NULL OR o.CreatedDate>=@From) AND (@To IS NULL OR o.CreatedDate<@To)
 AND (@Kind=0 OR (@Kind=1 AND ISNULL(o.RequiresCompletion,0)=0) OR (@Kind=2 AND o.RequiresCompletion=1))
 AND (@Priority=0 OR o.Priority=@Priority)
 AND (@Filter='all' OR @Filter=o.State
  OR (@Filter='noReply' AND o.FirstReplyDate IS NULL AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL)
  OR (@Filter='followup' AND o.InactiveParty=1 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL)
  OR (@Filter='legacy' AND o.LegacyOrganization=1)
  OR (@Filter='unread' AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=o.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0)))
 OPTION(RECOMPILE, LOOP JOIN);
 SELECT COUNT(*) TotalItems FROM #Matches;
 SELECT COUNT(*) TotalThreads,COALESCE(SUM(CASE WHEN o.CloseDate IS NULL AND o.ArchivedAt IS NULL AND o.FirstReplyDate IS NULL THEN 1 ELSE 0 END),0) NoReply,
 COALESCE(SUM(CASE WHEN o.State='overdue' AND o.RequiresCompletion=1 THEN 1 ELSE 0 END),0) OverdueTasks,
 COALESCE(SUM(CASE WHEN o.InactiveParty=1 AND o.CloseDate IS NULL AND o.ArchivedAt IS NULL THEN 1 ELSE 0 END),0) FollowUp,
 COALESCE(SUM(CASE WHEN o.IsCompleted=1 THEN 1 ELSE 0 END),0) Completed,
 COALESCE(SUM(CASE WHEN o.IsCompleted=0 AND o.CloseDate IS NOT NULL THEN 1 ELSE 0 END),0) NotCompleted,
 COALESCE(SUM(CASE WHEN o.ArchivedAt IS NOT NULL THEN 1 ELSE 0 END),0) Archived
 FROM #Matches m JOIN dbo.Correspondence_Overview o ON o.ID=m.ID;
 SELECT ID INTO #Page FROM #Matches ORDER BY PriorityRank DESC,LastMessageDate DESC,ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
 SELECT o.*,a.IsParticipant,a.IsAdmin,
 CASE WHEN @All=1 THEN o.SenderName+N' ← '+o.ReceiverName WHEN o.SenderID=@Actor THEN o.ReceiverName ELSE o.SenderName END OtherName,
 CASE WHEN o.SenderID=@Actor THEN o.ReceiverImage ELSE o.SenderImage END OtherImage,
 (SELECT COUNT(*) FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=o.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0) UnreadCount

 FROM #Page p JOIN dbo.Correspondence_Overview o ON o.ID=p.ID JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=o.ID
 ORDER BY o.PriorityRank DESC,o.LastMessageDate DESC,o.ID DESC;
END;

GO
