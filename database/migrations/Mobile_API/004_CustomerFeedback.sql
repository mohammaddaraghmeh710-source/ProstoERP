SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Insert_Customer_Feedback_Request','P') IS NULL THROW 51800,'Apply Employee_Feedback/009_CustomerSupport.sql first.',1;
IF OBJECT_ID('dbo.Customer_Feedback_Submissions','U') IS NULL
BEGIN
 CREATE TABLE dbo.Customer_Feedback_Submissions(
 OperationID uniqueidentifier NOT NULL PRIMARY KEY,
 PayloadHash binary(32) NOT NULL,
 RequestID int NOT NULL UNIQUE REFERENCES dbo.Employee_Feedback_Requests(ID),
 OccurredAt datetimeoffset(3) NOT NULL,
 ReceivedUtc datetime2(3) NOT NULL,
 WorkflowGroupID uniqueidentifier NOT NULL
 );
END;
IF OBJECT_ID('dbo.Customer_Feedback_RateLimits','U') IS NULL
BEGIN
 CREATE TABLE dbo.Customer_Feedback_RateLimits(
 ClientHash binary(32) NOT NULL, Scope varchar(12) NOT NULL,WindowUtc datetime2(0) NOT NULL,
 Attempts int NOT NULL,PRIMARY KEY(ClientHash,Scope,WindowUtc));
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_Feedback_CheckRate @ClientHash binary(32),@Scope varchar(12) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @Scope NOT IN('options','submit') THROW 51800,'Invalid limiter scope.',1;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@Window datetime2(0),@Count int,@Limit int,@Seconds int;
 SET @Window=CASE WHEN @Scope='submit' THEN DATEADD(hour,DATEDIFF(hour,0,@Now),0) ELSE DATEADD(minute,DATEDIFF(minute,0,@Now),0) END;
 SET @Limit=CASE WHEN @Scope='submit' THEN 10 ELSE 120 END;
 SET @Seconds=DATEDIFF(second,@Now,CASE WHEN @Scope='submit' THEN DATEADD(hour,1,@Window) ELSE DATEADD(minute,1,@Window) END);
 BEGIN TRANSACTION;
 SELECT @Count=Attempts FROM dbo.Customer_Feedback_RateLimits WITH(UPDLOCK,HOLDLOCK) WHERE ClientHash=@ClientHash AND Scope=@Scope AND WindowUtc=@Window;
 IF @Count IS NULL BEGIN
  INSERT dbo.Customer_Feedback_RateLimits VALUES(@ClientHash,@Scope,@Window,1); SET @Count=1;
 END ELSE IF @Count<@Limit BEGIN
  UPDATE dbo.Customer_Feedback_RateLimits SET Attempts=Attempts+1 WHERE ClientHash=@ClientHash AND Scope=@Scope AND WindowUtc=@Window;
  SET @Count=@Count+1;
 END ELSE SET @Count=@Limit+1;
 DELETE dbo.Customer_Feedback_RateLimits WHERE WindowUtc<DATEADD(day,-2,@Now);
 COMMIT;
 SELECT CONVERT(bit,CASE WHEN @Count<=@Limit THEN 1 ELSE 0 END) Allowed,@Seconds RetryAfterSeconds;
END;
GO
