# Sourced only by Test-CRM-TypePage.ps1 -IncludeManagement -MultiBrandOnly.
# The host and every SQL operation below target its generated schema-only database.
function OpenMultiAccounts([int]$actor=1){
 $script:testActor=$actor
 $script:target='/Modules/CRM_Accounts/ManageCRMAccounts.aspx'
 $page=$hostObject.Request($script:target+'?testActor='+$actor,$null)
 CheckHtml $page
 Assert ($hostObject.LastStatus -eq 200) 'Multi-brand account management GET failed.'
 return $page
}
function MultiRow([string]$html,[int]$id){return [regex]::Match($html,'(?s)<tr><td data-title="الرقم">'+$id+'</td>.*?</tr>').Value}
function MultiRowAction([string]$html,[int]$id,[string]$caption){
 $row=MultiRow $html $id
 Assert ($row -ne '') ('Missing multi-brand account row '+$id)
 return (Action $row $caption)
}
function OrganizationSelect([string]$html,[string]$name){return [regex]::Match($html,'(?s)<select\b[^>]*id="'+[regex]::Escape($name)+'"[^>]*>.*?</select>').Value}
function SelectedMembership([string]$html,[string]$name,[string[]]$expected){
 $select=OrganizationSelect $html $name
 foreach($id in $expected){Assert ($select -match ('<option\b(?=[^>]*value="'+[regex]::Escape($id)+'")(?=[^>]*selected="selected")[^>]*>')) ('Selected organization option was not preserved: '+$name+' / '+$id)}
}
function MultiAccountValues([string]$name){return @{
 'f_Name_AR'=$name;'f_Name_EN'='Multi-brand UI customer';'f_Account_Type_ID'='1';'f_Owner_ID'='2';
 'f_Account_Brands'=@('1','2');'f_Account_Branches'=@('101','102','201');
 'f_Phone'='';'f_Email'='';'f_Country'='';'f_Address'='عنوان محفوظ';'f_Website'='';'f_Registration_Number'='';'f_Notes'='بيانات اختبار محفوظة';
 'chkIsActive'='on';'chkLoginActive'='on';'txtUsername'='';'txtPassword'=''
}}

$html=OpenMultiAccounts
Assert ($html -notmatch 'id="pnlSupplierBrands"|id="f_Supplier_Brands"|id="f_Brand_ID"|id="f_Branch_ID"') 'Retired scalar/supplier organization controls are still rendered.'
$html=Post $html ($prefix+'btnNewRecord')
Assert ((OrganizationSelect $html 'f_Account_Brands') -match '\bmultiple="multiple"' -and (OrganizationSelect $html 'f_Account_Branches') -match '\bmultiple="multiple"') 'Account organization controls must both support multiple selection.'
Assert ((OrganizationSelect $html 'f_Account_Brands') -notmatch 'onchange|__doPostBack' -and $html -match 'data-crm-account-branches="f_Account_Branches"') 'Brand selection still posts back or lacks the local branch cascade.'
Assert ((OrganizationSelect $html 'f_Account_Branches') -match 'data-brand-id="1"' -and (OrganizationSelect $html 'f_Account_Branches') -match 'data-brand-id="2"' -and (OrganizationSelect $html 'f_Account_Branches') -match 'علامة ثانية') 'Branch options need parent-brand metadata and readable labels.'

# Required-field failures retain the draft and all valid membership selections.
$values=MultiAccountValues ''
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'أدخل الاسم' -and $html -match 'value="Multi-brand UI customer"') 'Missing-name validation lost the entered account fields.'
SelectedMembership $html 'f_Account_Brands' @('1','2')
SelectedMembership $html 'f_Account_Branches' @('101','102','201')
$values['f_Name_AR']='عميل جديد متعدد العلامات UI'
$values['f_Account_Brands']=@()
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'اختر علامة تجارية واحدة على الأقل' -and $html -match 'value="عميل جديد متعدد العلامات UI"' -and (Q $test.ConnectionString "SELECT COUNT(*) N FROM CRM_Accounts WHERE Name_AR=N'عميل جديد متعدد العلامات UI'").Rows[0].N -eq 0) 'Missing-brand validation lost the draft or saved an account.'
SelectedMembership $html 'f_Account_Branches' @('101','102','201')
$values['f_Account_Brands']=@('1','2')
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'تمت الإضافة بنجاح') 'Multi-brand account create failed.'
$accountID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Accounts WHERE Name_AR=N'عميل جديد متعدد العلامات UI'").Rows[0].ID
Assert ($accountID -gt 0 -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Brands WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 2 -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Branches WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 3) 'The two brands and three branches were not saved together.'
Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM Customer_Logins WHERE AccountID=@id' @{'@id'=$accountID}).Rows[0].N -eq 0 -and (MultiRow $html $accountID) -match 'customer-default.svg') 'Organization membership unexpectedly created credentials or removed the default logo.'
$accountRow=MultiRow $html $accountID
Assert ($accountRow -match 'علامة أولى' -and $accountRow -match 'علامة ثانية' -and $accountRow -match 'الفرع الأول' -and $accountRow -match 'الفرع الثاني' -and $accountRow -match 'فرع العلامة الثانية') 'Management table does not show all account brands/branches.'
[IO.File]::WriteAllText((Join-Path $output 'accounts-multi-brand.html'),$html,[Text.UTF8Encoding]::new($true))

# Searching must include secondary memberships, rather than only compatibility scalars.
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='2'}
Assert ((MultiRow $html $accountID) -ne '') 'The non-primary account brand is missing from the brand filter.'
$html=Post $html ($prefix+'btnSearch') @{'filterBrand'='2';'filterBranch'='201'}
Assert ((MultiRow $html $accountID) -ne '') 'The non-primary branch is missing from the branch filter.'
$html=Post $html ($prefix+'btnReset')
$html=Post $html (MultiRowAction $html $accountID 'تعديل')
SelectedMembership $html 'f_Account_Brands' @('1','2')
SelectedMembership $html 'f_Account_Branches' @('101','102','201')

# A registered branch from an unselected third brand must still be rejected server-side.
$values['f_Account_Branches']=@('101','301')
$values['f_Name_AR']='تعديل يجب رفضه'
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'فروعًا تابعة للعلامات التجارية المحددة' -and (Q $test.ConnectionString 'SELECT Name_AR FROM CRM_Accounts WHERE ID=@id' @{'@id'=$accountID}).Rows[0].Name_AR -eq 'عميل جديد متعدد العلامات UI' -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Branches WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 3) 'A foreign-brand branch was accepted or partially saved account data.'
SelectedMembership $html 'f_Account_Brands' @('1','2')
Assert ($html -match 'value="تعديل يجب رفضه"' -and (OrganizationSelect $html 'f_Account_Branches') -match 'data-brand-id="2"') 'Rejected save lost entered fields or branch relationship metadata.'

# Branches are optional independently for every selected brand.
$html=OpenMultiAccounts
$html=Post $html (MultiRowAction $html $accountID 'تعديل')
$values['f_Name_AR']='عميل متعدد العلامات بدون فروع UI'
$values['f_Account_Branches']=@()
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Brands WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 2 -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Branches WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 0) 'Optional branches cleared brands or failed to remove branch membership.'

# An existing owner can maintain a normal customer, without credential or ownership controls.
$html=OpenMultiAccounts 2
$html=Post $html (MultiRowAction $html $accountID 'تعديل')
Assert ($html -notmatch 'id="ContentPlaceHolder1_txtUsername"') 'Owner can access customer credentials.'
$values['f_Name_AR']='عميل متعدد العلامات من المسؤول UI'
$values['f_Account_Branches']=@('102','201')
$values.Remove('txtUsername');$values.Remove('txtPassword');$values.Remove('chkLoginActive');$values.Remove('f_Owner_ID')
$html=Post $html ($prefix+'btnSaveRecord') $values
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT Owner_ID FROM CRM_Accounts WHERE ID=@id' @{'@id'=$accountID}).Rows[0].Owner_ID -eq 2 -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Branches WHERE Account_ID=@id' @{'@id'=$accountID}).Rows[0].N -eq 2) 'Owner-scoped normal customer membership save failed.'

# Suppliers use the same editor controls but retain administrator-only maintenance.
$supplierID=[int](Q $test.ConnectionString "SELECT ID FROM CRM_Accounts WHERE Name_AR=N'مورد متعدد العلامات SQL'").Rows[0].ID
$html=OpenMultiAccounts 1
$html=Post $html (MultiRowAction $html $supplierID 'تعديل')
SelectedMembership $html 'f_Account_Brands' @('1','2')
$supplierValues=MultiAccountValues 'مورد متعدد العلامات UI'
$supplierValues['f_Account_Type_ID']=[string](Q $test.ConnectionString "SELECT ID FROM CRM_Account_Types WHERE System_Code='SUPPLIER'").Rows[0].ID
$supplierValues['f_Account_Branches']=@('101','201')
$html=Post $html ($prefix+'btnSaveRecord') $supplierValues
Assert ($html -match 'تم حفظ التعديلات' -and (Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Supplier_Brands WHERE Account_ID=@id' @{'@id'=$supplierID}).Rows[0].N -eq 2) 'Supplier compatibility coverage did not match the shared account membership.'
$html=OpenMultiAccounts 2
$html=Post $html (MultiRowAction $html $supplierID 'تعديل')
$supplierValues['f_Name_AR']='تعديل مورد غير مصرح'
$supplierValues.Remove('txtUsername');$supplierValues.Remove('txtPassword');$supplierValues.Remove('chkLoginActive');$supplierValues.Remove('f_Owner_ID')
$html=Post $html ($prefix+'btnSaveRecord') $supplierValues
Assert ($html -match 'مدير النظام' -and (Q $test.ConnectionString 'SELECT Name_AR FROM CRM_Accounts WHERE ID=@id' @{'@id'=$supplierID}).Rows[0].Name_AR -eq 'مورد متعدد العلامات UI') 'Owner changed administrator-only supplier membership.'
$script:testActor=1
'PASS real ASP.NET multi-brand/multi-branch account create/edit, hierarchy validation/retained drafts, optional branches, secondary membership filters, owner/admin limits and unchanged credential/logo behavior.'
