$ErrorActionPreference = 'Stop'
$taskConfig = [xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$taskEntry = $taskConfig.configuration.connectionStrings.add | Where-Object { $_.name -eq 'Prosto_ERP_ConnectionConnection' }
$taskConnection = [Data.SqlClient.SqlConnection]::new([string]$taskEntry.connectionString)
$taskTransaction = $null
function Query([string]$sql, [hashtable]$parameters = @{}) {
    $command = $taskConnection.CreateCommand()
    $command.Transaction = $taskTransaction
    $command.CommandText = $sql
    foreach ($key in $parameters.Keys) { [void]$command.Parameters.AddWithValue($key, $parameters[$key]) }
    $table = [Data.DataTable]::new()
    try { [void]([Data.SqlClient.SqlDataAdapter]::new($command)).Fill($table) } finally { $command.Dispose() }
    return ,$table
}
function Assert([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
function Reject([string]$sql,[hashtable]$parameters,[int]$number) {
    try { [void](Query $sql $parameters); throw 'Expected rejection missing' }
    catch {
        $errorObject=$_.Exception
        while ($errorObject.InnerException) { $errorObject=$errorObject.InnerException }
        if ($errorObject -isnot [Data.SqlClient.SqlException] -or $errorObject.Number -ne $number) { throw }
    }
}
try {
    $taskConnection.Open()
    $taskTransaction=$taskConnection.BeginTransaction()
    $f=(Query @'
DECLARE @u int,@a int,@b int,@c int,@d int;
SELECT TOP(1) @u=ID,@b=Brand_ID FROM UsersMembers WHERE [Type]=7 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Brand_ID IS NOT NULL ORDER BY ID;
SELECT TOP(1) @a=ID FROM UsersMembers WHERE [Type]=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID;
IF @a IS NULL OR @u IS NULL THROW 51990,'Fixtures unavailable',1;
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,IsActive,IsDeleted) VALUES(@b,N'WG log test category',1,0); SET @c=SCOPE_IDENTITY();
INSERT Work_Guide_Documents(Brand_ID,Category_ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(@b,@c,N'WG log test document',N'WG log English document',1,0); SET @d=SCOPE_IDENTITY();
INSERT Work_Guide_Activity_Logs(User_ID,Brand_ID,Category_ID,Document_ID,Action_Type,AddedDate)
VALUES(@u,@b,@c,@d,N'1','20991229 23:59:59'),(@u,@b,@c,@d,N'1','20991230 00:00:00'),
      (@u,@b,@c,@d,N'2','20991230 23:59:59.997'),(@u,@b,@c,@d,N'2','20991231 00:00:00');
INSERT Work_Guide_Activity_Logs(User_ID,Brand_ID,Category_ID,Document_ID,Action_Type,AddedDate)
VALUES(@u,@b,@c,@d,N'AccessRequestReview','20991230 12:00:00');
SELECT @u AS U,@a AS A,@c AS C,@d AS D;
'@).Rows[0]
    $base='EXEC dbo.Select_Work_Guide_Activity_Logs_Admin @Admin_ID=@a,@Category_ID=@c,@Date_From=''20991230'',@Date_To=''20991230'''
    $params=@{'@a'=$f.A;'@c'=$f.C}
    $rows=Query $base $params
    Assert ($rows.Rows.Count -eq 2 -and $rows.Rows[0].TotalRows -eq 2) 'Inclusive end date/start boundary failed'
    $first=Query ($base+',@PageNumber=1,@PageSize=1') $params
    $second=Query ($base+',@PageNumber=2,@PageSize=1') $params
    Assert ($first.Rows.Count -eq 1 -and $second.Rows.Count -eq 1 -and $first.Rows[0].ID -ne $second.Rows[0].ID -and $first.Rows[0].TotalRows -eq 2) 'Paging failed'
    $named=Query ($base+',@Document_Name=N''English document''') $params
    Assert ($named.Rows.Count -eq 2) 'Document name filter failed'
    $absent=Query ($base+',@Document_Name=N''nonexistent-unique-document-51990''') $params
    Assert ($absent.Rows.Count -eq 0) 'Document filter ignored'
    $absent=Query ($base+',@User_Name=N''nonexistent-unique-user-51990''') $params
    Assert ($absent.Rows.Count -eq 0) 'User filter ignored'
    $user=(Query 'SELECT FullName_Ar FROM UsersMembers WHERE ID=@u' @{'@u'=$f.U}).Rows[0].FullName_Ar
    $withUser=@{'@a'=$f.A;'@c'=$f.C;'@name'=$user}
    Assert ((Query ($base+',@User_Name=@name') $withUser).Rows.Count -eq 2) 'User match failed'
    $categories=Query 'EXEC dbo.Select_Work_Guide_Log_Categories @Admin_ID=@a' @{'@a'=$f.A}
    Assert (@($categories.Rows | Where-Object {$_.ID -eq $f.C}).Count -eq 1) 'Category filter options missing'
    [void](Query 'INSERT Work_Guide_Activity_Logs(User_ID,Category_ID,Document_ID,Action_Type,AddedDate) SELECT TOP(55) @u,@c,@d,N''1'',''20991230 15:00:00'' FROM sys.all_objects' @{'@u'=$f.U;'@c'=$f.C;'@d'=$f.D})
    $export=Query ($base+',@Export_All=1,@PageNumber=99,@PageSize=1') $params
    $page=Query ($base+',@PageNumber=1,@PageSize=50') $params
    Assert ($export.Rows.Count -eq 57 -and $page.Rows.Count -eq 50 -and $page.Rows[0].TotalRows -eq 57) 'Export must include every matching row beyond the current page.'
    Assert (@($export.Rows | Where-Object {$_.Action_Type -notin @('1','2')}).Count -eq 0) 'Other activity types leaked into export.'
    Assert ((Query ($base+',@Export_All=1,@Document_Name=N''nonexistent-unique-document-51990''') $params).Rows.Count -eq 0) 'Export ignored search filters.'
    Reject 'EXEC dbo.Select_Work_Guide_Activity_Logs_Admin @Admin_ID=@u' @{'@u'=$f.U} 51100
    Reject 'EXEC dbo.Select_Work_Guide_Activity_Logs_Admin @Admin_ID=@u,@Export_All=1' @{'@u'=$f.U} 51100
    Reject 'EXEC dbo.Select_Work_Guide_Log_Categories @Admin_ID=@u' @{'@u'=$f.U} 51100
    Reject 'EXEC dbo.Select_Work_Guide_Activity_Logs_Admin @Admin_ID=@a,@Date_From=''20991231'',@Date_To=''20991230''' @{'@a'=$f.A} 51101
    'PASS: filters, inclusive dates, stable paging, view/download only, complete filtered export, non-admin denial (including export), invalid date range.'
} finally {
    if ($taskTransaction) { $taskTransaction.Rollback(); $taskTransaction.Dispose() }
    $taskConnection.Dispose()
    'Synthetic activity log fixtures rolled back.'
}
