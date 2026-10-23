Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

Public Class CircularsFile
    Inherits System.Web.UI.Page
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        Response.Cache.SetCacheability(HttpCacheability.NoCache):Response.Cache.SetNoStore()
        Try
            If Request.HttpMethod<>"POST" Then Throw New HttpException(405,"استخدم POST.")
            If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401,"سجّل الدخول مجددًا.")
            If CustomerPortalData.Current IsNot Nothing OrElse SessionManager.GetInstance.Users.UserType=7 Then Throw New HttpException(403,"غير مسموح.")
            If Session("CircularCsrf") Is Nothing OrElse Not String.Equals(CStr(Session("CircularCsrf")),Request.Headers("X-Circular-CSRF"),StringComparison.Ordinal) Then Throw New HttpException(403,"طلب غير مسموح.")
            Dim id As Integer,eventID As Guid
            If Not Integer.TryParse(Request.QueryString("ID"),id) OrElse id<1 OrElse Not Guid.TryParse(Request.QueryString("event"),eventID) OrElse eventID=Guid.Empty Then Throw New HttpException(400,"بيانات غير صحيحة.")
            Dim action=Request.QueryString("action"),admin=Request.QueryString("admin")="1"
            Dim expectedVersion As Object = Nothing, parsedVersion As Integer
            If Request.QueryString("version") IsNot Nothing Then
             If Not Integer.TryParse(Request.QueryString("version"), parsedVersion) OrElse parsedVersion < 1 Then Throw New HttpException(400, "إصدار غير صحيح.")
             expectedVersion = parsedVersion
            End If
            Dim row=CircularsData.Query("dbo.Circular_File",CircularsData.P("@Actor",SqlDbType.Int,SessionManager.GetInstance.Users.UserID),CircularsData.P("@ID",SqlDbType.Int,id),
                CircularsData.P("@Action",SqlDbType.VarChar,action,16),CircularsData.P("@Source",SqlDbType.VarChar,"Portal",10),CircularsData.P("@EventID",SqlDbType.UniqueIdentifier,eventID),CircularsData.P("@Admin",SqlDbType.Bit,admin),CircularsData.P("@ExpectedVersion",SqlDbType.Int,expectedVersion)).Tables(0).Rows(0)
            Response.ClearContent():Response.ContentType="application/pdf" : Response.AddHeader("X-Circular-Version",CInt(row("Version")).ToString(Global.System.Globalization.CultureInfo.InvariantCulture))
            Response.AddHeader("X-Content-Type-Options","nosniff")
            Response.AddHeader("Content-Disposition",If(action="download","attachment","inline") & "; filename=circular-" & id.ToString() & ".pdf; filename*=UTF-8''" & Uri.EscapeDataString(CStr(row("FileName"))))
            Dim bytes=DirectCast(row("FileBytes"),Byte())
            Response.AddHeader("Content-Length",bytes.Length.ToString())
            Response.BinaryWrite(bytes)
        Catch ex As Exception
            Response.ClearContent():Response.TrySkipIisCustomErrors=True:Response.ContentType="text/plain; charset=utf-8"
            Dim http=TryCast(ex,HttpException),sql=TryCast(ex,SqlException)
            Response.StatusCode=If(http IsNot Nothing,http.GetHttpCode(),If(sql IsNot Nothing AndAlso sql.Number=51804,404,If(sql IsNot Nothing AndAlso (sql.Number=51801 OrElse sql.Number=51803),403,If(sql IsNot Nothing AndAlso sql.Number=51800,400,If(sql IsNot Nothing AndAlso sql.Number=51809,409,500)))))
            Response.Write(If(http IsNot Nothing,http.Message,If(sql IsNot Nothing AndAlso sql.Number=51809,"تغيّر إصدار التعميم؛ أغلق النافذة وأعد فتحه.",CircularsData.ErrorText(ex))))
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Protected Overrides Sub Render(writer As HtmlTextWriter)
        ' Only protected PDF bytes or a plain error message are written.
    End Sub
End Class
