param([Parameter(Mandatory)][string]$TestConnection)
$ErrorActionPreference='Stop'
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($TestConnection)
if($test.DataSource -notin @('localhost','.','(local)') -or $test.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'An isolated local test database is required.'}
$api=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Prosto_ERP_API'))
$build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot ('../../../tmp/circular-mail-tests-'+[guid]::NewGuid().ToString('N'))))
[void][IO.Directory]::CreateDirectory($build)
Get-ChildItem -LiteralPath (Join-Path $api 'bin') -Filter '*.dll' | Copy-Item -Destination $build -Force
$exe=Join-Path $build 'CircularNotificationTests.exe'
$refs=@('Prosto_ERP_API.dll','Prosto_ERP_ClassLibrary.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll') | ForEach-Object {'/reference:'+(Join-Path $build $_)}
& (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe "/out:$exe" /reference:System.Configuration.dll /reference:System.Data.dll /reference:System.Web.dll /reference:System.Net.Http.dll @refs (Join-Path $PSScriptRoot 'CircularNotificationTests.cs')
if($LASTEXITCODE -ne 0){throw 'Circular notification test compilation failed.'}
$cfg=New-Object xml
$cfg.LoadXml('<configuration><appSettings><add key="CircularNotifications.Enabled" value="false"/><add key="CircularNotifications.PortalBaseUrl" value="http://localhost:52219/"/></appSettings><connectionStrings><add name="Prosto_ERP_ConnectionConnection" connectionString="" providerName="System.Data.SqlClient"/></connectionStrings></configuration>')
$cfg.configuration.connectionStrings.add.connectionString=$TestConnection
$apiCfg=[xml](Get-Content -LiteralPath (Join-Path $api 'Web.config'))
if($apiCfg.configuration.runtime){[void]$cfg.configuration.AppendChild($cfg.ImportNode($apiCfg.configuration.runtime,$true))}
$cfg.Save($exe+'.config')
& $exe
if($LASTEXITCODE -ne 0){throw 'Circular mail delivery tests failed.'}
