Imports System.Data
Imports System.IO
Imports System.Linq
Imports System.Web
Imports System.Web.UI
Imports System.Web.Script.Serialization

Public Class CustomerWorkGuideFile
    Inherits PageBase
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Server.ScriptTimeout = 120
        Response.Cache.SetCacheability(HttpCacheability.NoCache) : Response.Cache.SetNoStore()
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Try
            If CustomerPortalData.Current Is Nothing Then Throw New HttpException(401, "يلزم تسجيل الدخول.")
            If Request.HttpMethod <> "POST" Then Throw New HttpException(405, "طلب غير مسموح.")
            Dim token = TryCast(Session("CRMGuideCSRF"), String)
            If String.IsNullOrEmpty(token) OrElse Request.Headers("X-CRMGuide-CSRF") <> token Then Throw New HttpException(403, "طلب غير مسموح.")
            Dim id As Integer, category As Integer, action = Request.QueryString("action")
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 OrElse Not Integer.TryParse(Request.QueryString("category"), category) OrElse category <= 0 OrElse Not {"view", "download", "details"}.Contains(action) Then Throw New HttpException(404, "الملف غير متاح.")
            Dim row = Authorize(id, category, action, False)
            Dim url = Convert.ToString(row("File_Url")), extension = Convert.ToString(row("File_Extension"))
            If action = "details" Then
                Dim currentDetails = Authorize(id, category, action, True)
                Response.ContentType = "application/json; charset=utf-8"
                Response.Write((New JavaScriptSerializer With {.MaxJsonLength = 8388608}).Serialize(New With {.nameAr = Convert.ToString(currentDetails("Name_AR")), .nameEn = Convert.ToString(currentDetails("Name_EN")), .detailsAr = CRMWorkGuideContent.Clean(Convert.ToString(currentDetails("Details_AR"))), .detailsEn = CRMWorkGuideContent.Clean(Convert.ToString(currentDetails("Details_EN")))}))
                Context.ApplicationInstance.CompleteRequest() : Return
            End If
            If action = "view" AndAlso extension <> ".pdf" Then
                ' Viewing Word means downloading its original; it still requires the download grant.
                action = "download" : row = Authorize(id, category, action, False)
            End If
            Dim physical = CRMWorkGuideFile.PhysicalPath(url)
            If Not File.Exists(physical) Then Throw New HttpException(404, "الملف غير متاح.")
            Dim bytes = File.ReadAllBytes(physical)
            ' Conversion can take time: revalidate current login, grant, category, item and file pointer.
            Dim current = Authorize(id, category, action, True)
            If Convert.ToString(current("File_Url")) <> url Then Throw New HttpException(409, "تغير الملف؛ أعد فتح الدليل.")
            If action = "view" Then
                Response.ContentType = "application/pdf"
                Response.AddHeader("Content-Disposition", "inline; filename=work-guide.pdf")
            Else
                Response.ContentType = If(extension = ".pdf", "application/pdf", If(extension = ".doc", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                Response.AddHeader("Content-Disposition", "attachment; filename=""work-guide-" & id.ToString() & extension & """; filename*=UTF-8''" & Uri.EscapeDataString(Convert.ToString(row("File_Name"))))
            End If
            Response.BinaryWrite(bytes)
        Catch ex As Exception
            Response.ClearContent() : Response.TrySkipIisCustomErrors = True
            Dim http = TryCast(ex, HttpException), sql = TryCast(ex, System.Data.SqlClient.SqlException)
            Response.StatusCode = If(http IsNot Nothing, http.GetHttpCode(), If(sql IsNot Nothing AndAlso sql.Number = 51911, 401, If(sql IsNot Nothing AndAlso sql.Number = 51912, 403, If(TypeOf ex Is ArgumentException, 422, 500))))
            Response.ContentType = "text/plain; charset=utf-8"
            Response.Write(If(TypeOf ex Is ArgumentException, ex.Message, If(sql IsNot Nothing AndAlso sql.Number = 51912, "لا تملك صلاحية لهذه العملية ضمن التصنيف المحدد.", "الملف غير متاح؛ تحقق من صلاحية الدخول وأعد المحاولة.")))
            If Response.StatusCode = 500 Then System.Diagnostics.Trace.TraceError("Customer work-guide file failed: {0}", ex.GetType().Name)
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Private Function Authorize(id As Integer, category As Integer, action As String, log As Boolean) As DataRow
        Return CustomerPortalData.CustomerQuery("dbo.Customer_WorkGuide_File", CustomerPortalData.P("@ID", SqlDbType.Int, id), CustomerPortalData.P("@Category_ID", SqlDbType.Int, category), CustomerPortalData.P("@Action", SqlDbType.VarChar, action, 10), CustomerPortalData.P("@Log", SqlDbType.Bit, log)).Rows(0)
    End Function
    Protected Overrides Sub Render(writer As HtmlTextWriter)
    End Sub
End Class
