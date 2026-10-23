param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
try {
 $cn.Open()
 Backup-CrmLogoDatabase $cn
 $tx=$cn.BeginTransaction()
 try {
  foreach($file in @('007_Audience_Schema.sql','008_Audience_Procedures.sql')){
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){
    if(-not $batch.Trim()){continue}
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch
    try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
   }
  }
  Apply-CrmAccountOrganization $cn $tx;$tx.Commit();'Information-page audience permissions applied. Existing pages remain employee-only.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
