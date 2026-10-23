param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
. (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
$stagedLogos=[Collections.Generic.List[string]]::new()
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$connection=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($connection.DataSource -notin @('localhost','.','(local)')){throw 'This apply script is restricted to local SQL Server. Deploy the reviewed SQL scripts through the server deployment process.'}
$cn=[Data.SqlClient.SqlConnection]::new($connection.ConnectionString)
$transaction=$null
try{
 $cn.Open()
 Backup-CrmLogoDatabase $cn
 $cmd=$cn.CreateCommand();$cmd.CommandText="SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.Insert_Customer_Feedback_Request'))"
 $previous=$cmd.ExecuteScalar()
 if($previous -is [DBNull] -or -not $previous){throw 'Customer feedback migration 009 is required.'}
 $backup=Join-Path $PSScriptRoot ('../../../tmp/customer-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
 [void][IO.Directory]::CreateDirectory($backup)
 [IO.File]::WriteAllText((Join-Path $backup 'Insert_Customer_Feedback_Request.sql'),[string]$previous,[Text.UTF8Encoding]::new($true))
 $cmd.CommandText='SELECT ID,IsActive,IsDeleted FROM dbo.UsersMembers WHERE Type=7'
 $rows=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($rows);$rows|Export-Clixml -LiteralPath (Join-Path $backup 'retired-account-status.xml')
 $transaction=$cn.BeginTransaction()
 foreach($file in @('001_Accounts.sql','002_Services.sql','003_Portal.sql','004_MobileApi.sql','006_Dashboard.sql','007_SelfService.sql','008_ContactJobTitles.sql','../News/002_BilingualDetails.sql','010_BrandNews.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){
   if(-not $batch.Trim()){continue}
   $cmd=$cn.CreateCommand();$cmd.Transaction=$transaction;$cmd.CommandText=$batch;$cmd.CommandTimeout=120;[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
  }
 }
 Export-CrmLogoFiles $cn $transaction (Join-Path $PSScriptRoot '../../Portal/FileManager/CustomerLogos') $stagedLogos
 Apply-CrmFileLogoSql $cn $transaction (Join-Path $PSScriptRoot '../CRM')
 Apply-CrmAccountOrganization $cn $transaction;$transaction.Commit();$transaction=$null
 'Customer portal migrations applied atomically. Legacy external identities are disabled; historical rows are retained.'
 "Previous procedure and account statuses: $backup"
}catch{
 if($transaction){try{$transaction.Rollback()}catch{}}
 Remove-CrmStagedLogos $stagedLogos
 throw
}finally{$cn.Dispose()}
