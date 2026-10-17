$ErrorActionPreference = 'Stop'
# Tests insert only synthetic categories/roles/documents inside rolled-back transactions.
# Existing users/brands are read as fixtures; no real grants or requests are committed.
$taskPortal = Join-Path $PSScriptRoot '../../../src/Portal'
$taskConfig = [xml](Get-Content (Join-Path $taskPortal 'Web.config'))
$taskEntry = $taskConfig.configuration.connectionStrings.add | Where-Object { $_.name -eq 'Prosto_ERP_ConnectionConnection' }
$taskConnection = [Data.SqlClient.SqlConnection]::new([string]$taskEntry.connectionString)
$script:taskTransaction = $null
function Query([string]$sql, [hashtable]$parameters = @{}) {
    $command = $taskConnection.CreateCommand()
    $command.Transaction = $script:taskTransaction
    $command.CommandText = $sql
    $command.CommandTimeout = 30
    foreach ($key in $parameters.Keys) { [void]$command.Parameters.AddWithValue($key, $parameters[$key]) }
    $table = [Data.DataTable]::new()
    try { [void]([Data.SqlClient.SqlDataAdapter]::new($command)).Fill($table) } finally { $command.Dispose() }
    return ,$table
}
function Assert([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
function Fixture {
    $script:taskTransaction = $taskConnection.BeginTransaction()
    $result = Query @'
DECLARE @u int,@a int,@b int,@c1 int,@c2 int,@child int,@role int,@doc int;
SELECT TOP(1) @u=ID,@b=Brand_ID FROM UsersMembers WHERE [Type]=7 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Brand_ID IS NOT NULL ORDER BY ID;
SELECT TOP(1) @a=ID FROM UsersMembers WHERE [Type]=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID;
IF @u IS NULL OR @a IS NULL THROW 51990,'Tests need an active external user and administrator.',1;
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,Title_En,IsDeleted,IsActive) VALUES(@b,N'WG test A',N'WG test A',0,1);SET @c1=SCOPE_IDENTITY();
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,Title_En,IsDeleted,IsActive) VALUES(@b,N'WG test B',N'WG test B',0,1);SET @c2=SCOPE_IDENTITY();
INSERT Work_Guide_Categories(Brand_ID,Parent_ID,Title_Ar,IsDeleted,IsActive) VALUES(@b,@c1,N'WG test child',0,1);SET @child=SCOPE_IDENTITY();
INSERT Work_Guide_Roles(Title_Ar,Title_En,Code,IsDeleted,IsActive) VALUES(N'WG test role',N'WG test role',CONVERT(nvarchar(36),NEWID()),0,1);SET @role=SCOPE_IDENTITY();
INSERT Work_Guide_Role_Permissions(Role_ID,Can_View_Category,Can_View_Document,Can_Print_Document,Can_Download_Document) VALUES(@role,1,1,0,1);
INSERT Work_Guide_Documents(Brand_ID,Category_ID,Title_Ar,Is_Download_Allowed,IsDeleted,IsActive,AddedDate) VALUES(@b,@c1,N'WG test document',0,0,1,GETDATE());SET @doc=SCOPE_IDENTITY();
SELECT @u AS U,@a AS A,@b AS B,@c1 AS C1,@c2 AS C2,@child AS Child,@role AS Role,@doc AS Doc;
'@
    return $result.Rows[0]
}
function Rollback {
    if ($script:taskTransaction) {
        try { $script:taskTransaction.Rollback() } catch { }
        $script:taskTransaction.Dispose()
        $script:taskTransaction = $null
    }
}
function Submit($f) {
    return Query 'EXEC dbo.Insert_Work_Guide_Access_Request @User_ID=@u,@Category_IDs=@xml,@Reason=@reason' @{
        '@u'=$f.U; '@xml'="<items><item id='$($f.C1)'/><item id='$($f.C2)'/></items>"; '@reason'='Synthetic workflow verification'
    }
}
function ExpectError([string]$name,[int]$number,[scriptblock]$action) {
    try {
        & $action
        throw "$name did not reject the invalid operation."
    } catch {
        $errorObject=$_.Exception
        while ($errorObject.InnerException) { $errorObject=$errorObject.InnerException }
        if ($errorObject -isnot [Data.SqlClient.SqlException] -or $errorObject.Number -ne $number) { throw }
        Write-Output "PASS: $name"
    } finally { Rollback }
}
try {
    $taskConnection.Open()
    $f=Fixture
    $submitted=Submit $f
    $batch=$submitted.Rows[0].Batch_ID
    $rows=Query 'SELECT ID,Category_ID FROM Work_Guide_Access_Requests WHERE Batch_ID=@batch ORDER BY Category_ID' @{'@batch'=$batch}
    Assert ($rows.Rows.Count -eq 2) 'Two request items expected.'
    $before=Query 'SELECT Can_View_Document FROM dbo.Work_Guide_Effective_Categories(@u,@b) WHERE ID=@c' @{'@u'=$f.U;'@b'=$f.B;'@c'=$f.C1}
    Assert (-not [bool]$before.Rows[0].Can_View_Document) 'Pending request granted access.'
    $decisions="<items><item id='$($rows.Rows[0].ID)' status='A' role='$($f.Role)' note='Approved in test'/><item id='$($rows.Rows[1].ID)' status='R' role='0' note='Rejected in test'/></items>"
    [void](Query 'EXEC dbo.Review_Work_Guide_Access_Request @Admin_ID=@a,@Batch_ID=@batch,@Decisions=@xml' @{'@a'=$f.A;'@batch'=$batch;'@xml'=$decisions})
    $states=Query 'SELECT Status,Assigned_Role_ID,ReviewedBy FROM Work_Guide_Access_Requests WHERE Batch_ID=@batch ORDER BY Category_ID' @{'@batch'=$batch}
    Assert ($states.Rows[0].Status -eq 'A' -and $states.Rows[1].Status -eq 'R') 'Mixed decisions failed.'
    Assert ($states.Rows[0].Assigned_Role_ID -eq $f.Role -and $states.Rows[0].ReviewedBy -eq $f.A) 'Review audit/role incorrect.'
    $access=Query 'SELECT ID,Can_View_Document FROM dbo.Work_Guide_Effective_Categories(@u,@b) WHERE ID IN(@c1,@c2,@child)' @{'@u'=$f.U;'@b'=$f.B;'@c1'=$f.C1;'@c2'=$f.C2;'@child'=$f.Child}
    Assert (@($access.Rows|Where-Object {$_.Can_View_Document}).Count -eq 1) 'Permission leaked to rejected/child categories.'
    $file=Query 'EXEC dbo.Check_Work_Guide_User_Document_Permission @User_ID=@u,@Document_ID=@d' @{'@u'=$f.U;'@d'=$f.Doc}
    Assert ($file.Rows.Count -eq 1 -and -not [bool]$file.Rows[0].Can_Download_Document) 'File-level download restriction ignored.'
    $docs=Query 'EXEC dbo.Select_Work_Guide_View_Authorized_Documents @User_ID=@u,@Brand_ID=@b,@Category_ID=@c' @{'@u'=$f.U;'@b'=$f.B;'@c'=$f.C1}
    Assert ($docs.Rows.Count -eq 1 -and -not [bool]$docs.Rows[0].Can_Download_Document) 'Listing differs from file permission.'
    $history=Query 'EXEC dbo.Select_Work_Guide_Access_Requests @Actor_ID=@u,@Batch_ID=@batch' @{'@u'=$f.U;'@batch'=$batch}
    Assert ($history.Rows.Count -eq 2 -and @($history.Rows|Where-Object {$_.User_ID -ne $f.U}).Count -eq 0) 'History ownership failed.'
    $closed=Query 'EXEC dbo.Select_Work_Guide_Access_Requests @Actor_ID=@u,@Batch_ID=@batch,@Status=''H''' @{'@u'=$f.U;'@batch'=$batch}
    $pending=Query 'EXEC dbo.Select_Work_Guide_Access_Requests @Actor_ID=@u,@Batch_ID=@batch,@Status=''P''' @{'@u'=$f.U;'@batch'=$batch}
    Assert ($closed.Rows.Count -eq 2 -and $pending.Rows.Count -eq 0) 'Previous/pending request separation failed.'
    $tableBatch=[guid]::NewGuid()
    [void](Query 'INSERT Work_Guide_Access_Requests(Batch_ID,User_ID,Brand_ID,Category_ID,Reason,Status,ReviewedBy,ReviewedDate,ReviewNote) SELECT TOP(55) @batch,@u,@b,@c,N''DataTable fixture'',''R'',@a,GETDATE(),N''test'' FROM sys.all_objects' @{'@batch'=$tableBatch;'@u'=$f.U;'@b'=$f.B;'@c'=$f.C1;'@a'=$f.A})
    $allRows=Query 'EXEC Select_Work_Guide_Access_Requests @Actor_ID=@a,@Batch_ID=@batch,@All_Rows=1,@PageSize=1,@PageNumber=99' @{'@a'=$f.A;'@batch'=$tableBatch}
    $pageRows=Query 'EXEC Select_Work_Guide_Access_Requests @Actor_ID=@a,@Batch_ID=@batch,@PageSize=50' @{'@a'=$f.A;'@batch'=$tableBatch}
    Assert ($allRows.Rows.Count -eq 55 -and $pageRows.Rows.Count -eq 50) 'DataTable listing is incomplete or default paging changed.'
    Write-Output 'PASS: all administrator DataTable rows beyond the first page, default paging retained.'
    Write-Output 'PASS: pending isolation, mixed review, exact role, audit, no child grant, download restriction, listing and history.'
    Rollback

    $f=Fixture;[void](Submit $f)
    ExpectError 'Duplicate pending categories' 51104 { [void](Submit $f) }
    $f=Fixture
    ExpectError 'Forged category ID' 51103 { [void](Query 'EXEC Insert_Work_Guide_Access_Request @User_ID=@u,@Category_IDs=@xml,@Reason=N''test''' @{'@u'=$f.U;'@xml'="<items><item id='-1'/></items>"}) }
    $f=Fixture
    ExpectError 'Non-external request actor' 51100 { [void](Query 'EXEC Insert_Work_Guide_Access_Request @User_ID=@u,@Category_IDs=@xml,@Reason=N''test''' @{'@u'=$f.A;'@xml'="<items><item id='$($f.C1)'/></items>"}) }
    $f=Fixture;$batch=(Submit $f).Rows[0].Batch_ID;$row=(Query 'SELECT TOP(1) ID FROM Work_Guide_Access_Requests WHERE Batch_ID=@b' @{'@b'=$batch}).Rows[0]
    $xml="<items><item id='$($row.ID)' status='A' role='$($f.Role)' note='test'/></items>"
    ExpectError 'Non-admin review actor' 51100 { [void](Query 'EXEC Review_Work_Guide_Access_Request @Admin_ID=@a,@Batch_ID=@b,@Decisions=@x' @{'@a'=$f.U;'@b'=$batch;'@x'=$xml}) }
    $f=Fixture;$batch=(Submit $f).Rows[0].Batch_ID;$row=(Query 'SELECT TOP(1) ID FROM Work_Guide_Access_Requests WHERE Batch_ID=@b' @{'@b'=$batch}).Rows[0]
    [void](Query 'UPDATE Work_Guide_Roles SET IsActive=0 WHERE ID=@r' @{'@r'=$f.Role})
    $xml="<items><item id='$($row.ID)' status='A' role='$($f.Role)' note='test'/></items>"
    ExpectError 'Inactive role approval' 51109 { [void](Query 'EXEC Review_Work_Guide_Access_Request @Admin_ID=@a,@Batch_ID=@b,@Decisions=@x' @{'@a'=$f.A;'@b'=$batch;'@x'=$xml}) }
    $f=Fixture;$batch=(Submit $f).Rows[0].Batch_ID;$row=(Query 'SELECT TOP(1) ID FROM Work_Guide_Access_Requests WHERE Batch_ID=@b' @{'@b'=$batch}).Rows[0]
    $xml="<items><item id='$($row.ID)' status='A' role='$($f.Role)' note='test'/></items>"
    [void](Query 'EXEC Review_Work_Guide_Access_Request @Admin_ID=@a,@Batch_ID=@b,@Decisions=@x' @{'@a'=$f.A;'@b'=$batch;'@x'=$xml})
    $remaining=Query 'SELECT Status FROM Work_Guide_Access_Requests WHERE Batch_ID=@b AND ID<>@id' @{'@b'=$batch;'@id'=$row.ID}
    Assert ($remaining.Rows.Count -eq 1 -and $remaining.Rows[0].Status -eq 'P') 'Single-category review changed another request item.'
    Write-Output 'PASS: single-category review preserves pending sibling.'
    ExpectError 'Replay of already reviewed request' 51106 { [void](Query 'EXEC Review_Work_Guide_Access_Request @Admin_ID=@a,@Batch_ID=@b,@Decisions=@x' @{'@a'=$f.A;'@b'=$batch;'@x'=$xml}) }
    Write-Output 'All test data rolled back. Identity counters may advance.'
} finally { Rollback; $taskConnection.Dispose() }
