# Sourced by the isolated Test-Dashboard host after CRM 020/022. Never connects to a source database.
if($builder.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'An isolated customer test database is required.'}
function ContentRows([string]$sql,[hashtable]$parameters=@{}){
 $cn=[Data.SqlClient.SqlConnection]::new($TestConnection)
 try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$sql;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$rows=[Data.DataTable]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($rows);return ,$rows}finally{$cn.Dispose()}
}
function ContentRejected([scriptblock]$action,[string]$message,[int]$number){
 $denied=$false;try{& $action|Out-Null}catch{$detail=$_.Exception;while($detail.InnerException){$detail=$detail.InnerException};if($detail -isnot [Data.SqlClient.SqlException] -or $detail.Number -ne $number){throw};$denied=$true};Assert $denied $message
}
function ContentPage([string]$title,[int[]]$brands,[int[]]$customers=@()){
 $brandXml='<brands>'+(($brands|ForEach-Object{'<brand id="'+$_+'" />'}) -join '')+'</brands>'
 $customerXml='<customers>'+(($customers|ForEach-Object{'<customer id="'+$_+'" />'}) -join '')+'</customers>'
 return [int](ContentRows "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,@TitleAr=@title,@TitleEn=@title,@SummaryAr=N'ملخص متعدد العلامات',@SummaryEn=N'Multiple brand summary',@DetailsAr=N'<p>تفاصيل متعددة العلامات</p>',@DetailsEn=N'<p>Multiple brand details</p>',@Order=0,@Published=1,@Mode='immediate',@AllTypes=1,@Roles=N'<roles/>',@ExpectedAccessRevision=0,@Brands=@brands,@Audience='customers',@AllCustomers=@all,@Customers=@customers" @{'@title'=$title;'@brands'=$brandXml;'@all'=($customers.Count -eq 0);'@customers'=$customerXml}).Rows[0].ID
}
function ContentCircular([string]$title,[int]$brand,[int]$customer=1,[string]$audience='customers'){
 $targets=if($audience -eq 'customers'){'<targets><item kind="customer" id="'+$customer+'" /></targets>'}else{'<targets/>'}
 return [int](ContentRows "EXEC dbo.Circular_AdminSave @Actor=1,@BrandID=@brand,@Title=@title,@Title_EN=@title,@Summary=N'ملخص تعميم',@Summary_EN=N'Circular summary',@CircularDate='20261021',@HasPeriod=0,@IsEnabled=1,@AllowDownload=1,@Audience=@audience,@Targets=@targets,@FileName=N'multibrand.pdf',@FileBytes=0x255044462D312E34" @{'@brand'=$brand;'@title'=$title;'@audience'=$audience;'@targets'=$targets}).Rows[0].ID
}
function ContentCustomerCircular([int]$id,[int]$expected=200){
 $dashboard=Page '/CustomerPortal/Dashboard.aspx'
 $token=[Web.HttpUtility]::HtmlDecode([regex]::Match($dashboard,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)
 $raw=$hostObject.RequestWithCsrf(("/CircularReader.aspx?kind=customer&id=$id"),'x=1',$token)
 Assert ($hostObject.Status -eq $expected) ("Customer circular metadata returns HTTP $expected") | Out-Host
 return $raw|ConvertFrom-Json
}
Sql @'
UPDATE Brands SET IsActive=1,IsDeleted=0 WHERE ID IN(1,2);
SET IDENTITY_INSERT Brands ON;INSERT Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(3,N'علامة غير مرتبطة','Unassigned brand',1,0),(4,N'علامة متوقفة','Paused brand',0,0),(5,N'علامة دون محتوى','Empty assigned brand',1,0);SET IDENTITY_INSERT Brands OFF;
UPDATE CRM_Accounts SET Brand_ID=CASE WHEN ID=1 THEN 1 ELSE 2 END,Is_Active=1,Is_Deleted=0 WHERE ID IN(1,2);
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) SELECT 1,v.ID,1 FROM(VALUES(1),(2),(4),(5))v(ID) WHERE NOT EXISTS(SELECT 1 FROM CRM_Account_Brands ab WHERE ab.Account_ID=1 AND ab.Brand_ID=v.ID);
INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) SELECT 2,2,1 WHERE NOT EXISTS(SELECT 1 FROM CRM_Account_Brands WHERE Account_ID=2 AND Brand_ID=2);
SET IDENTITY_INSERT News ON;
INSERT News(PID,Brand_ID,Title_AR,Title_En,Brief_Ar,Brief_En,Details,Details_EN,Image,[Date],Item_Order,IsActive,IsDeleted) VALUES
(901,1,N'خبر متعدد أول','Multi brand news one',N'ملخص أول','First summary',N'<p>تفاصيل أولى</p>',N'<p>First details</p>',NULL,'20261021',1,1,0),
(902,2,N'خبر متعدد ثان','Multi brand news two',N'ملخص ثان','Second summary',N'<p>تفاصيل ثانية</p>',N'<p>Second details</p>',NULL,'20261021',2,1,0),
(903,3,N'خبر غير مصرح','Unassigned secret news',N'غير مسموح','Unassigned',N'UNASSIGNED_SECRET',N'UNASSIGNED_SECRET',NULL,'20261021',3,1,0),
(904,4,N'خبر علامة متوقفة','Paused brand secret news',N'غير مسموح','Paused',N'PAUSED_SECRET',N'PAUSED_SECRET',NULL,'20261021',4,1,0);
SET IDENTITY_INSERT News OFF;
'@
[void](Login)
$stamp=(ContentRows 'SELECT SecurityStamp FROM Customer_Logins WHERE AccountID=1').Rows[0].SecurityStamp
$news=ContentRows 'EXEC dbo.Customer_News @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert (@($news.Rows|Where-Object {$_.PID -in @(901,902)}).Count -eq 2 -and @($news.Rows|Where-Object {$_.PID -in @(903,904)}).Count -eq 0 -and $news.Columns.Contains('Brand_Name')) 'News uses the union of assigned active brands with filter metadata'
$contentBrands=ContentRows 'EXEC dbo.Customer_ContentBrands @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert ($contentBrands.Rows.Count -eq 3 -and @($contentBrands.Rows|Where-Object BrandID -eq 5).Count -eq 1 -and @($contentBrands.Rows|Where-Object {$_.BrandID -in @(3,4)}).Count -eq 0) 'Brand filters include every assigned active brand, including brands with no published content'
$dashboard=Page '/CustomerPortal/Dashboard.aspx?brand=3'
Assert ($hostObject.Status -eq 200 -and $dashboard.Contains('خبر متعدد أول') -and $dashboard.Contains('خبر متعدد ثان') -and $dashboard -notmatch 'خبر غير مصرح|خبر علامة متوقفة') 'Dashboard shows both assigned news brands and ignores a forged brand query'
Assert ($dashboard -match 'data-news-brand-filter' -and $dashboard -match 'data-brand-id=[''"]2[''"]' -and $dashboard -match 'customer-content-filters.js') 'News renders a local brand picker and per-slide authorized brand identifiers'
[void](Page '/CustomerPortal/NewsDetail.aspx?id=902');Assert ($hostObject.Status -eq 200) 'A direct news link from the second assigned brand is authorized'
foreach($id in @(903,904)){[void](Page "/CustomerPortal/NewsDetail.aspx?id=$id");Assert ($hostObject.Status -eq 404) 'Unassigned or inactive brand news direct links remain denied'}

$infoOne=ContentPage 'MULTI_INFO_ONE' @(1)
$infoTwo=ContentPage 'MULTI_INFO_TWO' @(2) @(1)
$infoShared=ContentPage 'MULTI_INFO_SHARED' @(1,2)
$infoOther=ContentPage 'MULTI_INFO_OTHER_CUSTOMER' @(2) @(2)
$infoForeign=ContentPage 'MULTI_INFO_FOREIGN' @(3)
$info=ContentRows 'EXEC dbo.Customer_InformationPages @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert (@($info.Rows|Where-Object {$_.ID -in @($infoOne,$infoTwo,$infoShared)}).Count -eq 3 -and @($info.Rows|Where-Object {$_.ID -in @($infoOther,$infoForeign)}).Count -eq 0) 'Information pages union assigned brands while preserving exact named-customer grants'
Assert (@($info.Rows|Where-Object ID -eq $infoShared).Count -eq 1) 'A page linked to two assigned brands appears only once'
$customers=ContentRows 'EXEC dbo.Select_Information_Page_Customers @Actor=1,@ID=0'
$customer=@($customers.Rows|Where-Object ID -eq 1)[0]
Assert ($customer.Brand_IDs.Split(',') -contains '1' -and $customer.Brand_IDs.Split(',') -contains '2' -and $customer.Brand_IDs.Split(',') -notcontains '4') 'Information-page targeting offers all active customer brands as a CSV without inactive memberships'
ContentRejected {ContentPage 'MULTI_INFO_INVALID_TARGET' @(1) @(2)} 'Named information-page targets must intersect the selected page brands' 51600
[void](Page "/CustomerPortal/InformationPage.aspx?id=$infoTwo&lang=en");Assert ($hostObject.Status -eq 200) 'A named information-page grant works through a second assigned brand'
[void](Page "/CustomerPortal/InformationPage.aspx?id=$infoOther");Assert ($hostObject.Status -eq 404) 'Membership alone never bypasses a page granted to another customer'

$circularOne=ContentCircular 'MULTI_CIRCULAR_ONE' 1
$circularTwo=ContentCircular 'MULTI_CIRCULAR_TWO' 2
$staffCircular=ContentCircular 'MULTI_CIRCULAR_STAFF_ONLY' 1 1 'all'
ContentRejected {ContentCircular 'MULTI_CIRCULAR_INVALID_TARGET' 3} 'A named circular customer must be assigned to its brand' 51800
$circulars=ContentRows 'EXEC dbo.Customer_Circulars @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert (@($circulars.Rows|Where-Object {$_.ID -in @($circularOne,$circularTwo)}).Count -eq 2 -and @($circulars.Rows|Where-Object ID -eq $staffCircular).Count -eq 0 -and $circulars.Columns.Contains('BrandName')) 'Circulars return both assigned brands and preserve employee audience separation'
$circularPage=Page '/CustomerPortal/Dashboard.aspx?brand=3'
Assert ($hostObject.Status -eq 200 -and $circularPage -match 'id="customerCircularTable"' -and $circularPage -match 'data-brand-id=[''"]2[''"]' -and $circularPage.Contains('MULTI_CIRCULAR_ONE') -and $circularPage.Contains('MULTI_CIRCULAR_TWO')) 'Circular dashboard table includes authorized rows and brand metadata'
$detail=ContentCustomerCircular $circularTwo
Assert ($detail.id -eq $circularTwo -and $detail.version -eq 1) 'Second-brand circular detail is protected and readable in the shared modal'
$csrf=[Web.HttpUtility]::HtmlDecode([regex]::Match($circularPage,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)
$noticeRows=ContentRows 'EXEC dbo.Customer_CircularNotifications @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert (@($noticeRows.Rows|Where-Object {$_.ID -in @($circularOne,$circularTwo)}).Count -eq 2) 'Notifications include eligible circulars from every assigned active brand'
Sql 'EXEC dbo.Circular_Dispatch;EXEC dbo.Circular_Dispatch;'
Sql "IF EXISTS(SELECT CircularID,Version,RecipientKind,RecipientID FROM Circular_CurrentRecipients GROUP BY CircularID,Version,RecipientKind,RecipientID HAVING COUNT(*)>1) THROW 51999,'Duplicate recipients',1;IF (SELECT COUNT(*) FROM Circular_Notices WHERE RecipientKind='customer' AND RecipientID=1 AND CircularID IN($circularOne,$circularTwo))<>2 THROW 51999,'Incorrect multi-brand notices',1;IF (SELECT COUNT(*) FROM Circular_Mail WHERE RecipientKind='customer' AND RecipientID=1 AND CircularID IN($circularOne,$circularTwo))<>2 THROW 51999,'Incorrect multi-brand mail',1;"
Assert $true 'Notice and mail materialization deduplicate each customer per circular version'
$mailId=(ContentRows "SELECT ID FROM Circular_Mail WHERE RecipientKind='customer' AND RecipientID=1 AND CircularID=$circularTwo").Rows[0].ID
$mailEmail=(ContentRows 'SELECT Email FROM CRM_Accounts WHERE ID=1').Rows[0].Email
Sql "UPDATE Circular_Mail SET Status='sending',ClaimedUtc=SYSUTCDATETIME() WHERE ID=$mailId;"
$mail=ContentRows 'EXEC dbo.Circular_MailValidate @ID=@id,@Email=@email' @{'@id'=$mailId;'@email'=$mailEmail}
Assert ($mail.Rows.Count -eq 1) 'An eligible second-brand mail validates before delivery'

Sql 'DELETE CRM_Account_Branches WHERE Account_ID=1 AND Brand_ID=2;DELETE CRM_Account_Brands WHERE Account_ID=1 AND Brand_ID=2;'
foreach($url in @('/CustomerPortal/NewsDetail.aspx?id=902',"/CustomerPortal/InformationPage.aspx?id=$infoTwo")){[void](Page $url);Assert ($hostObject.Status -eq 404) 'Removing one membership immediately revokes direct content links from that brand'}
[void](ContentCustomerCircular $circularTwo 404)
[void]($hostObject.RequestWithCsrf(("/CustomerPortal/CircularFile.aspx?ID=$circularTwo&action=view&event="+[guid]::NewGuid()),'fixture=1',$csrf));Assert ($hostObject.Status -eq 404) 'A previously opened PDF link rechecks current brand membership'
$noticeRows=ContentRows 'EXEC dbo.Customer_CircularNotifications @AccountID=1,@Stamp=@s' @{'@s'=$stamp}
Assert (@($noticeRows.Rows|Where-Object ID -eq $circularTwo).Count -eq 0 -and @($noticeRows.Rows|Where-Object ID -eq $circularOne).Count -eq 1) 'Revocation removes only the affected brand notification'
$mail=ContentRows 'EXEC dbo.Circular_MailValidate @ID=@id,@Email=@email' @{'@id'=$mailId;'@email'=$mailEmail}
Assert ($mail.Rows.Count -eq 0) 'Mail eligibility rechecks membership immediately before delivery'
Sql "UPDATE Circular_Mail SET Status='pending' WHERE ID=$mailId;EXEC Circular_Dispatch;IF NOT EXISTS(SELECT 1 FROM Circular_Mail WHERE ID=$mailId AND Status='cancelled') THROW 51999,'Revoked pending mail was not cancelled',1;"
[void](Page '/CustomerPortal/NewsDetail.aspx?id=901');Assert ($hostObject.Status -eq 200) 'Other brand content remains available after a single-brand revocation'
Sql "UPDATE Brands SET IsActive=0 WHERE ID=1;"
[void](Page '/CustomerPortal/NewsDetail.aspx?id=901');Assert ($hostObject.Status -eq 404) 'Pausing a remaining assigned brand immediately denies its news'
[void](Page "/CustomerPortal/InformationPage.aspx?id=$infoOne");Assert ($hostObject.Status -eq 404) 'Pausing a remaining assigned brand immediately denies its information pages'
[void](ContentCustomerCircular $circularOne 404)
Sql "UPDATE Brands SET IsActive=1 WHERE ID=1;"
[IO.File]::WriteAllText((Join-Path $output 'multi-brand-dashboard.html'),$dashboard,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'multi-brand-circulars.html'),$circularPage,[Text.UTF8Encoding]::new($true))
'PASS multi-brand content union, exact grants, management targeting, local filter markup, direct-link/file revocation, audience boundaries and deduplicated notice/mail eligibility.'
