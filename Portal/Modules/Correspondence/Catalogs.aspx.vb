Imports System.Linq
Imports System.Data
Imports System.Web
Imports Prosto_ERP_ClassLibrary

Public Class CorrespondenceCatalogs
    Inherits PageBase
    Private ReadOnly Property Actor As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property
    Private ReadOnly Property Kind As String
        Get
            Return If(Request.QueryString("kind") = "R", "R", "P")
        End Get
    End Property
    Private Function Rows() As DataTable
        Return CorrespondenceData.Query("dbo.Correspondence_CatalogList", CorrespondenceData.P("@Actor", SqlDbType.Int, Actor), CorrespondenceData.P("@Kind", SqlDbType.Char, Kind, 1), CorrespondenceData.P("@Mode", SqlDbType.Int, 2))
    End Function
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        ViewStateUserKey = Session.SessionID
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/login.aspx") : Return
        ' Recheck the current account in SQL on every request, including postbacks.
        Try
            Rows()
        Catch ex As System.Data.SqlClient.SqlException
            If ex.Number = 51400 Then Throw New HttpException(403, "غير مسموح")
            Throw
        End Try
    End Sub
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        litTitle.Text = If(Kind = "P", "إدارة أولويات المراسلات", "إدارة أسباب الإنهاء")
        pnlPriority.Visible = Kind = "P" : pnlReason.Visible = Kind = "R"
        If Not IsPostBack Then BindRows()
    End Sub
    Private Sub BindRows()
        grid.DataSource = Rows() : grid.DataBind()
    End Sub
    Protected Function Token(item As Object) As String
        Dim row = CType(item, DataRowView)
        Return CStr(row("ID")) & ":" & Convert.ToBase64String(CType(row("Version"), Byte()))
    End Function
    Private Sub ResetEditor()
        ViewState.Remove("EditID") : ViewState.Remove("EditVersion")
        txtTitle.Text = "" : txtOrder.Text = "10" : chkActive.Checked = True : chkUrgent.Checked = False : ddlBehavior.SelectedValue = "normal"
        litEditor.Text = "إضافة خيار"
    End Sub
    Private Sub Notice(message As String, Optional failed As Boolean = False)
        litNotice.Text = "<div role=""status"" class=""alert " & If(failed, "alert-danger", "alert-success") & """>" & HttpUtility.HtmlEncode(message) & "</div>"
    End Sub
    Protected Sub Save_Click(sender As Object, e As EventArgs)
        Try
            Dim rank As Integer
            If String.IsNullOrWhiteSpace(txtTitle.Text) OrElse txtTitle.Text.Trim().Length > 200 Then Throw New ArgumentException("أدخل اسمًا لا يتجاوز 200 حرف.")
            If Not Integer.TryParse(txtOrder.Text, rank) OrElse rank < 0 OrElse rank > 999 Then Throw New ArgumentException("الترتيب عدد بين 0 و999.")
            CorrespondenceData.Query("dbo.Correspondence_CatalogSave", CorrespondenceData.P("@Actor", SqlDbType.Int, Actor), CorrespondenceData.P("@Kind", SqlDbType.Char, Kind, 1), CorrespondenceData.P("@ID", SqlDbType.Int, If(ViewState("EditID"), 0)), CorrespondenceData.P("@Title", SqlDbType.NVarChar, txtTitle.Text.Trim(), 200), CorrespondenceData.P("@SortOrder", SqlDbType.Int, rank), CorrespondenceData.P("@IsUrgent", SqlDbType.Bit, chkUrgent.Checked), CorrespondenceData.P("@Behavior", SqlDbType.VarChar, ddlBehavior.SelectedValue, 12), CorrespondenceData.P("@IsActive", SqlDbType.Bit, chkActive.Checked), CorrespondenceData.P("@Version", SqlDbType.Binary, If(ViewState("EditVersion"), DBNull.Value), 8))
            ResetEditor() : BindRows() : Notice("تم حفظ الخيار.")
        Catch ex As Exception
            Notice(CorrespondenceData.ErrorText(ex), True)
        End Try
    End Sub
    Protected Sub Cancel_Click(sender As Object, e As EventArgs)
        ResetEditor() : BindRows() : litNotice.Text = ""
    End Sub
    Protected Sub Catalog_Command(sender As Object, e As GridViewCommandEventArgs)
        Try
            If Not {"EditOption", "activate", "deactivate", "RemoveOption"}.Contains(e.CommandName) Then Return
            Dim parts = CStr(e.CommandArgument).Split(":"c), id = Integer.Parse(parts(0)), version = Convert.FromBase64String(parts(1))
            If e.CommandName = "EditOption" Then
                Dim selected = Rows().Select("ID=" & id.ToString())
                If selected.Length <> 1 Then Throw New ArgumentException("الخيار غير متاح؛ حدّث الصفحة.")
                Dim row = selected(0)
                ViewState("EditID") = id : ViewState("EditVersion") = row("Version")
                txtTitle.Text = CStr(row("Title")) : txtOrder.Text = CStr(row("SortOrder")) : chkActive.Checked = CBool(row("IsActive")) : chkUrgent.Checked = CBool(row("IsUrgent")) : ddlBehavior.SelectedValue = CStr(row("Behavior")) : litEditor.Text = "تعديل الخيار"
                litNotice.Text = ""
            Else
                CorrespondenceData.Query("dbo.Correspondence_CatalogState", CorrespondenceData.P("@Actor", SqlDbType.Int, Actor), CorrespondenceData.P("@ID", SqlDbType.Int, id), CorrespondenceData.P("@Action", SqlDbType.VarChar, If(e.CommandName = "RemoveOption", "delete", e.CommandName), 12), CorrespondenceData.P("@Version", SqlDbType.Binary, version, 8))
                ResetEditor() : BindRows() : Notice("تم تحديث الخيار.")
            End If
        Catch ex As Exception
            Notice(CorrespondenceData.ErrorText(ex), True)
        End Try
    End Sub
End Class
