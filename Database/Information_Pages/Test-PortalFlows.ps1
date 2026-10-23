# Uses the disposable authenticated ASP.NET host from CustomerPortal/Test-Dashboard.ps1.
Sql 'UPDATE CRM_Accounts SET Brand_ID=CASE WHEN ID=1 THEN 1 ELSE 2 END WHERE ID IN(1,2);UPDATE UsersMembers SET Brand_ID=1 WHERE ID IN(1,2);'
function InformationPost([string]$url,[string]$html,[hashtable]$values){
 $form=@{'__EVENTTARGET'='ctl00$ContentPlaceHolder1$btnSave'}
 foreach($match in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')){
  $name=[regex]::Match($match.Value,'name="([^"]+)"').Groups[1].Value;$value=[regex]::Match($match.Value,'value="([^"]*)"').Groups[1].Value
  if($name){$form[$name]=[Web.HttpUtility]::HtmlDecode($value)}
 }
 $form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$btnSave'
 foreach($key in $values.Keys){$form['ctl00$ContentPlaceHolder1$'+$key]=$values[$key]}
 $body=($form.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode($_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
 return Page $url $body
}
$infoAdd='/Modules/Information_Pages/Edit.aspx?newsTestActor=1'
$html=Page $infoAdd
Assert ($hostObject.Status -eq 200 -and $html -match 'ddlAudience' -and $html -match 'lstCustomers' -and $html -match 'informationEveryone' -and $html -match 'ابحث عن اسم العميل') 'Information editor renders employee/customer/everyone scope and searchable named customers'
Assert ($html -match 'data-brand-id="1"' -and $html -match 'data-brand-id="2"' -and $html -match 'data-customer-name=' -and $html -match 'filterCustomers') 'Information editor exposes registered brand/customer metadata for local cascading search'
[IO.File]::WriteAllText((Join-Path $output 'information-add.html'),$html,[Text.UTF8Encoding]::new($true))
$values=@{lstBrands='1';ddlAudience='customers';ddlAccess='all';ddlCustomersAccess='selected';lstCustomers='1';txtTitleAr='صفحة العميل المحدد';txtTitleEn='Selected customer page';txtSummaryAr='ملخص الصفحة للعميل';txtSummaryEn='Customer page summary';txtDetailsAr='<p>تفاصيل <strong>عربية للعميل</strong></p><script>BAD_INFORMATION()</script>';txtDetailsEn='<p>Customer <strong>English details</strong></p>';txtOrder='3';ddlStatus='1';ddlMode='immediate'}
[void](InformationPost $infoAdd $html $values)
Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*Manage.aspx?saved=1') 'Real information form saves selected-customer audience'
$infoId=[int](Q $TestConnection "SELECT ID FROM Information_Pages WHERE Title_En='Selected customer page'").Rows[0].ID
Sql "IF NOT EXISTS(SELECT 1 FROM Information_Pages p JOIN Information_Page_Customers c ON c.PageID=p.ID WHERE p.ID=$infoId AND p.Audience='customers' AND p.AllCustomers=0 AND c.AccountID=1 AND p.Details_Ar NOT LIKE '%BAD_INFORMATION%') THROW 51999,'Customer audience form persistence/sanitation failed',1;"
$infoEdit='/Modules/Information_Pages/Edit.aspx?ID='+$infoId+'&newsTestActor=1'
$html=Page $infoEdit
Assert ($html -match 'selected="selected" value="customers"' -and $html -match 'selected="selected" value="selected"' -and $html -match 'selected="selected" value="1"') 'Information edit restores audience and selected customer'
[IO.File]::WriteAllText((Join-Path $output 'information-edit.html'),$html,[Text.UTF8Encoding]::new($true))
$html=Page '/Modules/Information_Pages/Manage.aspx?newsTestActor=1';Assert ($html.Contains('content-management.js') -and $html.Contains('contentManager')) 'Information management renders the AJAX management component'
[void](Login)
$html=Page '/CustomerPortal/Dashboard.aspx?accountID=2';Assert ($hostObject.Status -eq 200 -and $html.Contains('صفحة العميل المحدد') -and $html.Contains('InformationPage.aspx?id='+$infoId)) 'Customer sees only its permitted information pages and direct navigation ignores forged account ID'
[IO.File]::WriteAllText((Join-Path $output 'information-list.html'),$html,[Text.UTF8Encoding]::new($true))
Assert ($html -match 'customer-information-menu' -and $html -match 'menu-sub' -and $html -match ('href="/CustomerPortal/InformationPage.aspx\?id='+$infoId+'"')) 'Customer menu exposes authorized information titles as direct content links'
$html=Page ("/CustomerPortal/InformationPage.aspx?id=$infoId");Assert ($hostObject.Status -eq 200 -and $html.Contains('<strong>عربية للعميل</strong>') -and $html -notmatch 'BAD_INFORMATION') 'Customer information detail renders sanitized Arabic rich content'
Assert ($html -notmatch 'العودة إلى الصفحات|href="InformationPages.aspx') 'Customer details have no return-to-list action'
$html=Page ("/CustomerPortal/InformationPage.aspx?id=$infoId&lang=en");Assert ($hostObject.Status -eq 200 -and $html.Contains('<strong>English details</strong>') -and $html.Contains('<strong>عربية للعميل</strong>') -and $html -match 'data-detail-language="en"' -and $html -match 'data-detail-language-toggle' -and $html -match 'detail-language.js') 'Information detail preloads both languages with English selected and local button switching'
[IO.File]::WriteAllText((Join-Path $output 'information-detail-en.html'),$html,[Text.UTF8Encoding]::new($true))
Sql "IF (SELECT COUNT(*) FROM Information_Page_Logs WHERE PageID=$infoId AND CustomerAccountID=1 AND ActorID=0 AND Action='view')<>2 THROW 51999,'Customer information visit identity missing',1;"
$html=Page '/Modules/Information_Pages/Logs.aspx?newsTestActor=1';Assert ($html.Contains('عميل الاختبار') -and $html.Contains('عميل · 1')) 'Information audit page renders customer visit identity separately from employees'
# A tampered/stale cross-brand customer POST must fail without changing grants or content.
$html=Page $infoEdit;$values.lstCustomers='2';$invalid=InformationPost $infoEdit $html $values
Assert ($hostObject.Status -eq 200 -and $invalid.Contains('اختر عملاء فعالين ضمن العلامات التجارية المحددة')) 'Server still rejects cross-brand customers if browser filtering is bypassed'
Sql "IF NOT EXISTS(SELECT 1 FROM Information_Page_Customers WHERE PageID=$infoId AND AccountID=1) OR EXISTS(SELECT 1 FROM Information_Page_Customers WHERE PageID=$infoId AND AccountID=2) THROW 51999,'Invalid cross-brand save changed grants',1;"
$values.lstCustomers='1'
$html=Page $infoEdit;$values.ddlAudience='all';[void](InformationPost $infoEdit $html $values)
Assert ($hostObject.Status -eq 302) 'Actual edit changes audience to everyone'
Sql "IF NOT EXISTS(SELECT 1 FROM Information_Pages WHERE ID=$infoId AND Audience='all' AND AllCustomers=1 AND AllUserTypes=1 AND VersionNumber=1) THROW 51999,'Audience-only form save changed content version or scope',1;"
$html=Page $infoEdit;$values.ddlAudience='employees';[void](InformationPost $infoEdit $html $values)
[void](Login)
$html=Page ("/CustomerPortal/InformationPage.aspx?id=$infoId");Assert ($hostObject.Status -eq 404 -and $html -notmatch 'عربية للعميل|English details') 'Changing audience revokes existing customer session direct access without content leakage'
$html=Page '/CustomerPortal/Dashboard.aspx';Assert ($html.Contains('لا توجد صفحات متاحة') -and $html -notmatch 'pnlInformationLinks|صفحة العميل المحدد') 'Revoked customer page disappears from menu and list immediately'
[void](Page ("/CustomerPortal/InformationPage.aspx?id=not-an-id"));Assert ($hostObject.Status -eq 404) 'Invalid information detail ID fails safely'
# Employee ordinary viewing shares the local switch; a timer/form POST preserves language and adds no visit.
$employeeUrl="/Modules/Information_Pages/View.aspx?ID=$infoId&newsTestActor=2"
$html=Page $employeeUrl
Assert ($hostObject.Status -eq 200 -and $html -match 'data-detail-language="ar"' -and $html -match 'data-detail-lang="en"' -and $html -match 'data-detail-language-toggle') 'Employee information reader provides both sanitized languages with a local switch'
[IO.File]::WriteAllText((Join-Path $output 'information-employee.html'),$html,[Text.UTF8Encoding]::new($true))
$form=@{}
foreach($input in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')){$name=[regex]::Match($input.Value,'name="([^"]+)"').Groups[1].Value;$value=[regex]::Match($input.Value,'value="([^"]*)"').Groups[1].Value;if($name){$form[$name]=[Web.HttpUtility]::HtmlDecode($value)}}
$form['ctl00$ContentPlaceHolder1$detailLanguage']='en'
$body=($form.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode($_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
$html=Page $employeeUrl $body
Assert ($hostObject.Status -eq 200 -and $html -match 'data-detail-language="en"') 'Employee language choice survives subsequent Web Forms postbacks'
Sql "IF (SELECT COUNT(*) FROM Information_Page_Logs WHERE PageID=$infoId AND ActorID=2 AND Action='view')<>1 THROW 51999,'Language state POST created an extra visit',1;"
'PASS actual information editor/customer navigation/detail/language/audit/revocation and employee state flows.'
