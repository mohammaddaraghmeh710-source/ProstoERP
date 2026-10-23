-- Additive English content; Details remains the Arabic/legacy field. Omitted English saves preserve it.
IF COL_LENGTH('dbo.News','Details_EN') IS NULL ALTER TABLE dbo.News ADD Details_EN nvarchar(max) NULL;
GO
CREATE OR ALTER PROCEDURE dbo.News_AdminSave
 @Actor int,@BrandID int,@PID int=NULL,@Title_AR nvarchar(max)=NULL,@Title_En nvarchar(max)=NULL,
 @Brief_Ar nvarchar(max)=NULL,@Brief_En nvarchar(max)=NULL,@Details nvarchar(max)=NULL,@Image nvarchar(max)=NULL,
 @Date datetime=NULL,@Item_Order int=NULL,@IsActive bit=1,@Details_EN nvarchar(max)=NULL
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51950,'Administrator required.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51951,'Active brand required.',1;
 IF @PID IS NULL BEGIN
  INSERT dbo.News(Brand_ID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Details_EN,Image,[Date],Item_Order,AddedUser,AddedDate,IsActive,IsDeleted)
   VALUES(@BrandID,@Title_AR,@Title_En,@Brief_Ar,@Brief_En,@Details,ISNULL(@Details_EN,N''),@Image,@Date,@Item_Order,@Actor,GETDATE(),1,0);
  SET @PID=CONVERT(int,SCOPE_IDENTITY());
 END ELSE BEGIN
  UPDATE dbo.News SET Brand_ID=@BrandID,Title_AR=@Title_AR,Title_En=@Title_En,Brief_Ar=@Brief_Ar,Brief_En=@Brief_En,
   Details=@Details,Details_EN=COALESCE(@Details_EN,Details_EN),Image=@Image,[Date]=@Date,Item_Order=@Item_Order,IsActive=@IsActive,ModifyUser=@Actor,ModifyDate=GETDATE()
  WHERE PID=@PID AND ISNULL(IsDeleted,0)=0;
  IF @@ROWCOUNT=0 THROW 51952,'News unavailable.',1;
 END;
 COMMIT;SELECT @PID PID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
