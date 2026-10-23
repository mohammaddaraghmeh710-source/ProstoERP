Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Web
Imports System.Web.Script.Serialization

Public Class CircularReaderEndpoint
    Inherits System.Web.UI.Page

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Response.ContentType = "application/json; charset=utf-8"
        Response.Cache.SetNoStore()
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Dim serializer As New JavaScriptSerializer()
        Try
            If Request.HttpMethod <> "POST" Then Throw New HttpException(405, "استخدم POST.")
            Dim kind = Request.QueryString("kind"), id As Integer
            If Not {"customer", "employee", "admin"}.Contains(kind) OrElse Not Integer.TryParse(Request.QueryString("id"), id) OrElse id < 1 Then Throw New HttpException(400, "طلب غير صحيح.")
            Dim customer = kind = "customer", admin = kind = "admin"
            Dim key = If(customer, "CustomerCircularCsrf", "CircularCsrf")
            If Session(key) Is Nothing OrElse Not String.Equals(Convert.ToString(Session(key)), Request.Headers("X-Circular-CSRF"), StringComparison.Ordinal) Then Throw New HttpException(403, "انتهت صلاحية النموذج؛ أعد فتح الصفحة.")
            Dim rows As DataTable
            If customer Then
                If CustomerPortalData.Current Is Nothing Then Throw New HttpException(401, "سجّل الدخول مجددًا.")
                CustomerPortalData.RequireSession()
                rows = CustomerPortalData.CustomerQuery("dbo.Customer_Circulars", CustomerPortalData.P("@ID", SqlDbType.Int, id))
            Else
                If CustomerPortalData.Current IsNot Nothing Then Throw New HttpException(403, "غير مسموح.")
                Dim actor = SessionManager.GetInstance.Users
                If actor Is Nothing Then Throw New HttpException(401, "سجّل الدخول مجددًا.")
                If actor.UserType = 7 OrElse (admin AndAlso actor.UserType <> 1) Then Throw New HttpException(403, "غير مسموح.")
                rows = CircularsData.Query("dbo.Circular_Detail", CircularsData.P("@Actor", SqlDbType.Int, actor.UserID), CircularsData.P("@ID", SqlDbType.Int, id), CircularsData.P("@Admin", SqlDbType.Bit, admin)).Tables(0)
            End If
            If rows.Rows.Count = 0 Then Throw New HttpException(404, "التعميم غير متاح.")
            Dim row = rows.Rows(0)
            Dim result = New With {
                .id = id, .version = CInt(row("Version")),
                .title = Text(row, "Title"), .titleEn = Text(row, "Title_EN"),
                .summary = Text(row, "Summary"), .summaryEn = Text(row, "Summary_EN"),
                .date = CDate(row("CircularDate")).ToString("yyyy-MM-dd", Global.System.Globalization.CultureInfo.InvariantCulture),
                .brand = Text(row, "BrandName"), .fileName = Text(row, "FileName"),
                .allowDownload = CBool(row("AllowDownload")), .isRead = Not admin AndAlso CBool(row("IsRead")),
                .fileUrl = If(customer, "/CustomerPortal/CircularFile.aspx?ID=", "/Modules/Circulars/File.aspx?ID=") & id.ToString(Global.System.Globalization.CultureInfo.InvariantCulture) & If(admin, "&admin=1", ""),
                .admin = admin
            }
            Response.Write(serializer.Serialize(result))
        Catch ex As Exception
            Dim http = TryCast(ex, HttpException), sql = TryCast(ex, SqlException)
            Response.StatusCode = If(http IsNot Nothing, http.GetHttpCode(), If(sql IsNot Nothing AndAlso sql.Number = 51804, 404, If(sql IsNot Nothing AndAlso sql.Number = 51911, 401, If(sql IsNot Nothing AndAlso {51801, 51803}.Contains(sql.Number), 403, 500))))
            Response.TrySkipIisCustomErrors = True
            Response.Write(serializer.Serialize(New With {.error = If(http IsNot Nothing, http.Message, If(Response.StatusCode = 401, "سجّل الدخول مجددًا.", CircularsPresentation.ErrorText(ex)))}))
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Private Shared Function Text(row As DataRow, name As String) As String
        Return If(row.Table.Columns.Contains(name) AndAlso Not row.IsNull(name), Convert.ToString(row(name)), "")
    End Function

    Protected Overrides Sub Render(writer As System.Web.UI.HtmlTextWriter)
    End Sub
End Class
