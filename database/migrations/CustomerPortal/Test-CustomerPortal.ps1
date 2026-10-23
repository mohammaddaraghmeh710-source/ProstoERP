param([switch]$KeepDatabase,[string]$ApiBuildDirectory,[switch]$DatabaseOnly,[switch]$MultiBrandOnly,[switch]$FeedbackOnly)
$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL Server required.'}
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$testName='Prosto_Customer_Test_'+[guid]::NewGuid().ToString('N')
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$testName
function Q([string]$connection,[string]$sql){
 $cn=[Data.SqlClient.SqlConnection]::new($connection)
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=120;$ds=[Data.DataSet]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($ds);if($ds.Tables.Count){return ,$ds.Tables[0]}}finally{$cn.Dispose()}
}
$created=$false; $passed=$false
try{
 [void](Q $master.ConnectionString "CREATE DATABASE [$testName]");$created=$true
 $tables=@('JobTitles','JobTitle_Items','Departments','Shift','News','UsersMembers','Users_Types','Brands','Branches','CRM_Accounts','CRM_Account_Types','CRM_Contacts','CRM_Activity_Logs','Employee_Feedback_Types','Employee_Feedback_Topics','Employee_Feedback_Requests','Employee_Feedback_Workflow','Employee_Feedback_Attachments','Employee_Feedback_Notifications')
 if($FeedbackOnly){$tables=@($tables|Where-Object {$_ -notlike 'Employee_Feedback_*'})}
 foreach($table in $tables){
  [void](Q $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$($source.InitialCatalog)].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY($(if($table -eq 'News'){'PID'}else{'ID'}));")
  $defaults=Q $source.ConnectionString "SELECT c.name Col,d.definition Def FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID('dbo.$table')"
  foreach($row in $defaults.Rows){[void](Q $test.ConnectionString "ALTER TABLE dbo.[$table] ADD DEFAULT $($row.Def) FOR [$($row.Col)]")}
 }
 if($FeedbackOnly){
  foreach($file in @('../Employee_Feedback/001_Schema.sql','../Employee_Feedback/002_Simplify.sql','../Employee_Feedback/004_Procedures.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
  [void](Q $test.ConnectionString ([regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Employee_Feedback/007_TypesAndApplicant.sql')),'(?im)^\s*GO\s*$')[0]))
 }
 [void](Q $test.ConnectionString @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'مدير النظام',1,0),(4,N'موظف',1,0),(7,N'خارجي',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,UserName,Type,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','test-admin',1,1,0),(2,N'موظف اختبار','test-employee',4,1,0),(7,N'خارجي سابق','test-external',7,1,0);SET IDENTITY_INSERT UsersMembers OFF;
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'العلامة الأولى',1,0),(2,N'العلامة الثانية',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,IsActive,IsDeleted) VALUES(1,1,N'الفرع الأول',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT CRM_Accounts ON;INSERT CRM_Accounts(ID,Name_AR,Owner_ID,Phone,Email,Is_Active,Is_Deleted,AddedUser) VALUES(1,N'عميل الاختبار',1,'0790000000','test@example.invalid',1,0,1),(2,N'عميل آخر',1,'0790000001','test2@example.invalid',1,0,1);SET IDENTITY_INSERT CRM_Accounts OFF;
IF NOT EXISTS(SELECT 1 FROM Employee_Feedback_Types WHERE ID=1) BEGIN SET IDENTITY_INSERT Employee_Feedback_Types ON;INSERT Employee_Feedback_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'شكوى','Complaint',1,0),(2,N'اقتراح','Suggestion',1,0);SET IDENTITY_INSERT Employee_Feedback_Types OFF;END;
SET IDENTITY_INSERT Employee_Feedback_Topics ON;INSERT Employee_Feedback_Topics(ID,Type,Brand_ID,Title_Ar,Title_En,IsActive,IsDeleted,AddedUser) VALUES(1,1,1,N'جودة الخدمة','Quality',1,0,1),(2,2,1,N'تحسين الخدمة','Improve',1,0,1);SET IDENTITY_INSERT Employee_Feedback_Topics OFF;
'@)
 if($FeedbackOnly){
  [void](Q $test.ConnectionString "SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,IsActive,IsDeleted) VALUES(2,N'مدير فرع',1,0),(3,N'مدير وردية',1,0),(5,N'مدير علامة',1,0),(6,N'مدير قسم',1,0);SET IDENTITY_INSERT Users_Types OFF;UPDATE UsersMembers SET Brand_ID=1,Branch_ID=1 WHERE ID IN(1,2);SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,UserName,Type,Brand_ID,Branch_ID,IsActive,IsDeleted) VALUES(3,N'مدير نظام ثان','test-admin-two',1,1,1,1,0),(4,N'موظف آخر','test-other-employee',4,1,1,1,0);SET IDENTITY_INSERT UsersMembers OFF;SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,IsActive,IsDeleted) VALUES(2,1,N'فرع غير مرتبط',1,0),(3,2,N'فرع العلامة الثانية',1,0);SET IDENTITY_INSERT Branches OFF;")
  foreach($file in @('../Employee_Feedback/005_PermissionDefaults.sql','../Employee_Feedback/006_ConfigurableWorkflow.sql','../Employee_Feedback/007_TypesAndApplicant.sql','../Employee_Feedback/008_DashboardDailyActivity.sql','../Employee_Feedback/009_CustomerSupport.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 }
 [void](Q $test.ConnectionString "IF COL_LENGTH('dbo.CRM_Accounts','Brand_ID') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Brand_ID int NULL,Branch_ID int NULL;")
 $access=[regex]::Match([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CRM/001_CRM_Schema.sql')),'(?s)CREATE OR ALTER FUNCTION dbo.CRM_CanAccess.*?(?=\r?\nGO)').Value;[void](Q $test.ConnectionString $access)
 foreach($file in @('../CRM/009_CRM_Contact_Names.sql','../CRM/011_CRM_ContactTitles_Activity.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 [void](Q $test.ConnectionString "IF COL_LENGTH('dbo.CRM_Accounts','Logo_Data') IS NULL ALTER TABLE dbo.CRM_Accounts ADD Logo_Data varbinary(max) NULL;")
 foreach($file in @('001_Accounts.sql','002_Services.sql','003_Portal.sql','006_Dashboard.sql','007_SelfService.sql','008_ContactJobTitles.sql','../News/001_BrandNews.sql','../News/002_BilingualDetails.sql','010_BrandNews.sql','../Information_Pages/001_Schema.sql','../Information_Pages/003_Access_Restore_Schema.sql','../Information_Pages/005_Brand_Access_Schema.sql','../Information_Pages/006_Brand_Access_Procedures.sql','../Information_Pages/004_Access_Restore_Procedures.sql','../Information_Pages/002_Procedures.sql','../Information_Pages/007_Audience_Schema.sql','../Information_Pages/008_Audience_Procedures.sql','../Circulars/001_Schema.sql','../Circulars/002_Procedures.sql','../Circulars/003_BrandedAudiences.sql','../Circulars/004_ReaderVersion.sql','../Email_Notification/001_BrandGmail.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
 }
 $results=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests.sql')))
 $results|Format-Table -AutoSize
 [void](Q $test.ConnectionString "CREATE TABLE dbo.CRM_Account_Logos(Account_ID int PRIMARY KEY REFERENCES dbo.CRM_Accounts(ID),Image_Data varbinary(max) CHECK(DATALENGTH(Image_Data) BETWEEN 8 AND 2097152 AND SUBSTRING(Image_Data,1,8)=0x89504E470D0A1A0A),Modified_User int,Modified_Date datetime2,Row_Version rowversion);INSERT dbo.CRM_Account_Logos(Account_ID,Image_Data,Modified_User) VALUES(2,0x89504E470D0A1A0A,1);")
 foreach($file in @('../CRM/008_CRM_Account_Logos.sql','../CRM/010_CRM_Inline_Logos.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 [void](Q $test.ConnectionString "IF OBJECT_ID('dbo.CRM_Account_Logos','U') IS NOT NULL OR NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=2 AND Logo_Data=0x89504E470D0A1A0A) THROW 51999,'Inline logo migration did not preserve the old image.',1;")
 'PASS: Legacy logo bytes copied and verified; separate logo table removed.'

 . (Join-Path $PSScriptRoot '../CRM/FileLogoMigration.ps1')
 $exportRoot=Join-Path $PSScriptRoot ('../../../tmp/logo-export-test-'+[guid]::NewGuid().ToString('N'))
 $exportConnection=[Data.SqlClient.SqlConnection]::new($test.ConnectionString);$exportConnection.Open();$exportTransaction=$exportConnection.BeginTransaction();$exported=[Collections.Generic.List[string]]::new()
 try {
  Export-CrmLogoFiles $exportConnection $exportTransaction $exportRoot $exported
  Apply-CrmFileLogoSql $exportConnection $exportTransaction (Join-Path $PSScriptRoot '../CRM')
  $exportTransaction.Commit()
 }catch{if($exportTransaction.Connection){$exportTransaction.Rollback()};Remove-CrmStagedLogos $exported;throw}finally{$exportConnection.Dispose()}
 [void](Q $test.ConnectionString "IF COL_LENGTH('dbo.CRM_Accounts','Logo_Data') IS NOT NULL OR NOT EXISTS(SELECT 1 FROM CRM_Accounts WHERE ID=2 AND Logo_Url LIKE '/FileManager/CustomerLogos/%.png') THROW 51999,'URL-only logo migration failed.',1;")
 'PASS: Existing logo file hash verified, URL stored, binary column removed.'
 $results=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-SelfService.sql')))
 $results|Format-Table -AutoSize
 if($MultiBrandOnly){
  foreach($file in @('../CRM/017_CRM_Suppliers.sql','../CRM/020_CRM_Account_Organization.sql','../CRM/022_CRM_MultiBrand_Content.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 }
 if($FeedbackOnly){
  foreach($file in @('../CRM/017_CRM_Suppliers.sql','../CRM/020_CRM_Account_Organization.sql','../CRM/022_CRM_MultiBrand_Content.sql','../Employee_Feedback/010_WorkspaceNotifications.sql','012_FeedbackWorkspace.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
  [void](Q $test.ConnectionString "INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(1,1,1),(2,2,1);INSERT CRM_Account_Branches(Account_ID,Brand_ID,Branch_ID,AddedUser) VALUES(1,1,1,1),(2,2,3,1);")
  $feedbackChecks=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Employee_Feedback/Tests-Workspace.sql')));$feedbackChecks|Format-Table -AutoSize
  . (Join-Path $PSScriptRoot '../Employee_Feedback/WorkspaceMigration.ps1')
  $workspaceCn=[Data.SqlClient.SqlConnection]::new($test.ConnectionString);$workspaceCn.Open();$workspaceTx=$workspaceCn.BeginTransaction()
  try{Apply-FeedbackWorkspace $workspaceCn $workspaceTx -Enable;$workspaceTx.Commit();'PASS: Workspace deployment helper reasserts current readers/writers atomically and is idempotent.'}catch{if($workspaceTx.Connection){$workspaceTx.Rollback()};throw}finally{$workspaceCn.Dispose()}

 }
 if(-not $DatabaseOnly){& (Join-Path $PSScriptRoot 'Test-Dashboard.ps1') -TestConnection $test.ConnectionString -MultiBrandOnly:$MultiBrandOnly -FeedbackOnly:$FeedbackOnly}
 if($ApiBuildDirectory){ & (Join-Path $PSScriptRoot 'Test-CustomerApi.ps1') -BuildDirectory $ApiBuildDirectory -TestConnection $test.ConnectionString }
 $passed=$true
 if($KeepDatabase){
  $stage=Join-Path $PSScriptRoot '../../../../tmp/customer-stage';[IO.Directory]::CreateDirectory($stage)|Out-Null
  $entry=$config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection';$entry.connectionString=$test.ConnectionString
  $config.Save((Join-Path $stage 'Web.config'))
  Set-Content (Join-Path $stage 'test-database.txt') $testName
  "Isolated database retained for browser verification: $testName"
 }
}finally{
 if($created -and (-not $KeepDatabase -or -not $passed) -and $testName -match '^Prosto_Customer_Test_[a-f0-9]{32}$'){
  [Data.SqlClient.SqlConnection]::ClearAllPools();[void](Q $master.ConnectionString "ALTER DATABASE [$testName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$testName]")
 }
}
