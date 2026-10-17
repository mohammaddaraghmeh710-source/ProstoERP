Imports System.IO

Public Class CustomerDownload
    Inherits CustomerPortalPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim id As Integer
        If Not Integer.TryParse(Request.QueryString("id"), id) Then _
            Throw New HttpException(404, "الملف غير متاح")
        Dim rows = CustomerPortalData.Guide("file", 0, id)
        If rows.Rows.Count <> 1 OrElse Not CBool(rows.Rows(0)("Can_Download_Document")) Then _
            Throw New HttpException(403, "التنزيل غير متاح")
        Dim path = Server.MapPath(CStr(rows.Rows(0)("File_Path")))
        If _
            Not File.Exists(path) OrElse
            Not String.Equals(IO.Path.GetExtension(path), ".pdf", StringComparison.OrdinalIgnoreCase) Then _
            Throw New HttpException(404, "الملف غير متاح")
        CustomerPortalData.LogFile(id, "download")
        Response.Clear()
        Response.ContentType = "application/pdf"
        Response.AddHeader("Content-Disposition", "attachment; filename=guide-" & id.ToString() & ".pdf")
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Response.TransmitFile(path)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class


