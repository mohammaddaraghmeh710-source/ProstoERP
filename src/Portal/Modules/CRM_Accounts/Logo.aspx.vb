Imports System.Data
Imports System.Web
Imports System.Web.UI

Public Class CRMAccountLogoPage
    Inherits PageBase

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Try
            If Request.HttpMethod <> "GET" Then Throw New HttpException(405, "طلب غير مسموح.")
            If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401, "يلزم تسجيل الدخول.")
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 Then Throw New HttpException(404, "الشعار غير متاح.")
            Dim rows = CRMData.Query("dbo.CRM_Select_Account_Logo", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Account_ID", SqlDbType.Int, id))
            Dim bytes = If(rows.Rows.Count = 0, Nothing, CRMAccountLogo.ReadFile(Convert.ToString(rows.Rows(0)("Logo_Url"))))
            If bytes Is Nothing Then
                Response.Redirect(CRMAccountLogo.DefaultUrl, False)
            Else
                Response.ContentType = "image/png"
                Response.BinaryWrite(bytes)
            End If
        Catch ex As Exception
            Response.ClearContent()
            Response.TrySkipIisCustomErrors = True
            Dim http = TryCast(ex, HttpException), sql = TryCast(ex, System.Data.SqlClient.SqlException)
            Response.StatusCode = If(http IsNot Nothing, http.GetHttpCode(), If(sql IsNot Nothing AndAlso sql.Number = 51201, 404, 500))
            Response.ContentType = "text/plain; charset=utf-8"
            Response.Write("الشعار غير متاح.")
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        ' Return only authorized image bytes or a plain error response.
    End Sub
End Class
