$ErrorActionPreference = 'Stop'
$cfg = [xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config') -Raw)
$cn = New-Object System.Data.SqlClient.SqlConnection($cfg.configuration.connectionStrings.add.connectionString)
$cn.Open()
$tx = $cn.BeginTransaction([System.Data.IsolationLevel]::Serializable)
try {
    $cmd = $cn.CreateCommand()
    $cmd.Transaction = $tx
    $cmd.CommandText = @'
SELECT ID,FullName_Ar,Type,Shif_ID,ModifyDate FROM dbo.UsersMembers WITH (UPDLOCK,HOLDLOCK)
WHERE Branch_ID=25 AND ISNULL(IsDeleted,0)=0 ORDER BY ID;
SELECT ID,Start_Time,End_Time,Start_Time_Ramadan,End_Time_Ramadan,ModifyDate
FROM dbo.Shift WITH (UPDLOCK,HOLDLOCK) WHERE ID IN (1,2,3);
'@
    $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $ds = New-Object System.Data.DataSet 'BeforeTrial'
    [void]$da.Fill($ds)
    $backup = Join-Path $PSScriptRoot ('before-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.xml')
    $ds.WriteXml($backup, [System.Data.XmlWriteMode]::WriteSchema)
    $cmd.CommandText = @'
SET XACT_ABORT ON;
IF (SELECT COUNT(*) FROM dbo.UsersMembers WHERE Branch_ID=25 AND ISNULL(IsDeleted,0)=0)<>36
    THROW 50001,'Unexpected branch employee count',1;
IF (SELECT COUNT(*) FROM dbo.UsersMembers WHERE Branch_ID=25 AND ID BETWEEN 147 AND 182
    AND Type=4 AND Shif_ID IS NULL AND IsActive=1 AND ISNULL(IsDeleted,0)=0)<>36
    THROW 50002,'Employee state changed; review before applying',1;
IF (SELECT COUNT(*) FROM dbo.Shift WHERE ID IN (1,2,3) AND IsActive=1 AND ISNULL(IsDeleted,0)=0)<>3
    THROW 50003,'Expected three active shifts',1;
UPDATE dbo.UsersMembers
SET Type=CASE WHEN ID=147 THEN 2 WHEN ID BETWEEN 148 AND 150 THEN 3 ELSE 4 END,
    Shif_ID=CASE WHEN ID=147 THEN NULL WHEN ID BETWEEN 148 AND 150 THEN ID-147 ELSE ((ID-151)%3)+1 END,
    ModifyDate=GETDATE()
WHERE Branch_ID=25 AND ID BETWEEN 147 AND 182 AND ISNULL(IsDeleted,0)=0;
IF @@ROWCOUNT<>36 THROW 50004,'Employee update count mismatch',1;
UPDATE dbo.Shift
SET Start_Time=CASE ID WHEN 1 THEN '08:00' WHEN 2 THEN '16:00' ELSE '00:00' END,
    End_Time=CASE ID WHEN 1 THEN '16:00' WHEN 2 THEN '00:00' ELSE '08:00' END,
    Start_Time_Ramadan=CASE ID WHEN 1 THEN '08:00' WHEN 2 THEN '16:00' ELSE '00:00' END,
    End_Time_Ramadan=CASE ID WHEN 1 THEN '16:00' WHEN 2 THEN '00:00' ELSE '08:00' END,
    ModifyDate=GETDATE()
WHERE ID IN (1,2,3);
IF @@ROWCOUNT<>3 THROW 50005,'Shift update count mismatch',1;
IF (SELECT COUNT(*) FROM dbo.UsersMembers WHERE Branch_ID=25 AND Type=2 AND Shif_ID IS NULL AND ISNULL(IsDeleted,0)=0)<>1
    THROW 50006,'Branch manager verification failed',1;
IF EXISTS (SELECT Shif_ID FROM dbo.UsersMembers WHERE Branch_ID=25 AND ISNULL(IsDeleted,0)=0 AND Shif_ID IS NOT NULL
    GROUP BY Shif_ID HAVING SUM(CASE WHEN Type=3 THEN 1 ELSE 0 END)<>1
    OR COUNT(*)<>CASE WHEN Shif_ID IN (1,2) THEN 12 ELSE 11 END)
    THROW 50007,'Shift allocation verification failed',1;
'@
    [void]$cmd.ExecuteNonQuery()
    $tx.Commit()
    Write-Output "Committed. Previous values saved: $backup"
} catch {
    try { $tx.Rollback() } catch { }
    throw
} finally {
    $cn.Close()
}
