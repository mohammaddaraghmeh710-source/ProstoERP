param([switch]$Large)
$ErrorActionPreference='Stop'
$threadCount=if($Large){120}else{36}
$messageCount=if($Large){40}else{5}
$bodyLength=if($Large){3800}else{200}
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $db.Open();$tx=$db.BeginTransaction()
 $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandTimeout=120
 $cmd.CommandText=@'
DECLARE @manager int,@employee int,@i int=0,@j int,@thread int;
INSERT UsersMembers(Type,FullName_Ar,IsActive,IsDeleted) VALUES(2,N'CM load fixture manager',1,0);SET @manager=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,IsActive,IsDeleted) VALUES(4,N'CM load fixture employee',1,0);SET @employee=SCOPE_IDENTITY();
WHILE @i<@ThreadCount
BEGIN
 INSERT Correspondence_Threads(Title,Brief,SenderID,ReceiverID,CreatedBy,CreatedDate,Status,IsDeleted)
 VALUES(N'Performance fixture',REPLICATE(N'B',@BodyLength),@manager,@employee,@manager,GETUTCDATE(),1,0);
 SET @thread=SCOPE_IDENTITY();SET @j=0;
 WHILE @j<@MessageCount
 BEGIN
  INSERT Correspondence_Thread_Messages(ThreadID,SenderID,ReceivedID,Body,CreatedDate,IsRead)
  VALUES(@thread,@manager,@employee,REPLICATE(N'M',@BodyLength),GETUTCDATE(),0);
  SET @j+=1;
 END;
 SET @i+=1;
END;
SELECT @employee;
'@
 [void]$cmd.Parameters.AddWithValue('@ThreadCount',$threadCount);[void]$cmd.Parameters.AddWithValue('@MessageCount',$messageCount);[void]$cmd.Parameters.AddWithValue('@BodyLength',$bodyLength)
 $actor=[int]$cmd.ExecuteScalar()
 foreach($page in @(1,[int][Math]::Ceiling($threadCount/30.0))) {
  $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandTimeout=60
  $cmd.CommandText="EXEC Select_Correspondence_Threads_ByUserID @Actor=@user,@Page=@page"
  [void]$cmd.Parameters.AddWithValue('@user',$actor);[void]$cmd.Parameters.AddWithValue('@page',$page)
  $watch=[Diagnostics.Stopwatch]::StartNew();$r=$cmd.ExecuteReader();$rows=0
  while($r.Read()) { $rows++;if([int]$r['TotalRows'] -ne $threadCount -or [int]$r['MessageCount'] -ne $messageCount){throw 'Incorrect paged aggregates'} }
  $r.Close();$watch.Stop()
  if($rows -ne [Math]::Min(30,$threadCount-($page-1)*30)){throw 'Incorrect page size'}
  "PASS $threadCount conversations / $($threadCount*$messageCount) messages: page $page, $rows rows, $($watch.ElapsedMilliseconds) ms"
 }
 $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText="EXEC Select_Correspondence_UnreadCount @Actor=$actor"
 if([int]$cmd.ExecuteScalar() -ne $threadCount){throw 'Unread count is not per conversation'}
 'PASS unread conversation count under load'
} finally {
 if($tx -and $tx.Connection){$tx.Rollback()};$db.Dispose()
}
