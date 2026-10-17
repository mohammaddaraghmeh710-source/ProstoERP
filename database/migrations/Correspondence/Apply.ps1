$ErrorActionPreference = 'Stop'
$config = [xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$connectionString = [string]($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$connection = [Data.SqlClient.SqlConnection]::new($connectionString)
try {
    $connection.Open()
    $transaction = $connection.BeginTransaction()
    try {
        $sql = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_Approved_Fields_And_Relationships.sql'))
        foreach ($batch in [regex]::Split($sql, '(?im)^\s*GO\s*$')) {
            if ([string]::IsNullOrWhiteSpace($batch)) { continue }
            $command = $connection.CreateCommand()
            $command.Transaction = $transaction
            $command.CommandText = $batch
            try { [void]$command.ExecuteNonQuery() } finally { $command.Dispose() }
        }
        $transaction.Commit()
        Write-Output 'Approved correspondence fields, relationships and indexes applied successfully.'
    } catch {
        if ($transaction.Connection) { $transaction.Rollback() }
        throw
    }
} finally { $connection.Dispose() }
