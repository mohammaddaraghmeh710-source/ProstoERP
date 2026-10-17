-- Apply after 005. DeviceID is a case-sensitive installation identifier, not a MAC address.
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.MobileApi_DevicePolicy','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileApi_DevicePolicy(UserID int NOT NULL PRIMARY KEY REFERENCES dbo.UsersMembers(ID),AllowNextEnrollment bit NOT NULL);
 CREATE TABLE dbo.MobileApi_Devices(
 ID int IDENTITY PRIMARY KEY,UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
 DeviceID nvarchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,DevicePlatform nvarchar(16) NOT NULL,
 DeviceManufacturer nvarchar(100) NULL,DeviceModel nvarchar(150) NOT NULL,OSVersion nvarchar(50) NOT NULL,
 AppVersion nvarchar(50) NOT NULL,AppBuild nvarchar(50) NULL,MACID varchar(17) NULL,
 IsApproved bit NOT NULL DEFAULT 0,FirstSeenUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),LastLoginUtc datetime2(0) NULL,
 CONSTRAINT UQ_MobileApi_Device UNIQUE(UserID,DeviceID,DevicePlatform));
 CREATE TABLE dbo.MobileApi_DeviceRequests(
 ID int IDENTITY PRIMARY KEY,DeviceRegistrationID int NOT NULL REFERENCES dbo.MobileApi_Devices(ID),
 Status varchar(20) NOT NULL DEFAULT 'Pending' CHECK(Status IN('Pending','Approved','Rejected','Cancelled')),
 CreatedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),DecidedUtc datetime2(0) NULL,
 DecidedBy int NULL REFERENCES dbo.UsersMembers(ID),Decision varchar(24) NULL,Comment nvarchar(500) NULL);
 CREATE UNIQUE INDEX UX_MobileApi_PendingDevice ON dbo.MobileApi_DeviceRequests(DeviceRegistrationID) WHERE Status='Pending';
 CREATE TABLE dbo.MobileApi_DeviceHistory(
 ID bigint IDENTITY PRIMARY KEY,UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
 DeviceRegistrationID int NULL REFERENCES dbo.MobileApi_Devices(ID),RequestID int NULL REFERENCES dbo.MobileApi_DeviceRequests(ID),
 Action varchar(24) NOT NULL,ActorID int NULL REFERENCES dbo.UsersMembers(ID),Comment nvarchar(500) NULL,CreatedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME());
 CREATE INDEX IX_MobileApi_DeviceHistory_User ON dbo.MobileApi_DeviceHistory(UserID,ID DESC);
END;
IF COL_LENGTH('dbo.MobileApi_Sessions','DeviceRegistrationID') IS NULL
 ALTER TABLE dbo.MobileApi_Sessions ADD DeviceRegistrationID int NULL REFERENCES dbo.MobileApi_Devices(ID);
GO
-- Preserve the earliest known device for existing accounts; retain all historic rows.
-- Accounts whose old sessions lack device information enroll at their next login.
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'MobileApi_DeviceAccess_Migrated')
BEGIN
 ;WITH Known AS (SELECT *,ROW_NUMBER() OVER(PARTITION BY UserID,DeviceID COLLATE Latin1_General_100_BIN2,DevicePlatform ORDER BY CreatedUtc,TokenHash) rn
 FROM dbo.MobileApi_Sessions WHERE DeviceID IS NOT NULL AND DeviceModel IS NOT NULL AND OSVersion IS NOT NULL AND AppVersion IS NOT NULL)
 INSERT dbo.MobileApi_Devices(UserID,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,AppVersion,AppBuild,MACID,FirstSeenUtc)
 SELECT UserID,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,AppVersion,AppBuild,MACID,CreatedUtc FROM Known WHERE rn=1;
 ;WITH FirstDevice AS(SELECT *,ROW_NUMBER() OVER(PARTITION BY UserID ORDER BY FirstSeenUtc,ID) rn FROM dbo.MobileApi_Devices)
 UPDATE FirstDevice SET IsApproved=1 WHERE rn=1;
 INSERT dbo.MobileApi_DevicePolicy SELECT DISTINCT UserID,0 FROM dbo.MobileApi_Devices;
 UPDATE s SET DeviceRegistrationID=d.ID,RevokedUtc=CASE WHEN d.IsApproved=0 THEN COALESCE(s.RevokedUtc,SYSUTCDATETIME()) ELSE s.RevokedUtc END
 FROM dbo.MobileApi_Sessions s JOIN dbo.MobileApi_Devices d ON d.UserID=s.UserID AND d.DeviceID=s.DeviceID COLLATE Latin1_General_100_BIN2 AND d.DevicePlatform=s.DevicePlatform;
 UPDATE dbo.MobileApi_Sessions SET RevokedUtc=COALESCE(RevokedUtc,SYSUTCDATETIME()) WHERE DeviceRegistrationID IS NULL;
 INSERT dbo.MobileApi_DeviceHistory(UserID,DeviceRegistrationID,Action) SELECT UserID,ID,CASE WHEN IsApproved=1 THEN 'MigratedApproved' ELSE 'MigratedRevoked' END FROM dbo.MobileApi_Devices;
 EXEC sys.sp_addextendedproperty @name=N'MobileApi_DeviceAccess_Migrated',@value=1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_DeviceAccess
 @Username nvarchar(250),@EncryptedPassword nvarchar(max),@AppVersion nvarchar(50),@DeviceID nvarchar(128),
 @DevicePlatform nvarchar(16),@DeviceModel nvarchar(150),@OSVersion nvarchar(50),@AppBuild nvarchar(50)=NULL,
 @DeviceManufacturer nvarchar(100)=NULL,@MACID varchar(17)=NULL,@Submit bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @UserID int,@Device int,@Request int;
 BEGIN TRY
 BEGIN TRAN;
 SELECT @UserID=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE UserName=@Username
 AND Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Type<>7;
 IF @UserID IS NULL BEGIN COMMIT; RETURN; END;
 SELECT @Device=ID FROM dbo.MobileApi_Devices WHERE UserID=@UserID AND DeviceID=@DeviceID COLLATE Latin1_General_100_BIN2 AND DevicePlatform=@DevicePlatform;
 IF @Submit=1 AND NOT EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@Device AND IsApproved=1)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_DeviceRequests WHERE DeviceRegistrationID=@Device AND Status='Pending')
   AND (SELECT COUNT(*) FROM dbo.MobileApi_DeviceRequests r JOIN dbo.MobileApi_Devices d ON d.ID=r.DeviceRegistrationID WHERE d.UserID=@UserID AND r.Status='Pending')>=5
   THROW 51713,'Too many pending device requests.',1;
  IF @Device IS NULL BEGIN
   INSERT dbo.MobileApi_Devices(UserID,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,AppVersion,AppBuild,MACID)
   VALUES(@UserID,@DeviceID,@DevicePlatform,@DeviceManufacturer,@DeviceModel,@OSVersion,@AppVersion,@AppBuild,@MACID);
   SET @Device=SCOPE_IDENTITY();
  END;
  SELECT @Request=ID FROM dbo.MobileApi_DeviceRequests WHERE DeviceRegistrationID=@Device AND Status='Pending';
  IF @Request IS NULL BEGIN
   UPDATE dbo.MobileApi_Devices SET DeviceManufacturer=@DeviceManufacturer,DeviceModel=@DeviceModel,OSVersion=@OSVersion,
   AppVersion=@AppVersion,AppBuild=@AppBuild,MACID=@MACID WHERE ID=@Device;
   INSERT dbo.MobileApi_DeviceRequests(DeviceRegistrationID) VALUES(@Device);SET @Request=SCOPE_IDENTITY();
   INSERT dbo.MobileApi_DeviceHistory(UserID,DeviceRegistrationID,RequestID,Action,ActorID) VALUES(@UserID,@Device,@Request,'Requested',@UserID);
  END;
 END;
 SELECT TOP(1) @Request=ID FROM dbo.MobileApi_DeviceRequests WHERE DeviceRegistrationID=@Device ORDER BY ID DESC;
 SELECT @Request RequestID,
 CASE WHEN EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@Device AND IsApproved=1) THEN 'Approved'
 WHEN @Request IS NOT NULL THEN (SELECT Status FROM dbo.MobileApi_DeviceRequests WHERE ID=@Request) ELSE 'NotRequested' END Status,
 CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@Device AND IsApproved=1) OR NOT EXISTS(SELECT 1 FROM dbo.MobileApi_DevicePolicy WHERE UserID=@UserID AND AllowNextEnrollment=0) THEN 1 ELSE 0 END AS bit) CanLogin,
 (SELECT CreatedUtc FROM dbo.MobileApi_DeviceRequests WHERE ID=@Request) CreatedUtc,
 (SELECT DecidedUtc FROM dbo.MobileApi_DeviceRequests WHERE ID=@Request) DecidedUtc;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_ManageDevices
 @Actor int,@UserID int,@Action varchar(24),@DeviceRegistrationID int=NULL,@RequestID int=NULL,@Comment nvarchar(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @Target int,@Now datetime2(0)=SYSUTCDATETIME();
 BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51711,'Administrator permission required.',1;
 SELECT @Target=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@UserID AND ISNULL(IsDeleted,0)=0;
 IF @Target IS NULL THROW 51712,'User not found.',1;
 IF @Action NOT IN('ApproveReplace','ApproveAdd','Reject','Revoke','ResetAll') THROW 51712,'Invalid action.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_DevicePolicy WHERE UserID=@UserID) INSERT dbo.MobileApi_DevicePolicy VALUES(@UserID,0);
 IF @Action IN('ApproveReplace','ApproveAdd','Reject')
 BEGIN
  SET @DeviceRegistrationID=NULL;
  SELECT @DeviceRegistrationID=d.ID FROM dbo.MobileApi_DeviceRequests r JOIN dbo.MobileApi_Devices d ON d.ID=r.DeviceRegistrationID
  WHERE r.ID=@RequestID AND r.Status='Pending' AND d.UserID=@UserID;
  IF @DeviceRegistrationID IS NULL THROW 51712,'Request already processed or not found.',1;
  UPDATE dbo.MobileApi_DeviceRequests SET Status=CASE WHEN @Action='Reject' THEN 'Rejected' ELSE 'Approved' END,
   DecidedUtc=@Now,DecidedBy=@Actor,Decision=@Action,Comment=@Comment WHERE ID=@RequestID;
 END;
 IF @Action='Revoke' AND NOT EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@DeviceRegistrationID AND UserID=@UserID AND IsApproved=1) THROW 51712,'Device already revoked or not found.',1;
 IF @Action IN('ApproveReplace','ResetAll','Revoke')
 BEGIN
  UPDATE dbo.MobileApi_Devices SET IsApproved=0 WHERE UserID=@UserID AND (@Action<>'Revoke' OR ID=@DeviceRegistrationID);
  UPDATE dbo.MobileApi_Sessions SET RevokedUtc=COALESCE(RevokedUtc,@Now) WHERE UserID=@UserID AND (@Action<>'Revoke' OR DeviceRegistrationID=@DeviceRegistrationID);
 END;
 IF @Action IN('ApproveReplace','ApproveAdd') UPDATE dbo.MobileApi_Devices SET IsApproved=1 WHERE ID=@DeviceRegistrationID;
 IF @Action<>'Reject' UPDATE dbo.MobileApi_DevicePolicy SET AllowNextEnrollment=CASE WHEN @Action='ResetAll' THEN 1 ELSE 0 END WHERE UserID=@UserID;
 IF @Action='ResetAll'
 BEGIN
  SET @DeviceRegistrationID=NULL;SET @RequestID=NULL;
  UPDATE r SET Status='Cancelled',DecidedUtc=@Now,DecidedBy=@Actor,Decision='ResetAll',Comment=@Comment
  FROM dbo.MobileApi_DeviceRequests r JOIN dbo.MobileApi_Devices d ON d.ID=r.DeviceRegistrationID WHERE d.UserID=@UserID AND r.Status='Pending';
 END;
 INSERT dbo.MobileApi_DeviceHistory(UserID,DeviceRegistrationID,RequestID,Action,ActorID,Comment) VALUES(@UserID,@DeviceRegistrationID,@RequestID,@Action,@Actor,@Comment);
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_DeviceAdminView @Actor int,@UserID int=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51711,'Administrator permission required.',1;
 SELECT u.ID,u.Employee_Number,u.FullName_Ar,COALESCE(p.AllowNextEnrollment,1) AllowNextEnrollment,
 (SELECT COUNT(*) FROM dbo.MobileApi_Devices d WHERE d.UserID=u.ID AND d.IsApproved=1) ApprovedCount,
 (SELECT COUNT(*) FROM dbo.MobileApi_Devices d JOIN dbo.MobileApi_DeviceRequests r ON r.DeviceRegistrationID=d.ID WHERE d.UserID=u.ID AND r.Status='Pending') PendingCount
 FROM dbo.UsersMembers u LEFT JOIN dbo.MobileApi_DevicePolicy p ON p.UserID=u.ID WHERE (@UserID IS NULL OR u.ID=@UserID) AND ISNULL(u.IsDeleted,0)=0;
 IF @UserID IS NULL RETURN;
 SELECT * FROM dbo.MobileApi_Devices WHERE UserID=@UserID ORDER BY IsApproved DESC,ID DESC;
 SELECT r.ID,r.Status,r.CreatedUtc,r.DecidedUtc,r.Decision,r.Comment,d.DeviceID,d.DevicePlatform,d.DeviceModel,d.OSVersion,d.AppVersion,d.AppBuild,d.DeviceManufacturer,d.MACID
 FROM dbo.MobileApi_DeviceRequests r JOIN dbo.MobileApi_Devices d ON d.ID=r.DeviceRegistrationID WHERE d.UserID=@UserID ORDER BY CASE WHEN r.Status='Pending' THEN 0 ELSE 1 END,r.ID DESC;
 SELECT h.ID,h.Action,h.Comment,h.CreatedUtc,h.RequestID,d.DeviceID,d.DeviceModel,u.FullName_Ar ActorName
 FROM dbo.MobileApi_DeviceHistory h LEFT JOIN dbo.MobileApi_Devices d ON d.ID=h.DeviceRegistrationID LEFT JOIN dbo.UsersMembers u ON u.ID=h.ActorID WHERE h.UserID=@UserID ORDER BY h.ID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Login
 @Username nvarchar(250),@EncryptedPassword nvarchar(max),@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int,
 @AppVersion nvarchar(50),@DeviceID nvarchar(128),@DevicePlatform nvarchar(16),@DeviceModel nvarchar(150),@OSVersion nvarchar(50),
 @AppBuild nvarchar(50)=NULL,@DeviceManufacturer nvarchar(100)=NULL,@MACID varchar(17)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @IdleMinutes<1 OR @MaximumMinutes<@IdleMinutes THROW 51700,'Invalid session settings.',1;
 IF NULLIF(LTRIM(RTRIM(@AppVersion)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@DeviceID)),N'') IS NULL
 OR @DevicePlatform IS NULL OR @DevicePlatform NOT IN(N'Android',N'iOS')
 OR NULLIF(LTRIM(RTRIM(@DeviceModel)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@OSVersion)),N'') IS NULL
 THROW 51702,'Application version and device information are required.',1;
 DECLARE @UserID int,@EmployeeNumber int,@Now datetime2(0)=SYSUTCDATETIME();
 BEGIN TRY
 BEGIN TRANSACTION;
 SELECT @UserID=u.ID,@EmployeeNumber=u.Employee_Number FROM dbo.UsersMembers u WITH(UPDLOCK,HOLDLOCK)
 WHERE u.UserName=@Username AND u.Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7;
 IF @UserID IS NULL BEGIN COMMIT; RETURN; END;

 DECLARE @Device int;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_DevicePolicy WHERE UserID=@UserID) INSERT dbo.MobileApi_DevicePolicy VALUES(@UserID,1);
 SELECT @Device=ID FROM dbo.MobileApi_Devices WHERE UserID=@UserID AND DeviceID=@DeviceID COLLATE Latin1_General_100_BIN2 AND DevicePlatform=@DevicePlatform;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@Device AND IsApproved=1)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_DevicePolicy WHERE UserID=@UserID AND AllowNextEnrollment=1)
   THROW 51710,'Device approval required.',1;
  IF @Device IS NULL BEGIN
   INSERT dbo.MobileApi_Devices(UserID,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,AppVersion,AppBuild,MACID)
   VALUES(@UserID,@DeviceID,@DevicePlatform,@DeviceManufacturer,@DeviceModel,@OSVersion,@AppVersion,@AppBuild,@MACID);
   SET @Device=SCOPE_IDENTITY();
  END;
  UPDATE dbo.MobileApi_Devices SET IsApproved=1 WHERE ID=@Device;
  UPDATE dbo.MobileApi_DeviceRequests SET Status='Approved',DecidedUtc=@Now,Decision='AutoEnrolled' WHERE DeviceRegistrationID=@Device AND Status='Pending';
  INSERT dbo.MobileApi_DeviceHistory(UserID,DeviceRegistrationID,Action,ActorID) VALUES(@UserID,@Device,'AutoEnrolled',@UserID);
 END;
 UPDATE dbo.MobileApi_DevicePolicy SET AllowNextEnrollment=0 WHERE UserID=@UserID;
 UPDATE dbo.MobileApi_Devices SET DeviceManufacturer=@DeviceManufacturer,DeviceModel=@DeviceModel,OSVersion=@OSVersion,
 AppVersion=@AppVersion,AppBuild=@AppBuild,MACID=@MACID,LastLoginUtc=@Now WHERE ID=@Device;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,
 DeviceRegistrationID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID)
 VALUES(@TokenHash,@UserID,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),
 @Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now),
 @Device,@EmployeeNumber,LTRIM(RTRIM(@AppVersion)),NULLIF(LTRIM(RTRIM(@AppBuild)),N''),LTRIM(RTRIM(@DeviceID)),@DevicePlatform,
 NULLIF(LTRIM(RTRIM(@DeviceManufacturer)),N''),LTRIM(RTRIM(@DeviceModel)),LTRIM(RTRIM(@OSVersion)),@MACID);
 -- Employee identity comes only from the authenticated account, never the device payload.
 SELECT u.ID,u.Type,u.Type UserTypeID,u.Employee_Number,u.FullName_Ar,u.Fullname_En,u.User_Image,
 u.PhoneNumber,u.MobileNumber,u.Email,u.Brand_ID,u.Branch_ID,u.Department_ID,u.JobTitle_ID,u.Shif_ID,
 u.Gender,u.Nationality,u.UserName,u.Status,u.Item_Order,u.AddedUser,u.AddedDate,u.ModifyUser,u.ModifyDate,u.IsDeleted,u.IsActive,
 t.Title_Ar UserType_Ar,t.Title_En UserType_En,b.Title_Ar Brand_Ar,b.Title_En Brand_En,
 br.Title_Ar Branch_Ar,br.Title_En Branch_En,d.Title_Ar Department_Ar,d.Title_En Department_En,
 j.Title_Ar JobTitle_Ar,j.Title_En JobTitle_En,s.Title_Ar Shift_Ar,s.Title_En Shift_En,
 g.Title_Ar Gender_Ar,g.Title_En Gender_En,n.Title_Ar Nationality_Ar,n.Title_En Nationality_En
 FROM dbo.UsersMembers u
 LEFT JOIN dbo.Users_Types t ON t.ID=u.Type
 LEFT JOIN dbo.Brands b ON b.ID=u.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=u.Branch_ID
 LEFT JOIN dbo.Departments d ON d.ID=u.Department_ID LEFT JOIN dbo.JobTitles j ON j.ID=u.JobTitle_ID
 LEFT JOIN dbo.Shift s ON s.ID=u.Shif_ID LEFT JOIN dbo.Genders g ON g.ID=u.Gender
 LEFT JOIN dbo.Nationalities n ON n.ID=u.Nationality WHERE u.ID=@UserID;
 SELECT UserID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID,
 CreatedUtc,ExpiresUtc ExpiresAt,AbsoluteExpiresUtc AbsoluteExpiresAt FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Authenticate @TokenHash binary(32),@IdleMinutes int
AS
BEGIN
 SET NOCOUNT ON;
 IF @IdleMinutes<1 THROW 51700,'Invalid session settings.',1;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 UPDATE s SET LastSeenUtc=@Now,ExpiresUtc=CASE WHEN DATEADD(minute,@IdleMinutes,@Now)<s.AbsoluteExpiresUtc THEN DATEADD(minute,@IdleMinutes,@Now) ELSE s.AbsoluteExpiresUtc END
 OUTPUT inserted.UserID,inserted.ExpiresUtc ExpiresAt,inserted.AbsoluteExpiresUtc AbsoluteExpiresAt
 FROM dbo.MobileApi_Sessions s JOIN dbo.UsersMembers u ON u.ID=s.UserID
 JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.UserID=s.UserID AND d.IsApproved=1
 WHERE s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password));
END;
GO
