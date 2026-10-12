$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$tx=$null
function Q([string]$sql,[hashtable]$parameters=@{}){$cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$sql;foreach($key in $parameters.Keys){if($key -eq '@v'){$p=$cmd.Parameters.Add($key,[Data.SqlDbType]::Binary,8);$p.Value=$parameters[$key]}else{[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])}};$t=[Data.DataTable]::new();try{[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($t)}finally{$cmd.Dispose()};return ,$t}
function Assert([bool]$ok,[string]$msg){if(-not $ok){throw $msg}}
try {
 $db.Open();$tx=$db.BeginTransaction()
 $ids=(Q 'SELECT (SELECT TOP(1) ID FROM UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) A,(SELECT TOP(1) ID FROM UsersMembers WHERE Type<>1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) U').Rows[0]
 $name='CRM new workflow '+[guid]::NewGuid()
 $a=(Q 'EXEC dbo.CRM_Save_Accounts @Actor_ID=@a,@Data=@x' @{'@a'=$ids.A;'@x'="<row><Name_AR>$name</Name_AR><Owner_ID>$($ids.U)</Owner_ID><Is_Active>1</Is_Active></row>"}).Rows[0]
 $c=(Q 'EXEC dbo.CRM_Save_Contacts @Actor_ID=@a,@Data=@x' @{'@a'=$ids.U;'@x'="<row><Account_ID>$($a.ID)</Account_ID><Name_AR>Test contact</Name_AR><Email>test@example.invalid</Email><Job_Title>Manager</Job_Title><Is_Active>0</Is_Active></row>"}).Rows[0]
 Assert (-not (Q 'EXEC dbo.CRM_Select_Contacts @Actor_ID=@a,@ID=@id' @{'@a'=$ids.U;'@id'=$c.ID}).Rows[0].Is_Active) 'Checkbox state not saved on insert'
 [void](Q "EXEC dbo.CRM_Set_Active @Actor_ID=@a,@Entity='Contacts',@ID=@id,@Is_Active=1,@Version=@v" @{'@a'=$ids.U;'@id'=$c.ID;'@v'=$c.Row_Version})
 $now=(Q 'EXEC dbo.CRM_Select_Contacts @Actor_ID=@a,@ID=@id' @{'@a'=$ids.U;'@id'=$c.ID}).Rows[0]
 Assert $now.Is_Active 'Activation failed'
 [void](Q 'EXEC dbo.CRM_Save_Contacts @Actor_ID=@a,@ID=@id,@Version=@v,@Data=@x' @{'@a'=$ids.U;'@id'=$c.ID;'@v'=$now.Row_Version;'@x'="<row><Account_ID>$($a.ID)</Account_ID><Name_AR>Edited contact</Name_AR><Email>edited@example.invalid</Email><Job_Title>Supervisor</Job_Title><Is_Active>0</Is_Active></row>"})
 $now=(Q 'EXEC dbo.CRM_Select_Contacts @Actor_ID=@a,@ID=@id' @{'@a'=$ids.U;'@id'=$c.ID}).Rows[0]
 Assert (-not $now.Is_Active -and $now.Job_Title -eq 'Supervisor') 'Edit / checkbox deactivation failed'
 $logs=Q 'EXEC dbo.CRM_Select_Logs @Actor_ID=@a,@Account_ID=@id' @{'@a'=$ids.U;'@id'=$a.ID}
 Assert ($logs.Rows.Count -eq 4) 'Atomic audit history missing'
 $retired=(Q "SELECT COUNT(*) N FROM sys.objects WHERE name IN ('CRM_Contracts','CRM_Installments','CRM_Invoices','CRM_Payments','CRM_Followups','CRM_Attachments','CRM_Email_Outbox','CRM_Settings','CRM_Select_Contracts','CRM_Save_Invoices','CRM_Queue_Notifications')").Rows[0].N
 Assert ($retired -eq 0) 'Retired database objects remain'
 Write-Output 'PASS create/edit/active checkbox/audit/owner access; retired database objects absent'
 try{[void](Q 'EXEC dbo.CRM_Save_Payment_Methods @Actor_ID=@a,@Data=@x' @{'@a'=$ids.U;'@x'='<row><Name_AR>Denied lookup</Name_AR></row>'});throw 'Expected admin-only rejection'}catch{$ex=$_.Exception;while($ex.InnerException){$ex=$ex.InnerException};if($ex -isnot [Data.SqlClient.SqlException] -or $ex.Number -ne 51201){throw}}
 Write-Output 'PASS system definitions limited to administrator; all test writes rolled back'
}finally{if($tx -and $tx.Connection){$tx.Rollback()};$db.Dispose()}
