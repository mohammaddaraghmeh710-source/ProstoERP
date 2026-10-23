param([string]$BuildDirectory = 'C:/Projects/ERPProsto/tmp/mobile-api-build')
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../Prosto_ERP_API'
$config=[xml](Get-Content (Join-Path $api 'Web.config'))
$source=New-Object System.Data.SqlClient.SqlConnectionStringBuilder (($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Tests require local SQL Server.'}
$testName='Prosto_MobileApi_Test_'+[Guid]::NewGuid().ToString('N')
$master=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
$master['Initial Catalog']='master'
function Execute-Sql([string]$connection,[string]$sql){
 $cn=New-Object System.Data.SqlClient.SqlConnection $connection
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=60;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}
}
$created=$false
$authSource=[IO.File]::ReadAllText((Join-Path $api 'Authentication/AuthenticationAttribute.cs'))
$authName=[regex]::Match($authSource,'pair\[0\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value
$authSecret=[regex]::Match($authSource,'pair\[1\]\s*!=\s*"([^"\r\n]+)"').Groups[1].Value
if(!$authName -or !$authSecret){throw 'Current fixed integration credentials could not be resolved for the isolated BIO test.'}
$env:BIO_TEST_BASIC=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authName+':'+$authSecret))
try{
 Execute-Sql $master.ConnectionString "CREATE DATABASE [$testName]"
 $created=$true
 $test=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
 $test['Initial Catalog']=$testName
 $sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Users_Types','Brands','Branches','Departments','JobTitles','Shift','Genders','Nationalities','News','Information_Pages','Information_Page_Roles')){
  Execute-Sql $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]"
 }
 Execute-Sql $test.ConnectionString 'ALTER TABLE dbo.UsersMembers ADD PRIMARY KEY(ID); ALTER TABLE dbo.Brands ADD PRIMARY KEY(ID)'
 Execute-Sql $test.ConnectionString 'CREATE TABLE dbo.Information_Page_Brands(PageID int NOT NULL,BrandID int NOT NULL,PRIMARY KEY(PageID,BrandID))'
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Information_Pages/006_Brand_Access_Procedures.sql')),'(?im)^\s*GO\s*$')){
  if($batch.Trim()){Execute-Sql $test.ConnectionString $batch}
 }
 foreach($name in @('001_Sessions.sql','002_Procedures.sql','005_DeviceSessions.sql','006_DeviceAccess.sql','008_BIOLogin.sql','../News/001_BrandNews.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $name)),'(?im)^GO\s*$')){
   if($batch.Trim()){Execute-Sql $test.ConnectionString $batch}
  }
 }
 [void][IO.Directory]::CreateDirectory($BuildDirectory)
 Get-ChildItem -LiteralPath (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $BuildDirectory -Force
 $exe=Join-Path $BuildDirectory 'MobileApiTests.exe'
 $xml=New-Object System.Xml.XmlDocument
 $xml.LoadXml('<configuration><connectionStrings/><appSettings/></configuration>')
 $entry=$xml.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$test.ConnectionString)
 [void]$xml.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 foreach($setting in $config.configuration.appSettings.add){[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($xml.ImportNode($setting,$true))}
 $httpSetting=$xml.SelectSingleNode('/configuration/appSettings/add[@key="MobileApi.AllowHttp"]'); if($httpSetting){$httpSetting.SetAttribute('value','false')}else{$httpSetting=$xml.CreateElement('add');$httpSetting.SetAttribute('key','MobileApi.AllowHttp');$httpSetting.SetAttribute('value','false');[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($httpSetting)}
 if($config.configuration.runtime){[void]$xml.configuration.AppendChild($xml.ImportNode($config.configuration.runtime,$true))}
 $xml.Save("$exe.config")
 $compiler=Join-Path $api 'bin/roslyn/csc.exe'
 $refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','Encryptor.dll','Prosto_ERP_ClassLibrary.dll') | ForEach-Object { '/reference:'+(Join-Path $BuildDirectory $_) }
 & $compiler /nologo /target:exe "/out:$exe" /reference:System.Net.Http.dll /reference:System.Web.dll /reference:System.Configuration.dll /reference:System.Data.dll /reference:System.Data.Linq.dll @refs (Join-Path $PSScriptRoot 'MobileApi.IntegrationTests.cs') (Join-Path $PSScriptRoot 'ApiPerformanceProbe.cs')
 if($LASTEXITCODE -ne 0){throw 'Test compilation failed'}
 & $exe (Join-Path $PSScriptRoot '006_DeviceAccess.sql') (Join-Path $PSScriptRoot '008_BIOLogin.sql')
 if($LASTEXITCODE -ne 0){throw 'Integration tests failed'}
}finally{
 Remove-Item Env:BIO_TEST_BASIC -ErrorAction SilentlyContinue
 [System.Data.SqlClient.SqlConnection]::ClearAllPools()
 if($created -and $testName -match '^Prosto_MobileApi_Test_[a-f0-9]{32}$'){
  Execute-Sql $master.ConnectionString "ALTER DATABASE [$testName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$testName]"
  'Isolated test database removed.'
 }
 # This generated file contains the local connection string, so remove it after the run.
 $testConfig=Join-Path $BuildDirectory 'MobileApiTests.exe.config'
 if(Test-Path -LiteralPath $testConfig){Remove-Item -LiteralPath $testConfig}
}
