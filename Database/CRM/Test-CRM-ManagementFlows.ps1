# Invoked by Test-CRM-TypePage.ps1 -IncludeManagement inside its disposable database/ASP.NET host.
[void](Q $test.ConnectionString @'
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,UserName,Type,IsActive,IsDeleted) VALUES(3,N'مسؤول آخر','other-owner',4,1,0);SET IDENTITY_INSERT UsersMembers OFF;
IF NOT EXISTS(SELECT 1 FROM Brands WHERE ID=1) BEGIN SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'علامة أولى',1,0),(2,N'علامة ثانية',1,0);SET IDENTITY_INSERT Brands OFF; END;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,Title_Ar,BrandID,IsActive,IsDeleted) VALUES(1,N'فرع أول',1,1,0),(2,N'فرع ثان',2,1,0);SET IDENTITY_INSERT Branches OFF;
UPDATE CRM_Accounts SET Brand_ID=1,Branch_ID=1 WHERE ID=1;
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(1,1,1);
INSERT CRM_Account_Branches(Account_ID,Brand_ID,Branch_ID,AddedUser) VALUES(1,1,1,1);
INSERT CRM_Accounts(Name_AR,Name_EN,Owner_ID,Brand_ID,AddedUser) VALUES(N'عميل مسؤول آخر',N'Other customer',3,2,1);
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) VALUES(CONVERT(int,SCOPE_IDENTITY()),2,1);
INSERT CRM_Contacts(Account_ID,Name_AR,Job_Title,Email,Is_Active,AddedUser) VALUES(1,N'جهة أولى',N'مدير','first@example.test',1,1),(1,N'جهة ثانية',N'محاسب','second@example.test',0,1),(2,N'جهة عميل آخر',N'مشرف','other@example.test',1,1);
'@)
function OpenPage([string]$entity,[int]$actor=1,[string]$query='') {
 $script:testActor=$actor
 $script:target='/Modules/CRM_'+$entity+'/ManageCRM'+$entity+'.aspx'
 $url=$script:target+'?testActor='+$actor+$query
 $page=$hostObject.Request($url,$null)
 if($page -match 'Server Error|Exception Details|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'last.html'),$page,[Text.UTF8Encoding]::new($true))}
 CheckHtml $page
 Assert ($hostObject.LastStatus -eq 200) 'Management GET failed.'
 return $page
}
function RowAction([string]$html,[int]$id,[string]$caption) {
 $row=[regex]::Match($html,'(?s)<tr><td data-title="الرقم">'+$id+'</td>.*?</tr>').Value
 Assert ($row -ne '') "Missing management row $id"
 return (Action $row $caption)
}
function AccountValues([string]$name,[string]$username='',[string]$password='',[int]$brand=1) {
 return @{'f_Name_AR'=$name;'f_Name_EN'='Customer test';'f_Account_Type_ID'='1';'f_Owner_ID'='2';'f_Account_Brands'=@([string]$brand);'f_Account_Branches'=@();'f_Email'='customer@example.test';'f_Phone'='123456';'f_Website'='https://example.test';'f_Notes'='بيانات & محفوظة';'chkIsActive'='on';'txtUsername'=$username;'txtPassword'=$password;'chkLoginActive'='on'}
}
function ContactValues([string]$name,[int]$account=1) {
 return @{'f_Account_ID'=[string]$account;'f_Name_AR'=$name;'f_Name_EN'='Contact test';'f_Job_Title'='مدير تجريبي';'f_Job_Title_EN'='Test Manager';'f_Gender'='M';'f_Phone'='654321';'f_Email'='contact@example.test';'f_Notes'='ملاحظات & محفوظة';'chkIsActive'='on'}
}
function ContactCount([string]$html,[int]$id,[int]$count) {
 $row=[regex]::Match($html,'(?s)<tr><td data-title="الرقم">'+$id+'</td>.*?</tr>').Value
 Assert ($row -match ('data-title="جهات الاتصال"><a[^>]*>'+ $count +'</a>')) "Contact count incorrect for customer $id"
}
$html=OpenPage 'Accounts';CheckCounts $html 2 2 0;ContactCount $html 1 2;ContactCount $html 2 1
Assert ($html -match 'id="filterBrand"' -and $html -match 'id="filterBranch"' -and $html -notmatch 'id="ContentPlaceHolder1_filterPhone"|id="ContentPlaceHolder1_filterEmail"' -and $html -match 'customer-default.svg') 'Customer filters/default logo missing.'
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='1';'filterBranch'='1'};Assert ((CountRows $html) -eq 1) 'Customer brand/branch filters failed.';CheckCounts $html 2 2 0
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='1';'filterBranch'='2'};Assert ((CountRows $html) -eq 0) 'Cross-brand filter ignored selected brand.'
$html=Post $html ($prefix+'btnReset')
Assert ($html -match '<option value="1" data-brand-id="1">' -and $html -match '<option value="2" data-brand-id="2">') 'Branch metadata lost after filter postback/reset.'
Assert ($html -notmatch 'href="(?:Add|Edit)CRMAccounts|href="CustomerAccess|return confirm\(') 'Old account page actions remain.'
[IO.File]::WriteAllText((Join-Path $output 'accounts.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSearch') @{'filterName'='Other customer'};Assert ((CountRows $html) -eq 1) 'Account English filter failed.';CheckCounts $html 2 2 0
$html=Post $html ($prefix+'btnReset')
$html=Post $html ($prefix+'btnNewRecord')
Assert ($html -match 'id="ContentPlaceHolder1_txtUsername"' -and $html -match 'function openCRMPanel') 'Integrated account editor missing.'
Assert ($html.IndexOf('العلامات التجارية والفروع') -lt $html.IndexOf('id="logoPreview"') -and $html.IndexOf('id="logoPreview"') -lt $html.IndexOf('id="ContentPlaceHolder1_f_Name_AR"') -and $html.IndexOf('id="ContentPlaceHolder1_txtPassword"') -lt $html.IndexOf('id="ContentPlaceHolder1_chkIsActive"') -and $html.IndexOf('id="ContentPlaceHolder1_chkIsActive"') -lt $html.IndexOf('id="ContentPlaceHolder1_chkLoginActive"')) 'Customer editor section/state order incorrect.'
Assert ([regex]::Match($html,'<select[^>]*id="f_Account_Brands"[^>]*>').Value -notmatch 'onchange|__doPostBack') 'Editor brand still posts back.'
[IO.File]::WriteAllText((Join-Path $output 'account-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues '' 'new-login' 'Test-only-password1!')
Assert ($html -match 'أدخل الاسم' -and (CountRows $html) -eq 2) 'Account required validation failed.'
Add-Type -AssemblyName System.Drawing
$bitmap=[Drawing.Bitmap]::new(1200,800);$stream=[IO.MemoryStream]::new();$graphics=[Drawing.Graphics]::FromImage($bitmap)
try{$graphics.Clear([Drawing.Color]::RoyalBlue);$graphics.DrawRectangle([Drawing.Pens]::White,300,200,600,400);$bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$logoBytes=$stream.ToArray()}finally{$graphics.Dispose();$bitmap.Dispose();$stream.Dispose()}
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login' 'Test-only-password1!') 'fake.png' ([Text.Encoding]::UTF8.GetBytes('<script>alert(1)</script>'))
Assert ($html -match 'ليس صورة صالحة' -and (CountRows $html) -eq 2) 'Fake PNG accepted.'
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login' 'Test-only-password1!') 'logo.svg' $logoBytes
Assert ($html -match 'PNG وJPG وGIF فقط' -and (CountRows $html) -eq 2) 'Unsupported logo extension accepted.'
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login' 'Test-only-password1!') 'big.png' ([byte[]]::new(2097153))
Assert ($html -match 'حجم الشعار' -and (CountRows $html) -eq 2) 'Oversized upload accepted.'
$bitmap=[Drawing.Bitmap]::new(4097,1);$stream=[IO.MemoryStream]::new()
try{$bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$wideLogo=$stream.ToArray()}finally{$bitmap.Dispose();$stream.Dispose()}
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login' 'Test-only-password1!') 'wide.png' $wideLogo
Assert ($html -match 'أبعاد الشعار' -and (CountRows $html) -eq 2) 'Oversized image dimensions accepted.'
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login') 'valid.png' $logoBytes
Assert ($html -match 'كلمة المرور مطلوبة' -and (CountRows $html) -eq 2) 'New login failure partially saved customer.'
Assert ((Q $test.ConnectionString "SELECT COUNT(*) N FROM CRM_Activity_Logs WHERE Entity='Accounts' AND Action=N'إضافة' AND Record_ID>2").Rows[0].N -eq 0) 'Failed profile persisted audit.'
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Accounts WHERE Logo_Url IS NOT NULL').Rows[0].N -eq 0) 'Failed profile persisted logo.'
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد من القائمة' 'new-login' 'Test-only-password1!') 'valid.png' $logoBytes
Assert ($html -match 'alert-success alert-dismissible' -and $html -notmatch 'Test-only-password1!') 'Profile create failed or password echoed.'
$account=(Q $test.ConnectionString "SELECT a.ID,l.SecurityStamp,l.PasswordHash FROM CRM_Accounts a JOIN Customer_Logins l ON l.AccountID=a.ID WHERE l.Username='new-login'").Rows[0];$newAccount=[int]$account.ID
Assert ($newAccount -gt 2 -and (CountRows $html) -eq 3) 'Account/login not created together.';CheckCounts $html 3 3 0;ContactCount $html $newAccount 0
Assert ($html -match ('Logo.aspx\?id='+$newAccount+'&amp;v=') -and (Q $test.ConnectionString 'SELECT LEN(Logo_Url) N FROM CRM_Accounts WHERE ID=@id' @{'@id'=$newAccount}).Rows[0].N -gt 8) 'Customer logo URL missing from table/database.'
[IO.File]::WriteAllText((Join-Path $output 'accounts-logo.html'),$html,[Text.UTF8Encoding]::new($true))
[void]$hostObject.Request('/Modules/CRM_Accounts/Logo.aspx?id='+$newAccount,$null)
Assert ($hostObject.LastStatus -eq 200 -and $hostObject.LastContentType -like 'image/png*' -and [BitConverter]::ToString($hostObject.LastBytes,0,8) -eq '89-50-4E-47-0D-0A-1A-0A') "Protected logo response failed: status=$($hostObject.LastStatus), type=$($hostObject.LastContentType), bytes=$($hostObject.LastBytes.Length)."
[IO.File]::WriteAllBytes((Join-Path $output 'customer-logo.png'),$hostObject.LastBytes)
$stream=[IO.MemoryStream]::new([byte[]]$hostObject.LastBytes);$image=[Drawing.Image]::FromStream($stream)
try{Assert ($image.Width -eq 512 -and $image.Height -eq 341) 'Logo resize/aspect ratio incorrect.'}finally{$image.Dispose();$stream.Dispose()}
[void]$hostObject.Request('/Modules/CRM_Accounts/Logo.aspx?id='+$newAccount+'&testActor=2',$null);Assert ($hostObject.LastStatus -eq 200) 'Owning employee cannot read logo.'
[void]$hostObject.Request('/Modules/CRM_Accounts/Logo.aspx?id='+$newAccount+'&testActor=3',$null);Assert ($hostObject.LastStatus -eq 404) 'Other owner can read logo.'
[void]$hostObject.Request('/Modules/CRM_Accounts/Logo.aspx?id='+$newAccount+'&testActor=0',$null);Assert ($hostObject.LastStatus -eq 401) 'Anonymous logo request allowed.'
[void]$hostObject.Request('/Modules/CRM_Accounts/Logo.aspx?id=1',$null);Assert ($hostObject.LastStatus -eq 302 -and $hostObject.LastLocation -match 'customer-default.svg') 'Missing logo has no default.'
$logoVersion=(Q $test.ConnectionString 'SELECT Row_Version FROM CRM_Accounts WHERE ID=@id' @{'@id'=$newAccount}).Rows[0].Row_Version
$denied=$false
try{[void](Q $test.ConnectionString 'EXEC CRM_Save_Account_Logo @Actor_ID=3,@Account_ID=@id,@Logo_Url=@url,@Version=@v' @{'@id'=$newAccount;'@url'='/FileManager/CustomerLogos/11111111111111111111111111111111.png';'@v'=$logoVersion})}catch{$denied=$_.Exception.ToString() -match 'صلاحية'}
Assert $denied 'Other owner can replace logo.'
$denied=$false
try{[void](Q $test.ConnectionString 'EXEC CRM_Save_Account_Logo @Actor_ID=1,@Account_ID=@id,@Logo_Url=@url,@Version=0x0000000000000000' @{'@id'=$newAccount;'@url'='/FileManager/CustomerLogos/11111111111111111111111111111111.png'})}catch{$denied=$_.Exception.ToString() -match 'تم تعديل السجل'}
Assert $denied 'Stale logo update accepted.'
'PASS brand/branch filters, registered branch metadata, actual multipart image validation/resizing, atomic logo rollback and scoped/versioned logo access.'
$html=Post $html (RowAction $html $newAccount 'تعديل')
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد معدل' 'new-login')
$current=(Q $test.ConnectionString 'SELECT SecurityStamp,PasswordHash FROM Customer_Logins WHERE AccountID=@id' @{'@id'=$newAccount}).Rows[0]
Assert ($html -match 'تم حفظ التعديلات' -and $current.SecurityStamp -eq $account.SecurityStamp -and [Convert]::ToBase64String($current.PasswordHash) -eq [Convert]::ToBase64String($account.PasswordHash)) 'Unchanged login rotated session/password.'
$html=Post $html (RowAction $html $newAccount 'تعديل')
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل جديد معدل' 'new-login' 'Reset-test-password1!')
$reset=(Q $test.ConnectionString 'SELECT SecurityStamp,PasswordHash,Salt,Iterations FROM Customer_Logins WHERE AccountID=@id' @{'@id'=$newAccount}).Rows[0]
$derive=[Security.Cryptography.Rfc2898DeriveBytes]::new('Reset-test-password1!',[byte[]]$reset.Salt,[int]$reset.Iterations,[Security.Cryptography.HashAlgorithmName]::SHA256)
try{Assert ($reset.SecurityStamp -ne $current.SecurityStamp -and [Convert]::ToBase64String($reset.PasswordHash) -eq [Convert]::ToBase64String($derive.GetBytes(32)) -and $html -notmatch 'Reset-test-password1!') 'Integrated password reset/hash/stamp failed.'}finally{$derive.Dispose()}
$html=Post $html ($prefix+'btnNewRecord');$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'عميل مكرر الدخول' 'new-login' 'Other-test-password1!')
Assert ($html -match 'اسم المستخدم محجوز' -and (CountRows $html) -eq 3) 'Duplicate login partially saved new customer.'
$html=Post $html (RowAction $html $newAccount 'تعديل')
[void](Q $test.ConnectionString 'UPDATE Customer_Logins SET IsActive=IsActive WHERE AccountID=@id' @{'@id'=$newAccount})
$html=Post $html ($prefix+'btnSaveRecord') (AccountValues 'تعديل يجب التراجع عنه' 'changed-login')
Assert ($html -match 'تغير الحساب' -and (Q $test.ConnectionString 'SELECT Name_AR FROM CRM_Accounts WHERE ID=@id' @{'@id'=$newAccount}).Rows[0].Name_AR -eq 'عميل جديد معدل') 'Stale login partially saved customer.'
$html=Post $html (RowAction $html $newAccount 'تعديل')
$branchValues=AccountValues 'عميل جديد معدل' 'new-login' '' 2;$branchValues['f_Account_Branches']=@('2')
$html=Post $html ($prefix+'btnSaveRecord') $branchValues
Assert ((Q $test.ConnectionString 'SELECT Brand_ID,Branch_ID FROM CRM_Accounts WHERE ID=@id' @{'@id'=$newAccount}).Rows[0].Brand_ID -eq 2) 'Brand-only save failed.'
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Accounts WHERE Logo_Url IS NOT NULL AND ID=@id' @{'@id'=$newAccount}).Rows[0].N -eq 1) 'Edit without upload removed existing logo.'
$html=Post $html (RowAction $html $newAccount 'تعديل')
$branchValues['f_Account_Brands']=@('1')
$html=Post $html ($prefix+'btnSaveRecord') $branchValues
Assert ($html -match 'فروعًا تابعة للعلامات التجارية المحددة' -and (Q $test.ConnectionString 'SELECT Brand_ID FROM CRM_Accounts WHERE ID=@id' @{'@id'=$newAccount}).Rows[0].Brand_ID -eq 2) 'Cross-brand forged selection saved.'
$html=Post $html (RowAction $html $newAccount 'إيقاف');CheckCounts $html 3 2 1
$html=Post $html (RowAction $html $newAccount 'تفعيل');CheckCounts $html 3 3 0
$html=Post $html (RowAction $html 1 'حذف')
Assert ($html -match 'crmDeleteModal' -and -not (Q $test.ConnectionString 'SELECT Is_Deleted FROM CRM_Accounts WHERE ID=1').Rows[0].Is_Deleted) 'Account deleted before modal confirmation.'
$html=Post $html ($prefix+'btnConfirmDelete')
Assert ($html -match 'لديه جهات اتصال' -and (CountRows $html) -eq 3) 'Linked customer delete protection lost.'
'PASS customer inline create/edit, integrated optional login, atomic create/update failure, unchanged credentials, brand cascade, statistics and delete dependencies.'

$html=OpenPage 'Contacts';CheckCounts $html 3 2 1
[IO.File]::WriteAllText((Join-Path $output 'contacts.html'),$html,[Text.UTF8Encoding]::new($true))
$html=OpenPage 'Contacts' 1 '&account=1';Assert ((CountRows $html) -eq 2) 'Customer contact-count navigation filter failed.'
$html=Post $html ($prefix+'btnSearch') @{'filterJob'='محاسب'};Assert ((CountRows $html) -eq 1) 'Contact job filter failed.';CheckCounts $html 3 2 1
$html=Post $html ($prefix+'btnReset');$html=Post $html ($prefix+'btnNewRecord')
[IO.File]::WriteAllText((Join-Path $output 'contact-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Post $html ($prefix+'btnSaveRecord') (ContactValues '')
Assert ($html -match 'أدخل الاسم' -and (CountRows $html) -eq 3) 'Contact validation failed.'
$html=Post $html ($prefix+'btnSaveRecord') (ContactValues 'جهة جديدة من القائمة')
Assert ($html -match 'تمت الإضافة بنجاح' -and $html -match 'ملاحظات &amp; محفوظة') 'Contact create/encoding failed.'
$newContact=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Contacts WHERE Name_AR=N'جهة جديدة من القائمة'").Rows[0].ID
CheckCounts $html 4 3 1
$html=OpenPage 'Accounts';ContactCount $html 1 3
$html=OpenPage 'Contacts';$html=Post $html (RowAction $html $newContact 'تعديل')
$html=Post $html ($prefix+'btnSaveRecord') (ContactValues 'جهة منقولة' $newAccount)
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT Account_ID FROM CRM_Contacts WHERE ID=@id' @{'@id'=$newContact}).Rows[0].Account_ID -eq $newAccount) 'Contact move failed.'
$html=OpenPage 'Accounts';ContactCount $html 1 2;ContactCount $html $newAccount 1
$html=OpenPage 'Contacts';$html=Post $html (RowAction $html $newContact 'تعديل')
[void](Q $test.ConnectionString "UPDATE CRM_Contacts SET Notes=N'تعديل متزامن' WHERE ID=@id" @{'@id'=$newContact})
$html=Post $html ($prefix+'btnSaveRecord') (ContactValues 'كتابة قديمة' $newAccount)
Assert ($html -match 'تم تعديل السجل أو إلغاؤه' -and $html -match 'value="كتابة قديمة"') 'Contact stale protection/retained input failed.'
$html=Post $html (RowAction $html $newContact 'إيقاف');CheckCounts $html 4 2 2
$html=Post $html (RowAction $html $newContact 'تفعيل');CheckCounts $html 4 3 1
$html=Post $html (RowAction $html $newContact 'حذف')
Assert (-not (Q $test.ConnectionString 'SELECT Is_Deleted FROM CRM_Contacts WHERE ID=@id' @{'@id'=$newContact}).Rows[0].Is_Deleted) 'Contact deleted without confirmation.'
[IO.File]::WriteAllText((Join-Path $output 'contact-delete.html'),$html,[Text.UTF8Encoding]::new($true))
[void](Q $test.ConnectionString 'UPDATE CRM_Contacts SET Notes=Notes WHERE ID=@id' @{'@id'=$newContact})
$html=Post $html ($prefix+'btnConfirmDelete');Assert ($html -match 'السجل تغير أو حُذف') 'Stale contact confirmation accepted.'
$html=Post $html (RowAction $html $newContact 'حذف');$html=Post $html ($prefix+'btnConfirmDelete');CheckCounts $html 3 2 1
$html=Post $html ($prefix+'btnConfirmDelete');Assert ($html -match 'اختر السجل المراد حذفه') 'Repeated contact confirmation accepted.'
$html=OpenPage 'Accounts';ContactCount $html $newAccount 0
$html=Post $html (RowAction $html $newAccount 'حذف');$html=Post $html ($prefix+'btnConfirmDelete');CheckCounts $html 2 2 0
'PASS contact inline validation/create/edit/move, live customer counts, status, stale edit/delete, confirmation and replay protection.'

$html=OpenPage 'Accounts' 2;Assert ((CountRows $html) -eq 1) 'Owner customer scope leaked.';CheckCounts $html 1 1 0;ContactCount $html 1 2
$html=Post $html (RowAction $html 1 'تعديل')
Assert ($html -notmatch 'id="ContentPlaceHolder1_txtPassword"|id="ContentPlaceHolder1_txtUsername"') 'Owner can access customer login fields.'
[IO.File]::WriteAllText((Join-Path $output 'owner-editor.html'),$html,[Text.UTF8Encoding]::new($true))
$values=AccountValues 'تعديل المسؤول' 'forged-login' 'Forged-test-password1!';$values['f_Owner_ID']='3';$values['f_Account_Branches']=@('1')
try{$html=Post $html ($prefix+'btnSaveRecord') $values;throw 'Forged owner dropdown accepted.'}catch{Assert (([IO.File]::ReadAllText((Join-Path $output 'last.html'))) -match 'Invalid postback or callback argument') 'Unexpected forged-owner failure.'}
$html=OpenPage 'Accounts' 2;$html=Post $html (RowAction $html 1 'تعديل')
$values.Remove('f_Owner_ID')
try{$html=Post $html ($prefix+'btnSaveRecord') $values;throw 'Unrendered login fields accepted.'}catch{Assert (([IO.File]::ReadAllText((Join-Path $output 'last.html'))) -match 'Invalid postback or callback argument') 'Unexpected forged-credentials failure.'}
$html=OpenPage 'Accounts' 2;$html=Post $html (RowAction $html 1 'تعديل')
$values.Remove('txtUsername');$values.Remove('txtPassword');$values.Remove('chkLoginActive')
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT Owner_ID FROM CRM_Accounts WHERE ID=1').Rows[0].Owner_ID -eq 2 -and (Q $test.ConnectionString "SELECT COUNT(*) N FROM Customer_Logins WHERE Username='forged-login'").Rows[0].N -eq 0) 'Owner changed ownership or customer login.'
$html=OpenPage 'Contacts' 2;Assert ((CountRows $html) -eq 2) 'Owner contact scope leaked.';CheckCounts $html 2 1 1
$html=Post $html ($prefix+'btnNewRecord');Assert ($html -notmatch '<option[^>]*>عميل مسؤول آخر</option>') 'Other owner customer selectable.'
$html=Post $html ($prefix+'btnSaveRecord') (ContactValues 'جهة المسؤول')
Assert ($html -match 'تمت الإضافة بنجاح' -and (CountRows $html) -eq 3) 'Owner cannot create scoped contact.'
'PASS owner-scoped records/counts/options, same-page owner save and server-enforced login/ownership permissions.'
$script:testActor=1

# Supplier coverage uses the existing same-page customer editor and repeated ListBox form values.
$html=OpenPage 'Accounts'
$html=Post $html ($prefix+'btnNewRecord')
$supplierType=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Account_Types WHERE System_Code='SUPPLIER'").Rows[0].ID
$supplierValues=AccountValues 'مورد يغطي علامتين'
$supplierValues['f_Name_EN']='Two-brand supplier'
$supplierValues['f_Account_Type_ID']=[string]$supplierType
$supplierValues['f_Account_Brands']=@()
$html=Post $html ($prefix+'btnSaveRecord') $supplierValues
Assert ($html -match 'اختر علامة تجارية واحدة على الأقل' -and (Q $test.ConnectionString "SELECT COUNT(*) N FROM CRM_Accounts WHERE Name_AR=N'مورد يغطي علامتين'").Rows[0].N -eq 0) 'Supplier saved without required brand coverage.'
$supplierValues['f_Account_Brands']=@('1','2')
$html=Post $html ($prefix+'btnSaveRecord') $supplierValues
Assert ($html -match 'تمت الإضافة بنجاح') 'Supplier inline create failed.'
$supplierID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Accounts WHERE Name_AR=N'مورد يغطي علامتين'").Rows[0].ID
$coverage=(Q $test.ConnectionString 'SELECT Brand_ID FROM CRM_Supplier_Brands WHERE Account_ID=@id ORDER BY Brand_ID' @{'@id'=$supplierID}).Rows
Assert ($coverage.Count -eq 2 -and $coverage[0].Brand_ID -eq 1 -and $coverage[1].Brand_ID -eq 2) 'Multiple supplier brand values did not persist.'
$supplierRow=[regex]::Match($html,'(?s)<tr><td data-title="الرقم">'+$supplierID+'</td>.*?</tr>').Value
Assert ($supplierRow -match 'علامة أولى' -and $supplierRow -match 'علامة ثانية') 'Supplier table coverage names/count missing.'
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM Customer_Logins WHERE AccountID=@id' @{'@id'=$supplierID}).Rows[0].N -eq 0) 'Supplier coverage accidentally enabled a customer login.'
$html=Post $html (RowAction $html $supplierID 'تعديل')
$supplierSelect=[regex]::Match($html,'(?s)<select[^>]*id="f_Account_Brands"[^>]*>.*?</select>').Value
Assert ($supplierSelect -match '<option(?=[^>]*selected="selected")(?=[^>]*value="1")[^>]*>' -and $supplierSelect -match '<option(?=[^>]*selected="selected")(?=[^>]*value="2")[^>]*>') 'Supplier edit did not preserve all selected brands.'
$supplierValues['f_Name_AR']='مورد يغطي علامتين معدل'
$supplierValues['f_Name_EN']='Edited two-brand supplier'
$html=Post $html ($prefix+'btnSaveRecord') $supplierValues
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Supplier_Brands WHERE Account_ID=@id' @{'@id'=$supplierID}).Rows[0].N -eq 2) 'Supplier edit lost multi-brand coverage.'
$html=Post $html ($prefix+'btnNewRecord')
$ordinaryValues=AccountValues 'عميل دون تغطية مورد'
$html=Post $html ($prefix+'btnSaveRecord') $ordinaryValues
Assert ($html -match 'تمت الإضافة بنجاح') 'Ordinary customer unexpectedly requires supplier coverage.'
$ordinaryID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Accounts WHERE Name_AR=N'عميل دون تغطية مورد'").Rows[0].ID
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Supplier_Brands WHERE Account_ID=@id' @{'@id'=$ordinaryID}).Rows[0].N -eq 0) 'Ordinary customer received supplier brand coverage.'
# Delete only these generated fixtures so later work-guide/customer assertions retain their scope.
$html=Post $html (RowAction $html $ordinaryID 'حذف');$html=Post $html ($prefix+'btnConfirmDelete')
$html=Post $html (RowAction $html $supplierID 'حذف');$html=Post $html ($prefix+'btnConfirmDelete')
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Accounts WHERE ID IN(@supplier,@ordinary) AND Is_Deleted=1' @{'@supplier'=$supplierID;'@ordinary'=$ordinaryID}).Rows[0].N -eq 2) 'Supplier test fixture cleanup failed.'
'PASS supplier same-page required/multiple brand coverage, edit selection/name/count persistence, ordinary-customer separation and no implicit login.'
