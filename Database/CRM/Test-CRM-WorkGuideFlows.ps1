# Runs after the existing management flows in the disposable database and ASP.NET host.
$script:target='/Modules/CRM_WorkGuide/ManageCRMWorkGuide.aspx';$script:testActor=1
$guideDirectory=Join-Path $stage 'Modules/CRM_WorkGuide'
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_WorkGuide/File.aspx') -Destination $guideDirectory
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_WorkGuide/web.config') -Destination $guideDirectory
$storage=Join-Path $stage 'FileManager/CRMWorkGuide';[void][IO.Directory]::CreateDirectory($storage)
Copy-Item -LiteralPath (Join-Path $portal 'FileManager/CRMWorkGuide/web.config') -Destination $storage
function GuideFiles {return @(Get-ChildItem -LiteralPath $storage -File|Where-Object Extension -ne '.config').Count}
function CategoryValues([string]$ar,[string]$en,[string]$parent=''){return @{'categoryBrand'='1';'categoryNameAr'=$ar;'categoryNameEn'=$en;'categoryOrder'='2';'categoryParent'=$parent}}
function GuideValues([string]$name,[string]$categories){return @{'guideBrand'='1';'guideNameAr'=$name;'guideNameEn'='Operations Guide';'guideSummaryAr'='ملخص & عربي آمن';'guideSummaryEn'='English summary';'guideOrder'='5';'guideCategoryIDs'=$categories;'guideActive'='on'}}
function GuideAction([string]$html,[int]$id,[string]$title){return (Action ([regex]::Match($html,'(?s)<tr><td data-title="الرقم">'+$id+'</td>.*?</tr>').Value) $title)}
function GuidePage { $script:testActor=1;$page=$hostObject.Request($script:target,$null);CheckHtml $page;return $page }
function NewWord([bool]$macro=$false,[bool]$excel=$false) {
 Add-Type -AssemblyName System.IO.Compression
 $stream=[IO.MemoryStream]::new();$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
 try {
  $entries=@{'[Content_Types].xml'='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="xml" ContentType="application/xml" /></Types>'; '_rels/.rels'='<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="r1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml" /></Relationships>'}
  $entries[$(if($excel){'xl/workbook.xml'}else{'word/document.xml'})]='<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Guide</w:t></w:r></w:p></w:body></w:document>'
  if($macro){$entries['word/vbaProject.bin']='not allowed'}
  foreach($key in $entries.Keys){$entry=$zip.CreateEntry($key);$writer=[IO.StreamWriter]::new($entry.Open());try{$writer.Write($entries[$key])}finally{$writer.Dispose()}}
 }finally{$zip.Dispose()};$bytes=$stream.ToArray();$stream.Dispose();return ,$bytes
}
$pdf=[Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n1 0 obj<</Type/Catalog>>endobj`n%%EOF")
$html=GuidePage;CheckCounts $html 0 0 0
Assert ($html -match 'crmGuideEditor' -and $html -match 'crmCategories' -and $html -match 'jstree.js" defer' -and $html -notmatch 'return confirm\(') 'Work-guide Template/inline/tree components missing.'
$html=Post $html ($prefix+'btnManageCategories');$html=Post $html ($prefix+'categoryBrand') @{'categoryBrand'='1'}
Assert ($html -match "getElementById\('crmCategories'\)") 'Category panel did not open.'
$html=Post $html ($prefix+'btnSaveCategory') (CategoryValues 'تصنيف رئيسي' '')
Assert ($html -match 'أدخل اسم التصنيف بالإنجليزية') 'Category English name is not required.'
$html=Post $html ($prefix+'btnSaveCategory') (CategoryValues 'تصنيف رئيسي' 'Operations')
Assert ($html -match 'تم حفظ التصنيف بنجاح') 'Root category save failed.'
$rootID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Categories WHERE Name_AR=N'تصنيف رئيسي'").Rows[0].ID
$html=Post $html ($prefix+'btnCategoryChild') @{'categorySelected'=[string]$rootID}
$html=Post $html ($prefix+'btnSaveCategory') (CategoryValues 'تصنيف فرعي' 'Procedures' ([string]$rootID))
$childID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Categories WHERE Name_AR=N'تصنيف فرعي'").Rows[0].ID
$html=Post $html ($prefix+'btnCategoryRoot')
$html=Post $html ($prefix+'btnSaveCategory') (CategoryValues 'تصنيف السلامة' 'Safety')
$otherID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_WorkGuide_Categories WHERE Name_AR=N'تصنيف السلامة'").Rows[0].ID
$html=Post $html ($prefix+'btnCategoryEdit') @{'categorySelected'=[string]$childID}
Assert ($html -match 'value="Procedures"' -and $html -match 'تعديل التصنيف') 'Category edit did not load bilingual values.'
[IO.File]::WriteAllText((Join-Path $output 'workguide-categories.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnNewGuide')
Assert ($html -match "getElementById\('crmGuideEditor'\)") 'Guide editor did not open.'
$values=GuideValues 'دليل تشغيل' "$childID,$otherID";$values['guideSummaryEn']=''
$html=Post $html ($prefix+'btnSaveGuide') $values
Assert ($html -match 'أدخل الملخص بالإنجليزية') 'English summary is not required.'
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' "$childID,$otherID")
Assert ($html -match 'أرفق ملف PDF أو Word') 'Create without upload was accepted.'
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' "$childID,$otherID") 'fake.pdf' ([Text.Encoding]::UTF8.GetBytes('<script>fake</script>')) 'guideUpload'
Assert ($html -match 'ملف PDF غير صالح' -and (GuideFiles) -eq 0) 'Fake PDF was persisted.'
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' "$childID,$otherID") 'blocked.exe' $pdf 'guideUpload'
Assert ($html -match 'يسمح بملفات PDF وWord' -and (GuideFiles) -eq 0) 'Unsupported file extension accepted.'
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' "$childID,$otherID") 'oversize.pdf' ([byte[]]::new(10485761)) 'guideUpload'
Assert ($html -match 'لا يتجاوز 10 ميجابايت' -and (GuideFiles) -eq 0) 'Oversized document accepted.'
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' "$childID,$otherID") 'operations.pdf' $pdf 'guideUpload'
Assert ($html -match 'تم حفظ دليل العمل بنجاح' -and (GuideFiles) -eq 1) 'Valid PDF upload/save failed.';CheckCounts $html 1 1 0
$guide=(Q $test.ConnectionString "SELECT ID,File_Url FROM CRM_WorkGuide_Items WHERE Name_AR=N'دليل تشغيل'").Rows[0];$guideID=[int]$guide.ID;$originalUrl=[string]$guide.File_Url
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_WorkGuide_ItemCategories WHERE Item_ID=@id' @{'@id'=$guideID}).Rows[0].N -eq 2) 'Multiple category selections were lost.'
[void]$hostObject.Request('/Modules/CRM_WorkGuide/File.aspx?id='+$guideID,$null)
Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastContentType -like 'application/pdf*' -and $hostObject.LastBytes.Length -eq $pdf.Length) 'Authorized guide download failed.'
[void]$hostObject.Request('/Modules/CRM_WorkGuide/File.aspx?id='+$guideID+'&testActor=2',$null);Assert ($hostObject.LastStatus -eq 403) 'Owner downloaded shared administrative guide.'
[void]$hostObject.Request('/Modules/CRM_WorkGuide/File.aspx?id='+$guideID+'&testActor=0',$null);Assert ($hostObject.LastStatus -eq 401) 'Anonymous guide download accepted.'
$html=GuidePage;$html=Post $html ($prefix+'btnNewGuide')
$wordValues=GuideValues 'دليل السلامة' ([string]$otherID);$wordValues['guideNameEn']='Safety Handbook';$wordValues.Remove('guideActive')
$html=Post $html ($prefix+'btnSaveGuide') $wordValues 'not-word.docx' (NewWord $false $true) 'guideUpload'
Assert ($html -match 'ملف Word غير صالح' -and (GuideFiles) -eq 1) 'Excel renamed DOCX accepted.'
$html=Post $html ($prefix+'btnSaveGuide') $wordValues 'macro.docx' (NewWord $true) 'guideUpload'
Assert ($html -match 'وحدات ماكرو غير مسموحة' -and (GuideFiles) -eq 1) 'Macro-enabled upload accepted.'
$html=Post $html ($prefix+'btnSaveGuide') $wordValues 'safety.docx' (NewWord) 'guideUpload'
Assert ($html -match 'تم حفظ دليل العمل بنجاح' -and (GuideFiles) -eq 2) 'Word upload failed.';CheckCounts $html 2 1 1
[IO.File]::WriteAllText((Join-Path $output 'workguide.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSearch') @{'filterName'='Safety'};Assert ((CountRows $html) -eq 1) 'English guide name filter failed.';CheckCounts $html 2 1 1
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnSearch') @{'filterCategory'=[string]$rootID};Assert ((CountRows $html) -eq 1) 'Category filter did not include descendants.'
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnSearch') @{'filterCategory'=[string]$otherID};Assert ((CountRows $html) -eq 2) 'Multiple category membership filter failed.'
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnSearch') @{'filterStatus'='0'};Assert ((CountRows $html) -eq 1) 'Guide status filter failed.'
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnNewGuide')
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل' ([string]$childID)) 'duplicate.pdf' $pdf 'guideUpload'
Assert ($html -match 'الاسم مستخدم مسبقًا' -and (GuideFiles) -eq 2 -and (CountRows $html) -eq 2) 'Duplicate save leaked a file or row.'
$html=Post $html (GuideAction $html $guideID 'تعديل')
[IO.File]::WriteAllText((Join-Path $output 'workguide-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'دليل تشغيل معدل' ([string]$childID))
Assert ($html -match 'تم حفظ دليل العمل بنجاح') 'Guide edit failed.'
Assert ((Q $test.ConnectionString 'SELECT File_Url FROM CRM_WorkGuide_Items WHERE ID=@id' @{'@id'=$guideID}).Rows[0].File_Url -eq $originalUrl -and (GuideFiles) -eq 2) 'Edit without upload lost/replaced existing file.'
$html=Post $html (GuideAction $html $guideID 'تعديل');[void](Q $test.ConnectionString 'UPDATE CRM_WorkGuide_Items SET Sort_Order=7 WHERE ID=@id' @{'@id'=$guideID})
$html=Post $html ($prefix+'btnSaveGuide') (GuideValues 'محاولة قديمة' ([string]$childID)) 'stale.pdf' $pdf 'guideUpload'
Assert ($html -match 'الدليل تغير أو حُذف' -and $html -match 'value="محاولة قديمة"' -and (GuideFiles) -eq 2) 'Stale edit overwrote data/leaked a file/lost input.'
$html=Post $html (GuideAction $html $guideID 'إيقاف');CheckCounts $html 2 0 2
$html=Post $html (GuideAction $html $guideID 'تفعيل');CheckCounts $html 2 1 1
$html=Post $html ($prefix+'btnManageCategories');$html=Post $html ($prefix+'categoryBrand') @{'categoryBrand'='1'};$html=Post $html ($prefix+'btnCategoryEdit') @{'categorySelected'=[string]$childID}
$html=Post $html ($prefix+'btnSaveCategory') (CategoryValues 'تصنيف فرعي معدل' 'Edited Procedures' ([string]$otherID))
Assert ($html -match 'تم حفظ التصنيف بنجاح') 'Category reparent/edit failed.'
$html=Post $html ($prefix+'btnSearch') @{'filterCategory'=[string]$rootID};Assert ((CountRows $html) -eq 0) 'Reparented category remained in old parent filter.'
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnManageCategories');$html=Post $html ($prefix+'categoryBrand') @{'categoryBrand'='1'};$html=Post $html ($prefix+'btnCategoryDelete') @{'categorySelected'=[string]$childID}
Assert ($html -match "getElementById\('crmCategoryDeleteModal'\)") 'Category delete modal missing.'
$html=Post $html ($prefix+'btnConfirmCategoryDelete');Assert ($html -match 'تصنيف مرتبط بأدلة') 'Linked category deletion was not blocked.'
$html=Post $html (GuideAction $html $guideID 'حذف')
Assert ($html -match "getElementById\('crmGuideDeleteModal'\)") 'Guide delete modal missing.'
[IO.File]::WriteAllText((Join-Path $output 'workguide-delete.html'),$html,[Text.UTF8Encoding]::new($true))
[void](Q $test.ConnectionString 'UPDATE CRM_WorkGuide_Items SET Sort_Order=9 WHERE ID=@id' @{'@id'=$guideID})
$html=Post $html ($prefix+'btnConfirmGuideDelete');Assert ($html -match 'السجل تغير أو حُذف' -and (CountRows $html) -eq 2) 'Stale guide delete accepted.'
$html=Post $html (GuideAction $html $guideID 'حذف');$html=Post $html ($prefix+'btnConfirmGuideDelete');CheckCounts $html 1 0 1
$html=Post $html ($prefix+'btnConfirmGuideDelete');Assert ($html -match 'اختر الدليل المراد حذفه أولًا') 'Guide deletion could be replayed.'
[void]$hostObject.Request('/Modules/CRM_WorkGuide/File.aspx?id='+$guideID,$null);Assert ($hostObject.LastStatus -eq 404 -and (GuideFiles) -eq 2) 'Deleted guide still downloads or retained files were lost.'
$html=GuidePage;$html=Post $html ($prefix+'btnManageCategories');$html=Post $html ($prefix+'categoryBrand') @{'categoryBrand'='1'};$html=Post $html ($prefix+'btnCategoryDelete') @{'categorySelected'=[string]$childID};$html=Post $html ($prefix+'btnConfirmCategoryDelete')
Assert ($html -match 'تم حذف التصنيف بنجاح') 'Unused leaf category deletion failed.'
$html=$hostObject.Request($target+'?testActor=2',$null);CheckHtml $html;Assert ($html -match 'مدير النظام فقط' -and $html -notmatch 'id="crmGuideEditor"') 'Owner reached work-guide administration.'
'PASS actual ASP.NET category tree CRUD/reparenting, bilingual forms, multi-category/descendant filters, PDF/Word uploads, cleanup, downloads, counts, status, optimistic edits/deletes, modal replay and administrator scope.'
