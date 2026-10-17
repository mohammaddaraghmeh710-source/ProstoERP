param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/circulars-api-build',[switch]$KeepForUI)
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../../src/ProstoERP.Api'
$cfg=[xml](Get-Content (Join-Path $api 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($cfg.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL only.'}
$testName='Prosto_Circulars_Test_'+[Guid]::NewGuid().ToString('N')
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
function Sql([string]$cs,[string]$sql){$cn=[Data.SqlClient.SqlConnection]::new($cs);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandTimeout=90;$cmd.CommandText=$sql;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}}
$created=$false;$passed=$false;$exe=Join-Path $BuildDirectory 'CircularTests.exe'
try{
 [void][IO.Directory]::CreateDirectory($BuildDirectory)
 Get-ChildItem -LiteralPath (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $BuildDirectory -Force
 Sql $master.ConnectionString "CREATE DATABASE [$testName]";$created=$true
 $test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$testName;$sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Users_Types','Users_Status','Brands','Branches','Departments','JobTitles','Shift','Genders','Nationalities','News','Information_Pages','Information_Page_Roles')){
  Sql $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]"
 }
 Sql $test.ConnectionString 'ALTER TABLE dbo.UsersMembers ADD PRIMARY KEY(ID)'
 Sql $test.ConnectionString 'CREATE TABLE dbo.Information_Page_Brands(PageID int NOT NULL,BrandID int NOT NULL,PRIMARY KEY(PageID,BrandID))'
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Information_Pages/006_Brand_Access_Procedures.sql')),'(?im)^\s*GO\s*$')){
  if($batch.Trim()){Sql $test.ConnectionString $batch}
 }
 foreach($file in @('../Mobile_API/001_Sessions.sql','../Mobile_API/002_Procedures.sql','../Mobile_API/005_DeviceSessions.sql','../Mobile_API/006_DeviceAccess.sql','../Mobile_API/008_BIOLogin.sql','001_Schema.sql','002_Procedures.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^GO\s*$')){if($batch.Trim()){Sql $test.ConnectionString $batch}}
 }
 $xml=[xml]'<configuration><connectionStrings/><appSettings/></configuration>'
 $entry=$xml.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$test.ConnectionString);[void]$xml.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 foreach($setting in $cfg.configuration.appSettings.add){[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($xml.ImportNode($setting,$true))}
 $httpSetting=$xml.SelectSingleNode('/configuration/appSettings/add[@key="MobileApi.AllowHttp"]')
 if($httpSetting){$httpSetting.SetAttribute('value','false')}else{$httpSetting=$xml.CreateElement('add');$httpSetting.SetAttribute('key','MobileApi.AllowHttp');$httpSetting.SetAttribute('value','false');[void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($httpSetting)}
 if($cfg.configuration.runtime){[void]$xml.configuration.AppendChild($xml.ImportNode($cfg.configuration.runtime,$true))}
 $xml.Save("$exe.config")
 $refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','Encryptor.dll')|ForEach-Object{'/reference:'+(Join-Path $BuildDirectory $_)}
 & (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Net.Http.dll /reference:System.Web.dll /reference:System.Configuration.dll /reference:System.Data.dll @refs (Join-Path $PSScriptRoot 'Circulars.IntegrationTests.cs')
 if($LASTEXITCODE -ne 0){throw 'Test compilation failed'}
 & $exe
 if($LASTEXITCODE -ne 0){throw 'Circular tests failed'}
 $passed=$true
 if($KeepForUI){[IO.File]::WriteAllText((Join-Path $PSScriptRoot '../../../../tmp/circulars-test-database.txt'),$testName);'Isolated test database retained for UI verification.'}
}finally{
 [Data.SqlClient.SqlConnection]::ClearAllPools()
 if($created -and !($KeepForUI -and $passed) -and $testName -match '^Prosto_Circulars_Test_[a-f0-9]{32}$'){Sql $master.ConnectionString "ALTER DATABASE [$testName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$testName]";'Isolated test database removed.'}
 if(Test-Path -LiteralPath "$exe.config"){Remove-Item -LiteralPath "$exe.config"}
}
