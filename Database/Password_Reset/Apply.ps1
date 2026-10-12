$ErrorActionPreference='Stop'
$cfg=[xml][IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../Prosto_ERP_API/Web.config'))
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($cfg.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'Only configured local SQL Server is supported.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $cn.Open();$transaction=$cn.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_PasswordReset.sql')),'(?im)^\s*GO\s*$')){
   if(!$batch.Trim()){continue};$cmd=$cn.CreateCommand();$cmd.Transaction=$transaction;$cmd.CommandText=$batch;$cmd.CommandTimeout=90;[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
  }
  $transaction.Commit();'Password reset schema installed; no passwords changed and no email sent.'
 }catch{if($transaction.Connection){$transaction.Rollback()};throw}finally{$transaction.Dispose()}
}finally{$cn.Dispose()}
