-- Initial defaults approved for employee feedback.
-- Run transactionally. Existing administrator configuration is preserved on rerun.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF (SELECT COUNT(*) FROM dbo.Users_Types WHERE ID IN(1,2,3,4,5,6,7)
    AND IsActive=1 AND ISNULL(IsDeleted,0)=0)<>7
    THROW 51500,N'Expected active user types are missing.',1;

IF OBJECT_ID(N'dbo.Employee_Feedback_Permissions',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.Employee_Feedback_Permissions(
  UserTypeID int NOT NULL CONSTRAINT PK_EF_Permissions PRIMARY KEY,
  CanSubmit bit NOT NULL CONSTRAINT DF_EF_Permissions_Submit DEFAULT(0),
  CanTransfer bit NOT NULL CONSTRAINT DF_EF_Permissions_Transfer DEFAULT(0),
  CanClose bit NOT NULL CONSTRAINT DF_EF_Permissions_Close DEFAULT(0),
  AddedDate datetime NOT NULL CONSTRAINT DF_EF_Permissions_Added DEFAULT(GETUTCDATE()),
  ModifyUser int NULL,
  ModifyDate datetime NULL,
  CONSTRAINT FK_EF_Permissions_Type FOREIGN KEY(UserTypeID) REFERENCES dbo.Users_Types(ID),
  CONSTRAINT FK_EF_Permissions_Modifier FOREIGN KEY(ModifyUser) REFERENCES dbo.UsersMembers(ID)
 );
END;

IF OBJECT_ID(N'dbo.Employee_Feedback_AllowedRecipients',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.Employee_Feedback_AllowedRecipients(
  SenderUserTypeID int NOT NULL,
  RecipientUserTypeID int NOT NULL,
  CONSTRAINT PK_EF_AllowedRecipients PRIMARY KEY(SenderUserTypeID,RecipientUserTypeID),
  CONSTRAINT FK_EF_AllowedRecipients_Sender FOREIGN KEY(SenderUserTypeID)
    REFERENCES dbo.Employee_Feedback_Permissions(UserTypeID),
  CONSTRAINT FK_EF_AllowedRecipients_Recipient FOREIGN KEY(RecipientUserTypeID)
    REFERENCES dbo.Users_Types(ID)
 );
END;

-- Seed recipient lists only for newly configured roles, so rerunning cannot
-- restore a route deliberately removed by an administrator.
DECLARE @NewRoles TABLE(UserTypeID int PRIMARY KEY);
INSERT dbo.Employee_Feedback_Permissions(UserTypeID,CanSubmit,CanTransfer,CanClose)
OUTPUT inserted.UserTypeID INTO @NewRoles
SELECT v.UserTypeID,v.CanSubmit,v.CanTransfer,v.CanClose
FROM (VALUES
 (1,0,0,1), -- System administrator: close addressed requests.
 (2,1,1,1), -- Branch manager.
 (3,1,1,1), -- Shift manager.
 (4,1,0,0), -- Employee: submit/read own requests.
 (5,1,0,0), -- Quality controller: submit/read own requests by default.
 (6,1,1,1), -- Department manager.
 (7,1,0,0)  -- External account: submit/read own requests.
) v(UserTypeID,CanSubmit,CanTransfer,CanClose)
WHERE NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions p WITH(UPDLOCK,HOLDLOCK)
 WHERE p.UserTypeID=v.UserTypeID);

-- This list is shared by submission and transfer. CanTransfer applies only
-- to taking a transfer action on an incoming request, not to submission.
INSERT dbo.Employee_Feedback_AllowedRecipients(SenderUserTypeID,RecipientUserTypeID)
SELECT v.SenderType,v.RecipientType
FROM (VALUES
 (2,1),
 (3,2),(3,1),
 (4,3),(4,6),(4,2),(4,1),
 (5,1),
 (6,2),(6,3),(6,1),
 (7,1)
) v(SenderType,RecipientType)
JOIN @NewRoles n ON n.UserTypeID=v.SenderType;
