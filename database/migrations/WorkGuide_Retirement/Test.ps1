$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$cn=[Data.SqlClient.SqlConnection]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$tx=$null
try {
 $cn.Open();$tx=$cn.BeginTransaction()
 function Run([string]$sql){$cmd=$cn.CreateCommand();try{$cmd.Transaction=$tx;$cmd.CommandText=$sql;$cmd.CommandTimeout=120;return $cmd.ExecuteScalar()}finally{$cmd.Dispose()}}
 $baseline=Run 'SELECT CONCAT((SELECT COUNT(*) FROM Customer_Logins),'':'',(SELECT COUNT(*) FROM CRM_Accounts),'':'',(SELECT COUNT(*) FROM CRM_Contacts),'':'',(SELECT COUNT(*) FROM Customer_Portal_Feedback),'':'',(SELECT COUNT(*) FROM Customer_Portal_Activity WHERE Action NOT IN(''view'',''download'',''grant'',''access-request'',''access-review'')))'
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/001_Accounts.sql')),'(?im)^\s*GO\s*$')){if($batch -match 'CREATE OR ALTER PROCEDURE dbo.Customer_AdminData\b'){[void](Run $batch)}}
 $sql=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_Remove.sql'))
 [void](Run $sql);[void](Run $sql)
 $after=Run 'SELECT CONCAT((SELECT COUNT(*) FROM Customer_Logins),'':'',(SELECT COUNT(*) FROM CRM_Accounts),'':'',(SELECT COUNT(*) FROM CRM_Contacts),'':'',(SELECT COUNT(*) FROM Customer_Portal_Feedback),'':'',(SELECT COUNT(*) FROM Customer_Portal_Activity WHERE Action NOT IN(''view'',''download'',''grant'',''access-request'',''access-review'')))'
 if($baseline -ne $after){throw 'Shared customer data changed.'}
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/006_Dashboard.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Run $batch)}}
 'PASS: Complete removal, repeat execution, preserved CRM/login/feedback/shared audit and dashboard creation in a rollback-only transaction.'
} finally {if($tx){try{$tx.Rollback()}finally{$tx.Dispose()}};$cn.Dispose()}
