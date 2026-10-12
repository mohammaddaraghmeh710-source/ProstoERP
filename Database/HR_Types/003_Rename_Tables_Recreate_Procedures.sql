-- Rename the existing HR lookup tables, preserving rows, and recreate their procedures.
USE [Prosto_Live];
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.vacations', N'U') IS NULL OR OBJECT_ID(N'dbo.HR_Departure_Types', N'U') IS NULL
        THROW 51000, 'Expected source tables are missing.', 1;
    IF OBJECT_ID(N'dbo.HR_Vacations_Types') IS NOT NULL OR OBJECT_ID(N'dbo.HR_Leaves_Types') IS NOT NULL
        THROW 51000, 'A target table already exists; review before migration.', 1;
    IF OBJECT_ID(N'dbo.Insert_HR_Vacations_Types') IS NOT NULL THROW 51000, 'Target procedure Insert_HR_Vacations_Types already exists.', 1;
    DROP PROCEDURE dbo.Insert_vacations;
    IF OBJECT_ID(N'dbo.Select_HR_Vacations_Types_All') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Vacations_Types_All already exists.', 1;
    DROP PROCEDURE dbo.Select_vacations_All;
    IF OBJECT_ID(N'dbo.Select_HR_Vacations_Types_ByID') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Vacations_Types_ByID already exists.', 1;
    DROP PROCEDURE dbo.Select_vacations_ByID;
    IF OBJECT_ID(N'dbo.Select_HR_Vacations_Types_Filter') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Vacations_Types_Filter already exists.', 1;
    DROP PROCEDURE dbo.Select_vacations_Filter;
    IF OBJECT_ID(N'dbo.Select_HR_Vacations_Types_ForDDL') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Vacations_Types_ForDDL already exists.', 1;
    DROP PROCEDURE dbo.Select_vacations_ForDDL;
    IF OBJECT_ID(N'dbo.Update_HR_Vacations_Types_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Vacations_Types_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_vacations_ByID;
    IF OBJECT_ID(N'dbo.Update_HR_Vacations_Types_IsActive_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Vacations_Types_IsActive_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_vacations_IsActive_ByID;
    IF OBJECT_ID(N'dbo.Update_HR_Vacations_Types_IsDeleted_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Vacations_Types_IsDeleted_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_vacations_IsDeleted_ByID;
    IF OBJECT_ID(N'dbo.Insert_HR_Leaves_Types') IS NOT NULL THROW 51000, 'Target procedure Insert_HR_Leaves_Types already exists.', 1;
    DROP PROCEDURE dbo.Insert_HR_Departure_Types;
    IF OBJECT_ID(N'dbo.Select_HR_Leaves_Types_All') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Leaves_Types_All already exists.', 1;
    DROP PROCEDURE dbo.Select_HR_Departure_Types_All;
    IF OBJECT_ID(N'dbo.Select_HR_Leaves_Types_ByID') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Leaves_Types_ByID already exists.', 1;
    DROP PROCEDURE dbo.Select_HR_Departure_Types_ByID;
    IF OBJECT_ID(N'dbo.Select_HR_Leaves_Types_Filter') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Leaves_Types_Filter already exists.', 1;
    DROP PROCEDURE dbo.Select_HR_Departure_Types_Filter;
    IF OBJECT_ID(N'dbo.Select_HR_Leaves_Types_ForDDL') IS NOT NULL THROW 51000, 'Target procedure Select_HR_Leaves_Types_ForDDL already exists.', 1;
    DROP PROCEDURE dbo.Select_HR_Departure_Types_ForDDL;
    IF OBJECT_ID(N'dbo.Update_HR_Leaves_Types_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Leaves_Types_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_HR_Departure_Types_ByID;
    IF OBJECT_ID(N'dbo.Update_HR_Leaves_Types_IsActive_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Leaves_Types_IsActive_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_HR_Departure_Types_IsActive_ByID;
    IF OBJECT_ID(N'dbo.Update_HR_Leaves_Types_IsDeleted_ByID') IS NOT NULL THROW 51000, 'Target procedure Update_HR_Leaves_Types_IsDeleted_ByID already exists.', 1;
    DROP PROCEDURE dbo.Update_HR_Departure_Types_IsDeleted_ByID;
    EXEC sys.sp_rename N'dbo.vacations', N'HR_Vacations_Types', N'OBJECT';
    EXEC sys.sp_rename N'dbo.PK_vacations', N'PK_HR_Vacations_Types', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_vacations_Is_Active', N'DF_HR_Vacations_Types_Is_Active', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_vacations_Is_Deleted', N'DF_HR_Vacations_Types_Is_Deleted', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_vacations_AddedDate', N'DF_HR_Vacations_Types_AddedDate', N'OBJECT';
    EXEC sys.sp_rename N'dbo.UQ_vacations_Core_ID', N'UQ_HR_Vacations_Types_Core_ID', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_vacations_Max_Value', N'CK_HR_Vacations_Types_Max_Value', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_vacations_Name_AR', N'CK_HR_Vacations_Types_Name_AR', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_vacations_Name_En', N'CK_HR_Vacations_Types_Name_En', N'OBJECT';
    EXEC sys.sp_rename N'dbo.HR_Departure_Types', N'HR_Leaves_Types', N'OBJECT';
    EXEC sys.sp_rename N'dbo.PK_HR_Departure_Types', N'PK_HR_Leaves_Types', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_HR_Departure_Types_Is_Active', N'DF_HR_Leaves_Types_Is_Active', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_HR_Departure_Types_Is_Deleted', N'DF_HR_Leaves_Types_Is_Deleted', N'OBJECT';
    EXEC sys.sp_rename N'dbo.DF_HR_Departure_Types_AddedDate', N'DF_HR_Leaves_Types_AddedDate', N'OBJECT';
    EXEC sys.sp_rename N'dbo.UQ_HR_Departure_Types_Core_ID', N'UQ_HR_Leaves_Types_Core_ID', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_HR_Departure_Types_Max_Value', N'CK_HR_Leaves_Types_Max_Value', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_HR_Departure_Types_Name_AR', N'CK_HR_Leaves_Types_Name_AR', N'OBJECT';
    EXEC sys.sp_rename N'dbo.CK_HR_Departure_Types_Name_En', N'CK_HR_Leaves_Types_Name_En', N'OBJECT';
    EXEC(N'CREATE PROCEDURE dbo.Insert_HR_Vacations_Types
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value int,
    @AddedUser int,
    @Is_Active bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.HR_Vacations_Types (Core_ID, Name_AR, Name_En, Max_Value, AddedUser, Is_Active)
    VALUES (@Core_ID, LTRIM(RTRIM(@Name_AR)), LTRIM(RTRIM(@Name_En)), @Max_Value, @AddedUser, @Is_Active);
    SELECT CONVERT(int, SCOPE_IDENTITY()) AS NewID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Vacations_Types_All
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Vacations_Types WHERE Is_Deleted = 0
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Vacations_Types_ByID
    @ID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Vacations_Types WHERE ID = @ID AND Is_Deleted = 0;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Vacations_Types_Filter
    @Keyword nvarchar(200) = NULL,
    @Is_Active bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Keyword = NULLIF(LTRIM(RTRIM(@Keyword)), N'''');
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Vacations_Types
    WHERE Is_Deleted = 0
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword, Name_AR) > 0 OR CHARINDEX(@Keyword, Name_En) > 0)
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Vacations_Types_ForDDL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Vacations_Types WHERE Is_Deleted = 0 AND Is_Active = 1
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Vacations_Types_ByID
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
    UPDATE dbo.HR_Vacations_Types
    SET Core_ID = @Core_ID, Name_AR = LTRIM(RTRIM(@Name_AR)), Name_En = LTRIM(RTRIM(@Name_En)),
        Max_Value = @Max_Value, Is_Active = @Is_Active,
        Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Vacations_Types_IsActive_ByID
    @ID int,
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Vacations_Types
    SET Is_Active = @Is_Active, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Vacations_Types_IsDeleted_ByID
    @ID int,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Vacations_Types
    SET Is_Deleted = 1, Is_Active = 0, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Insert_HR_Leaves_Types
    @Core_ID int,
    @Name_AR nvarchar(200),
    @Name_En nvarchar(200),
    @Max_Value decimal(9,2),
    @AddedUser int,
    @Is_Active bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.HR_Leaves_Types (Core_ID, Name_AR, Name_En, Max_Value, AddedUser, Is_Active)
    VALUES (@Core_ID, LTRIM(RTRIM(@Name_AR)), LTRIM(RTRIM(@Name_En)), @Max_Value, @AddedUser, @Is_Active);
    SELECT CONVERT(int, SCOPE_IDENTITY()) AS NewID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Leaves_Types_All
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Leaves_Types WHERE Is_Deleted = 0
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Leaves_Types_ByID
    @ID int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Leaves_Types WHERE ID = @ID AND Is_Deleted = 0;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Leaves_Types_Filter
    @Keyword nvarchar(200) = NULL,
    @Is_Active bit = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Keyword = NULLIF(LTRIM(RTRIM(@Keyword)), N'''');
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Leaves_Types
    WHERE Is_Deleted = 0
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active)
      AND (@Keyword IS NULL OR CHARINDEX(@Keyword, Name_AR) > 0 OR CHARINDEX(@Keyword, Name_En) > 0)
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Select_HR_Leaves_Types_ForDDL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Core_ID, Name_AR, Name_En, Max_Value, Is_Active, Is_Deleted, AddedUser, AddedDate, Modified_User, Modified_Date
    FROM dbo.HR_Leaves_Types WHERE Is_Deleted = 0 AND Is_Active = 1
    ORDER BY Name_AR, ID;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Leaves_Types_ByID
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
    UPDATE dbo.HR_Leaves_Types
    SET Core_ID = @Core_ID, Name_AR = LTRIM(RTRIM(@Name_AR)), Name_En = LTRIM(RTRIM(@Name_En)),
        Max_Value = @Max_Value, Is_Active = @Is_Active,
        Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Leaves_Types_IsActive_ByID
    @ID int,
    @Is_Active bit,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Leaves_Types
    SET Is_Active = @Is_Active, Modified_User = @Modified_User, Modified_Date = GETDATE()
    WHERE ID = @ID AND Is_Deleted = 0;
    SELECT @@ROWCOUNT AS AffectedRows;
END;');
    EXEC(N'CREATE PROCEDURE dbo.Update_HR_Leaves_Types_IsDeleted_ByID
    @ID int,
    @Modified_User int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.HR_Leaves_Types
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
