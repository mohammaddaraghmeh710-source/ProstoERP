-- Explicitly requested simplification of the empty stage-1 schema.
-- ApplySimplified.ps1 supplies the transaction. Refuse to discard any records.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Employee_Feedback_Workflow') IS NOT NULL
    THROW 51000,'Simplified schema already exists.',1;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Employee_Data WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Stages WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Recipients WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Actions WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Attachments WITH (TABLOCKX,HOLDLOCK))
 OR EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WITH (TABLOCKX,HOLDLOCK))
    THROW 51001,'Existing feedback records require a data-preserving migration. Nothing changed.',1;

ALTER TABLE dbo.Employee_Feedback_Requests ADD EmployeeID int NOT NULL
    CONSTRAINT FK_EF_Requests_Employee REFERENCES dbo.UsersMembers(ID);
CREATE INDEX IX_EF_Requests_Employee ON dbo.Employee_Feedback_Requests(EmployeeID,AddedDate DESC,ID);

CREATE TABLE dbo.Employee_Feedback_Workflow (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Workflow PRIMARY KEY,
    Request_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),
    SenderID int NOT NULL REFERENCES dbo.UsersMembers(ID),
    ReceiverID int NOT NULL REFERENCES dbo.UsersMembers(ID),
    Comment nvarchar(max) NOT NULL,
    ActionType int NOT NULL, -- code constants: 1 submission, 2 transfer, 3 close
    GroupID uniqueidentifier NOT NULL, -- same value for all recipients of one operation
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Workflow_Added DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_EF_Workflow_Request UNIQUE(ID,Request_ID),
    CONSTRAINT UQ_EF_Workflow_Recipient UNIQUE(Request_ID,GroupID,ReceiverID),
    CONSTRAINT CK_EF_Workflow_Action CHECK(ActionType IN (1,2,3)),
    CONSTRAINT CK_EF_Workflow_Comment CHECK(LEN(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(Comment,CHAR(9),' '),CHAR(10),' '),CHAR(13),' '))))>0)
);
CREATE INDEX IX_EF_Workflow_Timeline ON dbo.Employee_Feedback_Workflow(Request_ID,AddedDate,ID);
CREATE INDEX IX_EF_Workflow_Inbox ON dbo.Employee_Feedback_Workflow(ReceiverID,Request_ID,ID) INCLUDE(GroupID,ActionType);

ALTER TABLE dbo.Employee_Feedback_Attachments DROP CONSTRAINT FK_EF_Attachments_Action;
DROP INDEX IX_EF_Attachments_Request ON dbo.Employee_Feedback_Attachments;
EXEC sys.sp_rename 'dbo.Employee_Feedback_Attachments.Action_ID','Workflow_ID','COLUMN';
ALTER TABLE dbo.Employee_Feedback_Attachments ADD CONSTRAINT FK_EF_Attachments_Workflow
    FOREIGN KEY(Workflow_ID,Request_ID) REFERENCES dbo.Employee_Feedback_Workflow(ID,Request_ID);
CREATE INDEX IX_EF_Attachments_Request ON dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,ID);

-- Preserve notification fields and indexes as requested. Action_ID now references
-- the workflow event, instead of the removed Actions table.
ALTER TABLE dbo.Employee_Feedback_Notifications DROP CONSTRAINT FK_EF_Notifications_Action;
ALTER TABLE dbo.Employee_Feedback_Notifications ADD CONSTRAINT FK_EF_Notifications_Workflow
    FOREIGN KEY(Action_ID,Request_ID) REFERENCES dbo.Employee_Feedback_Workflow(ID,Request_ID);

DROP TABLE dbo.Employee_Feedback_Actions;
DROP TABLE dbo.Employee_Feedback_Recipients;
DROP TABLE dbo.Employee_Feedback_Stages;
DROP TABLE dbo.Employee_Feedback_Employee_Data;
