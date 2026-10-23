param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/employee-hr-build')
$ErrorActionPreference='Stop'
$portal=Join-Path $PSScriptRoot '../../Portal'
$compiler=Join-Path $PSScriptRoot '../../Prosto_ERP_API/bin/roslyn/csc.exe'
if(!(Test-Path -LiteralPath $compiler)){$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'}
$refs=@('CRM.dll','Prosto_ERP_ClassLibrary.dll','Newtonsoft.Json.dll','System.Net.Http.WinHttpHandler.dll')|ForEach-Object{'/reference:'+(Join-Path $BuildDirectory $_)}
& $compiler /nologo /target:exe ('/out:'+(Join-Path $BuildDirectory 'EmployeeHRTests.exe')) /reference:System.Web.dll /reference:System.Data.dll /reference:System.Net.Http.dll @refs (Join-Path $PSScriptRoot 'EmployeeHR.Tests.cs')
if($LASTEXITCODE -ne 0){throw 'HR test compilation failed.'}
$runtimeConfig=[xml][IO.File]::ReadAllText((Join-Path $portal 'Web.config'))
$testConfig=[xml]'<configuration/>'
[void]$testConfig.DocumentElement.AppendChild($testConfig.ImportNode($runtimeConfig.configuration.runtime,$true))
$testConfig.Save((Join-Path $BuildDirectory 'EmployeeHRTests.exe.config'))
& (Join-Path $BuildDirectory 'EmployeeHRTests.exe')
if($LASTEXITCODE -ne 0){throw 'HR contract tests failed.'}

# Read-only routing/authorization query over existing schema; no migration or real data copied.
$helper=[IO.File]::ReadAllText((Join-Path $portal 'AppCode/EmployeeHRData.vb'))
$contextSql=[regex]::Match($helper,'(?s)Private Const ContextSql As String = "(.*?)"').Groups[1].Value
if(!$contextSql){throw 'HR context query not found.'}
function Context([int]$actor,[int]$employee){return ,(Query $test.ConnectionString ("DECLARE @Actor int=$actor,@EmployeeID int=$employee;"+$contextSql))}
$config=[xml](Get-Content -LiteralPath (Join-Path $portal 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Only local SQL Server is supported.'}
$name='Prosto_EmployeeHR_Test_'+[guid]::NewGuid().ToString('N')
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
function Query([string]$connection,[string]$sql){$cn=[Data.SqlClient.SqlConnection]::new($connection);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=60;$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cn.Dispose()}}
function Check([bool]$value,[string]$message){if(!$value){throw $message};"PASS: $message"}
function Denied([string]$sql,[string]$message){$blocked=$false;try{[void](Query $test.ConnectionString $sql)}catch{if($_.Exception.ToString().Contains('Access denied.')){$blocked=$true}else{throw}};Check $blocked $message}
$created=$false
try{
 [void](Query $master.ConnectionString "CREATE DATABASE [$name]");$created=$true
 [void](Query $test.ConnectionString @'
 CREATE TABLE dbo.Brands(ID int PRIMARY KEY,Title_Ar nvarchar(200),IsActive bit,IsDeleted bit);
 CREATE TABLE dbo.Branches(ID int PRIMARY KEY,BrandID int,Title_Ar nvarchar(200),IsActive bit,IsDeleted bit);
 CREATE TABLE dbo.UsersMembers(ID int PRIMARY KEY,Type int,Employee_Number int,FullName_Ar nvarchar(200),Brand_ID int,Branch_ID int,IsActive bit,IsDeleted bit);
 CREATE TABLE dbo.AttendanceIntegrationSettings(BrandID int PRIMARY KEY,HrUrl nvarchar(2000),HrUsername varbinary(max),HrPassword varbinary(max),Enabled bit);
 INSERT dbo.Brands VALUES(1,N'Brand one',1,0),(2,N'Brand two',1,0);
 INSERT dbo.Branches VALUES(1,1,N'Branch one',1,0),(2,2,N'Branch two',1,0);
 INSERT dbo.UsersMembers VALUES(1,1,1,N'Admin',1,1,1,0),(10,4,5,N'Owner',1,1,1,0),(20,4,5,N'Other tenant',2,2,1,0),(30,4,30,N'Inactive',1,1,0,0),(40,7,40,N'Retired',1,1,1,0);
 INSERT dbo.AttendanceIntegrationSettings VALUES(1,N'https://synthetic.example.test/',0x01,0x02,0);
'@)
 $row=Context 10 10
 Check ($row.Rows.Count -eq 1 -and $row.Rows[0].Employee_Number -eq 5 -and $row.Rows[0].Brand_ID -eq 1) 'Owner resolves own API routing identity'
 Check ($row.Rows[0].HrUrl -eq 'https://synthetic.example.test/' -and $row.Columns.Count -eq 6 -and !$row.Columns.Contains('FullName_Ar') -and !$row.Columns.Contains('BrandName')) 'Context returns routing/settings only, no display fields'
 Check ((Context 10 20).Rows.Count -eq 0) 'Employee cannot select another tenant employee'
 Check ((Context 30 10).Rows.Count -eq 0) 'Inactive actor rejected'
 Check ((Context 40 40).Rows.Count -eq 0) 'Retired customer identity rejected'
 Check ((Context 1 20).Rows.Count -eq 1) 'Admin can select employee in another active brand'
 [void](Query $test.ConnectionString "INSERT dbo.UsersMembers VALUES(11,4,5,N'Duplicate',1,1,1,0)")
 Check ((Context 1 10).Rows.Count -eq 0) 'Ambiguous employee number within brand rejected'
 [void](Query $test.ConnectionString 'UPDATE dbo.UsersMembers SET IsActive=0 WHERE ID=11; UPDATE dbo.Brands SET IsActive=0 WHERE ID=1')
 Check ((Context 1 10).Rows.Count -eq 0) 'Inactive target brand rejected'
 [void](Query $test.ConnectionString 'UPDATE dbo.Brands SET IsActive=1 WHERE ID=1; UPDATE dbo.UsersMembers SET IsDeleted=1 WHERE ID=10')
 Check ((Context 1 10).Rows.Count -eq 0) 'Deleted target rejected'
}finally{
 if($created){[void](Query $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$name]")}
}
