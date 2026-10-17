SET XACT_ABORT ON;
IF OBJECT_ID('dbo.Circulars','U') IS NULL
BEGIN
 CREATE TABLE dbo.Circulars(
 ID int IDENTITY PRIMARY KEY,Title nvarchar(250) NOT NULL,Summary nvarchar(2000) NOT NULL,
 CircularDate date NOT NULL,StartUtc datetime2(0) NOT NULL,EndUtc datetime2(0) NOT NULL,
 IsEnabled bit NOT NULL,AllowDownload bit NOT NULL,Audience varchar(16) NOT NULL,
 FileName nvarchar(250) NOT NULL,FileBytes varbinary(max) NOT NULL,Version int NOT NULL DEFAULT 1,
 CreatedBy int NOT NULL REFERENCES dbo.UsersMembers(ID),CreatedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 ModifiedBy int NOT NULL REFERENCES dbo.UsersMembers(ID),ModifiedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT CK_Circular_Dates CHECK(EndUtc>StartUtc),
 CONSTRAINT CK_Circular_Audience CHECK(Audience IN('all','roles','organization')),
 CONSTRAINT CK_Circular_File CHECK(DATALENGTH(FileBytes) BETWEEN 8 AND 10485760));
 CREATE INDEX IX_Circulars_Active ON dbo.Circulars(IsEnabled,StartUtc,EndUtc);
 CREATE TABLE dbo.Circular_Targets(CircularID int NOT NULL REFERENCES dbo.Circulars(ID),
 Kind varchar(16) NOT NULL CHECK(Kind IN('role','brand','branch','department','shift')),TargetID int NOT NULL,
 PRIMARY KEY(CircularID,Kind,TargetID));
 CREATE TABLE dbo.Circular_Reads(CircularID int NOT NULL REFERENCES dbo.Circulars(ID),Version int NOT NULL,
 UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),FirstReadUtc datetime2(0) NOT NULL,LastReadUtc datetime2(0) NOT NULL,
 PRIMARY KEY(CircularID,Version,UserID));
 CREATE TABLE dbo.Circular_Logs(ID bigint IDENTITY PRIMARY KEY,CircularID int NOT NULL REFERENCES dbo.Circulars(ID),
 Version int NOT NULL,TitleSnapshot nvarchar(250) NOT NULL,UserID int NOT NULL REFERENCES dbo.UsersMembers(ID),
 EmployeeNumber int NULL,Action varchar(16) NOT NULL CHECK(Action IN('create','update','view','download','preview')),
 Source varchar(10) NOT NULL CHECK(Source IN('Portal','Mobile')),
 EventID uniqueidentifier NOT NULL,OccurredAtUtc datetime2(0) NULL,RecordedUtc datetime2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
 DeviceID nvarchar(128) NULL,AppVersion nvarchar(50) NULL,
 CONSTRAINT UQ_Circular_Event UNIQUE(UserID,EventID));
 CREATE INDEX IX_CircularLogs_Request ON dbo.Circular_Logs(CircularID,ID DESC);
END;
GO
CREATE OR ALTER FUNCTION dbo.Circular_Visible(@Actor int,@Now datetime2(0))
RETURNS TABLE AS RETURN(
 SELECT c.ID FROM dbo.Circulars c JOIN dbo.UsersMembers u ON u.ID=@Actor
 WHERE u.IsActive=1 AND ISNULL(u.IsDeleted,0)=0 AND c.IsEnabled=1 AND c.StartUtc<=@Now AND @Now<c.EndUtc
 AND (c.Audience='all' OR (c.Audience='roles' AND EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind='role' AND t.TargetID=u.Type))
 OR (c.Audience='organization' AND NOT EXISTS(
 SELECT 1 FROM (VALUES('brand',u.Brand_ID),('branch',u.Branch_ID),('department',u.Department_ID),('shift',u.Shif_ID)) v(Kind,Value)
 WHERE EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind=v.Kind)
 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Targets t WHERE t.CircularID=c.ID AND t.Kind=v.Kind AND t.TargetID=v.Value))))
);
GO
