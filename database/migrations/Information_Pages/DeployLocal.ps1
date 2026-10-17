$ErrorActionPreference='Stop'
$portal=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../src/Portal'))
$build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../tmp/information-build'))
$backup=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot ('../../../../tmp/information-backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))))
[void][IO.Directory]::CreateDirectory($backup)
$name='CRM.dll'
$source=Join-Path $build $name
$target=Join-Path $portal "bin/$name"
if(-not (Test-Path -LiteralPath $source)){throw 'Build Portal first.'}
Copy-Item -LiteralPath $target -Destination (Join-Path $backup $name)
Copy-Item -LiteralPath $source -Destination $target -Force
if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Binary verification failed.'}
"Local Portal binary updated and verified. Backup: $backup"
