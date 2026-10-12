param([string]$TestDatabase='Prosto_Correspondence_Governance_Test5')
$ErrorActionPreference='Stop'
if($TestDatabase -notmatch '^Prosto_Correspondence_Governance_Test[A-Za-z0-9_]*$'){throw 'Use an isolated correspondence test database.'}
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($builder.InitialCatalog -eq $TestDatabase){throw 'Application database is not a test database.'}
$builder['Initial Catalog']=$TestDatabase
& (Join-Path $PSScriptRoot 'ApplyCatalogs.ps1') -ConnectionString $builder.ConnectionString
$old=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'TestPage.ps1'))
$fixture=[regex]::Match($old,'(?s)\$fixture=@''\r?\n(.*?)\r?\n''@').Groups[1].Value
$setup=@'
DECLARE @new TABLE(ID int);
INSERT @new EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@Title=N'Custom priority',@SortOrder=99,@IsUrgent=1;
DECLARE @priority int=(SELECT ID FROM @new),@version binary(8);DELETE @new;
INSERT @new EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='R',@Title=N'Custom reason';
DECLARE @reason int=(SELECT ID FROM @new);DELETE @new;
'@
$create="EXEC Insert_Correspondence_Thread @Actor=@manager,@Brand=0,@Recipients=@targets,@Title=N'Custom',@Brief=NULL,@Body=N'Test',@RequiresCompletion=1,@DueDate=NULL,@Files=NULL,@Priority=@priority;"
$reply="EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@thread,@Body=N'Reply',@Files=NULL;"
$positive=$create+@'
DECLARE @custom int=(SELECT MAX(ID) FROM Correspondence_Threads WHERE CreatedBy=@manager);
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@custom AND PriorityName=N'Custom priority' AND PriorityRank=99 AND PriorityUrgent=1) THROW 51900,'Missing priority snapshot',1;
SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority;
EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@ID=@priority,@Title=N'Renamed priority',@Version=@version;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@custom AND PriorityName=N'Custom priority' AND PriorityRank=99 AND PriorityUrgent=1) THROW 51900,'Priority history rewritten',1;
EXEC Insert_Correspondence_Thread_Message @Actor=@employee,@ThreadID=@custom,@Body=N'Reply',@Files=NULL;
EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@custom,@IsCompleted=1,@ClosureReasonID=@reason;
SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@reason;
EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='R',@ID=@reason,@Title=N'Renamed reason',@Behavior='transfer',@Version=@version;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@custom AND ClosureReasonName=N'Custom reason' AND ClosureKind='normal') THROW 51900,'Reason history rewritten',1;
SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority;
EXEC Correspondence_CatalogState @Actor=@admin,@ID=@priority,@Action='deactivate',@Version=@version;
SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority;
EXEC Correspondence_CatalogState @Actor=@admin,@ID=@priority,@Action='activate',@Version=@version;
IF NOT EXISTS(SELECT 1 FROM Correspondence_Catalog WHERE ID=@priority AND IsActive=1) THROW 51900,'Activation failed',1;
IF (SELECT COUNT(*) FROM Correspondence_CatalogAudit WHERE CatalogID IN(@priority,@reason))<>6 THROW 51900,'Audit missing',1;
EXEC Correspondence_Browse @Actor=@admin,@All=1,@Priority=@priority;
EXEC Correspondence_Detail @Actor=@manager,@ThreadID=@custom;
'@
$deactivateP="SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority; EXEC Correspondence_CatalogState @Actor=@admin,@ID=@priority,@Action='deactivate',@Version=@version;"
$cases=@(
 @{Name='custom options, snapshots, activation and audit';Sql=$positive;Error=0},
 @{Name='manager cannot manage catalogs';Sql="EXEC Correspondence_CatalogSave @Actor=@manager,@Kind='P',@Title=N'Forbidden';";Error=51400},
 @{Name='employee cannot list admin options';Sql="EXEC Correspondence_CatalogList @Actor=@employee,@Kind='P',@Mode=2;";Error=51400},
 @{Name='disabled administrator denied';Sql="UPDATE UsersMembers SET IsActive=0 WHERE ID=@admin; EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@Title=N'Forbidden';";Error=51400},
 @{Name='duplicate names rejected';Sql="EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@Title=N'Custom priority';";Error=51400},
 @{Name='stale edit rejected';Sql="SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority; EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@ID=@priority,@Title=N'First',@Version=@version; EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='P',@ID=@priority,@Title=N'Stale',@Version=@version;";Error=51400},
 @{Name='disabled priority rejected at send';Sql=$deactivateP+$create;Error=51400},
 @{Name='used priority cannot be deleted';Sql=$create+"SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority; EXEC Correspondence_CatalogState @Actor=@admin,@ID=@priority,@Action='delete',@Version=@version;";Error=51400},
 @{Name='unused option can be deleted';Sql="SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@priority; EXEC Correspondence_CatalogState @Actor=@admin,@ID=@priority,@Action='delete',@Version=@version; IF NOT EXISTS(SELECT 1 FROM Correspondence_Catalog WHERE ID=@priority AND IsDeleted=1 AND IsActive=0) THROW 51900,'Delete failed',1;";Error=0},
 @{Name='disabled reason rejected at closure';Sql=$reply+"SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@reason; EXEC Correspondence_CatalogState @Actor=@admin,@ID=@reason,@Action='deactivate',@Version=@version; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=1,@ClosureReasonID=@reason;";Error=51400},
 @{Name='used reason cannot be deleted';Sql=$reply+"EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=1,@ClosureReasonID=@reason; SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@reason; EXEC Correspondence_CatalogState @Actor=@admin,@ID=@reason,@Action='delete',@Version=@version;";Error=51400},
 @{Name='custom transfer preserves transfer workflow';Sql="SELECT @version=Version FROM Correspondence_Catalog WHERE ID=@reason; EXEC Correspondence_CatalogSave @Actor=@admin,@Kind='R',@ID=@reason,@Title=N'Reassignment',@Behavior='transfer',@Version=@version; EXEC Update_Correspondence_Thread_Close @Actor=@manager,@ThreadID=@thread,@IsCompleted=0,@ClosureReasonID=@reason,@CloseReason=N'Changed owner'; IF NOT EXISTS(SELECT 1 FROM Correspondence_Threads WHERE ID=@thread AND ClosureKind='transfer' AND ClosureReasonID=@reason) THROW 51900,'Transfer mapping failed',1;";Error=0}
)
foreach($case in $cases){
 $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
 try{
  $connection.Open();$cmd=$connection.CreateCommand();$cmd.CommandTimeout=120;$cmd.CommandText='BEGIN TRAN;'+$fixture+[Environment]::NewLine+$setup+[Environment]::NewLine+$case.Sql
  $number=0
  try{[void]$cmd.ExecuteNonQuery()}catch [Data.SqlClient.SqlException]{$number=$_.Exception.Number;if($number -ne $case.Error){throw}}
  if($number -ne $case.Error){throw "Unexpected success: $($case.Name)"}
  Write-Output "PASS $($case.Name)"
 }finally{if($connection.State -eq 'Open'){$cmd=$connection.CreateCommand();$cmd.CommandText='IF @@TRANCOUNT>0 ROLLBACK;';[void]$cmd.ExecuteNonQuery()};$connection.Dispose()}
}
# Existing participant, notification, attachment and completion regressions against 007.
$saved=$env:CORRESPONDENCE_TEST_CONNECTION
try{$env:CORRESPONDENCE_TEST_CONNECTION=$builder.ConnectionString;& (Join-Path $PSScriptRoot 'TestPage.ps1')}finally{$env:CORRESPONDENCE_TEST_CONNECTION=$saved}
