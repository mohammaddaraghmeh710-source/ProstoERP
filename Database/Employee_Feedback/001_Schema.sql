-- Stage 1 only: tables, relationships and indexes. Dates are UTC.
-- Apply.ps1 wraps this entire file in one transaction. No existing data is changed.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE 'Employee[_]Feedback[_]%')
    THROW 51000, 'Employee feedback tables already exist. Review before applying.', 1;

CREATE TABLE dbo.Employee_Feedback_Topics (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Topics PRIMARY KEY,
    Type int NOT NULL, -- 1 complaint, 2 suggestion
    Brand_ID int NOT NULL REFERENCES dbo.Brands(ID),
    Title_Ar nvarchar(200) NOT NULL,
    Title_En nvarchar(200) NOT NULL,
    Item_Order int NOT NULL CONSTRAINT DF_EF_Topics_Order DEFAULT 0,
    AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Topics_Added DEFAULT GETUTCDATE(),
    ModifyUser int NULL REFERENCES dbo.UsersMembers(ID),
    ModifyDate datetime NULL,
    IsActive bit NOT NULL CONSTRAINT DF_EF_Topics_Active DEFAULT 1,
    IsDeleted bit NOT NULL CONSTRAINT DF_EF_Topics_Deleted DEFAULT 0,
    CONSTRAINT CK_EF_Topics_Type CHECK (Type IN (1,2)),
    CONSTRAINT CK_EF_Topics_Titles CHECK (LEN(LTRIM(RTRIM(Title_Ar)))>0 AND LEN(LTRIM(RTRIM(Title_En)))>0),
    CONSTRAINT UQ_EF_Topics_Scope UNIQUE (ID,Type,Brand_ID)
);
CREATE INDEX IX_EF_Topics_List ON dbo.Employee_Feedback_Topics(Brand_ID,Type,IsDeleted,IsActive,Item_Order);

CREATE TABLE dbo.Employee_Feedback_Requests (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Requests PRIMARY KEY,
    Type int NOT NULL,
    Topic_ID int NOT NULL,
    Brand_ID int NOT NULL,
    Topic_Title_Ar nvarchar(200) NOT NULL,
    Topic_Title_En nvarchar(200) NOT NULL,
    Title nvarchar(300) NOT NULL,
    Details nvarchar(max) NOT NULL,
    DiscloseIdentity bit NOT NULL,
    RequestedRecipientType int NOT NULL, -- Users_Types: 1 system, 2 branch, 3 shift
    Status int NOT NULL CONSTRAINT DF_EF_Requests_Status DEFAULT 1, -- 1 new, 2 in progress, 3 closed
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Requests_Added DEFAULT GETUTCDATE(),
    CloseDate datetime NULL,
    RowVersion rowversion NOT NULL,
    CONSTRAINT FK_EF_Requests_Topic FOREIGN KEY (Topic_ID,Type,Brand_ID)
        REFERENCES dbo.Employee_Feedback_Topics(ID,Type,Brand_ID),
    CONSTRAINT CK_EF_Requests_Target CHECK (RequestedRecipientType IN (1,2,3)),
    CONSTRAINT CK_EF_Requests_Text CHECK (LEN(LTRIM(RTRIM(Title)))>0 AND LEN(LTRIM(RTRIM(Details)))>0),
    CONSTRAINT CK_EF_Requests_Status CHECK ((Status IN (1,2) AND CloseDate IS NULL) OR (Status=3 AND CloseDate IS NOT NULL)),
    CONSTRAINT CK_EF_Requests_CloseDate CHECK (CloseDate IS NULL OR CloseDate>=AddedDate)
);
CREATE INDEX IX_EF_Requests_Report ON dbo.Employee_Feedback_Requests(Brand_ID,Type,Status,AddedDate DESC,ID);

-- Private snapshot: never return this table to anonymous recipients or reports.
-- Missing organizational assignments remain NULL, matching current employee records.
CREATE TABLE dbo.Employee_Feedback_Employee_Data (
    Request_ID int NOT NULL CONSTRAINT PK_EF_EmployeeData PRIMARY KEY REFERENCES dbo.Employee_Feedback_Requests(ID),
    Employee_ID int NOT NULL REFERENCES dbo.UsersMembers(ID),
    Employee_Number int NULL,
    FullName_Ar nvarchar(max) NULL,
    FullName_En nvarchar(max) NULL,
    Branch_ID int NULL REFERENCES dbo.Branches(ID),
    Department_ID int NULL REFERENCES dbo.Departments(ID),
    JobTitle_ID int NULL REFERENCES dbo.JobTitles(ID),
    Shift_ID int NULL REFERENCES dbo.Shift(ID),
    Brand_Title_Ar nvarchar(max) NULL,
    Brand_Title_En nvarchar(max) NULL,
    Branch_Title_Ar nvarchar(max) NULL,
    Branch_Title_En nvarchar(max) NULL,
    Department_Title_Ar nvarchar(max) NULL,
    Department_Title_En nvarchar(max) NULL,
    JobTitle_Title_Ar nvarchar(max) NULL,
    JobTitle_Title_En nvarchar(max) NULL,
    Shift_Title_Ar nvarchar(max) NULL,
    Shift_Title_En nvarchar(max) NULL
);
CREATE INDEX IX_EF_EmployeeData_Own ON dbo.Employee_Feedback_Employee_Data(Employee_ID,Request_ID);
CREATE INDEX IX_EF_EmployeeData_Organization ON dbo.Employee_Feedback_Employee_Data(Branch_ID,Department_ID,JobTitle_ID,Shift_ID,Request_ID);

CREATE TABLE dbo.Employee_Feedback_Stages (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Stages PRIMARY KEY,
    Request_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),
    Stage_Number int NOT NULL,
    IntendedRecipientType int NOT NULL,
    RecipientType int NOT NULL,
    RoutingReason nvarchar(500) NULL, -- e.g. missing branch/shift manager -> system administrators
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Stages_Added DEFAULT GETUTCDATE(),
    CompletedDate datetime NULL,
    CONSTRAINT UQ_EF_Stages_Number UNIQUE (Request_ID,Stage_Number),
    CONSTRAINT UQ_EF_Stages_RequestRole UNIQUE (ID,Request_ID,RecipientType),
    CONSTRAINT CK_EF_Stages_Number CHECK (Stage_Number>0),
    CONSTRAINT CK_EF_Stages_Routing CHECK (IntendedRecipientType IN (1,2,3) AND RecipientType IN (1,2,3)
        AND (RecipientType=IntendedRecipientType OR (RecipientType=1 AND RoutingReason IS NOT NULL AND LEN(LTRIM(RTRIM(RoutingReason)))>0))),
    CONSTRAINT CK_EF_Stages_Date CHECK (CompletedDate IS NULL OR CompletedDate>=AddedDate)
);
CREATE UNIQUE INDEX UX_EF_Stages_Open ON dbo.Employee_Feedback_Stages(Request_ID) WHERE CompletedDate IS NULL;

CREATE TABLE dbo.Employee_Feedback_Recipients (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Recipients PRIMARY KEY,
    Stage_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Stages(ID),
    User_ID int NOT NULL REFERENCES dbo.UsersMembers(ID),
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Recipients_Added DEFAULT GETUTCDATE(),
    ReadDate datetime NULL,
    CONSTRAINT UQ_EF_Recipients_User UNIQUE (Stage_ID,User_ID)
);
CREATE INDEX IX_EF_Recipients_Inbox ON dbo.Employee_Feedback_Recipients(User_ID,Stage_ID) INCLUDE (ReadDate);

CREATE TABLE dbo.Employee_Feedback_Actions (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Actions PRIMARY KEY,
    Request_ID int NOT NULL,
    Stage_ID int NOT NULL,
    RecipientType int NOT NULL,
    ActionType int NOT NULL, -- 1 transfer, 2 close; no independent reply
    Details nvarchar(max) NOT NULL,
    AddedUser int NOT NULL,
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Actions_Added DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_EF_Actions_Stage UNIQUE (Stage_ID), -- one winner, including concurrent requests
    CONSTRAINT UQ_EF_Actions_Request UNIQUE (ID,Request_ID),
    CONSTRAINT FK_EF_Actions_Stage FOREIGN KEY (Stage_ID,Request_ID,RecipientType)
        REFERENCES dbo.Employee_Feedback_Stages(ID,Request_ID,RecipientType),
    CONSTRAINT FK_EF_Actions_Actor FOREIGN KEY (Stage_ID,AddedUser)
        REFERENCES dbo.Employee_Feedback_Recipients(Stage_ID,User_ID),
    CONSTRAINT CK_EF_Actions_Type CHECK (ActionType IN (1,2) AND (RecipientType<>1 OR ActionType=2)),
    CONSTRAINT CK_EF_Actions_Details CHECK (LEN(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(Details,CHAR(9),' '),CHAR(10),' '),CHAR(13),' '))))>0)
);
CREATE INDEX IX_EF_Actions_Timeline ON dbo.Employee_Feedback_Actions(Request_ID,AddedDate,ID);

CREATE TABLE dbo.Employee_Feedback_Attachments (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Attachments PRIMARY KEY,
    Request_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),
    Action_ID int NULL, -- NULL = original employee submission
    FileName nvarchar(260) NOT NULL, -- generated storage name, never a client path
    OriginalFileName nvarchar(260) NOT NULL, -- private metadata; display neutral attachment labels
    File_Type nvarchar(10) NOT NULL,
    FileSize bigint NOT NULL,
    AddedDate datetime NOT NULL CONSTRAINT DF_EF_Attachments_Added DEFAULT GETUTCDATE(),
    CONSTRAINT FK_EF_Attachments_Action FOREIGN KEY (Action_ID,Request_ID) REFERENCES dbo.Employee_Feedback_Actions(ID,Request_ID),
    CONSTRAINT UQ_EF_Attachments_File UNIQUE (FileName),
    CONSTRAINT CK_EF_Attachments_Size CHECK (FileSize>0 AND FileSize<=10485760),
    CONSTRAINT CK_EF_Attachments_Name CHECK (LEN(LTRIM(RTRIM(FileName)))>0),
    CONSTRAINT CK_EF_Attachments_Type CHECK (File_Type IN ('pdf','doc','docx','xls','xlsx','jpg','jpeg','png','gif'))
);
CREATE INDEX IX_EF_Attachments_Request ON dbo.Employee_Feedback_Attachments(Request_ID,Action_ID,ID);

CREATE TABLE dbo.Employee_Feedback_Notifications (
    ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EF_Notifications PRIMARY KEY,
    UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
    Request_ID int NOT NULL REFERENCES dbo.Employee_Feedback_Requests(ID),
    Action_ID int NULL,
    NotificationType int NOT NULL, -- 1 submission, 2 transfer, 3 close
    SendDate datetime NOT NULL CONSTRAINT DF_EF_Notifications_Send DEFAULT GETUTCDATE(),
    IsRead bit NOT NULL CONSTRAINT DF_EF_Notifications_Read DEFAULT 0,
    ReadDate datetime NULL,
    CONSTRAINT FK_EF_Notifications_Action FOREIGN KEY (Action_ID,Request_ID) REFERENCES dbo.Employee_Feedback_Actions(ID,Request_ID),
    CONSTRAINT CK_EF_Notifications_Type CHECK ((NotificationType=1 AND Action_ID IS NULL) OR (NotificationType IN (2,3) AND Action_ID IS NOT NULL)),
    CONSTRAINT CK_EF_Notifications_Read CHECK ((IsRead=0 AND ReadDate IS NULL) OR (IsRead=1 AND ReadDate IS NOT NULL))
);
CREATE INDEX IX_EF_Notifications_Inbox ON dbo.Employee_Feedback_Notifications(UserID,IsRead,SendDate DESC) INCLUDE (Request_ID,Action_ID);
CREATE UNIQUE INDEX UX_EF_Notifications_Submission ON dbo.Employee_Feedback_Notifications(UserID,Request_ID) WHERE Action_ID IS NULL;
CREATE UNIQUE INDEX UX_EF_Notifications_Action ON dbo.Employee_Feedback_Notifications(UserID,Action_ID) WHERE Action_ID IS NOT NULL;
