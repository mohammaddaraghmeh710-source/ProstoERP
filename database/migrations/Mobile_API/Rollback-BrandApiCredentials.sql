-- Restore pre-brand ERP mobile contracts. Preserve historic session metadata and saved brand settings.
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
CREATE OR ALTER PROCEDURE dbo.MobileApi_News
AS
BEGIN
 SET NOCOUNT ON;
 SELECT PID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Image,Date,Item_Order,
 AddedUser,AddedDate,ModifyUser,ModifyDate,IsDeleted,IsActive
 FROM dbo.News WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Item_Order,Date DESC,PID DESC;
END;
GO
