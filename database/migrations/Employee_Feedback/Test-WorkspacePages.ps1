# Sourced by the isolated customer ASP.NET host after the full feedback fixture.
if($builder.InitialCatalog -notmatch '^Prosto_Customer_Test_[a-f0-9]{32}$'){throw 'Only isolated feedback fixtures are permitted.'}
function FeedbackRows([string]$query){$cn=[Data.SqlClient.SqlConnection]::new($TestConnection);try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText=$query;$set=[Data.DataSet]::new();[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($set);if($set.Tables.Count){return ,$set.Tables[0]}}finally{$cn.Dispose()}}
function FeedbackForm([string]$html,[hashtable]$values){
 foreach($input in [regex]::Matches($html,'<input[^>]+type="hidden"[^>]*>')){$name=[regex]::Match($input.Value,'name="([^"]+)"').Groups[1].Value;$value=[regex]::Match($input.Value,'value="([^"]*)"').Groups[1].Value;if($name){$values[$name]=[Web.HttpUtility]::HtmlDecode($value)}}
 return ($values.GetEnumerator()|ForEach-Object{[Web.HttpUtility]::UrlEncode($_.Key)+'='+[Web.HttpUtility]::UrlEncode([string]$_.Value)}) -join '&'
}
function FeedbackSelect([string]$html,[string]$id){return [regex]::Match($html,'<select\b[^>]*id="[^"]*'+$id+'"[^>]*>.*?</select>','Singleline').Value}
function FeedbackFixtureFile([string]$extension,[byte[]]$bytes){
 $name=[guid]::NewGuid().ToString('N')+'.'+$extension
 [void][IO.Directory]::CreateDirectory((Join-Path $stage 'App_Data/EmployeeFeedback'))
 [IO.File]::WriteAllBytes((Join-Path $stage ('App_Data/EmployeeFeedback/'+$name)),$bytes)
 return $name
}
function AssertFeedbackAttachment([int]$id,[byte[]]$bytes,[string]$mime,[bool]$canPreview,[string]$label){
 [void]($hostObject.Request(("/CustomerPortal/FeedbackFile.aspx?id=$id"),$null))
 Assert ($hostObject.Status -eq 200 -and $hostObject.ContentType -eq 'application/octet-stream' -and $hostObject.ContentDisposition -like 'attachment;*' -and [Convert]::ToBase64String($hostObject.Bytes) -eq [Convert]::ToBase64String($bytes)) ("Owner downloads exact $label bytes as an attachment")
 [void]($hostObject.Request(("/CustomerPortal/FeedbackFile.aspx?id=$id&preview=1"),$null))
 $disposition=if($canPreview){'inline;*'}else{'attachment;*'}
 Assert ($hostObject.Status -eq 200 -and $hostObject.ContentType -eq $mime -and $hostObject.ContentDisposition -like $disposition -and [Convert]::ToBase64String($hostObject.Bytes) -eq [Convert]::ToBase64String($bytes)) ("Owner preview handles $label with the expected MIME and disposition")
}
function AssertFeedbackDetailLayout([string]$html,[string]$prefix,[int]$id,[string]$title,[string]$label){
 $card=[regex]::Match($html,'<div\b[^>]*\bclass=["\x27][^"\x27]*\binvoice-preview-card\b[^"\x27]*["\x27][^>]*>','IgnoreCase')
 $summaryElement=[regex]::Match($html,'<section\b[^>]*\bclass=["\x27][^"\x27]*\bfeedback-request-summary\b[^"\x27]*["\x27][^>]*>','IgnoreCase')
 $informationPane=[regex]::Match($html,'<div\b[^>]*\bid=["\x27]'+[regex]::Escape($prefix+'-details')+'["\x27][^>]*>','IgnoreCase')
 $workflow=[regex]::Match($html,'<div\b[^>]*\bid=["\x27]'+[regex]::Escape($prefix+'-workflow')+'["\x27][^>]*>','IgnoreCase')
 $toggle=[regex]::Match($html,'<button\b(?=[^>]*\bdata-bs-target=["\x27]#'+[regex]::Escape($prefix+'-workflow')+'["\x27])[^>]*>.*?</button>','Singleline')
 $workflowCollapse=[regex]::Match($html,'<button\b(?=[^>]*\bdata-bs-target=["\x27]#'+[regex]::Escape($prefix+'-workflow')+'["\x27])(?=[^>]*\bdata-bs-toggle=["\x27]collapse["\x27])[^>]*>','Singleline')
 $informationTab=[regex]::Match($html,'<button\b(?=[^>]*\bdata-bs-target=["\x27]#'+[regex]::Escape($prefix+'-details')+'["\x27])[^>]*>.*?</button>','Singleline')
 Assert ($card.Success -and $summaryElement.Success -and $informationPane.Success -and $informationPane.Value -match '\brole=["\x27]tabpanel["\x27]' -and $informationPane.Value -match '\bclass=["\x27](?=[^"\x27]*\btab-pane\b)(?=[^"\x27]*\bactive\b)[^"\x27]*["\x27]' -and $informationTab.Success -and $informationTab.Value -match 'data-bs-toggle=["\x27]tab["\x27]' -and $informationTab.Value -match 'معلومات الطلب') ("$label opens the compact request information tab by default")
 Assert ($workflow.Success -and $workflow.Index -gt $summaryElement.Index -and $workflow.Value -match '\brole=["\x27]tabpanel["\x27]' -and $workflow.Value -match '\bclass=["\x27](?=[^"\x27]*\btab-pane\b)(?![^"\x27]*\bactive\b)[^"\x27]*["\x27]' -and $toggle.Success -and $toggle.Value -match '\btype=["\x27]button["\x27]' -and $toggle.Value -match 'data-bs-toggle=["\x27]tab["\x27]' -and $toggle.Value -match 'سير العمل' -and -not $workflowCollapse.Success) ("$label exposes workflow through a local Template tab without a collapse button")
 if($prefix -eq 'customer-feedback'){
  Assert ($html -notmatch 'data-bs-target=["\x27]#(?:feedback-actions|pnlLogs)["\x27]') 'Customer details expose only information and workflow tabs'
 }else{
  Assert ($html -match 'data-bs-target=["\x27]#feedback-actions["\x27]' -and $html -match 'id=["\x27]feedback-actions["\x27][^>]*role=["\x27]tabpanel["\x27]' -and $html -match 'data-bs-target=["\x27]#pnlLogs["\x27]' -and $html -match 'id=["\x27]pnlLogs["\x27]') 'Administrator details retain actions and authorized logs tabs'
 }
 $information=$html.Substring($summaryElement.Index,$workflow.Index-$summaryElement.Index)
 $summary=$information.IndexOf('feedback-request-summary');$body=$information.IndexOf('feedback-request-body');$applicant=$information.IndexOf('feedback-request-applicant');$titleAt=$information.IndexOf([Web.HttpUtility]::HtmlEncode($title))
 $requestHeader=if($summary -ge 0 -and $body -gt $summary){$information.Substring($summary,$body-$summary)}else{''}
 $applicantName=[string](FeedbackRows "SELECT ApplicantName FROM Employee_Feedback_Requests WHERE ID=$id").Rows[0].ApplicantName
 $applicantAt=if($applicant -ge 0){$information.IndexOf([Web.HttpUtility]::HtmlEncode($applicantName),$applicant)}else{-1}
 Assert ($summary -ge 0 -and $titleAt -gt $summary -and $body -gt $titleAt -and $applicant -gt $body -and $applicantName -ne '' -and $applicantAt -gt $applicant -and $requestHeader -match ('رقم الطلب:?\s*</dt>\s*<dd\b[^>]*>\s*#'+$id+'\s*</dd>') -and $requestHeader -match 'id="[^"]*lblSource"' -and $requestHeader -match 'id="[^"]*lblType"' -and $requestHeader -match 'id="[^"]*lblStatus"') ("$label orders request badges and title, complaint text, then applicant information on one page")
 Assert ($html -notmatch '\bfeedback-detail-heading\b' -and $information -notmatch '<aside\b' -and $information -match '\bcard-body\b' -and $information -match 'row g-3 align-items-stretch' -and $information -match 'col-12 col-lg-8 feedback-request-body' -and $information -match 'col-12 col-lg-4 feedback-request-applicant' -and $information -match '<hr class="my-0"' -and $html -match 'feedback-detail-card') ("$label retains compact Template information sections and responsive detail/applicant columns inside its information tab")
 $footerElement=[regex]::Match($html,'<div\b[^>]*\bclass=["\x27][^"\x27]*\bfeedback-detail-footer\b[^"\x27]*["\x27][^>]*>.*?</div>','Singleline')
 $back=[regex]::Match($footerElement.Value,'<a\b[^>]*>(?:(?!</a>).)*?العودة للقائمة\s*</a>','Singleline')
 $href=[regex]::Match($back.Value,'\bhref=["\x27]([^"\x27]+)["\x27]').Groups[1].Value
 $expected=if($prefix -eq 'customer-feedback'){'Feedback.aspx'}else{'ManageEmployeeFeedback.aspx'}
 $full=if($prefix -eq 'customer-feedback'){'/CustomerPortal/Feedback.aspx'}else{'/Modules/Employee_Feedback/ManageEmployeeFeedback.aspx'}
 Assert ($footerElement.Success -and $back.Success -and $back.Index -gt 0 -and $footerElement.Index -gt $workflow.Index -and $workflow.Index -gt $summaryElement.Index -and $back.Value -match '\bclass=["\x27][^"\x27]*\bbtn-primary\b' -and ($href -eq $expected -or $href -eq $full) -and $back.Value -notmatch 'history\.back|javascript:') ("$label has a blue bottom link to the full follow-up list without source/report filtering")
}

[void](Login)
$html=Page '/CustomerPortal/Feedback.aspx'
$listTable=[regex]::Match($html,'<table\b[^>]*\bid="ERPTable"[^>]*>','IgnoreCase').Value
Assert ($listTable -match 'data-enhanced="1"' -and $listTable -match '\bERP_ProstoTBL\b' -and $listTable -match '\bcard-list-table\b' -and $listTable -match '\bcrm-table\b' -and $html -match '\bcrm-shell\b' -and $html -match 'data-customer-feedback-search' -and $html -match 'data-customer-feedback-brand-filter' -and $html -match 'data-customer-feedback-status') 'Customer complaints reuse the CRM enhanced table and local name, brand and status filters'
$listToolbar=[regex]::Match($html,'<[^>]+\bid="pnlTableActions"[^>]*>.*?</div>','Singleline').Value
Assert ($listToolbar -match 'type-toolbar-controls' -and $listToolbar -match 'data-bs-target="#customerFeedbackWizard"' -and $html.IndexOf('id="pnlTableActions"') -lt $html.IndexOf('id="ERPTable"') -and $html -match '/assets/js/crm-list\.js' -and $html -match '/assets/css/crm-list\.css') 'The same-page add action uses the standard CRM toolbar and shared search, page-length and pagination initializer'
$listRows=@([regex]::Matches($html,'<tr\b[^>]*data-customer-feedback-row=["\x27]1["\x27][^>]*>.*?</tr>','Singleline'))
Assert ($listRows.Count -gt 0 -and @($listRows|Where-Object {$_.Value -notmatch 'data-title="الطلب"' -or $_.Value -notmatch 'data-title="الحالة"' -or $_.Value -notmatch 'type-row-action' -or $_.Value -notmatch 'data-bs-toggle="tooltip"' -or $_.Value -notmatch 'fa-solid fa-eye'}).Count -eq 0 -and $html -match 'type-stat-card' -and $html -match 'type-stat-count' -and $html -match 'type-stat-icon') 'Customer rows preserve mobile card labels, compact Font Awesome detail actions and CRM statistics cards'
Assert ([regex]::Matches($html,'<section data-feedback-step=').Count -eq 4 -and $html -match 'data-feedback-wizard' -and $html -match 'offcanvas' -and $html -notmatch 'onchange="[^"]*__doPostBack') 'Customer submission uses four wizard steps without postback selector cascades'
$brand=FeedbackSelect $html 'ddlBrand';$branch=FeedbackSelect $html 'ddlBranch'
Assert ($brand -match 'value="1"' -and $brand -notmatch 'value="2"' -and $branch -match 'value="1"' -and $branch -notmatch 'value="2"|value="3"') 'Customer wizard registers only the exact active CRM brand and branch assignments'
Assert ($html -match 'ولا توجد إمكانية لإخفائها' -and $html -match 'مديري النظام الفعّالين فقط' -and $html -notmatch 'id="[^"]*(ddlTarget|ddlIdentity)"') 'Customer recipient and disclosed identity cannot be changed in the browser'

$values=@{'ctl00$ContentPlaceHolder1$ddlBrand'='1';'ctl00$ContentPlaceHolder1$ddlBranch'='1';'ctl00$ContentPlaceHolder1$ddlType'='1';'ctl00$ContentPlaceHolder1$ddlTopic'='1';'ctl00$ContentPlaceHolder1$txtTitle'='HTTP_WORKSPACE_CUSTOMER';'ctl00$ContentPlaceHolder1$txtDetails'='Customer complaint details from real ASP.NET form';'ctl00$ContentPlaceHolder1$txtMobile'='0790000000';'ctl00$ContentPlaceHolder1$btnSubmit'='إرسال الطلب'}
$body=FeedbackForm $html $values
$submissionBytes=[Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n1 0 obj<</Type/Catalog>>endobj`n%%EOF")
$saved=$hostObject.Upload('/CustomerPortal/Feedback.aspx',$body,'submission.pdf',$submissionBytes,'ctl00$ContentPlaceHolder1$uploads','application/pdf')
Assert ($saved -match 'data-feedback-saved="1"' -and $saved -match 'HTTP_WORKSPACE_CUSTOMER' -and $saved -match 'تم إرسال الطلب رقم') 'Submitting the customer wizard persists and immediately renders the new follow-up row and success message'
$newID=[int](FeedbackRows "SELECT ID FROM Employee_Feedback_Requests WHERE Title=N'HTTP_WORKSPACE_CUSTOMER'").Rows[0].ID
Assert ($saved -match ('data-feedback-saved-id="'+$newID+'"')) 'Successful customer response identifies the saved request so local filters cannot hide it'
Sql "IF (SELECT COUNT(*) FROM Customer_Portal_Feedback WHERE RequestID=$newID AND AccountID=1)<>1 OR EXISTS(SELECT 1 FROM Employee_Feedback_Workflow w JOIN UsersMembers u ON u.ID=w.ReceiverID WHERE w.Request_ID=$newID AND u.Type<>1) THROW 51999,'Customer request ownership or admin-only route failed',1;"
$submission=(FeedbackRows "SELECT ID,FileName,Workflow_ID FROM Employee_Feedback_Attachments WHERE Request_ID=$newID AND OriginalFileName=N'submission.pdf'").Rows
Assert ($submission.Count -eq 1 -and $submission[0].Workflow_ID -is [DBNull] -and $submission[0].FileName -match '^[a-f0-9]{32}\.pdf$' -and [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $stage ('App_Data/EmployeeFeedback/'+$submission[0].FileName)))) -eq [Convert]::ToBase64String($submissionBytes)) 'A real multipart submission stores its PDF under a generated filename as an original request attachment'
$submissionID=[int]$submission[0].ID
$notice=$hostObject.Request('/CircularNotifications.aspx',$null)|ConvertFrom-Json
Assert ($hostObject.Status -eq 200 -and $notice.PSObject.Properties.Name -contains 'rows' -and @($notice.feedback|Where-Object ID -eq $newID).Count -eq 1) 'Combined customer bell retains circular rows and the newly submitted complaint notification'
$expectedType=[string](FeedbackRows 'SELECT Title_Ar FROM Employee_Feedback_Types WHERE ID=1').Rows[0].Title_Ar
Assert ([string](@($notice.feedback|Where-Object ID -eq $newID)[0].TypeName) -eq $expectedType) 'Customer bell reports the submitted complaint type from the active type catalog'
$detail=Page ("/CustomerPortal/FeedbackDetail.aspx?id=$newID")
[IO.File]::WriteAllText((Join-Path $output 'feedback-customer-detail.html'),$detail,[Text.UTF8Encoding]::new($true))
Assert ($detail -match 'HTTP_WORKSPACE_CUSTOMER' -and $detail -match 'invoice-preview-card' -and $detail -match 'customer-feedback-workflow' -and $detail -notmatch 'تأكيد التحويل|إغلاق الطلب') 'Customer complaint details show owned information and workflow tabs without employee actions'
AssertFeedbackDetailLayout $detail 'customer-feedback' $newID 'HTTP_WORKSPACE_CUSTOMER' 'Customer complaint detail'
$notice=$hostObject.Request('/CircularNotifications.aspx',$null)|ConvertFrom-Json
Assert (@($notice.feedback|Where-Object ID -eq $newID).Count -eq 0) 'Authorized detail opening acknowledges only that customer complaint notice'
# Exercise both nested workflow attachment groups, including an image transfer
# and a PDF/Word close. Actions use the existing canonical SQL workflow contract.
$transferBytes=[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jK3cAAAAASUVORK5CYII=')
$transferName=FeedbackFixtureFile 'png' $transferBytes
$transferXml='<files><file name="'+$transferName+'" original="transfer.png" type="png" size="'+$transferBytes.Length+'"/></files>'
Sql "DECLARE @Version binary(8)=(SELECT RowVersion FROM Employee_Feedback_Requests WHERE ID=$newID);EXEC Update_Employee_Feedback_Action @Actor=1,@ID=$newID,@Version=@Version,@Action=2,@TargetType=1,@Comment=N'HTTP_ACTION_FILE_TRANSFER',@Files=N'$transferXml';"
$transferred=Page ("/CustomerPortal/FeedbackDetail.aspx?id=$newID")
$transferID=[int](FeedbackRows ("SELECT ID FROM Employee_Feedback_Attachments WHERE Request_ID=$newID AND FileName='$transferName'")).Rows[0].ID
Assert ($transferred -match 'HTTP_ACTION_FILE_TRANSFER' -and $transferred -match ('FeedbackFile.aspx\?id='+$submissionID+'(?:&|"|\x27|\s)') -and $transferred -match ('FeedbackFile.aspx\?id='+$transferID+'(?:&|"|\x27|\s)')) 'Customer details retain original submission files and bind transfer files before closure'
$actionBytes=[Text.Encoding]::ASCII.GetBytes("%PDF-1.4`n% closing-action fixture`n1 0 obj<</Type/Catalog>>endobj`n%%EOF")
$actionName=FeedbackFixtureFile 'pdf' $actionBytes
$wordBytes=[byte[]](0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1)+[Text.Encoding]::ASCII.GetBytes('Synthetic Word download fixture')
$wordName=FeedbackFixtureFile 'doc' $wordBytes
$actionXml='<files><file name="'+$actionName+'" original="resolution.pdf" type="pdf" size="'+$actionBytes.Length+'"/><file name="'+$wordName+'" original="resolution.doc" type="doc" size="'+$wordBytes.Length+'"/></files>'
Sql "DECLARE @Version binary(8)=(SELECT RowVersion FROM Employee_Feedback_Requests WHERE ID=$newID);EXEC Update_Employee_Feedback_Action @Actor=3,@ID=$newID,@Version=@Version,@Action=3,@Comment=N'HTTP_ACTION_FILE_CLOSE',@Files=N'$actionXml';"
$closed=Page ("/CustomerPortal/FeedbackDetail.aspx?id=$newID")
[IO.File]::WriteAllText((Join-Path $output 'feedback-customer-closed-detail.html'),$closed,[Text.UTF8Encoding]::new($true))
$actionID=[int](FeedbackRows ("SELECT ID FROM Employee_Feedback_Attachments WHERE Request_ID=$newID AND FileName='$actionName'")).Rows[0].ID
$wordID=[int](FeedbackRows ("SELECT ID FROM Employee_Feedback_Attachments WHERE Request_ID=$newID AND FileName='$wordName'")).Rows[0].ID
Assert ($hostObject.Status -eq 200 -and $closed -match 'HTTP_ACTION_FILE_CLOSE' -and $closed -match 'HTTP_ACTION_FILE_TRANSFER' -and $closed -match ('FeedbackFile.aspx\?id='+$actionID+'(?:&|"|\x27|\s)') -and $closed -match ('FeedbackFile.aspx\?id='+$wordID+'(?:&|"|\x27|\s)')) 'Closed customer details continue to bind the transfer and closing attachments'
AssertFeedbackDetailLayout $closed 'customer-feedback' $newID 'HTTP_WORKSPACE_CUSTOMER' 'Closed customer complaint detail'
Sql "IF (SELECT COUNT(*) FROM Employee_Feedback_Attachments WHERE Request_ID=$newID AND Workflow_ID IS NULL)<>1 OR (SELECT COUNT(*) FROM Employee_Feedback_Attachments a JOIN Employee_Feedback_Workflow w ON w.ID=a.Workflow_ID WHERE a.Request_ID=$newID AND w.Request_ID=$newID AND w.ActionType=2 AND w.Comment=N'HTTP_ACTION_FILE_TRANSFER')<>1 OR (SELECT COUNT(*) FROM Employee_Feedback_Attachments a JOIN Employee_Feedback_Workflow w ON w.ID=a.Workflow_ID WHERE a.Request_ID=$newID AND w.Request_ID=$newID AND w.ActionType=3 AND w.Comment=N'HTTP_ACTION_FILE_CLOSE')<>2 OR (SELECT COUNT(DISTINCT w.GroupID) FROM Employee_Feedback_Attachments a JOIN Employee_Feedback_Workflow w ON w.ID=a.Workflow_ID WHERE a.Request_ID=$newID)<>2 THROW 51999,'Submission, transfer and close attachment group linkage failed.',1;"
Assert $true 'Submission, transfer and closing files belong to the exact request and distinct workflow groups'
$workflowHtml=[regex]::Match($closed,'<ol class="timeline\b.*?</ol>','Singleline').Value
$events=@([regex]::Matches($workflowHtml,'<li class="timeline-item\b.*?</li>','Singleline'))
$transferEvent=@($events|Where-Object {$_.Value -match 'HTTP_ACTION_FILE_TRANSFER'})
$closeEvent=@($events|Where-Object {$_.Value -match 'HTTP_ACTION_FILE_CLOSE'})
Assert ($transferEvent.Count -eq 1 -and $closeEvent.Count -eq 1 -and $transferEvent[0].Value -match ('FeedbackFile.aspx\?id='+$transferID+'(?:&|"|\x27|\s)') -and $transferEvent[0].Value -notmatch ('FeedbackFile.aspx\?id='+$actionID+'(?:&|"|\x27|\s)') -and $closeEvent[0].Value -match ('FeedbackFile.aspx\?id='+$actionID+'(?:&|"|\x27|\s)') -and $closeEvent[0].Value -match ('FeedbackFile.aspx\?id='+$wordID+'(?:&|"|\x27|\s)') -and $closeEvent[0].Value -notmatch ('FeedbackFile.aspx\?id='+$transferID+'(?:&|"|\x27|\s)')) 'Nested workflow repeaters show each action attachment only in its own transfer or closing event'
Assert ($closed -match 'id="feedback-preview"' -and $closed -match 'data-feedback-preview="true"' -and $closed -match ('FeedbackFile.aspx\?id='+$submissionID+'&amp;preview=1') -and $closed -match ('FeedbackFile.aspx\?id='+$transferID+'&amp;preview=1') -and $closed -match ('FeedbackFile.aspx\?id='+$actionID+'&amp;preview=1') -and $closed -notmatch ('FeedbackFile.aspx\?id='+$wordID+'&amp;preview=1')) 'PDF and image attachments expose the shared preview modal while Word exposes download only'
AssertFeedbackAttachment $submissionID $submissionBytes 'application/pdf' $true 'submission PDF'
AssertFeedbackAttachment $transferID $transferBytes 'image/png' $true 'transfer image'
AssertFeedbackAttachment $actionID $actionBytes 'application/pdf' $true 'closing PDF'
AssertFeedbackAttachment $wordID $wordBytes 'application/octet-stream' $false 'closing Word document'
$foreignRequest=[int](FeedbackRows "SELECT ID FROM Employee_Feedback_Requests WHERE Title=N'WS_EMPLOYEE_ANONYMOUS'").Rows[0].ID
$foreignName=FeedbackFixtureFile 'pdf' $submissionBytes
Sql "INSERT Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize) VALUES($foreignRequest,'$foreignName','foreign.pdf','pdf',$($submissionBytes.Length));"
$foreignFile=[int](FeedbackRows "SELECT MAX(ID) ID FROM Employee_Feedback_Attachments WHERE Request_ID=$foreignRequest").Rows[0].ID
foreach($preview in @('','&preview=1')){[void]($hostObject.Request(("/CustomerPortal/FeedbackFile.aspx?id=$foreignFile"+$preview),$null));Assert ($hostObject.Status -eq 404) 'Customer cannot preview or download an existing employee request attachment'}
# A second customer owns a real file, so denial cannot be explained by a missing file.
Sql "EXEC Insert_Customer_Feedback_Request @Type=1,@Topic=1,@Brand=1,@Branch=1,@Name=N'Other customer fixture',@Mobile=N'0790000001',@Title=N'HTTP_WORKSPACE_OTHER_CUSTOMER',@Details=N'Foreign ownership attachment fixture',@Disclose=1,@Files=N'<files/>';INSERT Customer_Portal_Feedback(RequestID,AccountID,OperationID) SELECT ID,2,NEWID() FROM Employee_Feedback_Requests WHERE Title=N'HTTP_WORKSPACE_OTHER_CUSTOMER';"
$otherRequest=[int](FeedbackRows "SELECT ID FROM Employee_Feedback_Requests WHERE Title=N'HTTP_WORKSPACE_OTHER_CUSTOMER'").Rows[0].ID
$otherName=FeedbackFixtureFile 'png' $transferBytes
Sql "INSERT Employee_Feedback_Attachments(Request_ID,FileName,OriginalFileName,File_Type,FileSize) VALUES($otherRequest,'$otherName','other-customer.png','png',$($transferBytes.Length));"
$otherFile=[int](FeedbackRows "SELECT MAX(ID) ID FROM Employee_Feedback_Attachments WHERE Request_ID=$otherRequest").Rows[0].ID
foreach($preview in @('','&preview=1')){[void]($hostObject.Request(("/CustomerPortal/FeedbackFile.aspx?id=$otherFile"+$preview),$null));Assert ($hostObject.Status -eq 404) 'Customer cannot preview or download another customer attachment'}
[void]($hostObject.Request(("/CustomerPortal/FeedbackDetail.aspx?id=$otherRequest"),$null))
Assert ($hostObject.Status -eq 404) 'Customer detail layout does not expose another customer request or applicant information'
$missing=$hostObject.Request('/CustomerPortal/FeedbackDetail.aspx?id=2147483647',$null)
Assert ($hostObject.Status -eq 404) 'Unknown or unowned customer complaint details remain unavailable'
$stale=Page '/CustomerPortal/Feedback.aspx'
$bad=@{'ctl00$ContentPlaceHolder1$ddlBrand'='1';'ctl00$ContentPlaceHolder1$ddlBranch'='1';'ctl00$ContentPlaceHolder1$ddlType'='1';'ctl00$ContentPlaceHolder1$ddlTopic'='1';'ctl00$ContentPlaceHolder1$txtTitle'='';'ctl00$ContentPlaceHolder1$txtDetails'='Required title missing';'ctl00$ContentPlaceHolder1$txtMobile'='0790000000';'ctl00$ContentPlaceHolder1$btnSubmit'='إرسال الطلب'}
$invalid=Page '/CustomerPortal/Feedback.aspx' (FeedbackForm $stale $bad)
Assert ($invalid -match 'أكمل العنوان' -and $invalid -match 'data-feedback-saved="0"') 'Server validation rejects incomplete customer wizard submissions without a false success'

$admin=Page '/Modules/Employee_Feedback/Dashboard.aspx?newsTestActor=1'
Assert ($admin -match 'لوحة إدارة الشكاوى والاقتراحات' -and $admin -match 'HTTP_WORKSPACE_CUSTOMER' -and $admin -match 'أنواع الطلبات' -and $admin -match 'مواضيع الطلبات' -and $admin -match 'الصلاحيات والمستلمون') 'Administrator dashboard combines global requests, actionable counts, settings, reports and logs'
$adminNotice=$hostObject.Request('/CircularNotifications.aspx',$null)|ConvertFrom-Json
$adminFeedback=@($adminNotice.feedback|Where-Object ID -eq $otherRequest)
Assert ($hostObject.Status -eq 200 -and $adminFeedback.Count -eq 1 -and [string]$adminFeedback[0].TypeName -eq $expectedType) 'Administrator bell reports the actual complaint type instead of a fixed suggestion label'
# The employee detail base requires a per-page draft token even for read-only
# GETs. Supply one explicitly rather than changing the general Page/302 contract.
$viewDraft='&draft='+[guid]::NewGuid().ToString('N')
$adminDetail=Page ("/Modules/Employee_Feedback/ViewEmployeeFeedback.aspx?ID=$newID&newsTestActor=1"+$viewDraft)
[IO.File]::WriteAllText((Join-Path $output 'feedback-admin-detail.html'),$adminDetail,[Text.UTF8Encoding]::new($true))
Assert ($hostObject.Status -eq 200) 'Administrator detail GET with a valid draft token renders directly'
AssertFeedbackDetailLayout $adminDetail 'feedback' $newID 'HTTP_WORKSPACE_CUSTOMER' 'Administrator complaint detail'
foreach($source in @('&report=1','&source=my')){
 $returnDetail=Page ("/Modules/Employee_Feedback/ViewEmployeeFeedback.aspx?ID=$newID&newsTestActor=1"+$source+$viewDraft)
 Assert ($hostObject.Status -eq 200) 'Scoped administrator detail GET with a valid draft token renders directly'
 AssertFeedbackDetailLayout $returnDetail 'feedback' $newID 'HTTP_WORKSPACE_CUSTOMER' 'Administrator complaint detail opened from a scoped entry'
}
$anonymous=Page ("/Modules/Employee_Feedback/ViewEmployeeFeedback.aspx?ID=$foreignRequest&report=1&newsTestActor=1"+$viewDraft)
$privateApplicant=[string](FeedbackRows "SELECT ApplicantName FROM Employee_Feedback_Requests WHERE ID=$foreignRequest").Rows[0].ApplicantName
Assert ($hostObject.Status -eq 200 -and $privateApplicant -ne '' -and $anonymous -match 'هوية غير معلنة' -and $anonymous -notmatch [regex]::Escape([Web.HttpUtility]::HtmlEncode($privateApplicant))) 'Single-page applicant details preserve anonymous employee masking in administrator information, contact and workflow sections'
$nav=[regex]::Match($admin,'<li class="menu-item"><a href=[''"]/Modules/Employee_Feedback/Dashboard.aspx[''"] class="menu-link">.*?</li>','Singleline').Value
Assert ($nav -ne '' -and $nav -notmatch 'menu-toggle|menu-sub') 'Administrator complaints navigation is a direct dashboard link without submenu children'
$system=[regex]::Match($admin,'<!-- Administrator -->.*?<!--','Singleline').Value
Assert ($system -notmatch 'Employee_Feedback_(Permissions|Topics|Types)') 'Complaint settings are removed from the system administration menu'
$global=Page '/Modules/Employee_Feedback/ManageEmployeeFeedback.aspx?newsTestActor=1'
Assert ($global -match 'HTTP_WORKSPACE_CUSTOMER' -and $global -match 'feedback-needs-action' -and $global -match 'بانتظار إجرائك' -and $global -notmatch 'href="EmployeeFeedbackNotifications.aspx"') 'Administrator follow-up includes customer requests and distinctly highlights actual pending actions'
$employee=Page '/Modules/Employee_Feedback/ManageEmployeeFeedback.aspx?newsTestActor=2'
Assert ($employee -notmatch 'HTTP_WORKSPACE_CUSTOMER' -and $employee -match '/Modules/Employee_Feedback/ManageEmployeeFeedback.aspx') 'Ordinary employee follow-up excludes customer complaints and uses the direct follow-up menu entry'
$wizard=Page ('/Modules/Employee_Feedback/AddEmployeeFeedback.aspx?newsTestActor=2&draft='+[guid]::NewGuid().ToString('N'))
Assert ([regex]::Matches($wizard,'data-feedback-step=').Count -eq 4 -and $wizard -match 'الفرع الأول' -and $wizard -notmatch 'onchange="[^"]*__doPostBack|id="[^"]*(ddlBrand|ddlBranch)"') 'Employee wizard has four steps with server-derived fixed branch data and local selector changes'
[void]($hostObject.Request('/Modules/Employee_Feedback/Dashboard.aspx?newsTestActor=2',$null));Assert ($hostObject.Status -eq 403) 'Employee cannot open administrator dashboard'
[void]($hostObject.Request('/Modules/Employee_Feedback/EmployeeFeedbackNotifications.aspx?newsTestActor=1',$null));Assert ($hostObject.Status -eq 302 -and $hostObject.Location -like '*EmployeeFeedbackLogs.aspx') 'Removed standalone notification page redirects administrators to activity logs'
[IO.File]::WriteAllText((Join-Path $output 'feedback-admin.html'),$admin,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'feedback-customer.html'),$saved,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'feedback-employee-wizard.html'),$wizard,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $output 'feedback-stage.txt'),$stage)
[void](Login)
'PASS feedback workspace HTTP pages, ownership, admin dashboard, wizard structure, real submit/list refresh, combined notifications and read acknowledgement.'
