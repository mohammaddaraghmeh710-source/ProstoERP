param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
$config=[xml][IO.File]::ReadAllText($ConfigPath)
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL Server required.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$tx=$null
try{
 $cn.Open();Backup-CrmLogoDatabase $cn
 $tx=$cn.BeginTransaction()
 foreach($file in @('../News/002_BilingualDetails.sql','010_BrandNews.sql')){
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){
  if(-not $batch.Trim()){continue};$cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=120
  try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
 }
 }
 Apply-CrmAccountOrganization $cn $tx;$tx.Commit();$tx=$null;'Customer brand-news procedure applied.'
}catch{if($tx){$tx.Rollback()};throw}finally{$cn.Dispose()}
