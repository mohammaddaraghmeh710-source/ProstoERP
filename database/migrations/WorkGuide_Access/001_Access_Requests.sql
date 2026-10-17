-- Execute GO-separated batches on one connection inside a transaction.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID(N'dbo.Work_Guide_Access_Requests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Work_Guide_Access_Requests (
        ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Work_Guide_Access_Requests PRIMARY KEY,
        Batch_ID uniqueidentifier NOT NULL,
        User_ID int NOT NULL REFERENCES dbo.UsersMembers(ID),
        Brand_ID int NOT NULL REFERENCES dbo.Brands(ID),
        Category_ID int NOT NULL REFERENCES dbo.Work_Guide_Categories(ID),
        Category_Path nvarchar(max) NULL,
        Reason nvarchar(1000) NOT NULL,
        Status char(1) NOT NULL CONSTRAINT DF_WG_Request_Status DEFAULT ('P'),
        Assigned_Role_ID int NULL REFERENCES dbo.Work_Guide_Roles(ID),
        AddedDate datetime NOT NULL CONSTRAINT DF_WG_Request_Date DEFAULT (GETDATE()),
        ReviewedBy int NULL REFERENCES dbo.UsersMembers(ID),
        ReviewedDate datetime NULL,
        ReviewNote nvarchar(1000) NULL,
        CONSTRAINT CK_WG_Request_State CHECK (
            (Status = 'P' AND Assigned_Role_ID IS NULL AND ReviewedBy IS NULL AND ReviewedDate IS NULL) OR
            (Status = 'A' AND Assigned_Role_ID IS NOT NULL AND ReviewedBy IS NOT NULL AND ReviewedDate IS NOT NULL) OR
            (Status = 'R' AND Assigned_Role_ID IS NULL AND ReviewedBy IS NOT NULL AND ReviewedDate IS NOT NULL)),
        CONSTRAINT CK_WG_Request_Reason CHECK (LEN(LTRIM(RTRIM(Reason))) > 0)
    );
    CREATE UNIQUE INDEX UX_WG_Request_Pending ON dbo.Work_Guide_Access_Requests(User_ID, Brand_ID, Category_ID) WHERE Status = 'P';
    CREATE INDEX IX_WG_Request_Batch ON dbo.Work_Guide_Access_Requests(Batch_ID, ID);
    CREATE INDEX IX_WG_Request_Review ON dbo.Work_Guide_Access_Requests(Status, AddedDate DESC);
END;
IF COL_LENGTH('dbo.Work_Guide_Access_Requests','Category_Path') IS NULL
    ALTER TABLE dbo.Work_Guide_Access_Requests ADD Category_Path nvarchar(max) NULL;
GO
CREATE OR ALTER FUNCTION dbo.Work_Guide_Effective_Categories(@User_ID int, @Brand_ID int)
RETURNS TABLE
AS RETURN (
    WITH Tree AS (
        SELECT c.ID, c.Brand_ID, c.Parent_ID, c.Title_Ar, c.Title_En, c.Item_Order, 0 AS Level_No,
               CAST(COALESCE(c.Title_Ar,c.Title_En,N'') AS nvarchar(max)) AS Full_Path_Ar,
               CAST('/' + CONVERT(varchar(12),c.ID) + '/' AS varchar(max)) AS ID_Path,
               CAST(RIGHT('0000000000'+CONVERT(varchar(10),ISNULL(c.Item_Order,999999)),10)+'-'+RIGHT('0000000000'+CONVERT(varchar(10),c.ID),10) AS varchar(max)) AS Sort_Path
        FROM dbo.Work_Guide_Categories c
        WHERE c.Brand_ID=@Brand_ID AND c.Parent_ID IS NULL AND ISNULL(c.IsDeleted,0)=0 AND ISNULL(c.IsActive,1)=1
        UNION ALL
        SELECT c.ID,c.Brand_ID,c.Parent_ID,c.Title_Ar,c.Title_En,c.Item_Order,t.Level_No+1,
               CAST(t.Full_Path_Ar+N' / '+COALESCE(c.Title_Ar,c.Title_En,N'') AS nvarchar(max)),
               CAST(t.ID_Path+CONVERT(varchar(12),c.ID)+'/' AS varchar(max)),
               CAST(t.Sort_Path+'.'+RIGHT('0000000000'+CONVERT(varchar(10),ISNULL(c.Item_Order,999999)),10)+'-'+RIGHT('0000000000'+CONVERT(varchar(10),c.ID),10) AS varchar(max))
        FROM dbo.Work_Guide_Categories c JOIN Tree t ON c.Parent_ID=t.ID
        WHERE c.Brand_ID=@Brand_ID AND ISNULL(c.IsDeleted,0)=0 AND ISNULL(c.IsActive,1)=1
          AND CHARINDEX('/'+CONVERT(varchar(12),c.ID)+'/',t.ID_Path)=0 AND t.Level_No<99
    )
    SELECT t.ID,t.Brand_ID,t.Parent_ID,t.Title_Ar,t.Title_En,t.Item_Order,t.Level_No,t.Sort_Path,t.Full_Path_Ar,
           permission.Role_ID,permission.Role_Title_Ar,permission.Role_Title_En,permission.Role_Code,
           CAST(ISNULL(permission.Can_View_Category,0) AS bit) AS Can_View_Category,
           CAST(ISNULL(permission.Can_View_Document,0) AS bit) AS Can_View_Document,
           CAST(ISNULL(permission.Can_Print_Document,0) AS bit) AS Can_Print_Document,
           CAST(ISNULL(permission.Can_Download_Document,0) AS bit) AS Can_Download_Document
    FROM Tree t
    JOIN dbo.UsersMembers u ON u.ID=@User_ID AND u.Brand_ID=@Brand_ID AND ISNULL(u.IsDeleted,0)=0 AND ISNULL(u.IsActive,0)=1
    OUTER APPLY (
        SELECT TOP (1) r.ID AS Role_ID,r.Title_Ar AS Role_Title_Ar,r.Title_En AS Role_Title_En,r.Code AS Role_Code,
               p.Can_View_Category,p.Can_View_Document,p.Can_Print_Document,p.Can_Download_Document
        FROM dbo.Work_Guide_User_Category_Roles g
        JOIN Tree ancestor ON ancestor.ID=g.Category_ID
        JOIN dbo.Work_Guide_Roles r ON r.ID=g.Role_ID AND ISNULL(r.IsDeleted,0)=0 AND ISNULL(r.IsActive,1)=1
        JOIN dbo.Work_Guide_Role_Permissions p ON p.Role_ID=r.ID
        WHERE g.User_ID=@User_ID AND g.Brand_ID=@Brand_ID AND ISNULL(g.IsDeleted,0)=0 AND ISNULL(g.IsActive,1)=1
          AND (g.Start_Date IS NULL OR g.Start_Date<=GETDATE()) AND (g.End_Date IS NULL OR g.End_Date>=GETDATE())
          AND (g.Category_ID=t.ID OR (ISNULL(g.Apply_To_Children,0)=1 AND t.ID_Path LIKE ancestor.ID_Path+'%'))
        ORDER BY ancestor.Level_No DESC,g.ID DESC,p.ID DESC
    ) permission
);
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Request_Categories @User_ID int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Brand_ID int;
    SELECT @Brand_ID=Brand_ID FROM dbo.UsersMembers WHERE ID=@User_ID AND [Type]=7 AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0;
    IF @Brand_ID IS NULL THROW 51100,N'الحساب غير مخوّل بطلب صلاحيات دليل العمل.',1;
    SELECT c.*,pending.ID AS Pending_Request_ID,
           CAST(CASE WHEN c.Can_View_Document=0 AND pending.ID IS NULL THEN 1 ELSE 0 END AS bit) AS Can_Request
    FROM dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c
    LEFT JOIN dbo.Work_Guide_Access_Requests pending ON pending.User_ID=@User_ID AND pending.Brand_ID=@Brand_ID AND pending.Category_ID=c.ID AND pending.Status='P'
    ORDER BY c.Sort_Path OPTION(MAXRECURSION 100);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Insert_Work_Guide_Access_Request
    @User_ID int, @Category_IDs xml, @Reason nvarchar(1000)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    DECLARE @Brand_ID int,@Batch_ID uniqueidentifier=NEWID();
    SET @Reason=NULLIF(LTRIM(RTRIM(@Reason)),N'');
    IF @Reason IS NULL THROW 51101,N'يرجى توضيح سبب الطلب.',1;
    DECLARE @Selected TABLE(ID int PRIMARY KEY);
    INSERT @Selected SELECT DISTINCT node.value('@id','int') FROM @Category_IDs.nodes('/items/item') x(node);
    IF (SELECT COUNT(*) FROM @Selected) NOT BETWEEN 1 AND 200 THROW 51102,N'حدد من تصنيف واحد إلى 200 تصنيف.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Brand_ID=Brand_ID FROM dbo.UsersMembers WITH (UPDLOCK,HOLDLOCK) WHERE ID=@User_ID AND [Type]=7 AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0;
        IF @Brand_ID IS NULL THROW 51100,N'الحساب غير مخوّل بطلب صلاحيات دليل العمل.',1;
        IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c ON c.ID=s.ID WHERE c.ID IS NULL OR c.Can_View_Document=1)
            THROW 51103,N'بعض التصنيفات غير متاحة للطلب أو لديك صلاحية الوصول إليها بالفعل. حدّث الصفحة.',1;
        IF EXISTS(SELECT 1 FROM dbo.Work_Guide_Access_Requests q WITH (UPDLOCK,HOLDLOCK) JOIN @Selected s ON s.ID=q.Category_ID WHERE q.User_ID=@User_ID AND q.Brand_ID=@Brand_ID AND q.Status='P')
            THROW 51104,N'يوجد طلب معلّق لأحد التصنيفات المحددة. حدّث الصفحة.',1;
        INSERT dbo.Work_Guide_Access_Requests(Batch_ID,User_ID,Brand_ID,Category_ID,Category_Path,Reason)
        SELECT @Batch_ID,@User_ID,@Brand_ID,s.ID,c.Full_Path_Ar,@Reason FROM @Selected s
        JOIN dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c ON c.ID=s.ID;
        COMMIT;
        SELECT @Batch_ID AS Batch_ID, (SELECT COUNT(*) FROM @Selected) AS Requested_Count;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
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
    WHERE (@Type=1 OR q.User_ID=@Actor_ID) AND (@Status IS NULL OR q.Status=@Status)
      AND (@Brand_ID IS NULL OR q.Brand_ID=@Brand_ID) AND (@Batch_ID IS NULL OR q.Batch_ID=@Batch_ID)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword,ISNULL(u.FullName_Ar,N''))>0 OR CHARINDEX(@Keyword,ISNULL(c.Title_Ar,N''))>0)
    ORDER BY q.AddedDate DESC,q.ID DESC OFFSET (CONVERT(bigint,@PageNumber)-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_Request_Roles @Admin_ID int
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Admin_ID AND [Type]=1 AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0)
        THROW 51100,N'غير مخوّل بمراجعة الطلبات.',1;
    SELECT r.ID,r.Title_Ar,CAST(ISNULL(p.Can_View_Document,0) AS bit) AS Can_View_Document,
           CAST(ISNULL(p.Can_Print_Document,0) AS bit) AS Can_Print_Document,
           CAST(ISNULL(p.Can_Download_Document,0) AS bit) AS Can_Download_Document
    FROM dbo.Work_Guide_Roles r CROSS APPLY(SELECT TOP(1) * FROM dbo.Work_Guide_Role_Permissions rp WHERE rp.Role_ID=r.ID ORDER BY rp.ID DESC) p
    WHERE ISNULL(r.IsDeleted,0)=0 AND ISNULL(r.IsActive,1)=1 AND p.Can_View_Document=1 ORDER BY r.Title_Ar;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Review_Work_Guide_Access_Request
    @Admin_ID int, @Batch_ID uniqueidentifier, @Decisions xml
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    DECLARE @Items TABLE(ID int PRIMARY KEY,Decision char(1),Role_ID int NULL,Note nvarchar(1000));
    INSERT @Items SELECT n.value('@id','int'),n.value('@status','char(1)'),NULLIF(n.value('@role','int'),0),NULLIF(LTRIM(RTRIM(n.value('@note','nvarchar(1000)'))),N'') FROM @Decisions.nodes('/items/item') x(n);
    IF (SELECT COUNT(*) FROM @Items) NOT BETWEEN 1 AND 200 OR EXISTS(SELECT 1 FROM @Items WHERE Decision NOT IN('A','R') OR (Decision='A' AND Role_ID IS NULL) OR (Decision='R' AND Note IS NULL))
        THROW 51105,N'حدد دورًا لكل موافقة وسببًا لكل رفض.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH (HOLDLOCK) WHERE ID=@Admin_ID AND [Type]=1 AND ISNULL(IsActive,0)=1 AND ISNULL(IsDeleted,0)=0)
            THROW 51100,N'غير مخوّل بمراجعة الطلبات.',1;
        DECLARE @Locked TABLE(ID int PRIMARY KEY,User_ID int,Brand_ID int,Category_ID int,Status char(1));
        INSERT @Locked SELECT q.ID,q.User_ID,q.Brand_ID,q.Category_ID,q.Status FROM dbo.Work_Guide_Access_Requests q WITH(UPDLOCK,HOLDLOCK) JOIN @Items i ON i.ID=q.ID WHERE q.Batch_ID=@Batch_ID;
        IF (SELECT COUNT(*) FROM @Locked)<>(SELECT COUNT(*) FROM @Items) OR EXISTS(SELECT 1 FROM @Locked WHERE Status<>'P')
            THROW 51106,N'تغيّرت حالة أحد الطلبات أو لا ينتمي لهذه المجموعة. حدّث الصفحة.',1;
        IF EXISTS(SELECT 1 FROM @Locked q JOIN @Items i ON i.ID=q.ID LEFT JOIN dbo.UsersMembers u ON u.ID=q.User_ID AND u.Brand_ID=q.Brand_ID AND u.[Type]=7 AND ISNULL(u.IsActive,0)=1 AND ISNULL(u.IsDeleted,0)=0 WHERE i.Decision='A' AND u.ID IS NULL)
            THROW 51107,N'الحساب غير فعال أو تغيّرت علامته التجارية؛ لا يمكن منح الصلاحية.',1;
        IF EXISTS(SELECT 1 FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Effective_Categories(q.User_ID,q.Brand_ID) c WHERE c.ID=q.Category_ID))
            THROW 51108,N'أحد التصنيفات غير فعال أو لم يعد ضمن العلامة التجارية.',1;
        IF EXISTS(SELECT 1 FROM @Items i WHERE i.Decision='A' AND NOT EXISTS(SELECT 1 FROM dbo.Work_Guide_Roles r WITH(HOLDLOCK) JOIN dbo.Work_Guide_Role_Permissions p WITH(HOLDLOCK) ON p.Role_ID=r.ID WHERE r.ID=i.Role_ID AND ISNULL(r.IsDeleted,0)=0 AND ISNULL(r.IsActive,1)=1 AND p.Can_View_Document=1 AND p.ID=(SELECT MAX(p2.ID) FROM dbo.Work_Guide_Role_Permissions p2 WHERE p2.Role_ID=r.ID)))
            THROW 51109,N'اختر دورًا فعالًا يسمح بعرض الوثائق.',1;
        -- Replace the direct grant for each approved category. Ancestors and siblings are unchanged.
        UPDATE g SET IsActive=0,ModifyUser=@Admin_ID,ModifyDate=GETDATE()
        FROM dbo.Work_Guide_User_Category_Roles g WITH(UPDLOCK,HOLDLOCK)
        JOIN @Locked q ON q.User_ID=g.User_ID AND q.Brand_ID=g.Brand_ID AND q.Category_ID=g.Category_ID
        JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A' AND ISNULL(g.IsDeleted,0)=0;
        INSERT dbo.Work_Guide_User_Category_Roles(User_ID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,AddedUser,AddedDate,IsDeleted,IsActive)
        SELECT q.User_ID,q.Brand_ID,q.Category_ID,i.Role_ID,0,@Admin_ID,GETDATE(),0,1 FROM @Locked q JOIN @Items i ON i.ID=q.ID WHERE i.Decision='A';
        UPDATE q SET Status=i.Decision,Assigned_Role_ID=CASE WHEN i.Decision='A' THEN i.Role_ID END,ReviewedBy=@Admin_ID,ReviewedDate=GETDATE(),ReviewNote=i.Note
        FROM dbo.Work_Guide_Access_Requests q JOIN @Items i ON i.ID=q.ID;
        INSERT dbo.Work_Guide_Activity_Logs(User_ID,Brand_ID,Category_ID,Action_Type,Action_Details,AddedDate)
        SELECT @Admin_ID,q.Brand_ID,q.Category_ID,N'AccessRequestReview',CONCAT(N'Request ',q.ID,N': ',i.Decision,N'; role ',i.Role_ID,N'; ',i.Note),GETDATE()
        FROM @Locked q JOIN @Items i ON i.ID=q.ID;
        COMMIT;
        SELECT COUNT(*) AS Reviewed_Count FROM @Items;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_View_Authorized_Categories @User_ID int,@Brand_ID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID,Brand_ID,Parent_ID,Title_Ar,Title_En,Item_Order,Level_No,Sort_Path,Full_Path_Ar,
           CAST(REPLICATE(N'— ',Level_No)+ISNULL(Title_Ar,N'') AS nvarchar(max)) AS Tree_Title_Ar
    FROM dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID)
    WHERE Can_View_Category=1 OR Can_View_Document=1 ORDER BY Sort_Path OPTION(MAXRECURSION 100);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_View_Authorized_Documents
    @User_ID int,@Brand_ID int,@Category_ID int=NULL,@Search_Text nvarchar(500)=NULL,@PageNumber int=1,@PageSize int=20
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search_Text=NULLIF(LTRIM(RTRIM(@Search_Text)),N'');
    IF @PageNumber IS NULL OR @PageNumber<1 SET @PageNumber=1;
    IF @PageSize IS NULL OR @PageSize<1 OR @PageSize>200 SET @PageSize=20;
    SELECT d.ID,d.Brand_ID,d.Category_ID,d.Title_Ar,d.Title_En,d.Description_Ar,d.Description_En,c.Full_Path_Ar AS Category_Title_Ar,d.File_Size,d.AddedDate,
           c.Can_View_Document,CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) AS Can_Download_Document,c.Can_Print_Document,COUNT(*) OVER() AS TotalRows
    FROM dbo.Work_Guide_Documents d JOIN dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c ON c.ID=d.Category_ID
    WHERE d.Brand_ID=@Brand_ID AND ISNULL(d.IsDeleted,0)=0 AND ISNULL(d.IsActive,1)=1 AND c.Can_View_Document=1
      AND (@Category_ID IS NULL OR d.Category_ID=@Category_ID)
      AND (@Search_Text IS NULL OR CHARINDEX(@Search_Text,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Title_En,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Description_Ar,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Description_En,N''))>0 OR CHARINDEX(@Search_Text,c.Full_Path_Ar)>0)
    ORDER BY d.AddedDate DESC,d.ID DESC OFFSET (CONVERT(bigint,@PageNumber)-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY OPTION(MAXRECURSION 100);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Check_Work_Guide_User_Document_Permission @User_ID int,@Document_ID int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Brand_ID int=(SELECT Brand_ID FROM dbo.Work_Guide_Documents WHERE ID=@Document_ID);
    SELECT d.ID AS Document_ID,d.Brand_ID,d.Category_ID,d.Title_Ar,d.Title_En,d.Original_File_Name,d.Stored_File_Name,d.File_Path,d.File_Extension,d.Mime_Type,d.File_Size,d.Version_No,d.Is_Download_Allowed,
           @User_ID AS User_ID,c.Role_ID,c.Role_Title_Ar,c.Role_Title_En,c.Role_Code,c.Can_View_Document,c.Can_Print_Document,
           CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) AS Can_Download_Document
    FROM dbo.Work_Guide_Documents d JOIN dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c ON c.ID=d.Category_ID
    WHERE d.ID=@Document_ID AND d.Brand_ID=@Brand_ID AND ISNULL(d.IsActive,1)=1 AND ISNULL(d.IsDeleted,0)=0 AND c.Can_View_Document=1 OPTION(MAXRECURSION 100);
END;
