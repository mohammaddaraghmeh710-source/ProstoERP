param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot 'FileLogoMigration.ps1')
$cfg=[xml](Get-Content -LiteralPath $ConfigPath)
$connection=[Data.SqlClient.SqlConnection]::new([string]($cfg.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$transaction=$null;$files=[Collections.Generic.List[string]]::new()
try {
 $connection.Open();Backup-CrmLogoDatabase $connection
 $transaction=$connection.BeginTransaction()
 Export-CrmLogoFiles $connection $transaction (Join-Path $PSScriptRoot '../../Portal/FileManager/CustomerLogos') $files
 Apply-CrmFileLogoSql $connection $transaction $PSScriptRoot
 Apply-CrmAccountOrganization $connection $transaction;$transaction.Commit();$transaction=$null
 'Customer logos now use FileManager files and a Logo_Url on each customer; binary storage removed.'
}catch{if($transaction){try{$transaction.Rollback()}catch{}};Remove-CrmStagedLogos $files;throw}finally{$connection.Dispose()}
