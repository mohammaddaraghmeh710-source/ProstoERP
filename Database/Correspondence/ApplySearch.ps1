$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$connection=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $connection.Open();$transaction=$connection.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '005_Search_Fields.sql')),'(?im)^\s*GO\s*$')){
   if([string]::IsNullOrWhiteSpace($batch)){continue}
   $command=$connection.CreateCommand();$command.Transaction=$transaction;$command.CommandText=$batch
   try{[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
  }
  $transaction.Commit();'Correspondence module procedures applied.'
 }catch{if($transaction.Connection){$transaction.Rollback()};throw}
}finally{$connection.Dispose()}
