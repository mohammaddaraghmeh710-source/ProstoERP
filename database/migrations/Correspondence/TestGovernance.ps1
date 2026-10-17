param([string]$TestDatabase='Prosto_Correspondence_Governance_Test')
$ErrorActionPreference='Stop'
if($TestDatabase -notmatch '^Prosto_Correspondence_Governance_Test[A-Za-z0-9_]*$'){throw 'Use an isolated correspondence test database name.'}
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$source=$builder.InitialCatalog
if($source -eq $TestDatabase){throw 'Test database must differ from application database.'}
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $connection.Open();$cmd=$connection.CreateCommand();$cmd.CommandText="IF DB_ID(N'$TestDatabase') IS NOT NULL THROW 51900,'Choose a fresh isolated test database name.',1; CREATE DATABASE [$TestDatabase];";[void]$cmd.ExecuteNonQuery()
 foreach($table in @('UsersMembers','Brands','Branches','Departments','JobTitles','Shift','Correspondence_Threads','Correspondence_Thread_Messages','Correspondence_Message_Attachments','Correspondence_Notifications')){
  $cmd.CommandText="SELECT TOP(0) * INTO [$TestDatabase].dbo.[$table] FROM dbo.[$table]; ALTER TABLE [$TestDatabase].dbo.[$table] ADD PRIMARY KEY(ID);";[void]$cmd.ExecuteNonQuery()
 }
}finally{$connection.Dispose()}
$builder['Initial Catalog']=$TestDatabase
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try {
 $connection.Open()
 foreach($file in @('002_Page_Operations.sql','003_Module_Procedures.sql','004_Independent_Procedures.sql','005_Search_Fields.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){
   if(!$batch.Trim()){continue};$cmd=$connection.CreateCommand();$cmd.CommandTimeout=120;$cmd.CommandText=$batch;[void]$cmd.ExecuteNonQuery()
  }
 }
}finally{$connection.Dispose()}
& (Join-Path $PSScriptRoot 'ApplyGovernance.ps1') -ConnectionString $builder.ConnectionString
# Verify reapplying is safe and does not recapture historical organization.
& (Join-Path $PSScriptRoot 'ApplyGovernance.ps1') -ConnectionString $builder.ConnectionString
$old=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'TestPage.ps1'))
$fixture=[regex]::Match($old,'(?s)\$fixture=@''\r?\n(.*?)\r?\n''@').Groups[1].Value
$positive=@'
IF (SELECT COUNT(*) FROM Correspondence_Parties WHERE ThreadID=@thread)<>2 THROW 51900,'Missing organization snapshots',1;
IF (SELECT Priority FROM Correspondence_Threads WHERE ID=@thread)<>1 THROW 51900,'Legacy caller priority default failed',1;
EXEC Correspondence_Detail @Actor=@admin,@ThreadID=@thread,@Supervisory=1;
EXEC Correspondence_Messages @Actor=@admin,@ThreadID=@thread;
EXEC Correspondence_Files @Actor=@admin,@ThreadID=@thread;
DECLARE @event uniqueidentifier=NEWID();
EXEC Correspondence_LogView @Actor=@admin,@ThreadID=@thread,@EventID=@event;
EXEC Correspondence_LogView @Actor=@admin,@ThreadID=@thread,@EventID=@event;
IF (SELECT COUNT(*) FROM Correspondence_Audit WHERE ThreadID=@thread)<>1 THROW 51900,'Repeated poll duplicated audit',1;
IF EXISTS(SELECT 1 FROM Correspondence_Thread_Messages WHERE ThreadID=@thread AND IsRead=1) THROW 51900,'Admin observation changed read receipts',1;
UPDATE UsersMembers SET Brand_ID=@brand2,Branch_ID=@branch3,Shif_ID=2 WHERE ID=@employee;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Parties WHERE ThreadID=@thread AND UserID=@employee AND BrandID=@brand AND BranchID=@branch AND ShiftID=1) THROW 51900,'Transfer rewrote snapshot',1;
IF EXISTS(SELECT 1 FROM Correspondence_AllowedRecipients(@employee,0) WHERE ID=@manager) THROW 51900,'New conversations use old organization',1;
EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'After transfer',@Files=NULL;
EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=0,@ClosureKind='transfer',@CloseReason=N'Reassigned';
SET @targets=(SELECT @other [@id] FOR XML PATH('item'),ROOT('items'));
EXEC Insert_Correspondence_Thread @Actor=@manager,@Brand=0,@Recipients=@targets,@Title=N'Follow-up',@Brief=NULL,@Body=N'New owner',@RequiresCompletion=1,@DueDate=NULL,@Files=NULL,@Priority=2,@RelatedThreadID=@thread;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE RelatedThreadID=@thread AND ReceiverID=@other AND Priority=2) THROW 51900,'Linked reassignment missing',1;
DECLARE @next int=(SELECT MAX(ID) FROM Correspondence_Threads WHERE RelatedThreadID=@thread);
UPDATE UsersMembers SET IsActive=0 WHERE ID=@manager;
EXEC Correspondence_Archive @Actor=@admin,@ThreadID=@next,@Reason=N'Creator inactive';
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@next AND ArchivedAt IS NOT NULL AND CloseDate IS NULL AND IsCompleted IS NULL) THROW 51900,'Archive invented completion or normal closure',1;
EXEC Correspondence_Browse @Actor=@admin,@All=1,@Brand=@brand;
EXEC Correspondence_AuditList @Actor=@admin,@ThreadID=@next;
EXEC Correspondence_Organization @Actor=@other,@ThreadID=@next;
EXEC Correspondence_Related @Actor=@admin,@ThreadID=@thread;
'@
$cases=@(
 @{Name='snapshots, cross-brand transfer, admin audit, linked task and archive';Sql=$positive;Error=0},
 @{Name='nonparticipant manager cannot read';Sql='EXEC Correspondence_Detail @Actor=@peer,@ThreadID=@thread;';Error=51400},
 @{Name='employee cannot request global list';Sql='EXEC Correspondence_Browse @Actor=@employee,@All=1;';Error=51400},
 @{Name='observer cannot reply';Sql="EXEC Insert_Correspondence_Thread_Message @Actor=@admin,@ThreadID=@thread,@Body=N'Invalid',@Files=NULL;";Error=51400},
 @{Name='observer cannot mark participant read';Sql="EXEC Update_Correspondence_Messages_Read @Actor=@admin,@ThreadID=@thread,@MessageIDs=N'<items/>';";Error=51400},
 @{Name='observer cannot determine completion';Sql='EXEC Update_Correspondence_Thread_Close @Actor=@admin,@ThreadID=@thread,@IsCompleted=1;';Error=51400},
 @{Name='active creator cannot be administratively archived';Sql="EXEC Correspondence_Archive @Actor=@admin,@ThreadID=@thread,@Reason=N'Invalid';";Error=51400},
 @{Name='archive needs reason';Sql="UPDATE UsersMembers SET IsActive=0 WHERE ID=@manager; EXEC Correspondence_Archive @Actor=@admin,@ThreadID=@thread,@Reason=N' ';";Error=51400},
 @{Name='archived task rejects replies';Sql="UPDATE UsersMembers SET IsActive=0 WHERE ID=@manager; EXEC Correspondence_Archive @Actor=@admin,@ThreadID=@thread,@Reason=N'Inactive'; EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Invalid',@Files=NULL;";Error=51400},
 @{Name='archived task cannot later be completed';Sql="UPDATE UsersMembers SET IsActive=0 WHERE ID=@manager; EXEC Correspondence_Archive @Actor=@admin,@ThreadID=@thread,@Reason=N'Inactive'; UPDATE UsersMembers SET IsActive=1 WHERE ID=@manager; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=1;";Error=51400},
 @{Name='disabled administrator denied';Sql='UPDATE UsersMembers SET IsActive=0 WHERE ID=@admin; EXEC Correspondence_Detail @Actor=@admin,@ThreadID=@thread;';Error=51400},
 @{Name='invalid priority rejected';Sql="EXEC Insert_Correspondence_Thread @Actor=@manager,@Brand=0,@Recipients=@targets,@Title=N'Invalid',@Brief=NULL,@Body=N'Test',@RequiresCompletion=0,@DueDate=NULL,@Files=NULL,@Priority=3;";Error=51400},
 @{Name='transfer reason required';Sql="EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Reply',@Files=NULL; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=0,@ClosureKind='transfer';";Error=51400}
)
foreach($case in $cases){
 $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
 try{
  $connection.Open();$cmd=$connection.CreateCommand();$cmd.CommandTimeout=120;$cmd.CommandText='BEGIN TRAN;'+$fixture+[Environment]::NewLine+$case.Sql
  $number=0
  try{[void]$cmd.ExecuteNonQuery()}catch [Data.SqlClient.SqlException]{$number=$_.Exception.Number;if($number -ne $case.Error){throw}}
  if($number -ne $case.Error){throw "Unexpected success: $($case.Name)"}
  Write-Output "PASS $($case.Name)"
 }finally{if($connection.State -eq 'Open'){$cmd=$connection.CreateCommand();$cmd.CommandText='IF @@TRANCOUNT>0 ROLLBACK;';[void]$cmd.ExecuteNonQuery()};$connection.Dispose()}
}
Write-Output "Isolated test database retained: $TestDatabase. Application data was not changed."
