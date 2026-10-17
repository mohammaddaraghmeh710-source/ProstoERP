-- Apply after 006. BIOID is a random reusable secret, not biometric data. Only hashes are stored.
SET XACT_ABORT ON;
IF OBJECT_ID('dbo.MobileApi_BIOCredentials','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileApi_BIOCredentials(
  BIOHash binary(32) NOT NULL PRIMARY KEY,
  UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
  DeviceRegistrationID int NOT NULL UNIQUE REFERENCES dbo.MobileApi_Devices(ID),
  SourceTokenHash binary(32) NOT NULL REFERENCES dbo.MobileApi_Sessions(TokenHash),
  PasswordFingerprint binary(32) NOT NULL,RevocationEpoch bigint NOT NULL,
  CreatedUtc datetime2(0) NOT NULL,ExpiresUtc datetime2(0) NOT NULL);
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Login
 @Username nvarchar(250),@EncryptedPassword nvarchar(max),@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int,
 @AppVersion nvarchar(50),@DeviceID nvarchar(128),@DevicePlatform nvarchar(16),@DeviceModel nvarchar(150),@OSVersion nvarchar(50),
 @AppBuild nvarchar(50)=NULL,@DeviceManufacturer nvarchar(100)=NULL,@MACID varchar(17)=NULL,@BIOHash binary(32)=NULL
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
 IF @BIOHash IS NOT NULL
 BEGIN
  DECLARE @Epoch bigint=ISNULL((SELECT MAX(ID) FROM dbo.MobileApi_DeviceHistory WHERE UserID=@UserID
   AND (Action IN('ResetAll','ApproveReplace') OR (Action='Revoke' AND DeviceRegistrationID=@Device))),0);
  DELETE dbo.MobileApi_BIOCredentials WHERE DeviceRegistrationID=@Device;
  INSERT dbo.MobileApi_BIOCredentials(BIOHash,UserID,DeviceRegistrationID,SourceTokenHash,PasswordFingerprint,RevocationEpoch,CreatedUtc,ExpiresUtc)
  VALUES(@BIOHash,@UserID,@Device,@TokenHash,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),@Epoch,@Now,DATEADD(minute,@MaximumMinutes,@Now));
 END;
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
CREATE OR ALTER PROCEDURE dbo.MobileApi_LoginViaBIO
 @BIOHash binary(32),@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @BIOHash IS NULL OR @TokenHash IS NULL OR @IdleMinutes<1 OR @MaximumMinutes<@IdleMinutes THROW 51700,'Invalid session settings.',1;
 DECLARE @UserID int,@Device int,@Fingerprint binary(32),@Epoch bigint,@Expires datetime2(0),@Source binary(32),
 @Password nvarchar(max),@Active bit,@Deleted bit,@Type int,@EmployeeNumber int,@Now datetime2(0)=SYSUTCDATETIME();
 BEGIN TRY
 BEGIN TRANSACTION;
 -- Resolve first without holding a credential lock; all employee operations lock UsersMembers first.
 SELECT @UserID=UserID FROM dbo.MobileApi_BIOCredentials WHERE BIOHash=@BIOHash;
 IF @UserID IS NULL THROW 51720,'BIOID invalid.',1;
 SELECT @Password=Password,@Active=IsActive,@Deleted=IsDeleted,@Type=Type,@EmployeeNumber=Employee_Number
 FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@UserID;
 SELECT @Device=DeviceRegistrationID,@Fingerprint=PasswordFingerprint,@Epoch=RevocationEpoch,@Expires=ExpiresUtc,@Source=SourceTokenHash
 FROM dbo.MobileApi_BIOCredentials WITH(UPDLOCK,HOLDLOCK) WHERE BIOHash=@BIOHash AND UserID=@UserID;
 IF @Device IS NULL THROW 51720,'BIOID invalid.',1;
 IF @Expires<=@Now THROW 51721,'BIOID expired.',1;
 IF ISNULL(@Deleted,0)=1 THROW 51724,'Account deleted.',1;
 IF ISNULL(@Active,0)=0 THROW 51723,'Account inactive.',1;
 IF @Type IS NULL OR @Type=7 THROW 51727,'Employee login unavailable.',1;
 IF @Password IS NULL OR @Fingerprint<>HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Password)) THROW 51725,'Password changed.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileApi_Devices WHERE ID=@Device AND UserID=@UserID AND IsApproved=1)
  THROW 51726,'Device not approved.',1;
 IF @Epoch<>ISNULL((SELECT MAX(ID) FROM dbo.MobileApi_DeviceHistory WHERE UserID=@UserID
  AND (Action IN('ResetAll','ApproveReplace') OR (Action='Revoke' AND DeviceRegistrationID=@Device))),0)
  THROW 51722,'BIOID revoked.',1;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,
 DeviceRegistrationID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID)
 SELECT @TokenHash,@UserID,@Fingerprint,@Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now),
 @Device,@EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID
 FROM dbo.MobileApi_Sessions WHERE TokenHash=@Source AND UserID=@UserID AND DeviceRegistrationID=@Device;
 IF @@ROWCOUNT<>1 THROW 51720,'BIOID invalid.',1;
 UPDATE dbo.MobileApi_Devices SET LastLoginUtc=@Now WHERE ID=@Device;
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
