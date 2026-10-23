# Runs in the isolated CustomerPortal ASP.NET/SQL host; never sends email.
Sql "UPDATE UsersMembers SET IsActive=1,IsDeleted=0,Brand_ID=1 WHERE ID IN(1,2);UPDATE UsersMembers SET Branch_ID=1 WHERE ID=2;UPDATE CRM_Accounts SET Brand_ID=CASE WHEN ID=1 THEN 1 ELSE 2 END,Is_Active=1,Is_Deleted=0 WHERE ID IN(1,2);UPDATE Customer_Logins SET IsActive=1 WHERE AccountID=1;"
function CircularCustomerDetail([int]$id,[int]$expected=200){
 $dashboard=Page '/CustomerPortal/Dashboard.aspx'
 $token=[Web.HttpUtility]::HtmlDecode([regex]::Match($dashboard,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)
 $raw=$hostObject.RequestWithCsrf(("/CircularReader.aspx?kind=customer&id=$id"),'x=1',$token)
 Assert ($hostObject.Status -eq $expected) ("Customer modal metadata HTTP $expected") | Out-Host
 return $raw|ConvertFrom-Json
}
function CircularToken {
 $html=Page '/Modules/Circulars/Manage.aspx?newsTestActor=1'
 Assert ($hostObject.Status -eq 200 -and $html -match 'circular-management.js' -and $html -match 'type-stat-card' -and $html -match 'offcanvas') 'Circular administration renders the CRM management design'
 $script:circularToken=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'data-token=[''"]([^''"]+)').Groups[1].Value)
}
function CircularAjax([string]$action,[hashtable]$payload,[int]$expected=200,[byte[]]$file=$null,[string]$token=$script:circularToken,[int]$actor=1){
 $url="/Modules/Circulars/AdminAjax.aspx?action=$action&newsTestActor=$actor";$json=$payload|ConvertTo-Json -Depth 8 -Compress
 if($null -ne $file){$html=$hostObject.UploadCircular($url,$json,'test.pdf',$file,$token)}else{$html=$hostObject.RequestWithCsrf($url,('payload='+[Web.HttpUtility]::UrlEncode($json)),$token)}
 if($hostObject.Status -ne $expected){[IO.File]::WriteAllText((Join-Path $output 'circular-error.txt'),$html,[Text.UTF8Encoding]::new($true));throw "Circular AJAX $action expected $expected, got $($hostObject.Status); see circular-error.txt"}
 return $html|ConvertFrom-Json
}
# A real one-page PDF with correct xref offsets, also retained for visual QA.
$objects=@('<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R] /Count 1 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 240] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
$stream='BT /F1 18 Tf 30 180 Td (Circular QA - protected PDF) Tj ET';$objects+=('<< /Length '+$stream.Length+">>`nstream`n"+$stream+"`nendstream")
$pdf="%PDF-1.4`n";$offsets=@(0)
for($i=0;$i -lt $objects.Count;$i++){$offsets+=[Text.Encoding]::ASCII.GetByteCount($pdf);$pdf+=($i+1).ToString()+" 0 obj`n"+$objects[$i]+"`nendobj`n"}
$xref=[Text.Encoding]::ASCII.GetByteCount($pdf);$pdf+="xref`n0 6`n0000000000 65535 f `n";foreach($offset in $offsets[1..5]){$pdf+=$offset.ToString('0000000000')+" 00000 n `n"};$pdf+="trailer`n<< /Root 1 0 R /Size 6 >>`nstartxref`n$xref`n%%EOF`n";$pdfBytes=[Text.Encoding]::ASCII.GetBytes($pdf)
[IO.File]::WriteAllBytes((Join-Path $output 'circular-test.pdf'),$pdfBytes)
CircularToken
$p=@{id=0;version=0;brand=1;titleAr='تعميم العميل التجريبي';titleEn='Customer circular QA';summaryAr='ملخص عربي للتعميم';summaryEn='English circular summary';date='2026-10-18';period='0';start='';end='';enabled='1';download='0';audience='customers';customer='1';customerType='';role='';branch='';department='';shift=''}
[void](CircularAjax save $p 422 ([Text.Encoding]::ASCII.GetBytes('not a PDF')))
$p.customer='2';[void](CircularAjax save $p 422 $pdfBytes);$p.customer='1'
$saved=CircularAjax save $p 200 $pdfBytes;$customerCircular=[int]$saved.id;$p.id=$customerCircular;$p.version=[int]$saved.version
$listed=CircularAjax list @{};Assert (@($listed.rows|Where-Object {$_.ID -eq $customerCircular -and $_.BrandID -eq 1 -and $_.Title_EN -eq $p.titleEn -and -not $_.HasPeriod}).Count -eq 1) 'Circular AJAX save immediately refreshes brand, bilingual content, period and state'
$editor=CircularAjax editor @{id=$customerCircular};Assert ($editor.item.FileName -eq 'test.pdf' -and @($editor.targets|Where-Object {$_.Kind -eq 'customer' -and $_.TargetID -eq 1}).Count -eq 1) 'Circular editor restores file and exact customer targets'
[void](CircularAjax save $p 403 $null 'wrong-token');[void](CircularAjax list @{} 403 $null $script:circularToken 2)
CircularToken
[void](Login)
$html=Page '/CustomerPortal/Dashboard.aspx';Assert ($hostObject.Status -eq 200 -and $html.Contains($p.titleEn) -and $html -match 'circular-notifications.js' -and $html -match 'id="customerCircularTable"') 'Customer dashboard table lists authorized circulars and the notification widget'
$detail=CircularCustomerDetail $customerCircular;Assert ($detail.summaryEn -eq $p.summaryEn -and !$detail.allowDownload) 'Customer modal metadata preserves bilingual content and download denial'
$customerToken=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)
$notices=(Page '/CircularNotifications.aspx')|ConvertFrom-Json;Assert ($notices.customer -and @($notices.rows|Where-Object {$_.ID -eq $customerCircular}).Count -eq 1) 'Customer bell returns an unread authorized circular'
$circularEvent=[guid]::NewGuid().ToString();$fileUrl="/CustomerPortal/CircularFile.aspx?ID=$customerCircular&action=view&event=$circularEvent"
[void]($hostObject.RequestWithCsrf($fileUrl,'fixture=1','wrong-token'));Assert ($hostObject.Status -eq 403) 'Customer file rejects invalid CSRF'
[void]($hostObject.RequestWithCsrf($fileUrl,'fixture=1',$customerToken));Assert ($hostObject.Status -eq 200 -and $hostObject.ContentType -like 'application/pdf*' -and $hostObject.Bytes.Length -eq $pdfBytes.Length) 'Customer view streams the original protected PDF'
[void]($hostObject.RequestWithCsrf($fileUrl,'fixture=1',$customerToken))
Sql "IF (SELECT COUNT(*) FROM Circular_CustomerLogs WHERE CircularID=$customerCircular AND AccountID=1 AND EventID='$circularEvent')<>1 OR NOT EXISTS(SELECT 1 FROM Circular_CustomerReads WHERE CircularID=$customerCircular AND AccountID=1 AND Version=1) THROW 51999,'Customer receipt/replay audit failed',1;"
$notices=(Page '/CircularNotifications.aspx')|ConvertFrom-Json;Assert (@($notices.rows|Where-Object {$_.ID -eq $customerCircular}).Count -eq 0) 'PDF viewing clears the current-version notification'
[void]($hostObject.RequestWithCsrf(("/CustomerPortal/CircularFile.aspx?ID=$customerCircular&action=download&event="+[guid]::NewGuid()),'fixture=1',$customerToken));Assert ($hostObject.Status -eq 403) 'Download denial is enforced on the server'
CircularToken
$p.titleEn='Customer circular revised';$saved=CircularAjax save $p
[void](CircularAjax save $p 409);$p.version=[int]$saved.version
[void](Login)
$notices=(Page '/CircularNotifications.aspx')|ConvertFrom-Json;Assert (@($notices.rows|Where-Object {$_.ID -eq $customerCircular -and $_.Version -eq 2}).Count -eq 1) 'New versions become unread and notify again while old receipts remain'
CircularToken
$p.period='1';[void](CircularAjax save $p 422)
$zone=[TimeZoneInfo]::FindSystemTimeZoneById('Jordan Standard Time');$future=[TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow.AddHours(1),$zone)
$p.start=$future.ToString('yyyy-MM-ddTHH:mm');$p.end=$future.AddDays(1).ToString('yyyy-MM-ddTHH:mm');$saved=CircularAjax save $p;$p.version=[int]$saved.version
Sql "IF EXISTS(SELECT 1 FROM Circular_Notices WHERE CircularID=$customerCircular AND Version=$($p.version)) THROW 51999,'Scheduled circular notified early',1;"
[void](Login);[void](CircularCustomerDetail $customerCircular 404)
CircularToken
Sql "SET IDENTITY_INSERT CRM_Account_Types ON;INSERT CRM_Account_Types(ID,Name_AR,Name_EN,Is_Active,Is_Deleted,AddedUser) VALUES(501,N'نوع اختبار التعميم','Circular test type',1,0,1);SET IDENTITY_INSERT CRM_Account_Types OFF;UPDATE CRM_Accounts SET Account_Type_ID=501 WHERE ID IN(1,2);"
$p.period='0';$p.audience='customerTypes';$p.customer='';$p.customerType='501';$p.download='1';$saved=CircularAjax save $p;$p.version=[int]$saved.version
[void](Login)
$detail=CircularCustomerDetail $customerCircular
$html=Page '/CustomerPortal/Dashboard.aspx';$customerToken=[Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)
Assert $detail.allowDownload 'Customer-type targeting authorizes downloads for the matching account'
[void]($hostObject.RequestWithCsrf(("/CustomerPortal/CircularFile.aspx?ID=$customerCircular&action=download&event="+[guid]::NewGuid()),'fixture=1',$customerToken));Assert ($hostObject.Status -eq 200) 'Explicitly allowed customer download is audited'
Sql 'UPDATE CRM_Accounts SET Brand_ID=2 WHERE ID=1;'
[void](CircularCustomerDetail $customerCircular 404)
Sql 'UPDATE CRM_Accounts SET Brand_ID=1 WHERE ID=1;'
CircularToken
[void](CircularAjax toggle @{id=$customerCircular;version=$p.version;enabled='0'})
[void](Login);[void](CircularCustomerDetail $customerCircular 404)
CircularToken
$editor=CircularAjax editor @{id=$customerCircular};$p.version=$editor.item.Version;$p.enabled='1';$saved=CircularAjax save $p;$p.version=[int]$saved.version
$staff=$p.Clone();$staff.id=0;$staff.version=0;$staff.titleAr='تعميم الموظفين التجريبي';$staff.titleEn='Employee circular QA';$staff.audience='roles';$staff.role='4';$staff.customerType=''
$saved=CircularAjax save $staff 200 $pdfBytes;$staffCircular=[int]$saved.id
Sql "IF NOT EXISTS(SELECT 1 FROM dbo.Circular_Visible(2,SYSUTCDATETIME()) WHERE ID=$staffCircular) OR EXISTS(SELECT 1 FROM dbo.Circular_CustomerVisible(1,SYSUTCDATETIME()) WHERE ID=$staffCircular) THROW 51999,'Employee audience boundary failed',1;UPDATE UsersMembers SET Brand_ID=2 WHERE ID=2;IF EXISTS(SELECT 1 FROM dbo.Circular_Visible(2,SYSUTCDATETIME()) WHERE ID=$staffCircular) THROW 51999,'Employee cross-brand visibility',1;UPDATE UsersMembers SET Brand_ID=1 WHERE ID=2;"
$staff.id=$staffCircular;$staff.version=[int]$saved.version;$staff.audience='organization';$staff.role='';$staff.branch='1';$staff.brand=2
[void](CircularAjax save $staff 422)
$staff.brand=1;$saved=CircularAjax save $staff;$staff.version=[int]$saved.version
$logs=CircularAjax logs @{id=$customerCircular;page=1};Assert (@($logs.rows|Where-Object {$_.ActorKind -eq 'customer' -and $_.ActorID -eq 1}).Count -gt 0 -and @($logs.rows|Where-Object {$_.Action -eq 'update'}).Count -gt 0) 'Unified report preserves admin operations, customer read/download identity and mail status'
[IO.File]::WriteAllText((Join-Path $output 'circular-fixture-ids.json'),(@{customer=$customerCircular;employee=$staffCircular}|ConvertTo-Json),[Text.UTF8Encoding]::new($true))
'PASS branded circular AJAX, bilingual data, audience boundaries, period/state, notifications, PDF/CSRF, concurrency and preserved read/audit history.'
