Imports System.IO

Public Class CustomerFeedbackFile
    Inherits CustomerPortalPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim id As Integer
        If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 Then _
            Throw New HttpException(404, "المرفق غير متاح")
        Dim files = CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackDetail",
                                                     CustomerPortalData.P("@AttachmentID", SqlDbType.Int, id))
        If files.Rows.Count <> 1 Then Throw New HttpException(404, "المرفق غير متاح")
        Dim name = CStr(files.Rows(0)("FileName"))
        If Path.GetFileName(name) <> name OrElse name.Contains(":") Then _
            Throw New HttpException(404, "المرفق غير متاح")
        Dim physical = Path.Combine(Server.MapPath("~/App_Data/EmployeeFeedback/"), name)
        If Not File.Exists(physical) Then Throw New HttpException(404, "المرفق غير متاح")
        Response.Clear()
        Response.ContentType = "application/octet-stream"
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Response.AddHeader("Content-Disposition",
                           "attachment; filename=attachment-" & id.ToString() & Path.GetExtension(name))
        Response.TransmitFile(physical)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Overrides Sub Render(writer As HtmlTextWriter)
    End Sub
End Class


