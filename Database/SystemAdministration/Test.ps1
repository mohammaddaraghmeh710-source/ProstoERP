param([switch]$KeepDatabase)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Web
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$portal=Join-Path $root 'Portal'
$config=[xml](Get-Content -LiteralPath (Join-Path $portal 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Only local SQL Server is supported.'}
$name='Prosto_SystemAdmin_Test_'+[guid]::NewGuid().ToString('N')
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
$stage=[IO.Path]::GetFullPath((Join-Path $root ('../tmp/system-admin-'+[guid]::NewGuid().ToString('N'))))
$output=[IO.Path]::GetFullPath((Join-Path $root '../tmp/system-admin-results'));[void][IO.Directory]::CreateDirectory($output)
function Query([string]$connection,[string]$sql,[hashtable]$parameters=@{}){$cn=[Data.SqlClient.SqlConnection]::new($connection);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=300;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cn.Dispose()}}
function Assert([bool]$condition,[string]$message){if(!$condition){throw $message};"PASS: $message"}
$created=$false;$passed=$false
try{
 # Definitions only, with synthetic fixtures. No application rows or credentials are copied.
 [void](Query $master.ConnectionString "CREATE DATABASE [$name]");$created=$true
 $menu=[IO.File]::ReadAllText((Join-Path $portal 'Site.Master')).Split(@('<!-- Administrator -->'),[StringSplitOptions]::None)[1].Split(@('<% If CanUseCRM() Then %>'),[StringSplitOptions]::None)[0]
 $routes=@([regex]::Matches($menu,'href="(/Modules/[^"?]+\.aspx)"')|ForEach-Object{$_.Groups[1].Value}|Where-Object{$_ -notlike '/Modules/News/*'})
 $codeFiles=@($routes|ForEach-Object{Get-ChildItem -LiteralPath (Join-Path $portal ([IO.Path]::GetDirectoryName($_.TrimStart('/')))) -Filter '*.vb'})
 $codeFiles+=@('Site.Master.vb','CircularNotifications.aspx.vb','AppCode/EmployeeFeedbackData.vb','AppCode/EmployeeFeedbackConfig.vb','AppCode/EmployeeFeedbackCatalog.vb','AppCode/CorrespondenceData.vb','AppCode/AttendanceData.vb','AppCode/SystemAdministrationUI.vb','AppCode/CRMSupplierData.vb')|ForEach-Object{Get-Item -LiteralPath (Join-Path $portal $_)}
 $codeFiles+=Get-Item -LiteralPath (Join-Path $root 'Prosto_ERP_ClassLibrary/AttendanceIntegration.vb')
 $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($file in $codeFiles){$code=[IO.File]::ReadAllText($file.FullName);foreach($m in [regex]::Matches($code,'(?i)(?:db\.((?:Select|Insert|Update|Save|Delete)_\w+)|(?:\[dbo\]|dbo)\s*\.\s*\[?(\w+)\]?)')){$value=if($m.Groups[1].Success){$m.Groups[1].Value}else{$m.Groups[2].Value};[void]$names.Add($value)}}
 foreach($table in @('UsersMembers','Users_Types','Brands','Branches','Departments','JobTitles','Shift','Users_Status','Genders','Nationalities','CRM_Account_Types','CRM_Accounts','CRM_Supplier_Brands')){[void]$names.Add($table)}
 $quoted=($names|ForEach-Object{"N'"+$_.Replace("'","''")+"'"}) -join ','
 $objects=Query $source.ConnectionString ("WITH objects AS (SELECT object_id,CAST('/'+CONVERT(varchar(20),object_id)+'/' AS varchar(max)) Path FROM sys.objects WHERE schema_id=SCHEMA_ID('dbo') AND name IN ($quoted) UNION ALL SELECT d.referenced_id,CAST(o.Path+CONVERT(varchar(20),d.referenced_id)+'/' AS varchar(max)) FROM objects o JOIN sys.sql_expression_dependencies d ON d.referencing_id=o.object_id WHERE d.referenced_id IS NOT NULL AND o.Path NOT LIKE '%/'+CONVERT(varchar(20),d.referenced_id)+'/%') SELECT DISTINCT s.name,RTRIM(s.type) type,m.definition FROM objects o JOIN sys.objects s ON s.object_id=o.object_id LEFT JOIN sys.sql_modules m ON m.object_id=s.object_id WHERE s.schema_id=SCHEMA_ID('dbo') AND s.type IN('U','P','V','FN','IF','TF') OPTION(MAXRECURSION 100)")
 foreach($row in @($objects.Rows|Where-Object type -eq 'U')){
  $table=[string]$row.name
  [void](Query $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$($source.InitialCatalog)].dbo.[$table]")
  $columns=Query $source.ConnectionString "SELECT c.name FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=OBJECT_ID('dbo.$table') AND i.is_primary_key=1 ORDER BY ic.key_ordinal"
  if($columns.Rows.Count){$pk=($columns.Rows|ForEach-Object{'['+([string]$_.name).Replace(']',']]')+']'}) -join ',';[void](Query $test.ConnectionString "ALTER TABLE dbo.[$table] ADD PRIMARY KEY($pk)")}
  $defaults=Query $source.ConnectionString "SELECT c.name Col,d.definition Def FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID('dbo.$table')"
  foreach($value in $defaults.Rows){[void](Query $test.ConnectionString "ALTER TABLE dbo.[$table] ADD DEFAULT $($value.Def) FOR [$($value.Col)]")}
 }
 $pending=@($objects.Rows|Where-Object type -ne 'U')
 for($attempt=0;$pending.Count -and $attempt -lt 20;$attempt++){$remaining=@();foreach($row in $pending){try{[void](Query $test.ConnectionString ([regex]::Replace([string]$row.definition,'(?i)\b(?:CREATE\s+OR\s+ALTER|CREATE|ALTER)\s+(PROCEDURE|PROC|FUNCTION|VIEW)\b','CREATE OR ALTER $1')))}catch{$remaining+=$row}};if($remaining.Count -eq $pending.Count){throw ('Unresolved SQL definitions: '+(($remaining|ForEach-Object name) -join ','))};$pending=$remaining}
 [void](Query $test.ConnectionString @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','Test admin',1,0),(4,N'موظف اختبار','Test employee',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,Fullname_En,UserName,Type,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','Test administrator','test-admin',1,1,0),(2,N'موظف اختبار','Test employee','test-employee',4,1,0);SET IDENTITY_INSERT UsersMembers OFF;
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'علامة اختبار','Test brand',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'فرع اختبار','Test branch',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT Departments ON;INSERT Departments(ID,BranchID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'قسم اختبار','Test department',1,0);SET IDENTITY_INSERT Departments OFF;
SET IDENTITY_INSERT JobTitles ON;INSERT JobTitles(ID,DepartmentID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'محطة اختبار','Test station',1,0);SET IDENTITY_INSERT JobTitles OFF;
SET IDENTITY_INSERT CRM_Account_Types ON;INSERT CRM_Account_Types(ID,Name_AR,Name_EN,System_Code,Is_Active,Is_Deleted,AddedUser) VALUES(101,N'الموردون','Suppliers','SUPPLIER',1,0,1);SET IDENTITY_INSERT CRM_Account_Types OFF;
SET IDENTITY_INSERT CRM_Accounts ON;INSERT CRM_Accounts(ID,Name_AR,Name_EN,Account_Type_ID,Brand_ID,Is_Active,Is_Deleted,AddedUser) VALUES(101,N'مورد اختبار','Test supplier',101,1,1,0,1);SET IDENTITY_INSERT CRM_Accounts OFF;
INSERT CRM_Supplier_Brands(Account_ID,Brand_ID,AddedUser) VALUES(101,1,1);
'@)
 foreach($table in @('Genders','Nationalities','Users_Status','Shift','JobTitle_Items_Types','Maintenance_Companies','HR_Vacations_Types','HR_Leaves_Types','Employee_Feedback_Types','Employee_Feedback_Topics','JobTitle_Items')){
  $columns=Query $test.ConnectionString "SELECT name FROM sys.columns WHERE object_id=OBJECT_ID('dbo.$table')"
  $values=@{Title_Ar="N'عنصر اختبار'";Title_En="N'Test reference'";Name_AR="N'نوع اختبار'";Name_En="N'Test type'";IsActive='1';Is_Active='1';IsDeleted='0';Is_Deleted='0';Item_Order='0';AddedUser='1';AddedDate='GETDATE()';Core_ID='1';Max_Value='1';JobTitle_ID='1';Tool_Number="N'QA-001'";ItemTypeID='1';Supplier_Account_ID='101';MaintenanceCompanyID='1';Type='1';Brand_ID='1'}
  $fields=@();$expressions=@();foreach($column in $columns.Rows){if($values.ContainsKey([string]$column.name)){$fields+='['+$column.name+']';$expressions+=$values[[string]$column.name]}}
  [void](Query $test.ConnectionString ('INSERT dbo.['+$table+']('+($fields -join ',')+') VALUES('+($expressions -join ',')+')'))
 }
 [void]([Reflection.Assembly]::LoadFrom((Join-Path $portal 'bin/Encryptor.dll')))
 $cipher=([Echo.Encrptor.TripleDesEncryptor]::new()).Encrypt('System-Admin-Fixture!2026')
 [void](Query $test.ConnectionString 'UPDATE dbo.UsersMembers SET Password=@Password,Employee_Number=ID,Status=1,Gender=1,Nationality=1,Brand_ID=1,Branch_ID=1,Department_ID=1,JobTitle_ID=1,Shif_ID=1' @{'@Password'=$cipher})
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'bin'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'Controls'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'FileManager'))
 Copy-Item -Path (Join-Path $portal 'bin/*.dll') -Destination (Join-Path $stage 'bin') -Force
 Copy-Item -Path (Join-Path $portal 'Controls/*.ascx') -Destination (Join-Path $stage 'Controls') -Force
 foreach($file in @('Site.Master','CircularNotifications.aspx','Login.aspx','Customer.Master')){Copy-Item -LiteralPath (Join-Path $portal $file) -Destination $stage}
 $menu=[IO.File]::ReadAllText((Join-Path $portal 'Site.Master')).Split(@('<!-- Administrator -->'),[StringSplitOptions]::None)[1].Split(@('<% If CanUseCRM() Then %>'),[StringSplitOptions]::None)[0]
 $routes=@([regex]::Matches($menu,'href="(/Modules/[^"?]+\.aspx)"')|ForEach-Object{$_.Groups[1].Value}|Where-Object{$_ -notlike '/Modules/News/*'})
 foreach($route in $routes){$folder=[IO.Path]::GetDirectoryName($route.TrimStart('/'));[void][IO.Directory]::CreateDirectory((Join-Path $stage $folder));Get-ChildItem -LiteralPath (Join-Path $portal $folder) -Filter '*.aspx'|Copy-Item -Destination (Join-Path $stage $folder) -Force}
 foreach($folder in @('assets','ckeditor','fonts')){New-Item -ItemType Junction -Path (Join-Path $stage $folder) -Target (Join-Path $portal $folder)|Out-Null}
 ($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString=$test.ConnectionString
 $web=$config.configuration.'system.web';$modules=$web.httpModules;if($null -eq $modules){$modules=$config.CreateElement('httpModules');[void]$web.AppendChild($modules)}
 $module=$config.CreateElement('add');$module.SetAttribute('name','NewsPortalTestIdentity');$module.SetAttribute('type','NewsPortalTestIdentity, CustomerPortalPageTests');[void]$modules.AppendChild($module)
 $serverModules=$config.configuration.'system.webServer'.modules;if($null -eq $serverModules){$serverModules=$config.CreateElement('modules');[void]$config.configuration.'system.webServer'.AppendChild($serverModules)}
 $module=$config.CreateElement('add');$module.SetAttribute('name','NewsPortalTestIdentity');$module.SetAttribute('type','NewsPortalTestIdentity, CustomerPortalPageTests');[void]$serverModules.AppendChild($module)
 $config.Save((Join-Path $stage 'Web.config'))
 $assembly=Join-Path $stage 'bin/CustomerPortalPageTests.dll';Add-Type -Path (Join-Path $root 'Database/CustomerPortal/CustomerPortalPageTests.cs') -ReferencedAssemblies @('System.Web',(Join-Path $stage 'bin/CRM.dll')) -OutputAssembly $assembly
 $type=[Reflection.Assembly]::LoadFrom($assembly).GetType('CustomerPortalPageHost');$hostObject=[Web.Hosting.ApplicationHost]::CreateApplicationHost($type,'/',$stage)
 foreach($route in $routes){
  $html=$hostObject.Request($route+'?newsTestActor=1',$null)
  if($hostObject.Status -ne 200 -or $html -match 'Server Error|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'error.html'),$html);throw "Rendering failed: $route ($($hostObject.Status)). See tmp/system-admin-results/error.html"}
  Assert ($html -match 'systemAdminConfiguration' -and $html -match 'systemAdminPanel') "$route renders with the shared asynchronous workspace"
  $json=[regex]::Match($html,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
  if(-not $json.special){$rendered=[regex]::Matches($html,'<tr[^>]+data-admin-id=');$active=[regex]::Matches($html,'data-admin-active=[''"]1[''"]');Assert ($rendered.Count -eq $active.Count) 'Every synthetic active row exposes its actual state for filters and badges'}
  $forms=@();if($json.add){$forms+=$json.add+'?saEditor='+$json.token};if($json.edit){$forms+=$json.edit+'?ID=1&saEditor='+$json.token}
  if($json.special){$forms+=$route+'?'+$(if($json.special -eq 'permissions'){'role=4'}else{'brand=1'})+'&saEditor='+$json.token}
  foreach($url in $forms){$editor=$hostObject.Request($url,$null);if($hostObject.Status -ne 200 -or $editor -match 'Server Error|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'error.html'),$editor);throw "Editor rendering failed: $url ($($hostObject.Status)). See tmp/system-admin-results/error.html"};Assert ($editor -match '"editor":true' -and $editor -match 'systemAdminPanel') "Embedded editor renders: $($url.Split('?')[0])"}
 }
 . (Join-Path $PSScriptRoot 'Test-Editors.ps1')
 $html=$hostObject.Request('/Modules/Brands/ManageBrands.aspx?newsTestActor=2',$null);Assert ($hostObject.Status -eq 403) 'An ordinary employee cannot use system administration'
 [IO.File]::WriteAllText((Join-Path $output 'stage.txt'),$stage)
 [IO.File]::WriteAllText((Join-Path $output 'database.txt'),$name)
 $passed=$true;"Management render checks passed. Stage: $stage"
}finally{
 if($created -and (-not $KeepDatabase -or -not $passed) -and $name -match '^Prosto_SystemAdmin_Test_[a-f0-9]{32}$'){[Data.SqlClient.SqlConnection]::ClearAllPools();[void](Query $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$name]")}
}

