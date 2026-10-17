$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/ProstoERP.Api/Web.config'))
$builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder (($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'This helper applies only to configured local SQL Server.'}
$connection=New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
try {
 $connection.Open(); $transaction=$connection.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Rollback-BrandApiCredentials.sql')),'(?im)^\s*GO\s*$')) {
   if(!$batch.Trim()){continue}
   $command=$connection.CreateCommand();$command.Transaction=$transaction;$command.CommandText=$batch;$command.CommandTimeout=90
   [void]$command.ExecuteNonQuery();$command.Dispose()
  }
  $transaction.Commit()
  'Previous mobile login/device/news procedures restored; stored sessions and brand settings retained.'
 } catch {try{$transaction.Rollback()}catch{};throw} finally {$transaction.Dispose()}
} finally {$connection.Dispose()}