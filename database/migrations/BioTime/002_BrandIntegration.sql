-- Apply to the shared Portal/API database. Additive and rerunnable; no credentials in scripts.
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dbo.AttendanceIntegrationSettings','U') IS NULL
CREATE TABLE dbo.AttendanceIntegrationSettings (
 BrandID int NOT NULL PRIMARY KEY REFERENCES dbo.Brands(ID),
 ApiUsername nvarchar(200) NOT NULL UNIQUE,
 ApiPassword varbinary(max) NOT NULL, ApiSalt binary(32) NOT NULL, ApiHash binary(32) NOT NULL,
 BioUsername varbinary(max) NOT NULL, BioPassword varbinary(max) NOT NULL,
 Enabled bit NOT NULL, ModifiedBy int NOT NULL, ModifiedUtc datetime2 NOT NULL,
 Version rowversion NOT NULL
);
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_Admin @Actor int, @BrandID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51700,'Access denied.',1;
 SELECT ApiUsername,BioUsername,Enabled,Version FROM dbo.AttendanceIntegrationSettings WHERE BrandID=@BrandID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_Save
 @Actor int,@BrandID int,@ApiUsername nvarchar(200),@ApiPassword varbinary(max),@ApiSalt binary(32),@ApiHash binary(32),
 @BioUsername varbinary(max),@BioPassword varbinary(max),@Enabled bit,@Version binary(8)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51700,'Access denied.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51701,'Invalid brand.',1;
 IF LEN(LTRIM(RTRIM(@ApiUsername)))=0 OR CHARINDEX(':',@ApiUsername)>0 OR DATALENGTH(@BioUsername)=0 THROW 51701,'Invalid settings.',1;
 BEGIN TRAN;
 IF EXISTS(SELECT 1 FROM dbo.AttendanceIntegrationSettings WITH(UPDLOCK,HOLDLOCK) WHERE BrandID=@BrandID)
 BEGIN
  UPDATE dbo.AttendanceIntegrationSettings SET ApiUsername=@ApiUsername,ApiPassword=COALESCE(@ApiPassword,ApiPassword),ApiSalt=COALESCE(@ApiSalt,ApiSalt),ApiHash=COALESCE(@ApiHash,ApiHash),BioUsername=@BioUsername,BioPassword=COALESCE(@BioPassword,BioPassword),Enabled=@Enabled,ModifiedBy=@Actor,ModifiedUtc=SYSUTCDATETIME()
  WHERE BrandID=@BrandID AND Version=@Version;
  IF @@ROWCOUNT<>1 BEGIN ROLLBACK; THROW 51702,'Settings changed. Reload.',1; END;
 END
 ELSE
 BEGIN
  IF @Version IS NOT NULL OR @ApiPassword IS NULL OR @BioPassword IS NULL OR @ApiHash IS NULL OR @ApiSalt IS NULL BEGIN ROLLBACK; THROW 51701,'Both passwords required for new settings.',1; END;
  INSERT dbo.AttendanceIntegrationSettings(BrandID,ApiUsername,ApiPassword,ApiSalt,ApiHash,BioUsername,BioPassword,Enabled,ModifiedBy,ModifiedUtc)
  VALUES(@BrandID,@ApiUsername,@ApiPassword,@ApiSalt,@ApiHash,@BioUsername,@BioPassword,@Enabled,@Actor,SYSUTCDATETIME());
 END;
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_Authenticate @ApiUsername nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.AttendanceIntegrationSettings) BEGIN SELECT -1 BrandID; RETURN; END;
 SELECT s.BrandID,s.ApiSalt,s.ApiHash FROM dbo.AttendanceIntegrationSettings s JOIN dbo.Brands b ON b.ID=s.BrandID
 WHERE s.ApiUsername=@ApiUsername AND s.Enabled=1 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_Employee @Actor int,@EmployeeID int=0,@EmployeeCode nvarchar(200)=NULL,@BrandID int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Type<>7) THROW 51700,'Access denied.',1;
 DECLARE @Admin bit=CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1) THEN 1 ELSE 0 END;
 SELECT e.ID,e.Employee_Number,e.FullName_Ar,e.Brand_ID,b.Title_Ar BrandName FROM dbo.UsersMembers e JOIN dbo.Brands b ON b.ID=e.Brand_ID
 WHERE e.IsActive=1 AND ISNULL(e.IsDeleted,0)=0 AND e.Type<>7 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 AND (@EmployeeID=0 OR e.ID=@EmployeeID) AND (@EmployeeCode IS NULL OR CONVERT(nvarchar(200),e.Employee_Number)=@EmployeeCode)
 AND (@BrandID=0 OR e.Brand_ID=@BrandID) AND (@Admin=1 OR e.ID=@Actor);
END;
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_Credentials @Actor int,@EmployeeID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Type<>7 AND (Type=1 OR ID=@EmployeeID)) THROW 51700,'Access denied.',1;
 SELECT s.ApiUsername,s.ApiPassword,s.BioUsername,s.BioPassword FROM dbo.UsersMembers e JOIN dbo.AttendanceIntegrationSettings s ON s.BrandID=e.Brand_ID JOIN dbo.Brands b ON b.ID=e.Brand_ID
 WHERE e.ID=@EmployeeID AND e.IsActive=1 AND ISNULL(e.IsDeleted,0)=0 AND e.Type<>7 AND s.Enabled=1 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_ApiEmployee @BrandID int,@EmployeeCode nvarchar(200)
AS
BEGIN
 SET NOCOUNT ON;
 SELECT TOP(1) ID FROM dbo.UsersMembers WHERE Brand_ID=@BrandID AND CONVERT(nvarchar(200),Employee_Number)=@EmployeeCode AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Type<>7;
END;
GO
