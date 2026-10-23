-- Replacement procedures and verified account links are deployed atomically by Apply-Suppliers.ps1.
DROP PROCEDURE IF EXISTS dbo.Insert_Suppliers;
DROP PROCEDURE IF EXISTS dbo.Select_Suppliers_All;
DROP PROCEDURE IF EXISTS dbo.Select_Suppliers_ByID;
DROP PROCEDURE IF EXISTS dbo.Update_Suppliers_ByID;
DROP PROCEDURE IF EXISTS dbo.Update_Suppliers_IsActive_ByID;
DROP PROCEDURE IF EXISTS dbo.Update_Suppliers_IsDeleted_ByID;
GO
IF OBJECT_ID('dbo.Suppliers','U') IS NOT NULL
BEGIN
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id=OBJECT_ID('dbo.Suppliers')) THROW 51201,N'ما زالت هناك إجراءات تعتمد على جدول الموردين القديم.',1;
 IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id=OBJECT_ID('dbo.Suppliers')) THROW 51201,N'ما زالت هناك جداول تعتمد على الموردين القدامى.',1;
 DROP TABLE dbo.Suppliers;
END;
GO
