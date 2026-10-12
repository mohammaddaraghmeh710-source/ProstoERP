Imports System.Linq
Imports System.Web
Imports Prosto_ERP_ClassLibrary

Public Class EmployeeFeedbackPage
    Inherits PageBase
    Protected ReadOnly Property ActorID As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property
    Protected ReadOnly Property ActorType As Integer
        Get
            Return SessionManager.GetInstance.Users.UserType
        End Get
    End Property
    Protected ReadOnly Property RequestID As Integer
        Get
            Dim value As Integer
            Integer.TryParse(Request.QueryString("ID"),value)
            Return Math.Max(0,value)
        End Get
    End Property
    Protected ReadOnly Property ReportMode As Boolean
        Get
            Return Request.QueryString("report")="1"
        End Get
    End Property
    Protected Overrides Sub OnInit(e As EventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/Login.aspx")
        ViewStateUserKey=Session.SessionID
        MyBase.OnInit(e)
    End Sub
    Protected Sub RequireAdmin()
        If ActorType<>1 Then Throw New HttpException(403,"غير مسموح")
    End Sub
    Protected Function Number(list As DropDownList) As Integer
        Dim value As Integer
        Integer.TryParse(list.SelectedValue,value)
        Return value
    End Function
    Protected Sub ShowError(ex As Exception)
        Dim target=TryCast(FindDeep(Me,"litMessage"),Literal)
        If target IsNot Nothing Then target.Text="<div class=""alert alert-danger"" role=""alert"">" & Server.HtmlEncode(EmployeeFeedbackData.ErrorText(ex)) & "</div>"
    End Sub
    Private Function FindDeep(parent As Control,id As String) As Control
        If parent.ID=id Then Return parent
        For Each child As Control In parent.Controls
            Dim found=FindDeep(child,id)
            If found IsNot Nothing Then Return found
        Next
        Return Nothing
    End Function
    Protected Sub EnsureDraft()
        Dim token As Guid
        If Not Guid.TryParse(Request.QueryString("draft"),token) Then Response.Redirect(Request.RawUrl & If(Request.QueryString.Count=0,"?","&") & "draft=" & Guid.NewGuid().ToString("N"))
    End Sub
    Protected ReadOnly Property UploadKey As String
        Get
            Dim token As Guid
            If Not Guid.TryParse(Request.QueryString("draft"),token) Then Throw New ArgumentException("أعد فتح الصفحة.")
            Return "EmployeeFeedback:" & ActorID.ToString() & ":" & Request.Path & ":" & RequestID.ToString() & ":" & token.ToString("N")
        End Get
    End Property
    Protected Function QueuedFiles() As List(Of FileAttribute)
        Return TryCast(Session(UploadKey),List(Of FileAttribute))
    End Function
    Protected Sub ValidateUploadAccess()
        If ReportMode Then Throw New HttpException(403,"التقرير للاطلاع فقط")
        If RequestID>0 Then
            Using db As New Prosto_ERP_DataClassesDataContext()
                If Not db.Select_Employee_Feedback_Request(ActorID,RequestID,False).Single().CanAct Then Throw New HttpException(403,"المعاملة للاطلاع فقط")
            End Using
        ElseIf EmployeeFeedbackConfig.Mine(ActorID) Is Nothing OrElse Not EmployeeFeedbackConfig.Mine(ActorID).CanSubmit Then
            Throw New HttpException(403,"غير مسموح بالتقديم")
        End If
    End Sub
    Protected Sub AttachmentUpload_UploadStart(sender As Object,e As AjaxControlToolkit.AjaxFileUploadStartEventArgs)
        ValidateUploadAccess()
    End Sub
    Protected Sub AttachmentUpload_UploadComplete(sender As Object,e As AjaxControlToolkit.AjaxFileUploadEventArgs)
        ValidateUploadAccess()
        Dim extension=IO.Path.GetExtension(e.FileName).ToLowerInvariant()
        If Not {".pdf",".doc",".docx",".xls",".xlsx",".jpg",".jpeg",".png",".gif"}.Contains(extension) Then Throw New ArgumentException("نوع الملف غير مسموح.")
        Dim bytes=e.GetContents()
        If bytes.Length=0 OrElse bytes.Length>EmployeeFeedbackData.MaxFileBytes Then Throw New ArgumentException("الحد الأقصى للمرفق 10 ميجابايت.")
        Dim items=QueuedFiles()
        If items Is Nothing Then items=New List(Of FileAttribute)
        If items.Count>=EmployeeFeedbackData.MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
        items.Add(New FileAttribute With {.NameFile=IO.Path.GetFileName(e.FileName),.Type=e.ContentType,.FileByte=bytes})
        Session(UploadKey)=items
    End Sub
    Protected Sub ClearUploads_Click(sender As Object,e As EventArgs)
        Session.Remove(UploadKey)
    End Sub
    Protected Sub ShowQueued()
        Dim label=TryCast(FindDeep(Me,"lblQueued"),Label)
        If label Is Nothing Then Return
        Dim items=QueuedFiles()
        label.Text=If(items Is Nothing OrElse items.Count=0,"","عدد المرفقات المحددة: " & items.Count.ToString())
    End Sub
End Class
