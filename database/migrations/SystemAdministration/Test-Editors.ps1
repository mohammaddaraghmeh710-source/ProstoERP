# Sourced by Test.ps1. Every request targets its schema-only synthetic database.
function Attribute([string]$html,[string]$name){$m=[regex]::Match($html,'\b'+[regex]::Escape($name)+'\s*=\s*(["''])(.*?)\1','Singleline,IgnoreCase');return [Web.HttpUtility]::HtmlDecode($m.Groups[2].Value)}
function Values([string]$html){
 $data=@{}
 foreach($input in [regex]::Matches($html,'<input\b[^>]*>','IgnoreCase')){$tag=$input.Value;$key=Attribute $tag 'name';$type=Attribute $tag 'type';if(!$key -or $type -in @('file','submit','button','reset')){continue};if($type -in @('checkbox','radio') -and $tag -notmatch '\bchecked\b'){continue};$value=Attribute $tag 'value';if($type -in @('checkbox','radio') -and !$value){$value='on'};$data[$key]=$value}
 foreach($textarea in [regex]::Matches($html,'<textarea\b([^>]*)>(.*?)</textarea>','Singleline,IgnoreCase')){$key=Attribute $textarea.Groups[1].Value 'name';if($key){$data[$key]=[Web.HttpUtility]::HtmlDecode($textarea.Groups[2].Value)}}
 foreach($select in [regex]::Matches($html,'<select\b([^>]*)>(.*?)</select>','Singleline,IgnoreCase')){$key=Attribute $select.Groups[1].Value 'name';$options=@([regex]::Matches($select.Groups[2].Value,'<option\b([^>]*)>(.*?)</option>','Singleline,IgnoreCase'));$chosen=@($options|Where-Object {$_.Groups[1].Value -match '\bselected\b'});if(!$chosen.Count -and $options.Count){$chosen=@($options[0])};if($key -and $chosen.Count){$data[$key]=Attribute $chosen[0].Groups[1].Value 'value'}}
 return $data
}
function AsyncPost([string]$url,[string]$html,[hashtable]$data,[string]$target){
 $scriptName=[regex]::Match($html,'PageRequestManager\._initialize\([''"]([^''"]+)').Groups[1].Value
 if(!$scriptName){throw 'ScriptManager was not rendered.'}
 $data['__EVENTTARGET']=$target;$data['__EVENTARGUMENT']='';$data['__ASYNCPOST']='true';$data[$scriptName]='ctl00$ContentPlaceHolder1$systemAdminPanel|'+$target
 $body=($data.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode([string]$_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
 $response=$hostObject.RequestAsync($url,$body)
 if($hostObject.Status -ne 200 -or $response -match '\|error\|'){[IO.File]::WriteAllText((Join-Path $output 'ajax-error.txt'),$response);throw "AJAX request failed: $url. See tmp/system-admin-results/ajax-error.txt"}
 Assert ($response -match '\|updatePanel\|' -and $hostObject.ContentType -like 'text/plain*') 'The operation returns an ASP.NET AJAX delta, without document navigation' | Out-Host
 return $response
}
function SaveEditor([string]$url,[string]$html,[hashtable]$overrides=@{},[string]$buttonID='btnSave'){
 $data=Values $html
 foreach($key in $overrides.Keys){$data['ctl00$ContentPlaceHolder1$'+$key]=$overrides[$key]}
 $button=@([regex]::Matches($html,'<input\b[^>]*>','IgnoreCase')|Where-Object {(Attribute $_.Value 'name') -like ('*$'+$buttonID)})
 if($button.Count){$target=Attribute $button[0].Value 'name';$data[$target]=Attribute $button[0].Value 'value'}else{
  $link=@([regex]::Matches($html,'<a\b[^>]*>','IgnoreCase')|Where-Object {(Attribute $_.Value 'id') -like ('*_'+$buttonID)})
  if(!$link.Count){throw "Save button not rendered: $url"}
  $target=[regex]::Match((Attribute $link[0].Value 'href'),'(?:__doPostBack|PostBackOptions)\([''"]([^''"]+)').Groups[1].Value
  if(!$target){throw 'The save postback target was not rendered.'}
 }
 $response=AsyncPost $url $html $data $target
 if($response -notmatch 'system-admin-complete'){[IO.File]::WriteAllText((Join-Path $output 'save-error.txt'),$response);throw "Save did not complete: $url. See tmp/system-admin-results/save-error.txt"}
 Assert ($response -notmatch '\|pageRedirect\|') 'An embedded save completes without a redirect' | Out-Host
 return $response
}

# Exercise each original edit handler, including its real validators and ViewState version.
foreach($route in $routes){
 $management=$hostObject.Request($route+'?newsTestActor=1',$null)
 $definition=[regex]::Match($management,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
 if(!$definition.edit){continue}
 $url=$definition.edit+'?ID=1&saEditor='+$definition.token;$html=$hostObject.Request($url,$null)
 [void](SaveEditor $url $html)
 Assert $true "Existing editor saves asynchronously: $($definition.edit)"
}

# A new record must be visible when the management refresh callback runs.
$route='/Modules/Brands/ManageBrands.aspx';$management=$hostObject.Request($route+'?newsTestActor=1',$null)
$definition=[regex]::Match($management,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
$url=$definition.add+'?saEditor='+$definition.token;$html=$hostObject.Request($url,$null)
[void](SaveEditor $url $html @{txtFullNameAr='علامة اختبار AJAX';txtFullNameEn='AJAX created brand'})
$management=$hostObject.Request($route,$null);$data=Values $management
$reload=@([regex]::Matches($management,'<input\b[^>]*>')|Where-Object {(Attribute $_.Value 'id') -eq 'reloadAdmin'})[0]
$response=AsyncPost $route $management $data (Attribute $reload.Value 'name')
Assert ($response -match 'AJAX created brand') 'The management AJAX callback includes the newly saved data'

# Integration saves are isolated storage operations. The API worker is never hosted here.
$route='/Modules/Attendance_Integration/ManageAttendanceIntegration.aspx';$management=$hostObject.Request($route+'?newsTestActor=1',$null)
$definition=[regex]::Match($management,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
$url=$route+'?brand=1&saEditor='+$definition.token;$html=$hostObject.Request($url,$null)
[void](SaveEditor $url $html @{txtApiUrl='http://localhost:52380/';txtApiUser='synthetic-api';txtApiPassword='Synthetic-API!2026';txtBioUrl='http://127.0.0.1:8089/';txtBioUser='synthetic-bio';txtBioPassword='Synthetic-Bio!2026';chkEnabled='on'})
$html=$hostObject.Request($url,$null)
[void](SaveEditor $url $html @{txtSenderEmail='synthetic-notify@example.invalid';txtSmtpPassword='abcdabcdabcdabcd';chkEmailEnabled='on'} 'btnSaveEmail')
$stored=Query $test.ConnectionString 'SELECT a.Enabled ApiEnabled,e.Enabled EmailEnabled FROM dbo.AttendanceIntegrationSettings a JOIN dbo.EmailNotificationSettings e ON e.BrandID=a.BrandID WHERE a.BrandID=1'
Assert ($stored.Rows.Count -eq 1 -and $stored.Rows[0].ApiEnabled -and $stored.Rows[0].EmailEnabled) 'Both integration and independent email settings survive asynchronous saves'

# Permission save uses the original role-version and target checks.
$route='/Modules/Employee_Feedback_Permissions/ManageEmployeeFeedbackPermissions.aspx';$management=$hostObject.Request($route+'?newsTestActor=1',$null)
$definition=[regex]::Match($management,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
$url=$route+'?role=4&saEditor='+$definition.token;$html=$hostObject.Request($url,$null)
[void](SaveEditor $url $html @{ddlRole='4';chkSubmit='on';chkTransfer='on';chkClose='on';'lstTargets$0'='on'})
Assert $true 'Permission editing preserves its existing server contract under AJAX'

# Explicitly registered ListView commands must also refresh their conditional region.
$route='/Modules/Users/ManageUsers.aspx';$html=$hostObject.Request($route+'?newsTestActor=1',$null)
$link=@([regex]::Matches($html,'<a\b[^>]*>','IgnoreCase')|Where-Object {(Attribute $_.Value 'id') -like '*_btnDevices_0'})[0]
$target=[regex]::Match((Attribute $link.Value 'href'),'__doPostBack\([''"]([^''"]+)').Groups[1].Value
$response=AsyncPost $route $html (Values $html) $target
Assert ($response -match 'id="deviceModal"' -and $response -match 'أجهزة تطبيق الهاتف') 'Device commands refresh their modal HTML in the same AJAX response'

$route='/Modules/Departments/ManageDepartments.aspx';$html=$hostObject.Request($route,$null)
$definition=[regex]::Match($html,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
$url=$definition.add+'?saEditor='+$definition.token;$html=$hostObject.Request($url,$null);$data=Values $html
$data['ctl00$ContentPlaceHolder1$ddlBrand']='1';$data['ctl00$ContentPlaceHolder1$txtTitleAr']='Preserved draft'
$response=AsyncPost $url $html $data 'ctl00$ContentPlaceHolder1$ddlBrand'
Assert ($response -match 'Preserved draft' -and $response -match 'فرع اختبار') 'Dependent branch loading preserves the entered draft without document navigation'

# Custom ListItem metadata must survive the real ViewState/AJAX round trip.
# Otherwise the client brand filter removes every supplier after a cascade.
$fixture=Query $test.ConnectionString @'
INSERT Brands(Title_Ar,Title_En,IsActive,IsDeleted) VALUES(N'علامة تصفية المورد','Supplier filter brand',1,0);
DECLARE @Brand int=CONVERT(int,SCOPE_IDENTITY());
INSERT CRM_Accounts(Name_AR,Name_EN,Account_Type_ID,Brand_ID,Is_Active,Is_Deleted,AddedUser) VALUES(N'مورد العلامة الثانية','Second-brand supplier',101,@Brand,1,0,1);
DECLARE @Account int=CONVERT(int,SCOPE_IDENTITY());
INSERT CRM_Supplier_Brands(Account_ID,Brand_ID,AddedUser) VALUES(101,@Brand,1),(@Account,@Brand,1);
SELECT @Brand BrandID,@Account AccountID;
'@
$supplierBrand=[string]$fixture.Rows[0].BrandID
$secondSupplier=[string]$fixture.Rows[0].AccountID
$route='/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx'
$management=$hostObject.Request($route+'?newsTestActor=1',$null)
$definition=[regex]::Match($management,'id="systemAdminConfiguration"[^>]*>(.*?)</script>','Singleline').Groups[1].Value|ConvertFrom-Json
$toolURLs=@($route)
$toolURLs+=$definition.add+'?saEditor='+$definition.token
$toolURLs+=$definition.edit+'?ID=1&saEditor='+$definition.token
foreach($url in $toolURLs){
 $html=$hostObject.Request($url,$null);$data=Values $html
 $data['ctl00$ContentPlaceHolder1$ddlBrand']=$supplierBrand
 $data['ctl00$ContentPlaceHolder1$ddlSupplier']='101'
 $response=AsyncPost $url $html $data 'ctl00$ContentPlaceHolder1$ddlBrand'
 $supplierSelect=[regex]::Match($response,'<select\b[^>]*id="[^"]*ddlSupplier"[^>]*>.*?</select>','Singleline').Value
 foreach($id in @('101',$secondSupplier)){
  $option=[regex]::Match($supplierSelect,'<option\b(?=[^>]*\bvalue="'+$id+'")[^>]*>','Singleline').Value
  $brandIDs=(Attribute $option 'data-brand-ids').Split(',')
  Assert ($option -ne '' -and $brandIDs -contains $supplierBrand -and (Attribute $option 'data-available') -eq '1') ('Supplier '+$id+' retains brand/availability metadata after the AJAX cascade: '+$url.Split('?')[0])
 }
 Assert ($supplierSelect -match '<option\b(?=[^>]*\bvalue="101")(?=[^>]*\bselected="selected")[^>]*>') 'A valid supplier selection survives the brand cascade'
 if($url -like '*Edit_*'){
  Assert ((Attribute $supplierSelect 'data-current-account') -eq '101' -and (Attribute $supplierSelect 'data-current-brand') -eq '1') 'Historical supplier identity/brand metadata survive the edit cascade'
 }
}
