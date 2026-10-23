-- Mobile authentication v1. Requires Mobile_API/008, Password_Reset/001 and Email_Notification/001.
-- Review before deployment. Does not create employees, choose between multiple devices, or send email.
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRAN;
IF OBJECT_ID('dbo.PasswordReset_AccountEpoch','U') IS NULL OR OBJECT_ID('dbo.MobileApi_BIOCredentials','U') IS NULL
 THROW 51969,'Apply the prerequisite mobile/password-reset migrations first.',1;
IF EXISTS(SELECT UserID FROM dbo.MobileApi_Devices WHERE IsApproved=1 GROUP BY UserID HAVING COUNT(*)>1)
 THROW 51969,'Resolve employees with multiple approved devices before enabling single-device authentication.',1;
IF COL_LENGTH('dbo.MobileApi_Devices','OtpVerifiedUtc') IS NULL ALTER TABLE dbo.MobileApi_Devices ADD OtpVerifiedUtc datetime2(0) NULL;
IF COL_LENGTH('dbo.MobileApi_Devices','FCMToken') IS NULL ALTER TABLE dbo.MobileApi_Devices ADD FCMToken nvarchar(4000) NULL,FCMUpdatedUtc datetime2(0) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','FCMToken') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD FCMToken nvarchar(4000) NULL;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.MobileApi_Devices') AND name='UX_MobileApi_OneApprovedDevice')
 CREATE UNIQUE INDEX UX_MobileApi_OneApprovedDevice ON dbo.MobileApi_Devices(UserID) WHERE IsApproved=1;
IF OBJECT_ID('dbo.MobileAuth_Attempts','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileAuth_Attempts(ID bigint IDENTITY PRIMARY KEY,Scope varchar(32) NOT NULL,AccountHash binary(32) NOT NULL,SourceHash binary(32) NOT NULL,CreatedUtc datetime2(0) NOT NULL);
 CREATE INDEX IX_MobileAuth_Account ON dbo.MobileAuth_Attempts(Scope,AccountHash,CreatedUtc);
 CREATE INDEX IX_MobileAuth_Source ON dbo.MobileAuth_Attempts(SourceHash,CreatedUtc);
END;
IF OBJECT_ID('dbo.MobileAuth_Activation','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileAuth_Activation(
 ID uniqueidentifier PRIMARY KEY,UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),Purpose varchar(24) NOT NULL CHECK(Purpose IN('registration','device-replacement')),
 DeviceJson nvarchar(max) NOT NULL CHECK(ISJSON(DeviceJson)=1),Email nvarchar(254) NOT NULL,BrandID int NOT NULL,
 PasswordFingerprint binary(32) NOT NULL,ResetEpoch bigint NOT NULL,OtpHash binary(32) NOT NULL,
 CreatedUtc datetime2(0) NOT NULL,ExpiresUtc datetime2(0) NOT NULL,Sent bit NOT NULL DEFAULT 0,
 Attempts int NOT NULL DEFAULT 0,Invalidated bit NOT NULL DEFAULT 0,UsedUtc datetime2(0) NULL);
 CREATE INDEX IX_MobileAuth_Activation_User ON dbo.MobileAuth_Activation(UserID,CreatedUtc);
END;
IF OBJECT_ID('dbo.MobileAuth_BiometricKeys','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileAuth_BiometricKeys(CredentialID uniqueidentifier PRIMARY KEY,UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),DeviceRegistrationID int NOT NULL UNIQUE REFERENCES dbo.MobileApi_Devices(ID),
 Modulus varchar(684) NOT NULL,Exponent varchar(4) NOT NULL,PasswordFingerprint binary(32) NOT NULL,ResetEpoch bigint NOT NULL,DeviceEpoch bigint NOT NULL,CreatedUtc datetime2(0) NOT NULL,ExpiresUtc datetime2(0) NOT NULL);
 CREATE TABLE dbo.MobileAuth_BiometricChallenges(ID uniqueidentifier PRIMARY KEY,CredentialID uniqueidentifier NOT NULL REFERENCES dbo.MobileAuth_BiometricKeys(CredentialID) ON DELETE CASCADE,
 Binding binary(32) NOT NULL,Challenge nvarchar(512) NOT NULL,ExpiresUtc datetime2(0) NOT NULL);
 CREATE INDEX IX_MobileAuth_BiometricExpiry ON dbo.MobileAuth_BiometricChallenges(ExpiresUtc);
END;
GO
CREATE OR ALTER FUNCTION dbo.MobileAuth_Device(@Json nvarchar(max)) RETURNS TABLE AS RETURN
 SELECT * FROM OPENJSON(@Json) WITH(AppVersion nvarchar(50) '$.AppVersion',AppBuild nvarchar(50) '$.AppBuild',
 DeviceID nvarchar(128) '$.Device.DeviceID',Platform nvarchar(16) '$.Device.Platform',Manufacturer nvarchar(100) '$.Device.Manufacturer',
 Model nvarchar(150) '$.Device.Model',OSVersion nvarchar(50) '$.Device.OSVersion',MACID varchar(17) '$.Device.MACID',FCMToken nvarchar(4000) '$.Device.FCMToken');
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_Limit @Scope varchar(32),@AccountHash binary(32),@SourceHash binary(32)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource='MobileAuth_RateLimits',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
 IF @Lock<0 THROW 51960,'Authentication rate limit.',1;
 DELETE TOP(1000) FROM dbo.MobileAuth_Attempts WHERE CreatedUtc<DATEADD(day,-1,@Now);
 IF (SELECT COUNT(*) FROM dbo.MobileAuth_Attempts WHERE Scope=@Scope AND AccountHash=@AccountHash AND CreatedUtc>DATEADD(minute,-15,@Now))>=CASE WHEN @Scope='activation' THEN 5 ELSE 10 END
 OR (SELECT COUNT(*) FROM dbo.MobileAuth_Attempts WHERE SourceHash=@SourceHash AND CreatedUtc>DATEADD(minute,-15,@Now))>=60
 BEGIN COMMIT; THROW 51960,'Authentication rate limit.',1; END;
 INSERT dbo.MobileAuth_Attempts(Scope,AccountHash,SourceHash,CreatedUtc) VALUES(@Scope,@AccountHash,@SourceHash,@Now);
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_Register @ID uniqueidentifier,@Username nvarchar(250),@EncryptedPassword nvarchar(max),@OtpHash binary(32),@Purpose varchar(24),@DeviceJson nvarchar(max)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @Purpose NOT IN('registration','device-replacement') OR ISJSON(@DeviceJson)<>1 THROW 51962,'Invalid activation.',1;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Email nvarchar(254),@Brand int,@Name nvarchar(250),@BrandName nvarchar(250),@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @User=u.ID,@Email=u.Email,@Brand=u.Brand_ID,@Name=u.FullName_Ar FROM dbo.UsersMembers u WITH(UPDLOCK,HOLDLOCK)
 WHERE u.UserName=@Username AND u.Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7;
 IF @User IS NULL THROW 51965,'Invalid credentials.',1;
 SELECT @BrandName=Title_Ar FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
 IF @BrandName IS NULL OR NULLIF(LTRIM(RTRIM(@Email)),N'') IS NULL THROW 51968,'Recovery contact unavailable.',1;
 IF EXISTS(SELECT 1 FROM dbo.MobileAuth_Activation WHERE UserID=@User AND CreatedUtc>DATEADD(second,-60,@Now)) THROW 51960,'Wait before requesting another code.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileAuth_Device(@DeviceJson) WHERE DeviceID<>N'' AND Platform IN(N'Android',N'iOS') AND Model<>N'' AND OSVersion<>N'' AND AppVersion<>N'' AND FCMToken<>N'') THROW 51962,'Device information required.',1;
 IF @Purpose='registration' AND EXISTS(SELECT 1 FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j
 WHERE d.UserID=@User AND d.IsApproved=1 AND (d.DeviceID<>j.DeviceID COLLATE Latin1_General_100_BIN2 OR d.DevicePlatform<>j.Platform)) THROW 51961,'Another device is registered. Use device replacement.',1;
 UPDATE dbo.MobileAuth_Activation SET Invalidated=1 WHERE UserID=@User AND UsedUtc IS NULL;
 INSERT dbo.MobileAuth_Activation(ID,UserID,Purpose,DeviceJson,Email,BrandID,PasswordFingerprint,ResetEpoch,OtpHash,CreatedUtc,ExpiresUtc)
 VALUES(@ID,@User,@Purpose,@DeviceJson,@Email,@Brand,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),ISNULL((SELECT Epoch FROM dbo.PasswordReset_AccountEpoch WHERE UserID=@User),0),@OtpHash,@Now,DATEADD(minute,10,@Now));
 COMMIT;
 SELECT @Brand BrandID,@Email Email,@Name EmployeeName,@BrandName BrandName;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_Delivery @ID uniqueidentifier,@Sent bit
AS BEGIN SET NOCOUNT ON;
 UPDATE dbo.MobileAuth_Activation SET Sent=@Sent,Invalidated=CASE WHEN @Sent=0 THEN 1 ELSE Invalidated END WHERE ID=@ID AND UsedUtc IS NULL AND Invalidated=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_Verify @ID uniqueidentifier,@OtpHash binary(32),@Purpose varchar(24)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Json nvarchar(max),@Hash binary(32),@Now datetime2(0)=SYSUTCDATETIME(),@Device int;
 SELECT @User=UserID FROM dbo.MobileAuth_Activation WHERE ID=@ID;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @Json=a.DeviceJson,@Hash=a.OtpHash FROM dbo.MobileAuth_Activation a WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.UsersMembers u ON u.ID=a.UserID JOIN dbo.Brands b ON b.ID=u.Brand_ID
 WHERE a.ID=@ID AND a.Purpose=@Purpose AND a.Sent=1 AND a.Invalidated=0 AND a.UsedUtc IS NULL AND a.ExpiresUtc>@Now AND a.Attempts<5
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 AND u.Email COLLATE Latin1_General_100_BIN2=a.Email COLLATE Latin1_General_100_BIN2 AND u.Brand_ID=a.BrandID
 AND HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))=a.PasswordFingerprint
 AND ISNULL((SELECT Epoch FROM dbo.PasswordReset_AccountEpoch WHERE UserID=@User),0)=a.ResetEpoch;
 IF @Json IS NULL BEGIN COMMIT; THROW 51962,'Verification expired or unavailable.',1; END;
 IF @Hash<>@OtpHash BEGIN UPDATE dbo.MobileAuth_Activation SET Attempts=Attempts+1 WHERE ID=@ID; COMMIT; THROW 51962,'Verification failed.',1; END;
 IF @Purpose='registration' AND EXISTS(SELECT 1 FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@Json) j
 WHERE d.UserID=@User AND d.IsApproved=1 AND (d.DeviceID<>j.DeviceID COLLATE Latin1_General_100_BIN2 OR d.DevicePlatform<>j.Platform)) THROW 51961,'Another device is registered.',1;
 -- Atomic replacement: revoke sessions and both old/new biometric credentials before approving one device.
 UPDATE dbo.MobileApi_Devices SET IsApproved=0,OtpVerifiedUtc=NULL,FCMToken=NULL WHERE UserID=@User;
 UPDATE dbo.MobileApi_Sessions SET RevokedUtc=COALESCE(RevokedUtc,@Now) WHERE UserID=@User;
 DELETE dbo.MobileAuth_BiometricKeys WHERE UserID=@User;
 DELETE dbo.MobileApi_BIOCredentials WHERE UserID=@User;
 SELECT @Device=d.ID FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@Json) j
 WHERE d.UserID=@User AND d.DeviceID=j.DeviceID COLLATE Latin1_General_100_BIN2 AND d.DevicePlatform=j.Platform;
 IF @Device IS NULL BEGIN
  INSERT dbo.MobileApi_Devices(UserID,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,AppVersion,AppBuild,MACID)
  SELECT @User,DeviceID,Platform,Manufacturer,Model,OSVersion,AppVersion,AppBuild,MACID FROM dbo.MobileAuth_Device(@Json);
  SET @Device=SCOPE_IDENTITY();
 END;
 UPDATE d SET IsApproved=1,OtpVerifiedUtc=@Now,FCMToken=j.FCMToken,FCMUpdatedUtc=@Now,DeviceManufacturer=j.Manufacturer,DeviceModel=j.Model,OSVersion=j.OSVersion,AppVersion=j.AppVersion,AppBuild=j.AppBuild,MACID=j.MACID
 FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@Json) j WHERE d.ID=@Device;
 UPDATE dbo.MobileApi_DevicePolicy SET AllowNextEnrollment=0 WHERE UserID=@User;
 IF @@ROWCOUNT=0 INSERT dbo.MobileApi_DevicePolicy VALUES(@User,0);
 UPDATE r SET Status='Cancelled',DecidedUtc=@Now,Decision='OtpActivation' FROM dbo.MobileApi_DeviceRequests r JOIN dbo.MobileApi_Devices d ON d.ID=r.DeviceRegistrationID WHERE d.UserID=@User AND r.Status='Pending';
 INSERT dbo.MobileApi_DeviceHistory(UserID,DeviceRegistrationID,Action,ActorID) VALUES(@User,@Device,CASE WHEN @Purpose='device-replacement' THEN 'ApproveReplace' ELSE 'OtpActivated' END,@User);
 UPDATE dbo.MobileAuth_Activation SET UsedUtc=@Now,Invalidated=1 WHERE UserID=@User AND UsedUtc IS NULL;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Login
 @Username nvarchar(250),@EncryptedPassword nvarchar(max),@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int,
 @AppVersion nvarchar(50),@DeviceID nvarchar(128),@DevicePlatform nvarchar(16),@DeviceModel nvarchar(150),@OSVersion nvarchar(50),
 @AppBuild nvarchar(50)=NULL,@DeviceManufacturer nvarchar(100)=NULL,@MACID varchar(17)=NULL,@BIOHash binary(32)=NULL,@FCMToken nvarchar(4000)=NULL
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
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7
 AND EXISTS(SELECT 1 FROM dbo.Brands b WHERE b.ID=u.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0);
 IF @UserID IS NULL BEGIN COMMIT; RETURN; END;

 DECLARE @Device int;
 SELECT @Device=ID FROM dbo.MobileApi_Devices WHERE UserID=@UserID AND DeviceID=@DeviceID COLLATE Latin1_General_100_BIN2 AND DevicePlatform=@DevicePlatform AND IsApproved=1 AND OtpVerifiedUtc IS NOT NULL;
 IF @Device IS NULL THROW 51966,'Activate this device with email verification first.',1;
 IF NULLIF(LTRIM(RTRIM(@FCMToken)),N'') IS NULL THROW 51962,'FCM token required.',1;
 UPDATE dbo.MobileApi_DevicePolicy SET AllowNextEnrollment=0 WHERE UserID=@UserID;
 UPDATE dbo.MobileApi_Devices SET DeviceManufacturer=@DeviceManufacturer,DeviceModel=@DeviceModel,OSVersion=@OSVersion,
 AppVersion=@AppVersion,AppBuild=@AppBuild,MACID=@MACID,FCMToken=@FCMToken,FCMUpdatedUtc=@Now,LastLoginUtc=@Now WHERE ID=@Device;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,
 DeviceRegistrationID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID,FCMToken)
 VALUES(@TokenHash,@UserID,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),
 @Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now),
 @Device,@EmployeeNumber,LTRIM(RTRIM(@AppVersion)),NULLIF(LTRIM(RTRIM(@AppBuild)),N''),LTRIM(RTRIM(@DeviceID)),@DevicePlatform,
 NULLIF(LTRIM(RTRIM(@DeviceManufacturer)),N''),LTRIM(RTRIM(@DeviceModel)),LTRIM(RTRIM(@OSVersion)),@MACID,@FCMToken);
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
 SELECT UserID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID,FCMToken,
 CreatedUtc,ExpiresUtc ExpiresAt,AbsoluteExpiresUtc AbsoluteExpiresAt FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER VIEW dbo.MobileAuth_ValidBiometrics AS
 SELECT k.CredentialID,k.UserID,k.DeviceRegistrationID,k.Modulus,k.Exponent,k.PasswordFingerprint,
 d.DeviceID,d.DevicePlatform,u.Employee_Number EmployeeNumber
 FROM dbo.MobileAuth_BiometricKeys k JOIN dbo.UsersMembers u ON u.ID=k.UserID
 JOIN dbo.MobileApi_Devices d ON d.ID=k.DeviceRegistrationID AND d.UserID=k.UserID
 JOIN dbo.Brands b ON b.ID=u.Brand_ID
 WHERE k.ExpiresUtc>SYSUTCDATETIME() AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7
 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 AND d.IsApproved=1 AND d.OtpVerifiedUtc IS NOT NULL
 AND HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))=k.PasswordFingerprint
 AND ISNULL((SELECT Epoch FROM dbo.PasswordReset_AccountEpoch WHERE UserID=k.UserID),0)=k.ResetEpoch
 AND ISNULL((SELECT MAX(ID) FROM dbo.MobileApi_DeviceHistory WHERE UserID=k.UserID AND
 (Action IN('ResetAll','ApproveReplace') OR (Action='Revoke' AND DeviceRegistrationID=k.DeviceRegistrationID))),0)=k.DeviceEpoch;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_EnrollBiometric @CredentialID uniqueidentifier,@TokenHash binary(32),@EncryptedPassword nvarchar(max),@Modulus varchar(684),@Exponent varchar(4)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Device int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @User=UserID FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @Device=d.ID FROM dbo.MobileApi_Sessions s JOIN dbo.UsersMembers u ON u.ID=s.UserID
 JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.UserID=s.UserID
 WHERE s.TokenHash=@TokenHash AND s.UserID=@User AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND d.IsApproved=1 AND d.OtpVerifiedUtc IS NOT NULL
 AND u.Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2 AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password));
 IF @Device IS NULL THROW 51965,'Reauthentication required.',1;
 DELETE dbo.MobileAuth_BiometricKeys WHERE DeviceRegistrationID=@Device;
 INSERT dbo.MobileAuth_BiometricKeys(CredentialID,UserID,DeviceRegistrationID,Modulus,Exponent,PasswordFingerprint,ResetEpoch,DeviceEpoch,CreatedUtc,ExpiresUtc)
 VALUES(@CredentialID,@User,@Device,@Modulus,@Exponent,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),
 ISNULL((SELECT Epoch FROM dbo.PasswordReset_AccountEpoch WHERE UserID=@User),0),
 ISNULL((SELECT MAX(ID) FROM dbo.MobileApi_DeviceHistory WHERE UserID=@User AND (Action IN('ResetAll','ApproveReplace') OR (Action='Revoke' AND DeviceRegistrationID=@Device))),0),@Now,DATEADD(day,90,@Now));
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_BiometricChallenge @ID uniqueidentifier,@CredentialID uniqueidentifier,@Binding binary(32),@Challenge nvarchar(512),@DeviceID nvarchar(128),@Platform nvarchar(16)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int;
 SELECT @User=UserID FROM dbo.MobileAuth_BiometricKeys WHERE CredentialID=@CredentialID;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 IF NOT EXISTS(SELECT 1 FROM dbo.MobileAuth_ValidBiometrics WHERE CredentialID=@CredentialID AND DeviceID=@DeviceID COLLATE Latin1_General_100_BIN2 AND DevicePlatform=@Platform) THROW 51964,'Biometric credential unavailable.',1;
 DELETE dbo.MobileAuth_BiometricChallenges WHERE CredentialID=@CredentialID;
 INSERT dbo.MobileAuth_BiometricChallenges VALUES(@ID,@CredentialID,@Binding,@Challenge,DATEADD(second,120,SYSUTCDATETIME()));
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_ConsumeBiometric @ID uniqueidentifier,@CredentialID uniqueidentifier,@Binding binary(32)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int; DECLARE @Result TABLE(Modulus varchar(684),Exponent varchar(4),Challenge nvarchar(512));
 SELECT @User=UserID FROM dbo.MobileAuth_BiometricKeys WHERE CredentialID=@CredentialID;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 DELETE c OUTPUT k.Modulus,k.Exponent,deleted.Challenge INTO @Result
 FROM dbo.MobileAuth_BiometricChallenges c JOIN dbo.MobileAuth_ValidBiometrics k ON k.CredentialID=c.CredentialID
 WHERE c.ID=@ID AND c.CredentialID=@CredentialID AND c.Binding=@Binding AND c.ExpiresUtc>SYSUTCDATETIME();
 COMMIT;
 SELECT * FROM @Result;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_BiometricLogin @CredentialID uniqueidentifier,@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int,@DeviceJson nvarchar(max)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @IdleMinutes<1 OR @MaximumMinutes<@IdleMinutes OR ISJSON(@DeviceJson)<>1 THROW 51962,'Invalid authentication request.',1;
 BEGIN TRY BEGIN TRAN;
 DECLARE @UserID int,@Device int,@EmployeeNumber int,@Fingerprint binary(32),@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @UserID=UserID FROM dbo.MobileAuth_BiometricKeys WHERE CredentialID=@CredentialID;
 SELECT @UserID=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@UserID;
 SELECT @Device=k.DeviceRegistrationID,@EmployeeNumber=k.EmployeeNumber,@Fingerprint=k.PasswordFingerprint FROM dbo.MobileAuth_ValidBiometrics k CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j
 WHERE k.CredentialID=@CredentialID AND k.DeviceID=j.DeviceID COLLATE Latin1_General_100_BIN2 AND k.DevicePlatform=j.Platform
 AND NULLIF(j.FCMToken,N'') IS NOT NULL AND NULLIF(j.AppVersion,N'') IS NOT NULL AND NULLIF(j.OSVersion,N'') IS NOT NULL AND NULLIF(j.Model,N'') IS NOT NULL;
 IF @Device IS NULL THROW 51964,'Biometric credential unavailable.',1;
 UPDATE d SET FCMToken=j.FCMToken,FCMUpdatedUtc=@Now,DeviceManufacturer=j.Manufacturer,DeviceModel=j.Model,OSVersion=j.OSVersion,AppVersion=j.AppVersion,AppBuild=j.AppBuild,MACID=j.MACID,LastLoginUtc=@Now
 FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j WHERE d.ID=@Device;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,DeviceRegistrationID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID,FCMToken)
 SELECT @TokenHash,@UserID,@Fingerprint,@Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now),@Device,@EmployeeNumber,AppVersion,AppBuild,DeviceID,Platform,Manufacturer,Model,OSVersion,MACID,FCMToken FROM dbo.MobileAuth_Device(@DeviceJson);
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
 SELECT UserID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID,FCMToken,CreatedUtc,ExpiresUtc ExpiresAt,AbsoluteExpiresUtc AbsoluteExpiresAt FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileAuth_UpdateDevice @TokenHash binary(32),@DeviceJson nvarchar(max)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Device int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @User=UserID FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @Device=d.ID FROM dbo.MobileApi_Sessions s JOIN dbo.UsersMembers u ON u.ID=s.UserID JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.UserID=u.ID
 CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j WHERE s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))
 AND d.IsApproved=1 AND d.OtpVerifiedUtc IS NOT NULL AND d.DeviceID=j.DeviceID COLLATE Latin1_General_100_BIN2 AND d.DevicePlatform=j.Platform AND NULLIF(j.FCMToken,N'') IS NOT NULL;
 IF @Device IS NULL THROW 51966,'Registered device required.',1;
 UPDATE d SET FCMToken=j.FCMToken,FCMUpdatedUtc=@Now,DeviceManufacturer=j.Manufacturer,DeviceModel=j.Model,OSVersion=j.OSVersion,AppVersion=j.AppVersion,AppBuild=j.AppBuild,MACID=j.MACID
 FROM dbo.MobileApi_Devices d CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j WHERE d.ID=@Device;
 UPDATE s SET FCMToken=j.FCMToken FROM dbo.MobileApi_Sessions s CROSS APPLY dbo.MobileAuth_Device(@DeviceJson) j WHERE s.TokenHash=@TokenHash;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_LoginViaBIO @BIOHash binary(32),@TokenHash binary(32),@IdleMinutes int,@MaximumMinutes int
AS BEGIN SET NOCOUNT ON; THROW 51964,'Static BIOID login retired. Use a signed biometric challenge.',1; END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Logout @TokenHash binary(32)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Device int,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @User=UserID FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @Device=DeviceRegistrationID FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash AND UserID=@User;
 UPDATE dbo.MobileApi_Sessions SET RevokedUtc=COALESCE(RevokedUtc,@Now) WHERE UserID=@User AND DeviceRegistrationID=@Device;
 UPDATE dbo.MobileApi_Devices SET FCMToken=NULL,FCMUpdatedUtc=@Now WHERE ID=@Device AND UserID=@User;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_Authenticate @TokenHash binary(32),@IdleMinutes int
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @IdleMinutes<1 THROW 51700,'Invalid session settings.',1;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@User int;
 SELECT @User=UserID FROM dbo.MobileApi_Sessions WHERE TokenHash=@TokenHash;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 UPDATE s SET LastSeenUtc=@Now,ExpiresUtc=CASE WHEN DATEADD(minute,@IdleMinutes,@Now)<s.AbsoluteExpiresUtc THEN DATEADD(minute,@IdleMinutes,@Now) ELSE s.AbsoluteExpiresUtc END
 OUTPUT inserted.UserID,inserted.ExpiresUtc ExpiresAt,inserted.AbsoluteExpiresUtc AbsoluteExpiresAt
 FROM dbo.MobileApi_Sessions s JOIN dbo.UsersMembers u ON u.ID=s.UserID
 JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.UserID=s.UserID AND d.IsApproved=1 AND d.OtpVerifiedUtc IS NOT NULL
 WHERE s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))
 AND EXISTS(SELECT 1 FROM dbo.Brands b WHERE b.ID=u.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0);
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO

COMMIT;
GO
