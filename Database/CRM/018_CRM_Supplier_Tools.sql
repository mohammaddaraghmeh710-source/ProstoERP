-- Run inside the deployment transaction. Infer only brands evidenced by existing tool links.
IF OBJECT_ID('dbo.Suppliers','U') IS NOT NULL AND COL_LENGTH('dbo.JobTitle_Items','SupplierID') IS NOT NULL
EXEC(N'
DECLARE @Actor int=(SELECT TOP(1) ID FROM dbo.UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID);
IF @Actor IS NULL THROW 51201,N''يجب وجود مدير نظام فعال لترحيل الموردين.'',1;
DECLARE @Type int=(SELECT ID FROM dbo.CRM_Account_Types WHERE System_Code=''SUPPLIER'');
DECLARE @Map table(Legacy_ID int PRIMARY KEY,Account_ID int NOT NULL);
DECLARE @Legacy int,@AR nvarchar(200),@Account int,@Brand int,@Before xml,@After xml;
IF EXISTS(SELECT 1 FROM dbo.Suppliers WHERE LEN(Title_Ar)>200 OR LEN(Title_En)>200) THROW 51201,N''اسم مورد قديم أطول من الحد المسموح للعملاء. راجعه قبل الترحيل.'',1;
DECLARE suppliers CURSOR LOCAL FAST_FORWARD FOR SELECT ID,COALESCE(NULLIF(LTRIM(RTRIM(Title_Ar)),N''''),N''مورد قديم #''+CONVERT(nvarchar(20),ID)) FROM dbo.Suppliers ORDER BY ID;
OPEN suppliers;FETCH NEXT FROM suppliers INTO @Legacy,@AR;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Account=NULL;SET @Brand=NULL;
 IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE Normalized_Name=UPPER(LTRIM(RTRIM(@AR))) AND (Account_Type_ID<>@Type OR Account_Type_ID IS NULL OR Is_Deleted=1)) THROW 51201,N''اسم المورد يطابق عميلًا من نوع آخر أو محذوفًا. يجب مراجعة الربط قبل الترحيل.'',1;
 SELECT @Account=ID FROM dbo.CRM_Accounts WHERE Normalized_Name=UPPER(LTRIM(RTRIM(@AR))) AND Account_Type_ID=@Type AND Is_Deleted=0;
 SELECT @Brand=MIN(b.BrandID) FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID WHERE i.SupplierID=@Legacy;
 IF @Account IS NULL BEGIN
  INSERT dbo.CRM_Accounts(Name_AR,Name_EN,Account_Type_ID,Brand_ID,Is_Active,Is_Deleted,AddedUser,AddedDate,Modified_User,Modified_Date)
  SELECT @AR,s.Title_En,@Type,@Brand,ISNULL(s.IsActive,0),ISNULL(s.IsDeleted,0),CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=s.AddedUser) THEN s.AddedUser ELSE @Actor END,ISNULL(s.AddedDate,GETDATE()),CASE WHEN EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=s.ModifyUser) THEN s.ModifyUser END,s.ModifyDate FROM dbo.Suppliers s WHERE s.ID=@Legacy;
  SET @Account=CONVERT(int,SCOPE_IDENTITY());
 END;
 INSERT @Map VALUES(@Legacy,@Account);
 INSERT dbo.CRM_Supplier_Brands(Account_ID,Brand_ID,AddedUser)
 SELECT DISTINCT @Account,b.BrandID,@Actor FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID
 WHERE i.SupplierID=@Legacy AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Supplier_Brands sb WHERE sb.Account_ID=@Account AND sb.Brand_ID=b.BrandID);
 SELECT @Before=(SELECT * FROM dbo.Suppliers WHERE ID=@Legacy FOR XML PATH(''Legacy_Supplier''),TYPE);
 SELECT @After=(SELECT a.ID,a.Name_AR,a.Name_EN,a.Account_Type_ID,a.Brand_ID,a.Is_Active,a.Is_Deleted,(SELECT Brand_ID FROM dbo.CRM_Supplier_Brands WHERE Account_ID=@Account ORDER BY Brand_ID FOR XML PATH(''Brand''),ROOT(''Supplier_Brands''),TYPE) FROM dbo.CRM_Accounts a WHERE a.ID=@Account FOR XML PATH(''row''),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor,@Account,N''Accounts'',@Account,N''ترحيل المورد'',@Before,@After);
 FETCH NEXT FROM suppliers INTO @Legacy,@AR;
END;
CLOSE suppliers;DEALLOCATE suppliers;
IF (SELECT COUNT(*) FROM @Map)<>(SELECT COUNT(*) FROM dbo.Suppliers) THROW 51201,N''فشل التحقق من عدد الموردين المنقولين.'',1;
IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i LEFT JOIN @Map m ON m.Legacy_ID=i.SupplierID WHERE i.SupplierID IS NOT NULL AND (m.Account_ID IS NULL OR (i.Supplier_Account_ID IS NOT NULL AND i.Supplier_Account_ID<>m.Account_ID))) THROW 51201,N''تعذر مطابقة ارتباط الأدوات بالموردين.'',1;
UPDATE i SET Supplier_Account_ID=m.Account_ID FROM dbo.JobTitle_Items i JOIN @Map m ON m.Legacy_ID=i.SupplierID;
IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i JOIN @Map m ON m.Legacy_ID=i.SupplierID WHERE i.Supplier_Account_ID<>m.Account_ID OR i.Supplier_Account_ID IS NULL) THROW 51201,N''فشل التحقق من نقل روابط الأدوات.'',1;
');
GO

IF OBJECT_ID('dbo.FK_JobTitle_Items_Suppliers','F') IS NOT NULL ALTER TABLE dbo.JobTitle_Items DROP CONSTRAINT FK_JobTitle_Items_Suppliers;
IF COL_LENGTH('dbo.JobTitle_Items','SupplierID') IS NOT NULL ALTER TABLE dbo.JobTitle_Items DROP COLUMN SupplierID;
IF OBJECT_ID('dbo.FK_JobTitle_Items_SupplierAccount','F') IS NULL ALTER TABLE dbo.JobTitle_Items WITH CHECK ADD CONSTRAINT FK_JobTitle_Items_SupplierAccount FOREIGN KEY(Supplier_Account_ID) REFERENCES dbo.CRM_Accounts(ID);
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.JobTitle_Items') AND name='IX_JobTitle_Items_SupplierAccount') CREATE INDEX IX_JobTitle_Items_SupplierAccount ON dbo.JobTitle_Items(Supplier_Account_ID);
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Require_Tool_Supplier @Actor_ID int,@Supplier_Account_ID int,@JobTitle_ID int,@Current_Item_ID int=NULL AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'إدارة الأدوات متاحة لمدير النظام فقط.',1;
 DECLARE @Brand int=(SELECT b.BrandID FROM dbo.JobTitles j JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID WHERE j.ID=@JobTitle_ID);
 IF @Brand IS NULL OR @Supplier_Account_ID IS NULL THROW 51201,N'اختر محطة تعريفية وموردًا صحيحين.',1;
 IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i JOIN dbo.JobTitles j ON j.ID=i.JobTitle_ID JOIN dbo.Departments d ON d.ID=j.DepartmentID JOIN dbo.Branches b ON b.ID=d.BranchID JOIN dbo.CRM_Supplier_Brands sb ON sb.Account_ID=i.Supplier_Account_ID AND sb.Brand_ID=@Brand WHERE i.ID=@Current_Item_ID AND i.Supplier_Account_ID=@Supplier_Account_ID AND b.BrandID=@Brand) RETURN;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts a JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID JOIN dbo.CRM_Supplier_Brands sb ON sb.Account_ID=a.ID AND sb.Brand_ID=@Brand JOIN dbo.Brands b ON b.ID=sb.Brand_ID WHERE a.ID=@Supplier_Account_ID AND a.Is_Active=1 AND a.Is_Deleted=0 AND t.System_Code='SUPPLIER' AND t.Is_Active=1 AND t.Is_Deleted=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0) THROW 51201,N'المورد غير فعال أو غير مرتبط بالعلامة التجارية الخاصة بالأداة.',1;
END;
GO
CREATE OR ALTER PROCEDURE [dbo].[Insert_JobTitle_Items]
(
    @JobTitle_ID                INT,
    @Title_Ar                   NVARCHAR(MAX),
    @Title_En                   NVARCHAR(MAX),
    @Tool_Number                NVARCHAR(100) = NULL,
    @Supplier_Account_ID                 INT = NULL,
    @MaintenanceCompanyID       INT = NULL,
    @ItemTypeID                 INT = NULL,
    @Policies_Ar                NVARCHAR(MAX) = NULL,
    @Policies_En                NVARCHAR(MAX) = NULL,
    @Working_Method_Video_Ar    NVARCHAR(MAX) = NULL,
    @Working_Method_Video_En    NVARCHAR(MAX) = NULL,
    @Evaluation_Method_Video_Ar NVARCHAR(MAX) = NULL,
    @Evaluation_Method_Video_En NVARCHAR(MAX) = NULL,
    @AddedUser                  INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY BEGIN TRANSACTION;
    DECLARE @SupplierLock int;
    EXEC @SupplierLock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
    IF @SupplierLock<0 THROW 51201,N'السجل مشغول. أعد المحاولة.',1;
    EXEC dbo.CRM_Require_Tool_Supplier @AddedUser,@Supplier_Account_ID,@JobTitle_ID,NULL;
    DECLARE @Before xml=NULL,@After xml,@SavedID int;

    INSERT INTO [dbo].[JobTitle_Items]
    (
        JobTitle_ID,
        Title_Ar,
        Title_En,
        Tool_Number,
        Supplier_Account_ID,
        MaintenanceCompanyID,
        ItemTypeID,
        Policies_Ar,
        Policies_En,
        Working_Method_Video_Ar,
        Working_Method_Video_En,
        Evaluation_Method_Video_Ar,
        Evaluation_Method_Video_En,
        AddedUser,
        AddedDate,
        IsDeleted,
        IsActive
    )
    VALUES
    (
        @JobTitle_ID,
        @Title_Ar,
        @Title_En,
        @Tool_Number,
        @Supplier_Account_ID,
        @MaintenanceCompanyID,
        @ItemTypeID,
        @Policies_Ar,
        @Policies_En,
        @Working_Method_Video_Ar,
        @Working_Method_Video_En,
        @Evaluation_Method_Video_Ar,
        @Evaluation_Method_Video_En,
        @AddedUser,
        GETDATE(),
        0,
        1
    );
    SET @SavedID=CONVERT(int,SCOPE_IDENTITY());
SELECT @After=(SELECT ID,JobTitle_ID,Title_Ar,Title_En,Tool_Number,Supplier_Account_ID,IsActive AS Is_Active,IsDeleted AS Is_Deleted FROM dbo.JobTitle_Items WHERE ID=@SavedID FOR XML PATH('row'),TYPE);
    INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@AddedUser,NULL,N'JobTitle_Items',@SavedID,N'إضافة أداة',@Before,@After);
    COMMIT;
    SELECT CONVERT(decimal(38,0),@SavedID) AS NewID;
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_All]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.ID,
        jti.JobTitle_ID,
        jti.Title_Ar,
        jti.Title_En,
        jti.Tool_Number,
        jti.Supplier_Account_ID,
        jti.MaintenanceCompanyID,
        jti.ItemTypeID,
        jti.Policies_Ar,
        jti.Policies_En,
        jti.Working_Method_Video_Ar,
        jti.Working_Method_Video_En,
        jti.Evaluation_Method_Video_Ar,
        jti.Evaluation_Method_Video_En,
        jti.AddedUser,
        jti.AddedDate,
        jti.ModifyUser,
        jti.ModifyDate,
        jti.IsDeleted,
        jti.IsActive,
        -- Job Title
        jt.ID       AS JobTitleID,
        jt.Title_Ar AS JobTitle_Title_Ar,
        jt.Title_En AS JobTitle_Title_En,
        -- Department
        d.ID        AS DepartmentID,
        d.Title_Ar  AS Department_Title_Ar,
        d.Title_En  AS Department_Title_En,
        -- Branch
        b.ID        AS BranchID,
        b.Title_Ar  AS Branch_Title_Ar,
        b.Title_En  AS Branch_Title_En,
        -- Brand
        br.ID       AS BrandID,
        br.Title_Ar AS Brand_Title_Ar,
        br.Title_En AS Brand_Title_En,
        -- Other lookups
        s.Name_AR  AS Supplier_Title_Ar,
        s.Name_EN  AS Supplier_Title_En,
        mc.Title_Ar AS Maintenance_Title_Ar,
        mc.Title_En AS Maintenance_Title_En,
        it.Title_Ar AS ItemType_Title_Ar,
        it.Title_En AS ItemType_Title_En
    FROM dbo.JobTitle_Items jti
    LEFT JOIN dbo.JobTitles jt
        ON jt.ID = jti.JobTitle_ID
        AND ISNULL(jt.IsDeleted, 0) = 0
    LEFT JOIN dbo.Departments d
        ON d.ID = jt.DepartmentID
        AND ISNULL(d.IsDeleted, 0) = 0
    LEFT JOIN dbo.Branches b
        ON b.ID = d.BranchID
        AND ISNULL(b.IsDeleted, 0) = 0
    LEFT JOIN dbo.Brands br
        ON br.ID = b.BrandID
        AND ISNULL(br.IsDeleted, 0) = 0
    LEFT JOIN dbo.CRM_Accounts s
        ON s.ID = jti.Supplier_Account_ID
        AND ISNULL(s.Is_Deleted, 0) = 0
    LEFT JOIN dbo.Maintenance_Companies mc
        ON mc.ID = jti.MaintenanceCompanyID
        AND ISNULL(mc.IsDeleted, 0) = 0
    LEFT JOIN dbo.JobTitle_Items_Types it
        ON it.ID = jti.ItemTypeID
        AND ISNULL(it.IsDeleted, 0) = 0
    WHERE ISNULL(jti.IsDeleted, 0) = 0
    ORDER BY jti.ID DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_ByID]
(
    @ID INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.*,
        jt.Title_Ar AS JobTitle_Title_Ar,
        jt.Title_En AS JobTitle_Title_En,
        s.Name_AR  AS Supplier_Title_Ar,
        s.Name_EN  AS Supplier_Title_En,
        mc.Title_Ar AS Maintenance_Title_Ar,
        mc.Title_En AS Maintenance_Title_En,
        it.Title_Ar AS ItemType_Title_Ar,
        it.Title_En AS ItemType_Title_En
    FROM dbo.JobTitle_Items jti
    LEFT JOIN dbo.JobTitles jt ON jt.ID = jti.JobTitle_ID
    LEFT JOIN dbo.CRM_Accounts s ON s.ID = jti.Supplier_Account_ID
    LEFT JOIN dbo.Maintenance_Companies mc ON mc.ID = jti.MaintenanceCompanyID
    LEFT JOIN dbo.JobTitle_Items_Types it ON it.ID = jti.ItemTypeID
    WHERE jti.ID = @ID
      AND ISNULL(jti.IsDeleted,0) = 0;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_ByJobTitle_ID]
(
    @JobTitle_ID INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.*,
        jt.Title_Ar AS JobTitle_Title_Ar,
        jt.Title_En AS JobTitle_Title_En,
        s.Name_AR  AS Supplier_Title_Ar,
        s.Name_EN  AS Supplier_Title_En,
        mc.Title_Ar AS Maintenance_Title_Ar,
        mc.Title_En AS Maintenance_Title_En,
        it.Title_Ar AS ItemType_Title_Ar,
        it.Title_En AS ItemType_Title_En
    FROM dbo.JobTitle_Items jti
    LEFT JOIN dbo.JobTitles jt ON jt.ID = jti.JobTitle_ID
    LEFT JOIN dbo.CRM_Accounts s ON s.ID = jti.Supplier_Account_ID
    LEFT JOIN dbo.Maintenance_Companies mc ON mc.ID = jti.MaintenanceCompanyID
    LEFT JOIN dbo.JobTitle_Items_Types it ON it.ID = jti.ItemTypeID
    WHERE jti.JobTitle_ID = @JobTitle_ID
      AND ISNULL(jti.IsDeleted,0) = 0;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_Filter]
(
    @JobTitle_ID INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.ID,
        jti.JobTitle_ID,
        jti.Title_Ar,
        jti.Title_En,
        jti.Tool_Number,
        jti.Supplier_Account_ID,
        jti.MaintenanceCompanyID,
        jti.ItemTypeID,
        jti.Policies_Ar,
        jti.Policies_En,
        jti.Working_Method_Video_Ar,
        jti.Working_Method_Video_En,
        jti.Evaluation_Method_Video_Ar,
        jti.Evaluation_Method_Video_En,
        jti.AddedUser,
        jti.AddedDate,
        jti.ModifyUser,
        jti.ModifyDate,
        jti.IsDeleted,
        jti.IsActive,
        jt.Title_Ar AS JobTitle_Title_Ar,
        jt.Title_En AS JobTitle_Title_En,
        s.Name_AR  AS Supplier_Title_Ar,
        s.Name_EN  AS Supplier_Title_En,
        mc.Title_Ar AS Maintenance_Title_Ar,
        mc.Title_En AS Maintenance_Title_En,
        it.Title_Ar AS ItemType_Title_Ar,
        it.Title_En AS ItemType_Title_En
    FROM dbo.JobTitle_Items jti
    LEFT JOIN dbo.JobTitles jt ON jt.ID = jti.JobTitle_ID
    LEFT JOIN dbo.CRM_Accounts s ON s.ID = jti.Supplier_Account_ID
    LEFT JOIN dbo.Maintenance_Companies mc ON mc.ID = jti.MaintenanceCompanyID
    LEFT JOIN dbo.JobTitle_Items_Types it ON it.ID = jti.ItemTypeID
    WHERE ISNULL(jti.IsDeleted,0) = 0
      AND (@JobTitle_ID IS NULL OR jti.JobTitle_ID = @JobTitle_ID)
    ORDER BY jti.ID DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_Filter_V2]
(
    -- Basic Search
    @Tool_Number            NVARCHAR(100) = NULL,
    @ItemTypeID             INT = NULL,
    @TitleKeyword           NVARCHAR(200) = NULL,  -- يبحث بالاسم عربي/إنجليزي
    -- Advanced Search
    @BrandID                INT = NULL,
    @BranchID               INT = NULL,
    @DepartmentID           INT = NULL,
    @JobTitle_ID            INT = NULL,
    @Supplier_Account_ID             INT = NULL,
    @MaintenanceCompanyID   INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.ID,
        jti.JobTitle_ID,
        jti.Tool_Number,
        jti.Title_Ar,
        jti.Title_En,
        jti.ItemTypeID,
        jti.Supplier_Account_ID,
        jti.MaintenanceCompanyID,
        jti.Policies_Ar,
        jti.Policies_En,
        jti.Working_Method_Video_Ar,
        jti.Working_Method_Video_En,
        jti.Evaluation_Method_Video_Ar,
        jti.Evaluation_Method_Video_En,
        jti.AddedUser,
        jti.AddedDate,
        jti.ModifyUser,
        jti.ModifyDate,
        jti.IsDeleted,
        jti.IsActive,
        -- names
        it.Title_Ar  AS ItemType_Title_Ar,
        it.Title_En  AS ItemType_Title_En,
        s.Name_AR   AS Supplier_Title_Ar,
        s.Name_EN   AS Supplier_Title_En,
        mc.Title_Ar  AS Maintenance_Title_Ar,
        mc.Title_En  AS Maintenance_Title_En,
        jt.Title_Ar  AS JobTitle_Title_Ar,
        jt.Title_En  AS JobTitle_Title_En,
        d.ID         AS DepartmentID,
        d.Title_Ar   AS Department_Title_Ar,
        d.Title_En   AS Department_Title_En,
        b.ID         AS BranchID,
        b.Title_Ar   AS Branch_Title_Ar,
        b.Title_En   AS Branch_Title_En,
        br.ID        AS BrandID,
        br.Title_Ar  AS Brand_Title_Ar,
        br.Title_En  AS Brand_Title_En
    FROM dbo.JobTitle_Items jti
    INNER JOIN dbo.JobTitles jt ON jt.ID = jti.JobTitle_ID
    INNER JOIN dbo.Departments d ON d.ID = jt.DepartmentID
    INNER JOIN dbo.Branches b ON b.ID = d.BranchID
    INNER JOIN dbo.Brands br ON br.ID = b.BrandID
    LEFT JOIN dbo.JobTitle_Items_Types it ON it.ID = jti.ItemTypeID
    LEFT JOIN dbo.CRM_Accounts s ON s.ID = jti.Supplier_Account_ID
    LEFT JOIN dbo.Maintenance_Companies mc ON mc.ID = jti.MaintenanceCompanyID
    WHERE ISNULL(jti.IsDeleted, 0) = 0
      -- Basic
      AND (@Tool_Number IS NULL OR jti.Tool_Number LIKE '%' + @Tool_Number + '%')
      AND (@ItemTypeID IS NULL OR jti.ItemTypeID = @ItemTypeID)
      AND (
            @TitleKeyword IS NULL
            OR jti.Title_Ar LIKE '%' + @TitleKeyword + '%'
            OR jti.Title_En LIKE '%' + @TitleKeyword + '%'
          )
      -- Advanced
      AND (@BrandID IS NULL OR br.ID = @BrandID)
      AND (@BranchID IS NULL OR b.ID = @BranchID)
      AND (@DepartmentID IS NULL OR d.ID = @DepartmentID)
      AND (@JobTitle_ID IS NULL OR jt.ID = @JobTitle_ID)
      AND (@Supplier_Account_ID IS NULL OR jti.Supplier_Account_ID = @Supplier_Account_ID)
      AND (@MaintenanceCompanyID IS NULL OR jti.MaintenanceCompanyID = @MaintenanceCompanyID)
    ORDER BY jti.ID DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_FullDetails_ByID]
    @JobTitle_ItemsID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (1)
        /* ========= JobTitle_Items ========= */
        JTI.[ID]                    AS [JobTitle_ItemsID],
        JTI.[JobTitle_ID]           AS [JobTitle_ID],
        JTI.[Title_Ar]              AS [Item_Title_Ar],
        JTI.[Title_En]              AS [Item_Title_En],
        JTI.[Tool_Number]           AS [Tool_Number],
        JTI.[Supplier_Account_ID]            AS [Supplier_Account_ID],
        JTI.[MaintenanceCompanyID]  AS [MaintenanceCompanyID],
        JTI.[ItemTypeID]            AS [ItemTypeID],
        /* ========= JobTitle ========= */
        ISNULL(JT.[DepartmentID], 0)        AS [DepartmentID],
        ISNULL(JT.[Title_Ar], N'')          AS [JobTitle_Title_Ar],
        ISNULL(JT.[Title_En], N'')          AS [JobTitle_Title_En],
        /* ========= Department ========= */
        ISNULL(D.[BranchID], 0)             AS [BranchID],
        ISNULL(D.[Title_Ar], N'')           AS [Department_Title_Ar],
        ISNULL(D.[Title_En], N'')           AS [Department_Title_En],
        /* ========= Branch ========= */
        ISNULL(B.[BrandID], 0)              AS [BrandID],
        ISNULL(B.[Title_Ar], N'')           AS [Branch_Title_Ar],
        ISNULL(B.[Title_En], N'')           AS [Branch_Title_En],
        /* ========= Brand ========= */
        ISNULL(BR.[Title_Ar], N'')          AS [Brand_Title_Ar],
        ISNULL(BR.[Title_En], N'')          AS [Brand_Title_En],
        ISNULL(BR.[Logo], N'')              AS [Brand_Logo],
        /* ========= Supplier ========= */
        ISNULL(s.[Name_AR], N'')           AS [Supplier_Title_Ar],
        ISNULL(s.[Name_EN], N'')           AS [Supplier_Title_En],
        /* ========= Maintenance Company ========= */
        ISNULL(MC.[Title_Ar], N'')          AS [MaintenanceCompany_Title_Ar],
        ISNULL(MC.[Title_En], N'')          AS [MaintenanceCompany_Title_En],
        /* ========= Item Type ========= */
        ISNULL(TY.[Title_Ar], N'')          AS [ItemType_Title_Ar],
        ISNULL(TY.[Title_En], N'')          AS [ItemType_Title_En],
        /* ========= Formatted Org Structure (Arabic/English) ========= */
        (ISNULL(BR.[Title_Ar], N'') + N' / ' +
         ISNULL(B.[Title_Ar],  N'') + N' / ' +
         ISNULL(D.[Title_Ar],  N'') + N' / ' +
         ISNULL(JT.[Title_Ar], N''))        AS [OrgStructure_Ar],
        (ISNULL(BR.[Title_En], N'') + N' / ' +
         ISNULL(B.[Title_En],  N'') + N' / ' +
         ISNULL(D.[Title_En],  N'') + N' / ' +
         ISNULL(JT.[Title_En], N''))        AS [OrgStructure_En]
    FROM [dbo].[JobTitle_Items] JTI
    LEFT JOIN [dbo].[JobTitles] JT
        ON JT.[ID] = JTI.[JobTitle_ID]
       AND ISNULL(JT.[IsDeleted], 0) = 0
    LEFT JOIN [dbo].[Departments] D
        ON D.[ID] = JT.[DepartmentID]
       AND ISNULL(D.[IsDeleted], 0) = 0
    LEFT JOIN [dbo].[Branches] B
        ON B.[ID] = D.[BranchID]
       AND ISNULL(B.[IsDeleted], 0) = 0
    LEFT JOIN [dbo].[Brands] BR
        ON BR.[ID] = B.[BrandID]
       AND ISNULL(BR.[IsDeleted], 0) = 0
    LEFT JOIN dbo.CRM_Accounts S
        ON S.[ID] = JTI.[Supplier_Account_ID]
       AND ISNULL(s.[Is_Deleted], 0) = 0
    LEFT JOIN [dbo].[Maintenance_Companies] MC
        ON MC.[ID] = JTI.[MaintenanceCompanyID]
       AND ISNULL(MC.[IsDeleted], 0) = 0
    LEFT JOIN [dbo].[JobTitle_Items_Types] TY
        ON TY.[ID] = JTI.[ItemTypeID]
       AND ISNULL(TY.[IsDeleted], 0) = 0
    WHERE JTI.[ID] = @JobTitle_ItemsID
      AND ISNULL(JTI.[IsDeleted], 0) = 0;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Select_JobTitle_Items_Search]
(
    @BrandID             INT = NULL,
    @BranchID            INT = NULL,
    @DepartmentID        INT = NULL,
    @JobTitle_ID         INT = NULL,
    @Supplier_Account_ID          INT = NULL,
    @MaintenanceCompanyID INT = NULL,
    @ItemTypeID          INT = NULL,
    @Tool_Number         NVARCHAR(100) = NULL,
    @Tool_Name           NVARCHAR(200) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        jti.ID,
        jti.JobTitle_ID,
        jti.Title_Ar,
        jti.Title_En,
        jti.Tool_Number,
        jti.ItemTypeID,
        jti.Supplier_Account_ID,
        jti.MaintenanceCompanyID,
        jti.AddedDate,
        jti.IsDeleted,
        jti.IsActive,
        b.Title_Ar  AS Brand_Title_Ar,
        br.Title_Ar AS Branch_Title_Ar,
        d.Title_Ar  AS Department_Title_Ar,
        jt.Title_Ar AS JobTitle_Title_Ar,
        it.Title_Ar AS ItemType_Title_Ar,
        s.Name_AR  AS Supplier_Title_Ar,
        mc.Title_Ar AS MaintenanceCompany_Title_Ar,
        (ISNULL(b.Title_Ar,'') + ' / ' + ISNULL(br.Title_Ar,'') + ' / ' + ISNULL(d.Title_Ar,'') + ' / ' + ISNULL(jt.Title_Ar,'')) AS OrgStructure_Ar
    FROM dbo.JobTitle_Items jti
    INNER JOIN dbo.JobTitles jt ON jt.ID = jti.JobTitle_ID
    INNER JOIN dbo.Departments d ON d.ID = jt.DepartmentID
    INNER JOIN dbo.Branches br ON br.ID = d.BranchID
    INNER JOIN dbo.Brands b ON b.ID = br.BrandID
    LEFT JOIN dbo.JobTitle_Items_Types it ON it.ID = jti.ItemTypeID
    LEFT JOIN dbo.CRM_Accounts s ON s.ID = jti.Supplier_Account_ID
    LEFT JOIN dbo.Maintenance_Companies mc ON mc.ID = jti.MaintenanceCompanyID
    WHERE ISNULL(jti.IsDeleted,0) = 0
      AND (@BrandID IS NULL OR b.ID = @BrandID)
      AND (@BranchID IS NULL OR br.ID = @BranchID)
      AND (@DepartmentID IS NULL OR d.ID = @DepartmentID)
      AND (@JobTitle_ID IS NULL OR jti.JobTitle_ID = @JobTitle_ID)
      AND (@Supplier_Account_ID IS NULL OR jti.Supplier_Account_ID = @Supplier_Account_ID)
      AND (@MaintenanceCompanyID IS NULL OR jti.MaintenanceCompanyID = @MaintenanceCompanyID)
      AND (@ItemTypeID IS NULL OR jti.ItemTypeID = @ItemTypeID)
      AND (@Tool_Number IS NULL OR jti.Tool_Number LIKE '%' + @Tool_Number + '%')
      AND (
            @Tool_Name IS NULL
            OR jti.Title_Ar LIKE '%' + @Tool_Name + '%'
            OR jti.Title_En LIKE '%' + @Tool_Name + '%'
          )
    ORDER BY jti.ID DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Update_JobTitle_Items_ByID]
(
    @ID                         INT,
    @JobTitle_ID                INT,
    @Title_Ar                   NVARCHAR(MAX),
    @Title_En                   NVARCHAR(MAX),
    @Tool_Number                NVARCHAR(100) = NULL,
    @Supplier_Account_ID                 INT = NULL,
    @MaintenanceCompanyID       INT = NULL,
    @ItemTypeID                 INT = NULL,
    @Policies_Ar                NVARCHAR(MAX) = NULL,
    @Policies_En                NVARCHAR(MAX) = NULL,
    @Working_Method_Video_Ar    NVARCHAR(MAX) = NULL,
    @Working_Method_Video_En    NVARCHAR(MAX) = NULL,
    @Evaluation_Method_Video_Ar NVARCHAR(MAX) = NULL,
    @Evaluation_Method_Video_En NVARCHAR(MAX) = NULL,
    @ModifyUser                 INT = NULL,
    @IsActive                   BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY BEGIN TRANSACTION;
    DECLARE @SupplierLock int;
    EXEC @SupplierLock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
    IF @SupplierLock<0 THROW 51201,N'السجل مشغول. أعد المحاولة.',1;
    EXEC dbo.CRM_Require_Tool_Supplier @ModifyUser,@Supplier_Account_ID,@JobTitle_ID,@ID;
    DECLARE @Before xml=NULL,@After xml,@SavedID int;
    SELECT @Before=(SELECT ID,JobTitle_ID,Title_Ar,Title_En,Tool_Number,Supplier_Account_ID,IsActive AS Is_Active,IsDeleted AS Is_Deleted FROM dbo.JobTitle_Items WHERE ID=@ID FOR XML PATH('row'),TYPE);
    IF @Before IS NULL THROW 51201,N'الأداة غير موجودة.',1;

    UPDATE [dbo].[JobTitle_Items]
    SET JobTitle_ID                = @JobTitle_ID,
        Title_Ar                   = @Title_Ar,
        Title_En                   = @Title_En,
        Tool_Number                = @Tool_Number,
        Supplier_Account_ID                 = @Supplier_Account_ID,
        MaintenanceCompanyID       = @MaintenanceCompanyID,
        ItemTypeID                 = @ItemTypeID,
        Policies_Ar                = @Policies_Ar,
        Policies_En                = @Policies_En,
        Working_Method_Video_Ar    = @Working_Method_Video_Ar,
        Working_Method_Video_En    = @Working_Method_Video_En,
        Evaluation_Method_Video_Ar = @Evaluation_Method_Video_Ar,
        Evaluation_Method_Video_En = @Evaluation_Method_Video_En,
        ModifyUser                 = @ModifyUser,
        ModifyDate                 = GETDATE(),
        IsActive                   = ISNULL(@IsActive, IsActive)
    WHERE ID = @ID;
SELECT @After=(SELECT ID,JobTitle_ID,Title_Ar,Title_En,Tool_Number,Supplier_Account_ID,IsActive AS Is_Active,IsDeleted AS Is_Deleted FROM dbo.JobTitle_Items WHERE ID=@ID FOR XML PATH('row'),TYPE);
    INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@ModifyUser,NULL,N'JobTitle_Items',@ID,N'تعديل أداة',@Before,@After);
    COMMIT;
    
    END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH;
END
GO
