param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../CRM/AccountOrganizationMigration.ps1')
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $cn.Open(); $tx=$cn.BeginTransaction()
 try {
  foreach($file in @('001_Schema.sql','003_Access_Restore_Schema.sql','005_Brand_Access_Schema.sql','006_Brand_Access_Procedures.sql','004_Access_Restore_Procedures.sql','002_Procedures.sql','007_Audience_Schema.sql','008_Audience_Procedures.sql')) {
   foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')) {
    if([string]::IsNullOrWhiteSpace($batch)){continue}
    $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch
    try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
   }
  }
  # Update only this dependent mobile procedure, never replay mobile login/session migrations.
  $exists=$cn.CreateCommand();$exists.Transaction=$tx;$exists.CommandText="SELECT COUNT(*) FROM sys.procedures WHERE object_id=OBJECT_ID('dbo.MobileApi_InfoPages')"
  try{$hasMobile=[int]$exists.ExecuteScalar() -gt 0}finally{$exists.Dispose()}
  if($hasMobile){
   $mobile=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Mobile_API/002_Procedures.sql'))
   $batches=@([regex]::Split($mobile,'(?im)^\s*GO\s*$') | Where-Object {$_ -match 'CREATE OR ALTER PROCEDURE dbo\.MobileApi_InfoPages\b'})
   if($batches.Count -ne 1){throw 'Expected exactly one mobile information-page procedure.'}
   $cmd=$cn.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batches[0]
   try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
  }
  Apply-CrmAccountOrganization $cn $tx;$tx.Commit();'Information pages schema, audience/brand access and dependent mobile procedure applied.'
 }catch{if($tx.Connection){$tx.Rollback()};throw}
}finally{$cn.Dispose()}
