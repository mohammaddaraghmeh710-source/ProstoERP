-- Depends on UsersMembers/Brands, Email_Notification/001 and Mobile_API/008.
IF OBJECT_ID('dbo.PasswordReset_Challenges','U') IS NULL
BEGIN
 CREATE TABLE dbo.PasswordReset_Challenges(
  ID uniqueidentifier NOT NULL PRIMARY KEY,EmployeeNumber int NOT NULL,SourceHash binary(32) NOT NULL,
  UserID int NULL REFERENCES dbo.UsersMembers(ID),Email nvarchar(254) NULL,BrandID int NULL,
  PasswordFingerprint binary(32) NULL,OtpHash binary(32) NOT NULL,
  CreatedUtc datetime2(0) NOT NULL,ExpiresUtc datetime2(0) NOT NULL,Sent bit NOT NULL DEFAULT 0,
  Attempts int NOT NULL DEFAULT 0,Verified bit NOT NULL DEFAULT 0,Invalidated bit NOT NULL DEFAULT 0,
  ResetHash binary(32) NULL,ResetExpiresUtc datetime2(0) NULL,UsedUtc datetime2(0) NULL);
 CREATE INDEX IX_PasswordReset_Employee ON dbo.PasswordReset_Challenges(EmployeeNumber,CreatedUtc);
 CREATE INDEX IX_PasswordReset_Source ON dbo.PasswordReset_Challenges(SourceHash,CreatedUtc);
 CREATE UNIQUE INDEX UX_PasswordReset_Token ON dbo.PasswordReset_Challenges(ResetHash) WHERE ResetHash IS NOT NULL;
END;
IF OBJECT_ID('dbo.PasswordReset_AccountEpoch','U') IS NULL
 CREATE TABLE dbo.PasswordReset_AccountEpoch(UserID int NOT NULL PRIMARY KEY REFERENCES dbo.UsersMembers(ID),Epoch bigint NOT NULL);
GO
CREATE OR ALTER PROCEDURE dbo.PasswordReset_Request @EmployeeNumber int,@ID uniqueidentifier,@OtpHash binary(32),@SourceHash binary(32)
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRAN;
  DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@Count int,@User int,@Email nvarchar(254),@Brand int,@Password nvarchar(max),@Name nvarchar(250),@BrandName nvarchar(250),@Lock int;
  -- Serialize shared client and employee rate limits, including unavailable numbers.
  EXEC @Lock=sys.sp_getapplock @Resource='PasswordReset_RequestLimits',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
  IF @Lock<0 THROW 51900,'Too many requests.',1;
  IF EXISTS(SELECT 1 FROM dbo.PasswordReset_Challenges WHERE EmployeeNumber=@EmployeeNumber AND CreatedUtc>DATEADD(second,-60,@Now))
   OR (SELECT COUNT(*) FROM dbo.PasswordReset_Challenges WHERE EmployeeNumber=@EmployeeNumber AND CreatedUtc>DATEADD(hour,-1,@Now))>=5
   OR (SELECT COUNT(*) FROM dbo.PasswordReset_Challenges WHERE SourceHash=@SourceHash AND CreatedUtc>DATEADD(minute,-15,@Now))>=30
   THROW 51900,'Too many requests.',1;
  SELECT @Count=COUNT(*) FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE Employee_Number=@EmployeeNumber AND ISNULL(IsDeleted,0)=0;
  IF @Count=1 SELECT @User=ID,@Email=Email,@Brand=Brand_ID,@Password=Password,@Name=FullName_Ar FROM dbo.UsersMembers
   WHERE Employee_Number=@EmployeeNumber AND ISNULL(IsDeleted,0)=0 AND IsActive=1 AND Type<>7;
  INSERT dbo.PasswordReset_Challenges(ID,EmployeeNumber,SourceHash,UserID,Email,BrandID,PasswordFingerprint,OtpHash,CreatedUtc,ExpiresUtc)
   VALUES(@ID,@EmployeeNumber,@SourceHash,@User,@Email,@Brand,HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Password)),@OtpHash,@Now,DATEADD(minute,10,@Now));
  UPDATE dbo.PasswordReset_Challenges SET Invalidated=1 WHERE UserID=@User AND ID<>@ID AND UsedUtc IS NULL;
  SELECT @BrandName=Title_Ar FROM dbo.Brands WHERE ID=@Brand AND IsActive=1 AND ISNULL(IsDeleted,0)=0;
  COMMIT;
  SELECT @User UserID,@Email Email,@Brand BrandID,@Name EmployeeName,@BrandName BrandName;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.PasswordReset_Delivery @ID uniqueidentifier,@Sent bit
AS BEGIN SET NOCOUNT ON;
 UPDATE dbo.PasswordReset_Challenges SET Sent=@Sent,Invalidated=CASE WHEN @Sent=0 THEN 1 ELSE Invalidated END WHERE ID=@ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.PasswordReset_Verify @ID uniqueidentifier,@OtpHash binary(32),@ResetHash binary(32)
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@Now datetime2(0)=SYSUTCDATETIME(),@Hash binary(32),@Attempts int,@Valid bit=0;
 SELECT @User=UserID FROM dbo.PasswordReset_Challenges WHERE ID=@ID;
 -- Lock user first, consistently with mobile session/device operations.
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @Hash=c.OtpHash,@Attempts=c.Attempts,@Valid=1 FROM dbo.PasswordReset_Challenges c WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.UsersMembers u ON u.ID=c.UserID JOIN dbo.Brands b ON b.ID=u.Brand_ID
 WHERE c.ID=@ID AND c.Sent=1 AND c.Invalidated=0 AND c.Verified=0 AND c.UsedUtc IS NULL AND c.ExpiresUtc>@Now AND c.Attempts<5
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 AND u.Employee_Number=c.EmployeeNumber AND u.Brand_ID=c.BrandID AND u.Email COLLATE Latin1_General_100_BIN2=c.Email COLLATE Latin1_General_100_BIN2
 AND HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))=c.PasswordFingerprint;
 IF @Valid=0 BEGIN COMMIT;THROW 51901,'OTP unavailable or expired.',1;END;
 IF @Hash<>@OtpHash BEGIN
  UPDATE dbo.PasswordReset_Challenges SET Attempts=Attempts+1 WHERE ID=@ID;
  COMMIT;THROW 51902,'Incorrect OTP.',1;
 END;
 UPDATE dbo.PasswordReset_Challenges SET Verified=1,ResetHash=@ResetHash,ResetExpiresUtc=DATEADD(minute,10,@Now) WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.PasswordReset_Complete @ResetHash binary(32),@EncryptedPassword nvarchar(max)
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @User int,@ID uniqueidentifier,@Now datetime2(0)=SYSUTCDATETIME();
 SELECT @User=UserID FROM dbo.PasswordReset_Challenges WHERE ResetHash=@ResetHash;
 SELECT @User=ID FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@User;
 SELECT @ID=c.ID FROM dbo.PasswordReset_Challenges c WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.UsersMembers u ON u.ID=c.UserID JOIN dbo.Brands b ON b.ID=u.Brand_ID
 WHERE c.ResetHash=@ResetHash AND c.Verified=1 AND c.Invalidated=0 AND c.UsedUtc IS NULL AND c.ResetExpiresUtc>@Now
 AND u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND u.Type<>7 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 AND u.Employee_Number=c.EmployeeNumber AND u.Brand_ID=c.BrandID AND u.Email COLLATE Latin1_General_100_BIN2=c.Email COLLATE Latin1_General_100_BIN2
 AND HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password))=c.PasswordFingerprint;
 IF @ID IS NULL BEGIN COMMIT;THROW 51903,'Reset permission unavailable.',1;END;
 IF @EncryptedPassword IS NULL OR LEN(@EncryptedPassword)=0 THROW 51903,'Invalid password.',1;
 UPDATE dbo.UsersMembers SET Password=@EncryptedPassword,ModifyDate=GETDATE(),ModifyUser=@User WHERE ID=@User;
 UPDATE dbo.PasswordReset_Challenges SET UsedUtc=@Now,Invalidated=1 WHERE UserID=@User AND UsedUtc IS NULL;
 UPDATE dbo.PasswordReset_AccountEpoch WITH(UPDLOCK,HOLDLOCK) SET Epoch=Epoch+1 WHERE UserID=@User;
 IF @@ROWCOUNT=0 INSERT dbo.PasswordReset_AccountEpoch(UserID,Epoch) VALUES(@User,1);
 UPDATE dbo.MobileApi_Sessions SET RevokedUtc=COALESCE(RevokedUtc,@Now) WHERE UserID=@User;
 DELETE dbo.MobileApi_BIOCredentials WHERE UserID=@User;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
