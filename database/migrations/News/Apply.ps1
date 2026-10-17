param([int]$BackfillBrandID=0)
$ErrorActionPreference='Stop'
$cfg=[xml][IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../../src/ProstoERP.Api/Web.config'))
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($cfg.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'Only configured local SQL Server supported.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $cn.Open();$tx=$cn.BeginTransaction()
 try {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_BrandNews.sql')),'(?im)^\s*GO\s*$')) {
   if(!$batch.Trim()){continue};$cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=90;[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
  }
  if($BackfillBrandID -gt 0){
   $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText="IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@BrandID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51951,'Active brand required.',1; UPDATE dbo.News SET Brand_ID=@BrandID WHERE Brand_ID IS NULL; SELECT @@ROWCOUNT;"
   [void]$cmd.Parameters.AddWithValue('@BrandID',$BackfillBrandID);$updated=$cmd.ExecuteScalar();$cmd.Dispose()
  }
  $tx.Commit();"Brand news migration applied. Previously unassigned news updated: $updated"
 }catch{if($tx.Connection){$tx.Rollback()};throw}finally{$tx.Dispose()}
}finally{$cn.Dispose()}
