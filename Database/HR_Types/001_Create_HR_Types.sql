-- Target: the Portal database, Prosto_Live. Run once in SSMS.
-- Atomic, additive migration: refuses to replace existing tables/procedures.
USE [Prosto_Live];
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.vacations') IS NOT NULL
        THROW 51000, 'Object dbo.vacations already exists. Review before deployment.', 1;
    CREATE TABLE dbo.vacations (
        ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_vacations PRIMARY KEY,
        Core_ID int NOT NULL,
        Name_AR nvarchar(200) NOT NULL,
        Name_En nvarchar(200) NOT NULL,
        Max_Value int NOT NULL,
        Is_Active bit NOT NULL CONSTRAINT DF_vacations_Is_Active DEFAULT (1),
        Is_Deleted bit NOT NULL CONSTRAINT DF_vacations_Is_Deleted DEFAULT (0),
        AddedUser int NOT NULL,
        AddedDate datetime NOT NULL CONSTRAINT DF_vacations_AddedDate DEFAULT (GETDATE()),
        Modified_User int NULL,
        Modified_Date datetime NULL,
        CONSTRAINT UQ_vacations_Core_ID UNIQUE (Core_ID),
        CONSTRAINT CK_vacations_Max_Value CHECK (Max_Value > 0),
        CONSTRAINT CK_vacations_Name_AR CHECK (LEN(LTRIM(RTRIM(Name_AR))) > 0),
        CONSTRAINT CK_vacations_Name_En CHECK (LEN(LTRIM(RTRIM(Name_En))) > 0)
    );
    IF OBJECT_ID(N'dbo.Insert_vacations') IS NOT NULL
        THROW 51000, 'Object dbo.Insert_vacations already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Insert_vacations
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value int,
    @AddedUser int,
    @Is_Active bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.vacations (Core_ID, Name_AR, Name_En, Max_Value, AddedUser, Is_Active)
    VALUES (@Core_ID, LTRIM(RTRIM(@Name_AR)), LTRIM(RTRIM(@Name_En)), @Max_Value, @AddedUser, @Is_Active);
    SELECT CONVERT(int, SCOPE_IDENTITY()) AS NewID;
END;');
    IF OBJECT_ID(N'dbo.Select_vacations_All') IS NOT NULL
        THROW 51000, 'Object dbo.Select_vacations_All already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_vacations_All
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.vacations WHERE Is_Deleted = 0
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Select_vacations_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Select_vacations_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_vacations_ByID
    @ID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.vacations WHERE ID = @ID AND Is_Deleted = 0;
END;');
    IF OBJECT_ID(N'dbo.Select_vacations_Filter') IS NOT NULL
        THROW 51000, 'Object dbo.Select_vacations_Filter already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_vacations_Filter
    @Keyword nvarchar(200) = NULL,
    @Is_Active bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Keyword = NULLIF(LTRIM(RTRIM(@Keyword)), N'''');
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.vacations
    WHERE Is_Deleted = 0
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword, Name_AR) > 0 OR CHARINDEX(@Keyword, Name_En) > 0)
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Select_vacations_ForDDL') IS NOT NULL
        THROW 51000, 'Object dbo.Select_vacations_ForDDL already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_vacations_ForDDL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.vacations WHERE Is_Deleted = 0 AND Is_Active = 1
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Update_vacations_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_vacations_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_vacations_ByID
    @ID int,
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value int,
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.vacations
    SET Core_ID = @Core_ID, Name_AR = LTRIM(RTRIM(@Name_AR)), Name_En = LTRIM(RTRIM(@Name_En)),
        Max_Value = @Max_Value, Is_Active = @Is_Active,
        Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    IF OBJECT_ID(N'dbo.Update_vacations_IsActive_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_vacations_IsActive_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_vacations_IsActive_ByID
    @ID int,
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.vacations
    SET Is_Active = @Is_Active, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    IF OBJECT_ID(N'dbo.Update_vacations_IsDeleted_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_vacations_IsDeleted_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_vacations_IsDeleted_ByID
    @ID int,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.vacations
    SET Is_Deleted = 1, Is_Active = 0, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    IF OBJECT_ID(N'dbo.HR_Departure_Types') IS NOT NULL
        THROW 51000, 'Object dbo.HR_Departure_Types already exists. Review before deployment.', 1;
    CREATE TABLE dbo.HR_Departure_Types (
        ID int IDENTITY(1,1) NOT NULL CONSTRAINT PK_HR_Departure_Types PRIMARY KEY,
        Core_ID int NOT NULL,
        Name_AR nvarchar(200) NOT NULL,
        Name_En nvarchar(200) NOT NULL,
        Max_Value decimal(9,2) NOT NULL,
        Is_Active bit NOT NULL CONSTRAINT DF_HR_Departure_Types_Is_Active DEFAULT (1),
        Is_Deleted bit NOT NULL CONSTRAINT DF_HR_Departure_Types_Is_Deleted DEFAULT (0),
        AddedUser int NOT NULL,
        AddedDate datetime NOT NULL CONSTRAINT DF_HR_Departure_Types_AddedDate DEFAULT (GETDATE()),
        Modified_User int NULL,
        Modified_Date datetime NULL,
        CONSTRAINT UQ_HR_Departure_Types_Core_ID UNIQUE (Core_ID),
        CONSTRAINT CK_HR_Departure_Types_Max_Value CHECK (Max_Value > 0),
        CONSTRAINT CK_HR_Departure_Types_Name_AR CHECK (LEN(LTRIM(RTRIM(Name_AR))) > 0),
        CONSTRAINT CK_HR_Departure_Types_Name_En CHECK (LEN(LTRIM(RTRIM(Name_En))) > 0)
    );
    IF OBJECT_ID(N'dbo.Insert_HR_Departure_Types') IS NOT NULL
        THROW 51000, 'Object dbo.Insert_HR_Departure_Types already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Insert_HR_Departure_Types
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value decimal(9,2),
    @AddedUser int,
    @Is_Active bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.HR_Departure_Types (Core_ID, Name_AR, Name_En, Max_Value, AddedUser, Is_Active)
    VALUES (@Core_ID, LTRIM(RTRIM(@Name_AR)), LTRIM(RTRIM(@Name_En)), @Max_Value, @AddedUser, @Is_Active);
    SELECT CONVERT(int, SCOPE_IDENTITY()) AS NewID;
END;');
    IF OBJECT_ID(N'dbo.Select_HR_Departure_Types_All') IS NOT NULL
        THROW 51000, 'Object dbo.Select_HR_Departure_Types_All already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Departure_Types_All
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Departure_Types WHERE Is_Deleted = 0
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Select_HR_Departure_Types_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Select_HR_Departure_Types_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Departure_Types_ByID
    @ID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Departure_Types WHERE ID = @ID AND Is_Deleted = 0;
END;');
    IF OBJECT_ID(N'dbo.Select_HR_Departure_Types_Filter') IS NOT NULL
        THROW 51000, 'Object dbo.Select_HR_Departure_Types_Filter already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Departure_Types_Filter
    @Keyword nvarchar(200) = NULL,
    @Is_Active bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Keyword = NULLIF(LTRIM(RTRIM(@Keyword)), N'''');
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Departure_Types
    WHERE Is_Deleted = 0
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword, Name_AR) > 0 OR CHARINDEX(@Keyword, Name_En) > 0)
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Select_HR_Departure_Types_ForDDL') IS NOT NULL
        THROW 51000, 'Object dbo.Select_HR_Departure_Types_ForDDL already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Departure_Types_ForDDL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Departure_Types WHERE Is_Deleted = 0 AND Is_Active = 1
    ORDER BY Name_AR, ID;
END;');
    IF OBJECT_ID(N'dbo.Update_HR_Departure_Types_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_HR_Departure_Types_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Departure_Types_ByID
    @ID int,
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value decimal(9,2),
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Departure_Types
    SET Core_ID = @Core_ID, Name_AR = LTRIM(RTRIM(@Name_AR)), Name_En = LTRIM(RTRIM(@Name_En)),
        Max_Value = @Max_Value, Is_Active = @Is_Active,
        Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    IF OBJECT_ID(N'dbo.Update_HR_Departure_Types_IsActive_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_HR_Departure_Types_IsActive_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Departure_Types_IsActive_ByID
    @ID int,
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Departure_Types
    SET Is_Active = @Is_Active, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    IF OBJECT_ID(N'dbo.Update_HR_Departure_Types_IsDeleted_ByID') IS NOT NULL
        THROW 51000, 'Object dbo.Update_HR_Departure_Types_IsDeleted_ByID already exists. Review before deployment.', 1;
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Departure_Types_IsDeleted_ByID
    @ID int,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Departure_Types
    SET Is_Deleted = 1, Is_Active = 0, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
