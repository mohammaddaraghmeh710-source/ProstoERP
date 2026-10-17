$ErrorActionPreference='Stop'
$portal=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../src/Portal'))
$build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../tmp/feedback-build'))
$backup=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../tmp/feedback-deploy-backup'))
[void][IO.Directory]::CreateDirectory($backup)
foreach($name in @('CRM.dll','Prosto_ERP_ClassLibrary.dll')){
 $source=Join-Path $build $name;$destination=Join-Path $portal "bin/$name"
 if(-not (Test-Path -LiteralPath $source)){throw "Missing compiled file: $name"}
 $old=Join-Path $backup $name
 if(-not (Test-Path -LiteralPath $old)){Copy-Item -LiteralPath $destination -Destination $old}
 Copy-Item -LiteralPath $source -Destination $destination -Force
 if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash){throw "Binary verification failed: $name"}
}
'Local Portal binaries updated; backup retained; file hashes verified.'
