Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class AddEmployeeFeedback
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        If EmployeeFeedbackConfig.Mine(ActorID) Is Nothing OrElse Not EmployeeFeedbackConfig.Mine(ActorID).CanSubmit Then Response.Redirect("ManageEmployeeFeedback.aspx")
        EnsureDraft()
        If Not IsPostBack Then
            EmployeeFeedbackCatalog.FillTypes(ddlType,ActorID,0,"اختر نوع الطلب")
            FillTopics()
            EmployeeFeedbackConfig.FillTargets(ddlTarget,ActorID)
        End If
    End Sub
    Private Sub FillTopics()
        ddlTopic.Items.Clear() : ddlTopic.Items.Add(New ListItem("اختر الموضوع","0"))
        If Number(ddlType)=0 Then Return
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each t In db.Select_Employee_Feedback_Topics(ActorID,0,Number(ddlType),0,False)
                ddlTopic.Items.Add(New ListItem(t.Title_Ar & " — " & t.BrandName,t.ID.ToString()))
            Next
        End Using
    End Sub
    Protected Sub Type_Changed(sender As Object,e As EventArgs)
        Try : FillTopics() : Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub Target_Changed(sender As Object,e As EventArgs)
        Try
            lblRouting.Text=""
            If Number(ddlTarget)=0 Then Return
            Using db As New Prosto_ERP_DataClassesDataContext()
                Dim rows=db.Select_Employee_Feedback_Recipients(ActorID,Number(ddlTarget)).ToList()
                If rows.Count=0 Then Throw New ArgumentException("لا يوجد مدير متاح لاستلام الطلب.")
                lblRouting.Text=Server.HtmlEncode(If(rows.Any(Function(r) r.IsFallback),"لا يوجد المدير المطلوب؛ سيُوجّه الطلب إلى مدير النظام. ","") & "المستلمون: " & String.Join("، ",rows.Select(Function(r) r.FullName_Ar)))
            End Using
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub Save_Click(sender As Object,e As EventArgs)
        Dim saved As New List(Of String),id As Integer
        Try
            If Number(ddlType)=0 OrElse Number(ddlTopic)=0 OrElse Number(ddlTarget)=0 OrElse ddlIdentity.SelectedValue="" Then Throw New ArgumentException("أكمل الحقول الإلزامية.")
            If String.IsNullOrWhiteSpace(txtTitle.Text) OrElse txtTitle.Text.Length>300 OrElse String.IsNullOrWhiteSpace(txtDetails.Text) OrElse txtDetails.Text.Length>10000 Then Throw New ArgumentException("أدخل عنوانًا لا يتجاوز 300 حرف وتفاصيل لا تتجاوز 10000 حرف.")
            Dim attachments=EmployeeFeedbackData.SaveQueuedAttachments(QueuedFiles(),saved)
            Using db As New Prosto_ERP_DataClassesDataContext()
                id=db.Insert_Employee_Feedback_Request(ActorID,Number(ddlType),Number(ddlTopic),txtTitle.Text.Trim(),txtDetails.Text.Trim(),ddlIdentity.SelectedValue="1",Number(ddlTarget),attachments).Single().ID
            End Using
        Catch ex As Exception : CorrespondenceData.Cleanup(saved) : ShowError(ex) : Return : End Try
        Session.Remove(UploadKey)
        Session("FeedbackSubmitted")=id
        Response.Redirect("ManageEmployeeFeedback.aspx")
    End Sub
    Protected Overrides Sub OnPreRender(e As EventArgs)
        ShowQueued() : MyBase.OnPreRender(e)
    End Sub
End Class
