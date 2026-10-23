# Real Web Forms checks, after the customer guide access fixture in the same disposable host.
$script:testActor=1;$script:target='/Modules/CRM_WorkGuide/ManageCRMWorkGuide.aspx'
function BrandGuidePage { $page=$hostObject.Request($target+'?testActor=1',$null);CheckHtml $page;return $page }
function BrandGuideRow([string]$page,[int]$id,[string]$caption){return Action ([regex]::Match($page,'(?s)<tr><td data-title="الرقم">'+$id+'</td>.*?</tr>').Value) $caption}
function BrandCategoryValues([string]$ar,[string]$en,[string]$parent=''){return @{'categoryBrand'='2';'categoryNameAr'=$ar;'categoryNameEn'=$en;'categoryOrder'='0';'categoryParent'=$parent}}
function BrandGuideValues([string]$brand,[string]$ids){return @{'guideBrand'=$brand;'guideNameAr'='دليل خاص بالعلامة الثانية';'guideNameEn'='Brand two handbook';'guideSummaryAr'='ملخص العلامة الثانية';'guideSummaryEn'='Brand two summary';'guideOrder'='0';'guideActive'='on';'guideCategoryIDs'=$ids}}
$html=BrandGuidePage;$html=Post $html ($prefix+'btnNewGuide')
Assert ($html.IndexOf('id="guideBrand"') -lt $html.IndexOf('id="ContentPlaceHolder1_guideNameAr"') -and [regex]::Match($html,'<select[^>]+id="guideBrand"[^>]*>').Value -notmatch '__doPostBack|onchange') 'Guide brand is first and changes without postback'
$html=Post $html ($prefix+'btnSaveGuide') (BrandGuideValues '' ([string]$accessParent))
Assert ($html -match 'اختر العلامة التجارية أولًا') 'Guide form requires an explicit brand'
$html=BrandGuidePage;$html=Post $html ($prefix+'btnManageCategories')
$html=Post $html ($prefix+'categoryBrand') @{'categoryBrand'='2'}
$html=Post $html ($prefix+'btnSaveCategory') (BrandCategoryValues 'تصنيف مستقل للعلامة الثانية' 'Brand Two Only')
Assert ($html -match 'تم حفظ التصنيف بنجاح') 'A brand-specific root category saves inline'
$brandCategory=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Categories WHERE Brand_ID=2 AND Name_EN='Brand Two Only'").Rows[0].ID
$parentOptions=[regex]::Match($html,'(?s)<select[^>]+id="ContentPlaceHolder1_categoryParent".*?</select>').Value
Assert ($parentOptions -match 'Brand Two Only' -and $parentOptions -notmatch 'Main access|Operations|Safety') 'Parent choices contain only the selected brand tree'
$html=Post $html ($prefix+'btnSaveCategory') (BrandCategoryValues 'فرع العلامة الثانية' 'Brand Two Child' ([string]$brandCategory))
Assert ($html -match 'تم حفظ التصنيف بنجاح') 'A child category is saved within the same brand'
# A five-level tree catches hidden/depth-limited rendering in both editors.
$deepParent=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Categories WHERE Brand_ID=2 AND Name_EN='Brand Two Child'").Rows[0].ID
for($level=3;$level -le 5;$level++){
 $html=Post $html ($prefix+'btnSaveCategory') (BrandCategoryValues ('المستوى '+$level) ('Brand Two Level '+$level) ([string]$deepParent))
 Assert ($html -match 'تم حفظ التصنيف بنجاح') 'Deep category saves with its real parent'
 $deepParent=[int](Q $test.ConnectionString 'SELECT ID FROM CRM_WorkGuide_Categories WHERE Brand_ID=2 AND Name_EN=@name' @{'@name'=('Brand Two Level '+$level)}).Rows[0].ID
}
$treeJson=[regex]::Match($html,'(?s)<script type="application/json" id="crmGuideTreeData">(.*?)</script>').Groups[1].Value
$treeNodes=@(ConvertFrom-Json $treeJson)
Assert (@($treeNodes | Where-Object {-not $_.state.opened}).Count -eq 0 -and $html -match 'Brand Two Level 5') 'Every category depth is supplied and initially expanded'
[IO.File]::WriteAllText((Join-Path $output 'guide-brand-categories.html'),$html,[Text.UTF8Encoding]::new($true))
$html=BrandGuidePage;$html=Post $html ($prefix+'btnNewGuide')
$pdfBrand=[Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n1 0 obj<</Type/Catalog>>endobj`n%%EOF")
$html=Post $html ($prefix+'btnSaveGuide') (BrandGuideValues '2' ([string]$accessParent)) 'brand.pdf' $pdfBrand 'guideUpload'
Assert ($html -match 'أحد التصنيفات غير متاح') 'A forged category from another brand is rejected before saving'
$html=Post $html ($prefix+'btnSaveGuide') (BrandGuideValues '2' ([string]$brandCategory)) 'brand.pdf' $pdfBrand 'guideUpload'
Assert ($html -match 'تم حفظ دليل العمل بنجاح') ('Guide saves with its selected brand and matching classification: '+$hostObject.LastTrace)
$brandItem=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Items WHERE Brand_ID=2 AND Name_EN='Brand two handbook'").Rows[0].ID
$html=Post $html (BrandGuideRow $html $brandItem 'تعديل')
Assert ($html -match '<option selected="selected" value="2">' -and $html -match 'id="guideBrand"') 'Guide editing restores its saved brand'
[IO.File]::WriteAllText((Join-Path $output 'guide-brand-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSaveGuide') (BrandGuideValues '2' ([string]$brandCategory))
Assert ($html -match 'تم حفظ دليل العمل بنجاح') 'Guide edit keeps brand, categories and existing file without navigation'
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='1'}
Assert ($html -notmatch 'data-title="الرقم">'+$brandItem+'</td>') 'Brand filter excludes guides from other brands'
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='2'}
Assert ($html -match 'data-title="الرقم">'+$brandItem+'</td>' -and $html -match 'data-title="العلامة التجارية">علامة ثانية') 'Brand filter and brand table column show the matching guide'
$stats=(Q $test.ConnectionString 'SELECT COUNT(*) Total,SUM(CONVERT(int,Is_Active)) Active FROM CRM_WorkGuide_Items WHERE Is_Deleted=0').Rows[0];CheckCounts $html ([int]$stats.Total) ([int]$stats.Active) ([int]$stats.Total-[int]$stats.Active)
[IO.File]::WriteAllText((Join-Path $output 'guide-brand-list.html'),$html,[Text.UTF8Encoding]::new($true))
$script:target='/Modules/CRM_WorkGuide/Permissions.aspx'
$permissionPage=$hostObject.Request($target+'?account='+$accessAccount+'&testActor=1',$null);CheckHtml $permissionPage
Assert ($permissionPage -notmatch 'Brand Two Only|Brand Two Child' -and $permissionPage -match 'Main access') 'Customer permission editor is scoped to the customer brand'
[void](Q $test.ConnectionString 'UPDATE Customer_Logins SET IsActive=1 WHERE AccountID=@a' @{'@a'=$accessAccount})
$script:target='/CustomerPortal/WorkGuide.aspx';$html=$hostObject.Request($target+'?testCustomer='+$accessAccount,$null);CheckHtml $html
Assert ($html -notmatch 'Brand Two Only|Brand Two Child') 'Customer portal hides foreign-brand category names'
$token=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="customerGuideConfig" data-csrf=\x27([^\x27]+)').Groups[1].Value)
$fileUrl='/CustomerPortal/WorkGuideFile.aspx?id='+$brandItem+'&category='+$brandCategory+'&action=download'
[void]$hostObject.GuideFile($fileUrl,$token);Assert ($hostObject.LastStatus -eq 403) 'Foreign-brand document download forging is denied'
[void](Q $test.ConnectionString 'DELETE CRM_Account_Branches WHERE Account_ID=@a;DELETE CRM_Account_Brands WHERE Account_ID=@a;INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(@a,2,1);UPDATE CRM_Accounts SET Brand_ID=2,Branch_ID=NULL WHERE ID=@a' @{'@a'=$accessAccount})
$html=$hostObject.Request($target,$null);CheckHtml $html
Assert ($html -notmatch 'Main access|Download access') 'Changing customer brand removes previous-brand categories immediately'
$script:target='/Modules/CRM_WorkGuide/Permissions.aspx'
[void]$hostObject.Request($target+'?testActor=1',$null)
$rights=GrantValues $permissionPage $accessAccount @{}
$html=Post $permissionPage ($prefix+'btnSave') $rights
Assert ($html -match 'أحد التصنيفات أو الصلاحيات غير صحيح|تغيرت بيانات العميل') 'Old permission form cannot save categories after the customer brand changes'
$html=$hostObject.Request($target+'?account='+$accessAccount+'&testActor=1',$null);CheckHtml $html
$rights=GrantValues $html $accessAccount @{$brandCategory=3}
$html=Post $html ($prefix+'btnSave') $rights;Assert ($html -match 'تم حفظ صلاحيات دليل العمل') 'Administrator can grant categories in the new customer brand'
$script:target='/CustomerPortal/WorkGuide.aspx';$html=$hostObject.Request($target+'?testCustomer='+$accessAccount,$null);CheckHtml $html
$html=Post $html ($prefix+'btnSearch') @{'category'=[string]$brandCategory}
Assert ($html -match 'Brand two handbook' -and $html -match 'data-guide-action="view"' -and $html -match 'data-guide-action="download"' -and $html -notmatch 'Download access|Main access') 'Customer sees only granted guides belonging to the current brand'
$token=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="customerGuideConfig" data-csrf=\x27([^\x27]+)').Groups[1].Value)
[void]$hostObject.GuideFile($fileUrl,$token);Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastBytes.Length -eq $pdfBrand.Length) 'Matching-brand authorized download succeeds'
[IO.File]::WriteAllText((Join-Path $output 'customer-brand-guide.html'),$html,[Text.UTF8Encoding]::new($true))
$script:target='/Modules/CRM_WorkGuide/ManageCRMWorkGuide.aspx';[void]$hostObject.Request($target+'?testActor=1',$null)
'PASS actual ASP.NET brand-first forms, scoped parents/classifications, forged-brand denial, brand filters/statistics, customer grants, account-brand changes and protected portal files.'
