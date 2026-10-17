Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class ViewWorkGuide
    Inherits PageBase

    Protected Overrides Sub OnInit(e As EventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("~/login.aspx")
            Return
        End If
        ViewStateUserKey = Session.SessionID
        MyBase.OnInit(e)
    End Sub

    Private CurrentUserID As Integer
    Private CurrentBrandID As Integer

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        CurrentUserID = SessionManager.GetInstance.Users.UserID
        CurrentBrandID = GetCurrentUserBrandID()
        pnlRequestArea.Visible = SessionManager.GetInstance.Users.UserType = 7
        btnRequestAccess.Visible = pnlRequestArea.Visible AndAlso CurrentBrandID > 0

        If Not Page.IsPostBack Then

            FillCategories()
            FillRequestCategories()
            BindRequests()
            If Request.QueryString("requested") = "1" Then _
                AccessMessage(litAccessMessage, "تم إرسال طلبك للمراجعة. تابع حالته هنا.", True)
            FillDocuments()
        End If
    End Sub

    Private Function GetCurrentUserBrandID() As Integer

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim user = db.Select_UsersMembers_ByID(CurrentUserID).
                    FirstOrDefault()

            If _
                user IsNot Nothing AndAlso user.Brand_ID IsNot Nothing AndAlso user.IsActive.GetValueOrDefault() AndAlso
                Not user.IsDeleted.GetValueOrDefault() Then
                Return CInt(user.Brand_ID)
            End If

        End Using

        Return 0
    End Function

    Private Sub FillCategories()

        ddlCategory.Items.Clear()


        If CurrentBrandID = 0 Then
            Return
        End If

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim categories = db.Select_Work_Guide_View_Authorized_Categories(
                CurrentUserID,
                CurrentBrandID
                ).ToList()

            For Each item In categories
                Dim optionItem As New ListItem(item.Tree_Title_Ar, item.ID.ToString())
                optionItem.Attributes("data-parent") = Convert.ToString(item.Parent_ID)
                optionItem.Attributes("data-name") = item.Title_Ar
                optionItem.Attributes("data-path") = item.Full_Path_Ar
                ddlCategory.Items.Add(optionItem)
            Next

        End Using
    End Sub

    Private Sub FillRequestCategories()
        lstRequestCategories.Items.Clear()
        If Not pnlRequestArea.Visible OrElse CurrentBrandID = 0 Then Return
        Try
            For Each row As DataRow In WorkGuideAccess.Categories(CurrentUserID).Rows
                Dim item As New ListItem(Convert.ToString(row("Full_Path_Ar")), Convert.ToString(row("ID")))
                item.Enabled = Convert.ToBoolean(row("Can_Request"))
                item.Attributes("data-parent") = Convert.ToString(row("Parent_ID"))
                item.Attributes("data-name") = Convert.ToString(row("Title_Ar"))
                item.Attributes("data-path") = Convert.ToString(row("Full_Path_Ar"))
                item.Attributes("data-state") =
                    If _
                        (Convert.ToBoolean(row("Can_View_Document")), "متاح لك",
                         If(row.IsNull("Pending_Request_ID"), "يمكن طلبه", "طلب معلّق"))
                lstRequestCategories.Items.Add(item)
            Next
        Catch ex As SqlException
            AccessMessage(litAccessMessage, WorkGuideAccess.ErrorText(ex))
        End Try
    End Sub

    Private Sub FillDocuments()
        Dim selected =
                ddlCategory.Items.Cast (Of ListItem)().Where(Function(i) i.Selected).Select(
                    Function(i) Integer.Parse(i.Value)).Distinct().ToList()
        Dim _
            categories As _
                New XElement("items", selected.Select(Function(id) New XElement("item", New XAttribute("id", id))))
        Dim documents As New DataTable()
        If CurrentBrandID > 0 Then
            documents = WorkGuideAccess.Query("dbo.Select_Work_Guide_View_Documents_Multi",
                                              WorkGuideAccess.Parameter("@User_ID", SqlDbType.Int, CurrentUserID),
                                              WorkGuideAccess.Parameter("@Brand_ID", SqlDbType.Int, CurrentBrandID),
                                              WorkGuideAccess.Parameter("@Category_IDs", SqlDbType.Xml,
                                                                        categories.ToString()),
                                              WorkGuideAccess.Parameter("@Search_Text", SqlDbType.NVarChar,
                                                                        txtSearch.Text.Trim(), 500))
        End If
        lstDocuments.DataSource = documents
        lstDocuments.DataBind()
        lblDocumentsCount.Text = documents.Rows.Count.ToString() & " ملفات"
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        FillDocuments()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs)
        txtSearch.Text = ""
        ddlCategory.ClearSelection()
        FillDocuments()
    End Sub

    Public Function FormatFileSize(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return "-"
        End If

        Dim size As Decimal = Convert.ToDecimal(value)

        If size < 1024 Then
            Return size.ToString("N0") & " B"
        ElseIf size < 1024*1024 Then
            Return (size/1024).ToString("N2") & " KB"
        Else
            Return (size/1024/1024).ToString("N2") & " MB"
        End If
    End Function

    Public Function FormatDate(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return "-"
        End If

        Return Convert.ToDateTime(value).ToString("dd/MM/yyyy")
    End Function

    Private Sub AccessMessage(target As Literal, text As String, Optional success As Boolean = False)
        target.Text = "<div role='alert' class='alert alert-" & If(success, "success", "danger") & "'>" &
                      Server.HtmlEncode(text) & "</div>"
    End Sub

    Private Sub BindRequests()
        If Not pnlRequestArea.Visible Then Return
        Try
            Dim data = WorkGuideAccess.Query("dbo.Select_Work_Guide_My_Access_Requests",
                                             WorkGuideAccess.Parameter("@Actor_ID", SqlDbType.Int, CurrentUserID),
                                             WorkGuideAccess.Parameter("@Status", SqlDbType.Char,
                                                                       ddlRequestStatus.SelectedValue, 1))
            lstRequests.DataSource = data
            lstRequests.DataBind()
        Catch ex As SqlException
            AccessMessage(litAccessMessage, WorkGuideAccess.ErrorText(ex))
        End Try
    End Sub

    Protected Sub btnSubmitAccessRequest_Click(sender As Object, e As EventArgs)
        litRequestMessage.Text = ""
        Dim selected =
                lstRequestCategories.Items.Cast (Of ListItem)().Where(Function(item) item.Selected AndAlso item.Enabled) _
                .Select(Function(item) Integer.Parse(item.Value)).ToList()
        Dim reason = txtRequestReason.Text.Trim()
        If selected.Count = 0 OrElse selected.Count > 200 OrElse reason.Length = 0 OrElse reason.Length > 1000 Then
            AccessMessage(litRequestMessage, "حدد من تصنيف واحد إلى 200 تصنيف واكتب سبب الطلب بحد أقصى 1000 حرف.")
            ReopenRequestModal()
            Return
        End If
        Try
            WorkGuideAccess.Submit(CurrentUserID, selected, reason)
        Catch ex As SqlException
            AccessMessage(litRequestMessage, WorkGuideAccess.ErrorText(ex))
            FillRequestCategories()
            ReopenRequestModal()
            Return
        End Try
        Response.Redirect("ViewWorkGuide.aspx?requested=1#my-access-requests")
    End Sub

    Private Sub ReopenRequestModal()
        ClientScript.RegisterStartupScript(Me.GetType(), "request-modal",
                                           "window.addEventListener('load', openRequestAccessModal);", True)
    End Sub

    Protected Sub btnRefreshRequests_Click(sender As Object, e As EventArgs)

        FillCategories()
        FillRequestCategories()

        FillDocuments()
        BindRequests()
    End Sub

    Protected Sub ddlRequestStatus_SelectedIndexChanged(sender As Object, e As EventArgs)

        BindRequests()
    End Sub
End Class


