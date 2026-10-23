# Extract the signed LibreOffice runtime privately; this does not install the desktop application.
param([string]$InstallerPath)
$ErrorActionPreference='Stop'
if(-not $InstallerPath){throw 'Supply the official Windows x64 LibreOffice MSI path (-InstallerPath).'}
$installer=(Resolve-Path -LiteralPath $InstallerPath).Path
if([IO.Path]::GetExtension($installer) -ne '.msi'){throw 'An official MSI installer is required.'}
$signature=Get-AuthenticodeSignature -LiteralPath $installer
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'The Document Foundation'){throw 'Installer signature/publisher verification failed.'}
$portal=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../src/Portal'))
$target=Join-Path $portal 'App_Data/Tools/LibreOffice'
[void][IO.Directory]::CreateDirectory($target)
$log=Join-Path ([IO.Path]::GetTempPath()) ('CRM-GuideConverter-'+[guid]::NewGuid().ToString('N')+'.log')
$job=Start-Process -FilePath msiexec.exe -ArgumentList @('/a',('"'+$installer+'"'),'/qn',('TARGETDIR="'+$target+'"'),'/L*v',('"'+$log+'"')) -WindowStyle Hidden -Wait -PassThru
if($job.ExitCode -ne 0){throw "Private converter extraction failed ($($job.ExitCode)). See $log"}
$exe=Join-Path $target 'program/soffice.exe'
if(-not (Test-Path -LiteralPath $exe)){throw 'Converter executable was not extracted.'}
Write-Output "Word preview runtime ready: $exe"
