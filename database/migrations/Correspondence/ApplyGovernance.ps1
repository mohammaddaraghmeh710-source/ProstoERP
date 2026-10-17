param([string]$ConnectionString)
$ErrorActionPreference='Stop'
if(!$ConnectionString){
 $config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
 $ConnectionString=[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
}
$connection=[Data.SqlClient.SqlConnection]::new($ConnectionString)
try {
 $connection.Open();$transaction=$connection.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '006_Governance.sql')),'(?im)^\s*GO\s*$')){
   if([string]::IsNullOrWhiteSpace($batch)){continue}
   $command=$connection.CreateCommand();$command.Transaction=$transaction;$command.CommandTimeout=120;$command.CommandText=$batch
   try{[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
  }
  $transaction.Commit();'Correspondence governance applied atomically.'
 }catch{if($transaction.Connection){$transaction.Rollback()};throw}
}finally{$connection.Dispose()}
