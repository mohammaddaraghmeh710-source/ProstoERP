param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/correspondence-api-build')
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../Prosto_ERP_API'
$config=[xml](Get-Content (Join-Path $api 'Web.config'))
$source=New-Object System.Data.SqlClient.SqlConnectionStringBuilder (($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Tests require local SQL Server.'}
$testName='Prosto_CorrespondenceApi_Test_'+[Guid]::NewGuid().ToString('N')
$master=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
$master['Initial Catalog']='master'
function Execute-Sql([string]$connection,[string]$sql){
 $cn=New-Object System.Data.SqlClient.SqlConnection $connection
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=90;[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}
}
[void][IO.Directory]::CreateDirectory($BuildDirectory)
Get-ChildItem (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $BuildDirectory -Force
$created=$false
$exe=Join-Path $BuildDirectory 'CorrespondenceApiTests.exe'
$storage=Join-Path $BuildDirectory $testName
try{
 Execute-Sql $master.ConnectionString "CREATE DATABASE [$testName]"
 $created=$true
 $test=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $source.ConnectionString
 $test['Initial Catalog']=$testName
 $sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Users_Types','Brands','Branches','Departments','JobTitles','Shift','Genders','Nationalities','Correspondence_Threads','Correspondence_Thread_Messages','Correspondence_Message_Attachments','Correspondence_Notifications')){
  Execute-Sql $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID);"
 }
 Execute-Sql $test.ConnectionString 'CREATE TABLE dbo.Information_Page_Brands(PageID int NOT NULL,BrandID int NOT NULL,PRIMARY KEY(PageID,BrandID))'
 foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../Information_Pages/006_Brand_Access_Procedures.sql')),'(?im)^\s*GO\s*$')){
  if($batch.Trim()){Execute-Sql $test.ConnectionString $batch}
 }
 Execute-Sql $test.ConnectionString @'
SET IDENTITY_INSERT dbo.Users_Types ON;
INSERT dbo.Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) SELECT ID,CONCAT(N'Role ',ID),CONCAT(N'Role ',ID),1,0 FROM (VALUES(1),(2),(3),(4),(5),(6),(7))v(ID);
SET IDENTITY_INSERT dbo.Users_Types OFF;
SET IDENTITY_INSERT dbo.Brands ON; INSERT dbo.Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(29,N'Test brand',N'Test brand',1,0); SET IDENTITY_INSERT dbo.Brands OFF;
SET IDENTITY_INSERT dbo.Branches ON; INSERT dbo.Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(25,29,N'عبدالله غوشة',N'Abdullah Ghosheh',1,0); SET IDENTITY_INSERT dbo.Branches OFF;
'@
 $scripts=@('../Mobile_API/001_Sessions.sql','../Mobile_API/002_Procedures.sql','../Mobile_API/005_DeviceSessions.sql','../Mobile_API/006_DeviceAccess.sql','../Mobile_API/008_BIOLogin.sql','002_Page_Operations.sql','003_Module_Procedures.sql','004_Independent_Procedures.sql','005_Search_Fields.sql','006_Governance.sql','007_Catalogs.sql','008_MobileApi.sql')
 foreach($name in $scripts){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $name)),'(?im)^GO\s*$')){
   if($batch.Trim()){Execute-Sql $test.ConnectionString $batch}
  }
 }
 $xml=New-Object System.Xml.XmlDocument
 $xml.LoadXml('<configuration><connectionStrings/><appSettings/></configuration>')
 $entry=$xml.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$test.ConnectionString)
 [void]$xml.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 foreach($setting in $config.configuration.appSettings.add){
  $node=$xml.ImportNode($setting,$true)
  if($node.GetAttribute('key') -eq 'MobileApi.CorrespondenceStoragePath'){$node.SetAttribute('value',$storage)}
  [void]$xml.SelectSingleNode('/configuration/appSettings').AppendChild($node)
 }
 $http=$xml.SelectSingleNode('/configuration/appSettings/add[@key="MobileApi.AllowHttp"]');if($http){$http.SetAttribute('value','false')}
 if($config.configuration.runtime){[void]$xml.configuration.AppendChild($xml.ImportNode($config.configuration.runtime,$true))}
 $xml.Save("$exe.config")
 $refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','Encryptor.dll') | ForEach-Object { '/reference:'+(Join-Path $BuildDirectory $_) }
 & (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Net.Http.dll /reference:System.Web.dll /reference:System.Configuration.dll /reference:System.Data.dll /reference:System.Drawing.dll /reference:System.IO.Compression.dll @refs (Join-Path $PSScriptRoot 'CorrespondenceApi.IntegrationTests.cs') (Join-Path $PSScriptRoot '../Mobile_API/ApiPerformanceProbe.cs')
 if($LASTEXITCODE -ne 0){throw 'Test compilation failed'}
 & $exe
 if($LASTEXITCODE -ne 0){throw 'Correspondence API integration tests failed'}
}finally{
 [System.Data.SqlClient.SqlConnection]::ClearAllPools()
 if($created -and $testName -match '^Prosto_CorrespondenceApi_Test_[a-f0-9]{32}$'){
  Execute-Sql $master.ConnectionString "ALTER DATABASE [$testName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$testName]"
  'Isolated test database removed.'
 }
 if(Test-Path -LiteralPath "$exe.config"){Remove-Item -LiteralPath "$exe.config"}
 $resolved=[IO.Path]::GetFullPath($storage)
 $parent=[IO.Path]::GetFullPath($BuildDirectory).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 if($resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -match '^Prosto_CorrespondenceApi_Test_[a-f0-9]{32}$' -and (Test-Path -LiteralPath $resolved)){
  Remove-Item -LiteralPath $resolved -Recurse -Force
 }
}
