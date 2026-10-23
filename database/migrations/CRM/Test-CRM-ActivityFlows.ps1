# Invoked by Test-CRM-TypePage.ps1 -IncludeManagement in its isolated ASP.NET application.
[void](Q $test.ConnectionString @'
DECLARE @Before xml=N'<row><Name_AR>اسم النشاط السابق</Name_AR><Phone>123</Phone><PasswordHash>DO_NOT_RENDER_SECRET</PasswordHash></row>',@After xml=N'<row><Name_AR>اسم النشاط الجديد</Name_AR><Address>&lt;script&gt;unsafe()&lt;/script&gt;</Address></row>';
INSERT CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data,AddedDate) VALUES(1,1,N'Accounts',9001,N'تعديل',@Before,@After,'2021-03-14T12:00:00');
INSERT Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Before_Data,After_Data,CreatedUtc) VALUES(1,'profile-update',N'Accounts',9002,@Before,@After,'2021-03-14T10:00:00'),(2,'profile-update',N'Accounts',9003,N'<row><Name_AR>PRIVATE_OTHER_CUSTOMER</Name_AR></row>',NULL,'2021-03-14T10:00:00'),(1,'login',N'Customer_Session',9999,NULL,NULL,'2021-03-15T10:00:00');
'@)
$script:target='/Modules/CRM_Account_Types/Overview.aspx';$script:testActor=1
function LogPage([int]$actor=1){$script:testActor=$actor;$page=$hostObject.Request($script:target+'?testActor='+$actor,$null);CheckHtml $page;return $page}
function LogRows([string]$html){return [regex]::Match($html,'(?s)<tbody>(.*?)</tbody>').Groups[1].Value}
function LogCount([string]$html){return [regex]::Matches((LogRows $html),'data-title="التاريخ"').Count}
$logHtml=LogPage
Assert ($logHtml -match 'العلامات التجارية للعميل' -and $logHtml -match 'فروع العميل' -and $logHtml -match 'علامة أولى' -and $logHtml -match 'فرع أول') 'Canonical account memberships must render readable names in the before/after audit.'
Assert ($logHtml -match 'value="staff:1"' -and $logHtml -match 'value="customer:1"') 'Actor filter must distinguish employee/customer IDs.'
Assert ($logHtml -match 'اسم النشاط السابق' -and $logHtml -match 'اسم النشاط الجديد' -and $logHtml -match 'bg-label-warning' -and $logHtml -notmatch 'DO_NOT_RENDER_SECRET|<script>unsafe\(\)</script>' -and $logHtml -match '&lt;script&gt;unsafe\(\)&lt;/script&gt;') 'Audit detail labels/differences/encoding or secret redaction failed.'
[IO.File]::WriteAllText((Join-Path $output 'activity.html'),$logHtml,[Text.UTF8Encoding]::new($true))
$filters=@{'filterAccount'='1';'filterActor'='customer:1';'filterSource'='بوابة العميل';'filterFrom'='2021-03-14';'filterTo'='2021-03-14';'filterEntity'='Accounts'}
$logHtml=Post $logHtml ($prefix+'btnSearch') $filters
Assert ((LogCount $logHtml) -eq 1 -and (LogRows $logHtml) -match '9002' -and (LogRows $logHtml) -notmatch '9001|9003') 'Combined customer/actor/source/inclusive-date filters failed.'
$logHtml=LogPage;$filters['filterActor']='staff:1';$filters['filterSource']='إدارة النظام'
$logHtml=Post $logHtml ($prefix+'btnSearch') $filters
Assert ((LogCount $logHtml) -eq 1 -and (LogRows $logHtml) -match '9001') 'Employee actor/source filters failed.'
$logHtml=LogPage;$filters['filterSource']='بوابة العميل'
$logHtml=Post $logHtml ($prefix+'btnSearch') $filters
Assert ((LogCount $logHtml) -eq 0) 'Employee/customer actor ID collision leaked rows.'
$logHtml=LogPage;$filters['filterFrom']='2021-03-15';$filters['filterTo']='2021-03-14'
$logHtml=Post $logHtml ($prefix+'btnSearch') $filters
Assert ($logHtml -match 'نطاق التاريخ غير صحيح') 'Inverted date range was accepted.'
$logHtml=LogPage 2
Assert ($logHtml -notmatch 'PRIVATE_OTHER_CUSTOMER|value="customer:2"' -and (LogRows $logHtml) -notmatch '9999') 'Owner log rows/filter options leaked another account or authentication audit.'
$overviewDirectory=Join-Path $stage 'Modules/CRM_Account_Types'
Copy-Item -LiteralPath (Join-Path $portal 'Modules/CRM_Account_Types/Overview.aspx') -Destination $overviewDirectory
$overview=$hostObject.Request('/Modules/CRM_Account_Types/Overview.aspx?testActor=1',$null);CheckHtml $overview
Assert ([regex]::Matches($overview,'card crm-stat h-100').Count -eq 7 -and $overview -match 'href="#crmActivity"' -and $overview.IndexOf('id="crmActivity"') -gt $overview.IndexOf('إجمالي العملاء') -and $overview -match 'data-title="قبل التعديل"' -and $overview -notmatch 'alert-danger') 'Overview activity card/scoped count failed.'
[IO.File]::WriteAllText((Join-Path $output 'overview.html'),$overview,[Text.UTF8Encoding]::new($true))
$overview=$hostObject.Request('/Modules/CRM_Account_Types/Overview.aspx?testActor=2',$null);CheckHtml $overview
Assert ([regex]::Matches($overview,'card crm-stat h-100').Count -eq 3 -and $overview -notmatch 'alert-danger') 'Owner Overview counts/permissions failed.'
'PASS embedded Overview activity filters, actor identity separation, readable safe before/after details, owner isolation and Overview cards.'
