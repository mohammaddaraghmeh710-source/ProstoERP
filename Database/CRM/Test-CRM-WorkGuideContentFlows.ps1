# Uses only the disposable database/application created by Test-CRM-TypePage.ps1.
$script:testActor=1;$script:target='/Modules/CRM_WorkGuide/ManageCRMWorkGuide.aspx'
$seed=Q $test.ConnectionString @'
INSERT CRM_Accounts(Name_AR,AddedUser,Brand_ID) VALUES(N'عميل النصوص المنسقة',1,1);DECLARE @a int=SCOPE_IDENTITY();
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(@a,1,1);
INSERT Customer_Logins(AccountID,Username,PasswordHash,Salt,Iterations,ModifiedBy) VALUES(@a,'content-customer',CRYPT_GEN_RANDOM(32),CRYPT_GEN_RANDOM(32),210000,1);
DECLARE @parent int=NULL,@root int,@level int=1;
WHILE @level<=5 BEGIN
 INSERT CRM_WorkGuide_Categories(Brand_ID,Parent_ID,Name_AR,Name_EN,AddedUser) VALUES(1,@parent,CONCAT(N'تصنيف النصوص المستوى ',@level),CONCAT('Content level ',@level),1);
 SET @parent=CONVERT(int,SCOPE_IDENTITY());IF @level=1 SET @root=@parent;SET @level+=1;
END;
SELECT @a Account_ID,@root Root_ID,@parent Leaf_ID;
'@
$contentAccount=[int]$seed.Rows[0].Account_ID;$contentRoot=[int]$seed.Rows[0].Root_ID;$contentLeaf=[int]$seed.Rows[0].Leaf_ID
$html=BrandGuidePage;$html=Post $html ($prefix+'btnNewGuide')
function ContentValues([string]$ar,[string]$en){return @{'guideBrand'='1';'guideNameAr'='دليل النصوص المنسقة';'guideNameEn'='Rich guide';'guideSummaryAr'='ملخص مستقل';'guideSummaryEn'='Separate summary';'guideOrder'='0';'guideActive'='on';'guideCategoryIDs'=([string]$contentRoot+','+[string]$contentLeaf);'guideDetailsAr'=$ar;'guideDetailsEn'=$en}}
$values=ContentValues '<p>نص بلغة واحدة</p>' ''
$html=Post $html ($prefix+'btnSaveGuide') $values
Assert ($html -match 'أدخل التفاصيل بالعربية والإنجليزية معًا') 'Single-language details fail before any file save'
$ar='<h2>دليل منسق</h2><p dir="rtl">تجربة <strong>عبارة البحث العربية</strong> وتجربة ثانية.</p><script>EVIL_CONTENT_SCRIPT()</script><p><a href="javascript:alert(1)">رابط غير آمن</a></p>'
$en='<h2>Formatted handbook</h2><p>Find <strong>searchable unique phrase</strong> inside this guide.</p><table><tbody><tr><td>Search table</td></tr></tbody></table>'
$values=ContentValues $ar $en
$html=Post $html ($prefix+'btnSaveGuide') $values 'rich.pdf' $pdfBrand 'guideUpload'
Assert ($html -match 'تم حفظ دليل العمل بنجاح') 'Bilingual formatted details save with the inline guide'
$row=(Q $test.ConnectionString "SELECT ID,Details_AR,Details_EN FROM CRM_WorkGuide_Items WHERE Name_EN='Rich guide'").Rows[0];$contentItem=[int]$row.ID
Assert ($row.Details_AR -match '<strong>عبارة البحث العربية</strong>' -and $row.Details_AR -notmatch 'EVIL_CONTENT_SCRIPT|javascript:' -and $row.Details_EN -match '<table>') 'Shared server allowlist preserves formatting and strips active content'
$html=Post $html (BrandGuideRow $html $contentItem 'تعديل')
Assert ($html -match '&lt;strong&gt;عبارة البحث العربية&lt;/strong&gt;' -and $html -match 'crmGuideUpdateEditors') 'Editing restores encoded rich text to both editors'
[IO.File]::WriteAllText((Join-Path $output 'guide-rich-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSaveGuide') (ContentValues '<p>نسخة معدلة <strong>عبارة البحث العربية</strong></p>' $en)
Assert ($html -match 'تم حفظ دليل العمل بنجاح' -and (Q $test.ConnectionString "SELECT COUNT(*) N FROM CRM_Activity_Logs WHERE Entity='WorkGuide_Items' AND Record_ID=@i AND CONVERT(nvarchar(max),Before_Data) LIKE '%Details_AR%' AND CONVERT(nvarchar(max),After_Data) LIKE N'%نسخة معدلة%'" @{'@i'=$contentItem}).Rows[0].N -eq 1) 'Edits retain before/after rich content in the transactional audit'

$script:target='/Modules/CRM_WorkGuide/Permissions.aspx'
$html=$hostObject.Request($target+'?account='+$contentAccount+'&testActor=1',$null);CheckHtml $html
$html=Post $html ($prefix+'btnSave') (GrantValues $html $contentAccount @{$contentRoot=1;$contentLeaf=2})
Assert ($html -match 'تم حفظ صلاحيات دليل العمل') 'Separate tree checkboxes save view and download independently'
$rights=Q $test.ConnectionString 'SELECT Category_ID,Can_View,Can_Download FROM CRM_WorkGuide_Access WHERE Account_ID=@a' @{'@a'=$contentAccount}
Assert ($rights.Rows.Count -eq 2 -and ($rights.Rows|Where-Object Category_ID -eq $contentRoot).Can_View -and -not ($rights.Rows|Where-Object Category_ID -eq $contentRoot).Can_Download -and -not ($rights.Rows|Where-Object Category_ID -eq $contentLeaf).Can_View -and ($rights.Rows|Where-Object Category_ID -eq $contentLeaf).Can_Download) 'Parent/leaf grants never cascade or aggregate'
[IO.File]::WriteAllText((Join-Path $output 'guide-tree-permissions.html'),$html,[Text.UTF8Encoding]::new($true))
$script:target='/CustomerPortal/WorkGuide.aspx';$html=$hostObject.Request($target+'?testCustomer='+$contentAccount,$null);CheckHtml $html
Assert ($html -match 'Content level 1' -and $html -match 'Content level 5' -and $html -match 'تصنيف أب للتوضيح فقط') 'Customer tree preserves ancestor context without granting it'
[IO.File]::WriteAllText((Join-Path $output 'customer-rich-guide.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSearch') @{'filterName'='searchable unique phrase'}
Assert ([regex]::Matches($html,'data-title="الرقم">'+$contentItem+'</td>').Count -eq 1 -and $html -match 'data-guide-details="1"') 'All-category search matches actual formatted text only through a view-enabled category'
$detailPage=$hostObject.Request('/CustomerPortal/WorkGuideDetail.aspx?id='+$contentItem+'&category='+$contentRoot+'&search=searchable+unique+phrase',$null);CheckHtml $detailPage
Assert ($hostObject.LastStatus -eq 200 -and $detailPage -match 'id="guideDetailsPage"' -and $detailPage -match 'guideDetailsEnTab' -and $detailPage -match 'value="searchable unique phrase"' -and $detailPage -match '<strong>searchable unique phrase</strong>' -and $detailPage -notmatch 'id="customerGuideDetails"|EVIL_CONTENT_SCRIPT') 'Dedicated bilingual guide page carries the search and renders sanitized authorized details'
[IO.File]::WriteAllText((Join-Path $output 'customer-guide-detail-page.html'),$detailPage,[Text.UTF8Encoding]::new($true))
[void]$hostObject.Request('/CustomerPortal/WorkGuideDetail.aspx?id='+$contentItem+'&category='+$contentLeaf,$null)
Assert ($hostObject.LastStatus -eq 403) 'Direct guide detail page cannot borrow another category view grant'
$token=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="customerGuideConfig" data-csrf=\x27([^\x27]+)').Groups[1].Value)
$detailsUrl='/CustomerPortal/WorkGuideFile.aspx?id='+$contentItem+'&category='+$contentRoot+'&action=details'
$json=$hostObject.GuideFile($detailsUrl,$token)
Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastContentType -like 'application/json*') 'Own view permission opens details through the protected endpoint'
$detail=ConvertFrom-Json $json
Assert ($detail.detailsAr -match '<strong>عبارة البحث العربية</strong>' -and $detail.detailsEn -match 'searchable unique phrase' -and $json -notmatch 'File_Url|File_Name|EVIL_CONTENT_SCRIPT') 'Details return sanitized bilingual text without document paths'
[IO.File]::WriteAllText((Join-Path $output 'customer-guide-details.json'),$json,[Text.UTF8Encoding]::new($true))
[void]$hostObject.GuideFile('/CustomerPortal/WorkGuideFile.aspx?id='+$contentItem+'&category='+$contentLeaf+'&action=details',$token)
Assert ($hostObject.LastStatus -eq 403) 'Download-only category cannot expose detail text by borrowing parent view permission'
$html=$hostObject.Request($target,$null);$html=Post $html ($prefix+'btnSearch') @{'category'=[string]$contentLeaf;'filterName'='searchable unique phrase'}
$downloadOnlyMatches=[regex]::Matches($html,'<tr\b(?=[^>]*data-guide-id=[''"]'+$contentItem+'[''"])(?=[^>]*data-guide-category=[''"]'+$contentLeaf+'[''"])[^>]*>.*?</tr>','Singleline')
Assert ($downloadOnlyMatches.Count -eq 0) 'Download-only category search cannot infer restricted detail text through another permitted category row'
[void]$hostObject.GuideFile($detailsUrl,'invalid');Assert ($hostObject.LastStatus -eq 403) 'Details enforce CSRF'
[void](Q $test.ConnectionString 'DELETE CRM_WorkGuide_Access WHERE Account_ID=@a AND Category_ID=@c' @{'@a'=$contentAccount;'@c'=$contentRoot})
[void]$hostObject.GuideFile($detailsUrl,$token);Assert ($hostObject.LastStatus -eq 403) 'Revoked details permission is rechecked on each open'
[void]$hostObject.Request('/CustomerPortal/WorkGuideDetail.aspx?id='+$contentItem+'&category='+$contentRoot,$null);Assert ($hostObject.LastStatus -eq 403) 'Dedicated detail links revalidate revoked grants'
$tree=Q $test.ConnectionString 'DECLARE @s uniqueidentifier=(SELECT SecurityStamp FROM Customer_Logins WHERE AccountID=@a);EXEC Customer_WorkGuide_Tree @AccountID=@a,@Stamp=@s' @{'@a'=$contentAccount}
Assert ($tree.Rows.Count -eq 5 -and @($tree.Rows|Where-Object Has_Access).Count -eq 1) 'Unpermitted ancestors remain structural context only'
'PASS real ASP.NET independent tree checkboxes, five-level customer hierarchy, rich-text sanitation/save/edit/audit, all-guide text search, protected bilingual details, CSRF and exact-category revocation.'
