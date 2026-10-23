param([switch]$IncludeManagement,[switch]$DatabaseOnly,[switch]$AccessOnly,[switch]$GuideOnly,[switch]$KeepDatabase,[switch]$MultiBrandOnly)
$ErrorActionPreference='Stop'
if(($AccessOnly -or $GuideOnly) -and -not $IncludeManagement){throw 'AccessOnly/GuideOnly require IncludeManagement.'}
Add-Type -AssemblyName System.Web
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$portal=Join-Path $root 'ERP_Prosto/Portal'
$config=[xml](Get-Content (Join-Path $portal 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new(($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Local SQL Server required.'}
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$testName='Prosto_CRM_Page_Test_'+[guid]::NewGuid().ToString('N')
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$testName
$stage=Join-Path $root ('tmp/crm-type-page-'+[guid]::NewGuid().ToString('N'))
$output=Join-Path $root $(if($MultiBrandOnly){'tmp/crm-multibrand-results'}else{'tmp/crm-type-page-results'})
function Q([string]$connection,[string]$sql,[hashtable]$parameters=@{}) {
 $db=[Data.SqlClient.SqlConnection]::new($connection)
 try {$db.Open();$cmd=$db.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=120;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$set=[Data.DataSet]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($set);if($set.Tables.Count){return ,$set.Tables[0]};return ,([Data.DataTable]::new())} finally {$db.Dispose()}
}
function Assert([bool]$ok,[string]$message){if(-not $ok){throw $message}}
function CheckHtml([string]$html){Assert ($html -notmatch 'Server Error|Exception Details|Parser Error|Compilation Error') 'ASP.NET render failed.'}
$prefix='ctl00$ContentPlaceHolder1$'
$target='/Modules/CRM_Account_Types/ManageCRMAccountTypes.aspx'
function Post([string]$html,[string]$eventTarget,[hashtable]$values=@{},[string]$fileName='',[byte[]]$fileBytes=$null,[string]$fileField='logoUpload') {
 $form=@{}
 foreach($match in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')) {
  $name=[regex]::Match($match.Value,'name="([^"]+)"').Groups[1].Value
  $value=[regex]::Match($match.Value,'value="([^"]*)"').Groups[1].Value
  if($name){$form[$name]=[Web.HttpUtility]::HtmlDecode($value)}
 }
 $form['__EVENTTARGET']=$eventTarget
 $form[$prefix+'filterName']='';$form[$prefix+'filterStatus']=''
 foreach($key in $values.Keys){$form[$prefix+$key]=$values[$key]}
 $encoded=($form.GetEnumerator()|ForEach-Object {$entry=$_;foreach($value in @($entry.Value)){[Web.HttpUtility]::UrlEncode($entry.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$value)}}) -join '&'
 $postTarget=$target
 if($script:testActor -and $script:testActor -ne 1){$postTarget+='?testActor='+$script:testActor}
 $result=if($fileName){$hostObject.UploadField($postTarget,$encoded,$fileName,$fileBytes,$fileField)}else{$hostObject.Request($postTarget,$encoded)}
 [IO.File]::WriteAllText((Join-Path $output 'last.html'),$result,[Text.UTF8Encoding]::new($true))
 if($result -match 'Server Error|Exception Details|Parser Error|Compilation Error'){throw "ASP.NET render failed: $postTarget / $eventTarget"}
 Assert ($hostObject.LastStatus -eq 200) 'A page action redirected or returned an error.'
 return $result
}
function Action([string]$html,[string]$caption) {
 $link=[regex]::Match($html,'<a\b[^>]*aria-label="'+[regex]::Escape($caption)+'"[^>]*>.*?</a>').Value
 $decoded=[Web.HttpUtility]::HtmlDecode($link)
 $command=[regex]::Match($decoded,"__doPostBack\('([^']+)'").Groups[1].Value
 Assert ($command -ne '') "Missing row action: $caption"
 return $command
}
function EditorValues([string]$name,[string]$notes='اختبار الحفظ') {return @{'editNameAr'=$name;'editNameEn'='Inline type';'editNotes'=$notes;'editActive'='on'}}
function CountRows([string]$html){return [regex]::Matches($html,'data-title="الرقم"').Count}
function CheckCounts([string]$html,[int]$total,[int]$active,[int]$inactive) {
 $counts=@([regex]::Matches($html,'class="type-stat-count">([\d,]+)</div>')|ForEach-Object {[int]$_.Groups[1].Value.Replace(',','')})
 Assert ($counts.Count -eq 3 -and $counts[0] -eq $total -and $counts[1] -eq $active -and $counts[2] -eq $inactive) 'Summary counts incorrect.'
}
$created=$false
$completed=$false
try {
 [void](Q $master.ConnectionString "CREATE DATABASE [$testName]");$created=$true
 # Schema only: no real organization, customer, supplier or tool records are copied.
 $fixtureTables=@('UsersMembers','Users_Types','Brands','Branches')
 if($IncludeManagement){$fixtureTables+=@('Departments','JobTitles','JobTitle_Items','JobTitle_Items_Types','Maintenance_Companies')}
 foreach($table in $fixtureTables) {
  $catalog=$source.InitialCatalog.Replace(']',']]')
  [void](Q $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$catalog].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID);")
  $defaults=Q $source.ConnectionString "SELECT c.name Col,d.definition Def FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID('dbo.$table')"
  foreach($row in $defaults.Rows){[void](Q $test.ConnectionString "ALTER TABLE dbo.[$table] ADD DEFAULT $($row.Def) FOR [$($row.Col)]")}
 }
 [void](Q $test.ConnectionString @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'مدير اختبار',1,0),(4,N'موظف اختبار',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,FullName_Ar,UserName,Type,IsActive,IsDeleted) VALUES(1,N'مدير اختبار','test-admin',1,1,0),(2,N'مسؤول اختبار','test-owner',4,1,0);SET IDENTITY_INSERT UsersMembers OFF;
'@)
 foreach($file in @('001_CRM_Schema.sql','002_CRM_Procedures.sql','006_CRM_Delete.sql')) {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
 }
 [void](Q $test.ConnectionString "INSERT CRM_Accounts(Name_AR,Owner_ID,AddedUser) VALUES(N'عميل اختبار',2,1);")
 if($IncludeManagement) {
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '007_CRM_Organization_Overview.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '008_CRM_Account_Logos.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '009_CRM_Contact_Names.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '010_CRM_Inline_Logos.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '011_CRM_ContactTitles_Activity.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '012_CRM_FileLogos.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '013_CRM_WorkGuide.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
  $customerSql=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/001_Accounts.sql'))
  [void](Q $test.ConnectionString ([regex]::Match($customerSql,'(?s) CREATE TABLE dbo.Customer_Logins.*?(?= CREATE TABLE dbo.Customer_Portal_Activity)').Value))
  [void](Q $test.ConnectionString ([regex]::Match($customerSql,'(?s) CREATE TABLE dbo.Customer_Portal_Activity.*?(?= CREATE TABLE dbo.Customer_Portal_Feedback)').Value))
  foreach($batch in [regex]::Split($customerSql,'(?im)^\s*GO\s*$')){if($batch -match 'CREATE OR ALTER PROCEDURE dbo.Customer_(AdminCheck|SaveLogin|Credentials|LoginResult|Session)\b'){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split($customerSql,'(?im)^\s*GO\s*$')){if($batch -match 'CREATE OR ALTER PROCEDURE dbo.Customer_AdminData\b'){[void](Q $test.ConnectionString $batch)}}
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../CustomerPortal/007_SelfService.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
 }
 if($IncludeManagement){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '014_CRM_WorkGuide_Access.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 if($IncludeManagement){
  [void](Q $test.ConnectionString "SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,IsActive,IsDeleted) VALUES(1,N'علامة أولى',1,0),(2,N'علامة ثانية',1,0);SET IDENTITY_INSERT Brands OFF;")
  foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '015_CRM_WorkGuide_Brands.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}
 }
 if($IncludeManagement){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot '016_CRM_WorkGuide_Content.sql')),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
 for($i=1;$i -le 13;$i++){[void](Q $test.ConnectionString 'EXEC CRM_Save_Account_Types @Actor_ID=1,@Data=@x' @{'@x'="<row><Name_AR>نوع اختبار $i</Name_AR><Name_EN>Type $i</Name_EN><Notes>بيانات تجريبية</Notes><Is_Active>$($i%2)</Is_Active></row>"})}
 if($IncludeManagement){foreach($file in @('017_CRM_Suppliers.sql','018_CRM_Supplier_Tools.sql','019_CRM_Retire_Suppliers.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}}
 if($MultiBrandOnly){
  if(-not $IncludeManagement){throw 'MultiBrandOnly requires IncludeManagement.'}
  foreach($file in @('020_CRM_Account_Organization.sql','021_CRM_MultiBrand_WorkGuide.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}
  $result=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-AccountOrganization.sql')));$result|Format-Table -AutoSize
  $result=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-MultiBrand-WorkGuide.sql')));$result|Format-Table -AutoSize
 }
 $typeExtra=[int][bool]$IncludeManagement
 if($IncludeManagement -and -not $MultiBrandOnly){$guideSqlTests=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-WorkGuide.sql')));$guideSqlTests|Format-Table -AutoSize}
 if($IncludeManagement -and -not $MultiBrandOnly){$accessSqlTests=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-WorkGuideAccess.sql')));$accessSqlTests|Format-Table -AutoSize}
 if($IncludeManagement -and -not $MultiBrandOnly){$brandSqlTests=Q $test.ConnectionString ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Tests-WorkGuideBrands.sql')));$brandSqlTests|Format-Table -AutoSize}
 if($IncludeManagement -and -not $MultiBrandOnly){foreach($file in @('020_CRM_Account_Organization.sql','021_CRM_MultiBrand_WorkGuide.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Q $test.ConnectionString $batch)}}}}
 if($DatabaseOnly){if(-not $IncludeManagement){throw 'DatabaseOnly requires IncludeManagement.'};'PASS isolated CRM work-guide database checks.';return}
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'bin'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'Modules/CRM_Account_Types'));[void][IO.Directory]::CreateDirectory($output)
 Copy-Item -Path (Join-Path $portal 'bin/*.dll') -Destination (Join-Path $stage 'bin') -Force
 Copy-Item -LiteralPath (Join-Path $portal 'Site.Master') -Destination $stage
 $controls=Join-Path $stage 'Controls';[void][IO.Directory]::CreateDirectory($controls)
 foreach($file in @('CircularNotifications.ascx','SystemAdminWorkspace.ascx')){Copy-Item -LiteralPath (Join-Path $portal ('Controls/'+$file)) -Destination $controls}
 if($IncludeManagement){
  Copy-Item -LiteralPath (Join-Path $portal 'Customer.Master') -Destination $stage
  $customerDirectory=Join-Path $stage 'CustomerPortal';[void][IO.Directory]::CreateDirectory($customerDirectory)
  foreach($file in @('WorkGuide.aspx','WorkGuideDetail.aspx','WorkGuideFile.aspx')){Copy-Item -LiteralPath (Join-Path $portal ('CustomerPortal/'+$file)) -Destination $customerDirectory}
 }

 Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Account_Types/ManageCRMAccountTypes.aspx') -Destination (Join-Path $stage 'Modules/CRM_Account_Types')
 if($IncludeManagement){foreach($entity in @('Accounts','Contacts','Contract_Types','Payment_Methods','WorkGuide')){$directory=Join-Path $stage ('Modules/CRM_'+$entity);[void][IO.Directory]::CreateDirectory($directory);Copy-Item -LiteralPath (Join-Path $portal ('Modules/CRM_'+$entity+'/ManageCRM'+$entity.Replace('_','')+'.aspx')) -Destination $directory}}
 if($IncludeManagement){Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Accounts/Logo.aspx') -Destination (Join-Path $stage 'Modules/CRM_Accounts')}
 $assemblyPath=Join-Path $stage 'bin/CRMTypePageHost.dll'
 Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Web;
using System.Web.Hosting;
using System.Text;
public class CRMTypePageHost : MarshalByRefObject {
 class Worker : SimpleWorkerRequest {
  string targetPath,query;byte[] body;public MemoryStream Output=new MemoryStream();public int Status=200;public string ContentType,Location,RequestContentType="application/x-www-form-urlencoded";
  public Worker(string path,string query,string form,TextWriter output):base("fixture.aspx",query,output){targetPath=path;this.query=query;body=String.IsNullOrEmpty(form)?null:Encoding.UTF8.GetBytes(form);}
  public string Csrf;
  public override string[][] GetUnknownRequestHeaders(){return Csrf==null?new string[0][]:new[]{new[]{"X-CRMGuide-CSRF",Csrf}};}
  public override string GetFilePath(){return "/"+targetPath;}
  public override string GetFilePathTranslated(){return Path.Combine(HttpRuntime.AppDomainAppPath,targetPath.Replace('/',Path.DirectorySeparatorChar));}
  public override string GetPathInfo(){return "";}
  public override string GetUriPath(){return "/"+targetPath;}
  public override string GetRawUrl(){return "/"+targetPath+(query.Length==0?"":"?"+query);}
  public override string GetHttpVerbName(){return body==null?"GET":"POST";}
  public override byte[] GetPreloadedEntityBody(){return body;}
  public override int GetPreloadedEntityBodyLength(){return body==null?0:body.Length;}
  public override bool IsEntireEntityBodyIsPreloaded(){return true;}
  public override int GetTotalEntityBodyLength(){return body==null?0:body.Length;}
  public override void SendResponseFromMemory(byte[] data,int length){Output.Write(data,0,length);}
  public override void SendStatus(int code,string description){Status=code;}
  public void SetBody(byte[] value,string type){body=value;RequestContentType=type;}
  public override void SendKnownResponseHeader(int index,string value){if(index==GetKnownResponseHeaderIndex("Content-Type"))ContentType=value;if(index==GetKnownResponseHeaderIndex("Location"))Location=value;}
  public override string GetKnownRequestHeader(int index){
   if(index==HeaderCookie)return "ASP.NET_SessionId=abcdefghijklmnopqrstuvwx";
   if(index==HeaderUserAgent)return "Mozilla/5.0 Chrome/130.0.0.0 Safari/537.36";
   if(body!=null&&index==HeaderContentType)return RequestContentType;
   if(body!=null&&index==HeaderContentLength)return body.Length.ToString();
   return base.GetKnownRequestHeader(index);
  }
 }
 public int LastStatus;public string LastContentType,LastLocation,LastTrace;public byte[] LastBytes;
 public string GuideFile(string target,string token){var parts=target.TrimStart('/').Split(new char[]{'?'},2);var worker=new Worker(parts[0],parts.Length>1?parts[1]:"","x=1",new StringWriter());worker.Csrf=token;return Run(worker);}

 string Run(Worker worker){using(var trace=new StringWriter()){var listener=new System.Diagnostics.TextWriterTraceListener(trace);System.Diagnostics.Trace.Listeners.Add(listener);try{HttpRuntime.ProcessRequest(worker);}finally{listener.Flush();System.Diagnostics.Trace.Listeners.Remove(listener);LastTrace=trace.ToString();listener.Dispose();}}LastStatus=worker.Status;LastContentType=worker.ContentType;LastLocation=worker.Location;LastBytes=worker.Output.ToArray();return Encoding.UTF8.GetString(LastBytes);}
 public string Request(string target,string form){var parts=target.TrimStart('/').Split(new char[]{'?'},2);return Run(new Worker(parts[0],parts.Length>1?parts[1]:"",form,new StringWriter()));}
 public string Upload(string target,string form,string filename,byte[] file){return UploadField(target,form,filename,file,"logoUpload");}
 public string UploadField(string target,string form,string filename,byte[] file,string field){
  string boundary="CRMFixture"+Guid.NewGuid().ToString("N");var parts=target.TrimStart('/').Split(new char[]{'?'},2);var worker=new Worker(parts[0],parts.Length>1?parts[1]:"",null,new StringWriter());
  using(var bytes=new MemoryStream()){
   Action<string> write=s=>{var b=Encoding.UTF8.GetBytes(s);bytes.Write(b,0,b.Length);};
   foreach(var pair in form.Split('&')){var kv=pair.Split(new char[]{'='},2);write("--"+boundary+"\r\nContent-Disposition: form-data; name=\""+HttpUtility.UrlDecode(kv[0])+"\"\r\n\r\n"+HttpUtility.UrlDecode(kv.Length>1?kv[1]:"")+"\r\n");}
   write("--"+boundary+"\r\nContent-Disposition: form-data; name=\"ctl00$ContentPlaceHolder1$"+field+"\"; filename=\""+filename+"\"\r\nContent-Type: image/png\r\n\r\n");bytes.Write(file,0,file.Length);write("\r\n--"+boundary+"--\r\n");worker.SetBody(bytes.ToArray(),"multipart/form-data; boundary="+boundary);
  }return Run(worker);
 }
 public override object InitializeLifetimeService(){return null;}
}
public class CRMTypeTestIdentity : IHttpModule {
 public void Init(HttpApplication app){app.PostAcquireRequestState+=(s,e)=>{var c=HttpContext.Current;if(c.Session!=null){if(c.Request.QueryString["testActor"]!=null)CRM.CustomerPortalData.Current=null;
 int customer;if(int.TryParse(c.Request.QueryString["testCustomer"],out customer)){
 if(customer==0){CRM.CustomerPortalData.Current=null;}else{var row=CRM.CustomerPortalData.Query("dbo.Fixture_CustomerIdentity",CRM.CustomerPortalData.P("@ID",System.Data.SqlDbType.Int,customer)).Rows[0];CRM.CustomerPortalData.Current=new CRM.CustomerIdentity{AccountID=customer,Name="عميل اختبار",Stamp=(Guid)row["SecurityStamp"]};}
 }
 int actor; if(!int.TryParse(c.Request.QueryString["testActor"],out actor))actor=1;CRM.SessionManager.GetInstance.Users=actor==0?null:new CRM.UserEntity{UserID=actor,UserType=actor==1?1:4,NameAr="اختبار الصفحة"};}};}
 public void Dispose(){}
}
'@ -ReferencedAssemblies @('System.Web','System.Data','System.Xml',(Join-Path $stage 'bin/CRM.dll')) -OutputAssembly $assemblyPath
 $entry=$config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection';$entry.connectionString=$test.ConnectionString
 $web=$config.configuration.'system.web';$modules=$web.httpModules
 if($null -eq $modules){$modules=$config.CreateElement('httpModules');[void]$web.AppendChild($modules)}
 $module=$config.CreateElement('add');$module.SetAttribute('name','CRMTypeTestIdentity');$module.SetAttribute('type','CRMTypeTestIdentity, CRMTypePageHost');[void]$modules.AppendChild($module)

 if($IncludeManagement){
  $converter=Join-Path $portal 'App_Data/Tools/LibreOffice/program/soffice.exe'
  if(Test-Path -LiteralPath $converter){$setting=$config.CreateElement('add');$setting.SetAttribute('key','CRMWorkGuide.ConverterPath');$setting.SetAttribute('value',$converter);[void]$config.configuration.appSettings.AppendChild($setting)}
 }
 $config.Save((Join-Path $stage 'Web.config'))
 $hostType=[Reflection.Assembly]::LoadFrom($assemblyPath).GetType('CRMTypePageHost')
 $hostObject=[Web.Hosting.ApplicationHost]::CreateApplicationHost($hostType,'/',$stage)
 if($MultiBrandOnly){. (Join-Path $PSScriptRoot 'Test-CRM-MultiBrandFlows.ps1')}else{
 if(-not $AccessOnly -and -not $GuideOnly){
 $html=$hostObject.Request($target,$null);CheckHtml $html;Assert ((CountRows $html) -eq (13+$typeExtra)) 'Initial records missing.'
 CheckCounts $html (13+$typeExtra) (7+$typeExtra) 6
 Assert ($html -notmatch 'return confirm\(' -and $html -match '/assets/js/crm-list.js' -and $html -match 'id="pnlSearch"') 'Search/modal markup regression.'
 Assert ($html -notmatch 'href="(?:Add|Edit)CRMAccountTypes') 'Standalone editor links remain.'
 [IO.File]::WriteAllText((Join-Path $output 'list.html'),$html,[Text.UTF8Encoding]::new($true))
 $html=Post $html ($prefix+'btnSearch') @{'filterName'='Type 1'}
 Assert ((CountRows $html) -eq 5) 'English name search failed.'
 CheckCounts $html (13+$typeExtra) (7+$typeExtra) 6
 $html=Post $html ($prefix+'btnSearch') @{'filterStatus'='0'}
 Assert ((CountRows $html) -eq 6) 'Status filtering failed.'
 $html=Post $html ($prefix+'btnReset');Assert ((CountRows $html) -eq (13+$typeExtra)) 'Search reset failed.'
 'PASS initial render, English search, status filter and reset.'
 $html=Post $html ($prefix+'btnNewType')
 Assert ($html -match "getOrCreateInstance\(panel\).show") 'Editor did not reopen.'
 [IO.File]::WriteAllText((Join-Path $output 'editor.html'),$html,[Text.UTF8Encoding]::new($true))
 $html=Post $html ($prefix+'btnSaveType') (EditorValues '')
 Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Types').Rows[0].N -eq (13+$typeExtra)) 'Required validation wrote a row.'
 Assert ($html -match 'أدخل اسم النوع بالعربية') 'Required validation not rendered.'
 $name='نوع تمت إضافته من القائمة'
 $html=Post $html ($prefix+'btnSaveType') (EditorValues $name)
 Assert ($html -match 'تمت إضافة نوع العميل بنجاح' -and $html -match 'alert-success alert-dismissible') 'Create success alert missing.'
 $row=(Q $test.ConnectionString 'SELECT ID,Name_AR,Is_Active FROM CRM_Account_Types WHERE Name_AR=@n' @{'@n'=$name}).Rows[0];$id=[int]$row.ID
 Assert ($id -gt 0 -and $row.Is_Active -and (CountRows $html) -eq (14+$typeExtra)) 'Inline create/list refresh failed.'
 CheckCounts $html (14+$typeExtra) (8+$typeExtra) 6
 $html=Post $html (Action $html 'تعديل')
 Assert ($html -match ([regex]::Escape($name))) 'Edit form values missing.'
 $html=Post $html ($prefix+'btnSaveType') (EditorValues ($name+' معدل') 'ملاحظات & محفوظة')
 Assert ($html -match 'تم حفظ تعديلات نوع العميل بنجاح' -and $html -match 'ملاحظات &amp; محفوظة') 'Inline edit / output encoding failed.'
 'PASS required validation, create, edit, encoded output and no redirects.'
 $html=Post $html ($prefix+'btnNewType')
 $html=Post $html ($prefix+'btnSaveType') (EditorValues 'نوع اختبار 1')
 Assert ($html -match 'alert-danger alert-dismissible' -and $html -match "getOrCreateInstance\(panel\).show") 'Duplicate alert/editor state missing.'
 Assert ((Q $test.ConnectionString 'SELECT COUNT(*) N FROM CRM_Account_Types').Rows[0].N -eq (14+$typeExtra)) 'Duplicate row inserted.'
 $html=Post $html (Action $html 'تعديل')
 [void](Q $test.ConnectionString "UPDATE CRM_Account_Types SET Notes=N'تعديل متزامن' WHERE ID=@id" @{'@id'=$id})
 $html=Post $html ($prefix+'btnSaveType') (EditorValues 'محاولة قديمة')
 Assert ($html -match 'تم تعديل السجل أو إلغاؤه' -and $html -match 'value="محاولة قديمة"') 'Stale version/form retention failed.'
 Assert ((Q $test.ConnectionString 'SELECT Notes FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Notes -eq 'تعديل متزامن') 'Concurrent edit overwritten.'
 $html=Post $html (Action $html 'إيقاف');Assert ($html -match 'alert-success alert-dismissible') 'Row action alert missing.'
 Assert (-not (Q $test.ConnectionString 'SELECT Is_Active FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Is_Active) 'Deactivate failed.'
 CheckCounts $html (14+$typeExtra) (7+$typeExtra) 7
 $html=Post $html (Action $html 'تفعيل')
 Assert ((Q $test.ConnectionString 'SELECT Is_Active FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Is_Active) 'Activate failed.'
 CheckCounts $html (14+$typeExtra) (8+$typeExtra) 6
 $html=Post $html (Action $html 'حذف')
 Assert ($html -match 'function openDelete' -and $html -match 'id="typeDeleteModal"' -and $html -match 'نوع تمت إضافته من القائمة معدل') 'Delete confirmation modal missing.'
 Assert (-not (Q $test.ConnectionString 'SELECT Is_Deleted FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Is_Deleted) 'Delete occurred before confirmation.'
 [IO.File]::WriteAllText((Join-Path $output 'delete.html'),$html,[Text.UTF8Encoding]::new($true))
 [void](Q $test.ConnectionString "UPDATE CRM_Account_Types SET Notes=N'تعديل قبل تأكيد الحذف' WHERE ID=@id" @{'@id'=$id})
 $html=Post $html ($prefix+'btnConfirmDelete')
 Assert ($html -match 'alert-danger alert-dismissible' -and -not (Q $test.ConnectionString 'SELECT Is_Deleted FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Is_Deleted) 'Stale modal deleted changed row.'
 $html=Post $html (Action $html 'حذف')
 $html=Post $html ($prefix+'btnConfirmDelete')
 Assert ((Q $test.ConnectionString 'SELECT Is_Deleted FROM CRM_Account_Types WHERE ID=@id' @{'@id'=$id}).Rows[0].Is_Deleted -and (CountRows $html) -eq (13+$typeExtra)) 'Delete/list refresh failed.'
 CheckCounts $html (13+$typeExtra) (7+$typeExtra) 6
 $html=Post $html ($prefix+'btnConfirmDelete')
 Assert ($html -match 'اختر العنصر المراد حذفه' -and (CountRows $html) -eq (13+$typeExtra)) 'Delete confirmation could be reused.'
 $html=$hostObject.Request($target+'?testActor=2',$null);CheckHtml $html
 Assert ($html -match 'مدير النظام فقط' -and $html -notmatch 'id="typeEditor"') 'Nonadministrator reached type editor.'
 'PASS counts independent of filters, count refresh, duplicate/stale protection, retained input, activate/deactivate, modal confirmation/stale/replay rejection and administrator authorization.'
 if($IncludeManagement){. (Join-Path $PSScriptRoot 'Test-CRM-ManagementFlows.ps1')}
 if($IncludeManagement){. (Join-Path $PSScriptRoot 'Test-CRM-CatalogFlows.ps1');. (Join-Path $PSScriptRoot 'Test-CRM-WorkGuideFlows.ps1')}
 if($IncludeManagement){
  $logDirectory=Join-Path $stage 'Modules/CRM_Activity_Logs';[void][IO.Directory]::CreateDirectory($logDirectory)
  Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Activity_Logs/ManageCRMActivityLogs.aspx') -Destination $logDirectory
  [void]$hostObject.Request('/Modules/CRM_Activity_Logs/ManageCRMActivityLogs.aspx?testActor=1',$null)
  Assert ($hostObject.LastStatus -eq 302 -and $hostObject.LastLocation -match 'Overview.aspx#crmActivity') 'Legacy activity route must open the embedded Overview log.'
  Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Account_Types/Overview.aspx') -Destination (Join-Path $stage 'Modules/CRM_Account_Types')
  $logHtml=$hostObject.Request('/Modules/CRM_Account_Types/Overview.aspx?testActor=1',$null)
  [IO.File]::WriteAllText((Join-Path $output 'activity.html'),$logHtml,[Text.UTF8Encoding]::new($true));CheckHtml $logHtml
  Assert ($logHtml -match 'المصدر' -and $logHtml -match 'إدارة النظام') 'Unified administrator audit list/source failed.'
  [IO.File]::WriteAllText((Join-Path $output 'activity.html'),$logHtml,[Text.UTF8Encoding]::new($true))
  Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Accounts/CustomerAccess.aspx') -Destination (Join-Path $stage 'Modules/CRM_Accounts')
  [void](Q $test.ConnectionString "DECLARE @Hash varbinary(32)=CRYPT_GEN_RANDOM(32),@Salt varbinary(32)=CRYPT_GEN_RANDOM(32);EXEC Customer_SaveLogin @Actor=1,@AccountID=1,@Username=N'history-audit-test',@Hash=@Hash,@Salt=@Salt;")
  $accessHtml=$hostObject.Request('/Modules/CRM_Accounts/CustomerAccess.aspx?id=1&testActor=1',$null)
  [IO.File]::WriteAllText((Join-Path $output 'customer-access.html'),$accessHtml,[Text.UTF8Encoding]::new($true));CheckHtml $accessHtml
  Assert ($accessHtml -match 'المصدر' -and $accessHtml -match 'تحديث بيانات الدخول') 'Customer administration unified history failed.'
  'PASS unified CRM activity/history render with source, safe credential snapshots and administrator permissions.'
  . (Join-Path $PSScriptRoot 'Test-CRM-ActivityFlows.ps1')
 }

 }
 if($GuideOnly){. (Join-Path $PSScriptRoot 'Test-CRM-WorkGuideFlows.ps1')}
 if($IncludeManagement){. (Join-Path $PSScriptRoot 'Test-CRM-WorkGuideAccessFlows.ps1');. (Join-Path $PSScriptRoot 'Test-CRM-WorkGuideBrandFlows.ps1');. (Join-Path $PSScriptRoot 'Test-CRM-WorkGuideContentFlows.ps1')}
 }
 'All UI test writes were limited to the isolated database.'
 $completed=$true
 if($KeepDatabase){
  # Retain only a successfully tested synthetic fixture for local browser QA.
  [IO.File]::WriteAllText((Join-Path $output 'stage.txt'),$stage)
  [IO.File]::WriteAllText((Join-Path $output 'database.txt'),$testName)
  Write-Output ('Retained synthetic fixture: '+$testName+' | '+$stage)
 }
} finally {
 if($created -and (-not $KeepDatabase -or -not $completed) -and $testName -match '^Prosto_CRM_Page_Test_[a-f0-9]{32}$') {
  [Data.SqlClient.SqlConnection]::ClearAllPools();[void](Q $master.ConnectionString "ALTER DATABASE [$testName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$testName]")
 }
}
