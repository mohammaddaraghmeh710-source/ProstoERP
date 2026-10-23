Imports Prosto_ERP_ClassLibrary

Public Class ViewEmployeeFeedback
    Inherits EmployeeFeedbackPage
    Private fileRows As New List(Of Select_Employee_Feedback_AttachmentsResult)
    Private bound As Boolean

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        If ReportMode Then RequireAdmin()
        If RequestID = 0 Then Response.Redirect("ManageEmployeeFeedback.aspx")
        EnsureDraft()
        lnkBack.NavigateUrl="ManageEmployeeFeedback.aspx"
        If Not IsPostBack Then
            Try
                Using db As New Prosto_ERP_DataClassesDataContext()
                    db.Update_Employee_Feedback_Read(ActorID, RequestID, ReportMode)
                End Using
                FillDetails(True)
                If Request.QueryString("tab")="contact" Then ScriptManager.RegisterStartupScript(Me,Me.GetType(),"ContactTab","window.addEventListener('load',function(){document.getElementById('feedback-applicant').scrollIntoView({block:'start'});});",True)
            Catch ex As Exception : ShowError(ex) : End Try
        End If
    End Sub

    Private Sub FillDetails(resetVersion As Boolean)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Dim r=db.Select_Employee_Feedback_Request(ActorID,RequestID,ReportMode).Single()
            Dim applicant=EmployeeFeedbackCatalog.Summary(ActorID,RequestID,ReportMode)
            Dim contact=EmployeeFeedbackCatalog.Contact(ActorID,RequestID,ReportMode)
            litContact.Text=FeedbackPresentation.Contact(contact,True)
            lblSource.Text=If(applicant.SourceType=2,"عميل",FeedbackPresentation.SourceName(applicant.SourceType))
            fileRows=db.Select_Employee_Feedback_Attachments(ActorID,RequestID,ReportMode).ToList()
            pnlDetails.Visible=True : litID.Text=r.ID.ToString() : litTitle.Text=r.Title
            lblType.Text=Server.HtmlEncode(EmployeeFeedbackData.TypeText(r.Type)) : lblStatus.Text=EmployeeFeedbackData.StatusText(r.Status) : lblStatus.CssClass=EmployeeFeedbackData.StatusCss(r.Status)
            litDetails.Text=CorrespondencePresentation.MessageHtml(r.Details)
            litMeta.Text=FeedbackPresentation.RequestField("الموضوع",r.TopicName) & FeedbackPresentation.RequestField("تاريخ التقديم",CorrespondencePresentation.DisplayDate(r.AddedDate))
            Dim organization=""
            If contact.CanViewContact Then
                For Each entry In New Dictionary(Of String,String) From {{"القسم",r.DepartmentName},{"المسمى الوظيفي",r.JobTitleName},{"الوردية",r.ShiftName}}
                    If Not String.IsNullOrEmpty(entry.Value) Then organization &= FeedbackPresentation.RequestField(entry.Key,entry.Value)
                Next
            End If
            If organization<>"" Then litContact.Text &= "<dl class=""row g-2 mt-0 mb-0 feedback-request-meta"">" & organization & "</dl>"
            If r.CloseDate.HasValue Then litMeta.Text &= FeedbackPresentation.RequestField("تاريخ الإغلاق",CorrespondencePresentation.DisplayDate(r.CloseDate))
            pnlActions.Visible=r.CanAct : pnlReadOnly.Visible=Not r.CanAct
            btnTransfer.Visible=r.CanAct AndAlso EmployeeFeedbackConfig.Mine(ActorID).CanTransfer AndAlso (applicant.SourceType<>2 OrElse EmployeeFeedbackConfig.Targets(ActorID).Any(Function(target) target.ID=1))
            btnClose.Visible=r.CanAct AndAlso EmployeeFeedbackConfig.Mine(ActorID).CanClose
            btnTransfer.Text="تحويل للمتابعة"
            If resetVersion Then ViewState("Version")=r.RowVersion.ToArray()
            rptFiles.DataSource=fileRows : rptFiles.DataBind()
            lblNoFiles.Visible=fileRows.Count=0
            rptWorkflow.DataSource=db.Select_Employee_Feedback_Workflow(ActorID,RequestID,ReportMode).ToList() : rptWorkflow.DataBind()
            If Not r.CanAct Then ActionModal.Hide()
            liLogs.Visible = ActorType = 1
            pnlLogs.Visible = ActorType = 1
            If ActorType = 1 Then
                rptLogs.DataSource = EmployeeFeedbackConfig.Logs(ActorID, RequestID)
                rptLogs.DataBind()
            End If
            bound = True
        End Using
    End Sub

    Protected Function FilesFor(group As Object) As IEnumerable(Of Select_Employee_Feedback_AttachmentsResult)
        Dim id = DirectCast(group, Guid)
        Return fileRows.Where(Function(f) f.GroupID.HasValue AndAlso f.GroupID.Value = id)
    End Function

    Protected Function CanPreview(fileType As Object) As Boolean
        Return _
            {"pdf", "jpg", "jpeg", "png", "gif"}.Contains(Convert.ToString(fileType).TrimStart("."c).ToLowerInvariant())
    End Function

    Protected Function FileLink(id As Object) As String
        Return "DownloadEmployeeFeedback.aspx?ID=" & Convert.ToInt32(id).ToString() & If(ReportMode, "&report=1", "")
    End Function

    Private Sub StartAction(action As Integer)
        Try
            ValidateUploadAccess()
            Dim permission=EmployeeFeedbackConfig.Mine(ActorID)
            If (action=2 AndAlso Not permission.CanTransfer) OrElse (action=3 AndAlso Not permission.CanClose) Then Throw New ArgumentException("لا تملك صلاحية هذا الإجراء.")
            pnlTransferTarget.Visible=action=2
            If action=2 Then
                EmployeeFeedbackConfig.FillTargets(ddlTransferTarget,ActorID)
                Dim customerRequest=EmployeeFeedbackCatalog.Summary(ActorID,RequestID,False).SourceType=2
                For index=ddlTransferTarget.Items.Count-1 To 1 Step -1
                    Dim item=ddlTransferTarget.Items(index)
                    If customerRequest AndAlso item.Value<>"1" Then ddlTransferTarget.Items.RemoveAt(index)
                Next

            End If
            lblTransferRouting.Text=""
            ViewState("Action")=action : litActionTitle.Text=If(action=2,"تحويل الطلب","إغلاق الطلب") : litActionError.Text="" : txtComment.Text=""
            FillDetails(False) : ActionModal.Show()
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Private Sub RefreshTransferRouting()
        If ViewState("Action") Is Nothing OrElse CInt(ViewState("Action"))<>2 OrElse Not pnlActions.Visible Then Return
        Dim customerRequest=EmployeeFeedbackCatalog.Summary(ActorID,RequestID,False).SourceType=2
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each item As ListItem In ddlTransferTarget.Items
                If item.Value="0" Then Continue For
                Try
                    If customerRequest AndAlso item.Value<>"1" Then Throw New ArgumentException()
                    Dim recipients=db.ExecuteQuery(Of Select_Employee_Feedback_RecipientsResult)("EXEC dbo.Select_Employee_Feedback_TransferTargets @Actor={0},@ID={1},@Target={2}",ActorID,RequestID,Integer.Parse(item.Value)).ToList()
                    item.Attributes("data-feedback-routing")=If(recipients.Count=0,"لا يوجد مستلم متاح لهذا النوع.",If(recipients.Any(Function(r) r.IsFallback),"سيُوجّه الطلب إلى مدير النظام لعدم وجود المدير المطلوب. ","") & "المستلمون: " & String.Join("، ",recipients.Select(Function(r) r.FullName_Ar)))
                    item.Attributes.Remove("data-feedback-unavailable")
                Catch ex As Exception
                    item.Attributes("data-feedback-routing")="الجهة المحددة غير متاحة حاليًا. اختر جهة أخرى."
                    item.Attributes("data-feedback-unavailable")="1"
                End Try
            Next
        End Using
    End Sub

    Protected Sub Transfer_Click(sender As Object, e As EventArgs)
        StartAction(EmployeeFeedbackData.TransferAction)
    End Sub

    Protected Sub Close_Click(sender As Object, e As EventArgs)
        StartAction(EmployeeFeedbackData.CloseAction)
    End Sub

    Protected Sub Cancel_Click(sender As Object, e As EventArgs)
        Session.Remove(UploadKey)
        ViewState.Remove("Action")
        ActionModal.Hide()
    End Sub

    Protected Sub Confirm_Click(sender As Object, e As EventArgs)
        Dim saved As New List(Of String)
        Try
            ValidateUploadAccess()
            Dim action = Convert.ToInt32(ViewState("Action"))
            If _
                Not {2, 3}.Contains(action) OrElse String.IsNullOrWhiteSpace(txtComment.Text) OrElse
                txtComment.Text.Length > 10000 Then Throw New ArgumentException("أدخل الشروحات؛ الحد الأقصى 10000 حرف.")
            Dim version = TryCast(ViewState("Version"), Byte())
            If version Is Nothing Then Throw New ArgumentException("أعد فتح الطلب.")
            Dim attachments = EmployeeFeedbackData.SaveQueuedAttachments(QueuedFiles(), saved)
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.ExecuteCommand(
                    "EXEC dbo.Update_Employee_Feedback_Action @Actor={0},@ID={1},@Version={2},@Action={3},@Comment={4},@Files={5},@TargetType={6}",
                    ActorID, RequestID, version, action, txtComment.Text.Trim(), attachments.ToString(),
                    Number(ddlTransferTarget))
            End Using
        Catch ex As Exception
            CorrespondenceAttachments.Cleanup(saved)
            litActionError.Text = "<div class=""alert alert-danger"">" &
                                  Server.HtmlEncode(EmployeeFeedbackData.ErrorText(ex)) & "</div>"
            Try : FillDetails(False)
            Catch ignored As Exception : ShowError(ignored)
            End Try
            If pnlActions.Visible Then ActionModal.Show() Else ShowError(ex)
            Return
        End Try
        Session.Remove(UploadKey)
        ViewState.Remove("Action")
        ActionModal.Hide()
        FillDetails(True)
        litMessage.Text = "<div class=""alert alert-success"">تم تنفيذ الإجراء بنجاح.</div>"
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        If Not bound AndAlso Not ScriptManager.GetCurrent(Me).IsInAsyncPostBack Then
            Try : FillDetails(False)
            Catch ex As Exception : ShowError(ex)
            End Try
        End If
        If pnlActions.Visible AndAlso ViewState("Action") IsNot Nothing Then ActionModal.Show()
        RefreshTransferRouting()
        ShowQueued() : MyBase.OnPreRender(e)
    End Sub
End Class


