$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$cs=[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$cn=[Data.SqlClient.SqlConnection]::new($cs);$cn.Open()
$topic=0;$peer=0;$adminPeer=0;$passed=0
function Q([string]$sql){
 $cmd=$cn.CreateCommand();$cmd.CommandText=$sql
 try{$table=[Data.DataTable]::new();$table.Load($cmd.ExecuteReader());return ,$table}finally{$cmd.Dispose()}
}
function N([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}
function Check([bool]$condition,[string]$message){if(-not $condition){throw $message};$script:passed++;Write-Output "PASS: $message"}
function Deny([string]$sql,[string]$label){try{N $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq 51500){Check $true $label;return};throw};throw "Expected denial: $label"}
function Version([int]$id){$t=Q "SELECT RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=$id";return '0x'+[BitConverter]::ToString($t.Rows[0][0]).Replace('-','')}
function NewRequest([int]$target){$t=Q "EXEC dbo.Insert_Employee_Feedback_Request @Actor=151,@Type=1,@Topic=$topic,@Title=N'EF automated temporary test',@Details=N'Synthetic verification only',@Disclose=0,@Target=$target,@Files=N'<files/>'";return [int]$t.Rows[0].ID}
try{
 $t=Q "INSERT dbo.UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,IsActive,IsDeleted) VALUES(2,N'EF temporary peer',29,25,1,0); SELECT CONVERT(int,SCOPE_IDENTITY()) ID";$peer=[int]$t.Rows[0].ID
 $t=Q "INSERT dbo.UsersMembers(Type,FullName_Ar,IsActive,IsDeleted) VALUES(1,N'EF temporary admin',1,0); SELECT CONVERT(int,SCOPE_IDENTITY()) ID";$adminPeer=[int]$t.Rows[0].ID
 $t=Q "EXEC dbo.Save_Employee_Feedback_Topic @Actor=1,@ID=0,@Type=1,@Brand=29,@TitleAr=N'EF temporary topic',@TitleEn=N'EF temporary topic',@Order=99,@Active=1";$topic=[int]$t.Rows[0].ID
 Deny "EXEC dbo.Delete_Employee_Feedback_Topic @Actor=151,@ID=$topic" 'Employee cannot manage topics'
 $id=NewRequest 3
 $t=Q "SELECT ReceiverID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=$id";Check ($t.Rows.Count -eq 1 -and $t.Rows[0].ReceiverID -eq 148) 'Shift routing matches branch and shift'
 $t=Q "EXEC dbo.Select_Employee_Feedback_Request @Actor=148,@ID=$id";Check ($t.Rows[0].EmployeeName -eq 'هوية غير معلنة' -and $t.Rows[0].BranchName -ne '' -and $t.Rows[0].TopicName -eq 'موضوع غير معلن') 'Anonymous identity is hidden while the requested public branch is visible'
 Deny "EXEC dbo.Select_Employee_Feedback_Request @Actor=1,@ID=$id" 'Administrator cannot read non-addressed request outside reports'
 $t=Q "EXEC dbo.Select_Employee_Feedback_Request @Actor=1,@ID=$id,@Report=1";Check ($t.Rows[0].EmployeeName -eq 'هوية غير معلنة' -and -not $t.Rows[0].CanAct) 'Report masks anonymous identity and is read-only'
 $v=Version $id
 Deny "EXEC dbo.Update_Employee_Feedback_Action @Actor=151,@ID=$id,@Version=$v,@Action=3,@Comment=N'Test',@Files=N'<files/>'" 'Employee cannot act on own request'
 Deny "EXEC dbo.Update_Employee_Feedback_Action @Actor=148,@ID=$id,@Version=$v,@Action=2,@Comment=N' ',@Files=N'<files/>'" 'Explanation is mandatory'
 N "EXEC dbo.Update_Employee_Feedback_Read @Actor=148,@ID=$id"
 $t=Q "SELECT Status FROM dbo.Employee_Feedback_Requests WHERE ID=$id";Check ($t.Rows[0].Status -eq 2) 'First recipient read starts processing'
 $v=Version $id
 N "EXEC dbo.Update_Employee_Feedback_Action @Actor=148,@ID=$id,@Version=$v,@Action=2,@TargetType=2,@Comment=N'Transfer explanation',@Files=N'<files/>'"
 $t=Q "SELECT COUNT(*) C FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=$id AND ActionType=2";Check ($t.Rows[0].C -eq 2) 'Transfer delivered to both branch managers'
 $t=Q "EXEC dbo.Select_Employee_Feedback_Request @Actor=148,@ID=$id";Check (-not $t.Rows[0].CanAct) 'Previous recipient retains read-only access'
 $v=Version $id
 Deny "EXEC dbo.Update_Employee_Feedback_Action @Actor=148,@ID=$id,@Version=$v,@Action=3,@Comment=N'Test',@Files=N'<files/>'" 'Previous recipient cannot act after transfer'
 N "EXEC dbo.Update_Employee_Feedback_Action @Actor=147,@ID=$id,@Version=$v,@Action=2,@TargetType=1,@Comment=N'Escalation',@Files=N'<files/>'"
 $t=Q "SELECT COUNT(*) C FROM dbo.Employee_Feedback_Workflow w JOIN dbo.UsersMembers u ON u.ID=w.ReceiverID WHERE Request_ID=$id AND w.ActionType=2 AND u.Type=1";Check ($t.Rows[0].C -eq 2) 'Escalation delivered to both administrators'
 $v=Version $id
 Deny "EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=$id,@Version=$v,@Action=2,@Comment=N'Test',@Files=N'<files/>'" 'Administrator cannot transfer'
 N "EXEC dbo.Update_Employee_Feedback_Action @Actor=$adminPeer,@ID=$id,@Version=$v,@Action=3,@Comment=N'Closure',@Files=N'<files/>'"
 $v=Version $id
 Deny "EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=$id,@Version=$v,@Action=3,@Comment=N'Test',@Files=N'<files/>'" 'Closed request rejects a second administrator action'
 $t=Q "EXEC dbo.Select_Employee_Feedback_Workflow @Actor=1,@ID=$id";Check ($t.Rows[0].SenderName -eq 'هوية غير معلنة' -and $t.Rows[$t.Rows.Count-1].ReceiverNames -eq 'هوية غير معلنة') 'Timeline masks employee on submission and closure'
 $t=Q "EXEC dbo.Select_Employee_Feedback_Requests @Actor=1,@Mode=0,@Search=N'',@Type=0,@Status=0";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 1) 'Administrator inbox includes received escalation'
 # True concurrent actions: first connection retains its lock while second waits.
 $race=NewRequest 2;$v=Version $race
 $c1=[Data.SqlClient.SqlConnection]::new($cs);$c2=[Data.SqlClient.SqlConnection]::new($cs);$c1.Open();$c2.Open()
 try{
  $a=$c1.CreateCommand();$a.CommandText="BEGIN TRAN; EXEC dbo.Update_Employee_Feedback_Action @Actor=147,@ID=$race,@Version=$v,@Action=3,@Comment=N'Race winner',@Files=N'<files/>'; WAITFOR DELAY '00:00:02'; COMMIT;"
  $b=$c2.CreateCommand();$b.CommandText="EXEC dbo.Update_Employee_Feedback_Action @Actor=$peer,@ID=$race,@Version=$v,@Action=3,@Comment=N'Race loser',@Files=N'<files/>';"
  $one=$a.ExecuteNonQueryAsync();Start-Sleep -Milliseconds 200;$two=$b.ExecuteNonQueryAsync()
  [void]$one.GetAwaiter().GetResult();$denied=$false
  try{[void]$two.GetAwaiter().GetResult()}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq 51500){$denied=$true}else{throw}}
  $t=Q "SELECT COUNT(*) C FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=$race AND ActionType=3";Check ($denied -and $t.Rows[0].C -eq 1) 'Concurrent managers: exactly one committed action'
 }finally{$c1.Dispose();$c2.Dispose()}
 # A temporary employee without a shift tests fallback; no real assignment changes.
 $t=Q "BEGIN TRAN; INSERT dbo.UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,IsActive,IsDeleted) VALUES(4,N'EF temporary fallback',29,25,1,0); DECLARE @employee int=CONVERT(int,SCOPE_IDENTITY()); SELECT Type FROM dbo.Employee_Feedback_Targets(@employee,3); ROLLBACK;"
 Check ($t.Rows.Count -eq 2 -and @($t.Rows|Where-Object Type -ne 1).Count -eq 0) 'Missing shift manager falls back directly to all administrators'
}finally{
 # Close an unfinished local transaction before scoped cleanup.
 $cn.Close();$cn.Open()
 if($topic -gt 0){N "BEGIN TRAN; DELETE v FROM dbo.Employee_Feedback_Views v JOIN dbo.Employee_Feedback_Requests r ON r.ID=v.Request_ID WHERE r.Topic_ID=$topic; DELETE n FROM dbo.Employee_Feedback_Notifications n JOIN dbo.Employee_Feedback_Requests r ON r.ID=n.Request_ID WHERE r.Topic_ID=$topic; DELETE a FROM dbo.Employee_Feedback_Attachments a JOIN dbo.Employee_Feedback_Requests r ON r.ID=a.Request_ID WHERE r.Topic_ID=$topic; DELETE w FROM dbo.Employee_Feedback_Workflow w JOIN dbo.Employee_Feedback_Requests r ON r.ID=w.Request_ID WHERE r.Topic_ID=$topic; DELETE dbo.Employee_Feedback_Requests WHERE Topic_ID=$topic; DELETE dbo.Employee_Feedback_Topics WHERE ID=$topic; COMMIT;"}
 if($peer -gt 0){N "DELETE dbo.UsersMembers WHERE ID=$peer"};if($adminPeer -gt 0){N "DELETE dbo.UsersMembers WHERE ID=$adminPeer"}
 $cn.Dispose()
}
Write-Output "$passed behavioral checks passed; all temporary fixtures removed."
