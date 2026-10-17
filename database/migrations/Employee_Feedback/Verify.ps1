$ErrorActionPreference = 'Stop'
$config = [xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$connectionString = [string]($config.configuration.connectionStrings.add | Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$connection = [Data.SqlClient.SqlConnection]::new($connectionString)
$passed = 0
try {
    $connection.Open()
    $transaction = $connection.BeginTransaction()
    function Run-Sql([string]$sql) {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        $command.CommandText = $sql
        try { return $command.ExecuteScalar() } finally { $command.Dispose() }
    }
    function Expect-Rejected([string]$label, [string]$sql, [int[]]$numbers = @(547)) {
        try { [void](Run-Sql $sql) }
        catch {
            $exception = $_.Exception
            while ($exception.InnerException) { $exception = $exception.InnerException }
            if ($exception -is [Data.SqlClient.SqlException] -and $numbers -contains $exception.Number) {
                Write-Output "PASS: $label"
                $script:passed++
                return
            }
            throw
        }
        throw "Expected database rejection: $label"
    }
    try {
        [void](Run-Sql 'SET XACT_ABORT OFF;')
        $brand = Run-Sql 'SELECT TOP (1) ID FROM dbo.Brands ORDER BY ID'
        $user = Run-Sql 'SELECT TOP (1) ID FROM dbo.UsersMembers ORDER BY ID'
        $other = Run-Sql "SELECT TOP (1) ID FROM dbo.UsersMembers WHERE ID<>$user ORDER BY ID"
        if ($null -eq $brand -or $null -eq $user -or $null -eq $other) { throw 'Test requires a brand and two existing users.' }
        $topic = Run-Sql "INSERT dbo.Employee_Feedback_Topics(Type,Brand_ID,Title_Ar,Title_En,AddedUser) VALUES(1,$brand,N'اختبار مؤقت',N'Rollback test',$user); SELECT CAST(SCOPE_IDENTITY() AS int);"
        $requestSql = "INSERT dbo.Employee_Feedback_Requests(EmployeeID,Type,Topic_ID,Brand_ID,Topic_Title_Ar,Topic_Title_En,Title,Details,DiscloseIdentity,RequestedRecipientType) VALUES($user,1,$topic,$brand,N'Test',N'Test',N'Test',N'Details',0,3); SELECT CAST(SCOPE_IDENTITY() AS int);"
        $request = Run-Sql $requestSql
        $otherRequest = Run-Sql $requestSql
        $group = [guid]::NewGuid().ToString()
        $flow = Run-Sql "INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID) VALUES($request,$user,$other,N'Submission',1,'$group'); SELECT CAST(SCOPE_IDENTITY() AS int);"
        [void](Run-Sql "INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID) VALUES($request,$user,$user,N'Submission',1,'$group');")
        Expect-Rejected 'Duplicate receiver in one operation' "INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID) VALUES($request,$user,$other,N'Submission',1,'$group');" @(2601,2627)
        Expect-Rejected 'Mandatory explanation' "INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID) VALUES($request,$user,$other,CHAR(9)+CHAR(10),2,NEWID());"
        Expect-Rejected 'Unknown operation' "INSERT dbo.Employee_Feedback_Workflow(Request_ID,SenderID,ReceiverID,Comment,ActionType,GroupID) VALUES($request,$user,$other,N'Test',4,NEWID());"
        Expect-Rejected 'Cross-request attachment' "INSERT dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,FileName,OriginalFileName,File_Type,FileSize) VALUES($otherRequest,$flow,N'cross.pdf',N'cross.pdf','pdf',10);"
        Expect-Rejected 'Cross-request notification' "INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType) VALUES($other,$otherRequest,$flow,2);"
        Expect-Rejected '10 MiB limit' "INSERT dbo.Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize) VALUES($request,N'large.pdf',N'large.pdf','pdf',10485761);"
        [void](Run-Sql "INSERT dbo.Employee_Feedback_Attachments(Request_ID,Workflow_ID,FileName,OriginalFileName,File_Type,FileSize) VALUES($request,NULL,N'original.pdf',N'original.pdf','pdf',10),($request,$flow,N'workflow.pdf',N'workflow.pdf','pdf',10); INSERT dbo.Employee_Feedback_Notifications(UserID,Request_ID,Action_ID,NotificationType) VALUES($other,$request,NULL,1);")
        Write-Output 'PASS: employee link, multiple recipients, request and workflow attachments, notification'
        $passed++
    } finally { $transaction.Rollback() }
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) FROM sys.tables WHERE name LIKE 'Employee[_]Feedback[_]%'; SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id IN (SELECT object_id FROM sys.tables WHERE name LIKE 'Employee[_]Feedback[_]%') AND (is_disabled=1 OR is_not_trusted=1);"
    $reader = $command.ExecuteReader()
    [void]$reader.Read()
    if ($reader.GetInt32(0) -ne 5) { throw 'Expected five tables.' }
    [void]$reader.NextResult(); [void]$reader.Read()
    if ($reader.GetInt32(0) -ne 0) { throw 'Untrusted or disabled foreign keys.' }
    $reader.Close(); $command.Dispose()
    Write-Output "$passed checks passed; five tables verified; all test records rolled back."
} finally { $connection.Dispose() }
