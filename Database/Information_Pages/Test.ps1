param([string]$ConfigPath=(Join-Path $PSScriptRoot '../../Portal/Web.config'))
$ErrorActionPreference='Stop'
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cs=[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$cn=[Data.SqlClient.SqlConnection]::new($cs);$cn.Open()
$ids=[Collections.Generic.List[int]]::new();$passed=0
function Q([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{$dt=[Data.DataTable]::new();$dt.Load($cmd.ExecuteReader());return ,$dt}finally{$cmd.Dispose()}}
function N([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}
function Check([bool]$condition,[string]$label){if(-not $condition){throw $label};$script:passed++;Write-Output "PASS: $label"}
function Deny([string]$sql,[int]$code,[string]$label){try{N $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq $code){Check $true $label;return};throw};throw "Expected denial: $label"}
try {
 $admin=Q 'SELECT TOP(1) ID FROM dbo.UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID'
 $employee=Q 'SELECT TOP(1) ID FROM dbo.UsersMembers WHERE Type<>1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID'
 if($admin.Rows.Count -ne 1 -or $employee.Rows.Count -ne 1){throw 'Active admin and employee required for tests'}
 $a=[int]$admin.Rows[0].ID;$u=[int]$employee.Rows[0].ID
 $brand=Q "SELECT b.ID FROM dbo.UsersMembers u JOIN dbo.Brands b ON b.ID=u.Brand_ID WHERE u.ID=$u AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0"
 if($brand.Rows.Count -ne 1){throw 'Test employee must have an active brand'}
 $brandId=[int]$brand.Rows[0].ID
 $fields="@TitleAr=N'IP temporary verification',@TitleEn=N'IP temporary verification',@SummaryAr=N'Summary',@SummaryEn=N'Summary',@DetailsAr=N'<p>Arabic details</p>',@DetailsEn=N'<p>English details</p>',@Order=9"
 $t=Q "EXEC dbo.Save_Information_Page @Actor=$a,@ID=0,@ExpectedVersion=0,$fields,@Published=0,@Mode='immediate',@AllTypes=1,@ExpectedAccessRevision=0,@Brands='<brands><brand id=""$brandId""/></brands>'"
 $id=[int]$t.Rows[0].ID;$ids.Add($id)
 Check ($t.Rows[0].VersionNumber -eq 1) 'Creation starts version 1'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=$u";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 0) 'Draft hidden from employee list'
 Deny "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id,@LogVisit=1" 51604 'Direct draft link denied'
 Deny "EXEC dbo.Select_Information_Pages @Actor=$u,@Manage=1" 51600 'Employee cannot open management data'
 Deny "EXEC dbo.Save_Information_Page @Actor=$u,@ID=$id,@ExpectedVersion=1,$fields,@Published=1,@Mode='immediate'" 51600 'Employee cannot save'
 Deny "EXEC dbo.Select_Information_Page_Logs @Actor=$u,@ID=$id" 51600 'Employee cannot read logs'
 Deny "EXEC dbo.Select_Information_Page_History @Actor=$u,@ID=$id" 51600 'Employee cannot read versions'
 Deny "EXEC dbo.Select_Information_Page @Actor=0,@ID=$id" 51600 'Unauthenticated actor denied'
 Deny "EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=1,$fields,@Published=1,@Mode='scheduled'" 51600 'Scheduled publication requires both dates'
 Deny "EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=1,$fields,@Published=1,@Mode='scheduled',@StartUtc='2030-01-02',@EndUtc='2030-01-01'" 51600 'End must follow start'
 N "EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=1,$fields,@Published=1,@Mode='immediate'"
 $t=Q "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id,@LogVisit=1,@Language='en'"
 Check ($t.Rows[0].VersionNumber -eq 2 -and $t.Rows[0].Details_En -eq '<p>English details</p>') 'Immediate publication and bilingual content available'
 $t=Q "SELECT l.* FROM dbo.Information_Page_Logs l WHERE PageID=$id AND Action='view'"
 Check ($t.Rows.Count -eq 1 -and $t.Rows[0].ActorID -eq $u -and $t.Rows[0].VersionNumber -eq 2 -and $t.Rows[0].ActorName.Length -gt 0 -and $t.Rows[0].Language -eq 'en') 'Visit records employee name, ID, timestamp, version and language'
 Deny "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id,@Version=1" 51600 'Employee cannot request historical content'
 Deny "EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=1,$fields,@Published=1,@Mode='immediate'" 51600 'Stale edit rejected'
 $t=Q "SELECT COUNT(*) C FROM dbo.Information_Page_Versions WHERE PageID=$id";Check ($t.Rows[0].C -eq 2) 'Failed edits do not create versions'
 N "DECLARE @s datetime2=DATEADD(day,1,SYSUTCDATETIME()),@e datetime2=DATEADD(day,2,SYSUTCDATETIME()); EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=2,$fields,@Published=1,@Mode='scheduled',@StartUtc=@s,@EndUtc=@e"
 Deny "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id" 51604 'Future scheduled page inaccessible'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=$a,@Manage=1";Check ((@($t.Rows|Where-Object ID -eq $id)[0]).DisplayStatus -eq 'scheduled') 'Admin sees scheduled status'
 N "DECLARE @s datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@e datetime2=DATEADD(day,1,SYSUTCDATETIME()); EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=3,$fields,@Published=1,@Mode='scheduled',@StartUtc=@s,@EndUtc=@e"
 $t=Q "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id,@LogVisit=1";Check ($t.Rows[0].VersionNumber -eq 4) 'Page visible inside schedule'
 N "DECLARE @s datetime2=DATEADD(day,-1,SYSUTCDATETIME()),@e datetime2=SYSUTCDATETIME(); EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=4,$fields,@Published=1,@Mode='scheduled',@StartUtc=@s,@EndUtc=@e"
 Deny "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id" 51604 'End time is exclusive; expired page inaccessible'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=$u";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 0) 'Expired page disappears from list'
 $t=Q "EXEC dbo.Select_Information_Page @Actor=$a,@ID=$id,@Admin=1,@LogVisit=1";Check ($t.Rows[0].VersionNumber -eq 5) 'Admin can preview expired page'
 Deny "EXEC dbo.Delete_Information_Page @Actor=$u,@ID=$id,@ExpectedVersion=5" 51600 'Employee cannot delete'
 Deny "EXEC dbo.Delete_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=4" 51600 'Stale deletion rejected'
 N "EXEC dbo.Delete_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=5"
 $t=Q "SELECT * FROM dbo.Information_Pages WHERE ID=$id";Check ($t.Rows.Count -eq 1 -and $t.Rows[0].IsDeleted -and $t.Rows[0].DeletedBy -eq $a -and $t.Rows[0].DeletedUtc -ne [DBNull]::Value) 'Soft deletion retains content and actor/date'
 Deny "EXEC dbo.Select_Information_Page @Actor=$u,@ID=$id" 51604 'Deleted page direct link denied'
 $t=Q "EXEC dbo.Select_Information_Page_History @Actor=$a,@ID=$id";Check ($t.Rows.Count -eq 6 -and $t.Rows[0].Action -eq 'delete') 'History survives deletion with deletion revision'
 $t=Q "EXEC dbo.Select_Information_Page @Actor=$a,@ID=$id,@Admin=1,@Version=1";Check ($t.Rows[0].IsPublished -eq $false) 'Original draft revision remains immutable'
 $t=Q "EXEC dbo.Select_Information_Page_Logs @Actor=$a,@ID=$id";Check (@($t.Rows|Where-Object Action -ne 'access').Count -eq 9 -and @($t.Rows|Where-Object Action -eq 'access').Count -eq 1) 'Content operations and initial brand access all audited'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=$a,@Manage=1,@Deleted=1";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 1) 'Admin deleted archive retains access'
 Deny "EXEC dbo.Save_Information_Page @Actor=$a,@ID=$id,@ExpectedVersion=6,$fields,@Published=1,@Mode='immediate'" 51600 'Deleted page cannot be edited'
 "All $passed database checks passed."
} finally {
 foreach($id in $ids){N "DELETE dbo.Information_Page_Brands WHERE PageID=$id; DELETE dbo.Information_Page_Roles WHERE PageID=$id; DELETE dbo.Information_Page_Logs WHERE PageID=$id; DELETE dbo.Information_Page_Versions WHERE PageID=$id; DELETE dbo.Information_Pages WHERE ID=$id;"}
 $cn.Dispose()
}
