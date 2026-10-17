CREATE OR ALTER FUNCTION dbo.Information_Pages_ForBrand(@Brand int)
RETURNS TABLE
AS RETURN
 SELECT pb.PageID FROM dbo.Information_Page_Brands pb
 JOIN dbo.Brands b ON b.ID=pb.BrandID
 WHERE pb.BrandID=@Brand AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Information_Page_Brands @Actor int,@ID int=0
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
  THROW 51600,N'إدارة العلامات التجارية لمدير النظام فقط.',1;
 SELECT b.ID,b.Title_Ar,b.Title_En,
 CONVERT(bit,CASE WHEN b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 THEN 1 ELSE 0 END) IsAvailable,
 CONVERT(bit,CASE WHEN pb.BrandID IS NULL THEN 0 ELSE 1 END) IsSelected
 FROM dbo.Brands b LEFT JOIN dbo.Information_Page_Brands pb ON pb.BrandID=b.ID AND pb.PageID=@ID
 WHERE (b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) OR pb.BrandID IS NOT NULL
 ORDER BY b.Title_Ar,b.ID;
END;
