CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Threads_Search
 @Actor int,@Person nvarchar(200)=NULL,@Title nvarchar(200)=NULL,@Filter varchar(10)='all'
AS
BEGIN
 SET NOCOUNT ON;

 -- Filter narrow keys first. Do not spool or sort all message bodies,
 -- summaries and image paths for COUNT(*) OVER().
 CREATE TABLE #Matches(ID int NOT NULL PRIMARY KEY,LastMessageDate datetime NULL);
 INSERT #Matches(ID,LastMessageDate)
 SELECT t.ID,ISNULL((SELECT MAX(m.CreatedDate) FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID),t.CreatedDate)
 FROM dbo.Correspondence_Threads t
 JOIN dbo.UsersMembers actor ON actor.ID=@Actor AND actor.IsActive=1 AND ISNULL(actor.IsDeleted,0)=0
 JOIN dbo.UsersMembers otherUser ON otherUser.ID=CASE WHEN t.SenderID=@Actor THEN t.ReceiverID ELSE t.SenderID END
 WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID)
 AND (NULLIF(@Person,'') IS NULL OR otherUser.FullName_Ar LIKE N'%'+@Person+N'%')
 AND (NULLIF(@Title,'') IS NULL OR t.Title LIKE N'%'+@Title+N'%')
 AND (@Filter='all' OR (@Filter='closed' AND t.CloseDate IS NOT NULL)
 OR (@Filter='unread' AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID AND m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0))
 OR (@Filter='overdue' AND t.CloseDate IS NULL AND t.DueDate<GETUTCDATE())
 OR (@Filter='active' AND t.CloseDate IS NULL AND (t.DueDate IS NULL OR t.DueDate>=GETUTCDATE())));
 DECLARE @TotalRows int=(SELECT COUNT(*) FROM #Matches);
 SELECT s.*,@TotalRows TotalRows FROM #Matches p JOIN dbo.Correspondence_ThreadSummary(@Actor) s ON s.ID=p.ID
 -- The shared ERP table handles presentation sorting and paging.
 OPTION(RECOMPILE, LOOP JOIN);
END;
GO
