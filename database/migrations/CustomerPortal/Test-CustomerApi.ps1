param([Parameter(Mandatory)][string]$BuildDirectory,[Parameter(Mandatory)][string]$TestConnection)
$ErrorActionPreference='Stop'
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($TestConnection)
if($builder.DataSource -notin @('localhost','.','(local)') -or $builder.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'Only an isolated customer test database is allowed.'}
$exe=Join-Path $BuildDirectory 'CustomerApiTests.exe'
$storage=Join-Path $BuildDirectory $builder.InitialCatalog
$api=Join-Path $PSScriptRoot '../../../src/ProstoERP.Api'
try{
 $cn=[Data.SqlClient.SqlConnection]::new($TestConnection)
 try{
  $cn.Open()
  foreach($script in @('../Mobile_API/001_Sessions.sql','../Mobile_API/005_DeviceSessions.sql','../Mobile_API/006_DeviceAccess.sql','../Mobile_API/008_BIOLogin.sql','004_MobileApi.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $script)),'(?im)^\s*GO\s*$')){
   if($batch.Trim()){$cmd=$cn.CreateCommand();$cmd.CommandText=$batch;[void]$cmd.ExecuteNonQuery();$cmd.Dispose()}
  }
  }
 }finally{$cn.Dispose()}
 $source=[xml](Get-Content (Join-Path $api 'Web.config'))
 $config=[xml]'<configuration><connectionStrings/><appSettings/></configuration>'
 $entry=$config.CreateElement('add');$entry.SetAttribute('name','Prosto_ERP_ConnectionConnection');$entry.SetAttribute('connectionString',$TestConnection);[void]$config.SelectSingleNode('/configuration/connectionStrings').AppendChild($entry)
 $entry=$config.CreateElement('add');$entry.SetAttribute('key','MobileApi.FeedbackStoragePath');$entry.SetAttribute('value',(Join-Path $storage 'feedback'));[void]$config.SelectSingleNode('/configuration/appSettings').AppendChild($entry)
 if($source.configuration.runtime){[void]$config.configuration.AppendChild($config.ImportNode($source.configuration.runtime,$true))}
 $config.Save("$exe.config")
 $refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll')|ForEach-Object {'/reference:'+(Join-Path $BuildDirectory $_)}
 & (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Net.Http.dll /reference:System.Web.dll /reference:System.Configuration.dll /reference:System.Data.dll @refs (Join-Path $PSScriptRoot 'CustomerApi.IntegrationTests.cs') (Join-Path $PSScriptRoot '../Mobile_API/ApiPerformanceProbe.cs')
 if($LASTEXITCODE -ne 0){throw 'API test compilation failed'}
 & $exe
 if($LASTEXITCODE -ne 0){throw 'Customer API integration failed'}
}finally{
 if(Test-Path -LiteralPath "$exe.config"){Remove-Item -LiteralPath "$exe.config"}
 $resolved=[IO.Path]::GetFullPath($storage);$parent=[IO.Path]::GetFullPath($BuildDirectory).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 if($resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -match '^Prosto_Customer_Test_[a-f0-9]{32}$' -and (Test-Path -LiteralPath $resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
