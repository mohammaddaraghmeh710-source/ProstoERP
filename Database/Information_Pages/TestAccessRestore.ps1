param([Parameter(Mandatory=$true)][string]$ConfigPath)
$ErrorActionPreference='Stop'
$config=[xml](Get-Content -LiteralPath $ConfigPath)
$cs=[string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($cs)
if($builder.InitialCatalog -notmatch '^Codex_InformationPages_Test_[0-9a-f]{12}$'){throw 'This test requires the disposable isolated test database and synthetic accounts 1, 151, 152.'}
$cn=[Data.SqlClient.SqlConnection]::new($cs);$cn.Open();$passed=0
function Q([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{$dt=[Data.DataTable]::new();$dt.Load($cmd.ExecuteReader());return ,$dt}finally{$cmd.Dispose()}}
function N([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}
function Check([bool]$ok,[string]$label){if(-not $ok){throw $label};$script:passed++;"PASS: $label"}
function Deny([string]$sql,[int]$code,[string]$label){try{N $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq $code){Check $true $label;return};throw};throw "Expected denial: $label"}
try {
 $fields="@TitleAr=N'صلاحيات واسترجاع',@TitleEn=N'Access and restore',@SummaryAr=N'Summary',@SummaryEn=N'Summary',@DetailsAr=N'<p>Original</p>',@DetailsEn=N'<p>Original</p>',@Order=1,@Published=1,@Mode='immediate'"
 $t=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,$fields,@AllTypes=0,@Roles='<roles><role id=""4""/></roles>',@ExpectedAccessRevision=0,@Brands='<brands><brand id=""29""/></brands>'";$id=[int]$t.Rows[0].ID
 $t=Q "SELECT AllUserTypes,AccessRevision,VersionNumber FROM dbo.Information_Pages WHERE ID=$id"
 Check (-not $t.Rows[0].AllUserTypes -and $t.Rows[0].AccessRevision -eq 1 -and $t.Rows[0].VersionNumber -eq 1) 'New restricted page is saved atomically'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=151";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 1) 'Selected employee type sees menu entry'
 $t=Q "EXEC dbo.Select_Information_Pages @Actor=152";Check (@($t.Rows|Where-Object ID -eq $id).Count -eq 0) 'Unselected manager type cannot see menu entry'
 Deny "EXEC dbo.Select_Information_Page @Actor=152,@ID=$id,@LogVisit=1" 51604 'Unselected type cannot use copied direct link'
 $t=Q "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id,@LogVisit=1";Check ($t.Rows[0].VersionNumber -eq 1) 'Selected employee can read details'
 $t=Q "EXEC dbo.Select_Information_Page @Actor=1,@ID=$id,@Admin=1";Check ($t.Rows.Count -eq 1) 'Administrator retains preview'
 Deny "EXEC dbo.Save_Information_Page_Access @Actor=151,@ID=$id,@ExpectedRevision=1,@AllTypes=1,@Roles='<roles/>'" 51600 'Employee cannot change access'
 Deny "EXEC dbo.Select_Information_Page_Roles @Actor=151,@ID=$id" 51600 'Employee cannot read access editor data'
 Deny "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=1,@AllTypes=0,@Roles='<roles/>'" 51600 'Empty selection rejected'
 Deny "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=1,@AllTypes=0,@Roles='<roles><role id=""999""/></roles>'" 51600 'Unknown role rejected'
 Deny "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=1,@AllTypes=0,@Roles='<roles><role id=""8""/></roles>'" 51600 'Inactive role rejected'
 $t=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=1,$fields,@AllTypes=0,@Roles='<roles><role id=""2""/></roles>',@ExpectedAccessRevision=1"
 Check ($t.Rows[0].VersionNumber -eq 1) 'Permissions-only save does not create content revision'
 $t=Q "SELECT COUNT(*) C FROM dbo.Information_Page_Versions WHERE PageID=$id";Check ($t.Rows[0].C -eq 1) 'Version history contains no permission snapshots'
 $t=Q "SELECT Details,ActorName FROM dbo.Information_Page_Logs WHERE PageID=$id AND Action='access' ORDER BY ID DESC"
 Check ($t.Rows.Count -eq 2 -and $t.Rows[0].Details.Contains('موظف') -and $t.Rows[0].Details.Contains('مدير فرع') -and $t.Rows[0].ActorName.Length -gt 0) 'Permission audit records before/after role names and administrator'
 Deny "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id" 51604 'Revoked employee access stops immediately'
 $t=Q "EXEC dbo.Select_Information_Page @Actor=152,@ID=$id";Check ($t.Rows.Count -eq 1) 'Newly selected type gains access'
 Deny "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=1,@AllTypes=1,@Roles='<roles/>'" 51600 'Stale access changes rejected independently'
 N "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=2,@AllTypes=0,@Roles='<roles><role id=""2""/></roles>'"
 $t=Q "SELECT AccessRevision FROM dbo.Information_Pages WHERE ID=$id";Check ($t.Rows[0].AccessRevision -eq 2) 'Unchanged access does not add revision or audit'
 $changed=$fields.Replace("<p>Original</p>","<p>Changed</p>").Replace('@Order=1','@Order=5')
 N "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=1,$changed"
 Deny "EXEC dbo.Restore_Information_Page @Actor=151,@ID=$id,@SourceVersion=1,@ExpectedVersion=2" 51600 'Employee cannot restore'
 Deny "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$id,@SourceVersion=1,@ExpectedVersion=1" 51600 'Stale restore rejected'
 Deny "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$id,@SourceVersion=2,@ExpectedVersion=2" 51600 'Restoring current version rejected'
 N "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$id,@SourceVersion=1,@ExpectedVersion=2"
 $t=Q "SELECT * FROM dbo.Information_Pages WHERE ID=$id";Check ($t.Rows[0].VersionNumber -eq 3 -and $t.Rows[0].Details_Ar -eq '<p>Original</p>' -and $t.Rows[0].Details_En -eq '<p>Original</p>' -and $t.Rows[0].Item_Order -eq 1) 'Restore creates new version with old bilingual content and order'
 Check (-not $t.Rows[0].AllUserTypes -and $t.Rows[0].AccessRevision -eq 2) 'Restore does not touch current permission settings'
 $t=Q "SELECT UserTypeID FROM dbo.Information_Page_Roles WHERE PageID=$id";Check ($t.Rows.Count -eq 1 -and $t.Rows[0].UserTypeID -eq 2) 'Restore retains current role selection, not original roles'
 $t=Q "SELECT RestoredFromVersion FROM dbo.Information_Page_Versions WHERE PageID=$id AND VersionNumber=3";Check ($t.Rows[0].RestoredFromVersion -eq 1) 'Source revision recorded on restored version'
 $t=Q "SELECT Details FROM dbo.Information_Page_Logs WHERE PageID=$id AND Action='restore'";Check ($t.Rows.Count -eq 1 -and $t.Rows[0].Details.Contains('1')) 'Restore audit retains source version'
 $t=Q "SELECT Details_En FROM dbo.Information_Page_Versions WHERE PageID=$id AND VersionNumber=2";Check ($t.Rows[0].Details_En -eq '<p>Changed</p>') 'Overwritten revision remains immutable'
 # Failure of access validation must roll back simultaneous content changes.
 Deny "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=3,$changed,@AllTypes=0,@Roles='<roles/>',@ExpectedAccessRevision=2" 51600 'Combined save rejects invalid permissions'
 $t=Q "SELECT VersionNumber,Details_En FROM dbo.Information_Pages WHERE ID=$id";Check ($t.Rows[0].VersionNumber -eq 3 -and $t.Rows[0].Details_En -eq '<p>Original</p>') 'Failed combined save rolls back content and version'
 N "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=2,@AllTypes=1,@Roles='<roles/>'"
 $t=Q "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id";Check ($t.Rows.Count -eq 1) 'All-user mode restores access to every type'
 # Restore an expired schedule after immediate publication; do not extend its dates.
 $scheduled=$fields.Replace("@Mode='immediate'","@Mode='scheduled'")
 $t=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,$scheduled,@StartUtc='2020-01-01',@EndUtc='2020-01-02',@AllTypes=1,@ExpectedAccessRevision=0,@Brands='<brands><brand id=""29""/></brands>'";$expired=[int]$t.Rows[0].ID
 N "EXEC dbo.Save_Information_Page @Actor=1,@ID=$expired,@ExpectedVersion=1,$fields"
 N "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$expired,@SourceVersion=1,@ExpectedVersion=2"
 Deny "EXEC dbo.Select_Information_Page @Actor=151,@ID=$expired" 51604 'Restored expired schedule stays hidden'
 N "EXEC dbo.Delete_Information_Page @Actor=1,@ID=$expired,@ExpectedVersion=3"
 Deny "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$expired,@SourceVersion=1,@ExpectedVersion=4" 51600 'Restore cannot silently undelete a page'
 # Case-sensitive content changes must create a version even under CI database collation.
 $caseChanged=$fields.Replace('<p>Original</p>','<p>original</p>')
 $t=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=3,$caseChanged";Check ($t.Rows[0].VersionNumber -eq 4) 'Case-only content changes are not ignored'
 N "EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=3,@AllTypes=0,@Roles='<roles><role id=""2""/><role id=""4""/></roles>'"
 $employee=Q "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id";$manager=Q "EXEC dbo.Select_Information_Page @Actor=152,@ID=$id"
 Check ($employee.Rows.Count -eq 1 -and $manager.Rows.Count -eq 1) 'Multiple selected types can both read the page'
 $t=Q "SELECT VersionNumber FROM dbo.Information_Pages WHERE ID=$id";Check ($t.Rows[0].VersionNumber -eq 4) 'Multi-type access save still does not create content revision'
 "All $passed access/restore checks passed in the isolated database."
}finally{$cn.Dispose()}
