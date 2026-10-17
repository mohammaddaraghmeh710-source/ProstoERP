$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$cs=[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$cn=[Data.SqlClient.SqlConnection]::new($cs);$cn.Open()
function Run([string]$sql){$c=$cn.CreateCommand();$c.CommandText=$sql;try{[void]$c.ExecuteNonQuery()}finally{$c.Dispose()}}
try {
Run @"
SET XACT_ABORT ON;
BEGIN TRAN;
DECLARE @Topic int=(SELECT TOP(1) ID FROM dbo.Employee_Feedback_Topics WHERE Brand_ID=29 AND Type=1 AND IsActive=1 AND IsDeleted=0 ORDER BY ID);
INSERT dbo.UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Department_ID,Shif_ID,IsActive,IsDeleted) VALUES(4,N'EF V2 isolated employee',29,25,1,1,1,0);
DECLARE @Employee int=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,Department_ID,Shif_ID,IsActive,IsDeleted) VALUES(6,N'EF V2 isolated manager',29,25,1,2,1,0);
DECLARE @Manager int=CONVERT(int,SCOPE_IDENTITY());
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Targets(@Employee,6))<>2 THROW 51500,'Department routing failed',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Targets(@Employee,6) WHERE ID=@Manager) THROW 51500,'Department must not depend on shift',1;
DECLARE @New TABLE(ID int); INSERT @New EXEC dbo.Insert_Employee_Feedback_Request @Actor=@Employee,@Type=1,@Topic=@Topic,@Title=N'EF V2 synthetic',@Details=N'Synthetic',@Disclose=0,@Target=6,@Files=N'<files/>';
DECLARE @ID int=(SELECT ID FROM @New),@V binary(8);
EXEC dbo.Update_Employee_Feedback_Read @Actor=@Employee,@ID=@ID;
EXEC dbo.Update_Employee_Feedback_Read @Actor=@Manager,@ID=@ID;
EXEC dbo.Update_Employee_Feedback_Read @Actor=@Manager,@ID=@ID;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Views WHERE Request_ID=@ID)<>3 THROW 51500,'Views not recorded',1;
DECLARE @Logs TABLE(Request_ID int,EventDate datetime,EventType nvarchar(50),ActorName nvarchar(300));
INSERT @Logs EXEC dbo.Select_Employee_Feedback_Logs @Actor=1,@ID=@ID;
IF EXISTS(SELECT 1 FROM @Logs WHERE ActorName=N'EF V2 isolated employee') THROW 51500,'Identity leaked through logs',1;
IF (SELECT COUNT(*) FROM @Logs WHERE EventType=N'مشاهدة')<>3 THROW 51500,'Views absent from logs',1;
SELECT @V=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
EXEC dbo.Update_Employee_Feedback_Action @Actor=@Manager,@ID=@ID,@Version=@V,@Action=2,@TargetType=3,@Comment=N'Test department to shift',@Files=N'<files/>';
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID AND ActionType=2 AND ReceiverID=148) THROW 51500,'Department transfer to employee shift failed',1;
SELECT @V=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
EXEC dbo.Update_Employee_Feedback_Action @Actor=148,@ID=@ID,@Version=@V,@Action=2,@TargetType=1,@Comment=N'Test direct admin transfer',@Files=N'<files/>';
SELECT @V=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@ID,@Version=@V,@Action=3,@Comment=N'Test close',@Files=N'<files/>';
IF (SELECT Status FROM dbo.Employee_Feedback_Requests WHERE ID=@ID)<>3 THROW 51500,'Admin closure failed',1;
ROLLBACK;
"@
'PASS department matching independent of shift; multi-recipient department; department-to-shift and shift-to-admin; closure; repeat view logs; anonymous log privacy.'
Run @"
BEGIN TRAN;
DECLARE @Version binary(8)=(SELECT RowVersion FROM dbo.Employee_Feedback_Permissions WHERE UserTypeID=6);
EXEC dbo.Save_Employee_Feedback_Permissions @Actor=1,@Role=6,@Submit=1,@Transfer=0,@Close=0,@Targets=N'<targets><target id="1"/></targets>',@Version=@Version;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Permissions WHERE UserTypeID=6 AND (CanTransfer=1 OR CanClose=1)) THROW 51500,'Config save failed',1;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_AllowedRecipients WHERE SenderUserTypeID=6)<>1 THROW 51500,'Routes replacement failed',1;
ROLLBACK;
"@
'PASS administrator permissions and routes save atomically (changes rolled back).'
Run @"
BEGIN TRAN;
DECLARE @Topic int=(SELECT TOP(1) ID FROM dbo.Employee_Feedback_Topics WHERE Brand_ID=29 AND Type=1 AND IsActive=1 AND IsDeleted=0);
INSERT dbo.UsersMembers(Type,FullName_Ar,Brand_ID,Branch_ID,IsActive,IsDeleted) VALUES(5,N'EF V2 quality',29,25,1,0);
DECLARE @Quality int=CONVERT(int,SCOPE_IDENTITY());
EXEC dbo.Insert_Employee_Feedback_Request @Actor=@Quality,@Type=1,@Topic=@Topic,@Title=N'Quality synthetic',@Details=N'Test',@Disclose=0,@Target=1,@Files=N'<files/>';
INSERT dbo.UsersMembers(Type,FullName_Ar,Branch_ID,IsActive,IsDeleted) VALUES(7,N'EF V2 external',25,1,0);
DECLARE @External int=CONVERT(int,SCOPE_IDENTITY());
EXEC dbo.Insert_Employee_Feedback_Request @Actor=@External,@Type=1,@Topic=@Topic,@Title=N'External synthetic',@Details=N'Test',@Disclose=0,@Target=1,@Files=N'<files/>';
ROLLBACK;
"@
'PASS quality and external submission to system administrators, including external without assigned brand.'
foreach($sql in @(
 "EXEC dbo.Save_Employee_Feedback_Permissions @Actor=151,@Role=4,@Submit=1,@Transfer=1,@Close=1,@Targets=N'<targets><target id=`"1`"/></targets>'",
 "EXEC dbo.Select_Employee_Feedback_Logs @Actor=151",
 "EXEC dbo.Select_Employee_Feedback_Statistics @Actor=151",
 "EXEC dbo.Insert_Employee_Feedback_Request @Actor=147,@Type=1,@Topic=0,@Title=N'Test',@Details=N'Test',@Disclose=0,@Target=6,@Files=N'<files/>'"
)) { $denied=$false;try{Run $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq 51500){$denied=$true}else{throw}};if(-not $denied){throw 'Expected permission rejection'} }
'PASS unauthorized permission management, logs, statistics, and recipient type denied.'
}finally{if($cn.State -eq 'Open'){Run 'IF @@TRANCOUNT>0 ROLLBACK'};$cn.Dispose()}
