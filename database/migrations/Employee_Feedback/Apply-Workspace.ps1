param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
. (Join-Path $PSScriptRoot 'WorkspaceMigration.ps1')
$config=[xml][IO.File]::ReadAllText($ConfigPath)
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'This runner is restricted to local SQL Server.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $cn.Open();Backup-CrmLogoDatabase $cn;$tx=$cn.BeginTransaction()
 try {
  Apply-FeedbackWorkspace $cn $tx -Enable
  $tx.Commit();'Feedback workspace, exact customer branch scope and in-system notifications applied atomically; existing requests and logs retained.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
