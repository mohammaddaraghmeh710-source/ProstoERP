-- Add per-login snapshots without changing or revoking existing sessions.
-- NULL device fields identify sessions issued before this migration; never invent device data.
SET XACT_ABORT ON;
IF COL_LENGTH('dbo.MobileApi_Sessions','EmployeeNumber') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD EmployeeNumber int NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','AppVersion') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD AppVersion nvarchar(50) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','AppBuild') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD AppBuild nvarchar(50) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','DeviceID') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD DeviceID nvarchar(128) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','DevicePlatform') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD DevicePlatform nvarchar(16) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','DeviceManufacturer') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD DeviceManufacturer nvarchar(100) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','DeviceModel') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD DeviceModel nvarchar(150) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','OSVersion') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD OSVersion nvarchar(50) NULL;
IF COL_LENGTH('dbo.MobileApi_Sessions','MACID') IS NULL ALTER TABLE dbo.MobileApi_Sessions ADD MACID varchar(17) NULL;
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
 SELECT @UserID=u.ID,@EmployeeNumber=u.Employee_Number FROM dbo.UsersMembers u WITH(HOLDLOCK)
 WHERE u.UserName=@Username AND u.Password COLLATE Latin1_General_100_BIN2=@EncryptedPassword COLLATE Latin1_General_100_BIN2
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0;
 IF @UserID IS NULL BEGIN COMMIT; RETURN; END;
 INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,
 EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID)
 VALUES(@TokenHash,@UserID,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@EncryptedPassword)),
 @Now,@Now,DATEADD(minute,@IdleMinutes,@Now),DATEADD(minute,@MaximumMinutes,@Now),
 @EmployeeNumber,LTRIM(RTRIM(@AppVersion)),NULLIF(LTRIM(RTRIM(@AppBuild)),N''),LTRIM(RTRIM(@DeviceID)),@DevicePlatform,
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
