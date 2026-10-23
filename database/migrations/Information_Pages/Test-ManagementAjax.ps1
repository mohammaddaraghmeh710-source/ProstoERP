# Runs in the disposable ASP.NET host. Every AJAX call uses the real session, CSRF and SQL procedures.
$manage=Page '/Modules/Information_Pages/Manage.aspx?newsTestActor=1'
Assert ($hostObject.Status -eq 200 -and $manage -match 'contentManager|ContentManagement' -and $manage -match 'data-token=') 'Information management compiles the shared cards/filter/offcanvas component'
Assert ($manage -notmatch 'informationPagesMenu' -and $manage -match 'href=[''"]/Modules/Information_Pages/Manage.aspx') 'Administrator information menu is a direct link with no nested information submenu'
Assert ($manage -notmatch 'data-manager-refresh') 'Management toolbar has no manual refresh button'
$script:contentToken=[Web.HttpUtility]::HtmlDecode([regex]::Match($manage,'data-token=[''"]([^''"]+)').Groups[1].Value)
function ContentAjax([string]$kind,[string]$action,[hashtable]$data=@{},[int]$expected=200,[string]$token=$script:contentToken,[int]$actor=1){
 $body='payload='+[Web.HttpUtility]::UrlEncode(($data|ConvertTo-Json -Depth 10 -Compress))
 $html=$hostObject.RequestWithCsrf("/Modules/ContentManagementAjax.aspx?kind=$kind&action=$action&newsTestActor=$actor",$body,$token)
 if($hostObject.Status -ne $expected){[IO.File]::WriteAllText((Join-Path $output 'content-ajax-error.txt'),$html,[Text.UTF8Encoding]::new($true));throw "AJAX $kind/$action expected $expected got $($hostObject.Status): see content-ajax-error.txt"}
 return $html|ConvertFrom-Json
}
$before=ContentAjax pages list
$payload=@{id=0;version=0;accessRevision=0;titleAr='صفحة اختبار AJAX';titleEn='AJAX information page';summaryAr='ملخص عربي';summaryEn='English summary';detailsAr='<p>تفاصيل <strong>عربية</strong></p><script>BAD_AJAX_AR()</script>';detailsEn='<p>Safe <em>English details</em></p><script>BAD_AJAX_EN()</script>';order=2;active='0';mode='immediate';start='';end='';audience='customers';employeeScope='all';customerScope='selected';brands='1';roles='';customers='1'}
$saved=ContentAjax pages save $payload;$pageId=[int]$saved.id
$after=ContentAjax pages list
Assert (@($after.rows|Where-Object {-not $_.deleted}).Count -eq @($before.rows|Where-Object {-not $_.deleted}).Count+1 -and @($after.rows|Where-Object {$_.id -eq $pageId -and -not $_.active -and $_.nameAr -eq $payload.titleAr}).Count -eq 1) 'AJAX create returns a persisted record immediately in the management dataset/statistics'
$loaded=ContentAjax pages editor @{id=$pageId}
Assert ($loaded.item.Audience -eq 'customers' -and @($loaded.customers|Where-Object {$_.ID -eq 1 -and $_.IsSelected}).Count -eq 1 -and $loaded.item.Details_Ar -notmatch 'BAD_AJAX' -and $loaded.item.Details_En -notmatch 'BAD_AJAX') 'AJAX editor restores scope, selected customer and both sanitized rich-text fields'
$payload.id=$pageId;$payload.version=$loaded.item.VersionNumber;$payload.accessRevision=$loaded.item.AccessRevision;$payload.titleAr='صفحة محدثة مباشرة';$payload.active='1';$payload.brands='2';$payload.customers='2'
[void](ContentAjax pages save $payload)
$after=ContentAjax pages list
Assert (@($after.rows|Where-Object {$_.id -eq $pageId -and $_.nameAr -eq 'صفحة محدثة مباشرة' -and $_.active -and $_.brands -contains 2 -and $_.version -eq 2}).Count -eq 1) 'AJAX edit immediately returns changed title, brand, state and version'
[void](ContentAjax pages save $payload 409)
$loaded=ContentAjax pages editor @{id=$pageId};$payload.version=$loaded.item.VersionNumber;$payload.accessRevision=$loaded.item.AccessRevision;$payload.brands='1';$payload.titleAr='تعديل مرفوض'
[void](ContentAjax pages save $payload 409)
Sql "IF NOT EXISTS(SELECT 1 FROM Information_Pages WHERE ID=$pageId AND VersionNumber=2 AND Title_Ar=N'صفحة محدثة مباشرة') THROW 51999,'Invalid AJAX save changed current data',1;"
[void](ContentAjax pages delete @{id=$pageId;version=1} 409)
[void](ContentAjax pages delete @{id=$pageId;version=2})
$after=ContentAjax pages list
Assert (@($after.rows|Where-Object {$_.id -eq $pageId -and $_.deleted}).Count -eq 1) 'Versioned AJAX delete moves the record into its retained archive'
$history=Page ("/Modules/Information_Pages/History.aspx?ID=$pageId&newsTestActor=1")
Assert ($hostObject.Status -eq 200 -and $history -notmatch 'Information_Pages/Logs.aspx|ID="lnkLogs"') 'Version page has no link to logs'
Assert ($history -match 'type-stat-card' -and $history -match 'information-reports.js' -and $history -match 'data-restore-confirm' -and $history -notmatch 'return confirm') 'History shares management cards/table and uses modal restore confirmation'
$logs=Page '/Modules/Information_Pages/Logs.aspx?newsTestActor=1'
Assert ($hostObject.Status -eq 200 -and $logs -match 'type-stat-card' -and $logs -match 'table type-table' -and $logs -match 'data-title=' -and $logs -match 'crm-list.js') 'Activity log shares management statistics, filters and responsive row cards'
[IO.File]::WriteAllText((Join-Path $output 'information-manager.html'),$manage,[Text.UTF8Encoding]::new($true))
$newsPage=Page '/Modules/News/Manage_News.aspx?newsTestActor=1'
Assert ($hostObject.Status -eq 200 -and $newsPage -match 'contentManager' -and $newsPage -match 'data-kind=[''"]news') 'News management uses the same cards/filter/offcanvas markup'
[IO.File]::WriteAllText((Join-Path $output 'news-manager.html'),$newsPage,[Text.UTF8Encoding]::new($true))
$news=@{id=0;revision='';brand=1;titleAr='خبر اختبار AJAX';titleEn='AJAX news';summaryAr='ملخص خبر';summaryEn='News summary';detailsAr='<p>خبر <strong>عربي</strong></p><script>BAD_AJAX_NEWS()</script>';detailsEn='<p><em>English news</em></p>';order=1;active='0';date='2026-10-18T12:30'}
$saved=ContentAjax news save $news;$newsId=[int]$saved.id
$listing=ContentAjax news list
Assert (@($listing.rows|Where-Object {$_.id -eq $newsId -and -not $_.active}).Count -eq 1) 'AJAX news create honors an inactive state and updates management data'
$loaded=ContentAjax news editor @{id=$newsId};$news.id=$newsId;$news.revision=$loaded.revision;$news.titleAr='خبر تم تحديثه';$news.active='1';$news.brand=2
[void](ContentAjax news save $news)
$listing=ContentAjax news list
Assert (@($listing.rows|Where-Object {$_.id -eq $newsId -and $_.active -and $_.nameAr -eq 'خبر تم تحديثه' -and $_.brands -contains 2}).Count -eq 1) 'AJAX news edit updates title/state/brand in the returned management dataset'
[void](ContentAjax news save $news 409)
$loaded=ContentAjax news editor @{id=$newsId}
Assert ($loaded.item.Details -notmatch 'BAD_AJAX_NEWS' -and $loaded.item.Details_EN -match '<em>English news</em>') 'AJAX news preserves independently sanitized bilingual rich text'
[void](ContentAjax news delete @{id=$newsId;revision=$news.revision} 409)
[void](ContentAjax news delete @{id=$newsId;revision=$loaded.revision})
$listing=ContentAjax news list
Assert (@($listing.rows|Where-Object id -eq $newsId).Count -eq 0) 'AJAX news deletion removes the current row'
[void](ContentAjax pages list @{} 403 'wrong-token')
[void](ContentAjax pages list @{} 403 $script:contentToken 2)
[void](ContentAjax news save $news 401 $script:contentToken 0)
Assert $true 'AJAX endpoints reject missing login, non-admin actors and invalid CSRF'
# Seed authorized bilingual fixtures for browser regression checks; the entire database is disposable.
$payload.id=0;$payload.version=0;$payload.accessRevision=0;$payload.brands='1';$payload.customers='';$payload.audience='all';$payload.titleAr='صفحة اختبار تبديل اللغة';$payload.titleEn='Instant information language';$payload.detailsAr='<p>نص عربي مباشر</p>';$payload.detailsEn='<p>Instant English information</p>'
$fixturePage=ContentAjax pages save $payload
$news.id=0;$news.revision='';$news.brand=1;$news.titleAr='خبر اختبار تبديل اللغة';$news.titleEn='Instant news language';$news.detailsAr='<p>نص الخبر العربي</p>';$news.detailsEn='<p>Instant English news</p>'
$fixtureNews=ContentAjax news save $news
[IO.File]::WriteAllText((Join-Path $output 'content-fixture-ids.json'),(@{page=$fixturePage.id;news=$fixtureNews.id}|ConvertTo-Json))
'PASS AJAX management CRUD, refreshed datasets/statistics, concurrency, access atomicity, CSRF and administrator boundaries.'
