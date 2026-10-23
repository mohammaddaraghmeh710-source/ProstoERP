# Caller owns the verified backup and transaction. Preserve activated workspace contracts.
function Apply-FeedbackWorkspace([Data.SqlClient.SqlConnection]$Connection,[Data.SqlClient.SqlTransaction]$Transaction,[switch]$Enable) {
 $cmd=$Connection.CreateCommand();$cmd.Transaction=$Transaction;$cmd.CommandTimeout=120
 try {
  $cmd.CommandText="SELECT CASE WHEN OBJECT_ID('dbo.Feedback_PublishNotifications','P') IS NOT NULL THEN 1 ELSE 0 END"
  if(-not $Enable -and [int]$cmd.ExecuteScalar() -ne 1){return}
  $cmd.CommandText="SELECT CASE WHEN OBJECT_ID('dbo.Customer_Logins','U') IS NOT NULL AND OBJECT_ID('dbo.CRM_Account_Branches','U') IS NOT NULL AND OBJECT_ID('dbo.Employee_Feedback_Views','U') IS NOT NULL THEN 1 ELSE 0 END"
  if([int]$cmd.ExecuteScalar() -ne 1){throw 'Current employee feedback, customer portal and CRM account organization migrations are required.'}
  foreach($file in @('007_TypesAndApplicant.sql','008_DashboardDailyActivity.sql','009_CustomerSupport.sql','010_WorkspaceNotifications.sql','../CustomerPortal/012_FeedbackWorkspace.sql')){
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){$cmd.CommandText=$batch;[void]$cmd.ExecuteNonQuery()}}
  }
 }finally{$cmd.Dispose()}
}
