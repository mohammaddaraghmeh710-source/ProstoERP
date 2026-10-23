$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'WorkspaceMigration.ps1')
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$cs=[string]($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$connection=[Data.SqlClient.SqlConnection]::new($cs)
try {
 $connection.Open()
 $transaction=$connection.BeginTransaction()
 try {
  $command=$connection.CreateCommand()
  $command.Transaction=$transaction
  $command.CommandText=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '005_PermissionDefaults.sql'))
  try { [void]$command.ExecuteNonQuery() } finally { $command.Dispose() }
  Apply-FeedbackWorkspace $connection $transaction
  $transaction.Commit()
  'Employee feedback permission defaults saved.'
 } catch {
  if($transaction.Connection){$transaction.Rollback()}
  throw
 }
} finally { $connection.Dispose() }
