# Reassert canonical customer membership contracts after older feature migrations.
# Caller owns a verified backup and transaction. Existing installations opt in via Apply-AccountOrganization.
function Apply-CrmAccountOrganization([Data.SqlClient.SqlConnection]$Connection,[Data.SqlClient.SqlTransaction]$Transaction,[switch]$Enable) {
 $cmd=$Connection.CreateCommand();$cmd.Transaction=$Transaction;$cmd.CommandTimeout=120
 try {
  $cmd.CommandText="SELECT CASE WHEN OBJECT_ID('dbo.CRM_Account_Brands','U') IS NOT NULL THEN 1 ELSE 0 END"
  if(-not $Enable -and [int]$cmd.ExecuteScalar() -ne 1){return}
  $cmd.CommandText="DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Lock<0 THROW 51201,'CRM is busy.',1;"
  [void]$cmd.ExecuteNonQuery()
  $files=@('020_CRM_Account_Organization.sql')
  $cmd.CommandText="SELECT CASE WHEN OBJECT_ID('dbo.CRM_WorkGuide_Access','U') IS NOT NULL THEN 1 ELSE 0 END";if([int]$cmd.ExecuteScalar() -eq 1){$files+='021_CRM_MultiBrand_WorkGuide.sql'}
  $cmd.CommandText="SELECT CASE WHEN OBJECT_ID('dbo.News','U') IS NOT NULL AND OBJECT_ID('dbo.Information_Page_Customers','U') IS NOT NULL AND OBJECT_ID('dbo.Circulars','U') IS NOT NULL THEN 1 ELSE 0 END";if([int]$cmd.ExecuteScalar() -eq 1){$files+='022_CRM_MultiBrand_Content.sql'}
  foreach($file in $files){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){$cmd.CommandText=$batch;[void]$cmd.ExecuteNonQuery()}};Write-Output "$file applied"}
  . (Join-Path $PSScriptRoot '../Employee_Feedback/WorkspaceMigration.ps1')
  Apply-FeedbackWorkspace $Connection $Transaction
 }finally{$cmd.Dispose()}
}
