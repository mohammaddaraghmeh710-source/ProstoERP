IF COL_LENGTH('dbo.Information_Pages','AllUserTypes') IS NULL
 ALTER TABLE dbo.Information_Pages ADD AllUserTypes bit NOT NULL CONSTRAINT DF_InformationPages_AllTypes DEFAULT(1),
 AccessRevision int NOT NULL CONSTRAINT DF_InformationPages_AccessRevision DEFAULT(0);
GO
IF OBJECT_ID('dbo.Information_Page_Roles','U') IS NULL
 CREATE TABLE dbo.Information_Page_Roles(
  PageID int NOT NULL REFERENCES dbo.Information_Pages(ID),
  UserTypeID int NOT NULL REFERENCES dbo.Users_Types(ID),
  CONSTRAINT PK_Information_Page_Roles PRIMARY KEY(PageID,UserTypeID)
 );
GO
IF COL_LENGTH('dbo.Information_Page_Versions','RestoredFromVersion') IS NULL
 ALTER TABLE dbo.Information_Page_Versions ADD RestoredFromVersion int NULL;
IF COL_LENGTH('dbo.Information_Page_Logs','Details') IS NULL
 ALTER TABLE dbo.Information_Page_Logs ADD Details nvarchar(max) NULL;
GO
DECLARE @Constraint sysname,@Sql nvarchar(max);
DECLARE checks CURSOR LOCAL FAST_FORWARD FOR
 SELECT name FROM sys.check_constraints
 WHERE parent_object_id=OBJECT_ID('dbo.Information_Page_Logs')
 AND (parent_column_id=COLUMNPROPERTY(OBJECT_ID('dbo.Information_Page_Logs'),'Action','ColumnId')
      OR name='CK_Information_Page_Logs_Action');
OPEN checks; FETCH NEXT FROM checks INTO @Constraint;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'ALTER TABLE dbo.Information_Page_Logs DROP CONSTRAINT '+QUOTENAME(@Constraint);
 EXEC sys.sp_executesql @Sql;
 FETCH NEXT FROM checks INTO @Constraint;
END;
CLOSE checks; DEALLOCATE checks;
ALTER TABLE dbo.Information_Page_Logs ADD CONSTRAINT CK_Information_Page_Logs_Action
 CHECK(Action IN('create','update','delete','view','preview','access','restore'));
