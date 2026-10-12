param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$connection=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($connection.DataSource -notin @('localhost','.','(local)')){throw 'This apply script is restricted to local SQL Server. Deploy the reviewed SQL scripts through the server deployment process.'}
$cn=[Data.SqlClient.SqlConnection]::new($connection.ConnectionString)
$transaction=$null
try{
 $cn.Open()
 $cmd=$cn.CreateCommand();$cmd.CommandText="SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.Insert_Customer_Feedback_Request'))"
 $previous=$cmd.ExecuteScalar()
 if($previous -is [DBNull] -or -not $previous){throw 'Customer feedback migration 009 is required.'}
 $backup=Join-Path $PSScriptRoot ('../../../tmp/customer-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
 [void][IO.Directory]::CreateDirectory($backup)
 [IO.File]::WriteAllText((Join-Path $backup 'Insert_Customer_Feedback_Request.sql'),[string]$previous,[Text.UTF8Encoding]::new($true))
 foreach($procedure in @('Select_Work_Guide_Access_Requests','Review_Work_Guide_Access_Request')){
  $cmd.CommandText="SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$procedure'))"
  $definition=$cmd.ExecuteScalar()
  if($definition -is [DBNull] -or -not $definition){throw 'Existing work-guide access-request migrations are required.'}
  [IO.File]::WriteAllText((Join-Path $backup ($procedure+'.sql')),[string]$definition,[Text.UTF8Encoding]::new($true))
 }
 $cmd.CommandText='SELECT ID,IsActive,IsDeleted FROM dbo.UsersMembers WHERE Type=7'
 $rows=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($rows);$rows|Export-Clixml -LiteralPath (Join-Path $backup 'retired-account-status.xml')
 $transaction=$cn.BeginTransaction()
 foreach($file in @('001_Accounts.sql','002_Services.sql','003_Portal.sql','005_WorkGuideIntegration.sql','004_MobileApi.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){
   if(-not $batch.Trim()){continue}
   $cmd=$cn.CreateCommand();$cmd.Transaction=$transaction;$cmd.CommandText=$batch;$cmd.CommandTimeout=120;[void]$cmd.ExecuteNonQuery();$cmd.Dispose()
  }
 }
 $transaction.Commit();$transaction=$null
 'Customer portal migrations applied atomically. Legacy external identities are disabled; historical rows are retained.'
 "Previous procedure and account statuses: $backup"
}catch{
 if($transaction){try{$transaction.Rollback()}catch{}}
 throw
}finally{$cn.Dispose()}
