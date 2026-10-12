param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/email-api-tests')
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../Prosto_ERP_API'
$cfg=[xml][IO.File]::ReadAllText((Join-Path $api 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($cfg.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Tests require local SQL Server.'}
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$name='Prosto_Email_Test_'+[Guid]::NewGuid().ToString('N');$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
function SQL([string]$cs,[string]$text){$cn=[Data.SqlClient.SqlConnection]::new($cs);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$text;$cmd.CommandTimeout=90;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}}
$created=$false
try{
 SQL $master.ConnectionString "CREATE DATABASE [$name]";$created=$true
 $sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Brands')){SQL $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID)"}
 SQL $test.ConnectionString @'
SET IDENTITY_INSERT dbo.UsersMembers ON;INSERT dbo.UsersMembers(ID,Type,UserName,FullName_Ar,IsActive,IsDeleted) VALUES(1,1,N'email-admin',N'Admin',1,0),(2,4,N'email-employee',N'Employee',1,0),(4,1,N'inactive-admin',N'Admin',0,0);SET IDENTITY_INSERT dbo.UsersMembers OFF;
SET IDENTITY_INSERT dbo.Brands ON;INSERT dbo.Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'العلامة الأولى',N'One',1,0),(2,N'العلامة الثانية',N'Two',1,0),(3,N'موقوفة',N'Inactive',0,0),(4,N'غير مهيأة',N'Unconfigured',1,0);SET IDENTITY_INSERT dbo.Brands OFF;
'@
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_BrandGmail.sql')),'(?im)^GO\s*$')){if($batch.Trim()){SQL $test.ConnectionString $batch}}
 [void][IO.Directory]::CreateDirectory($BuildDirectory);Get-ChildItem (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $BuildDirectory -Force
 $exe=Join-Path $BuildDirectory 'EmailTests.exe';$xml=[xml]'<configuration><connectionStrings/><appSettings/></configuration>'
 $entry=$xml.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$test.ConnectionString);[void]$xml.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 $entry=$xml.CreateElement('add');$entry.SetAttribute('key','MobileApi.AllowHttp');$entry.SetAttribute('value','false');[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($entry)
 if($cfg.configuration.runtime){[void]$xml.configuration.AppendChild($xml.ImportNode($cfg.configuration.runtime,$true))};$xml.Save("$exe.config")
 $auth=[IO.File]::ReadAllText((Join-Path $api 'Authentication/AuthenticationAttribute.cs'))
 $authName=[regex]::Match($auth,'pair\[0\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value;$secret=[regex]::Match($auth,'pair\[1\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value
 if(!$authName -or !$secret){throw 'Unable to resolve current integration auth for the isolated test.'};$env:EMAIL_TEST_BASIC=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authName+':'+$secret))
 $refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','Prosto_ERP_ClassLibrary.dll','MailKit.dll','MimeKit.dll') | ForEach-Object { '/reference:'+(Join-Path $BuildDirectory $_) }
 & (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Net.Http.dll /reference:System.Configuration.dll /reference:System.Data.dll @refs (Join-Path $PSScriptRoot 'EmailNotificationTests.cs')
 if($LASTEXITCODE -ne 0){throw 'Email test compilation failed'};& $exe;if($LASTEXITCODE -ne 0){throw 'Email tests failed'}
}finally{
 Remove-Item Env:EMAIL_TEST_BASIC -ErrorAction SilentlyContinue
 [Data.SqlClient.SqlConnection]::ClearAllPools();if($created){SQL $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$name]";'Isolated email database removed.'}
}
