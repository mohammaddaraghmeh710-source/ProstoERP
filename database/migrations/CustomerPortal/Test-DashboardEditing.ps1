# Runs inside Test-Dashboard.ps1 against its disposable database and real ASP.NET host.
$prefix='ctl00$ContentPlaceHolder1$'
function PostDashboard([string]$html,[string]$target,[hashtable]$values=@{},[string]$filename='',[byte[]]$bytes=$null) {
 $form=@{'__EVENTTARGET'=$target}
 foreach($input in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')){$name=[regex]::Match($input.Value,'name="([^"]+)"').Groups[1].Value;$value=[regex]::Match($input.Value,'value="([^"]*)"').Groups[1].Value;if($name){$form[$name]=[Web.HttpUtility]::HtmlDecode($value)}}
 $form['__EVENTTARGET']=$target
 foreach($key in $values.Keys){$form[$prefix+$key]=$values[$key]}
 $body=($form.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode($_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
 $result=if($filename){$hostObject.Upload('/CustomerPortal/Dashboard.aspx',$body,$filename,$bytes)}else{$hostObject.Request('/CustomerPortal/Dashboard.aspx',$body)}
 if($result -match 'Server Error|Exception Details|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'error.html'),$result,[Text.UTF8Encoding]::new($true));throw 'Dashboard POST failed; see saved error.html.'}
 if($hostObject.Status -ne 200 -and $target -ne 'ctl00$btnLogout'){throw ('Dashboard POST unexpectedly redirected: '+$hostObject.Location)}
 return $result
}
function ContactAction([string]$html,[string]$name,[string]$label) {
 $card=($html -split '<div class="col-xl-6">'|Where-Object {$_ -match ('<h6 class="mb-1">'+[regex]::Escape([Web.HttpUtility]::HtmlEncode($name))+'</h6>')})|Select-Object -First 1
 $anchor=[regex]::Match($card,'<a(?=[^>]*aria-label="'+[regex]::Escape($label)+'")[^>]*>').Value
 $target=[regex]::Match([Web.HttpUtility]::HtmlDecode($anchor),"__doPostBack\('([^']+)'",
 [Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
 if(-not $target){throw 'Contact action not found: '+$label};return $target
}
function ProfileValues([string]$name){return @{'p_Name_AR'=$name;'p_Name_EN'='Customer Self Service';'p_Phone'='0795555555';'p_Email'='self@example.invalid';'p_Address'='عنوان تجريبي';'p_Country'='الأردن';'p_Website'='https://example.invalid';'p_Registration_Number'=''}}
function ContactValues([string]$name,[string]$english='Portal Contact'){return @{'c_Name_AR'=$name;'c_Name_EN'=$english;'c_Job_Title'='مدير';'c_Job_Title_EN'='Manager';'c_Phone'='0796666666';'c_Email'='portal@example.invalid';'c_Gender'='M';'c_IsActive'='on'}}
$html=Page '/CustomerPortal/Dashboard.aspx'
$html=PostDashboard $html ($prefix+'btnEditProfile')
Assert ($html -match "getElementById\('profileEditor'\)" -and $html -match 'id="ContentPlaceHolder1_p_Name_EN"' -and $html -notmatch 'id="(?:ContentPlaceHolder1_)?(?:p_Owner_ID|p_Is_Active|txtPassword)"') 'Profile uses same-page offcanvas with permitted fields only'
Assert ($html -match '<div class="col-12"><label[^>]*for="ContentPlaceHolder1_p_Address"') 'Profile address occupies a separate full-width row'
[IO.File]::WriteAllText((Join-Path $output 'profile-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=PostDashboard $html ($prefix+'btnSaveProfile') (ProfileValues '')
Assert ($html -match 'أدخل اسم العميل بالعربية') 'Profile required validation stays in the editor'
Sql "IF (SELECT Name_AR FROM CRM_Accounts WHERE ID=1)<>N'عميل الاختبار' THROW 51999,'Invalid form wrote profile',1;"
$html=PostDashboard $html ($prefix+'btnSaveProfile') (ProfileValues 'عميل الاختبار المعدل') 'fake.png' ([Text.Encoding]::UTF8.GetBytes('<script>invalid image</script>'))
Assert ($html -match 'ليس صورة صالحة') 'Dashboard rejects fake logo image content'
Add-Type -AssemblyName System.Drawing
$bitmap=[Drawing.Bitmap]::new(48,32);$stream=[IO.MemoryStream]::new();$graphics=[Drawing.Graphics]::FromImage($bitmap)
try{$graphics.Clear([Drawing.Color]::CornflowerBlue);$bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$logo=$stream.ToArray()}finally{$graphics.Dispose();$bitmap.Dispose();$stream.Dispose()}
$html=PostDashboard $html ($prefix+'btnSaveProfile') (ProfileValues 'عميل الاختبار المعدل') 'customer.png' $logo
Assert ($html -match 'تم حفظ بياناتك بنجاح' -and $html -match 'مرحبًا بك، عميل الاختبار المعدل') 'Profile saves name/contact data and logo without navigation'
Sql "IF NOT EXISTS(SELECT 1 FROM CRM_Accounts WHERE ID=1 AND Name_AR=N'عميل الاختبار المعدل' AND Logo_Url LIKE '/FileManager/CustomerLogos/%.png' AND Owner_ID=1 AND Is_Active=1) THROW 51999,'Inline profile/organization protection failed',1;"
Assert ((Get-ChildItem -LiteralPath (Join-Path $stage 'FileManager/CustomerLogos') -Filter '*.png').Count -eq 1) 'Validated portal logo is saved as a FileManager file'
[void](Page '/CustomerPortal/Logo.aspx?id=2');Assert ($hostObject.Status -eq 200 -and $hostObject.ContentType -like 'image/png*' -and $hostObject.Bytes.Length -gt 8) 'Own inline logo is streamed after upload'
$html=PostDashboard $html ($prefix+'btnEditProfile');Sql "UPDATE CRM_Accounts SET Phone='concurrent' WHERE ID=1"
$html=PostDashboard $html ($prefix+'btnSaveProfile') (ProfileValues 'محاولة قديمة')
Assert ($html -match 'أعد فتح النموذج' -and $html -match 'value="محاولة قديمة"') 'Stale profile is rejected and retains entered values'
Sql "IF NOT EXISTS(SELECT 1 FROM CRM_Accounts WHERE ID=1 AND Phone='concurrent') THROW 51999,'Concurrent change overwritten',1;"
$html=PostDashboard $html ($prefix+'btnNewContact')
Assert ($html -match "getElementById\('contactEditor'\)" -and $html -match 'الاسم بالإنجليزية') 'New contact opens the shared-style offcanvas'
[IO.File]::WriteAllText((Join-Path $output 'contact-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=PostDashboard $html ($prefix+'btnSaveContact') (ContactValues 'جهة لوحة تجريبية' '')
Assert ($html -match 'أدخل الاسم بالإنجليزية') 'Contact English name is required by the server form'
$missingJob=ContactValues 'جهة لوحة تجريبية';$missingJob['c_Job_Title_EN']=''
$html=PostDashboard $html ($prefix+'btnSaveContact') $missingJob
Assert ($html -match 'أدخل المسمى الوظيفي بالإنجليزية') 'English job title is required in the portal editor'
$html=PostDashboard $html ($prefix+'btnSaveContact') (ContactValues 'جهة لوحة تجريبية')
Assert ($html -match 'تم حفظ جهة الاتصال بنجاح' -and $html -match 'Portal Contact' -and $html -match 'Manager') 'Bilingual contact is created in the same dashboard'
Sql "IF NOT EXISTS(SELECT 1 FROM CRM_Contacts WHERE Account_ID=1 AND Name_AR=N'جهة لوحة تجريبية' AND Name_EN=N'Portal Contact' AND AddedUser IS NULL) THROW 51999,'Contact creation/provenance failed',1;"
$html=PostDashboard $html (ContactAction $html 'جهة لوحة تجريبية' 'تعديل جهة الاتصال')
Sql "UPDATE CRM_Contacts SET Phone='concurrent' WHERE Account_ID=1 AND Name_AR=N'جهة لوحة تجريبية'"
$html=PostDashboard $html ($prefix+'btnSaveContact') (ContactValues 'جهة لوحة معدلة' 'Edited Contact')
Assert ($html -match 'تم تعديلها' -and $html -match 'value="Edited Contact"') 'Stale contact updates are rejected with form retention'
$html=PostDashboard $html (ContactAction $html 'جهة لوحة تجريبية' 'تعديل جهة الاتصال')
$html=PostDashboard $html ($prefix+'btnSaveContact') (ContactValues 'جهة لوحة معدلة' 'Edited Contact')
Assert ($html -match 'تم حفظ جهة الاتصال بنجاح' -and $html -match 'جهة لوحة معدلة') 'Contact editing refreshes its dashboard card'
$html=PostDashboard $html (ContactAction $html 'جهة لوحة معدلة' 'حذف جهة الاتصال')
Assert ($html -match "getElementById\('contactDeleteModal'\)") 'Contact deletion opens a Bootstrap confirmation modal'
Sql "IF NOT EXISTS(SELECT 1 FROM CRM_Contacts WHERE Name_AR=N'جهة لوحة معدلة' AND Is_Deleted=0) THROW 51999,'Deleted before confirmation',1;"
[IO.File]::WriteAllText((Join-Path $output 'delete-modal.html'),$html,[Text.UTF8Encoding]::new($true))
$html=PostDashboard $html ($prefix+'btnDeleteContact')
Assert ($html -match 'تم حذف جهة الاتصال بنجاح') 'Modal confirmation soft-deletes the contact'
$html=PostDashboard $html ($prefix+'btnDeleteContact')
Assert ($html -match 'اختر جهة الاتصال المراد حذفها أولًا') 'Delete confirmation cannot be replayed'
Sql "IF EXISTS(SELECT 1 FROM CRM_Contacts WHERE Name_AR=N'جهة لوحة معدلة' AND Is_Deleted=0) THROW 51999,'Contact deletion failed',1;IF (SELECT COUNT(*) FROM Customer_Portal_Activity WHERE AccountID=1 AND Action IN('profile-update','contact-create','contact-update','contact-delete'))<>4 THROW 51999,'Dashboard successful mutation audit incomplete',1;"
[IO.File]::WriteAllText((Join-Path $output 'dashboard-edited.html'),$html,[Text.UTF8Encoding]::new($true))
'PASS: Real ASP.NET self-service form lifecycle, multipart image validation, versioned CRUD and atomic customer audit.'
