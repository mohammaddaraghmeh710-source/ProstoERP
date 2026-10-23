# Sourced after Test-MultiBrandContent.ps1 by the isolated CustomerPortal ASP.NET host.
if($builder.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'Only an isolated customer fixture is permitted.'}
function ReaderToken([string]$html){return [Web.HttpUtility]::HtmlDecode([regex]::Match($html,'id="circularReader"[^>]*data-csrf="([^"]+)"').Groups[1].Value)}
function ReaderMetadata([string]$kind,[int]$id,[string]$token,[int]$expected=200,[string]$suffix=''){
 $raw=$hostObject.RequestWithCsrf(("/CircularReader.aspx?kind=$kind&id=$id"+$suffix),'x=1',$token)
 if($hostObject.Status -ne $expected){[IO.File]::WriteAllText((Join-Path $output 'circular-reader-error.json'),$raw);throw "Reader $kind expected HTTP $expected, got $($hostObject.Status). See circular-reader-error.json"}
 return $raw|ConvertFrom-Json
}
function ReaderFile([string]$url,[string]$token,[int]$expected=200){
 [void]($hostObject.RequestWithCsrf($url,'x=1',$token))
 Assert ($hostObject.Status -eq $expected) ("Protected reader file returns HTTP $expected")
}
function ReaderRowState([string]$html,[int]$id,[int]$read){
 return @([regex]::Matches($html,'<tr\b[^>]*>')|Where-Object {$_.Value -match ('data-circular-id=[''"]'+$id+'[''"]') -and $_.Value -match ('data-read=[''"]'+$read+'[''"]')}).Count -eq 1
}
Sql 'UPDATE Brands SET IsActive=1,IsDeleted=0 WHERE ID IN(1,2);UPDATE UsersMembers SET IsActive=1,IsDeleted=0,Brand_ID=1,Branch_ID=1 WHERE ID IN(1,2);INSERT CRM_Account_Brands(Account_ID,Brand_ID,AddedUser) SELECT v.ID,1,1 FROM(VALUES(1),(2))v(ID) WHERE NOT EXISTS(SELECT 1 FROM CRM_Account_Brands ab WHERE ab.Account_ID=v.ID AND ab.Brand_ID=1);'
$readerCustomer=ContentCircular 'TABLE_READER_CUSTOMER' 1
$readerPrivate=ContentCircular 'TABLE_READER_OTHER_CUSTOMER' 1 2
$readerEmployee=ContentCircular 'TABLE_READER_EMPLOYEE' 1 1 'all'
[void](Login)
$html=Page '/CustomerPortal/Dashboard.aspx'
$customerCsrf=ReaderToken $html
Assert ($hostObject.Status -eq 200 -and $html -match 'id="customerCircularTable"' -and $html -match 'data-circular-row' -and $html -match 'card-list-table' -and $html -match 'TABLE_READER_CUSTOMER' -and $html -notmatch 'TABLE_READER_OTHER_CUSTOMER|TABLE_READER_EMPLOYEE') 'Dashboard table lists only the customer circular audience with responsive card rows'
Assert ($html -match 'data-circular-open' -and $html -match 'data-circular-id' -and $html -match 'data-read-badge' -and $html -match 'data-read=' -and $customerCsrf.Length -gt 20 -and [regex]::Matches($html,'id="circularReader"').Count -eq 1) 'Customer table and one shared modal expose current-version read state and view controls'
Assert ($html -match 'data-circular-name-filter' -and $html -match 'data-circular-brand-filter' -and $html -match 'data-circular-read-filter' -and (ReaderRowState $html $readerCustomer 0)) 'Customer table exposes local name, brand and read-state filters with an unread initial row'
[void](Page ("/CustomerPortal/Circulars.aspx?ID=$readerCustomer"));Assert ($hostObject.Status -eq 302 -and $hostObject.Location -match ('(?:^|/)Dashboard\.aspx\?circular='+$readerCustomer+'#customerCirculars$')) ("Legacy customer circular links redirect to the dashboard modal (HTTP $($hostObject.Status), Location $($hostObject.Location))")
$html=Page ("/CustomerPortal/Dashboard.aspx?circular=$readerCustomer")
Assert ($html -match ('data-initial-id="'+$readerCustomer+'"')) 'A dashboard circular deep link initializes the shared modal'
[void]($hostObject.Request(("/CircularReader.aspx?kind=customer&id=$readerCustomer"),$null));Assert ($hostObject.Status -eq 405) 'Circular metadata requires POST'
[void](ReaderMetadata customer $readerCustomer 'wrong-token' 403)
$before=(ContentRows 'SELECT COUNT(*) N FROM Circular_CustomerReads WHERE CircularID=@id AND AccountID=1' @{'@id'=$readerCustomer}).Rows[0].N
$metadata=ReaderMetadata customer $readerCustomer $customerCsrf
Assert ($metadata.id -eq $readerCustomer -and $metadata.version -eq 1 -and !$metadata.admin -and !$metadata.isRead -and $metadata.title -eq 'TABLE_READER_CUSTOMER' -and $metadata.summaryEn -eq 'Circular summary' -and $metadata.fileUrl -like '/CustomerPortal/CircularFile.aspx?ID=*') 'Customer modal metadata contains current bilingual content, date and the protected file URL'
Assert ((ContentRows 'SELECT COUNT(*) N FROM Circular_CustomerReads WHERE CircularID=@id AND AccountID=1' @{'@id'=$readerCustomer}).Rows[0].N -eq $before) 'Reading modal metadata alone does not record PDF readership'
[void](ReaderMetadata customer $readerPrivate $customerCsrf 404 '&accountID=2')
[void](ReaderMetadata customer $readerEmployee $customerCsrf 404)
ReaderFile ($metadata.fileUrl+'&action=view&version=2&event='+[guid]::NewGuid()) $customerCsrf 409
Assert ((ContentRows 'SELECT COUNT(*) N FROM Circular_CustomerReads WHERE CircularID=@id AND AccountID=1' @{'@id'=$readerCustomer}).Rows[0].N -eq $before) 'A mismatched PDF version records no customer read receipt'
ReaderFile ($metadata.fileUrl+'&action=view&version=1&event='+[guid]::NewGuid()) $customerCsrf
Assert ($hostObject.ContentType -like 'application/pdf*') 'Automatic modal PDF loading streams protected PDF bytes'
$metadata=ReaderMetadata customer $readerCustomer $customerCsrf
Assert $metadata.isRead 'A successful PDF view marks the exact displayed customer version as read'
Sql "IF NOT EXISTS(SELECT 1 FROM Circular_CustomerReads WHERE CircularID=$readerCustomer AND Version=1 AND AccountID=1) THROW 51999,'Missing exact-version receipt',1;EXEC Circular_AdminToggle @Actor=1,@ID=$readerCustomer,@ExpectedVersion=1,@Enabled=1;"
ReaderFile ($metadata.fileUrl+'&action=view&version=1&event='+[guid]::NewGuid()) $customerCsrf 409
$metadata=ReaderMetadata customer $readerCustomer $customerCsrf
Assert ($metadata.version -eq 2 -and !$metadata.isRead) 'An updated circular is unread while the previous version receipt is retained'
ReaderFile ($metadata.fileUrl+'&action=view&version=2&event='+[guid]::NewGuid()) $customerCsrf
$readDashboard=Page '/CustomerPortal/Dashboard.aspx'
Assert (ReaderRowState $readDashboard $readerCustomer 1) 'The customer table renders the current-version read state after PDF viewing'

$admin=Page '/Modules/Circulars/Manage.aspx?newsTestActor=1'
$adminCsrf=ReaderToken $admin
Assert ($hostObject.Status -eq 200 -and $admin -match 'card-list-table' -and $admin -match 'data-enhanced="1"' -and $admin -match 'data-kind="admin"' -and [regex]::Matches($admin,'id="circularReader"').Count -eq 1) 'Circular administration preserves its enhanced CRM table and has one protected preview modal'
$adminMenu=[regex]::Match($admin,'<li class="menu-item"><a class="menu-link" href=[''"](/Modules/Circulars/Manage.aspx)[''"]><i class="menu-icon tf-icons bx bx-broadcast".*?</li>','Singleline').Value
Assert ($adminMenu.Length -gt 0 -and $adminMenu -notmatch 'menu-toggle|menu-sub') 'Administrator circular navigation is one direct management link without subitems'
$deep=Page ("/Modules/Circulars/Manage.aspx?view=$readerEmployee&newsTestActor=1")
Assert ($deep -match ('data-initial-id="'+$readerEmployee+'"')) 'Administrator preview deep links initialize the modal in management'
$adminMeta=ReaderMetadata admin $readerEmployee $adminCsrf 200 '&newsTestActor=1'
Assert ($adminMeta.admin -and $adminMeta.fileUrl -like '*admin=1') 'Administrative metadata is explicitly preview-only'
ReaderFile ($adminMeta.fileUrl+'&action=view&version='+$adminMeta.version+'&event='+[guid]::NewGuid()+'&newsTestActor=1') $adminCsrf
Sql "IF EXISTS(SELECT 1 FROM Circular_Reads WHERE CircularID=$readerEmployee AND UserID=1) THROW 51999,'Admin preview counted as employee readership',1;IF NOT EXISTS(SELECT 1 FROM Circular_Logs WHERE CircularID=$readerEmployee AND UserID=1 AND Action='preview') THROW 51999,'Admin preview audit missing',1;"
Assert $true 'Admin preview is audited without recording an employee read receipt'

$employee=Page '/Modules/Circulars/Index.aspx?newsTestActor=2'
$employeeCsrf=ReaderToken $employee
Assert ($hostObject.Status -eq 200 -and $employee -match 'id="employeeCircularTable"' -and $employee -match 'card-list-table' -and $employee -match 'TABLE_READER_EMPLOYEE' -and $employee -notmatch 'TABLE_READER_OTHER_CUSTOMER|TABLE_READER_CUSTOMER') 'Employee circulars use the responsive table and preserve the employee audience boundary'
$employeeMenu=[regex]::Match($employee,'<li class="menu-item"><a class="menu-link" href=[''"](/Modules/Circulars/Index.aspx)[''"]><i class="menu-icon tf-icons bx bx-broadcast".*?</li>','Singleline').Value
Assert ($employeeMenu.Length -gt 0 -and $employeeMenu -notmatch 'menu-toggle|menu-sub') 'Employee circular navigation is a direct reader-table link'
[void](ReaderMetadata admin $readerEmployee $employeeCsrf 403 '&newsTestActor=2')
[void](ReaderMetadata employee $readerCustomer $employeeCsrf 404 '&newsTestActor=2')
$employeeMeta=ReaderMetadata employee $readerEmployee $employeeCsrf 200 '&newsTestActor=2'
Assert (!$employeeMeta.admin -and !$employeeMeta.isRead) 'Employee metadata loads without falsely marking a circular as read'
ReaderFile ($employeeMeta.fileUrl+'&action=view&version=2&event='+[guid]::NewGuid()+'&newsTestActor=2') $employeeCsrf 409
ReaderFile ($employeeMeta.fileUrl+'&action=view&version=1&event='+[guid]::NewGuid()+'&newsTestActor=2') $employeeCsrf
Sql "IF NOT EXISTS(SELECT 1 FROM Circular_Reads WHERE CircularID=$readerEmployee AND Version=1 AND UserID=2) THROW 51999,'Employee exact-version receipt missing',1;"
Assert $true 'Employee file viewing records its current version and real employee identity'
$employeeRead=Page '/Modules/Circulars/Index.aspx?newsTestActor=2'
Assert (ReaderRowState $employeeRead $readerEmployee 1) 'The employee table reflects current-version readership after opening the PDF'
[void](Page ("/Modules/Circulars/Index.aspx?ID=$readerEmployee&admin=1&newsTestActor=1"));Assert ($hostObject.Status -eq 302 -and $hostObject.Location -match ('(?:^|/)Manage\.aspx\?view='+$readerEmployee+'$')) ("Legacy administrative preview links redirect to the management modal (HTTP $($hostObject.Status), Location $($hostObject.Location))")
[void](Login)
[void](ReaderMetadata admin $readerEmployee $adminCsrf 403)
[void](ReaderMetadata employee $readerEmployee $employeeCsrf 403)
[IO.File]::WriteAllText((Join-Path $output 'circular-table-admin.html'),$admin,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'circular-table-employee.html'),$employee,[Text.UTF8Encoding]::new($true))
'PASS circular tables, direct navigation, shared modal metadata, CSRF/identity/audience boundaries, exact-version PDFs and preview/read audit semantics.'
