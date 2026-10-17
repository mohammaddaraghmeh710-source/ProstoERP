CREATE OR ALTER PROCEDURE dbo.Circular_Identity @Actor int,@EmployeeNumber int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Employee_Number=@EmployeeNumber AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Employee identity mismatch.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_List @Actor int,@Admin bit=0,@Search nvarchar(250)=N'',@UnreadOnly bit=0,@Page int=1,@PageSize int=20
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1)) THROW 51801,'Access denied.',1;
 IF @Page<1 OR @Page>100000 OR @PageSize<1 OR @PageSize>100 THROW 51800,'Invalid paging.',1;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 SELECT c.ID,c.Title,c.Summary,c.CircularDate,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,
 DATALENGTH(c.FileBytes) FileSizeBytes,c.Version,c.ModifiedUtc,
 CAST(CASE WHEN r.UserID IS NULL THEN 0 ELSE 1 END AS bit) IsRead,r.FirstReadUtc,r.LastReadUtc,
 CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>@Now THEN 'scheduled' WHEN c.EndUtc<=@Now THEN 'expired' ELSE 'active' END Status
 INTO #Items FROM dbo.Circulars c LEFT JOIN dbo.Circular_Reads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.UserID=@Actor
 WHERE (@Admin=1 OR EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) v WHERE v.ID=c.ID))
 AND (@Search=N'' OR CHARINDEX(@Search,c.Title)>0 OR CHARINDEX(@Search,c.Summary)>0);
 SELECT COUNT(*) Total,COALESCE(SUM(CASE WHEN IsRead=0 THEN 1 ELSE 0 END),0) Unread,COALESCE(SUM(CASE WHEN Status='active' THEN 1 ELSE 0 END),0) Active FROM #Items;
 SELECT COUNT(*) TotalItems FROM #Items WHERE @UnreadOnly=0 OR IsRead=0;
 SELECT * FROM #Items WHERE @UnreadOnly=0 OR IsRead=0 ORDER BY IsRead,CircularDate DESC,ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_Detail @Actor int,@ID int,@Admin bit=0
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME();
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1)) THROW 51801,'Access denied.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Circulars WHERE ID=@ID) OR (@Admin=0 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) WHERE ID=@ID)) THROW 51804,'Circular unavailable.',1;
 SELECT c.ID,c.Title,c.Summary,c.CircularDate,c.StartUtc,c.EndUtc,c.IsEnabled,c.AllowDownload,c.Audience,c.FileName,
 DATALENGTH(c.FileBytes) FileSizeBytes,c.Version,c.CreatedUtc,c.ModifiedUtc,
 CAST(CASE WHEN r.UserID IS NULL THEN 0 ELSE 1 END AS bit) IsRead,r.FirstReadUtc,r.LastReadUtc,
 CASE WHEN c.IsEnabled=0 THEN 'disabled' WHEN c.StartUtc>@Now THEN 'scheduled' WHEN c.EndUtc<=@Now THEN 'expired' ELSE 'active' END Status
 FROM dbo.Circulars c LEFT JOIN dbo.Circular_Reads r ON r.CircularID=c.ID AND r.Version=c.Version AND r.UserID=@Actor WHERE c.ID=@ID;
 IF @Admin=1 BEGIN
  SELECT t.Kind,t.TargetID,CASE t.Kind WHEN 'role' THEN r.Title_Ar WHEN 'brand' THEN b.Title_Ar WHEN 'branch' THEN br.Title_Ar WHEN 'department' THEN d.Title_Ar WHEN 'shift' THEN s.Title_Ar END Title
  FROM dbo.Circular_Targets t LEFT JOIN dbo.Users_Types r ON t.Kind='role' AND r.ID=t.TargetID
  LEFT JOIN dbo.Brands b ON t.Kind='brand' AND b.ID=t.TargetID LEFT JOIN dbo.Branches br ON t.Kind='branch' AND br.ID=t.TargetID
  LEFT JOIN dbo.Departments d ON t.Kind='department' AND d.ID=t.TargetID LEFT JOIN dbo.Shift s ON t.Kind='shift' AND s.ID=t.TargetID WHERE t.CircularID=@ID;
 END;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_Lookups @Actor int
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 SELECT 'role' Kind,ID,Title_Ar Title FROM dbo.Users_Types WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'brand',ID,Title_Ar FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'branch',ID,Title_Ar FROM dbo.Branches WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'department',ID,Title_Ar FROM dbo.Departments WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'shift',ID,Title_Ar FROM dbo.Shift WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_Save @Actor int,@ID int=0,@ExpectedVersion int=0,
 @Title nvarchar(250),@Summary nvarchar(2000),@CircularDate date,@StartUtc datetime2(0),@EndUtc datetime2(0),
 @IsEnabled bit,@AllowDownload bit,@Audience varchar(16),@Targets xml,@FileName nvarchar(250)=NULL,@FileBytes varbinary(max)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 DECLARE @Version int,@Now datetime2(0)=SYSUTCDATETIME(),@Event uniqueidentifier=NEWID();
 IF NULLIF(LTRIM(RTRIM(@Title)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(@Summary)),N'') IS NULL OR @EndUtc<=@StartUtc OR @StartUtc IS NULL OR @EndUtc IS NULL OR @CircularDate IS NULL
 OR @Audience IS NULL OR @Audience NOT IN('all','roles','organization') OR @ExpectedVersion IS NULL THROW 51800,'Invalid circular fields.',1;
 IF (@ID=0 AND @FileBytes IS NULL) OR (@FileBytes IS NULL AND @FileName IS NOT NULL) OR (@FileBytes IS NOT NULL AND (@FileName IS NULL OR DATALENGTH(@FileBytes) NOT BETWEEN 8 AND 10485760 OR SUBSTRING(@FileBytes,1,5)<>0x255044462D OR LOWER(RIGHT(@FileName,4))<>'.pdf')) THROW 51800,'A PDF up to 10MB is required.',1;
 DECLARE @Selected TABLE(Kind varchar(16),TargetID int,PRIMARY KEY(Kind,TargetID));
 INSERT @Selected SELECT DISTINCT x.n.value('@kind','varchar(16)'),x.n.value('@id','int') FROM @Targets.nodes('/targets/item') x(n);
 IF (@Audience='all' AND EXISTS(SELECT 1 FROM @Selected)) OR (@Audience<>'all' AND NOT EXISTS(SELECT 1 FROM @Selected))
 OR EXISTS(SELECT 1 FROM @Selected WHERE (@Audience='roles' AND Kind<>'role') OR (@Audience='organization' AND Kind NOT IN('brand','branch','department','shift'))) THROW 51800,'Select a valid audience.',1;
 IF EXISTS(SELECT 1 FROM @Selected t WHERE NOT EXISTS(
 SELECT 1 FROM (SELECT 'role' Kind,ID FROM dbo.Users_Types WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'brand',ID FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'branch',ID FROM dbo.Branches WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'department',ID FROM dbo.Departments WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0
 UNION ALL SELECT 'shift',ID FROM dbo.Shift WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0) a WHERE a.Kind=t.Kind AND a.ID=t.TargetID)) THROW 51800,'Audience item is inactive or missing.',1;
 IF EXISTS(SELECT 1 FROM @Selected t JOIN dbo.Branches b ON t.Kind='branch' AND b.ID=t.TargetID
 WHERE EXISTS(SELECT 1 FROM @Selected WHERE Kind='brand') AND NOT EXISTS(SELECT 1 FROM @Selected WHERE Kind='brand' AND TargetID=b.BrandID)) THROW 51800,'A selected branch does not belong to the selected brands.',1;
 BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF @ID=0 BEGIN
  INSERT dbo.Circulars(Title,Summary,CircularDate,StartUtc,EndUtc,IsEnabled,AllowDownload,Audience,FileName,FileBytes,CreatedBy,ModifiedBy)
  VALUES(@Title,@Summary,@CircularDate,@StartUtc,@EndUtc,@IsEnabled,@AllowDownload,@Audience,@FileName,@FileBytes,@Actor,@Actor);
  SET @ID=SCOPE_IDENTITY();SET @Version=1;
 END ELSE BEGIN
  SELECT @Version=Version FROM dbo.Circulars WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID;
  IF @Version IS NULL THROW 51804,'Circular unavailable.',1;
  IF @Version<>@ExpectedVersion THROW 51809,'Circular changed. Reload before saving.',1;
  SET @Version=@Version+1;
  UPDATE dbo.Circulars SET Title=@Title,Summary=@Summary,CircularDate=@CircularDate,StartUtc=@StartUtc,EndUtc=@EndUtc,
  IsEnabled=@IsEnabled,AllowDownload=@AllowDownload,Audience=@Audience,FileName=COALESCE(@FileName,FileName),FileBytes=COALESCE(@FileBytes,FileBytes),
  Version=@Version,ModifiedBy=@Actor,ModifiedUtc=@Now WHERE ID=@ID;
 END;
 DELETE dbo.Circular_Targets WHERE CircularID=@ID;
 INSERT dbo.Circular_Targets SELECT @ID,Kind,TargetID FROM @Selected;
 INSERT dbo.Circular_Logs(CircularID,Version,TitleSnapshot,UserID,EmployeeNumber,Action,Source,EventID)
 SELECT @ID,@Version,@Title,@Actor,Employee_Number,CASE WHEN @Version=1 THEN 'create' ELSE 'update' END,'Portal',@Event FROM dbo.UsersMembers WHERE ID=@Actor;
 SELECT @ID ID,@Version Version;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_File @Actor int,@ID int,@Action varchar(16),@Source varchar(10),@EventID uniqueidentifier,
 @OccurredAtUtc datetime2(0)=NULL,@TokenHash binary(32)=NULL,@Admin bit=0
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 DECLARE @Now datetime2(0)=SYSUTCDATETIME(),@Version int,@Title nvarchar(250),@Allow bit,@Employee int,@Device nvarchar(128),@App nvarchar(50);
 IF @Action IS NULL OR @Action NOT IN('view','download') OR @Source IS NULL OR @Source NOT IN('Portal','Mobile') OR @EventID IS NULL OR (@Source='Mobile' AND @Admin=1) THROW 51800,'Invalid file event.',1;
 IF @OccurredAtUtc>DATEADD(minute,5,@Now) OR @OccurredAtUtc<DATEADD(day,-30,@Now) THROW 51800,'Invalid event time.',1;
 BEGIN TRY
 BEGIN TRAN;
 SELECT @Employee=Employee_Number FROM dbo.UsersMembers WITH(UPDLOCK,HOLDLOCK) WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (@Admin=0 OR Type=1);
 IF @@ROWCOUNT=0 THROW 51801,'Access denied.',1;
 IF @Source='Mobile' BEGIN
  SELECT @Device=s.DeviceID,@App=s.AppVersion FROM dbo.MobileApi_Sessions s JOIN dbo.MobileApi_Devices d ON d.ID=s.DeviceRegistrationID AND d.IsApproved=1
  JOIN dbo.UsersMembers u ON u.ID=s.UserID WHERE s.UserID=@Actor AND s.TokenHash=@TokenHash AND s.RevokedUtc IS NULL AND s.ExpiresUtc>@Now AND s.AbsoluteExpiresUtc>@Now
  AND s.PasswordFingerprint=HASHBYTES('SHA2_256',CONVERT(varbinary(max),u.Password));
  IF @@ROWCOUNT=0 THROW 51801,'Invalid device session.',1;
 END;
 SELECT @Version=Version,@Title=Title,@Allow=AllowDownload FROM dbo.Circulars WITH(HOLDLOCK) WHERE ID=@ID;
 IF @Version IS NULL OR (@Admin=0 AND NOT EXISTS(SELECT 1 FROM dbo.Circular_Visible(@Actor,@Now) WHERE ID=@ID)) THROW 51804,'Circular unavailable.',1;
 IF @Action='download' AND @Allow=0 THROW 51803,'Download is not permitted.',1;
 IF @Admin=1 AND @Action='view' SET @Action='preview';
 IF EXISTS(SELECT 1 FROM dbo.Circular_Logs WHERE UserID=@Actor AND EventID=@EventID AND (CircularID<>@ID OR Version<>@Version OR Action<>@Action OR Source<>@Source)) THROW 51809,'EventID already used for another operation.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Circular_Logs WHERE UserID=@Actor AND EventID=@EventID)
 BEGIN
  INSERT dbo.Circular_Logs(CircularID,Version,TitleSnapshot,UserID,EmployeeNumber,Action,Source,EventID,OccurredAtUtc,DeviceID,AppVersion)
  VALUES(@ID,@Version,@Title,@Actor,@Employee,@Action,@Source,@EventID,@OccurredAtUtc,@Device,@App);
  IF @Admin=0 BEGIN
   UPDATE dbo.Circular_Reads SET LastReadUtc=@Now WHERE CircularID=@ID AND Version=@Version AND UserID=@Actor;
   IF @@ROWCOUNT=0 INSERT dbo.Circular_Reads VALUES(@ID,@Version,@Actor,@Now,@Now);
  END;
 END;
 SELECT FileName,FileBytes,@Version Version FROM dbo.Circulars WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;THROW;END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Circular_LogsPage @Actor int,@ID int,@Page int=1,@PageSize int=25
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51801,'Administrator required.',1;
 IF @Page<1 OR @Page>100000 OR @PageSize<1 OR @PageSize>100 THROW 51800,'Invalid paging.',1;
 SELECT COUNT(*) Total FROM dbo.Circular_Logs WHERE CircularID=@ID;
 SELECT l.ID,l.Version,l.TitleSnapshot,l.UserID,l.EmployeeNumber,u.FullName_Ar EmployeeName,l.Action,l.Source,l.OccurredAtUtc,l.RecordedUtc,l.DeviceID,l.AppVersion
 FROM dbo.Circular_Logs l JOIN dbo.UsersMembers u ON u.ID=l.UserID WHERE l.CircularID=@ID ORDER BY l.ID DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
