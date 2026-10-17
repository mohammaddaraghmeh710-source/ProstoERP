param([string]$BuildDirectory='C:/Projects/ERPProsto/tmp/mobile-api-build')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$api=Join-Path $root 'ERP_Prosto/Prosto_ERP_API'
$source=Join-Path $BuildDirectory 'Prosto_ERP_API.dll'
$target=Join-Path $api 'bin/Prosto_ERP_API.dll'
if(!(Test-Path -LiteralPath $source)){throw 'Build API first.'}
$backup=Join-Path $root ('tmp/feedback-api-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
[void](New-Item -ItemType Directory -Path $backup)
foreach($name in @('Prosto_ERP_API.dll','Prosto_ERP_API.pdb')){
 $old=Join-Path $api ('bin/'+$name)
 if(Test-Path -LiteralPath $old){Copy-Item -LiteralPath $old -Destination (Join-Path $backup $name)}
 $built=Join-Path $BuildDirectory $name
 if(Test-Path -LiteralPath $built){Copy-Item -LiteralPath $built -Destination $old -Force}
}
if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Deployed DLL verification failed.'}
'Local API DLL deployed and SHA256 verified. Previous DLL backed up in '+$backup
