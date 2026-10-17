$ErrorActionPreference = 'Stop'
$config = [xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$connectionString = [string]($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$connection = [Data.SqlClient.SqlConnection]::new($connectionString)
try {
    $connection.Open()
    $transaction = $connection.BeginTransaction()
    try {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        $command.CommandText = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '001_Schema.sql'))
        try { [void]$command.ExecuteNonQuery() } finally { $command.Dispose() }
        $transaction.Commit()
        Write-Output 'Stage 1: eight employee feedback tables, relationships and indexes created.'
    } catch {
        if ($transaction.Connection) { $transaction.Rollback() }
        throw
    }
} finally { $connection.Dispose() }
