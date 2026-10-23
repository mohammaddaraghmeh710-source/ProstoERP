Imports System.Data
Imports System.Linq
Imports System.Web
Public Class CustomerCircularFile
 Inherits System.Web.UI.Page
 Protected Overrides Sub OnLoad(e As EventArgs)
  MyBase.OnLoad(e) : Response.Cache.SetNoStore() : Response.AddHeader("X-Content-Type-Options","nosniff")
  Try
   If Request.HttpMethod<>"POST" Then Throw New HttpException(405,"استخدم POST.")
   If CustomerPortalData.Current Is Nothing Then Throw New HttpException(401,"سجّل الدخول مجددًا.")
   CustomerPortalData.RequireSession()
   If Session("CustomerCircularCsrf") Is Nothing OrElse Request.Headers("X-Circular-CSRF")<>CStr(Session("CustomerCircularCsrf")) Then Throw New HttpException(403,"طلب غير مسموح.")
   Dim id As Integer,eventID As Guid,action=Request.QueryString("action")
   If Not Integer.TryParse(Request.QueryString("ID"),id) OrElse id<1 OrElse Not Guid.TryParse(Request.QueryString("event"),eventID) OrElse eventID=Guid.Empty Then Throw New HttpException(400,"طلب غير صحيح.")
   Dim expectedVersion As Object = Nothing, parsedVersion As Integer
   If Request.QueryString("version") IsNot Nothing Then
    If Not Integer.TryParse(Request.QueryString("version"), parsedVersion) OrElse parsedVersion < 1 Then Throw New HttpException(400, "إصدار غير صحيح.")
    expectedVersion = parsedVersion
   End If
   Dim row=CustomerPortalData.CustomerQuery("dbo.Customer_CircularFile",CustomerPortalData.P("@ID",SqlDbType.Int,id),CustomerPortalData.P("@Action",SqlDbType.VarChar,action,16),CustomerPortalData.P("@EventID",SqlDbType.UniqueIdentifier,eventID),CustomerPortalData.P("@ExpectedVersion",SqlDbType.Int,expectedVersion)).Rows(0)
   Dim bytes=DirectCast(row("FileBytes"),Byte())
   Response.ContentType="application/pdf" : Response.AddHeader("X-Circular-Version",CInt(row("Version")).ToString(Global.System.Globalization.CultureInfo.InvariantCulture)) : Response.AddHeader("Content-Length",bytes.Length.ToString())
   Response.AddHeader("Content-Disposition",If(action="download","attachment","inline") & "; filename=circular-" & id.ToString() & ".pdf; filename*=UTF-8''" & Uri.EscapeDataString(CStr(row("FileName"))))
   Response.BinaryWrite(bytes)
  Catch ex As Exception
   Dim http=TryCast(ex,HttpException),sql=TryCast(ex,System.Data.SqlClient.SqlException)
   Response.ClearContent() : Response.ContentType="text/plain; charset=utf-8" : Response.TrySkipIisCustomErrors=True
   Response.StatusCode=If(http IsNot Nothing,http.GetHttpCode(),If(sql IsNot Nothing AndAlso sql.Number=51804,404,If(sql IsNot Nothing AndAlso {51801,51803,51704}.Contains(sql.Number),403,If(sql IsNot Nothing AndAlso sql.Number=51809,409,500))))
   Response.Write(If(http IsNot Nothing,http.Message,If(sql IsNot Nothing AndAlso sql.Number=51809,"تغيّر إصدار التعميم؛ أغلق النافذة وأعد فتحه.",CircularsPresentation.ErrorText(ex))))
  End Try
  Context.ApplicationInstance.CompleteRequest()
 End Sub
 Protected Overrides Sub Render(writer As System.Web.UI.HtmlTextWriter)
 End Sub
End Class
