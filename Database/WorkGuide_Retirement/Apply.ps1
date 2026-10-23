param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'This runner is restricted to local SQL Server. Use the reviewed SQL and a verified backup for other deployments.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$transaction=$null
function Execute([string]$sql){$cmd=$cn.CreateCommand();try{$cmd.CommandTimeout=300;$cmd.Transaction=$transaction;$cmd.CommandText=$sql;[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}
try {
 $cn.Open()
 $cmd=$cn.CreateCommand();$cmd.CommandText="SELECT CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultBackupPath'))";$folder=[string]$cmd.ExecuteScalar();$cmd.Dispose()
 if(-not $folder){throw 'SQL Server has no default backup directory. Create and verify a full backup before deployment.'}
 $backup=Join-Path $folder ('WorkGuideRetirement-'+[guid]::NewGuid().ToString('N')+'.bak')
 $cmd=$cn.CreateCommand();$cmd.CommandTimeout=300;$cmd.CommandText='BACKUP DATABASE '+('['+$builder.InitialCatalog.Replace(']',']]')+']')+' TO DISK=@Path WITH COPY_ONLY,CHECKSUM;';[void]$cmd.Parameters.AddWithValue('@Path',$backup);[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
 $cmd=$cn.CreateCommand();$cmd.CommandTimeout=300;$cmd.CommandText='RESTORE VERIFYONLY FROM DISK=@Path WITH CHECKSUM;';[void]$cmd.Parameters.AddWithValue('@Path',$backup);[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
 $record=Join-Path $PSScriptRoot '../../../tmp/work-guide-retirement';[void][IO.Directory]::CreateDirectory($record)
 [IO.File]::WriteAllText((Join-Path $record 'verified-backup.txt'),$backup)
 "Verified full COPY_ONLY backup: $backup"
 $transaction=$cn.BeginTransaction()
 # Refresh only shared customer procedures that previously referenced guide objects.
 $accounts=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/001_Accounts.sql'))
 foreach($batch in [regex]::Split($accounts,'(?im)^\s*GO\s*$')){if($batch -match 'CREATE OR ALTER PROCEDURE dbo.Customer_AdminData\b'){Execute $batch}}
 Execute ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_Remove.sql')))
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/006_Dashboard.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){Execute $batch}}
 $transaction.Commit();$transaction=$null
 'Work-guide tables, procedures, functions and related customer grants/API operations removed. Shared CRM credentials, contacts and feedback preserved; customer dashboard deployed.'
} catch {if($transaction){try{$transaction.Rollback()}catch{}};throw} finally {$cn.Dispose()}
