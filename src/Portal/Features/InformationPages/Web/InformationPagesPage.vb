Imports System.Data.SqlClient
Imports System.Web

Public Class InformationPagesPage
    Inherits PageBase

    Protected ReadOnly Property Actor As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property
    Protected ReadOnly Property IsAdministrator As Boolean
        Get
            Return SessionManager.GetInstance.Users.UserType = 1
        End Get
    End Property
    Protected ReadOnly Property PageID As Integer
        Get
            Return QueryNumber("ID")
        End Get
    End Property
    Protected ReadOnly Property English As Boolean
        Get
            Return Request.QueryString("lang") = "en"
        End Get
    End Property
    Protected Function QueryNumber(key As String) As Integer
        Dim value As Integer
        If Request.QueryString(key) IsNot Nothing AndAlso (Not Integer.TryParse(Request.QueryString(key), value) OrElse value < 0) Then Throw New HttpException(400, "رابط غير صحيح")
        Return value
    End Function
    Protected Overrides Sub OnInit(e As EventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("~/Login.aspx", True)
        ViewStateUserKey = Session.SessionID
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        MyBase.OnInit(e)
    End Sub
    Protected Sub RequireAdmin()
        If Not IsAdministrator Then Throw New HttpException(403, "غير مسموح")
    End Sub
    Protected Sub ShowError(target As Literal, ex As Exception)
        System.Diagnostics.Trace.TraceError("Information pages: {0}", ex)
        Dim sql = TryCast(ex, SqlException)
        Dim message = "تعذّر تنفيذ العملية. يرجى المحاولة مجددًا."
        If TypeOf ex Is ArgumentException OrElse (sql IsNot Nothing AndAlso (sql.Number = 51600 OrElse sql.Number = 51604)) Then message = ex.Message
        target.Text = "<div class=""alert alert-danger"" role=""alert"">" & Server.HtmlEncode(message) & "</div>"
    End Sub
End Class
