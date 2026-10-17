param([switch]$KeepDatabase,[string]$ApiBuildDirectory)
$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL Server required.'}
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$testName='Prosto_Customer_Test_'+[guid]::NewGuid().ToString('N')
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$testName
function Q([string]$connection,[string]$sql){
 $cn=[Data.SqlClient.SqlConnection]::new($connection)
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=120;$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cn.Dispose()}
}
$created=$false; $passed=$false
try{
 [void](Q $master.ConnectionString "CREATE DATABASE [$testName]");$created=$true
 $tables=@('UsersMembers','Users_Types','Brands','Branches','CRM_Accounts','Work_Guide_Categories','Work_Guide_Roles','Work_Guide_Role_Permissions','Work_Guide_Documents','Work_Guide_User_Category_Roles','Work_Guide_Activity_Logs','Employee_Feedback_Types','Employee_Feedback_Topics','Employee_Feedback_Requests','Employee_Feedback_Workflow','Employee_Feedback_Attachments','Employee_Feedback_Notifications')
 foreach($table in $tables){
  [void](Q $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$($source.InitialCatalog)].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID);")
  $defaults=Q $source.ConnectionString "SELECT c.name Col,d.definition Def FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID('dbo.$table')"
  foreach($row in $defaults.Rows){[void](Q $test.ConnectionString "ALTER TABLE dbo.[$table] ADD DEFAULT $($row.Def) FOR [$($row.Col)]")}
 }
 [void](Q $test.ConnectionString @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'مدير النظام',1,0),(4,N'موظف',1,0),(7,N'خارجي',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,UserName,Type,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','test-admin',1,1,0),(2,N'موظف اختبار','test-employee',4,1,0),(7,N'خارجي سابق','test-external',7,1,0);SET IDENTITY_INSERT UsersMembers OFF;
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'العلامة الأولى',1,0),(2,N'العلامة الثانية',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,IsActive,IsDeleted) VALUES(1,1,N'الفرع الأول',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT CRM_Accounts ON;INSERT CRM_Accounts(ID,Name_AR,Owner_ID,Phone,Email,Is_Active,Is_Deleted,AddedUser) VALUES(1,N'عميل الاختبار',1,'0790000000','test@example.invalid',1,0,1),(2,N'عميل آخر',1,'0790000001','test2@example.invalid',1,0,1);SET IDENTITY_INSERT CRM_Accounts OFF;
SET IDENTITY_INSERT Work_Guide_Categories ON;INSERT Work_Guide_Categories(ID,Brand_ID,Parent_ID,Title_Ar,IsActive,IsDeleted) VALUES(1,1,NULL,N'التشغيل',1,0),(2,1,1,N'إجراءات العمل',1,0),(3,2,NULL,N'التعليمات',1,0);SET IDENTITY_INSERT Work_Guide_Categories OFF;
SET IDENTITY_INSERT Work_Guide_Roles ON;INSERT Work_Guide_Roles(ID,Title_Ar,Code,IsActive,IsDeleted) VALUES(1,N'عرض وتنزيل','test-full',1,0),(2,N'عرض فقط','test-view',1,0);SET IDENTITY_INSERT Work_Guide_Roles OFF;
INSERT Work_Guide_Role_Permissions(Role_ID,Can_View_Category,Can_View_Document,Can_Print_Document,Can_Download_Document) VALUES(1,1,1,1,1),(2,1,1,0,0);
SET IDENTITY_INSERT Work_Guide_Documents ON;INSERT Work_Guide_Documents(ID,Brand_ID,Category_ID,Title_Ar,File_Path,Is_Download_Allowed,IsActive,IsDeleted,AddedDate) VALUES(1,1,2,N'دليل إجراءات العمل','~/App_Data/customer-test.pdf',1,1,0,GETDATE()),(2,2,3,N'دليل العلامة الثانية','~/App_Data/customer-test.pdf',0,1,0,GETDATE());SET IDENTITY_INSERT Work_Guide_Documents OFF;
SET IDENTITY_INSERT Employee_Feedback_Types ON;INSERT Employee_Feedback_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'شكوى','Complaint',1,0),(2,N'اقتراح','Suggestion',1,0);SET IDENTITY_INSERT Employee_Feedback_Types OFF;
SET IDENTITY_INSERT Employee_Feedback_Topics ON;INSERT Employee_Feedback_Topics(ID,Type,Brand_ID,Title_Ar,Title_En,IsActive,IsDeleted,AddedUser) VALUES(1,1,1,N'جودة الخدمة','Quality',1,0,1),(2,2,1,N'تحسين الخدمة','Improve',1,0,1);SET IDENTITY_INSERT Employee_Feedback_Topics OFF;
'@)
 foreach($file in @('../WorkGuide_Access/001_Access_Requests.sql','001_Accounts.sql','002_Services.sql','003_Portal.sql','005_WorkGuideIntegration.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
 }
 $results=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests.sql')))
 $results|Format-Table -AutoSize
 $results=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-WorkGuideIntegration.sql')))
 $results|Format-Table -AutoSize
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
