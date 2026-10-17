-- Read-only verification after deployment. No test records are inserted.
USE [Prosto_Live];
SET NOCOUNT ON;

DECLARE @Tables TABLE (Name sysname NOT NULL);
INSERT @Tables VALUES (N'HR_Vacations_Types'), (N'HR_Leaves_Types');

IF EXISTS (SELECT 1 FROM @Tables WHERE OBJECT_ID(N'dbo.' + Name, N'U') IS NULL)
    THROW 51001, 'A required HR types table is missing.', 1;

DECLARE @Procedures TABLE (Name sysname NOT NULL);
INSERT @Procedures
SELECT p.Prefix + t.Name + p.Suffix
FROM @Tables t
CROSS JOIN (VALUES
    (N'Insert_', N''),
    (N'Select_', N'_All'),
    (N'Select_', N'_ByID'),
    (N'Select_', N'_Filter'),
    (N'Select_', N'_ForDDL'),
    (N'Update_', N'_ByID'),
    (N'Update_', N'_IsActive_ByID'),
    (N'Update_', N'_IsDeleted_ByID')
) p(Prefix, Suffix);

IF EXISTS (SELECT 1 FROM @Procedures WHERE OBJECT_ID(N'dbo.' + Name, N'P') IS NULL)
    THROW 51002, 'A required HR types procedure is missing.', 1;

SELECT t.Name AS TableName, c.column_id, c.name AS ColumnName,
       TYPE_NAME(c.user_type_id) AS SqlType, c.max_length, c.precision, c.scale,
       c.is_nullable, c.is_identity
FROM @Tables t
JOIN sys.columns c ON c.object_id = OBJECT_ID(N'dbo.' + t.Name)
ORDER BY t.Name, c.column_id;

SELECT t.Name AS TableName, i.name AS UniqueIndex, c.name AS ColumnName, i.has_filter
FROM @Tables t
JOIN sys.indexes i ON i.object_id = OBJECT_ID(N'dbo.' + t.Name) AND i.is_unique = 1
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
ORDER BY t.Name, i.name;

-- Result-set metadata used by LINQ to SQL import; errors indicate a mapping issue.
SELECT p.Name AS ProcedureName, r.column_ordinal, r.name AS ResultColumn,
       r.system_type_name, r.is_nullable, r.error_number, r.error_message
FROM @Procedures p
CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(N'dbo.' + p.Name), 0) r
ORDER BY p.Name, r.column_ordinal;

SELECT N'Both tables and all 16 procedures exist. Review schema and result metadata above.' AS Verification;
