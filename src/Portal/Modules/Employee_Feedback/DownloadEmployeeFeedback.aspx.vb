Imports System.IO
Imports Prosto_ERP_ClassLibrary

Public Class DownloadEmployeeFeedback
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If ReportMode Then RequireAdmin()
        Using db As New Prosto_ERP_DataClassesDataContext()
            Dim f = db.Select_Employee_Feedback_Download(ActorID, RequestID, ReportMode).SingleOrDefault()
            If f Is Nothing Then Throw New HttpException(404, "المرفق غير متاح")
            Dim name = Path.GetFileName(f.FileName)
            If name <> f.FileName Then Throw New HttpException(404, "المرفق غير متاح")
            Dim file = Server.MapPath("~/App_Data/EmployeeFeedback/" & name)
            If Not IO.File.Exists(file) Then Throw New HttpException(404, "المرفق غير متاح")
            Response.Clear()
            Response.ContentType = "application/octet-stream"
            Response.AddHeader("X-Content-Type-Options", "nosniff")
            Dim _
                mime As _
                    New Dictionary(Of String,String) _
                    From {{"pdf","application/pdf"},{"png","image/png"},{"jpg","image/jpeg"},{"jpeg","image/jpeg"},
                    {"gif","image/gif"}}
            Dim extension = Convert.ToString(f.File_Type).TrimStart("."c).ToLowerInvariant()
            Dim preview = Request.QueryString("preview") = "1" AndAlso mime.ContainsKey(extension)
            If preview Then Response.ContentType = mime(extension)
            Response.AddHeader("Content-Disposition",
                               If(preview, "inline", "attachment") & "; filename=attachment-" & f.ID.ToString() & "." &
                               extension)
            Response.Cache.SetCacheability(HttpCacheability.NoCache)
            Response.Cache.SetNoStore()
            Response.TransmitFile(file)
            Response.End()
        End Using
    End Sub
End Class


