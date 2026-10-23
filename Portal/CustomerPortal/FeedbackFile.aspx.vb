Imports System.Data
Imports System.IO
Public Class CustomerFeedbackFile
 Inherits CustomerPortalPage
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  Dim id As Integer
  If Not Integer.TryParse(Request.QueryString("id"),id) OrElse id<=0 Then Throw New System.Web.HttpException(404,"المرفق غير متاح")
  Dim files=CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackDetail",CustomerPortalData.P("@AttachmentID",SqlDbType.Int,id))
  If files.Rows.Count<>1 Then Throw New System.Web.HttpException(404,"المرفق غير متاح")
  Dim name=CStr(files.Rows(0)("FileName"))
  If Path.GetFileName(name)<>name OrElse name.Contains(":") Then Throw New System.Web.HttpException(404,"المرفق غير متاح")
  Dim physical=Path.Combine(Server.MapPath("~/App_Data/EmployeeFeedback/"),name)
  If Not File.Exists(physical) Then Throw New System.Web.HttpException(404,"المرفق غير متاح")
  Response.Clear() : Response.ContentType="application/octet-stream"
  Response.AddHeader("X-Content-Type-Options","nosniff")
  Response.AddHeader("X-Frame-Options","SAMEORIGIN")
  Dim mime As New Dictionary(Of String,String) From {{"pdf","application/pdf"},{"png","image/png"},{"jpg","image/jpeg"},{"jpeg","image/jpeg"},{"gif","image/gif"}}
  Dim extension=Path.GetExtension(name).TrimStart("."c).ToLowerInvariant()
  Dim preview=Request.QueryString("preview")="1" AndAlso mime.ContainsKey(extension) AndAlso extension=Convert.ToString(files.Rows(0)("File_Type")).TrimStart("."c).ToLowerInvariant()
  If preview Then Response.ContentType=mime(extension)
  Response.AddHeader("Content-Disposition",If(preview,"inline","attachment") & "; filename=attachment-" & id.ToString() & "." & extension)
  Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache) : Response.Cache.SetNoStore()
  Response.TransmitFile(physical) : Context.ApplicationInstance.CompleteRequest()
 End Sub
 Protected Overrides Sub Render(writer As System.Web.UI.HtmlTextWriter)
 End Sub
End Class
