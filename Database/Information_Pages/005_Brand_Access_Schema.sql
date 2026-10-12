-- Run inside Apply.ps1's transaction. Existing pages are assigned only on first creation.
IF OBJECT_ID('dbo.Information_Page_Brands','U') IS NULL
BEGIN
 DECLARE @Prosto int;
 IF EXISTS(SELECT 1 FROM dbo.Information_Pages)
 BEGIN
  IF (SELECT COUNT(*) FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
      AND (LTRIM(RTRIM(Title_Ar))=N'بروستو' OR LTRIM(RTRIM(Title_En))=N'Prosto'))<>1
   THROW 51600,N'تعذر تحديد علامة بروستو بشكل فريد لترحيل الصفحات الحالية.',1;
  SELECT @Prosto=ID FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
   AND (LTRIM(RTRIM(Title_Ar))=N'بروستو' OR LTRIM(RTRIM(Title_En))=N'Prosto');
 END;
 CREATE TABLE dbo.Information_Page_Brands(
  PageID int NOT NULL REFERENCES dbo.Information_Pages(ID),
  BrandID int NOT NULL REFERENCES dbo.Brands(ID),
  CONSTRAINT PK_Information_Page_Brands PRIMARY KEY(PageID,BrandID)
 );
 CREATE INDEX IX_Information_Page_Brands_Brand ON dbo.Information_Page_Brands(BrandID,PageID);
 INSERT dbo.Information_Page_Brands(PageID,BrandID) SELECT ID,@Prosto FROM dbo.Information_Pages;
 UPDATE dbo.Information_Pages SET AccessRevision=AccessRevision+1;
 INSERT dbo.Information_Page_Logs(PageID,VersionNumber,Action,ActorID,ActorName,OccurredUtc,Details)
 SELECT ID,VersionNumber,'access',0,N'ترحيل ربط العلامات التجارية',SYSUTCDATETIME(),
 N'ربط الصفحة الحالية بعلامة بروستو؛ لم يتغير المحتوى أو أنواع المستخدمين.' FROM dbo.Information_Pages;
END;
