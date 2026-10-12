

CREATE   PROCEDURE [dbo].[Check_Work_Guide_User_Document_Permission]
    @User_ID INT,
    @Document_ID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Brand_ID INT;
    DECLARE @Category_ID INT;

    SELECT
        @Brand_ID = [Brand_ID],
        @Category_ID = [Category_ID]
    FROM [dbo].[Work_Guide_Documents]
    WHERE
        [ID] = @Document_ID
        AND ISNULL([IsDeleted], 0) = 0
        AND ISNULL([IsActive], 1) = 1;

    ;WITH CategoryAncestors AS
    (
        SELECT
            C.[ID],
            C.[Parent_ID],
            0 AS [Depth]
        FROM [dbo].[Work_Guide_Categories] C
        WHERE
            C.[ID] = @Category_ID
            AND C.[Brand_ID] = @Brand_ID
            AND ISNULL(C.[IsDeleted], 0) = 0
            AND ISNULL(C.[IsActive], 1) = 1

        UNION ALL

        SELECT
            P.[ID],
            P.[Parent_ID],
            CA.[Depth] + 1 AS [Depth]
        FROM [dbo].[Work_Guide_Categories] P
        INNER JOIN CategoryAncestors CA ON CA.[Parent_ID] = P.[ID]
        WHERE
            P.[Brand_ID] = @Brand_ID
            AND ISNULL(P.[IsDeleted], 0) = 0
            AND ISNULL(P.[IsActive], 1) = 1
    )
    SELECT TOP 1
        D.[ID] AS Document_ID,
        D.[Brand_ID],
        D.[Category_ID],
        D.[Title_Ar],
        D.[Title_En],
        D.[Original_File_Name],
        D.[Stored_File_Name],
        D.[File_Path],
        D.[File_Extension],
        D.[Mime_Type],
        D.[File_Size],
        D.[Version_No],
        D.[Is_Download_Allowed],

        UCR.[User_ID],
        UCR.[Role_ID],
        R.[Title_Ar] AS Role_Title_Ar,
        R.[Title_En] AS Role_Title_En,
        R.[Code] AS Role_Code,

        RP.[Can_View_Document],
        RP.[Can_Print_Document],
        RP.[Can_Download_Document]
    FROM CategoryAncestors CA
    INNER JOIN [dbo].[Work_Guide_User_Category_Roles] UCR
        ON UCR.[Category_ID] = CA.[ID]
    INNER JOIN [dbo].[Work_Guide_Roles] R
        ON UCR.[Role_ID] = R.[ID]
    INNER JOIN [dbo].[Work_Guide_Role_Permissions] RP
        ON UCR.[Role_ID] = RP.[Role_ID]
    INNER JOIN [dbo].[Work_Guide_Documents] D
        ON D.[ID] = @Document_ID
    WHERE
        UCR.[User_ID] = @User_ID
        AND UCR.[Brand_ID] = @Brand_ID
        AND ISNULL(UCR.[IsDeleted], 0) = 0
        AND ISNULL(UCR.[IsActive], 1) = 1
        AND ISNULL(R.[IsDeleted], 0) = 0
        AND ISNULL(R.[IsActive], 1) = 1
        AND ISNULL(RP.[Can_View_Document], 0) = 1
        AND (UCR.[Start_Date] IS NULL OR UCR.[Start_Date] <= GETDATE())
        AND (UCR.[End_Date] IS NULL OR UCR.[End_Date] >= GETDATE())
        AND
        (
            CA.[Depth] = 0
            OR ISNULL(UCR.[Apply_To_Children], 0) = 1
        )
    ORDER BY CA.[Depth] ASC;
END

GO

CREATE   PROCEDURE [dbo].[Select_Work_Guide_View_Authorized_Categories]
    @User_ID INT,
    @Brand_ID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH CategoryTree AS
    (
        SELECT
            C.[ID],
            C.[Brand_ID],
            C.[Parent_ID],
            C.[Title_Ar],
            C.[Title_En],
            C.[Item_Order],
            0 AS [Level_No],
            CAST(
                RIGHT('000000' + CAST(ISNULL(C.[Item_Order], 999999) AS NVARCHAR(20)), 6)
                + N'-' +
                RIGHT('000000' + CAST(C.[ID] AS NVARCHAR(20)), 6)
                AS NVARCHAR(MAX)
            ) AS [Sort_Path],
            CAST(C.[Title_Ar] AS NVARCHAR(MAX)) AS [Full_Path_Ar]
        FROM [dbo].[Work_Guide_Categories] C
        WHERE
            C.[Brand_ID] = @Brand_ID
            AND C.[Parent_ID] IS NULL
            AND ISNULL(C.[IsDeleted], 0) = 0
            AND ISNULL(C.[IsActive], 1) = 1

        UNION ALL

        SELECT
            C.[ID],
            C.[Brand_ID],
            C.[Parent_ID],
            C.[Title_Ar],
            C.[Title_En],
            C.[Item_Order],
            CT.[Level_No] + 1 AS [Level_No],
            CAST(
                CT.[Sort_Path]
                + N'.' +
                RIGHT('000000' + CAST(ISNULL(C.[Item_Order], 999999) AS NVARCHAR(20)), 6)
                + N'-' +
                RIGHT('000000' + CAST(C.[ID] AS NVARCHAR(20)), 6)
                AS NVARCHAR(MAX)
            ) AS [Sort_Path],
            CAST(CT.[Full_Path_Ar] + N' / ' + C.[Title_Ar] AS NVARCHAR(MAX)) AS [Full_Path_Ar]
        FROM [dbo].[Work_Guide_Categories] C
        INNER JOIN CategoryTree CT ON C.[Parent_ID] = CT.[ID]
        WHERE
            C.[Brand_ID] = @Brand_ID
            AND ISNULL(C.[IsDeleted], 0) = 0
            AND ISNULL(C.[IsActive], 1) = 1
    ),
    AuthorizedCategories AS
    (
        SELECT DISTINCT
            UCR.[Category_ID]
        FROM [dbo].[Work_Guide_User_Category_Roles] UCR
        INNER JOIN [dbo].[Work_Guide_Role_Permissions] RP 
            ON UCR.[Role_ID] = RP.[Role_ID]
        WHERE
            UCR.[User_ID] = @User_ID
            AND UCR.[Brand_ID] = @Brand_ID
            AND ISNULL(UCR.[IsDeleted], 0) = 0
            AND ISNULL(UCR.[IsActive], 1) = 1
            AND
            (
                ISNULL(RP.[Can_View_Category], 0) = 1
                OR ISNULL(RP.[Can_View_Document], 0) = 1
            )
    )
    SELECT
        CT.[ID],
        CT.[Brand_ID],
        CT.[Parent_ID],
        CT.[Title_Ar],
        CT.[Title_En],
        CT.[Item_Order],
        CT.[Level_No],
        CT.[Sort_Path],
        CT.[Full_Path_Ar],
        CASE
            WHEN CT.[Level_No] = 0 THEN CT.[Title_Ar]
            ELSE REPLICATE(N'     ', CT.[Level_No]) + REPLICATE(N'— ', CT.[Level_No]) + CT.[Title_Ar]
        END AS [Tree_Title_Ar]
    FROM CategoryTree CT
    INNER JOIN AuthorizedCategories AC 
        ON CT.[ID] = AC.[Category_ID]
    ORDER BY CT.[Sort_Path]
    OPTION (MAXRECURSION 0);
END

GO

CREATE   PROCEDURE [dbo].[Select_Work_Guide_View_Authorized_Documents]
    @User_ID INT,
    @Brand_ID INT,
    @Category_ID INT = NULL,
    @Search_Text NVARCHAR(500) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SET @Search_Text = NULLIF(LTRIM(RTRIM(@Search_Text)), N'');

    IF @PageNumber IS NULL OR @PageNumber < 1
        SET @PageNumber = 1;

    IF @PageSize IS NULL OR @PageSize < 1
        SET @PageSize = 20;

    ;WITH CategoryTree AS
    (
        SELECT
            C.[ID],
            C.[Brand_ID],
            C.[Parent_ID],
            C.[Title_Ar],
            C.[Title_En],
            0 AS [Level_No],
            CAST(C.[Title_Ar] AS NVARCHAR(MAX)) AS [Full_Path_Ar]
        FROM [dbo].[Work_Guide_Categories] C
        WHERE
            C.[Brand_ID] = @Brand_ID
            AND C.[Parent_ID] IS NULL
            AND ISNULL(C.[IsDeleted], 0) = 0
            AND ISNULL(C.[IsActive], 1) = 1

        UNION ALL

        SELECT
            C.[ID],
            C.[Brand_ID],
            C.[Parent_ID],
            C.[Title_Ar],
            C.[Title_En],
            CT.[Level_No] + 1 AS [Level_No],
            CAST(CT.[Full_Path_Ar] + N' / ' + C.[Title_Ar] AS NVARCHAR(MAX)) AS [Full_Path_Ar]
        FROM [dbo].[Work_Guide_Categories] C
        INNER JOIN CategoryTree CT ON C.[Parent_ID] = CT.[ID]
        WHERE
            C.[Brand_ID] = @Brand_ID
            AND ISNULL(C.[IsDeleted], 0) = 0
            AND ISNULL(C.[IsActive], 1) = 1
    ),
    UserCategoryPermissions AS
    (
        SELECT
            UCR.[Category_ID],
            MAX(CAST(ISNULL(RP.[Can_View_Category], 0) AS INT)) AS [Can_View_Category],
            MAX(CAST(ISNULL(RP.[Can_View_Document], 0) AS INT)) AS [Can_View_Document],
            MAX(CAST(ISNULL(RP.[Can_Print_Document], 0) AS INT)) AS [Can_Print_Document],
            MAX(CAST(ISNULL(RP.[Can_Download_Document], 0) AS INT)) AS [Can_Download_Document]
        FROM [dbo].[Work_Guide_User_Category_Roles] UCR
        INNER JOIN [dbo].[Work_Guide_Role_Permissions] RP 
            ON UCR.[Role_ID] = RP.[Role_ID]
        WHERE
            UCR.[User_ID] = @User_ID
            AND UCR.[Brand_ID] = @Brand_ID
            AND ISNULL(UCR.[IsDeleted], 0) = 0
            AND ISNULL(UCR.[IsActive], 1) = 1
        GROUP BY
            UCR.[Category_ID]
    ),
    AuthorizedDocuments AS
    (
        SELECT
            D.[ID],
            D.[Brand_ID],
            D.[Category_ID],
            D.[Title_Ar],
            D.[Title_En],
            D.[Description_Ar],
            D.[Description_En],
            CT.[Full_Path_Ar] AS [Category_Title_Ar],
            D.[File_Size],
            D.[AddedDate],
            CAST(UCP.[Can_View_Document] AS BIT) AS [Can_View_Document],
            CAST(UCP.[Can_Download_Document] AS BIT) AS [Can_Download_Document],
            CAST(UCP.[Can_Print_Document] AS BIT) AS [Can_Print_Document]
        FROM [dbo].[Work_Guide_Documents] D
        INNER JOIN UserCategoryPermissions UCP 
            ON D.[Category_ID] = UCP.[Category_ID]
        INNER JOIN CategoryTree CT 
            ON D.[Category_ID] = CT.[ID]
        WHERE
            D.[Brand_ID] = @Brand_ID
            AND ISNULL(D.[IsDeleted], 0) = 0
            AND ISNULL(D.[IsActive], 1) = 1
            AND ISNULL(UCP.[Can_View_Document], 0) = 1
            AND (@Category_ID IS NULL OR D.[Category_ID] = @Category_ID)
            AND
            (
                @Search_Text IS NULL
                OR D.[Title_Ar] LIKE N'%' + @Search_Text + N'%'
                OR ISNULL(D.[Title_En], N'') LIKE N'%' + @Search_Text + N'%'
                OR ISNULL(D.[Description_Ar], N'') LIKE N'%' + @Search_Text + N'%'
                OR ISNULL(D.[Description_En], N'') LIKE N'%' + @Search_Text + N'%'
                OR CT.[Full_Path_Ar] LIKE N'%' + @Search_Text + N'%'
            )
    )
    SELECT
        *,
        COUNT(1) OVER() AS [TotalRows]
    FROM AuthorizedDocuments
    ORDER BY
        [AddedDate] DESC,
        [ID] DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (MAXRECURSION 0);
END
