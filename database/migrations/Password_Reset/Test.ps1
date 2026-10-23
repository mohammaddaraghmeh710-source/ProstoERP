param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/password-reset-tests')
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../../src/ProstoERP.Api'
$cfg=[xml][IO.File]::ReadAllText((Join-Path $api 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($cfg.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Tests require local SQL Server.'}
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$name='Prosto_Reset_Test_'+[Guid]::NewGuid().ToString('N');$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
function SQL([string]$cs,[string]$text){$cn=[Data.SqlClient.SqlConnection]::new($cs);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$text;$cmd.CommandTimeout=90;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}}
$created=$false
try {
 SQL $master.ConnectionString "CREATE DATABASE [$name]";$created=$true
 $sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Brands')){SQL $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID)"}
 SQL $test.ConnectionString @'
SET IDENTITY_INSERT dbo.UsersMembers ON;
INSERT dbo.UsersMembers(ID,Type,Employee_Number,Brand_ID,Email,UserName,FullName_Ar,IsActive,IsDeleted) VALUES(1,1,100,1,'employee@example.test','100',N'<script>موظف</script>',1,0),(2,4,101,1,NULL,'101',N'بدون بريد',1,0);
SET IDENTITY_INSERT dbo.UsersMembers OFF;
SET IDENTITY_INSERT dbo.Brands ON;INSERT dbo.Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'العلامة الأولى',N'One',1,0);SET IDENTITY_INSERT dbo.Brands OFF;
CREATE TABLE dbo.MobileApi_Sessions(UserID int NOT NULL,RevokedUtc datetime2 NULL);
CREATE TABLE dbo.MobileApi_BIOCredentials(UserID int NOT NULL);
'@
 foreach($script in @('../Email_Notification/001_BrandGmail.sql','001_PasswordReset.sql','002_PerformanceIndexes.sql')) {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $script)),'(?im)^\s*GO\s*$')){if($batch.Trim()){SQL $test.ConnectionString $batch}}
 }
 [void][IO.Directory]::CreateDirectory($BuildDirectory);Get-ChildItem (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $BuildDirectory -Force
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../../../src/Portal/bin/CRM.dll') -Destination $BuildDirectory -Force
 $exe=Join-Path $BuildDirectory 'ResetTests.exe';$xml=[xml]'<configuration><connectionStrings/><appSettings/></configuration>'
 $entry=$xml.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$test.ConnectionString);[void]$xml.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 $entry=$xml.CreateElement('add');$entry.SetAttribute('key','MobileApi.AllowHttp');$entry.SetAttribute('value','false');[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($entry)
 $entry=$xml.CreateElement('add');$entry.SetAttribute('key','PasswordReset.HashKey');$entry.SetAttribute('value',[string]($cfg.configuration.appSettings.add | Where-Object key -eq 'PasswordReset.HashKey').value);[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($entry)
 if($cfg.configuration.runtime){[void]$xml.configuration.AppendChild($xml.ImportNode($cfg.configuration.runtime,$true))};$xml.Save("$exe.config")
 $auth=[IO.File]::ReadAllText((Join-Path $api 'Shared/Authentication/AuthenticationAttribute.cs'))
 $authName=[regex]::Match($auth,'pair\[0\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value;$secret=[regex]::Match($auth,'pair\[1\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value
 if(!$authName -or !$secret){throw 'Cannot resolve test integration auth.'};$env:EMAIL_TEST_BASIC=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authName+':'+$secret))
 $refs=@('CRM.dll','Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','Prosto_ERP_ClassLibrary.dll','MailKit.dll','MimeKit.dll','Encryptor.dll') | ForEach-Object { '/reference:'+(Join-Path $BuildDirectory $_) }
 & (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Web.dll /reference:System.Data.Linq.dll /reference:System.Net.Http.dll /reference:System.Configuration.dll /reference:System.Data.dll @refs (Join-Path $PSScriptRoot 'PasswordResetTests.cs')
 if($LASTEXITCODE -ne 0){throw 'Reset test compilation failed'};& $exe;if($LASTEXITCODE -ne 0){throw 'Reset tests failed'}
}finally {
 Remove-Item Env:EMAIL_TEST_BASIC -ErrorAction SilentlyContinue
 [Data.SqlClient.SqlConnection]::ClearAllPools();if($created){SQL $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$name]";'Isolated reset database removed.'}
}
