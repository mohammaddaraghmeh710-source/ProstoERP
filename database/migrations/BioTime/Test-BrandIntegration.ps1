param([switch]$ApplyLocalMigration)
$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$source=New-Object System.Data.SqlClient.SqlConnectionStringBuilder (($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Only local SQL Server is supported by this script.'}
$master=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
$master['Initial Catalog']='master'
function Execute([string]$connection,[string]$sql){
 $cn=New-Object System.Data.SqlClient.SqlConnection $connection
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandTimeout=60;$cmd.CommandText=$sql;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}
}
$script=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '002_BrandIntegration.sql'))+[Environment]::NewLine+[IO.File]::ReadAllText((Join-Path $PSScriptRoot '003_IntegrationUrlsAndHR.sql'))+[Environment]::NewLine+[IO.File]::ReadAllText((Join-Path $PSScriptRoot '004_AdminSecrets.sql'))
if($ApplyLocalMigration){
 foreach($batch in [regex]::Split($script,'(?im)^\s*GO\s*$')){if($batch.Trim()){Execute $source.ConnectionString $batch}}
 Write-Output 'Attendance migration applied to configured local database.'
 exit
}
$database='Prosto_Attendance_Test_'+[Guid]::NewGuid().ToString('N')
$test=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
$test['Initial Catalog']=$database
$created=$false
try{
 Execute $master.ConnectionString "CREATE DATABASE [$database]"; $created=$true
 Execute $test.ConnectionString @'
 CREATE TABLE dbo.Brands(ID int PRIMARY KEY,Title_Ar nvarchar(200),IsActive bit,IsDeleted bit);
 CREATE TABLE dbo.UsersMembers(ID int PRIMARY KEY,Type int,FullName_Ar nvarchar(200),Employee_Number int,Brand_ID int,IsActive bit,IsDeleted bit);
 INSERT dbo.Brands VALUES(1,N'Test one',1,0),(2,N'Test two',1,0);
 INSERT dbo.UsersMembers VALUES(1,1,N'Admin',1,1,1,0),(10,4,N'One',26,1,1,0),(20,4,N'Two',26,2,1,0),(21,4,N'Two distinct',99,2,1,0),(30,4,N'Inactive',30,1,0,0),(40,7,N'Retired',40,1,1,0);
'@
 foreach($batch in [regex]::Split($script,'(?im)^\s*GO\s*$')){if($batch.Trim()){Execute $test.ConnectionString $batch}}
 # Minimal existing login contract fixture for verifying legacy GetUser tenant isolation.
 $map=[xml][IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../../src/ProstoERP.Infrastructure/Generated/LinqToSql/Prosto_ERP_DataClasses.dbml'))
 $columns=$map.SelectNodes('//*[local-name()="Function" and @Method="Select_UsersMembers_ByUserName_Password"]/*[local-name()="ElementType"]/*[local-name()="Column"]')
 $selection=@($columns | ForEach-Object {
  $name=$_.GetAttribute('Name'); $type=$_.GetAttribute('DbType').Replace(' NOT NULL','')
  if($name -in @('ID','Type','Employee_Number','FullName_Ar','Brand_ID','IsDeleted','IsActive')){"u.[$name]"}else{"CAST(NULL AS $type) [$name]"}
 }) -join ','
 Execute $test.ConnectionString ("CREATE PROCEDURE dbo.Select_UsersMembers_ByUserName_Password @UserName nvarchar(max),@Password nvarchar(max) AS SELECT "+$selection+" FROM dbo.UsersMembers u WHERE u.ID=CASE WHEN @UserName=N'employee-one' THEN 10 ELSE 20 END")
 $env:BIOTIME_TEST_CONNECTION=$test.ConnectionString
 & (Join-Path $PSScriptRoot 'Test-BioTime.ps1')
 if($LASTEXITCODE -ne 0){throw 'Attendance tests failed.'}
}finally{
 Remove-Item Env:BIOTIME_TEST_CONNECTION -ErrorAction SilentlyContinue
 if($created){Execute $master.ConnectionString "ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$database]"}
}
