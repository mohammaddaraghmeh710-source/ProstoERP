-- Run through Apply.ps1 after a verified database backup. The caller owns the transaction.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Tables TABLE(Name sysname PRIMARY KEY);
INSERT @Tables VALUES('Work_Guide_Access_Requests'),('Work_Guide_Activity_Logs'),('Work_Guide_Document_Versions'),
 ('Work_Guide_User_Category_Roles'),('Work_Guide_Role_Permissions'),('Work_Guide_Documents'),('Work_Guide_Categories'),
 ('Work_Guide_Roles'),('Customer_Guide_Grants'),('CustomerApi_GuideOperations');
DECLARE @Objects TABLE(ID int PRIMARY KEY,Name sysname,Kind char(2));
INSERT @Objects SELECT o.object_id,o.name,o.type FROM sys.objects o
WHERE o.schema_id=SCHEMA_ID('dbo') AND o.type IN('P','FN','IF','TF','V') AND
 (o.name LIKE '%Work[_]Guide%' OR o.name IN('Customer_Guide','Customer_Guide_Effective','Customer_WorkGuide','Customer_WorkGuideAdmin','CustomerApi_Guide','Customer_SaveGrant','Customer_LogDocument'));
-- An unexpected consumer must be inspected rather than silently losing its relationship.
IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN @Tables t ON f.referenced_object_id=OBJECT_ID('dbo.'+t.Name)
 WHERE NOT EXISTS(SELECT 1 FROM @Tables p WHERE f.parent_object_id=OBJECT_ID('dbo.'+p.Name)))
 THROW 51990,'Unexpected foreign key to a retired guide table. No changes were committed.',1;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d
 WHERE (d.referenced_id IN(SELECT ID FROM @Objects) OR d.referenced_id IN(SELECT OBJECT_ID('dbo.'+Name) FROM @Tables))
 AND d.referencing_id NOT IN(SELECT ID FROM @Objects)
 AND d.referencing_id NOT IN(SELECT o.object_id FROM sys.objects o JOIN @Tables t ON o.parent_object_id=OBJECT_ID('dbo.'+t.Name))
 AND d.referencing_id NOT IN(SELECT OBJECT_ID('dbo.'+Name) FROM @Tables WHERE OBJECT_ID('dbo.'+Name) IS NOT NULL))
 THROW 51990,'Unexpected SQL consumer of work-guide objects. No changes were committed.',1;
DECLARE @sql nvarchar(max)=N'';
SELECT @sql=@sql+N'DROP '+CASE Kind WHEN 'P' THEN N'PROCEDURE ' WHEN 'V' THEN N'VIEW ' ELSE N'FUNCTION ' END+QUOTENAME('dbo')+N'.'+QUOTENAME(Name)+N';'+CHAR(10)
FROM @Objects WHERE Kind='P';
EXEC sys.sp_executesql @sql;
-- Schema-bound functions/views are removed from the dependency leaves inward.
DELETE @Objects WHERE Kind='P';
WHILE EXISTS(SELECT 1 FROM @Objects)
BEGIN
 DECLARE @id int=NULL,@name sysname,@kind char(2);
 SELECT TOP(1) @id=o.ID,@name=o.Name,@kind=o.Kind FROM @Objects o
 WHERE NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN @Objects c ON c.ID=d.referencing_id WHERE d.referenced_id=o.ID AND c.ID<>o.ID);
 IF @id IS NULL THROW 51990,'Cyclic guide module dependency requires inspection.',1;
 SET @sql=N'DROP '+CASE @kind WHEN 'V' THEN N'VIEW ' ELSE N'FUNCTION ' END+N'dbo.'+QUOTENAME(@name)+N';';
 EXEC sys.sp_executesql @sql;
 DELETE @Objects WHERE ID=@id;
END;
SET @sql=N'';
SELECT @sql=@sql+N'ALTER TABLE dbo.'+QUOTENAME(OBJECT_NAME(f.parent_object_id))+N' DROP CONSTRAINT '+QUOTENAME(f.name)+N';'+CHAR(10)
FROM sys.foreign_keys f JOIN @Tables t ON f.parent_object_id=OBJECT_ID('dbo.'+t.Name);
EXEC sys.sp_executesql @sql;
SET @sql=N'';
SELECT @sql=@sql+N'DROP TABLE dbo.'+QUOTENAME(Name)+N';'+CHAR(10) FROM @Tables WHERE OBJECT_ID('dbo.'+Name,'U') IS NOT NULL;
EXEC sys.sp_executesql @sql;
-- Keep login/credential/feedback history in the shared customer audit table.
IF OBJECT_ID('dbo.Customer_Portal_Activity','U') IS NOT NULL
BEGIN
 DELETE dbo.Customer_Portal_Activity WHERE Action IN('view','download','grant','access-request','access-review');
 IF COL_LENGTH('dbo.Customer_Portal_Activity','DocumentID') IS NOT NULL ALTER TABLE dbo.Customer_Portal_Activity DROP COLUMN DocumentID;
END;
IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0 AND schema_id=SCHEMA_ID('dbo')
 AND (name LIKE '%Work[_]Guide%' OR name IN('Customer_Guide','Customer_Guide_Effective','Customer_WorkGuide','Customer_WorkGuideAdmin','CustomerApi_Guide','Customer_SaveGrant','Customer_LogDocument','Customer_Guide_Grants','CustomerApi_GuideOperations')))
 THROW 51990,'Guide object removal is incomplete.',1;
