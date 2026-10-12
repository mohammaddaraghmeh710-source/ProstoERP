Imports System.Data
Imports System.Linq
Imports System.Globalization

Public Class CustomerAccess
    Inherits PageBase
    Private actor As Integer
    Private account As Integer
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/Login.aspx") : Return
        actor = SessionManager.GetInstance.Users.UserID
        If Not Integer.TryParse(Request.QueryString("id"), account) OrElse account <= 0 Then Throw New System.Web.HttpException(404, "العميل غير متاح")
        Try
            CustomerPortalData.Query("dbo.Customer_AdminCheck", CustomerPortalData.P("@Actor", SqlDbType.Int, actor))
        Catch ex As System.Data.SqlClient.SqlException
            If ex.Number=51910 Then Throw New System.Web.HttpException(403,"هذه الإدارة متاحة لمدير النظام فقط.")
            Throw
        End Try
        ViewStateUserKey = Session.SessionID
    End Sub
    Private Function Rows(section As String, Optional brand As Integer = 0) As DataTable
        Return CustomerPortalData.Query("dbo.Customer_AdminData", CustomerPortalData.P("@Actor", SqlDbType.Int, actor), CustomerPortalData.P("@AccountID", SqlDbType.Int, account), CustomerPortalData.P("@Section", SqlDbType.VarChar, section, 20), CustomerPortalData.P("@Brand", SqlDbType.Int, brand))
    End Function
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            FillLogin()
            BindRows()
        End If
    End Sub
    Private Sub FillLogin()
        Dim row = Rows("login").Rows(0)
        litName.Text = Server.HtmlEncode(CStr(row("Name_AR")))
        txtUsername.Text = Convert.ToString(row("Username"))
        chkLoginActive.Checked = IsDBNull(row("IsActive")) OrElse CBool(row("IsActive"))
        ViewState("LoginVersion") = If(IsDBNull(row("Version")), Nothing, row("Version"))
    End Sub
    Private Sub BindRows()
        activity.DataSource = Rows("activity") : activity.DataBind()
    End Sub
    Private Sub Message(text As String, Optional failed As Boolean = False)
        litMessage.Text = "<div class=""alert " & If(failed, "alert-danger", "alert-success") & """ role=""status"">" & Server.HtmlEncode(text) & "</div>"
    End Sub
    Protected Sub SaveLogin_Click(sender As Object, e As EventArgs)
        Try
            Dim hash As Byte() = Nothing, salt As Byte() = Nothing
            If txtPassword.Text <> "" Then
                If txtPassword.Text.Length < 8 OrElse txtPassword.Text.Length > 128 Then Throw New ArgumentException("كلمة المرور من 8 إلى 128 حرفًا.")
                salt = CustomerPortalData.NewSalt() : hash = CustomerPortalData.HashPassword(txtPassword.Text, salt, 210000)
            End If
            CustomerPortalData.Query("dbo.Customer_SaveLogin", CustomerPortalData.P("@Actor", SqlDbType.Int, actor), CustomerPortalData.P("@AccountID", SqlDbType.Int, account),
                CustomerPortalData.P("@Username", SqlDbType.NVarChar, txtUsername.Text.Trim(), 100), CustomerPortalData.P("@Hash", SqlDbType.VarBinary, hash, 32), CustomerPortalData.P("@Salt", SqlDbType.VarBinary, salt, 32),
                CustomerPortalData.P("@Active", SqlDbType.Bit, chkLoginActive.Checked), CustomerPortalData.P("@Version", SqlDbType.Binary, ViewState("LoginVersion"), 8))
            txtPassword.Text = "" : FillLogin() : BindRows() : Message("تم حفظ بيانات الدخول. يلزم العميل تسجيل الدخول مجددًا.")
        Catch ex As Exception
            Message(CustomerPortalData.ErrorText(ex), True)
        End Try
    End Sub
End Class
