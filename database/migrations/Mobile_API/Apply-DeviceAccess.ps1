$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/ProstoERP.Api/Web.config'))
$connection=New-Object System.Data.SqlClient.SqlConnection (($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $connection.Open(); $transaction=$connection.BeginTransaction()
 try {
  foreach($batch in [regex]::Split(([IO.File]::ReadAllText((Join-Path $PSScriptRoot '006_DeviceAccess.sql'))+[Environment]::NewLine+[IO.File]::ReadAllText((Join-Path $PSScriptRoot '008_BIOLogin.sql'))),'(?im)^GO\s*$')) {
   if(!$batch.Trim()){continue}
   $command=$connection.CreateCommand();$command.Transaction=$transaction;$command.CommandText=$batch;$command.CommandTimeout=90
   [void]$command.ExecuteNonQuery();$command.Dispose()
  }
  $transaction.Commit()
  'Device access migration applied. Historic records retained; tokens now require an approved device .'
 } catch {try{$transaction.Rollback()}catch{};throw} finally {$transaction.Dispose()}
} finally {$connection.Dispose()}
