# Dot-sourced by TestBrandAccess inside its disposable database. Real customer authorization is reused.
$stamp='11111111-1111-1111-1111-111111111111'
$fields="@TitleAr=N'جمهور اختباري',@TitleEn=N'Audience test',@SummaryAr=N's',@SummaryEn=N's',@DetailsAr=N'<p>عربي</p>',@DetailsEn=N'<p>English</p>',@Order=1,@Published=1,@Mode='immediate'"
$r=Q "EXEC dbo.Save_Information_Page @Actor=1,@ID=0,@ExpectedVersion=0,$fields,@AllTypes=1,@ExpectedAccessRevision=0,@Brands='<brands><brand id=""29""/></brands>'";$page=[int]$r.Rows[0].ID
$r=Q "SELECT Audience,AllCustomers FROM Information_Pages WHERE ID=$page";Check ($r.Rows[0].Audience -eq 'employees' -and -not $r.Rows[0].AllCustomers) 'Legacy page creation grants employees only'
Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51912 'Employee page cannot be opened by a customer'
function SetAudience([string]$audience,[int]$allCustomers,[string]$customers='<customers/>'){
 $revision=[int](Q "SELECT AccessRevision FROM Information_Pages WHERE ID=$page").Rows[0].AccessRevision
 N "EXEC Save_Information_Page_Access @Actor=1,@ID=$page,@ExpectedRevision=$revision,@AllTypes=1,@Roles='<roles/>',@Audience='$audience',@AllCustomers=$allCustomers,@Customers='$customers'"
}
SetAudience 'customers' 0 '<customers><customer id="101"/><customer id="101"/></customers>'
$r=Q "SELECT VersionNumber,AccessRevision FROM Information_Pages WHERE ID=$page";Check ($r.Rows[0].VersionNumber -eq 1 -and $r.Rows[0].AccessRevision -eq 2) 'Audience/customer-only edit changes access revision without content version'
$r=Q "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp'";Check (@($r.Rows|Where-Object ID -eq $page).Count -eq 1 -and $r.Rows[0].Details_En -eq '') 'Selected customer sees summary list without full content'
$r=Q "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page,@Language='en',@LogVisit=1";Check ($r.Rows[0].Details_En -eq '<p>English</p>') 'Selected customer can read English details'
Deny "EXEC Customer_InformationPages @AccountID=102,@Stamp='$stamp',@ID=$page,@LogVisit=1" 51912 'Unselected customer cannot open direct page link'
foreach($actor in @(151,1)){
 $r=Q "EXEC Select_Information_Pages @Actor=$actor";Check (@($r.Rows|Where-Object ID -eq $page).Count -eq 0) "Customer-only page excluded from employee $actor navigation"
 $r=Q "EXEC MobileApi_InfoPages @Actor=$actor";Check (@($r.Rows|Where-Object ID -eq $page).Count -eq 0) "Customer-only page excluded from employee $actor mobile API"
 Deny "EXEC Select_Information_Page @Actor=$actor,@ID=$page" 51604 "Customer-only ordinary employee $actor direct URL denied"
}
$r=Q "EXEC Select_Information_Page @Actor=1,@ID=$page,@Admin=1";Check ($r.Rows.Count -eq 1) 'Administrator can manage/preview customer-only content'
$r=Q "SELECT * FROM Information_Page_Logs WHERE PageID=$page AND Action='view'";Check ($r.Rows.Count -eq 1 -and $r.Rows[0].ActorID -eq 0 -and $r.Rows[0].CustomerAccountID -eq 101 -and $r.Rows[0].ActorName -eq 'عميل أول' -and $r.Rows[0].Language -eq 'en') 'Customer visit audit retains real customer identity and denies create no successful visits'
$r=Q "SELECT * FROM Customer_Portal_Activity WHERE RecordID=$page AND Action='information-view'";Check ($r.Rows.Count -eq 1 -and $r.Rows[0].AccountID -eq 101) 'Customer portal activity includes information-page visit'
$r=Q "SELECT TOP(1) Details FROM Information_Page_Logs WHERE PageID=$page AND Action='access' ORDER BY ID DESC";Check ($r.Rows[0].Details.Contains('عميل أول') -and $r.Rows[0].Details.Contains('employees') -and $r.Rows[0].Details.Contains('customers')) 'Audience audit records named before/after customer scope'
$revision=[int](Q "SELECT AccessRevision FROM Information_Pages WHERE ID=$page").Rows[0].AccessRevision
foreach($bad in @('<customers/>','<customers><customer id="999"/></customers>','<customers><customer id="103"/></customers>','<customers><customer id="104"/></customers>','<customers><customer id="105"/></customers>')){
 Deny "EXEC Save_Information_Page_Access @Actor=1,@ID=$page,@ExpectedRevision=$revision,@AllTypes=1,@Roles='<roles/>',@Audience='customers',@AllCustomers=0,@Customers='$bad'" 51600 'Empty/missing/cross-brand/inactive/deleted customer selection rejected'
}
Deny "EXEC Select_Information_Page_Customers @Actor=151,@ID=$page" 51600 'Customer permission choices remain administrator-only'
N "EXEC Save_Information_Page_Access @Actor=1,@ID=$page,@ExpectedRevision=$revision,@AllTypes=1,@Roles='<roles/>'"
$r=Q "SELECT Audience,AllCustomers,AccessRevision FROM Information_Pages WHERE ID=$page";Check ($r.Rows[0].Audience -eq 'customers' -and -not $r.Rows[0].AllCustomers -and $r.Rows[0].AccessRevision -eq $revision) 'Legacy access call preserves existing customer grants'
N "EXEC Save_Information_Page @Actor=1,@ID=$page,@ExpectedVersion=1,$($fields.Replace('English','Changed'))"
N "EXEC Restore_Information_Page @Actor=1,@ID=$page,@SourceVersion=1,@ExpectedVersion=2"
$r=Q "SELECT p.Audience,p.AccessRevision,c.AccountID FROM Information_Pages p JOIN Information_Page_Customers c ON c.PageID=p.ID WHERE p.ID=$page";Check ($r.Rows.Count -eq 1 -and $r.Rows[0].AccountID -eq 101 -and $r.Rows[0].Audience -eq 'customers' -and $r.Rows[0].AccessRevision -eq $revision) 'Legacy content save and content restore preserve customer access'
SetAudience 'customers' 1
$r=Q "EXEC Customer_InformationPages @AccountID=102,@Stamp='$stamp',@ID=$page";Check ($r.Rows.Count -eq 1) 'All-customers mode admits another customer in page brand'
Deny "EXEC Customer_InformationPages @AccountID=103,@Stamp='$stamp',@ID=$page" 51912 'All customers still respects selected page brands'
SetAudience 'all' 0
$r=Q "SELECT AllUserTypes,AllCustomers FROM Information_Pages WHERE ID=$page";Check ($r.Rows[0].AllUserTypes -and $r.Rows[0].AllCustomers) 'Everyone canonically grants all employee types and all customers'
$r=Q "EXEC Select_Information_Page @Actor=152,@ID=$page";Check ($r.Rows.Count -eq 1) 'Everyone grants another employee type in the selected brand'
$r=Q "EXEC Customer_InformationPages @AccountID=102,@Stamp='$stamp',@ID=$page";Check ($r.Rows.Count -eq 1) 'Everyone grants customers too'
$revision=[int](Q "SELECT AccessRevision FROM Information_Pages WHERE ID=$page").Rows[0].AccessRevision
Deny "EXEC Save_Information_Page @Actor=1,@ID=$page,@ExpectedVersion=3,$($fields.Replace('English','Stale content')),@AllTypes=1,@ExpectedAccessRevision=2,@Audience='employees',@AllCustomers=0" 51600 'Stale shared access revision rolls back combined content/audience update'
$r=Q "SELECT VersionNumber,Details_En,Audience FROM Information_Pages WHERE ID=$page";Check ($r.Rows[0].VersionNumber -eq 3 -and $r.Rows[0].Details_En -eq '<p>English</p>' -and $r.Rows[0].Audience -eq 'all') 'Failed combined update is fully atomic'
foreach($state in @('UPDATE Customer_Logins SET IsActive=0 WHERE AccountID=101','UPDATE CRM_Accounts SET Is_Active=0 WHERE ID=101','UPDATE CRM_Accounts SET Is_Deleted=1 WHERE ID=101')){
 N $state;Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51911 'Current inactive/deleted customer or disabled login denied';N 'UPDATE Customer_Logins SET IsActive=1 WHERE AccountID=101;UPDATE CRM_Accounts SET Is_Active=1,Is_Deleted=0 WHERE ID=101'
}
Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='22222222-2222-2222-2222-222222222222',@ID=$page" 51911 'Stale credential stamp denied'
N 'UPDATE CRM_Accounts SET Brand_ID=30 WHERE ID=101';Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51912 'Current customer brand controls access immediately';N 'UPDATE CRM_Accounts SET Brand_ID=29 WHERE ID=101'
N 'UPDATE Brands SET IsActive=0 WHERE ID=29';Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51912 'Disabled brand blocks customer content';N 'UPDATE Brands SET IsActive=1 WHERE ID=29'
foreach($state in @('IsPublished=0','IsDeleted=1',"PublishMode='scheduled',StartUtc=DATEADD(hour,1,SYSUTCDATETIME()),EndUtc=DATEADD(hour,2,SYSUTCDATETIME())","PublishMode='scheduled',StartUtc=DATEADD(hour,-2,SYSUTCDATETIME()),EndUtc=SYSUTCDATETIME()")){
 N "UPDATE Information_Pages SET $state WHERE ID=$page";Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51912 'Unpublished/deleted/future/expired customer page denied';N "UPDATE Information_Pages SET IsPublished=1,IsDeleted=0,PublishMode='immediate',StartUtc=NULL,EndUtc=NULL WHERE ID=$page"
}
SetAudience 'employees' 0
Deny "EXEC Customer_InformationPages @AccountID=101,@Stamp='$stamp',@ID=$page" 51912 'Changing audience immediately revokes customer direct URL'
$r=Q "SELECT COUNT(*) C FROM Information_Page_Customers WHERE PageID=$page";Check ($r.Rows[0].C -eq 0) 'Leaving customer scope removes stale individual grants'
'Audience authorization and compatibility checks passed.'
