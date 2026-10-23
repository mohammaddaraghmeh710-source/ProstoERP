param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
$stagedLogos=[Collections.Generic.List[string]]::new()
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'This runner is restricted to local SQL Server; use reviewed migrations and a verified backup for other deployments.'}
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$tx=$null
try {
 $cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText="SELECT CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultBackupPath'))";$folder=[string]$cmd.ExecuteScalar();$cmd.Dispose()
 if(-not $folder){throw 'A verified full backup is required.'}
 $backup=Join-Path $folder ('CustomerSelfService-'+[guid]::NewGuid().ToString('N')+'.bak')
 $cmd=$cn.CreateCommand();$cmd.CommandTimeout=300;$cmd.CommandText='BACKUP DATABASE ['+$builder.InitialCatalog.Replace(']',']]')+'] TO DISK=@Path WITH COPY_ONLY,CHECKSUM;';[void]$cmd.Parameters.AddWithValue('@Path',$backup);[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
 $cmd=$cn.CreateCommand();$cmd.CommandTimeout=300;$cmd.CommandText='RESTORE VERIFYONLY FROM DISK=@Path WITH CHECKSUM;';[void]$cmd.Parameters.AddWithValue('@Path',$backup);[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
 $record=Join-Path $PSScriptRoot '../../../tmp/customer-self-service';[void][IO.Directory]::CreateDirectory($record);[IO.File]::WriteAllText((Join-Path $record 'verified-backup.txt'),$backup)
 "Verified full backup: $backup"
 $tx=$cn.BeginTransaction()
 foreach($file in @('../CRM/009_CRM_Contact_Names.sql','../CRM/008_CRM_Account_Logos.sql','../CRM/010_CRM_Inline_Logos.sql','../CRM/011_CRM_ContactTitles_Activity.sql','006_Dashboard.sql','007_SelfService.sql','008_ContactJobTitles.sql','../News/002_BilingualDetails.sql','010_BrandNews.sql')) {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')) {
   if(-not $batch.Trim()){continue};$cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandTimeout=120;$cmd.CommandText=$batch
   try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
  }
 }
 Export-CrmLogoFiles $cn $tx (Join-Path $PSScriptRoot '../../Portal/FileManager/CustomerLogos') $stagedLogos
 Apply-CrmFileLogoSql $cn $tx (Join-Path $PSScriptRoot '../CRM')
 $supplierCheck=$cn.CreateCommand();$supplierCheck.Transaction=$tx;$supplierCheck.CommandText="SELECT CASE WHEN COL_LENGTH('dbo.CRM_Account_Types','System_Code') IS NOT NULL THEN 1 ELSE 0 END"
 if([int]$supplierCheck.ExecuteScalar() -eq 1){foreach($supplierFile in @('017_CRM_Suppliers.sql','018_CRM_Supplier_Tools.sql','019_CRM_Retire_Suppliers.sql')){foreach($supplierBatch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot ('../CRM/'+$supplierFile))),'(?im)^\s*GO\s*$')){if(-not $supplierBatch.Trim()){continue};$supplierCheck.CommandText=$supplierBatch;[void]$supplierCheck.ExecuteNonQuery()}}};$supplierCheck.Dispose()
 Apply-CrmAccountOrganization $cn $tx;$tx.Commit();$tx=$null
 'Customer self-service, bilingual contacts, unified audit and verified FileManager logo migration applied atomically.'
}catch{if($tx){try{$tx.Rollback()}catch{}};Remove-CrmStagedLogos $stagedLogos;throw}finally{$cn.Dispose()}
