SET XACT_ABORT ON;
IF OBJECT_ID('dbo.EmailNotificationSettings','U') IS NULL
 CREATE TABLE dbo.EmailNotificationSettings(BrandID int NOT NULL PRIMARY KEY REFERENCES dbo.Brands(ID),SenderEmail nvarchar(254) NOT NULL,
 AppPassword varbinary(max) NULL,Enabled bit NOT NULL DEFAULT 0,Version rowversion);
GO
CREATE OR ALTER PROCEDURE dbo.EmailNotification_Admin @Actor int,@BrandID int
AS BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51800,'Administrator required.',1;
 SELECT SenderEmail,Enabled,CAST(CASE WHEN AppPassword IS NULL THEN 0 ELSE 1 END AS bit) HasPassword,Version FROM dbo.EmailNotificationSettings WHERE BrandID=@BrandID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.EmailNotification_AdminSecret @Actor int,@BrandID int
AS BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51800,'Administrator required.',1;
 SELECT AppPassword,Version FROM dbo.EmailNotificationSettings WHERE BrandID=@BrandID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.EmailNotification_Save @Actor int,@BrandID int,@SenderEmail nvarchar(254),@AppPassword varbinary(max)=NULL,@Enabled bit,@Version binary(8)=NULL
AS BEGIN SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51800,'Administrator required.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WITH(HOLDLOCK) WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51803,'Brand unavailable.',1;
 IF NULLIF(LTRIM(RTRIM(@SenderEmail)),N'') IS NULL OR @SenderEmail LIKE '%'+CHAR(10)+'%' OR @SenderEmail LIKE '%'+CHAR(13)+'%' THROW 51801,'Sender required.',1;
 DECLARE @Existing binary(8),@OldSender nvarchar(254),@OldPassword varbinary(max);
 SELECT @Existing=Version,@OldSender=SenderEmail,@OldPassword=AppPassword FROM dbo.EmailNotificationSettings WITH(UPDLOCK,HOLDLOCK) WHERE BrandID=@BrandID;
 IF (@Existing IS NULL AND @Version IS NOT NULL) OR (@Existing IS NOT NULL AND (@Version IS NULL OR @Existing<>@Version)) THROW 51802,'Settings changed.',1;
 IF @AppPassword IS NULL AND ((@Enabled=1 AND @OldPassword IS NULL) OR (@OldSender IS NOT NULL AND @OldSender<>@SenderEmail)) THROW 51801,'App password required for enabled/new sender.',1;
 IF @Existing IS NULL INSERT dbo.EmailNotificationSettings(BrandID,SenderEmail,AppPassword,Enabled) VALUES(@BrandID,@SenderEmail,@AppPassword,@Enabled);
 ELSE UPDATE dbo.EmailNotificationSettings SET SenderEmail=@SenderEmail,AppPassword=COALESCE(@AppPassword,AppPassword),Enabled=@Enabled WHERE BrandID=@BrandID;
 COMMIT;END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.EmailNotification_Credentials @BrandID int
AS BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51803,'Brand unavailable.',1;
 SELECT s.SenderEmail,s.AppPassword,s.Enabled,b.Title_Ar BrandName FROM dbo.EmailNotificationSettings s JOIN dbo.Brands b ON b.ID=s.BrandID WHERE s.BrandID=@BrandID;
END;
GO
