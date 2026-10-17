param([switch]$KeepForUI)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$entry=$config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection'
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]$entry.connectionString)
if($builder.DataSource -notin @('localhost','.','(local)')){throw 'This test requires local SQL Server.'}
$database='Codex_InformationPages_Test_'+[Guid]::NewGuid().ToString('N').Substring(0,12)
$folder=Join-Path $root ('tmp/information-brands-test-'+$database.Substring($database.Length-12))
[void][IO.Directory]::CreateDirectory($folder)
$configPath=Join-Path $folder 'Web.config'
$builder['Initial Catalog']='master'
$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$created=$false;$passed=0;$success=$false
function Q([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$reader=$null;try{$dt=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();$dt.Load($reader);return ,$dt}finally{if($reader){$reader.Dispose()};$cmd.Dispose()}}
function N([string]$sql){$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}}
function Check([bool]$ok,[string]$label){if(-not $ok){throw "FAIL: $label"};$script:passed++;"PASS: $label"}
function Deny([string]$sql,[int]$code,[string]$label){try{N $sql}catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq $code){Check $true $label;return};throw};throw "Expected denial: $label"}
try {
 $cn.Open();N "CREATE DATABASE [$database]";$created=$true;$cn.ChangeDatabase($database)
 N @'
CREATE TABLE dbo.Brands(ID int PRIMARY KEY,Title_Ar nvarchar(200),Title_En nvarchar(200),IsActive bit,IsDeleted bit);
INSERT dbo.Brands VALUES(29,N'بروستو',N'Prosto',1,0),(30,N'علامة ثانية',N'Second brand',1,0),(31,N'موقوفة',N'Inactive',0,0),(32,N'محذوفة',N'Deleted',1,1);
CREATE TABLE dbo.UsersMembers(ID int PRIMARY KEY,Type int,Brand_ID int,FullName_Ar nvarchar(500),FullName_En nvarchar(500),IsActive bit,IsDeleted bit);
INSERT dbo.UsersMembers VALUES(1,1,NULL,N'مدير اختبار',N'Admin',1,0),(151,4,29,N'موظف اختبار',N'Employee',1,0),(152,2,29,N'مدير فرع اختبار',N'Manager',1,0),(153,4,30,N'موظف علامة ثانية',N'Second employee',1,0),(154,4,NULL,N'بلا علامة',N'No brand',1,0);
CREATE TABLE dbo.Users_Types(ID int PRIMARY KEY,Title_Ar nvarchar(200),Title_En nvarchar(200),Item_Order int,IsActive bit,IsDeleted bit);
INSERT dbo.Users_Types VALUES(1,N'مدير نظام',N'Admin',1,1,0),(2,N'مدير فرع',N'Manager',2,1,0),(4,N'موظف',N'Employee',4,1,0),(8,N'غير فعال',N'Inactive',8,0,0);
'@
 foreach($file in @('001_Schema.sql','003_Access_Restore_Schema.sql')){
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){N $batch}}
 }
 N @'
INSERT dbo.Information_Pages(Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,VersionNumber,CreatedBy,CreatedUtc,IsPublished)
VALUES(N'صفحة سابقة',N'Legacy',N'Summary',N'Summary',N'<p>Old</p>',N'<p>Old</p>',1,1,SYSUTCDATETIME(),1);
INSERT dbo.Information_Page_Versions(PageID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,IsDeleted,Action,ActorID,ActorName,OccurredUtc)
SELECT ID,VersionNumber,Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,IsDeleted,'create',1,N'Admin',CreatedUtc FROM dbo.Information_Pages;
'@
 N 'CREATE PROCEDURE dbo.MobileApi_InfoPages @Actor int AS SELECT 0 Stub;'
 $builder['Initial Catalog']=$database;$entry.connectionString=$builder.ConnectionString;$config.Save($configPath)
 & (Join-Path $PSScriptRoot 'Apply.ps1') -ConfigPath $configPath
 $r=Q 'SELECT p.VersionNumber,p.AccessRevision,p.Details_En,b.BrandID FROM dbo.Information_Pages p JOIN dbo.Information_Page_Brands b ON b.PageID=p.ID WHERE p.ID=1'
 Check ($r.Rows.Count -eq 1 -and $r.Rows[0].BrandID -eq 29 -and $r.Rows[0].VersionNumber -eq 1 -and $r.Rows[0].Details_En -eq '<p>Old</p>' -and $r.Rows[0].AccessRevision -eq 1) 'Existing page migrated only to Prosto without content/history change'
 $r=Q 'SELECT * FROM dbo.Information_Page_Logs WHERE PageID=1';Check ($r.Rows.Count -eq 1 -and $r.Rows[0].ActorID -eq 0) 'Migration has explicitly attributed system audit'
 & (Join-Path $PSScriptRoot 'Apply.ps1') -ConfigPath $configPath
 $r=Q 'SELECT COUNT(*) C FROM dbo.Information_Page_Logs WHERE PageID=1';Check ($r.Rows[0].C -eq 1) 'Migration is idempotent and does not repeat backfill/audit'
 & (Join-Path $PSScriptRoot 'Test.ps1') -ConfigPath $configPath
 & (Join-Path $PSScriptRoot 'TestAccessRestore.ps1') -ConfigPath $configPath
 $fields="@TitleAr=N'اختبار علامات',@TitleEn=N'Brand test',@SummaryAr=N's',@SummaryEn=N's',@DetailsAr=N'<p>Original</p>',@DetailsEn=N'<p>Original</p>',@Order=1,@Published=1,@Mode='immediate'"
 Deny "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,$fields" 51600 'New pages require explicit brand selection'
 $r=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,$fields,@AllTypes=0,@Roles='<roles><role id=""4""/></roles>',@ExpectedAccessRevision=0,@Brands='<brands><brand id=""29""/><brand id=""30""/><brand id=""30""/></brands>'";$id=[int]$r.Rows[0].ID
 $r=Q "SELECT COUNT(*) C FROM dbo.Information_Page_Brands WHERE PageID=$id";Check ($r.Rows[0].C -eq 2) 'Multiple brands saved with duplicate selections deduplicated'
 foreach($actor in @(151,153)){
  $r=Q "EXEC dbo.Select_Information_Pages @Actor=$actor";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 1) "Brand $actor sees page in menu"
  $r=Q "EXEC dbo.Select_Information_Page @Actor=$actor,@ID=$id";Check ($r.Rows.Count -eq 1) "Brand $actor can open direct link"
  $r=Q "EXEC dbo.MobileApi_InfoPages @Actor=$actor";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 1) "Brand $actor sees mobile content"
 }
 Deny "EXEC dbo.Select_Information_Page @Actor=152,@ID=$id" 51604 'Brand match does not bypass user-type restriction'
 Deny "EXEC dbo.Select_Information_Page @Actor=154,@ID=$id" 51604 'Brandless account cannot open direct link'
 $r=Q "EXEC dbo.Select_Information_Pages @Actor=154";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 0) 'Brandless account has no menu entry'
 $r=Q "EXEC dbo.MobileApi_InfoPages @Actor=154";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 0) 'Brandless account has no mobile entry'
 $r=Q "EXEC dbo.Select_Information_Page @Actor=1,@ID=$id,@Admin=1";Check ($r.Rows.Count -eq 1) 'Admin preview works across brands'
 Deny "EXEC dbo.Select_Information_Page @Actor=1,@ID=$id" 51604 'Ordinary admin viewing does not bypass brand scope'
 Deny "EXEC dbo.Select_Information_Page_Brands @Actor=151,@ID=$id" 51600 'Non-admin cannot load brand management data'
 $access="EXEC dbo.Save_Information_Page_Access @Actor=1,@ID=$id,@ExpectedRevision=1,@AllTypes=0,@Roles='<roles><role id=""4""/></roles>'"
 foreach($bad in @('<brands/>','<brands><brand id="999"/></brands>','<brands><brand id="31"/></brands>','<brands><brand id="32"/></brands>')){Deny "$access,@Brands='$bad'" 51600 "Invalid/inactive/deleted brand selection rejected: $bad"}
 N "$access,@Brands='<brands><brand id=""30""/></brands>'"
 $r=Q "SELECT VersionNumber,AccessRevision FROM dbo.Information_Pages WHERE ID=$id";Check ($r.Rows[0].VersionNumber -eq 1 -and $r.Rows[0].AccessRevision -eq 2) 'Brand-only change updates access revision, not content version'
 Deny "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id,@LogVisit=1" 51604 'Removing a brand immediately blocks direct links'
 $r=Q "EXEC dbo.Select_Information_Pages @Actor=151";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 0) 'Removing a brand immediately removes menu link'
 $r=Q "EXEC dbo.MobileApi_InfoPages @Actor=151";Check (@($r.Rows|Where-Object ID -eq $id).Count -eq 0) 'Removing a brand immediately blocks mobile content'
 $r=Q "SELECT * FROM dbo.Information_Page_Logs WHERE PageID=$id AND Action='view'";Check ($r.Rows.Count -eq 0) 'Denied request does not log a successful view'
 $r=Q "SELECT TOP(1) Details FROM dbo.Information_Page_Logs WHERE PageID=$id AND Action='access' ORDER BY ID DESC";Check ($r.Rows[0].Details.Contains('بروستو') -and $r.Rows[0].Details.Contains('علامة ثانية')) 'Brand audit contains before/after names'
 Deny "$access,@Brands='<brands><brand id=""29""/></brands>'" 51600 'Stale access editor cannot overwrite newer brand mapping'
 Deny "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=1,$($fields.Replace('Original','Changed')),@AllTypes=1,@ExpectedAccessRevision=2,@Brands='<brands/>'" 51600 'Invalid brand rolls back simultaneous content changes'
 $r=Q "SELECT VersionNumber,Details_En FROM dbo.Information_Pages WHERE ID=$id";Check ($r.Rows[0].VersionNumber -eq 1 -and $r.Rows[0].Details_En -eq '<p>Original</p>') 'Combined save is atomic'
 N "EXEC dbo.Save_Information_Page @Actor=1,@ID=$id,@ExpectedVersion=1,$($fields.Replace('Original','Changed'))"
 N "EXEC dbo.Restore_Information_Page @Actor=1,@ID=$id,@SourceVersion=1,@ExpectedVersion=2"
 $r=Q "SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=$id";Check ($r.Rows.Count -eq 1 -and $r.Rows[0].BrandID -eq 30) 'Restoring historical content preserves current brand assignments'
 N 'UPDATE dbo.UsersMembers SET Brand_ID=30 WHERE ID=151'
 $r=Q "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id";Check ($r.Rows.Count -eq 1) 'Current account brand is authoritative without new portal session'
 N 'UPDATE dbo.Brands SET IsActive=0 WHERE ID=30'
 Deny "EXEC dbo.Select_Information_Page @Actor=151,@ID=$id" 51604 'Brand deactivation blocks viewing immediately'
 $r=Q "EXEC dbo.Select_Information_Page_Brands @Actor=1,@ID=$id";Check (@($r.Rows|Where-Object {$_.ID -eq 30 -and $_.IsSelected -and -not $_.IsAvailable}).Count -eq 1) 'Editor retains disabled selected brand for explicit correction'
 N 'UPDATE dbo.Brands SET IsActive=1 WHERE ID=30; UPDATE dbo.UsersMembers SET Brand_ID=29 WHERE ID=151'
 & (Join-Path $PSScriptRoot 'Apply.ps1') -ConfigPath $configPath
 $r=Q "SELECT BrandID FROM dbo.Information_Page_Brands WHERE PageID=$id";Check ($r.Rows.Count -eq 1 -and $r.Rows[0].BrandID -eq 30) 'Reapplying migration does not reset edited brands to Prosto'
 $success=$true;"All $passed brand checks passed, plus existing information-page/access-restore suites."
 if($KeepForUI){[IO.File]::WriteAllText((Join-Path $folder 'database.txt'),$database);"UI fixture config: $configPath"}
} finally {
 if($created -and -not($KeepForUI -and $success)){
  $cn.Dispose();$builder['Initial Catalog']='master';$cn=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$cn.Open();[Data.SqlClient.SqlConnection]::ClearAllPools()
  if($database -notmatch '^Codex_InformationPages_Test_[a-f0-9]{12}$'){throw 'Unsafe cleanup name'}
  N "ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$database]"
  if(Test-Path -LiteralPath $configPath){Remove-Item -LiteralPath $configPath}
 }
 $cn.Dispose()
}
