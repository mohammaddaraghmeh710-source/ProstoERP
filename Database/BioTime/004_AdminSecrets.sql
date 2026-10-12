-- Run after 003_IntegrationUrlsAndHR.sql. No passwords are inserted or rotated.
CREATE OR ALTER PROCEDURE dbo.AttendanceIntegration_AdminSecrets @Actor int,@BrandID int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51700,'Access denied.',1;
 SELECT ApiPassword,BioPassword,HrPassword,Version FROM dbo.AttendanceIntegrationSettings WHERE BrandID=@BrandID;
END;
GO
