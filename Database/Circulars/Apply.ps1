param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try{
 $cn.Open();Backup-CrmLogoDatabase $cn;$tx=$cn.BeginTransaction()
 try{
  foreach($file in @('001_Schema.sql','002_Procedures.sql','003_BrandedAudiences.sql','004_ReaderVersion.sql','../Email_Notification/001_BrandGmail.sql')){
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^GO\s*$')){
    if(!$batch.Trim()){continue}
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=90
    try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
   }
  }
  Apply-CrmAccountOrganization $cn $tx;$tx.Commit();'Circulars schema and procedures applied.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
