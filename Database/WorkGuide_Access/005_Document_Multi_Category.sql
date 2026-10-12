CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_View_Documents_Multi
    @User_ID int,@Brand_ID int,@Category_IDs xml=NULL,@Search_Text nvarchar(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Search_Text=NULLIF(LTRIM(RTRIM(@Search_Text)),N'');
    SELECT d.ID,d.Brand_ID,d.Category_ID,d.Title_Ar,d.Title_En,d.Description_Ar,d.Description_En,c.Full_Path_Ar AS Category_Title_Ar,d.File_Size,d.AddedDate,
           c.Can_View_Document,CAST(CASE WHEN ISNULL(d.Is_Download_Allowed,1)=1 THEN c.Can_Download_Document ELSE 0 END AS bit) AS Can_Download_Document,c.Can_Print_Document,COUNT(*) OVER() AS TotalRows
    FROM dbo.Work_Guide_Documents d JOIN dbo.Work_Guide_Effective_Categories(@User_ID,@Brand_ID) c ON c.ID=d.Category_ID
    WHERE d.Brand_ID=@Brand_ID AND ISNULL(d.IsDeleted,0)=0 AND ISNULL(d.IsActive,1)=1 AND c.Can_View_Document=1
      AND (@Category_IDs IS NULL OR @Category_IDs.exist('/items/item')=0 OR d.Category_ID IN (SELECT n.value('@id','int') FROM @Category_IDs.nodes('/items/item') AS x(n)))
      AND (@Search_Text IS NULL OR CHARINDEX(@Search_Text,ISNULL(d.Title_Ar,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Title_En,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Description_Ar,N''))>0 OR CHARINDEX(@Search_Text,ISNULL(d.Description_En,N''))>0 OR CHARINDEX(@Search_Text,c.Full_Path_Ar)>0)
    ORDER BY d.AddedDate DESC,d.ID DESC OPTION(MAXRECURSION 100);
END;
GO
CREATE OR ALTER PROCEDURE dbo.Select_Work_Guide_My_Access_Requests @Actor_ID int,@Status char(1)='P' AS
BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Type IN(1,7)) THROW 51100,N'غير مخول.',1;
 SELECT q.ID,q.Category_ID,COALESCE(q.Category_Path,c.Title_Ar) AS Category_Name,q.AddedDate,q.Status,r.Title_Ar AS Role_Name,q.ReviewNote
 FROM dbo.Work_Guide_Access_Requests q JOIN dbo.Work_Guide_Categories c ON c.ID=q.Category_ID LEFT JOIN dbo.Work_Guide_Roles r ON r.ID=q.Assigned_Role_ID
 WHERE q.User_ID=@Actor_ID AND (q.Status=@Status OR (@Status='H' AND q.Status IN('A','R'))) ORDER BY q.AddedDate DESC,q.ID DESC;
END
GO
