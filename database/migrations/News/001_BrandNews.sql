-- Additive brand assignment. Legacy news readers/procedures are preserved.
IF COL_LENGTH('dbo.News','Brand_ID') IS NULL ALTER TABLE dbo.News ADD Brand_ID int NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_News_Brand')
 ALTER TABLE dbo.News ADD CONSTRAINT FK_News_Brand FOREIGN KEY(Brand_ID) REFERENCES dbo.Brands(ID);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.News') AND name='IX_News_Brand')
 CREATE INDEX IX_News_Brand ON dbo.News(Brand_ID,IsActive,IsDeleted);
GO
CREATE OR ALTER PROCEDURE dbo.News_AdminSave
 @Actor int,@BrandID int,@PID int=NULL,@Title_AR nvarchar(max)=NULL,@Title_En nvarchar(max)=NULL,
 @Brief_Ar nvarchar(max)=NULL,@Brief_En nvarchar(max)=NULL,@Details nvarchar(max)=NULL,@Image nvarchar(max)=NULL,
 @Date datetime=NULL,@Item_Order int=NULL,@IsActive bit=1
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51950,'Administrator required.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51951,'Active brand required.',1;
 IF @PID IS NULL BEGIN
  INSERT dbo.News(Brand_ID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Image,[Date],Item_Order,AddedUser,AddedDate,IsActive,IsDeleted)
   VALUES(@BrandID,@Title_AR,@Title_En,@Brief_Ar,@Brief_En,@Details,@Image,@Date,@Item_Order,@Actor,GETDATE(),1,0);
  SET @PID=CONVERT(int,SCOPE_IDENTITY());
 END ELSE BEGIN
  UPDATE dbo.News SET Brand_ID=@BrandID,Title_AR=@Title_AR,Title_En=@Title_En,Brief_Ar=@Brief_Ar,Brief_En=@Brief_En,
   Details=@Details,Image=@Image,[Date]=@Date,Item_Order=@Item_Order,IsActive=@IsActive,ModifyUser=@Actor,ModifyDate=GETDATE()
  WHERE PID=@PID AND ISNULL(IsDeleted,0)=0;
  IF @@ROWCOUNT=0 THROW 51952,'News unavailable.',1;
 END;
 COMMIT;SELECT @PID PID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.News_AdminList @Actor int,@Keyword nvarchar(250)=NULL,@IsActive bit=NULL,@BrandID int=NULL
AS BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51950,'Administrator required.',1;
 SELECT n.*,b.Title_Ar BrandName FROM dbo.News n LEFT JOIN dbo.Brands b ON b.ID=n.Brand_ID
 WHERE ISNULL(n.IsDeleted,0)=0 AND (@IsActive IS NULL OR n.IsActive=@IsActive) AND (@BrandID IS NULL OR n.Brand_ID=@BrandID)
 AND (@Keyword IS NULL OR CHARINDEX(@Keyword,ISNULL(n.Title_AR,N''))>0 OR CHARINDEX(@Keyword,ISNULL(n.Title_En,N''))>0
  OR CHARINDEX(@Keyword,ISNULL(n.Brief_Ar,N''))>0 OR CHARINDEX(@Keyword,ISNULL(n.Brief_En,N''))>0)
 ORDER BY n.Item_Order,n.[Date] DESC,n.PID DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.MobileApi_News @Actor int,@BrandID int
AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Brand_ID=@BrandID)
  OR NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
  THROW 51953,'Brand access denied.',1;
 SELECT PID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Image,[Date],Item_Order,AddedUser,AddedDate,ModifyUser,ModifyDate,IsDeleted,IsActive,Brand_ID
 FROM dbo.News WHERE Brand_ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Item_Order,[Date] DESC,PID DESC;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
