$ErrorActionPreference = 'Stop'
$config = [xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$connectionString = [string]($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$connection = [Data.SqlClient.SqlConnection]::new($connectionString)
$folder = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../src/Portal/App_Data/EmployeeFeedback'))
[void][IO.Directory]::CreateDirectory($folder)
$created = [Collections.Generic.List[string]]::new()
$committed = $false
try {
    Add-Type -AssemblyName System.Drawing
    foreach ($kind in @('Submission','Transfer')) {
        $file = [guid]::NewGuid().ToString('N') + '.png'
        $path = Join-Path $folder $file
        $bitmap = [Drawing.Bitmap]::new(800,240)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $font = [Drawing.Font]::new('Arial',20)
        try {
            $graphics.Clear([Drawing.Color]::White)
            $graphics.DrawString("DEMO ONLY - $kind attachment",$font,[Drawing.Brushes]::Navy,30,40)
            $graphics.DrawString('Employee Feedback / Branch 25',$font,[Drawing.Brushes]::Black,30,100)
            $graphics.DrawString('Synthetic test data - no personal information',$font,[Drawing.Brushes]::Gray,30,160)
            $bitmap.Save($path,[Drawing.Imaging.ImageFormat]::Png)
            $created.Add($path)
        } finally { $font.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }
    }
    $connection.Open()
    $transaction = $connection.BeginTransaction([Data.IsolationLevel]::Serializable)
    try {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        $command.CommandText = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '003_Demo_Branch25.sql'))
        [void]$command.Parameters.AddWithValue('@SubmissionFile',[IO.Path]::GetFileName($created[0]))
        [void]$command.Parameters.AddWithValue('@SubmissionSize',[long](Get-Item -LiteralPath $created[0]).Length)
        [void]$command.Parameters.AddWithValue('@TransferFile',[IO.Path]::GetFileName($created[1]))
        [void]$command.Parameters.AddWithValue('@TransferSize',[long](Get-Item -LiteralPath $created[1]).Length)
        try { [void]$command.ExecuteNonQuery() } finally { $command.Dispose() }
        $transaction.Commit()
        $committed = $true
        Write-Output 'Committed branch 25 demo: 6 topics, 9 requests, workflow, internal notifications and 2 PNG attachments.'
    } catch {
        if ($transaction.Connection) { $transaction.Rollback() }
        throw
    }
} finally {
    $connection.Dispose()
    if (-not $committed) {
        foreach ($path in $created) { Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue }
    }
}
