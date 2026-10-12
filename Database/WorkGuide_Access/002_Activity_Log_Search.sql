-- Extends request history without changing the existing procedure signature.
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Access_Requests
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
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Log_Categories
    @Admin_ID int
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Admin_ID AND [Type]=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
        THROW 51100,N'غير مخوّل بعرض سجل دليل العمل.',1;
    -- Keep inactive/deleted categories selectable because their audit history still matters.
    ;WITH Tree AS (
        SELECT c.ID,c.Parent_ID,c.Brand_ID,CONVERT(nvarchar(max),c.Title_Ar) AS Category_Path,
               CONVERT(varchar(max),'/' + CONVERT(varchar(12),c.ID) + '/') AS Visited
        FROM dbo.Work_Guide_Categories c
        WHERE c.Parent_ID IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Categories p WHERE p.ID=c.Parent_ID)
        UNION ALL
        SELECT c.ID,c.Parent_ID,c.Brand_ID,CONVERT(nvarchar(max),t.Category_Path+N' / '+c.Title_Ar),
               CONVERT(varchar(max),t.Visited+CONVERT(varchar(12),c.ID)+'/')
        FROM dbo.Work_Guide_Categories c JOIN Tree t ON c.Parent_ID=t.ID
        WHERE CHARINDEX('/'+CONVERT(varchar(12),c.ID)+'/',t.Visited)=0
    )
    SELECT c.ID,COALESCE(b.Title_Ar,N'بدون علامة تجارية')+N' / '+COALESCE(t.Category_Path,c.Title_Ar,N'تصنيف') AS Category_Name
    FROM dbo.Work_Guide_Categories c
    LEFT JOIN Tree t ON t.ID=c.ID
    LEFT JOIN dbo.Brands b ON b.ID=c.Brand_ID
    ORDER BY Category_Name,c.ID OPTION(MAXRECURSION 32767);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Activity_Logs_Admin
    @Admin_ID int, @User_Name nvarchar(200)=NULL, @Date_From date=NULL, @Date_To date=NULL,
    @Document_Name nvarchar(200)=NULL, @Category_ID int=NULL, @PageNumber int=1, @PageSize int=50
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Admin_ID AND [Type]=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0)
        THROW 51100,N'غير مخوّل بعرض سجل دليل العمل.',1;
    IF @Date_From>@Date_To THROW 51101,N'يجب أن يكون تاريخ البداية قبل تاريخ النهاية أو مساويًا له.',1;
    SET @User_Name=NULLIF(LTRIM(RTRIM(@User_Name)),N'');
    SET @Document_Name=NULLIF(LTRIM(RTRIM(@Document_Name)),N'');
    IF @PageNumber IS NULL OR @PageNumber<1 SET @PageNumber=1;
    IF @PageSize IS NULL OR @PageSize<1 OR @PageSize>200 SET @PageSize=50;
    SELECT l.ID,l.User_ID,l.Category_ID,l.Document_ID,l.AddedDate,l.Action_Type,l.Action_Details,l.IPAddress,
           COALESCE(u.FullName_Ar,u.Fullname_En,N'مستخدم غير متاح') AS User_Name,
           b.Title_Ar AS Brand_Name,c.Title_Ar AS Category_Name,d.Title_Ar AS Document_Name,
           COUNT(*) OVER() AS TotalRows
    FROM dbo.Work_Guide_Activity_Logs l
    LEFT JOIN dbo.UsersMembers u ON u.ID=l.User_ID
    LEFT JOIN dbo.Brands b ON b.ID=l.Brand_ID
    LEFT JOIN dbo.Work_Guide_Categories c ON c.ID=l.Category_ID
    LEFT JOIN dbo.Work_Guide_Documents d ON d.ID=l.Document_ID
    WHERE (@User_Name IS NULL OR CHARINDEX(@User_Name,ISNULL(u.FullName_Ar,N''))>0 OR CHARINDEX(@User_Name,ISNULL(u.Fullname_En,N''))>0)
      AND (@Document_Name IS NULL OR CHARINDEX(@Document_Name,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Document_Name,ISNULL(d.Title_En,N''))>0)
      AND (@Category_ID IS NULL OR l.Category_ID=@Category_ID)
      AND (@Date_From IS NULL OR l.AddedDate>=@Date_From)
      -- Inclusive end day, including 23:59:59, and safe even for 9999-12-31.
      AND (@Date_To IS NULL OR CONVERT(date,l.AddedDate)<=@Date_To)
    ORDER BY l.AddedDate DESC,l.ID DESC
    OFFSET (CONVERT(bigint,@PageNumber)-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
