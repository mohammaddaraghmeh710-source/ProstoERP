param([switch]$KeepDatabase)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$config=[xml](Get-Content -LiteralPath (Join-Path $root 'Portal/Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Only local SQL Server is supported.'}
$name='Prosto_Suppliers_Test_'+[guid]::NewGuid().ToString('N')
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
$output=Join-Path $root '../tmp/supplier-results';[void][IO.Directory]::CreateDirectory($output)
$db=$null;$tx=$null;$created=$false;$passed=$false
function Assert([bool]$ok,[string]$message){if(!$ok){throw $message};Write-Output ('PASS: '+$message)}
function Sql([string]$connection,[string]$sql,[hashtable]$parameters=@{}){
 $cn=[Data.SqlClient.SqlConnection]::new($connection)
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=120;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cn.Dispose()}
}
function Q([string]$sql,[hashtable]$parameters=@{}){
 $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$sql;$cmd.CommandTimeout=120
 try{foreach($key in $parameters.Keys){if($parameters[$key] -is [byte[]]){$p=$cmd.Parameters.Add($key,[Data.SqlDbType]::Binary,8);$p.Value=$parameters[$key]}else{[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])}};$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cmd.Dispose()}
}
function Rejected([scriptblock]$action,[string]$message,[int[]]$numbers=@(51200,51201)){
 $rejected=$false
 try{& $action|Out-Null}catch{$detail=$_.Exception;while($detail.InnerException){$detail=$detail.InnerException};if($detail -isnot [Data.SqlClient.SqlException] -or $detail.Number -notin $numbers){throw};$rejected=$true}
 Assert $rejected $message
}
function ApplyMigration{
 foreach($file in @('017_CRM_Suppliers.sql','018_CRM_Supplier_Tools.sql','019_CRM_Retire_Suppliers.sql')){
  $sql=[IO.File]::ReadAllText((Join-Path $PSScriptRoot $file))
  foreach($batch in [regex]::Split($sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')){if($batch.Trim()){[void](Q $batch)}}
 }
}
function Payload([string]$accountName,[int]$type,[int[]]$brands=@(1,2),[bool]$includeBrands=$true,[int]$owner=2){
 $coverage=if($includeBrands){'<Supplier_Brands>'+(($brands|ForEach-Object{'<Brand ID="'+$_+'" />'}) -join '')+'</Supplier_Brands>'}else{''}
 return '<row><Name_AR>'+[Security.SecurityElement]::Escape($accountName)+'</Name_AR><Name_EN>Test supplier account</Name_EN><Account_Type_ID>'+$type+'</Account_Type_ID><Brand_ID>1</Brand_ID><Owner_ID>'+$owner+'</Owner_ID><Is_Active>1</Is_Active>'+$coverage+'</row>'
}
function SaveAccount([int]$id,[string]$xml,[int]$actor=1,[byte[]]$version=$null){
 $parameters=@{'@a'=$actor;'@id'=$id;'@x'=$xml};$sql='EXEC dbo.CRM_Save_Accounts @Actor_ID=@a,@ID=@id,@Data=@x'
 if($version){$parameters['@v']=$version;$sql+=',@Version=@v'}
 return (Q $sql $parameters).Rows[0]
}
function Account([int]$id){return (Q 'SELECT * FROM dbo.CRM_Accounts WHERE ID=@id' @{'@id'=$id}).Rows[0]}
function AddTool([int]$supplier,[int]$station=1,[int]$actor=1){return (Q "EXEC dbo.Insert_JobTitle_Items @JobTitle_ID=@j,@Title_Ar=N'أداة اختبار إضافية',@Title_En=N'Additional test tool',@Supplier_Account_ID=@s,@AddedUser=@a,@MaintenanceCompanyID=1,@ItemTypeID=1" @{'@j'=$station;'@s'=$supplier;'@a'=$actor}).Rows[0].NewID}
function EditTool([int]$id,[int]$supplier,[int]$station=1,[int]$actor=1){[void](Q "EXEC dbo.Update_JobTitle_Items_ByID @ID=@id,@JobTitle_ID=@j,@Title_Ar=N'أداة تاريخية معدلة',@Title_En=N'Updated historical tool',@Supplier_Account_ID=@s,@ModifyUser=@a,@MaintenanceCompanyID=1,@ItemTypeID=1" @{'@id'=$id;'@j'=$station;'@s'=$supplier;'@a'=$actor})}
try{
 # Copy definitions and TOP(0) schemas only. Never copy application rows, logins or credentials.
 [void](Sql $master.ConnectionString "CREATE DATABASE [$name]");$created=$true
 $tables=@('UsersMembers','Users_Types','Brands','Branches','Departments','JobTitles','JobTitle_Items','JobTitle_Items_Types','Maintenance_Companies','CRM_Account_Types','CRM_Accounts','CRM_Contacts','CRM_Contract_Types','CRM_Payment_Methods','CRM_Activity_Logs','Customer_Logins')
 foreach($table in $tables){
  [void](Sql $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$($source.InitialCatalog)].dbo.[$table]")
  $computed=Sql $source.ConnectionString 'SELECT name,definition,is_persisted FROM sys.computed_columns WHERE object_id=OBJECT_ID(@table)' @{'@table'='dbo.'+$table}
  foreach($column in $computed.Rows){$escaped=([string]$column.name).Replace(']',']]');$persisted=if($column.is_persisted){' PERSISTED'}else{''};[void](Sql $test.ConnectionString ("ALTER TABLE dbo.[$table] DROP COLUMN [$escaped];ALTER TABLE dbo.[$table] ADD [$escaped] AS "+$column.definition+$persisted))}
  $indexes=Sql $source.ConnectionString 'SELECT name,is_primary_key,filter_definition,index_id FROM sys.indexes WHERE object_id=OBJECT_ID(@table) AND is_unique=1 AND is_hypothetical=0' @{'@table'='dbo.'+$table}
  foreach($index in $indexes.Rows){
   $columns=Sql $source.ConnectionString 'SELECT c.name FROM sys.index_columns i JOIN sys.columns c ON c.object_id=i.object_id AND c.column_id=i.column_id WHERE i.object_id=OBJECT_ID(@table) AND i.index_id=@index AND i.key_ordinal>0 ORDER BY i.key_ordinal' @{'@table'='dbo.'+$table;'@index'=$index.index_id}
   $keys=($columns.Rows|ForEach-Object{'['+([string]$_.name).Replace(']',']]')+']'}) -join ','
   if($index.is_primary_key){[void](Sql $test.ConnectionString "ALTER TABLE dbo.[$table] ADD PRIMARY KEY($keys)")}else{$filter=if($index.IsNull('filter_definition')){''}else{' WHERE '+$index.filter_definition};$indexName=([string]$index.name).Replace(']',']]');[void](Sql $test.ConnectionString "CREATE UNIQUE INDEX [$indexName] ON dbo.[$table]($keys)$filter")}
  }
  $defaults=Sql $source.ConnectionString 'SELECT c.name,d.definition FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID(@table)' @{'@table'='dbo.'+$table}
  foreach($column in $defaults.Rows){$escaped=([string]$column.name).Replace(']',']]');[void](Sql $test.ConnectionString ("ALTER TABLE dbo.[$table] ADD DEFAULT "+$column.definition+" FOR [$escaped]"))}
 }
 $db=[Data.SqlClient.SqlConnection]::new($test.ConnectionString);$db.Open()
 # Reconstruct the legacy shape independently so the test also works after source deployment.
 [void](Q @'
IF EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.CRM_Account_Types') AND name='UX_CRM_Account_Types_SystemCode') DROP INDEX UX_CRM_Account_Types_SystemCode ON dbo.CRM_Account_Types;
IF COL_LENGTH('dbo.CRM_Account_Types','System_Code') IS NOT NULL ALTER TABLE dbo.CRM_Account_Types DROP COLUMN System_Code;
IF COL_LENGTH('dbo.JobTitle_Items','Supplier_Account_ID') IS NOT NULL ALTER TABLE dbo.JobTitle_Items DROP COLUMN Supplier_Account_ID;
IF COL_LENGTH('dbo.JobTitle_Items','SupplierID') IS NULL ALTER TABLE dbo.JobTitle_Items ADD SupplierID int NULL;
CREATE TABLE dbo.Suppliers(ID int IDENTITY(1,1) PRIMARY KEY,Title_Ar nvarchar(max) NULL,Title_En nvarchar(max) NULL,Item_Order int NULL,IsActive bit NULL,IsDeleted bit NULL,AddedUser int NULL,AddedDate datetime NULL,ModifyUser int NULL,ModifyDate datetime NULL);
ALTER TABLE dbo.JobTitle_Items ADD CONSTRAINT FK_JobTitle_Items_Suppliers FOREIGN KEY(SupplierID) REFERENCES dbo.Suppliers(ID);
'@)
 foreach($proc in @('Insert_Suppliers','Select_Suppliers_All','Select_Suppliers_ByID','Update_Suppliers_ByID','Update_Suppliers_IsActive_ByID','Update_Suppliers_IsDeleted_ByID')){[void](Q ("CREATE OR ALTER PROCEDURE dbo.[$proc] AS SELECT ID FROM dbo.Suppliers;"))}
 foreach($function in @('CRM_CanAccess','CRM_CheckUser')){
  $definition=(Sql $source.ConnectionString 'SELECT OBJECT_DEFINITION(OBJECT_ID(@name)) Definition' @{'@name'='dbo.'+$function}).Rows[0].Definition
  if($definition -is [DBNull]){throw "Required CRM definition missing: $function"}
  [void](Q ([regex]::Replace([string]$definition,'(?i)\b(?:CREATE\s+OR\s+ALTER|CREATE|ALTER)\s+(FUNCTION|PROCEDURE|PROC)\b','CREATE OR ALTER $1')))
 }
 [void](Q @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','Test admin',1,0),(4,N'موظف اختبار','Test employee',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,Fullname_En,UserName,Type,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','Test administrator','supplier-admin',1,1,0),(2,N'مسؤول اختبار','Test owner','supplier-owner',4,1,0);SET IDENTITY_INSERT UsersMembers OFF;
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'علامة أولى','Brand one',1,0),(2,N'علامة ثانية','Brand two',1,0),(3,N'علامة ثالثة','Brand three',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'فرع أول','Branch one',1,0),(2,2,N'فرع ثان','Branch two',1,0),(3,3,N'فرع ثالث','Branch three',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT Departments ON;INSERT Departments(ID,BranchID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'قسم أول','Department one',1,0),(2,2,N'قسم ثان','Department two',1,0),(3,3,N'قسم ثالث','Department three',1,0);SET IDENTITY_INSERT Departments OFF;
SET IDENTITY_INSERT JobTitles ON;INSERT JobTitles(ID,DepartmentID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'محطة أولى','Station one',1,0),(2,2,N'محطة ثانية','Station two',1,0),(3,3,N'محطة ثالثة','Station three',1,0);SET IDENTITY_INSERT JobTitles OFF;
SET IDENTITY_INSERT JobTitle_Items_Types ON;INSERT JobTitle_Items_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'نوع أداة','Tool type',1,0);SET IDENTITY_INSERT JobTitle_Items_Types OFF;
SET IDENTITY_INSERT Maintenance_Companies ON;INSERT Maintenance_Companies(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'صيانة اختبار','Test maintenance',1,0);SET IDENTITY_INSERT Maintenance_Companies OFF;
SET IDENTITY_INSERT CRM_Account_Types ON;INSERT CRM_Account_Types(ID,Name_AR,Name_EN,Is_Active,Is_Deleted,AddedUser) VALUES(99,N'نوع آخر','Other type',1,0,1);SET IDENTITY_INSERT CRM_Account_Types OFF;
INSERT Suppliers(Title_Ar,Title_En,Item_Order,IsActive,IsDeleted,AddedUser,AddedDate,ModifyUser,ModifyDate) VALUES(N'مورد قديم مرتبط','Linked legacy supplier',7,1,0,1,'20250102',1,'20250203'),(N'مورد قديم مستقل','Unlinked legacy supplier',8,0,0,1,'20250304',NULL,NULL);
INSERT JobTitle_Items(JobTitle_ID,Title_Ar,Title_En,Tool_Number,SupplierID,MaintenanceCompanyID,ItemTypeID,AddedUser,AddedDate,IsActive,IsDeleted) VALUES(1,N'أداة قديمة','Legacy tool','LEGACY-001',1,1,1,1,'20250102',1,0);
INSERT CRM_Accounts(Name_AR,Name_EN,Account_Type_ID,Brand_ID,Is_Active,Is_Deleted,AddedUser) VALUES(N'مورد قديم مرتبط','Conflicting account',99,1,1,0,1);
'@)
 # An ambiguous existing identity must roll back the complete migration, including DDL.
 $tx=$db.BeginTransaction();$rolledBack=$false
 try{ApplyMigration}catch{$detail=$_.Exception;while($detail.InnerException){$detail=$detail.InnerException};if($detail -isnot [Data.SqlClient.SqlException] -or $detail.Number -ne 51201){throw};$rolledBack=$true}finally{if($tx.Connection){$tx.Rollback()};$tx=$null}
 Assert $rolledBack 'A legacy supplier matching a different customer type rejects migration'
 $rollback=(Q "SELECT COL_LENGTH('dbo.CRM_Account_Types','System_Code') CodeColumn,OBJECT_ID('dbo.CRM_Supplier_Brands') Coverage,COL_LENGTH('dbo.JobTitle_Items','SupplierID') LegacyColumn,(SELECT COUNT(*) FROM Suppliers) Suppliers,(SELECT COUNT(*) FROM JobTitle_Items WHERE SupplierID=1) Tools,(SELECT COUNT(*) FROM CRM_Accounts) Accounts").Rows[0]
 Assert ($rollback.IsNull('CodeColumn') -and $rollback.IsNull('Coverage') -and !$rollback.IsNull('LegacyColumn') -and $rollback.Suppliers -eq 2 -and $rollback.Tools -eq 1 -and $rollback.Accounts -eq 1) 'A rejected migration restores schema, suppliers, accounts and tool links'
 [void](Q 'DELETE FROM dbo.CRM_Accounts')
 $tx=$db.BeginTransaction();try{ApplyMigration;$tx.Commit()}catch{if($tx.Connection){$tx.Rollback()};throw}finally{$tx=$null}
 $supplierType=[int](Q "SELECT ID FROM CRM_Account_Types WHERE System_Code='SUPPLIER'").Rows[0].ID
 $linked=(Q "SELECT * FROM CRM_Accounts WHERE Name_AR=N'مورد قديم مرتبط'").Rows[0];$linkedID=[int]$linked.ID
 $unlinked=(Q "SELECT * FROM CRM_Accounts WHERE Name_AR=N'مورد قديم مستقل'").Rows[0]
 Assert ($linked.Account_Type_ID -eq $supplierType -and $linked.Brand_ID -eq 1 -and $linked.Name_EN -eq 'Linked legacy supplier' -and $linked.Is_Active -and $linked.AddedDate -eq [datetime]'2025-01-02' -and $linked.Modified_Date -eq [datetime]'2025-02-03') 'Linked supplier bilingual identity, status, timestamps and evidenced primary brand survive migration'
 Assert ($unlinked.IsNull('Brand_ID') -and !$unlinked.Is_Active -and (Q 'SELECT * FROM CRM_Supplier_Brands WHERE Account_ID=@id' @{'@id'=$unlinked.ID}).Rows.Count -eq 0 -and (Q 'SELECT * FROM Customer_Logins').Rows.Count -eq 0) 'An unlinked supplier receives no guessed brand or customer login'
 Assert ((Q 'SELECT * FROM CRM_Supplier_Brands WHERE Account_ID=@id AND Brand_ID=1' @{'@id'=$linkedID}).Rows.Count -eq 1 -and (Q 'SELECT * FROM JobTitle_Items WHERE ID=1 AND Supplier_Account_ID=@id' @{'@id'=$linkedID}).Rows.Count -eq 1) 'Legacy tool and supplier coverage retain their exact relationship'
 $retired=(Q "SELECT OBJECT_ID('dbo.Suppliers') LegacyTable,COL_LENGTH('dbo.JobTitle_Items','SupplierID') LegacyColumn,(SELECT COUNT(*) FROM sys.procedures WHERE name IN('Insert_Suppliers','Select_Suppliers_All','Select_Suppliers_ByID','Update_Suppliers_ByID','Update_Suppliers_IsActive_ByID','Update_Suppliers_IsDeleted_ByID')) LegacyProcedures").Rows[0]
 Assert ($retired.IsNull('LegacyTable') -and $retired.IsNull('LegacyColumn') -and $retired.LegacyProcedures -eq 0) 'Legacy supplier table, foreign key column and all six procedures are removed'
 $tx=$db.BeginTransaction();try{ApplyMigration;$tx.Commit()}catch{if($tx.Connection){$tx.Rollback()};throw}finally{$tx=$null}
 Assert ((Q 'SELECT * FROM CRM_Accounts').Rows.Count -eq 2 -and (Q "SELECT * FROM CRM_Activity_Logs WHERE Action=N'ترحيل المورد'").Rows.Count -eq 2) 'Repeating the migration creates no duplicate accounts, links or audit events'

 $saved=SaveAccount $linkedID (Payload 'مورد قديم مرتبط' $supplierType @(1,2)) 1 $linked.Row_Version
 Assert ((Q 'SELECT * FROM CRM_Supplier_Brands WHERE Account_ID=@id' @{'@id'=$linkedID}).Rows.Count -eq 2) 'A supplier can cover two brands through the CRM account editor contract'
 $audit=(Q "SELECT TOP(1) Before_Data,After_Data FROM CRM_Activity_Logs WHERE Account_ID=@id AND Action=N'تعديل' ORDER BY ID DESC" @{'@id'=$linkedID}).Rows[0]
 Assert ([string]$audit.Before_Data -match '<Brand_ID>1</Brand_ID>' -and [string]$audit.After_Data -match '<Brand_ID>2</Brand_ID>') 'Coverage changes appear in the atomic before and after audit snapshots'
 $newTool=[int](AddTool $linkedID 2)
 Assert ((Q 'SELECT * FROM JobTitle_Items WHERE ID=@id AND Supplier_Account_ID=@s' @{'@id'=$newTool;'@s'=$linkedID}).Rows.Count -eq 1) 'One supplier can be linked to tools in both covered brands'
 $other=SaveAccount 0 (Payload 'عميل من نوع آخر' 99 @() $false)
 Rejected {AddTool ([int]$other.ID)} 'A customer of another type cannot be selected as a tool supplier'
 Rejected {AddTool $linkedID 3} 'A supplier cannot be linked to tools in an uncovered third brand'
 Rejected {AddTool $linkedID 1 2} 'A nonadministrator cannot save tool supplier assignments'
 Rejected {SaveAccount $linkedID (Payload 'مورد قديم مرتبط' $supplierType @(1,2)) 1 $linked.Row_Version} 'A stale customer version cannot overwrite supplier coverage'
 Rejected {SaveAccount $linkedID (Payload 'مورد قديم مرتبط' $supplierType @(1,2)) 2 (Account $linkedID).Row_Version} 'A CRM account owner cannot modify supplier coverage'
 Rejected {SaveAccount $linkedID (Payload 'مورد قديم مرتبط' 99 @() $false) 2 (Account $linkedID).Row_Version} 'A CRM account owner cannot change supplier eligibility'
 Rejected {SaveAccount $linkedID (Payload 'مورد قديم مرتبط' $supplierType @(2)) 1 (Account $linkedID).Row_Version} 'A supplier brand used by an existing tool cannot be removed'
 Rejected {SaveAccount $linkedID (Payload 'مورد قديم مرتبط' 99 @() $false) 1 (Account $linkedID).Row_Version} 'Even an administrator cannot change the type of a supplier linked to tools'
 Rejected {[void](Q "EXEC CRM_Delete @Actor_ID=1,@Entity=N'Accounts',@ID=@id,@Version=@v" @{'@id'=$linkedID;'@v'=(Account $linkedID).Row_Version})} 'A supplier referenced by tools cannot be deleted'
 Rejected {[void](Q "EXEC CRM_Delete @Actor_ID=1,@Entity=N'Account_Types',@ID=@id,@Version=@v" @{'@id'=$supplierType;'@v'=(Q 'SELECT Row_Version FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$supplierType}).Rows[0].Row_Version})} 'The stable supplier customer type cannot be deleted'
 foreach($state in @('Account','Type','Brand')){
  $pause=switch($state){'Account'{"UPDATE CRM_Accounts SET Is_Active=0 WHERE ID=$linkedID"};'Type'{"UPDATE CRM_Account_Types SET Is_Active=0 WHERE ID=$supplierType"};'Brand'{'UPDATE Brands SET IsActive=0 WHERE ID=1'}}
  $resume=$pause.Replace('=0','=1');[void](Q $pause)
  try{
   Rejected {AddTool $linkedID 1} "A paused $state cannot be newly assigned to tools"
   EditTool 1 $linkedID 1
   Assert ((Q 'SELECT Title_En FROM JobTitle_Items WHERE ID=1').Rows[0].Title_En -eq 'Updated historical tool') "An unchanged historical link remains editable when its $state is paused"
  }finally{[void](Q $resume)}
 }
 Rejected {EditTool 1 $linkedID 3} 'Editing an existing tool cannot bypass supplier brand coverage'
 foreach($reader in @(
  'EXEC dbo.Select_JobTitle_Items_All',
  'EXEC dbo.Select_JobTitle_Items_ByID @ID=1',
  'EXEC dbo.Select_JobTitle_Items_ByJobTitle_ID @JobTitle_ID=1',
  'EXEC dbo.Select_JobTitle_Items_Filter @JobTitle_ID=1',
  'EXEC dbo.Select_JobTitle_Items_Filter_V2 @BrandID=1',
  'EXEC dbo.Select_JobTitle_Items_FullDetails_ByID @JobTitle_ItemsID=1',
  'EXEC dbo.Select_JobTitle_Items_Search @BrandID=1'
 )){$rows=Q $reader;Assert ($rows.Rows.Count -gt 0 -and $rows.Columns.Contains('Supplier_Account_ID') -and $rows.Rows[0].Supplier_Title_Ar -eq 'مورد قديم مرتبط') ('Supplier-aware tool reader remains callable: '+$reader)}
 $options=Q 'EXEC dbo.CRM_Supplier_Options @Actor_ID=1'
 Assert ($options.Columns.Contains('Brand_IDs') -and @($options.Rows|Where-Object ID -eq $linkedID).Count -eq 1) 'Supplier option procedures expose the expected lookup result rather than an authorization result set'
 $typeOptions=Q 'EXEC dbo.CRM_Supplier_Type @Actor_ID=1'
 $brandOptions=Q 'EXEC dbo.CRM_Supplier_Brand_Options @Actor_ID=1,@Account_ID=@id' @{'@id'=$linkedID}
 Assert ($typeOptions.Columns.Contains('ID') -and $typeOptions.Rows.Count -eq 1 -and $typeOptions.Rows[0].ID -eq $supplierType -and $brandOptions.Columns.Contains('Is_Selected') -and @($brandOptions.Rows|Where-Object Is_Selected).Count -eq 2) 'Supplier type and brand pickers return their expected single result shape'
 Rejected {[void](Q 'EXEC dbo.CRM_Supplier_Options @Actor_ID=2')} 'A CRM owner cannot enumerate the administrator supplier picker'
 Assert ((Q "SELECT * FROM CRM_Activity_Logs WHERE Entity=N'JobTitle_Items' AND Action=N'إضافة أداة'").Rows.Count -ge 1 -and (Q "SELECT * FROM CRM_Activity_Logs WHERE Entity=N'JobTitle_Items' AND Action=N'تعديل أداة'").Rows.Count -ge 3) 'Tool creation and historical edits retain their audit records'
 if($KeepDatabase){[IO.File]::WriteAllText((Join-Path $output 'database.txt'),$name)}
 [IO.File]::WriteAllText((Join-Path $output 'passed.txt'),[DateTime]::UtcNow.ToString('o'))
 $passed=$true;Write-Output ('Supplier migration and integration checks passed. Synthetic database: '+$name)
}finally{
 if($tx -and $tx.Connection){$tx.Rollback()};if($db){$db.Dispose()}
 if($created -and (!$KeepDatabase -or !$passed) -and $name -match '^Prosto_Suppliers_Test_[a-f0-9]{32}$' -and $name -ne $source.InitialCatalog){[Data.SqlClient.SqlConnection]::ClearAllPools();[void](Sql $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$name]")}
}
