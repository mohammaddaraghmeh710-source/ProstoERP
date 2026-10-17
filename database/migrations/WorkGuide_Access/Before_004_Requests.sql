-- Extends request history without changing the existing procedure signature.
CREATE   PROCEDURE dbo.Select_Work_Guide_Access_Requests
    @Actor_ID int, @Status char(1)=NULL, @Brand_ID int=NULL, @Keyword nvarchar(200)=NULL,
    @Batch_ID uniqueidentifier=NULL, @PageNumber int=1, @PageSize int=50
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Type int;
    SELECT @Type=[Type] FROM dbo.UsersMembers WHERE ID=@Actor_ID AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0;
    IF @Type IS NULL OR @Type NOT IN(1,7) THROW 51100,N'غير مخوّل بعرض الطلبات.',1;
    SET @Keyword=NULLIF(LTRIM(RTRIM(@Keyword)),N'');
    IF @PageNumber IS NULL OR @PageNumber<1 SET @PageNumber=1;
    IF @PageSize IS NULL OR @PageSize<1 OR @PageSize>200 SET @PageSize=50;
    SELECT q.ID,q.Batch_ID,q.User_ID,q.Brand_ID,q.Category_ID,q.Reason,q.Status,q.Assigned_Role_ID,q.AddedDate,q.ReviewedBy,q.ReviewedDate,q.ReviewNote,
           u.FullName_Ar AS User_Name,b.Title_Ar AS Brand_Name,COALESCE(q.Category_Path,c.Title_Ar) AS Category_Name,r.Title_Ar AS Role_Name,
           COUNT(*) OVER() AS TotalRows
    FROM dbo.Work_Guide_Access_Requests q
    JOIN dbo.UsersMembers u ON u.ID=q.User_ID
    JOIN dbo.Brands b ON b.ID=q.Brand_ID
    JOIN dbo.Work_Guide_Categories c ON c.ID=q.Category_ID
    LEFT JOIN dbo.Work_Guide_Roles r ON r.ID=q.Assigned_Role_ID
    WHERE (@Type=1 OR q.User_ID=@Actor_ID)
      AND (@Status IS NULL OR q.Status=@Status OR (@Status='H' AND q.Status IN('A','R')))
      AND (@Brand_ID IS NULL OR q.Brand_ID=@Brand_ID) AND (@Batch_ID IS NULL OR q.Batch_ID=@Batch_ID)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword,ISNULL(u.FullName_Ar,N''))>0 OR CHARINDEX(@Keyword,ISNULL(c.Title_Ar,N''))>0)
    ORDER BY q.AddedDate DESC,q.ID DESC OFFSET (CONVERT(bigint,@PageNumber)-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
