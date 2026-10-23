# Invoked only by the disposable customer portal page-test host after customer logout.
Sql 'CREATE OR ALTER PROCEDURE dbo.Select_Brands_All AS SELECT * FROM dbo.Brands;'
Sql 'CREATE OR ALTER PROCEDURE dbo.Select_News_ByID @PID int AS SELECT * FROM dbo.News WHERE PID=@PID;'
function NewsPost([string]$url,[string]$html,[hashtable]$values){
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
$newsAdd='/Modules/News/Add_News.aspx?newsTestActor=1'
$html=Page $newsAdd
Assert ($hostObject.Status -eq 200 -and $html -match 'news-editor.js' -and $html -match 'id="txtDetailsEn"') 'News add renders two rich-text editors'
$order=@('ddlBrand','txtDate','txtTitleAr','txtTitleEn','txtBriefAr','txtBriefEn','txtDetails','txtDetailsEn')
$previous=-1
foreach($field in $order){$position=$html.IndexOf('for="'+$(if($field -in @('txtDetails','txtDetailsEn')){$field}else{'ContentPlaceHolder1_'+$field})+'"');Assert ($position -gt $previous) 'News fields follow brand/date, bilingual titles, full-width summaries and bilingual details';$previous=$position}
Assert ($html -match '<div class="col-12"><label[^>]+for="ContentPlaceHolder1_txtBriefAr"' -and $html -match '<div class="col-12"><label[^>]+for="ContentPlaceHolder1_txtBriefEn"') 'Each news summary occupies its own full-width row'
[IO.File]::WriteAllText((Join-Path $output 'news-add.html'),$html,[Text.UTF8Encoding]::new($true))
$values=@{ddlBrand='1';txtDate='2026-10-18T10:30';txtTitleAr='خبر محررين';txtTitleEn='Bilingual editor news';txtBriefAr='ملخص مستقل';txtBriefEn='Independent summary';txtDetails='<p>تفاصيل <strong>عربية</strong></p><script>BAD_ADMIN_AR()</script>';txtDetailsEn='<h2>English details</h2><p><strong>Formatted English</strong></p><script>BAD_ADMIN_EN()</script>';txtOrder='4'}
[void](NewsPost $newsAdd $html $values)
Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*Manage_News.aspx?added=1') 'News saves Arabic and English details through the real add form'
$newsId=[int](Q $TestConnection "SELECT PID FROM News WHERE Title_En='Bilingual editor news'").Rows[0].PID
Sql "IF NOT EXISTS(SELECT 1 FROM News WHERE PID=$newsId AND Details LIKE N'%<strong>عربية</strong>%' AND Details_EN LIKE '%<strong>Formatted English</strong>%' AND Details NOT LIKE '%BAD_ADMIN_AR%' AND Details_EN NOT LIKE '%BAD_ADMIN_EN%') THROW 51999,'Bilingual news save/sanitation failed',1;"
$newsEdit='/Modules/News/Edit_News.aspx?PID='+$newsId+'&newsTestActor=1'
$html=Page $newsEdit
Assert ($html -match '&lt;strong&gt;Formatted English&lt;/strong&gt;' -and $html -match '&lt;strong&gt;عربية&lt;/strong&gt;') 'Editing restores both formatted languages from storage'
[IO.File]::WriteAllText((Join-Path $output 'news-edit.html'),$html,[Text.UTF8Encoding]::new($true))
$values.txtDetailsEn='<p>Updated <em>English details</em></p>';$values.chkIsActive='on'
[void](NewsPost $newsEdit $html $values)
Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*updated=1') 'Real news edit persists English changes'
Sql "IF NOT EXISTS(SELECT 1 FROM News WHERE PID=$newsId AND Details_EN=N'<p>Updated <em>English details</em></p>') THROW 51999,'English edit failed',1;EXEC News_AdminSave @Actor=1,@BrandID=1,@PID=$newsId,@Details=N'legacy arabic';IF NOT EXISTS(SELECT 1 FROM News WHERE PID=$newsId AND Details_EN=N'<p>Updated <em>English details</em></p>') THROW 51999,'Legacy save erased English',1;"
$html=Page $newsEdit;$values.txtDetailsEn='';[void](NewsPost $newsEdit $html $values)
Sql "IF NOT EXISTS(SELECT 1 FROM News WHERE PID=$newsId AND Details_EN=N'') THROW 51999,'Explicit English clear failed',1;"
foreach($actor in @(0,2)){[void](Page ("/Modules/News/Add_News.aspx?newsTestActor=$actor"));Assert ($hostObject.Status -eq 302) 'News editing remains administrator-only'}
Sql "BEGIN TRY EXEC News_AdminSave @Actor=2,@BrandID=1,@Details_EN=N'Forbidden';THROW 51999,'Non-admin write succeeded',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51950 THROW;END CATCH;BEGIN TRY EXEC News_AdminSave @Actor=1,@BrandID=999,@Details_EN=N'Forbidden';THROW 51999,'Invalid brand succeeded',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51951 THROW;END CATCH;"
'PASS actual ASP.NET news add/edit, field order/full-width summaries, bilingual sanitation/storage/clear/legacy preservation and administrator/brand guards.'
