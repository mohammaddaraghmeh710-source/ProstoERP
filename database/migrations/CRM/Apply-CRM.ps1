$ErrorActionPreference='Stop'
$cfg=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($cfg.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {$db.Open();$tx=$db.BeginTransaction();try {
 foreach($file in @('005_CRM_Retire_Contracts.sql','001_CRM_Schema.sql','002_CRM_Procedures.sql','006_CRM_Delete.sql')) {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')) {
   if([string]::IsNullOrWhiteSpace($batch)){continue};$cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$batch;$cmd.CommandTimeout=120
   try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
  };Write-Output "$file applied"
 };$tx.Commit()
}catch{if($tx.Connection){$tx.Rollback()};throw}}finally{$db.Dispose()}
