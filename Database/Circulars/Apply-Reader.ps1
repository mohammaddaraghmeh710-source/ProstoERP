param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
$config=[xml][IO.File]::ReadAllText($ConfigPath)
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $cn.Open();Backup-CrmLogoDatabase $cn;$tx=$cn.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '004_ReaderVersion.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){$cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=90;try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}}
  $tx.Commit();'Circular modal PDF version guards applied atomically; existing receipts and logs retained.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
