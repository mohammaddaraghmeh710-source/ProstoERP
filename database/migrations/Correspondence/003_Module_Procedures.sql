-- Named, single-result procedures for the existing LINQ-to-SQL/Web Forms modules.
SET XACT_ABORT ON;
GO
CREATE OR ALTER FUNCTION dbo.Correspondence_ThreadSummary(@Actor int)
RETURNS TABLE AS RETURN
 SELECT t.ID,t.Title,t.Brief,t.SenderID,t.ReceiverID,t.CreatedBy,t.RequiresCompletion,t.DueDate,t.CloseDate,t.IsCompleted,t.IsBroadcast,t.CreatedDate,
  u.FullName_Ar OtherName,u.User_Image OtherImage,
  a.MessageCount,a.UnreadCount,a.LastMessageDate,lastMessage.Body LastBody,lastMessage.SenderID LastSenderID,
  CAST(CASE WHEN t.CreatedBy=@Actor AND t.CloseDate IS NULL AND EXISTS(SELECT 1 FROM dbo.Correspondence_Thread_Messages r WHERE r.ThreadID=t.ID AND r.SenderID<>@Actor AND r.ReceivedID=@Actor) THEN 1 ELSE 0 END AS bit) CanClose
 FROM dbo.Correspondence_Threads t
 JOIN dbo.UsersMembers u ON u.ID=CASE WHEN t.SenderID=@Actor THEN t.ReceiverID ELSE t.SenderID END
 JOIN dbo.UsersMembers actor ON actor.ID=@Actor AND actor.IsActive=1 AND ISNULL(actor.IsDeleted,0)=0
 CROSS APPLY(SELECT COUNT(*) MessageCount,COUNT(CASE WHEN m.ReceivedID=@Actor AND ISNULL(m.IsRead,0)=0 THEN 1 END) UnreadCount,MAX(m.CreatedDate) LastMessageDate FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID) a
 OUTER APPLY(SELECT TOP(1) m.Body,m.SenderID FROM dbo.Correspondence_Thread_Messages m WHERE m.ThreadID=t.ID ORDER BY m.ID DESC) lastMessage
 WHERE ISNULL(t.IsDeleted,0)=0 AND @Actor IN(t.SenderID,t.ReceiverID);
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Threads_ByUserID
 @Actor int,@Search nvarchar(200)=NULL,@Filter varchar(10)='all',@Page int=1
AS
BEGIN
 SET NOCOUNT ON;
 IF @Page<1 SET @Page=1;
 SELECT *,COUNT(*) OVER() TotalRows FROM dbo.Correspondence_ThreadSummary(@Actor)
 WHERE (NULLIF(@Search,'') IS NULL OR Title LIKE N'%'+@Search+N'%' OR Brief LIKE N'%'+@Search+N'%' OR OtherName LIKE N'%'+@Search+N'%')
 AND (@Filter='all' OR (@Filter='unread' AND UnreadCount>0) OR (@Filter='closed' AND CloseDate IS NOT NULL)
 OR (@Filter='overdue' AND CloseDate IS NULL AND DueDate<GETUTCDATE()) OR (@Filter='active' AND CloseDate IS NULL AND (DueDate IS NULL OR DueDate>=GETUTCDATE())))
 ORDER BY ISNULL(LastMessageDate,CreatedDate) DESC,ID DESC OFFSET (@Page-1)*30 ROWS FETCH NEXT 30 ROWS ONLY;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Thread_ByID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT * FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE ID=@ThreadID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Messages_ByThreadID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT m.ID,m.ThreadID,m.SenderID,m.ReceivedID,m.Body,m.CreatedDate,ISNULL(m.IsRead,0) IsRead,m.ReadDate,u.FullName_Ar SenderName
 FROM dbo.Correspondence_Thread_Messages m JOIN dbo.UsersMembers u ON u.ID=m.SenderID WHERE m.ThreadID=@ThreadID ORDER BY m.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Attachments_ByThreadID @Actor int,@ThreadID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE ID=@ThreadID) THROW 51400,N'المحادثة غير متاحة لك.',1;
 SELECT a.ID,a.MessageID,a.FileName,a.File_Type,a.FileSize FROM dbo.Correspondence_Message_Attachments a
 JOIN dbo.Correspondence_Thread_Messages m ON m.ID=a.MessageID WHERE m.ThreadID=@ThreadID ORDER BY a.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_Recipients @Actor int,@Brand int=0,@Branch int=0,@Shift int=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT ID,FullName_Ar,Type FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand)
 WHERE (@Branch=0 OR Branch_ID=@Branch) AND (@Shift=0 OR Shif_ID=@Shift) ORDER BY FullName_Ar;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Correspondence_UnreadCount @Actor int
AS
BEGIN
 SET NOCOUNT ON;
 SELECT COUNT(*) UnreadThreads FROM dbo.Correspondence_ThreadSummary(@Actor) WHERE UnreadCount>0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread
 @Actor int,@Brand int,@Recipients xml,@Title nvarchar(200),@Brief nvarchar(2000),@Body nvarchar(4000),@RequiresCompletion bit,@DueDate datetime,@Files xml
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Correspondence_Page @Actor=@Actor,@Action='create',@Brand=@Brand,@Recipients=@Recipients,@Title=@Title,@Brief=@Brief,@Body=@Body,@RequiresCompletion=@RequiresCompletion,@DueDate=@DueDate,@Files=@Files;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Correspondence_Thread_Message @Actor int,@ThreadID int,@Body nvarchar(4000),@Files xml
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Correspondence_Page @Actor=@Actor,@Action='reply',@ThreadID=@ThreadID,@Body=@Body,@Files=@Files;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Update_Correspondence_Thread_Close @Actor int,@ThreadID int,@IsCompleted bit
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Correspondence_Page @Actor=@Actor,@Action='close',@ThreadID=@ThreadID,@IsCompleted=@IsCompleted;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Update_Correspondence_Messages_Read @Actor int,@ThreadID int,@MessageIDs xml
AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.Correspondence_Page @Actor=@Actor,@Action='read',@ThreadID=@ThreadID,@MessageIDs=@MessageIDs;
END;
