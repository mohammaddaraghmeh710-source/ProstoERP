$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$connectionString=if($env:CORRESPONDENCE_TEST_CONNECTION){$env:CORRESPONDENCE_TEST_CONNECTION}else{[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString}
$fixture=@'
DECLARE @brand int,@brand2 int,@branch int,@branch2 int,@branch3 int;
INSERT Brands(Title_Ar,IsActive,IsDeleted) VALUES(N'CM test brand',1,0); SET @brand=SCOPE_IDENTITY();
INSERT Brands(Title_Ar,IsActive,IsDeleted) VALUES(N'CM test other brand',1,0); SET @brand2=SCOPE_IDENTITY();
INSERT Branches(Title_Ar,BrandID,IsActive,IsDeleted) VALUES(N'CM test branch',@brand,1,0); SET @branch=SCOPE_IDENTITY();
INSERT Branches(Title_Ar,BrandID,IsActive,IsDeleted) VALUES(N'CM test branch2',@brand,1,0); SET @branch2=SCOPE_IDENTITY();
INSERT Branches(Title_Ar,BrandID,IsActive,IsDeleted) VALUES(N'CM test branch3',@brand2,1,0); SET @branch3=SCOPE_IDENTITY();
DECLARE @admin int,@manager int,@shift int,@employee int,@other int,@peer int,@alien int;
INSERT UsersMembers(Type,FullName_Ar,IsActive,IsDeleted) VALUES(1,N'CM test admin',1,0); SET @admin=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(2,N'CM test manager',@brand,@branch,1,1,0); SET @manager=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(3,N'CM test shift',@brand,@branch,1,1,0); SET @shift=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(4,N'CM test employee',@brand,@branch,1,1,0); SET @employee=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(4,N'CM test other shift',@brand,@branch,2,1,0); SET @other=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(2,N'CM test peer',@brand,@branch2,1,1,0); SET @peer=SCOPE_IDENTITY();
INSERT UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(2,N'CM test alien',@brand2,@branch3,1,1,0); SET @alien=SCOPE_IDENTITY();
DECLARE @targets xml=(SELECT @employee [@id] FOR XML PATH('item'),ROOT('items'));
EXEC Insert_Correspondence_Thread @Actor=@manager,@Recipients=@targets,@Title=N'Test title',@Brief=N'Independent brief',@Body=N'First message',@RequiresCompletion=1,@Brand=0,@DueDate=NULL,@Files=NULL;
DECLARE @thread int=(SELECT MAX(ID) FROM Correspondence_Threads WHERE CreatedBy=@manager);
DECLARE @message int=(SELECT MAX(ID) FROM Correspondence_Thread_Messages WHERE ThreadID=@thread);
'@
$positive=@'
IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@manager,0) WHERE ID=@shift) THROW 51900,'Manager to shift failed',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@manager,0) WHERE ID=@peer) THROW 51900,'Same-brand managers failed',1;
IF EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@manager,0) WHERE ID=@alien) THROW 51900,'Other-brand manager allowed',1;
IF EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@shift,0) WHERE ID IN(@other,@peer,@admin)) THROW 51900,'Shift scope failed',1;
IF EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@employee,0) WHERE ID IN(@other,@peer,@admin)) THROW 51900,'Employee scope failed',1;
IF EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@admin,0)) THROW 51900,'Admin without brand allowed',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@admin,@brand) WHERE ID=@manager) THROW 51900,'Admin manager missing',1;
IF EXISTS(SELECT 1 FROM dbo.Correspondence_AllowedRecipients(@admin,@brand) WHERE ID=@alien) THROW 51900,'Admin other brand leaked',1;
EXEC Insert_Correspondence_Thread_Message @Actor=@manager,@ThreadID=@thread,@Body=N'Second unread message',@Files=NULL;
DECLARE @counts TABLE(UnreadThreads int); INSERT @counts EXEC Select_Correspondence_UnreadCount @Actor=@employee;
IF (SELECT UnreadThreads FROM @counts)<>1 THROW 51900,'Counter counts messages, not threads',1;
EXEC Select_Correspondence_Thread_ByID @Actor=@employee,@ThreadID=@thread;
IF EXISTS(SELECT 1 FROM Correspondence_Thread_Messages WHERE ID=@message AND IsRead=1) THROW 51900,'Fetch incorrectly marked read',1;
DECLARE @read xml=(SELECT @message [@id] FOR XML PATH('item'),ROOT('items'));
EXEC Update_Correspondence_Messages_Read @Actor=@employee,@ThreadID=@thread,@MessageIDs=@read;
DECLARE @firstRead datetime=(SELECT ReadDate FROM Correspondence_Thread_Messages WHERE ID=@message);
IF @firstRead IS NULL THROW 51900,'Receipt missing',1;
IF EXISTS(SELECT 1 FROM Correspondence_Notifications WHERE MessageID=@message AND IsRead=1) THROW 51900,'Notification and message reading conflated',1;
EXEC Update_Correspondence_Messages_Read @Actor=@employee,@ThreadID=@thread,@MessageIDs=@read;
IF @firstRead<>(SELECT ReadDate FROM Correspondence_Thread_Messages WHERE ID=@message) THROW 51900,'Receipt overwritten',1;
DECLARE @files xml=N'<files><file name="test.pdf" type="application/pdf" size="123"/></files>';
EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Files=@files,@Body=NULL;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Message_Attachments a JOIN Correspondence_Thread_Messages m ON m.ID=a.MessageID WHERE m.ThreadID=@thread) THROW 51900,'Attachment-only reply failed',1;
UPDATE Correspondence_Threads SET DueDate=DATEADD(hour,-1,GETUTCDATE()) WHERE ID=@thread;
EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=0;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@thread AND CloseDate>DueDate AND IsCompleted=0 AND Status=3) THROW 51900,'Closing outcome failed',1;
SET @targets=(SELECT ID [@id] FROM UsersMembers WHERE ID IN(@employee,@other) FOR XML PATH('item'),ROOT('items'));
EXEC Insert_Correspondence_Thread @Actor=@manager,@Recipients=@targets,@Title=N'Bulk test',@Body=N'Bulk',@Brand=0,@Brief=NULL,@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;
IF (SELECT COUNT(*) FROM Correspondence_Threads WHERE CreatedBy=@manager AND Title=N'Bulk test')<>2 THROW 51900,'Bulk thread count failed',1;
IF (SELECT COUNT(DISTINCT BroadcastID) FROM Correspondence_Threads WHERE CreatedBy=@manager AND Title=N'Bulk test' AND IsBroadcast=1)<>1 THROW 51900,'Bulk group failed',1;
SET @targets=(SELECT @manager [@id] FOR XML PATH('item'),ROOT('items'));
EXEC Insert_Correspondence_Thread @Actor=@employee,@Recipients=@targets,@Title=N'Employee initiated',@Body=N'Question',@Brand=0,@Brief=NULL,@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;
SET @thread=(SELECT MAX(ID) FROM Correspondence_Threads WHERE CreatedBy=@employee);
EXEC Insert_Correspondence_Thread_Message @Actor=@manager,@ThreadID=@thread,@Body=N'Answer',@Files=NULL;
EXEC Update_Correspondence_Thread_Close @Actor=@employee,@ThreadID=@thread,@IsCompleted=NULL;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@thread AND CloseDate IS NOT NULL AND IsCompleted IS NULL) THROW 51900,'Employee creator close failed',1;
EXEC Select_Correspondence_Threads_ByUserID @Actor=@manager;
EXEC Select_Correspondence_Recipients @Actor=@admin,@Brand=@brand,@Branch=@branch,@Shift=1;
'@
$cases=@(
 @{Name='permissions, unread thread count, first receipts, independent notifications, files-only reply, closure, broadcast, employee creator';Sql=$positive;Error=0},
 @{Name='legacy participant-only detail remains restricted (oversight uses separate procedures)';Sql="EXEC Select_Correspondence_Thread_ByID @Actor=@admin,@ThreadID=@thread;";Error=51400},
 @{Name='creator cannot close before a reply';Sql="EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=1;";Error=51400},
 @{Name='recipient cannot close';Sql="EXEC Update_Correspondence_Thread_Close @Actor=@employee,@ThreadID=@thread,@IsCompleted=1;";Error=51400},
 @{Name='required outcome cannot be omitted';Sql="EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Reply',@Files=NULL; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=NULL;";Error=51400},
 @{Name='closed thread rejects replies';Sql="EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Reply',@Files=NULL; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=1; EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Invalid',@Files=NULL;";Error=51400},
 @{Name='cross-brand manager sending denied';Sql="SET @targets=(SELECT @alien [@id] FOR XML PATH('item'),ROOT('items')); EXEC Insert_Correspondence_Thread @Actor=@manager,@Recipients=@targets,@Title=N'Test',@Body=N'Test',@Brand=0,@Brief=NULL,@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;";Error=51400},
 @{Name='employee cannot initiate to administrator';Sql="SET @targets=(SELECT @admin [@id] FOR XML PATH('item'),ROOT('items')); EXEC Insert_Correspondence_Thread @Actor=@employee,@Recipients=@targets,@Title=N'Test',@Body=N'Test',@Brand=0,@Brief=NULL,@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;";Error=51400},
 @{Name='employee cannot request completion';Sql="SET @targets=(SELECT @manager [@id] FOR XML PATH('item'),ROOT('items')); EXEC Insert_Correspondence_Thread @Actor=@employee,@Recipients=@targets,@Title=N'Test',@Body=N'Test',@RequiresCompletion=1,@Brand=0,@Brief=NULL,@DueDate=NULL,@Files=NULL;";Error=51400},
 @{Name='invalid recipient rejects entire broadcast';Sql="SET @targets=(SELECT ID [@id] FROM UsersMembers WHERE ID IN(@employee,@alien) FOR XML PATH('item'),ROOT('items')); EXEC Insert_Correspondence_Thread @Actor=@manager,@Recipients=@targets,@Title=N'Test',@Body=N'Test',@Brand=0,@Brief=NULL,@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;";Error=51400}
)
foreach($case in $cases){
 $connection=[Data.SqlClient.SqlConnection]::new($connectionString)
 try{
  $connection.Open();$command=$connection.CreateCommand();$command.CommandTimeout=120;$command.CommandText='BEGIN TRANSACTION;'+$fixture+[Environment]::NewLine+$case.Sql
  $errorNumber=0
  try{[void]$command.ExecuteNonQuery()}catch [Data.SqlClient.SqlException]{$errorNumber=$_.Exception.Number;if($errorNumber -ne $case.Error){throw}}
  if($errorNumber -ne $case.Error){throw ('Expected rejection: '+$case.Name)}
  Write-Output ('PASS '+$case.Name)
 }finally{if($connection.State -eq 'Open'){$cleanup=$connection.CreateCommand();$cleanup.CommandText='IF @@TRANCOUNT>0 ROLLBACK;';[void]$cleanup.ExecuteNonQuery()};$connection.Dispose()}
}
