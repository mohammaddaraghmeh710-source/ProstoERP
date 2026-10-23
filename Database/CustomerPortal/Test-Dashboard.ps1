param([Parameter(Mandatory)][string]$TestConnection,[switch]$MultiBrandOnly,[switch]$FeedbackOnly)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Web
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($TestConnection)
if($builder.DataSource -notin @('localhost','.','(local)') -or $builder.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'Only an isolated customer test database is allowed.'}
$portal=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Portal'))
$stage=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot ('../../../tmp/customer-dashboard-'+[guid]::NewGuid().ToString('N'))))
$output=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../tmp/customer-dashboard-results'))
function Sql([string]$sql,[hashtable]$parameters=@{}){$cn=[Data.SqlClient.SqlConnection]::new($TestConnection);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};[void]$cmd.ExecuteNonQuery()}finally{$cn.Dispose()}}
function Assert([bool]$ok,[string]$message){if(-not $ok){throw $message};"PASS: $message"}
function Page([string]$url,[string]$form=''){$html=$script:hostObject.Request($url,$form);if($html -match 'Server Error|Exception Details|Parser Error|Compilation Error'){[IO.File]::WriteAllText((Join-Path $output 'error.html'),$html);throw 'ASP.NET page rendering failed; see tmp/customer-dashboard-results/error.html'};return $html}
function Login {
 $html=Page '/Login.aspx?kind=customer';$form=@{ddlAccountKind='customer';txtUserName='customer';txtPassword='Dashboard-Test!2026';btnLogin='تسجيل الدخول'}
 foreach($input in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')){$name=[regex]::Match($input.Value,'name="([^"]+)"').Groups[1].Value;$value=[regex]::Match($input.Value,'value="([^"]*)"').Groups[1].Value;if($name){$form[$name]=[Web.HttpUtility]::HtmlDecode($value)}}
 $body=($form.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode($_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
 return Page '/Login.aspx?kind=customer' $body
}
try {
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'bin'));[void][IO.Directory]::CreateDirectory((Join-Path $stage 'CustomerPortal'));[void][IO.Directory]::CreateDirectory($output)
 Copy-Item -Path (Join-Path $portal 'bin/*.dll') -Destination (Join-Path $stage 'bin') -Force
 foreach($file in @('Login.aspx','Customer.Master')){Copy-Item -LiteralPath (Join-Path $portal $file) -Destination $stage}
 foreach($file in @('Circulars.aspx','CircularFile.aspx','Dashboard.aspx','InformationPage.aspx','NewsDetail.aspx','Logo.aspx','Feedback.aspx','FeedbackDetail.aspx','FeedbackFile.aspx')){Copy-Item -LiteralPath (Join-Path $portal ('CustomerPortal/'+$file)) -Destination (Join-Path $stage 'CustomerPortal')}
 $config=[xml](Get-Content (Join-Path $portal 'Web.config'));($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString=$TestConnection;$config.Save((Join-Path $stage 'Web.config'))
 $assembly=Join-Path $stage 'bin/CustomerPortalPageTests.dll'
 Copy-Item -LiteralPath (Join-Path $portal 'Site.Master') -Destination $stage
 if($FeedbackOnly){
  [void][IO.Directory]::CreateDirectory((Join-Path $stage 'Modules'))
  foreach($directory in @('Employee_Feedback','Employee_Feedback_Types','Employee_Feedback_Topics','Employee_Feedback_Permissions')){Copy-Item -LiteralPath (Join-Path $portal ('Modules/'+$directory)) -Destination (Join-Path $stage 'Modules') -Recurse}
 }

 $newsDirectory=Join-Path $stage 'Modules/News';[void][IO.Directory]::CreateDirectory($newsDirectory)
 foreach($file in @('Add_News.aspx','Edit_News.aspx','Manage_News.aspx','Web.config')){Copy-Item -LiteralPath (Join-Path $portal ('Modules/News/'+$file)) -Destination $newsDirectory}
 $infoDirectory=Join-Path $stage 'Modules/Information_Pages';[void][IO.Directory]::CreateDirectory($infoDirectory)
 foreach($file in @('Edit.aspx','Manage.aspx','Logs.aspx','View.aspx','History.aspx','Index.aspx','Web.config')){Copy-Item -LiteralPath (Join-Path $portal ('Modules/Information_Pages/'+$file)) -Destination $infoDirectory}
 $circularDirectory=Join-Path $stage 'Modules/Circulars';[void][IO.Directory]::CreateDirectory($circularDirectory)
 foreach($file in @('Manage.aspx','AdminAjax.aspx','Index.aspx','File.aspx','Web.config')){Copy-Item -LiteralPath (Join-Path $portal ('Modules/Circulars/'+$file)) -Destination $circularDirectory}
 Copy-Item -LiteralPath (Join-Path $portal 'CircularNotifications.aspx') -Destination $stage
 Copy-Item -LiteralPath (Join-Path $portal 'CircularReader.aspx') -Destination $stage
 Copy-Item -LiteralPath (Join-Path $portal 'Modules/ContentManagementAjax.aspx') -Destination (Join-Path $stage 'Modules')
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'Controls'));Copy-Item -LiteralPath (Join-Path $portal 'Controls/ContentManagement.ascx') -Destination (Join-Path $stage 'Controls')
 foreach($control in @('CircularManagement.ascx','CircularNotifications.ascx','CircularReader.ascx','SystemAdminWorkspace.ascx')){Copy-Item -LiteralPath (Join-Path $portal ('Controls/'+$control)) -Destination (Join-Path $stage 'Controls')}
 $web=$config.configuration.'system.web';$modules=$web.httpModules
 if($null -eq $modules){$modules=$config.CreateElement('httpModules');[void]$web.AppendChild($modules)}
 $module=$config.CreateElement('add');$module.SetAttribute('name','NewsPortalTestIdentity');$module.SetAttribute('type','NewsPortalTestIdentity, CustomerPortalPageTests');[void]$modules.AppendChild($module);$config.Save((Join-Path $stage 'Web.config'))
 Add-Type -Path (Join-Path $PSScriptRoot 'CustomerPortalPageTests.cs') -ReferencedAssemblies @('System.Web',(Join-Path $stage 'bin/CRM.dll')) -OutputAssembly $assembly
 $type=[Reflection.Assembly]::LoadFrom($assembly).GetType('CustomerPortalPageHost');$script:hostObject=[Web.Hosting.ApplicationHost]::CreateApplicationHost($type,'/',$stage)
 $salt=New-Object byte[] 32;[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
 $derive=[Security.Cryptography.Rfc2898DeriveBytes]::new('Dashboard-Test!2026',$salt,210000,[Security.Cryptography.HashAlgorithmName]::SHA256)
 try{Sql 'UPDATE Customer_Logins SET PasswordHash=@Hash,Salt=@Salt,Iterations=210000,LockedUntil=NULL,FailedAttempts=0 WHERE AccountID=1' @{'@Hash'=$derive.GetBytes(32);'@Salt'=$salt}}finally{$derive.Dispose()}
 [void](Page '/CustomerPortal/Dashboard.aspx');Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*Login.aspx?kind=customer') 'Dashboard requires customer login'
 [void](Login);Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*CustomerPortal/Dashboard.aspx') 'Real customer login redirects to dashboard'
 $html=Page '/CustomerPortal/Dashboard.aspx?accountID=2';[IO.File]::WriteAllText((Join-Path $output 'dashboard.html'),$html,[Text.UTF8Encoding]::new($true));Assert ($hostObject.Status -eq 200 -and $html.Contains('عميل الاختبار') -and $html.Contains('جهة العميل الأول') -and -not $html.Contains('جهة عميل آخر')) ('Dashboard renders own profile and contacts; forged accountID is ignored (HTTP '+$hostObject.Status+')')
 Assert ($html -match 'page-profile.css' -and $html -match 'profile-banner.png' -and $html -match '/CustomerPortal/WorkGuide.aspx' -and $html -notmatch 'href="/CustomerPortal/Guide.aspx|PasswordHash|SecurityStamp') 'Profile Template and customer work-guide navigation render without sensitive fields'
 [IO.File]::WriteAllText((Join-Path $output 'dashboard.html'),$html,[Text.UTF8Encoding]::new($true))
 [void](Page '/CustomerPortal/Logo.aspx?id=2');Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*customer-default.svg') 'Own-logo endpoint uses default and ignores other customer IDs'
 if($FeedbackOnly){. (Join-Path $PSScriptRoot '../Employee_Feedback/Test-WorkspacePages.ps1');return}
 if($MultiBrandOnly){. (Join-Path $PSScriptRoot 'Test-DashboardEditing.ps1');. (Join-Path $PSScriptRoot 'Test-MultiBrandContent.ps1');. (Join-Path $PSScriptRoot '../Circulars/Test-TableReaders.ps1');return}
 . (Join-Path $PSScriptRoot 'Test-DashboardEditing.ps1')
 . (Join-Path $PSScriptRoot 'Test-News.ps1')
 Sql 'UPDATE Customer_Logins SET IsActive=0 WHERE AccountID=1';[void](Page '/CustomerPortal/Dashboard.aspx');Assert ($hostObject.Status -eq 302) 'Disabling login blocks an existing dashboard session'
 [void](Login);Assert ($hostObject.Status -eq 200) 'Disabled login cannot authenticate'
 Sql 'UPDATE Customer_Logins SET IsActive=1 WHERE AccountID=1;UPDATE CRM_Accounts SET Is_Active=0 WHERE ID=1';[void](Login);Assert ($hostObject.Status -eq 200) 'Inactive CRM customer cannot authenticate'
 Sql 'UPDATE CRM_Accounts SET Is_Active=1 WHERE ID=1';[void](Login);Sql 'UPDATE CRM_Accounts SET Is_Active=0 WHERE ID=1';[void](Page '/CustomerPortal/Dashboard.aspx');Assert ($hostObject.Status -eq 302) 'Deactivating CRM customer blocks an existing session'
 Sql 'UPDATE CRM_Accounts SET Is_Active=1 WHERE ID=1';[void](Login);Sql 'UPDATE Customer_Logins SET SecurityStamp=NEWID() WHERE AccountID=1';[void](Page '/CustomerPortal/Dashboard.aspx');Assert ($hostObject.Status -eq 302) 'Credential stamp changes block an existing session'
 [void]($hostObject.Request('/CustomerPortal/Guide.aspx',$null));Assert ($hostObject.Status -eq 404) 'Deleted customer guide page is unavailable'
 [void](Login);$logoutPage=Page '/CustomerPortal/Dashboard.aspx'
 [void](PostDashboard $logoutPage 'ctl00$btnLogout')
 Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*Login.aspx?kind=customer') 'Web logout clears the customer session'
 Sql "IF NOT EXISTS(SELECT 1 FROM Customer_Portal_Activity WHERE AccountID=1 AND Action='logout') THROW 51999,'Web logout audit missing',1;IF NOT EXISTS(SELECT 1 FROM Customer_Portal_Activity WHERE AccountID=1 AND Action='login-failed') THROW 51999,'Web failed-login audit missing',1;"
 [void](Page '/CustomerPortal/Dashboard.aspx');Assert ($hostObject.Status -eq 302) 'Web logout is audited and old session cannot reopen dashboard'
 . (Join-Path $PSScriptRoot '../News/Test-PortalFlows.ps1')
 . (Join-Path $PSScriptRoot '../Information_Pages/Test-PortalFlows.ps1')
 . (Join-Path $PSScriptRoot '../Information_Pages/Test-ManagementAjax.ps1')
 . (Join-Path $PSScriptRoot '../Circulars/Test-BrandedPortal.ps1')
} finally {$script:hostObject=$null}
