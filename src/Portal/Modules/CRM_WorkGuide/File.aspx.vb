Imports System.Data
Imports System.IO
Imports System.Web
Imports System.Web.UI

Public Class CRMWorkGuideDownload
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
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 Then Throw New HttpException(404, "الملف غير متاح.")
            Dim data = CRMData.Query("dbo.CRM_WorkGuide_File", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, id))
            If data.Rows.Count = 0 Then Throw New HttpException(404, "الملف غير متاح.")
            Dim row = data.Rows(0), file = CRMWorkGuideFile.PhysicalPath(Convert.ToString(row("File_Url")))
            If Not System.IO.File.Exists(file) Then Throw New HttpException(404, "الملف غير متاح.")
            Dim extension = Convert.ToString(row("File_Extension"))
            Response.ContentType = If(extension = ".pdf", "application/pdf", If(extension = ".doc", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
            Response.AddHeader("Content-Disposition", "attachment; filename=""work-guide-" & id.ToString() & extension & """; filename*=UTF-8''" & Uri.EscapeDataString(Convert.ToString(row("File_Name"))))
            Response.BinaryWrite(System.IO.File.ReadAllBytes(file))
        Catch ex As Exception
            Response.ClearContent() : Response.TrySkipIisCustomErrors = True
            Dim http = TryCast(ex, HttpException), sql = TryCast(ex, System.Data.SqlClient.SqlException)
            Response.StatusCode = If(http IsNot Nothing, http.GetHttpCode(), If(sql IsNot Nothing AndAlso sql.Number = 51200, 403, If(sql IsNot Nothing AndAlso sql.Number = 51201, 404, 500)))
            Response.ContentType = "text/plain; charset=utf-8" : Response.Write("الملف غير متاح.")
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Protected Overrides Sub Render(writer As HtmlTextWriter)
        ' Download responses contain only the authorized document bytes.
    End Sub
End Class
