IF OBJECT_ID('dbo.Information_Pages','U') IS NULL
BEGIN
 CREATE TABLE dbo.Information_Pages(
  ID int IDENTITY PRIMARY KEY,
  Title_Ar nvarchar(250) NOT NULL, Title_En nvarchar(250) NOT NULL,
  Summary_Ar nvarchar(2000) NOT NULL, Summary_En nvarchar(2000) NOT NULL,
  Details_Ar nvarchar(max) NOT NULL, Details_En nvarchar(max) NOT NULL,
  Item_Order int NOT NULL DEFAULT 0,
  IsPublished bit NOT NULL DEFAULT 0, PublishMode varchar(10) NOT NULL DEFAULT 'immediate',
  StartUtc datetime2(0) NULL, EndUtc datetime2(0) NULL,
  IsDeleted bit NOT NULL DEFAULT 0, VersionNumber int NOT NULL,
  CreatedBy int NOT NULL, CreatedUtc datetime2(0) NOT NULL,
  ModifiedBy int NULL, ModifiedUtc datetime2(0) NULL,
  DeletedBy int NULL, DeletedUtc datetime2(0) NULL,
  CONSTRAINT CK_Information_Pages_Order CHECK(Item_Order>=0),
  CONSTRAINT CK_Information_Pages_Schedule CHECK(
   (PublishMode='immediate' AND StartUtc IS NULL AND EndUtc IS NULL) OR
   (PublishMode='scheduled' AND StartUtc IS NOT NULL AND EndUtc IS NOT NULL AND EndUtc>StartUtc))
 );
 CREATE INDEX IX_Information_Pages_Visible ON dbo.Information_Pages(IsDeleted,IsPublished,Item_Order,ID);
END;
GO
IF OBJECT_ID('dbo.Information_Page_Versions','U') IS NULL
BEGIN
 CREATE TABLE dbo.Information_Page_Versions(
  PageID int NOT NULL REFERENCES dbo.Information_Pages(ID), VersionNumber int NOT NULL,
  Title_Ar nvarchar(250) NOT NULL, Title_En nvarchar(250) NOT NULL,
  Summary_Ar nvarchar(2000) NOT NULL, Summary_En nvarchar(2000) NOT NULL,
  Details_Ar nvarchar(max) NOT NULL, Details_En nvarchar(max) NOT NULL,
  Item_Order int NOT NULL, IsPublished bit NOT NULL, PublishMode varchar(10) NOT NULL,
  StartUtc datetime2(0) NULL, EndUtc datetime2(0) NULL, IsDeleted bit NOT NULL,
  Action varchar(10) NOT NULL, ActorID int NOT NULL,
  ActorName nvarchar(500) NOT NULL, OccurredUtc datetime2(0) NOT NULL,
  CONSTRAINT PK_Information_Page_Versions PRIMARY KEY(PageID,VersionNumber)
 );
END;
GO
IF OBJECT_ID('dbo.Information_Page_Logs','U') IS NULL
BEGIN
 CREATE TABLE dbo.Information_Page_Logs(
  ID bigint IDENTITY PRIMARY KEY, PageID int NOT NULL, VersionNumber int NOT NULL,
  Action varchar(10) NOT NULL CHECK(Action IN('create','update','delete','view','preview')),
  ActorID int NOT NULL, ActorName nvarchar(500) NOT NULL,
  OccurredUtc datetime2(0) NOT NULL, Language varchar(2) NULL,
  CONSTRAINT FK_Information_Page_Logs_Version FOREIGN KEY(PageID,VersionNumber)
   REFERENCES dbo.Information_Page_Versions(PageID,VersionNumber)
 );
 CREATE INDEX IX_Information_Page_Logs_Page ON dbo.Information_Page_Logs(PageID,OccurredUtc DESC,ID DESC);
END;
