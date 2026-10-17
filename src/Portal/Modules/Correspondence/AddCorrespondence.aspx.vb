Imports System.Data
Imports System.Web
Imports System.Linq
Imports System.Xml.Linq
Imports System.Globalization
Imports Prosto_ERP_ClassLibrary

Public Class AddCorrespondence
    Inherits PageBase
    Private ReadOnly Property ActorID As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property
    Private ReadOnly Property ActorType As Integer
        Get
            Return SessionManager.GetInstance.Users.UserType
        End Get
    End Property
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        ViewStateUserKey = Session.SessionID
    End Sub
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/login.aspx")
        If Not {1, 2, 3, 4}.Contains(ActorType) Then Response.Redirect("/Modules/Correspondence/ManageCorrespondence.aspx")
        EnsureUploadDraft()
        pnlAdmin.Visible = ActorType = 1
        pnlTask.Visible = ActorType <> 4
        btnSelectAll.Visible = ActorType <> 4
        lstRecipients.SelectionMode = If(ActorType = 4, ListSelectionMode.Single, ListSelectionMode.Multiple)
        If Not IsPostBack Then
            Try
                CorrespondenceData.FillCatalog(ddlPriority, ActorID, "P")
                If ddlPriority.Items.FindByValue("1") IsNot Nothing Then ddlPriority.SelectedValue = "1"
                ddlBrand.Items.Add(New ListItem("اختر العلامة التجارية", "0"))
                ddlBranch.Items.Add(New ListItem("جميع الفروع", "0"))
                ddlShift.Items.Add(New ListItem("جميع الورديات", "0"))
                If ActorType = 1 Then
                    Using db As New Prosto_ERP_DataClassesDataContext()
                        For Each item In db.Select_Brands_All()
                            ddlBrand.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
                        Next
                        For Each item In db.Select_Shift_All()
                            ddlShift.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
                        Next
                    End Using
                End If
                If RelatedID > 0 Then
                    Dim source = CorrespondenceData.ThreadQuery("dbo.Correspondence_Detail", ActorID, RelatedID).Rows(0)
                    If CInt(source("CreatedBy")) <> ActorID OrElse Convert.ToString(source("ClosureKind")) <> "transfer" Then Throw New ArgumentException("التكليف السابق غير متاح لنقل المسؤولية.")
                    ddlKind.SelectedValue = "2" : ddlKind.Enabled = False : txtDue.Enabled = True
                    txtTitle.Text = Convert.ToString(source("Title"))
                    litRelated.Text = "<div class=""alert alert-secondary"">تكليف جديد مرتبط بالمراسلة رقم " & RelatedID.ToString() & "؛ اختر المسؤول البديل.</div>"
                End If
                FillRecipients()
            Catch ex As Exception
                ShowError(ex)
            End Try
        End If
    End Sub
    Private Function SelectedNumber(list As DropDownList) As Integer
        Dim value As Integer
        Integer.TryParse(list.SelectedValue, value)
        Return value
    End Function
    Private Sub FillRecipients()
        lstRecipients.Items.Clear()
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each person In db.Select_Correspondence_Recipients(ActorID, SelectedNumber(ddlBrand), SelectedNumber(ddlBranch), SelectedNumber(ddlShift))
                Dim role = If(person.Type = 2, "مدير فرع", If(person.Type = 3, "مدير وردية", "موظف"))
                lstRecipients.Items.Add(New ListItem(person.FullName_Ar & " — " & role, person.ID.ToString()))
            Next
        End Using
        lblRecipientsHint.Text = If(ActorType = 1 AndAlso SelectedNumber(ddlBrand) = 0, "اختر العلامة التجارية أولاً لعرض الموظفين.", If(lstRecipients.Items.Count = 0, "لا يوجد مستلمون متاحون وفق هذه الخيارات.", If(ActorType = 4, "اختر مدير الفرع أو مدير الوردية.", "عند اختيار أكثر من مستلم تُنشأ محادثة مستقلة لكل شخص.")))
    End Sub
    Protected Sub Brand_Changed(sender As Object, e As EventArgs)
        Try
            ddlBranch.Items.Clear() : ddlBranch.Items.Add(New ListItem("جميع الفروع", "0"))
            ddlShift.SelectedValue = "0"
            If SelectedNumber(ddlBrand) > 0 Then
                Using db As New Prosto_ERP_DataClassesDataContext()
                    For Each branch In db.Select_Branches_ByBrandID(SelectedNumber(ddlBrand))
                        ddlBranch.Items.Add(New ListItem(branch.Title_Ar, branch.ID.ToString()))
                    Next
                End Using
            End If
            FillRecipients()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub
    Protected Sub Recipients_Changed(sender As Object, e As EventArgs)
        Try
            FillRecipients()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub
    Protected Sub SelectAll_Click(sender As Object, e As EventArgs)
        If ActorType = 4 Then Return
        For Each item As ListItem In lstRecipients.Items
            item.Selected = True
        Next
    End Sub
    Protected Sub Save_Click(sender As Object, e As EventArgs)
        Dim saved As New List(Of String)
        Dim ids As New List(Of Integer)
        Try
            Dim recipients = lstRecipients.Items.Cast(Of ListItem)().Where(Function(i) i.Selected).Select(Function(i) Integer.Parse(i.Value)).ToList()
            If recipients.Count = 0 Then Throw New ArgumentException("يرجى تحديد المستلم.")
            If ActorType = 4 AndAlso recipients.Count <> 1 Then Throw New ArgumentException("يرجى اختيار مستلم واحد.")
            If String.IsNullOrWhiteSpace(txtTitle.Text) OrElse txtTitle.Text.Length > 200 Then Throw New ArgumentException("يرجى إدخال عنوان لا يتجاوز 200 حرف.")
            If txtBrief.Text.Length > 2000 OrElse txtBody.Text.Length > 4000 Then Throw New ArgumentException("الحد الأقصى للملخص 2000 حرف وللرسالة 4000 حرف.")
            Dim due As DateTime? = Nothing
            If ActorType <> 4 AndAlso ddlKind.SelectedValue = "2" AndAlso Not String.IsNullOrWhiteSpace(txtDue.Text) Then
                Dim dateValue As DateTime
                If Not DateTime.TryParse(txtDue.Text, CultureInfo.InvariantCulture, DateTimeStyles.None, dateValue) Then Throw New ArgumentException("يرجى تحديد موعد صحيح.")
                due = TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(dateValue, DateTimeKind.Unspecified), TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time"))
            End If
            Dim attachments = CorrespondenceData.SaveQueuedAttachments(TryCast(Session(UploadKey), List(Of FileAttribute)), saved)
            Dim result = CorrespondenceData.Query("dbo.Insert_Correspondence_Thread",
                CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID), CorrespondenceData.P("@Brand", SqlDbType.Int, SelectedNumber(ddlBrand)),
                CorrespondenceData.P("@Recipients", SqlDbType.Xml, New XElement("items", recipients.Select(Function(id) New XElement("item", New XAttribute("id", id)))).ToString()),
                CorrespondenceData.P("@Title", SqlDbType.NVarChar, txtTitle.Text.Trim(), 200), CorrespondenceData.P("@Brief", SqlDbType.NVarChar, txtBrief.Text.Trim(), 2000),
                CorrespondenceData.P("@Body", SqlDbType.NVarChar, txtBody.Text.Trim(), 4000),
                CorrespondenceData.P("@RequiresCompletion", SqlDbType.Bit, ActorType <> 4 AndAlso ddlKind.SelectedValue = "2"),
                CorrespondenceData.P("@DueDate", SqlDbType.DateTime, due), CorrespondenceData.P("@Files", SqlDbType.Xml, attachments.ToString()),
                CorrespondenceData.P("@Priority", SqlDbType.Int, SelectedNumber(ddlPriority)),
                CorrespondenceData.P("@RelatedThreadID", SqlDbType.Int, If(RelatedID = 0, CType(Nothing, Object), RelatedID)))
            ids = result.AsEnumerable().Select(Function(r) CInt(r("ID"))).ToList()

        Catch ex As Exception
            CorrespondenceData.Cleanup(saved) : ShowError(ex) : Return
        End Try
        Session.Remove(UploadKey)
        Response.Redirect("ManageCorrespondence.aspx" & If(ids.Count = 1, "?ID=" & ids(0).ToString(), "?created=" & ids.Count.ToString()), False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Private ReadOnly Property RelatedID As Integer
        Get
            Dim value As Integer
            Integer.TryParse(Request.QueryString("related"), value)
            Return Math.Max(0, value)
        End Get
    End Property
    Protected Sub Kind_Changed(sender As Object, e As EventArgs)
        txtDue.Enabled = ddlKind.SelectedValue = "2"
        If Not txtDue.Enabled Then txtDue.Text = ""
    End Sub
    Private ReadOnly Property UploadKey As String
        Get
            Dim token As Guid
            If Not Guid.TryParse(Request.QueryString("draft"), token) Then Throw New ArgumentException("يرجى إعادة فتح الصفحة.")
            Return "CorrespondenceFiles:" & ActorID.ToString() & ":" & token.ToString("N")
        End Get
    End Property
    Private Sub EnsureUploadDraft()
        Dim token As Guid
        If Not Guid.TryParse(Request.QueryString("draft"), token) Then Response.Redirect(Request.RawUrl & If(Request.QueryString.Count=0,"?","&") & "draft=" & Guid.NewGuid().ToString("N"))
    End Sub
    Protected Sub AttachmentUpload_UploadStart(sender As Object, e As AjaxControlToolkit.AjaxFileUploadStartEventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401,"انتهت الجلسة")
    End Sub
    Protected Sub AttachmentUpload_UploadComplete(sender As Object, e As AjaxControlToolkit.AjaxFileUploadEventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401,"انتهت الجلسة")
        Dim extension = IO.Path.GetExtension(e.FileName).ToLowerInvariant()
        If Not {".pdf",".doc",".docx",".xls",".xlsx",".jpg",".jpeg",".png",".gif"}.Contains(extension) Then Throw New ArgumentException("نوع الملف غير مسموح.")
        Dim contents=e.GetContents()
        If contents.Length=0 OrElse contents.Length>CorrespondenceData.MaxFileBytes Then Throw New ArgumentException("الحد الأقصى للمرفق 10 ميجابايت.")
        Dim items=TryCast(Session(UploadKey),List(Of FileAttribute))
        If items Is Nothing Then items=New List(Of FileAttribute)
        If items.Count>=CorrespondenceData.MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات. امسح المرفقات المحددة لإعادة الاختيار.")
        items.Add(New FileAttribute With {.NameFile=e.FileName,.Type=e.ContentType,.FileByte=contents})
        Session(UploadKey)=items
    End Sub
    Protected Sub ClearUploads_Click(sender As Object,e As EventArgs)
        Session.Remove(UploadKey)
    End Sub
    Private Sub ShowQueuedUploads()
        Dim items=TryCast(Session(UploadKey),List(Of FileAttribute))
        lblQueued.Text=If(items Is Nothing OrElse items.Count=0, "", "المرفقات المحفوظة: " & items.Count.ToString())
    End Sub
    Protected Overrides Sub OnPreRender(e As EventArgs)
        ShowQueuedUploads()
        MyBase.OnPreRender(e)
    End Sub
    Private Sub ShowError(ex As Exception)
        litMessage.Text = "<div class=""alert alert-danger"" role=""alert"">" & Server.HtmlEncode(CorrespondenceData.ErrorText(ex)) & "</div>"
    End Sub
End Class
