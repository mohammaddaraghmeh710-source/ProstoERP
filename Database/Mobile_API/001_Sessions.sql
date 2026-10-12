-- Apply before 002_Procedures.sql. Tokens are never stored in plaintext.
IF OBJECT_ID('dbo.MobileApi_Sessions','U') IS NULL
BEGIN
 CREATE TABLE dbo.MobileApi_Sessions(
  TokenHash binary(32) NOT NULL CONSTRAINT PK_MobileApi_Sessions PRIMARY KEY,
  UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
  PasswordFingerprint varbinary(32) NOT NULL,
  CreatedUtc datetime2(0) NOT NULL,
  LastSeenUtc datetime2(0) NOT NULL,
  ExpiresUtc datetime2(0) NOT NULL,
  AbsoluteExpiresUtc datetime2(0) NOT NULL,
  RevokedUtc datetime2(0) NULL
 );
 CREATE INDEX IX_MobileApi_Sessions_User ON dbo.MobileApi_Sessions(UserID);
 CREATE INDEX IX_MobileApi_Sessions_Expiry ON dbo.MobileApi_Sessions(ExpiresUtc);
END;
