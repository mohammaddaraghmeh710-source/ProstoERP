param([string]$BuildDirectory = 'C:/Projects/ERPProsto/tmp/biotime-tests')
$ErrorActionPreference='Stop'
$api=Join-Path $PSScriptRoot '../../../src/ProstoERP.Api'
New-Item -ItemType Directory -Force $BuildDirectory | Out-Null
Copy-Item (Join-Path $api 'bin/*.dll') $BuildDirectory -Force
$refs=@('Prosto_ERP_API.dll','System.Web.Http.dll','System.Net.Http.Formatting.dll','Newtonsoft.Json.dll','System.Web.Http.WebHost.dll','Prosto_ERP_ClassLibrary.dll') | ForEach-Object { '/reference:'+(Join-Path $BuildDirectory $_) }
& (Join-Path $api 'bin/roslyn/csc.exe') /nologo /target:exe ('/out:'+(Join-Path $BuildDirectory 'BioTimeTests.exe')) /reference:System.Data.dll /reference:System.Data.Linq.dll /reference:System.Net.Http.dll /reference:System.Web.dll @refs (Join-Path $PSScriptRoot 'BioTime.IntegrationTests.cs') (Join-Path $PSScriptRoot 'BrandIntegrationTests.cs')
if($LASTEXITCODE -ne 0){throw 'Test compilation failed.'}
$config=[xml](Get-Content (Join-Path $api 'Web.config'))
$testConfig=New-Object System.Xml.XmlDocument
$testConfig.LoadXml('<configuration/>')
[void]$testConfig.DocumentElement.AppendChild($testConfig.ImportNode($config.configuration.runtime,$true))
$testConfig.Save((Join-Path $BuildDirectory 'BioTimeTests.exe.config'))
& (Join-Path $BuildDirectory 'BioTimeTests.exe')
if($LASTEXITCODE -ne 0){throw 'BioTime tests failed.'}
