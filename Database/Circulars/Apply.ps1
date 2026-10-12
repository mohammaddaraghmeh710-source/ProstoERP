param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try{
 $cn.Open();$tx=$cn.BeginTransaction()
 try{
  foreach($file in @('001_Schema.sql','002_Procedures.sql')){
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^GO\s*$')){
    if(!$batch.Trim()){continue}
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=90
    try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
   }
  }
  $tx.Commit();'Circulars schema and procedures applied.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
