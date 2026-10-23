# Runs last in the disposable database and actual ASP.NET Web Forms host.
$script:testActor=1;$script:target='/Modules/CRM_WorkGuide/Permissions.aspx'
$storage=Join-Path $stage 'FileManager/CRMWorkGuide';[void][IO.Directory]::CreateDirectory($storage)
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Activity_Logs/ManageCRMActivityLogs.aspx') -Destination (New-Item -Path (Join-Path $stage 'Modules/CRM_Activity_Logs') -ItemType Directory -Force).FullName
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Account_Types/Overview.aspx') -Destination (Join-Path $stage 'Modules/CRM_Account_Types')
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_WorkGuide/Permissions.aspx') -Destination (Join-Path $stage 'Modules/CRM_WorkGuide')
[void](Q $test.ConnectionString 'CREATE OR ALTER PROCEDURE dbo.Fixture_CustomerIdentity @ID int AS SELECT SecurityStamp FROM Customer_Logins WHERE AccountID=@ID;')
$seed=Q $test.ConnectionString @'
INSERT CRM_Accounts(Name_AR,AddedUser,Brand_ID) VALUES(N'عميل اختبار بوابة الأدلة',1,1);DECLARE @Account int=SCOPE_IDENTITY();
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(@Account,1,1);
INSERT Customer_Logins(AccountID,Username,PasswordHash,Salt,Iterations,ModifiedBy) VALUES(@Account,'guide-ui-test',CRYPT_GEN_RANDOM(32),CRYPT_GEN_RANDOM(32),210000,1);
INSERT CRM_WorkGuide_Categories(Name_AR,Name_EN,AddedUser,Brand_ID) VALUES(N'صلاحيات رئيسية','Main access',1,1);DECLARE @Parent int=SCOPE_IDENTITY();
INSERT CRM_WorkGuide_Categories(Parent_ID,Name_AR,Name_EN,AddedUser,Brand_ID) VALUES(@Parent,N'صلاحيات فرعية','Child access',1,1);DECLARE @Child int=SCOPE_IDENTITY();
INSERT CRM_WorkGuide_Categories(Name_AR,Name_EN,AddedUser,Brand_ID) VALUES(N'تحميل فقط للتجربة','Download access',1,1);DECLARE @Download int=SCOPE_IDENTITY();
SELECT @Account Account_ID,@Parent Parent_ID,@Child Child_ID,@Download Download_ID;
'@
$accessAccount=[int]$seed.Rows[0].Account_ID;$accessParent=[int]$seed.Rows[0].Parent_ID;$accessChild=[int]$seed.Rows[0].Child_ID;$accessDownload=[int]$seed.Rows[0].Download_ID
$html=$hostObject.Request($target+'?account='+$accessAccount+'&testActor=1',$null);CheckHtml $html
Assert ($html -match 'صلاحيات التصنيفات' -and $html -match 'id="guidePermissionsTree"' -and $html -match 'crm-guide-permissions.js') 'Administrator category grants use an expanded independent-rights tree'
function GrantValues([string]$page,[int]$account,[hashtable]$grants){
 $result=@{'account'=[string]$account}
 foreach($row in [regex]::Matches($page,'(?s)<span class="guide-grant-options" data-category=[\x27"](\d+)[\x27"]>(.*?)</span></span>')){
  $id=[int]$row.Groups[1].Value;$code=if($grants.ContainsKey($id)){[int]$grants[$id]}else{0}
  foreach($field in @('canView','canDownload')){
   if(($field -eq 'canView' -and ($code -band 1)) -or ($field -eq 'canDownload' -and ($code -band 2))){
    $name=[regex]::Match($row.Value,'name="([^"]+\$'+$field+')"').Groups[1].Value.Replace($prefix,'');Assert ($name -ne '') 'Missing registered checkbox';$result[$name]='on'
   }
  }
 }
 return $result
}
$values=GrantValues $html $accessAccount @{$accessParent=1;$accessDownload=2}
$html=Post $html ($prefix+'btnSave') $values
Assert ($html -match 'تم حفظ صلاحيات دليل العمل' -and $html -notmatch 'alert-danger') 'Category grants save in the same page'
$savedHtml=$html
$html=Post $html ($prefix+'btnSave') $values
Assert ($html -match 'تم حفظ صلاحيات دليل العمل') 'Saved permissions refresh their concurrency version'
$html=Post $savedHtml ($prefix+'btnSave') $values
Assert ($html -match 'تغيرت الصلاحيات') 'Stale permission editors are rejected'
$html=$hostObject.Request($target+'?account='+$accessAccount+'&testActor=1',$null);CheckHtml $html
[IO.File]::WriteAllText((Join-Path $output 'guide-permissions.html'),$html,[Text.UTF8Encoding]::new($true))
$html=$hostObject.Request($target+'?testActor=2',$null);CheckHtml $html
Assert ($html -notmatch 'id="ERPTable"' -and $html -notmatch 'صلاحيات فرعية') 'Account owner cannot read/manage grants'

# A real small DOCX, including correct package types, exercises local conversion.
Add-Type -AssemblyName System.IO.Compression
$stream=[IO.MemoryStream]::new();$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
try{
 $entries=@{'[Content_Types].xml'='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>';'_rels/.rels'='<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="r1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>';'word/document.xml'='<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:pPr><w:bidi/></w:pPr><w:r><w:t>دليل العمل — اختبار العرض داخل بوابة العميل</w:t></w:r></w:p><w:p><w:r><w:t>Customer work guide preview test.</w:t></w:r></w:p></w:body></w:document>'}
 foreach($key in $entries.Keys){$entry=$zip.CreateEntry($key);$writer=[IO.StreamWriter]::new($entry.Open());try{$writer.Write($entries[$key])}finally{$writer.Dispose()}}
}finally{$zip.Dispose()};$word=$stream.ToArray();$stream.Dispose()
$wordName=[guid]::NewGuid().ToString('N')+'.docx';$wordUrl='/FileManager/CRMWorkGuide/'+$wordName
[IO.File]::WriteAllBytes((Join-Path $storage $wordName),$word)
$item=Q $test.ConnectionString @'
INSERT CRM_WorkGuide_Items(Name_AR,Name_EN,Summary_AR,Summary_EN,File_Url,File_Name,File_Extension,File_Size,AddedUser,Brand_ID) VALUES(N'دليل بوابة العميل','Portal access guide',N'ملخص عربي للدليل','English guide summary',@url,N'دليل.docx','.docx',@size,1,1);DECLARE @ID int=SCOPE_IDENTITY();
INSERT CRM_WorkGuide_ItemCategories(Item_ID,Category_ID,Brand_ID) VALUES(@ID,@parent,1),(@ID,@child,1),(@ID,@download,1);SELECT @ID ID;
'@ @{'@url'=$wordUrl;'@size'=$word.Length;'@parent'=$accessParent;'@child'=$accessChild;'@download'=$accessDownload}
$accessItem=[int]$item.Rows[0].ID
$script:target='/CustomerPortal/WorkGuide.aspx'
$html=$hostObject.Request($target+'?testCustomer='+$accessAccount,$null);CheckHtml $html
Assert ($html -match 'Main access' -and $html -match 'Download access' -and $html -notmatch 'Child access') 'Customer category list exposes exact grants only'
$token=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="customerGuideConfig" data-csrf=\x27([^\x27]+)').Groups[1].Value)
Assert ($token.Length -eq 32) 'Viewer CSRF token is bound to the customer session'
$html=Post $html ($prefix+'btnSearch') @{'category'=[string]$accessParent}
$viewOnlyRows=[regex]::Matches($html,'<tr\b[^>]*data-guide-category=[''"]'+$accessParent+'[''"][^>]*>.*?</tr>','Singleline') | ForEach-Object {$_.Value}
$viewOnlyMarkup=$viewOnlyRows -join ''
Assert ($viewOnlyMarkup -match 'دليل بوابة العميل' -and $viewOnlyMarkup -match 'data-guide-details="1"' -and $viewOnlyMarkup -notmatch 'data-guide-action="download"' -and $html -notmatch 'File_Url|SecurityStamp|Child access') 'View-only category rows hide download and ungranted classifications even when other allowed categories are preloaded for local filtering'
[IO.File]::WriteAllText((Join-Path $output 'customer-workguide.html'),$html,[Text.UTF8Encoding]::new($true))
$fileTarget='/CustomerPortal/WorkGuideFile.aspx?id='+$accessItem+'&category='+$accessParent
[void]$hostObject.Request($fileTarget+'&action=view',$null);Assert ($hostObject.LastStatus -eq 405) 'Raw GET cannot open a guide'
[void]$hostObject.GuideFile($fileTarget+'&action=view','wrong');Assert ($hostObject.LastStatus -eq 403) 'Cross-site file requests are rejected'
[void]$hostObject.GuideFile($fileTarget+'&action=download',$token);Assert ($hostObject.LastStatus -eq 403) 'View-only category cannot download even through forged requests'
[void]$hostObject.GuideFile($fileTarget+'&action=view',$token)
Assert ($hostObject.LastStatus -eq 403) 'Viewing Word cannot bypass its original-download permission'
[void](Q $test.ConnectionString 'UPDATE CRM_WorkGuide_Access SET Can_Download=1 WHERE Account_ID=@a AND Category_ID=@c' @{'@a'=$accessAccount;'@c'=$accessParent})
[void]$hostObject.GuideFile($fileTarget+'&action=view',$token)
Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastContentType -like '*wordprocessingml*' -and $hostObject.LastBytes.Length -eq $word.Length) 'Word view returns the original file rather than PDF when download is granted'
[void](Q $test.ConnectionString 'UPDATE CRM_WorkGuide_Access SET Can_Download=0 WHERE Account_ID=@a AND Category_ID=@c' @{'@a'=$accessAccount;'@c'=$accessParent})
$downloadTarget='/CustomerPortal/WorkGuideFile.aspx?id='+$accessItem+'&category='+$accessDownload
[void]$hostObject.GuideFile($downloadTarget+'&action=view',$token);Assert ($hostObject.LastStatus -eq 403) 'Download-only view forging is denied'
[void]$hostObject.GuideFile($downloadTarget+'&action=download',$token);Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastBytes.Length -eq $word.Length) 'Authorized download returns the original Word file'
[void]$hostObject.GuideFile('/CustomerPortal/WorkGuideFile.aspx?id='+$accessItem+'&category='+$accessChild+'&action=view',$token);Assert ($hostObject.LastStatus -eq 403) 'Forged child category has no inherited permission'
[void](Q $test.ConnectionString 'DELETE CRM_WorkGuide_Access WHERE Account_ID=@a AND Category_ID=@c' @{'@a'=$accessAccount;'@c'=$accessParent})
[void]$hostObject.GuideFile($fileTarget+'&action=view',$token);Assert ($hostObject.LastStatus -eq 403) 'Cached preview cannot bypass permission revocation'
[void](Q $test.ConnectionString 'UPDATE Customer_Logins SET IsActive=0 WHERE AccountID=@a' @{'@a'=$accessAccount})
[void]$hostObject.GuideFile($downloadTarget+'&action=download',$token);Assert ($hostObject.LastStatus -eq 401) 'Disabled customer login invalidates file access immediately'
[void]$hostObject.Request('/CustomerPortal/WorkGuide.aspx?testCustomer=0',$null);Assert ($hostObject.LastStatus -eq 302) 'Anonymous portal guide list requires login'
[void]$hostObject.GuideFile($downloadTarget+'&action=download',$token);Assert ($hostObject.LastStatus -eq 401) 'Anonymous customer file access is denied'
$script:target='/Modules/CRM_Account_Types/Overview.aspx'
$html=$hostObject.Request($target+'?testActor=1',$null);CheckHtml $html
Assert ($html -match 'صلاحيات التصنيفات' -and $html -match 'تحميل دليل العمل' -and $html -match 'تحميل دليل العمل') 'Unified activity renders permission snapshots and customer view/download actions'
[IO.File]::WriteAllText((Join-Path $output 'guide-access-activity.html'),$html,[Text.UTF8Encoding]::new($true))
'PASS real ASP.NET category permission management, stale/admin isolation, customer list/action boundaries, Word originals without PDF conversion, protected downloads, CSRF, revocation and unified audit.'
