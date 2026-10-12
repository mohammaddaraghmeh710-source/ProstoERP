Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class ViewEmployeeFeedback
    Inherits EmployeeFeedbackPage
    Private fileRows As New List(Of Select_Employee_Feedback_AttachmentsResult)
    Private bound As Boolean
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        Response.Cache.SetCacheability(HttpCacheability.NoCache) : Response.Cache.SetNoStore()
        If ReportMode Then RequireAdmin()
        If RequestID=0 Then Response.Redirect("ManageEmployeeFeedback.aspx")
        EnsureDraft()
        lnkBack.NavigateUrl=If(ReportMode,"EmployeeFeedbackReports.aspx",If(Request.QueryString("source")="my","ManageEmployeeFeedback.aspx?view=mine","ManageEmployeeFeedback.aspx"))
        If Not IsPostBack Then
            Try
                Using db As New Prosto_ERP_DataClassesDataContext()
                    db.Update_Employee_Feedback_Read(ActorID,RequestID,ReportMode)
                End Using
                FillDetails(True)
                If Request.QueryString("tab")="contact" Then ScriptManager.RegisterStartupScript(Me,Me.GetType(),"ContactTab","window.addEventListener('load',function(){bootstrap.Tab.getOrCreateInstance(document.getElementById('feedback-contact-tab')).show();});",True)
            Catch ex As Exception : ShowError(ex) : End Try
        End If
    End Sub
    Private Sub FillDetails(resetVersion As Boolean)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Dim r=db.Select_Employee_Feedback_Request(ActorID,RequestID,ReportMode).Single()
            Dim applicant=EmployeeFeedbackCatalog.Summary(ActorID,RequestID,ReportMode)
            litContact.Text=FeedbackPresentation.Contact(EmployeeFeedbackCatalog.Contact(ActorID,RequestID,ReportMode))
            lblSource.Text=EmployeeFeedbackCatalog.SourceName(applicant.SourceType)
            fileRows=db.Select_Employee_Feedback_Attachments(ActorID,RequestID,ReportMode).ToList()
            pnlDetails.Visible=True : litID.Text=r.ID.ToString() : litTitle.Text=r.Title
            lblType.Text=Server.HtmlEncode(EmployeeFeedbackData.TypeText(r.Type)) : lblStatus.Text=EmployeeFeedbackData.StatusText(r.Status) : lblStatus.CssClass=EmployeeFeedbackData.StatusCss(r.Status)
            lblEmployee.Text=Server.HtmlEncode(r.EmployeeName) : litDetails.Text=CorrespondenceData.MessageHtml(r.Details)
            litMeta.Text="<div class=""row g-3"">" & FeedbackPresentation.Info("الموضوع",r.TopicName,"bx-category") & FeedbackPresentation.Info("تاريخ التقديم",CorrespondenceData.DisplayDate(r.AddedDate),"bx-calendar") & FeedbackPresentation.Info("العلامة التجارية",r.BrandName,"bx-store") & FeedbackPresentation.Info("الفرع",r.BranchName,"bx-map")
            For Each entry In New Dictionary(Of String,String) From {{"القسم",r.DepartmentName},{"المسمى الوظيفي",r.JobTitleName},{"الوردية",r.ShiftName}}
                If Not String.IsNullOrEmpty(entry.Value) Then litMeta.Text &= FeedbackPresentation.Info(entry.Key,entry.Value,"bx-buildings")
            Next
            If r.CloseDate.HasValue Then litMeta.Text &= FeedbackPresentation.Info("تاريخ الإغلاق",CorrespondenceData.DisplayDate(r.CloseDate),"bx-calendar-check")
            litMeta.Text &= "</div>"
            pnlActions.Visible=r.CanAct : pnlReadOnly.Visible=Not r.CanAct
            btnTransfer.Visible=r.CanAct AndAlso EmployeeFeedbackConfig.Mine(ActorID).CanTransfer
            btnClose.Visible=r.CanAct AndAlso EmployeeFeedbackConfig.Mine(ActorID).CanClose
            btnTransfer.Text="تحويل للمتابعة"
            If resetVersion Then ViewState("Version")=r.RowVersion.ToArray()
            rptFiles.DataSource=fileRows : rptFiles.DataBind()
            lblNoFiles.Visible=fileRows.Count=0
            rptWorkflow.DataSource=db.Select_Employee_Feedback_Workflow(ActorID,RequestID,ReportMode).ToList() : rptWorkflow.DataBind()
            If Not r.CanAct Then ActionModal.Hide()
            liLogs.Visible=ActorType=1 : pnlLogs.Visible=ActorType=1
            If ActorType=1 Then
                rptLogs.DataSource=EmployeeFeedbackConfig.Logs(ActorID,RequestID) : rptLogs.DataBind()
            End If
            bound=True
        End Using
    End Sub
    Protected Function FilesFor(group As Object) As IEnumerable(Of Select_Employee_Feedback_AttachmentsResult)
        Dim id=DirectCast(group,Guid)
        Return fileRows.Where(Function(f) f.GroupID.HasValue AndAlso f.GroupID.Value=id)
    End Function
    Protected Function CanPreview(fileType As Object) As Boolean
        Return {"pdf","jpg","jpeg","png","gif"}.Contains(Convert.ToString(fileType).TrimStart("."c).ToLowerInvariant())
    End Function
    Protected Function FileLink(id As Object) As String
        Return "DownloadEmployeeFeedback.aspx?ID=" & Convert.ToInt32(id).ToString() & If(ReportMode,"&report=1","")
    End Function
    Private Sub StartAction(action As Integer)
        Try
            ValidateUploadAccess()
            Dim permission=EmployeeFeedbackConfig.Mine(ActorID)
            If (action=2 AndAlso Not permission.CanTransfer) OrElse (action=3 AndAlso Not permission.CanClose) Then Throw New ArgumentException("لا تملك صلاحية هذا الإجراء.")
            pnlTransferTarget.Visible=action=2
            If action=2 Then EmployeeFeedbackConfig.FillTargets(ddlTransferTarget,ActorID)
            lblTransferRouting.Text=""
            ViewState("Action")=action : litActionTitle.Text=If(action=2,"تحويل الطلب","إغلاق الطلب") : litActionError.Text="" : txtComment.Text=""
            FillDetails(False) : ActionModal.Show()
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub TransferTarget_Changed(sender As Object,e As EventArgs)
        Try
            lblTransferRouting.Text=""
            If Number(ddlTransferTarget)=0 Then Return
            Using db As New Prosto_ERP_DataClassesDataContext()
                Dim rows=db.ExecuteQuery(Of Select_Employee_Feedback_RecipientsResult)("EXEC dbo.Select_Employee_Feedback_TransferTargets @Actor={0},@ID={1},@Target={2}",ActorID,RequestID,Number(ddlTransferTarget)).ToList()
                If rows.Count=0 Then Throw New ArgumentException("لا يوجد مستلم متاح لهذا النوع.")
                lblTransferRouting.Text=Server.HtmlEncode(If(rows.Any(Function(r) r.IsFallback),"سيُوجّه الطلب إلى مدير النظام لعدم وجود المدير المطلوب. ","") & "المستلمون: " & String.Join("، ",rows.Select(Function(r) r.FullName_Ar)))
            End Using
        Catch ex As Exception
            litActionError.Text="<div class=""alert alert-danger"">" & Server.HtmlEncode(EmployeeFeedbackData.ErrorText(ex)) & "</div>"
        End Try
    End Sub
    Protected Sub Transfer_Click(sender As Object,e As EventArgs)
        StartAction(EmployeeFeedbackData.TransferAction)
    End Sub
    Protected Sub Close_Click(sender As Object,e As EventArgs)
        StartAction(EmployeeFeedbackData.CloseAction)
    End Sub
    Protected Sub Cancel_Click(sender As Object,e As EventArgs)
        Session.Remove(UploadKey) : ViewState.Remove("Action") : ActionModal.Hide()
    End Sub
    Protected Sub Confirm_Click(sender As Object,e As EventArgs)
        Dim saved As New List(Of String)
        Try
            ValidateUploadAccess()
            Dim action=Convert.ToInt32(ViewState("Action"))
            If Not {2,3}.Contains(action) OrElse String.IsNullOrWhiteSpace(txtComment.Text) OrElse txtComment.Text.Length>10000 Then Throw New ArgumentException("أدخل الشروحات؛ الحد الأقصى 10000 حرف.")
            Dim version=TryCast(ViewState("Version"),Byte())
            If version Is Nothing Then Throw New ArgumentException("أعد فتح الطلب.")
            Dim attachments=EmployeeFeedbackData.SaveQueuedAttachments(QueuedFiles(),saved)
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.ExecuteCommand("EXEC dbo.Update_Employee_Feedback_Action @Actor={0},@ID={1},@Version={2},@Action={3},@Comment={4},@Files={5},@TargetType={6}",ActorID,RequestID,version,action,txtComment.Text.Trim(),attachments.ToString(),Number(ddlTransferTarget))
            End Using
        Catch ex As Exception
            CorrespondenceData.Cleanup(saved)
            litActionError.Text="<div class=""alert alert-danger"">" & Server.HtmlEncode(EmployeeFeedbackData.ErrorText(ex)) & "</div>"
            Try : FillDetails(False) : Catch ignored As Exception : ShowError(ignored) : End Try
            If pnlActions.Visible Then ActionModal.Show() Else ShowError(ex)
            Return
        End Try
        Session.Remove(UploadKey) : ViewState.Remove("Action") : ActionModal.Hide()
        FillDetails(True)
        litMessage.Text="<div class=""alert alert-success"">تم تنفيذ الإجراء بنجاح.</div>"
    End Sub
    Protected Overrides Sub OnPreRender(e As EventArgs)
        If Not bound AndAlso Not ScriptManager.GetCurrent(Me).IsInAsyncPostBack Then
            Try : FillDetails(False) : Catch ex As Exception : ShowError(ex) : End Try
        End If
        If pnlActions.Visible AndAlso ViewState("Action") IsNot Nothing Then ActionModal.Show()
        ShowQueued() : MyBase.OnPreRender(e)
    End Sub
End Class
