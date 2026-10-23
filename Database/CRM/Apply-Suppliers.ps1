param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot 'FileLogoMigration.ps1')
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'Use the local deployment runner.'}
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $connection.Open()
 Backup-CrmLogoDatabase $connection
 $transaction=$connection.BeginTransaction()
 try {
  $command=$connection.CreateCommand();$command.Transaction=$transaction;$command.CommandTimeout=120
  $command.CommandText="DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Lock<0 THROW 51201,'CRM is busy.',1;"
  [void]$command.ExecuteNonQuery()
  foreach($file in @('017_CRM_Suppliers.sql','018_CRM_Supplier_Tools.sql','019_CRM_Retire_Suppliers.sql')) {
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')) {
    if([string]::IsNullOrWhiteSpace($batch)){continue}
    $command.CommandText=$batch
    [void]$command.ExecuteNonQuery()
   }
   Write-Output "$file applied"
  }
  $command.CommandText="IF OBJECT_ID('dbo.Suppliers','U') IS NOT NULL OR COL_LENGTH('dbo.JobTitle_Items','SupplierID') IS NOT NULL THROW 51201,'Legacy supplier objects remain.',1;IF EXISTS(SELECT 1 FROM dbo.JobTitle_Items i LEFT JOIN dbo.CRM_Accounts a ON a.ID=i.Supplier_Account_ID WHERE i.Supplier_Account_ID IS NOT NULL AND a.ID IS NULL) THROW 51201,'A supplier link was lost.',1;"
  [void]$command.ExecuteNonQuery()
  Apply-CrmAccountOrganization $connection $transaction;$transaction.Commit()
  Write-Output 'Supplier accounts, tool links and retirement committed atomically.'
 }catch{if($transaction.Connection){$transaction.Rollback()};throw}
}finally{$connection.Dispose()}
