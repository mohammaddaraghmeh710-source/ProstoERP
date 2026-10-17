
CREATE   PROCEDURE dbo.Select_Work_Guide_Activity_Logs_Admin
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
