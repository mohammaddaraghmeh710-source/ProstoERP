param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'FileLogoMigration.ps1')
. (Join-Path $PSScriptRoot 'AccountOrganizationMigration.ps1')
$config=[xml][IO.File]::ReadAllText($ConfigPath)
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL Server required.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $cn.Open();Backup-CrmLogoDatabase $cn;$tx=$cn.BeginTransaction()
 try {
  Apply-CrmAccountOrganization $cn $tx -Enable
  $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText="IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Brand_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab WHERE ab.Account_ID=a.ID AND ab.Brand_ID=a.Brand_ID)) THROW 51201,'Legacy account brand was not retained.',1;IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts a WHERE a.Branch_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Branches abr WHERE abr.Account_ID=a.ID AND abr.Branch_ID=a.Branch_ID)) THROW 51201,'Legacy account branch was not retained.',1;SELECT (SELECT COUNT(*) FROM dbo.CRM_Account_Brands) BrandLinks,(SELECT COUNT(*) FROM dbo.CRM_Account_Branches) BranchLinks;"
  $table=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($table);$cmd.Dispose()
  $tx.Commit();$table|Format-Table -AutoSize;'Canonical customer memberships and protected content committed atomically.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
