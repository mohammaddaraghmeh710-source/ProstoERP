param([switch]$KeepDatabase,[switch]$PresentationOnly)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -eq 'Core'){throw 'Run this System.Web test with Windows PowerShell 5.1 (powershell.exe), not pwsh.'}
Add-Type -AssemblyName System.Web
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$portal=Join-Path $root 'src/Portal'
$config=[xml](Get-Content -LiteralPath (Join-Path $portal 'Web.config'))
$source=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
if($source.DataSource -notin @('localhost','.','(local)')){throw 'Only local SQL Server is supported.'}
$name='Prosto_CorrespondenceWorkspace_Test_'+[guid]::NewGuid().ToString('N')
$master=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$master['Initial Catalog']='master'
$test=[Data.SqlClient.SqlConnectionStringBuilder]::new($source.ConnectionString);$test['Initial Catalog']=$name
$stage=[IO.Path]::GetFullPath((Join-Path $root ('../tmp/correspondence-workspace-'+[guid]::NewGuid().ToString('N'))))
$output=[IO.Path]::GetFullPath((Join-Path $root '../tmp/correspondence-workspace-results'));[void][IO.Directory]::CreateDirectory($output)
function Query([string]$connection,[string]$sql,[hashtable]$parameters=@{}){
 $cn=[Data.SqlClient.SqlConnection]::new($connection)
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=120;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$dt=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($dt);return ,$dt}finally{$cn.Dispose()}
}
function Assert([bool]$ok,[string]$message){if(!$ok){throw $message};"PASS: $message"}
function Attribute([string]$html,[string]$name){$m=[regex]::Match($html,'\b'+[regex]::Escape($name)+'\s*=\s*(["''])(.*?)\1','Singleline,IgnoreCase');return [Web.HttpUtility]::HtmlDecode($m.Groups[2].Value)}
function Values([string]$html){
 $data=@{}
 foreach($input in [regex]::Matches($html,'<input\b[^>]*>','IgnoreCase')){$tag=$input.Value;$key=Attribute $tag 'name';$kind=Attribute $tag 'type';if(!$key -or $kind -in @('file','submit','button','reset')){continue};if($kind -in @('checkbox','radio') -and $tag -notmatch '\bchecked\b'){continue};$data[$key]=Attribute $tag 'value'}
 foreach($textarea in [regex]::Matches($html,'<textarea\b([^>]*)>(.*?)</textarea>','Singleline,IgnoreCase')){$key=Attribute $textarea.Groups[1].Value 'name';if($key){$data[$key]=[Web.HttpUtility]::HtmlDecode($textarea.Groups[2].Value)}}
 foreach($select in [regex]::Matches($html,'<select\b([^>]*)>(.*?)</select>','Singleline,IgnoreCase')){$key=Attribute $select.Groups[1].Value 'name';$options=@([regex]::Matches($select.Groups[2].Value,'<option\b([^>]*)>(.*?)</option>','Singleline,IgnoreCase'));$chosen=@($options|Where-Object {$_.Groups[1].Value -match '\bselected\b'});if(!$chosen.Count -and $options.Count){$chosen=@($options[0])};if($key -and $chosen.Count){$data[$key]=Attribute $chosen[0].Groups[1].Value 'value'}}
 return $data
}
function Page([string]$url){
 $html=$script:hostObject.Request($url,$null,$false)
 if($script:hostObject.Status -ge 500 -or $html -match 'Server Error|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'error.html'),$html);throw 'Page rendering failed; see tmp/correspondence-workspace-results/error.html'}
 return $html
}
function DecodeDelta([string]$delta){
 $items=@();$offset=0
 while($offset -lt $delta.Length){$end=$delta.IndexOf('|',$offset);if($end -lt 0){throw 'Invalid AJAX delta length.'};$length=[int]$delta.Substring($offset,$end-$offset);$offset=$end+1;$end=$delta.IndexOf('|',$offset);$kind=$delta.Substring($offset,$end-$offset);$offset=$end+1;$end=$delta.IndexOf('|',$offset);$id=$delta.Substring($offset,$end-$offset);$offset=$end+1;if($offset+$length -ge $delta.Length){throw 'Truncated AJAX delta.'};$value=$delta.Substring($offset,$length);$offset+=$length+1;$items+=@{Kind=$kind;ID=$id;Value=$value}}
 return $items
}
function Client([string]$url){
 $html=Page $url
 return @{Url=$url;Html=$html;Values=(Values $html);ScriptManager=[regex]::Match($html,'PageRequestManager\._initialize\([''"]([^''"]+)').Groups[1].Value}
}
function Post($client,[string]$button,[hashtable]$overrides=@{},[string]$panel='upConversation'){
 $data=@{};foreach($key in $client.Values.Keys){$data[$key]=$client.Values[$key]}
 foreach($key in $overrides.Keys){$data['ctl00$ContentPlaceHolder1$'+$key]=[string]$overrides[$key]}
 $target=if($button.StartsWith('ctl00$')){$button}else{'ctl00$ContentPlaceHolder1$'+$button}
 $data['__EVENTTARGET']=$target;$data['__EVENTARGUMENT']='';$data['__ASYNCPOST']='true';$data[$client.ScriptManager]='ctl00$ContentPlaceHolder1$'+$panel+'|'+$target
 $body=($data.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode([string]$_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
 $delta=$script:hostObject.Request($client.Url,$body,$true)
 if($script:hostObject.Status -ne 200 -or $delta -match '\|error\|'){[IO.File]::WriteAllText((Join-Path $output 'ajax-error.txt'),$delta);throw 'AJAX request failed; see tmp/correspondence-workspace-results/ajax-error.txt'}
 Assert ($delta -match '\|updatePanel\|' -and $delta -notmatch '\|pageRedirect\|' -and $script:hostObject.ContentType -like 'text/plain*') 'Workspace action returns panel deltas without redirect'|Out-Host
 foreach($item in (DecodeDelta $delta)){
  if($item.Kind -eq 'hiddenField'){$client.Values[$item.ID]=$item.Value}
  if($item.Kind -eq 'updatePanel'){$values=Values $item.Value;foreach($key in $values.Keys){$client.Values[$key]=$values[$key]};$client.Html=$item.Value}
 }
 return $delta
}
$created=$false;$passed=$false
try{
 # Copy empty table shapes and defaults only. No application rows or credentials are copied.
 [void](Query $master.ConnectionString "CREATE DATABASE [$name]");$created=$true
 $sourceName=$source.InitialCatalog.Replace(']',']]')
 foreach($table in @('UsersMembers','Users_Types','Brands','Branches','Departments','JobTitles','Shift','Correspondence_Threads','Correspondence_Thread_Messages','Correspondence_Message_Attachments','Correspondence_Notifications')){
  [void](Query $test.ConnectionString "SELECT TOP(0) * INTO dbo.[$table] FROM [$sourceName].dbo.[$table]; ALTER TABLE dbo.[$table] ADD PRIMARY KEY(ID)")
  $defaults=Query $source.ConnectionString "SELECT c.name Col,d.definition Def FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id WHERE d.parent_object_id=OBJECT_ID('dbo.$table')"
  foreach($value in $defaults.Rows){[void](Query $test.ConnectionString "ALTER TABLE dbo.[$table] ADD DEFAULT $($value.Def) FOR [$($value.Col)]")}
 }
 foreach($file in @('002_Page_Operations.sql','003_Module_Procedures.sql','004_Independent_Procedures.sql','005_Search_Fields.sql','006_Governance.sql','007_Catalogs.sql')){foreach($batch in [regex]::Split([IO.File]::ReadAllText((Join-Path $PSScriptRoot $file)),'(?im)^\s*GO\s*$')){if($batch.Trim()){[void](Query $test.ConnectionString $batch)}}}
 [void](Query $test.ConnectionString @'
SET IDENTITY_INSERT Users_Types ON;INSERT Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'مدير نظام تجريبي','Test administrator',1,0),(2,N'مدير فرع تجريبي','Test manager',1,0),(4,N'موظف تجريبي','Test employee',1,0);SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'علامة تجريبية','Test brand',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,1,N'فرع تجريبي','Test branch',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT UsersMembers ON;INSERT UsersMembers(ID,Type,FullName_Ar,Fullname_En,UserName,Brand_ID,Branch_ID,Shif_ID,IsActive,IsDeleted) VALUES(1,1,N'مدير النظام التجريبي','Test administrator','workspace-admin',1,1,1,1,0),(2,2,N'مدير الفرع التجريبي','Test manager','workspace-manager',1,1,1,1,0),(3,4,N'الموظف التجريبي','Test recipient','workspace-recipient',1,1,1,1,0),(4,2,N'مدير مستقل','Unrelated manager','workspace-outsider',1,1,1,1,0),(5,4,N'مستلم مستقل','Unrelated recipient','workspace-other',1,1,1,1,0);SET IDENTITY_INSERT UsersMembers OFF;
EXEC Insert_Correspondence_Thread @Actor=2,@Brand=0,@Recipients=N'<items><item id="3"/></items>',@Title=N'اختبار المحادثة الأولى',@Brief=N'ملخص المراسلة الأولى',@Body=N'رسالة افتتاحية أولى',@RequiresCompletion=1,@DueDate=NULL,@Files=NULL;
EXEC Insert_Correspondence_Thread @Actor=2,@Brand=0,@Recipients=N'<items><item id="3"/></items>',@Title=N'اختبار المحادثة الثانية',@Brief=N'ملخص المراسلة الثانية',@Body=N'رسالة افتتاحية ثانية',@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;
EXEC Insert_Correspondence_Thread @Actor=4,@Brand=0,@Recipients=N'<items><item id="5"/></items>',@Title=N'مراسلة خاصة مستقلة',@Brief=NULL,@Body=N'محتوى سري مستقل',@RequiresCompletion=0,@DueDate=NULL,@Files=NULL;
'@)
 $threads=Query $test.ConnectionString 'SELECT ID,Title FROM Correspondence_Threads ORDER BY ID';$first=[int]$threads.Rows[0].ID;$second=[int]$threads.Rows[1].ID;$private=[int]$threads.Rows[2].ID
 [void](Query $test.ConnectionString "EXEC Insert_Correspondence_Thread_Message @Actor=3,@ThreadID=$first,@Body=N'رد الموظف في الأولى',@Files=NULL")
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'bin'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'Modules/Correspondence'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'Controls'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'FileManager/Correspondence'))
 Copy-Item -Path (Join-Path $portal 'bin/*.dll') -Destination (Join-Path $stage 'bin') -Force
 Copy-Item -Path (Join-Path $portal 'Controls/*.ascx') -Destination (Join-Path $stage 'Controls') -Force
 foreach($file in @('Site.Master','CircularNotifications.aspx','Login.aspx','Customer.Master')){Copy-Item -LiteralPath (Join-Path $portal $file) -Destination $stage}
 Copy-Item -Path (Join-Path $portal 'Modules/Correspondence/*.aspx') -Destination (Join-Path $stage 'Modules/Correspondence')
 foreach($folder in @('assets','ckeditor','fonts')){New-Item -ItemType Junction -Path (Join-Path $stage $folder) -Target (Join-Path $portal $folder)|Out-Null}
 ($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString=$test.ConnectionString
 foreach($parent in @($config.configuration.'system.web',$config.configuration.'system.webServer')){
  $element=if($parent.Name -eq 'system.web'){'httpModules'}else{'modules'};$modules=$parent.SelectSingleNode($element);if($null -eq $modules){$modules=$config.CreateElement($element);[void]$parent.AppendChild($modules)}
  $module=$config.CreateElement('add');$module.SetAttribute('name','CorrespondenceWorkspaceIdentity');$module.SetAttribute('type','CorrespondenceWorkspaceIdentity, CorrespondenceWorkspaceTests');[void]$modules.AppendChild($module)
 }
 $config.Save((Join-Path $stage 'Web.config'))
 $assembly=Join-Path $stage 'bin/CorrespondenceWorkspaceTests.dll'
 Add-Type -Path (Join-Path $PSScriptRoot 'CorrespondenceWorkspaceTests.cs') -ReferencedAssemblies @('System.Web','System.Configuration','System.Data',(Join-Path $stage 'bin/CRM.dll')) -OutputAssembly $assembly
 $type=[Reflection.Assembly]::LoadFrom($assembly).GetType('CorrespondenceWorkspaceHost');$script:hostObject=[Web.Hosting.ApplicationHost]::CreateApplicationHost($type,'/',$stage)
 if($PresentationOnly){
  # Exercise only the newly affected readers and catalog AJAX editor, not the legacy workflow suite.
  $dashboard=Page '/Modules/Correspondence/Dashboard.aspx?workspaceActor=1'
  Assert ($script:hostObject.Status -eq 200 -and $dashboard.Contains('لوحة إدارة المراسلات') -and $dashboard.Contains('Catalogs.aspx?kind=P') -and $dashboard.Contains('Catalogs.aspx?kind=R') -and $dashboard.Contains('إجمالي المراسلات') -and $dashboard.Contains('card h-100')) 'Administrator dashboard renders correspondence statistics and catalog links'
  Assert ($dashboard -notmatch 'href=["\x27][^"\x27]*scope=all' -and $dashboard -notmatch 'id=["\x27]ERPTable["\x27]') 'Dashboard keeps global statistics read-only without oversight links or a global conversation queue'
  [IO.File]::WriteAllText((Join-Path $output 'dashboard.html'),$dashboard,[Text.UTF8Encoding]::new($true))
  [void]$script:hostObject.Request('/Modules/Correspondence/Dashboard.aspx?workspaceActor=2',$null,$false)
  Assert ($script:hostObject.Status -eq 403) 'Employee cannot open the administrator correspondence dashboard'
  $workspace=Page ('/Modules/Correspondence/ManageCorrespondence.aspx?workspaceActor=2&draft='+[guid]::NewGuid().ToString('N'))
  Assert ($script:hostObject.Status -eq 200 -and $workspace.Contains('correspondence-fullscreen') -and $workspace.Contains('id="txtTitleSearch"') -and $workspace.Contains('id="txtPerson"') -and $workspace.Contains('data-search-text=') -and $workspace.Contains('data-person=') -and $workspace.Contains('id="correspondence-search-count"')) 'Personal workspace exposes local title, counterpart and number search with the compact shell'
  Assert ($workspace.Contains('اختبار المحادثة الأولى') -and $workspace.Contains('اختبار المحادثة الثانية') -and -not $workspace.Contains('مراسلة خاصة مستقلة')) 'Local search dataset retains the existing personal visibility boundary'
  [IO.File]::WriteAllText((Join-Path $output 'list.html'),$workspace,[Text.UTF8Encoding]::new($true))
  [void]$script:hostObject.Request('/Modules/Correspondence/ManageCorrespondence.aspx?workspaceActor=1&scope=all',$null,$false)
  Assert ($script:hostObject.Status -eq 302 -and $script:hostObject.Location -match '(?:^|/)Dashboard\.aspx(?:\?|$)') 'Deferred administrator oversight route returns to the read-only dashboard before rendering conversations'
  [void]$script:hostObject.Request('/Modules/Correspondence/ManageCorrespondence.aspx?workspaceActor=2&scope=all',$null,$false)
  Assert ($script:hostObject.Status -eq 403) 'Nonadministrator cannot use the deferred oversight route'
  foreach($kind in @('P','R')){
   $catalogUrl='/Modules/Correspondence/Catalogs.aspx?workspaceActor=1&kind='+$kind
   $catalog=Client $catalogUrl
   Assert ($script:hostObject.Status -eq 200 -and $catalog.Html.Contains('id="ERPTable"') -and $catalog.Html.Contains('correspondenceCatalogEditor') -and $catalog.Html.Contains('data-catalog-total=')) "Catalog $kind renders the approved table, statistics and same-page editor"
   [void]$script:hostObject.Request(('/Modules/Correspondence/Catalogs.aspx?workspaceActor=2&kind='+$kind),$null,$false)
   Assert ($script:hostObject.Status -eq 403) "Catalog $kind management remains administrator-only"
   # Restore the administrator identity and fresh Web Forms state after the denied employee request.
   $catalog=Client $catalogUrl
   $before=Query $test.ConnectionString 'SELECT COUNT(*) Total FROM dbo.Correspondence_Catalog WHERE Kind=@Kind AND IsDeleted=0' @{Kind=$kind}
   $expectedTotal=[int]$before.Rows[0].Total+1
   $delta=Post $catalog 'btnNew' @{} 'upCatalog'
   Assert ($delta.Contains('upEditor')) "Catalog $kind add opens the existing editor through an AJAX panel"
   $newTitle='خيار عرض تجريبي '+$kind
   $saveValues=@{txtTitle=$newTitle;txtOrder='33';chkActive='on'}
   if($kind -eq 'R'){$saveValues.ddlBehavior='normal'}
   $delta=Post $catalog 'btnSave' $saveValues 'upEditor'
   $saved=Query $test.ConnectionString 'SELECT ID,Title,IsActive FROM dbo.Correspondence_Catalog WHERE Kind=@Kind AND Title=@Title AND IsDeleted=0' @{Kind=$kind;Title=$newTitle}
   Assert ($saved.Rows.Count -eq 1 -and $delta.Contains($newTitle) -and $delta.Contains('ERPTable') -and $delta.Contains(('data-catalog-total="'+$expectedTotal+'"'))) "Catalog $kind AJAX save refreshes the persisted list and statistics"
   $catalog=Client $catalogUrl
   $savedID=[int]$saved.Rows[0].ID
   $row=[regex]::Match($catalog.Html,('<tr\b[^>]*\bdata-catalog-id="'+$savedID+'"[^>]*>.*?</tr>'),'Singleline,IgnoreCase').Value
   $editLink=[regex]::Match($row,'<a\b[^>]*\baria-label="تعديل"[^>]*>','Singleline,IgnoreCase').Value
   $editTarget=[regex]::Match((Attribute $editLink 'href'),"__doPostBack\('([^']+)'",'IgnoreCase').Groups[1].Value
   Assert ($editTarget.StartsWith('ctl00$')) "Catalog $kind exposes the existing authorized edit command"
   $delta=Post $catalog $editTarget @{} 'upCatalog'
   Assert ($delta.Contains('upEditor') -and $delta.Contains($newTitle)) "Catalog $kind edit loads the chosen row through AJAX"
   $catalog.Values.Remove('ctl00$ContentPlaceHolder1$chkActive')
   $editedTitle=$newTitle+' معدل'
   $saveValues=@{txtTitle=$editedTitle;txtOrder='35'}
   if($kind -eq 'R'){$saveValues.ddlBehavior='normal'}
   $delta=Post $catalog 'btnSave' $saveValues 'upEditor'
   $edited=Query $test.ConnectionString 'SELECT Title,IsActive FROM dbo.Correspondence_Catalog WHERE ID=@ID AND IsDeleted=0' @{ID=$savedID}
   Assert ($edited.Rows.Count -eq 1 -and [string]$edited.Rows[0].Title -eq $editedTitle -and -not [bool]$edited.Rows[0].IsActive -and $delta.Contains($editedTitle) -and $delta.Contains('data-catalog-active="0"') -and $delta.Contains(('data-catalog-total="'+$expectedTotal+'"'))) "Catalog $kind AJAX edit refreshes the same row, active state and counts without navigation"
  }
  $editorToken=[guid]::NewGuid().ToString('N')
  $create=Client ('/Modules/Correspondence/AddCorrespondence.aspx?workspaceActor=2&editor='+$editorToken+'&draft='+[guid]::NewGuid().ToString('N'))
  $recipientSelect=[regex]::Match($create.Html,'<select\b[^>]*\bname="[^"]*\$lstRecipients"[^>]*>(.*?)</select>','Singleline,IgnoreCase')
  $recipientOptions=@([regex]::Matches($recipientSelect.Groups[1].Value,'<option\b[^>]*>','IgnoreCase'))
  Assert ($script:hostObject.Status -eq 200 -and $create.Html.Contains('upEditor') -and $recipientOptions.Count -gt 0) 'Embedded creation renders the existing authorized recipient options'
  $recipient=Attribute $recipientOptions[0].Value 'value'
  Assert ($recipient -match '^[1-9][0-9]*$') 'Embedded creation uses a real allowed recipient from its rendered form'
  $createdTitle='اختبار الإنشاء من النافذة الجانبية'
  $delta=Post $create 'btnSave' @{lstRecipients=$recipient;txtTitle=$createdTitle;txtBrief='ملخص تجريبي';txtBody='رسالة تجريبية من النموذج الجانبي';ddlPriority='1';ddlKind='1'} 'upEditor'
  $createdThread=Query $test.ConnectionString 'SELECT ID FROM dbo.Correspondence_Threads WHERE Title=@Title AND CreatedBy=2' @{Title=$createdTitle}
  Assert ($createdThread.Rows.Count -eq 1 -and $delta.Contains('upEditor') -and $delta.Contains('correspondence-created') -and $delta.Contains($editorToken) -and $delta.Contains(('"ids":['+[int]$createdThread.Rows[0].ID+']'))) 'Embedded AJAX creation persists one thread and returns its ID in the nonce-bound callback without redirect'
  [IO.File]::WriteAllText((Join-Path $output 'stage.txt'),$stage);[IO.File]::WriteAllText((Join-Path $output 'database.txt'),$name)
  $passed=$true;"Presentation checks passed. Stage: $stage"
  if($KeepDatabase){"Isolated synthetic database retained for visual QA: $name"}
  return
 }
 $draft=[guid]::NewGuid().ToString('N');$base='/Modules/Correspondence/ManageCorrespondence.aspx';$url=$base+'?workspaceActor=2&draft='+$draft
 $client=Client $url
 Assert ($script:hostObject.Status -eq 200 -and $client.Html.Contains('اختبار المحادثة الأولى') -and $client.Html.Contains('اختبار المحادثة الثانية') -and -not $client.Html.Contains('مراسلة خاصة مستقلة')) 'Personal list keeps separate threads for the same recipient and excludes unrelated content'
 [IO.File]::WriteAllText((Join-Path $output 'list.html'),$client.Html,[Text.UTF8Encoding]::new($true))
 $client=Client ($url+'&ID='+$first)
 Assert ($client.Html -match 'id="hfThread"' -and $client.Html -match 'correspondence-messages' -and $client.Html.Contains('رسالة افتتاحية أولى')) 'A direct thread link renders the conversation workspace'
 $delta=Post $client 'btnSelectThread' @{hfThread=$second;hfNavigation='1';hfDraftText=('{"'+$first+'":"مسودة الأولى"}');txtReply='مسودة الأولى';hfVisible='1'}
 Assert ($delta.Contains('رسالة افتتاحية ثانية') -and -not $delta.Contains('رسالة افتتاحية أولى')) 'Async selection displays only the selected conversation'
 $delta=Post $client 'btnSend' @{hfThread=$private;txtReply='رد اختبار يستهدف الثانية';hfVisible='1'}
 $sent=Query $test.ConnectionString "SELECT ThreadID FROM Correspondence_Thread_Messages WHERE Body=N'رد اختبار يستهدف الثانية'"
 Assert ($sent.Rows.Count -eq 1 -and [int]$sent.Rows[0].ThreadID -eq $second) 'Sending uses the ViewState selection despite the original URL and a forged hidden thread value'
 $client=Client ($url+'&ID='+$first+'&workspaceQueue=first-fixture.pdf');$client.Url=$url+'&ID='+$first
 Assert ($client.Html -match 'id="lblQueued"[^>]*>[^<]*1') 'A staged synthetic attachment is queued for the first conversation'
 $delta=Post $client 'btnSelectThread' @{hfThread=$second;hfNavigation='1';hfVisible='1'}
 Assert ($delta -notmatch 'id="lblQueued"[^>]*>[^<]*1') 'Selecting another conversation does not show the first attachment queue'
 $delta=Post $client 'btnSelectThread' @{hfThread=$first;hfNavigation='1';hfVisible='1'}
 Assert ($delta -match 'id="lblQueued"[^>]*>[^<]*1') 'Returning to the first conversation restores its attachment queue'
 $failedText='x'*4001
 $delta=Post $client 'btnSend' @{txtReply=$failedText;hfVisible='1'}
 Assert ($delta.Contains($failedText) -and $delta -match 'id="lblQueued"[^>]*>[^<]*1') 'Rejected sends preserve reply text and the selected attachment queue'
 $client=Client ($url+'&ID='+$second+'&workspaceQueue=second-fixture.pdf');$client.Url=$url+'&ID='+$second
 $delta=Post $client 'btnSend' @{txtReply='إرسال مرفق الثانية';hfVisible='1'}
 Assert ($delta -notmatch 'id="lblQueued"[^>]*>[^<]*1') 'Successful sending clears the selected attachment queue'
 $delta=Post $client 'btnSelectThread' @{hfThread=$first;hfNavigation='1';hfVisible='1'}
 Assert ($delta -match 'id="lblQueued"[^>]*>[^<]*1') 'Successful sending leaves another conversation attachment queue intact'
 $client=Client ($base+'?workspaceActor=3&draft='+$draft+'&ID='+$second)
 [void](Query $test.ConnectionString "EXEC Insert_Correspondence_Thread_Message @Actor=2,@ThreadID=$second,@Body=N'رسالة أثناء إخفاء الصفحة',@Files=NULL")
 $delta=Post $client 'ctl00$tmCorrespondenceCount' @{hfVisible='0'}
 $unread=Query $test.ConnectionString "SELECT IsRead FROM Correspondence_Thread_Messages WHERE Body=N'رسالة أثناء إخفاء الصفحة'"
 Assert (-not [bool]$unread.Rows[0].IsRead) 'Hidden-page refresh does not mark incoming messages read'
 [void]$script:hostObject.Request(($base+'?workspaceActor=1&scope=all&draft='+$draft+'&ID='+$second),$null,$false)
 Assert ($script:hostObject.Status -eq 302 -and $script:hostObject.Location -match '(?:^|/)Dashboard\.aspx(?:\?|$)') 'Deferred portal oversight redirects to the administrator dashboard without opening the requested conversation'
 $unread=Query $test.ConnectionString "SELECT IsRead FROM Correspondence_Thread_Messages WHERE Body=N'رسالة أثناء إخفاء الصفحة'"
 Assert (-not [bool]$unread.Rows[0].IsRead) 'Deferred oversight navigation preserves participant read receipts'
 $client=Client ($base+'?workspaceActor=3&draft='+$draft+'&ID='+$first)
 $delta=Post $client 'btnCloseStart'
 $closed=Query $test.ConnectionString "SELECT CloseDate FROM Correspondence_Threads WHERE ID=$first"
 Assert ([DBNull]::Value -eq $closed.Rows[0].CloseDate) 'Recipient cannot close a creator-owned correspondence'
 $client=Client ($url+'&ID='+$first)
 $delta=Post $client 'btnCloseStart'
 $delta=Post $client 'btnCloseConfirm' @{rblOutcome='1';ddlClosureKind='3';txtCloseReason='إغلاق اختبار';hfVisible='1'}
 $closed=Query $test.ConnectionString "SELECT CloseDate,IsCompleted FROM Correspondence_Threads WHERE ID=$first"
 Assert ([DBNull]::Value -ne $closed.Rows[0].CloseDate -and [bool]$closed.Rows[0].IsCompleted) 'Creator can close with an explicit task outcome after a recipient reply'
 $html=Page ($url+'&ID='+$private)
 Assert (-not $html.Contains('محتوى سري مستقل')) 'Forged direct access does not disclose another conversation'
 [IO.File]::WriteAllText((Join-Path $output 'stage.txt'),$stage);[IO.File]::WriteAllText((Join-Path $output 'database.txt'),$name)
 $passed=$true;"Workspace checks passed. Stage: $stage"
 if($KeepDatabase){"Isolated synthetic database retained for visual QA: $name"}
}finally{
 $script:hostObject=$null
 if($created -and (-not $KeepDatabase -or -not $passed) -and $name -match '^Prosto_CorrespondenceWorkspace_Test_[a-f0-9]{32}$'){[Data.SqlClient.SqlConnection]::ClearAllPools();[void](Query $master.ConnectionString "ALTER DATABASE [$name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$name]")}
}
