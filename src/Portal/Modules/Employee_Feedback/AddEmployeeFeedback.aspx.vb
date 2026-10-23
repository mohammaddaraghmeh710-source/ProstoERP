Imports Prosto_ERP_ClassLibrary

Public Class AddEmployeeFeedback
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If EmployeeFeedbackConfig.Mine(ActorID) Is Nothing OrElse Not EmployeeFeedbackConfig.Mine(ActorID).CanSubmit _
            Then Response.Redirect("ManageEmployeeFeedback.aspx")
        EnsureDraft()
        If Not IsPostBack Then
            FeedbackPresentation.FillTypes(ddlType, ActorID, 0, "اختر نوع الطلب")
            FillTopics()
            EmployeeFeedbackConfig.FillTargets(ddlTarget,ActorID)
            Dim applicant=EmployeeFeedbackCatalog.OwnApplicant(ActorID)
            litApplicant.Text="<div class='row g-3 mb-4'>" & FeedbackPresentation.Info("العلامة التجارية",applicant.BrandName,"bx-store") & FeedbackPresentation.Info("الفرع",applicant.BranchName,"bx-map") & "</div>" & FeedbackPresentation.Contact(applicant)
        End If
    End Sub

    Private Sub FillTopics()
        ddlTopic.Items.Clear() : ddlTopic.Items.Add(New ListItem("اختر الموضوع","0"))
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each t In db.Select_Employee_Feedback_Topics(ActorID,0,0,0,False)
                Dim item As New ListItem(t.Title_Ar & " — " & t.BrandName,t.ID.ToString())
                item.Attributes("data-feedback-type")=t.Type.ToString()
                ddlTopic.Items.Add(item)
            Next
        End Using
    End Sub
    Private Sub FillRoutingPreviews()
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each item As ListItem In ddlTarget.Items
                If item.Value="0" Then Continue For
                Try
                    Dim rows=db.Select_Employee_Feedback_Recipients(ActorID,Integer.Parse(item.Value)).ToList()
                    item.Attributes("data-feedback-routing")=If(rows.Count=0,"لا يوجد مدير متاح لاستلام الطلب.",If(rows.Any(Function(r) r.IsFallback),"لا يوجد المدير المطلوب؛ سيُوجّه الطلب إلى مدير النظام. ","") & "المستلمون: " & String.Join("، ",rows.Select(Function(r) r.FullName_Ar)))
                    item.Attributes.Remove("data-feedback-unavailable")
                Catch ex As Exception
                    item.Attributes("data-feedback-routing")="الجهة المحددة غير متاحة حاليًا. اختر جهة أخرى."
                    item.Attributes("data-feedback-unavailable")="1"
                End Try
            Next
        End Using
    End Sub

    Protected Sub Save_Click(sender As Object, e As EventArgs)
        Dim saved As New List(Of String), id As Integer
        Try
            If _
                Number(ddlType) = 0 OrElse Number(ddlTopic) = 0 OrElse Number(ddlTarget) = 0 OrElse
                ddlIdentity.SelectedValue = "" Then Throw New ArgumentException("أكمل الحقول الإلزامية.")
            If _
                String.IsNullOrWhiteSpace(txtTitle.Text) OrElse txtTitle.Text.Length > 300 OrElse
                String.IsNullOrWhiteSpace(txtDetails.Text) OrElse txtDetails.Text.Length > 10000 Then _
                Throw New ArgumentException("أدخل عنوانًا لا يتجاوز 300 حرف وتفاصيل لا تتجاوز 10000 حرف.")
            Dim attachments = EmployeeFeedbackData.SaveQueuedAttachments(QueuedFiles(), saved)
            Using db As New Prosto_ERP_DataClassesDataContext()
                id =
                    db.Insert_Employee_Feedback_Request(ActorID, Number(ddlType), Number(ddlTopic), txtTitle.Text.Trim(),
                                                        txtDetails.Text.Trim(), ddlIdentity.SelectedValue = "1",
                                                        Number(ddlTarget), attachments).Single().ID
            End Using
        Catch ex As Exception : CorrespondenceAttachments.Cleanup(saved)
            ShowError(ex)
            Return
        End Try
        Session.Remove(UploadKey)
        Session("FeedbackSubmitted") = id
        Response.Redirect("ManageEmployeeFeedback.aspx")
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Dim topics=db.Select_Employee_Feedback_Topics(ActorID,0,0,0,False).ToDictionary(Function(topic) topic.ID.ToString())
            For Each item As ListItem In ddlTopic.Items
                If item.Value="0" Then Continue For
                If topics.ContainsKey(item.Value) Then
                    item.Attributes("data-feedback-type")=topics(item.Value).Type.ToString()
                    item.Attributes.Remove("data-feedback-unavailable")
                Else
                    item.Attributes("data-feedback-unavailable")="1"
                End If
            Next
        End Using
        FillRoutingPreviews()
        ShowQueued()
        If IsPostBack Then
            Dim stepIndex=If(Request.Form("__EVENTTARGET")=btnClearUploads.UniqueID OrElse Request.Form(btnClearUploads.UniqueID) IsNot Nothing,2,3)
            ScriptManager.RegisterStartupScript(Me,Me.GetType(),"FeedbackWizardStep","document.addEventListener('DOMContentLoaded',function(){var w=document.querySelector('[data-feedback-wizard]');if(w&&window.FeedbackWizard)FeedbackWizard.goTo(w," & stepIndex.ToString() & ");});",True)
        End If
        MyBase.OnPreRender(e)
    End Sub
End Class


