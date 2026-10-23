# Runs within the isolated Test-Dashboard host/session.
Sql @'
UPDATE CRM_Accounts SET Brand_ID=1 WHERE ID=1;
SET IDENTITY_INSERT News ON;
INSERT News(PID,Brand_ID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Image,[Date],Item_Order,IsActive,IsDeleted) VALUES
(701,1,N'خبر العلامة الأولى','First brand news',N'ملخص الخبر الأول','First news summary',N'<p>تفاصيل الخبر الأول <strong>نص منسق</strong></p><script>BAD_NEWS_SCRIPT()</script>','/FileManager/test-news.png','2026-10-18',1,1,0),
(702,1,N'الخبر الثاني','Second news',N'ملخص الخبر الثاني','Second summary',N'<p>Second news details</p>','javascript:alert(1)','2026-10-17',2,1,0),
(703,2,N'خبر علامة أخرى','Other brand secret',N'غير مسموح',NULL,N'OTHER_BRAND_SECRET',NULL,NULL,1,1,0),
(704,1,N'خبر موقوف',NULL,NULL,NULL,N'INACTIVE_NEWS_SECRET',NULL,NULL,1,0,0),
(705,1,N'خبر محذوف',NULL,NULL,NULL,N'DELETED_NEWS_SECRET',NULL,NULL,1,1,1),
(706,NULL,N'خبر غير مربوط',NULL,NULL,NULL,N'UNASSIGNED_NEWS_SECRET',NULL,NULL,1,1,0);
SET IDENTITY_INSERT News OFF;
'@
Sql "UPDATE News SET Details_EN=N'<h2>English news details</h2><p>Read <strong>formatted English content</strong>.</p><script>BAD_EN_NEWS()</script>' WHERE PID=701"
try{
 $html=Page '/CustomerPortal/Dashboard.aspx?brand=2'
 Assert ($html -match 'خبر العلامة الأولى' -and $html -match 'الخبر الثاني' -and $html -notmatch 'خبر علامة أخرى|خبر موقوف|خبر محذوف|خبر غير مربوط') 'Carousel returns only current-brand active/nondeleted news and ignores forged brand'
 Assert ($html -match 'carousel carousel-dark slide carousel-fade' -and $html -match 'NewsDetail.aspx\?id=701' -and $html -match '18/10/2026' -and $html -match '/FileManager/test-news.png' -and $html -notmatch 'javascript:alert') 'Template carousel includes image/title/date/summary/detail links and rejects unsafe image URLs'
 Assert ($html.IndexOf('data-contact-card="1"') -lt $html.IndexOf('id="brandNewsSection"') -and $html -notmatch 'aria-label="الخبر السابق"|aria-label="الخبر التالي"' -and $html -match 'data-bs-slide-to=[''"]1[''"]') 'News appears below contacts without slider arrows; indicators remain available'
 Assert ($html -match 'id="brandNewsTitle">آخر الأخبار' -and $html -notmatch 'customer-news-card-column|أخبار علامتك التجارية') 'Latest news heading and full contact-section column replace the single-contact width'
 [IO.File]::WriteAllText((Join-Path $output 'dashboard-news.html'),$html,[Text.UTF8Encoding]::new($true))
 $html=Page '/CustomerPortal/NewsDetail.aspx?id=701&brand=2'
 Assert ($hostObject.Status -eq 200 -and $html -match 'تفاصيل الخبر الأول' -and $html -match '<strong>نص منسق</strong>' -and $html -notmatch 'BAD_NEWS_SCRIPT|<script>BAD') 'News detail preserves safe formatting, bilingual metadata and session-derived brand'
 Assert ($html -match 'card-header border-bottom d-flex align-items-start justify-content-between flex-wrap gap-3' -and $html -match 'card-body pt-4' -and $html -match 'customer-detail-content' -and $html -match 'newsLanguageSwitch' -and $html -notmatch 'role="tablist"|data-bs-toggle="tab"|customer-news-cover|ملخص الخبر الأول') 'News detail matches information-page header/body without tabs, cover or brief'
 [IO.File]::WriteAllText((Join-Path $output 'news-detail.html'),$html,[Text.UTF8Encoding]::new($true))
 $html=Page '/CustomerPortal/NewsDetail.aspx?id=701&lang=en'
 Assert ($hostObject.Status -eq 200 -and $html -match '<strong>formatted English content</strong>' -and $html -match 'First brand news' -and $html -match 'dir="ltr"' -and $html -match 'data-detail-language="en"' -and $html -match 'data-detail-language-toggle' -and $html -match 'detail-language.js' -and $html -notmatch 'BAD_EN_NEWS|First news summary') 'News preloads sanitized bilingual titles/details with an English initial state and a local type=button language toggle'
 [IO.File]::WriteAllText((Join-Path $output 'news-detail-en.html'),$html,[Text.UTF8Encoding]::new($true))
 $html=Page '/CustomerPortal/NewsDetail.aspx?id=702&lang=en';Assert ($hostObject.Status -eq 200 -and $html -match 'No English details are available') 'Legacy news without English text remains readable with an explicit empty state'
 foreach($id in @(703,704,705,706,999)){ $html=Page ("/CustomerPortal/NewsDetail.aspx?id=$id");Assert ($hostObject.Status -eq 404 -and $html -notmatch 'OTHER_BRAND_SECRET|INACTIVE_NEWS_SECRET|DELETED_NEWS_SECRET|UNASSIGNED_NEWS_SECRET') 'Direct news links deny cross-brand, inactive, deleted, unassigned and missing records' }
 Sql 'UPDATE CRM_Accounts SET Brand_ID=2 WHERE ID=1'
 $html=Page '/CustomerPortal/NewsDetail.aspx?id=701';Assert ($hostObject.Status -eq 404) 'Account brand changes immediately revoke old news links'
 Sql 'UPDATE CRM_Accounts SET Brand_ID=1 WHERE ID=1;UPDATE News SET IsActive=0 WHERE PID=701'
 $html=Page '/CustomerPortal/NewsDetail.aspx?id=701';Assert ($hostObject.Status -eq 404) 'Unpublishing news revokes an already opened link'
 Sql 'UPDATE Brands SET IsActive=0 WHERE ID=1'
 $html=Page '/CustomerPortal/Dashboard.aspx';Assert ($html -match 'لا توجد أخبار منشورة' -and $html -notmatch 'الخبر الثاني') 'Inactive brands do not publish news to the customer'
 Sql "IF NOT EXISTS(SELECT 1 FROM Customer_Portal_Activity WHERE AccountID=1 AND Entity=N'News' AND Action='news-details' AND RecordID=701) THROW 51999,'News detail audit missing',1;"
 'PASS customer brand-news carousel, direct-link authorization, publication/session changes, sanitation and audit.'
}finally{Sql 'UPDATE Brands SET IsActive=1 WHERE ID=1;UPDATE CRM_Accounts SET Brand_ID=NULL WHERE ID=1'}
