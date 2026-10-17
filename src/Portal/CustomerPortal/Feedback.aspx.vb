Imports System.Data
Imports System.IO
Imports System.Linq
Public Class CustomerFeedback
 Inherits CustomerPortalPage
 Private Function Options(section As String) As DataTable
  Return CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackOptions",CustomerPortalData.P("@Section",SqlDbType.VarChar,section,16),CustomerPortalData.P("@Brand",SqlDbType.Int,If(ddlBrand.SelectedValue="",0,CInt(ddlBrand.SelectedValue))),CustomerPortalData.P("@Type",SqlDbType.Int,If(ddlType.SelectedValue="",0,CInt(ddlType.SelectedValue))))
 End Function
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  If Not IsPostBack Then
   ViewState("Operation")=Guid.NewGuid()
   CustomerPortalData.BindOptions(ddlType,Options("types")) : CustomerPortalData.BindOptions(ddlBrand,Options("brands"))
   Brand_Changed(Nothing,EventArgs.Empty)
   txtMobile.Text=Convert.ToString(CustomerPortalData.RequireSession()("Phone"))
   BindHistory()
  End If
 End Sub
 Protected Sub Type_Changed(sender As Object,e As EventArgs)
  CustomerPortalData.BindOptions(ddlTopic,Options("topics"))
 End Sub
 Protected Sub Brand_Changed(sender As Object,e As EventArgs)
  CustomerPortalData.BindOptions(ddlBranch,Options("branches")) : Type_Changed(Nothing,EventArgs.Empty)
 End Sub
 Private Sub BindHistory()
  Dim rows=Options("history") : history.DataSource=rows : history.DataBind() : empty.Visible=rows.Rows.Count=0
 End Sub
 Protected Sub Submit_Click(sender As Object,e As EventArgs)
  Dim saved As New List(Of String)
  Try
   If CInt(ddlType.SelectedValue)=0 OrElse CInt(ddlBrand.SelectedValue)=0 OrElse CInt(ddlBranch.SelectedValue)=0 OrElse CInt(ddlTopic.SelectedValue)=0 Then Throw New ArgumentException("يرجى اختيار نوع الطلب والعلامة والفرع والموضوع.")
   If String.IsNullOrWhiteSpace(txtTitle.Text) OrElse String.IsNullOrWhiteSpace(txtDetails.Text) OrElse txtDetails.Text.Length>10000 OrElse String.IsNullOrWhiteSpace(txtMobile.Text) Then Throw New ArgumentException("أكمل العنوان ورقم التواصل والتفاصيل (حتى 10000 حرف).")
   Dim items As New List(Of FileAttribute)
   If uploads.PostedFiles.Count>EmployeeFeedbackData.MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
   For Each upload As System.Web.HttpPostedFile In uploads.PostedFiles
    If upload.ContentLength=0 Then Continue For
    If upload.ContentLength>EmployeeFeedbackData.MaxFileBytes Then Throw New ArgumentException("حجم الملف يتجاوز 10 ميجابايت.")
    Using stream As New MemoryStream()
     upload.InputStream.CopyTo(stream) : items.Add(New FileAttribute With {.NameFile=upload.FileName,.FileByte=stream.ToArray()})
    End Using
   Next
   Dim files=EmployeeFeedbackData.SaveQueuedAttachments(items,saved)
   Dim result=CustomerPortalData.CustomerQuery("dbo.Customer_SubmitFeedback",CustomerPortalData.P("@OperationID",SqlDbType.UniqueIdentifier,ViewState("Operation")),CustomerPortalData.P("@Type",SqlDbType.Int,CInt(ddlType.SelectedValue)),CustomerPortalData.P("@Topic",SqlDbType.Int,CInt(ddlTopic.SelectedValue)),CustomerPortalData.P("@Brand",SqlDbType.Int,CInt(ddlBrand.SelectedValue)),CustomerPortalData.P("@Branch",SqlDbType.Int,CInt(ddlBranch.SelectedValue)),CustomerPortalData.P("@Mobile",SqlDbType.NVarChar,txtMobile.Text.Trim(),30),CustomerPortalData.P("@Title",SqlDbType.NVarChar,txtTitle.Text.Trim(),300),CustomerPortalData.P("@Details",SqlDbType.NVarChar,txtDetails.Text.Trim(),-1),CustomerPortalData.P("@Files",SqlDbType.Xml,files.ToString()))
   If result.Columns.Contains("Replay") AndAlso CBool(result.Rows(0)("Replay")) Then
    For Each path In saved : File.Delete(path) : Next
   End If
   saved.Clear()
   ViewState("Operation")=Guid.NewGuid() : txtTitle.Text="" : txtDetails.Text=""
   litMessage.Text="<div class=""alert alert-success"" role=""status"">تم إرسال الطلب رقم " & CInt(result.Rows(0)("ID")).ToString() & " إلى مدير النظام.</div>"
   BindHistory()
  Catch ex As Exception
   Dim sql=TryCast(ex,System.Data.SqlClient.SqlException)
   If TypeOf ex Is ArgumentException OrElse (sql IsNot Nothing AndAlso {51910,51911,51500}.Contains(sql.Number)) Then
    For Each path In saved
     If File.Exists(path) Then File.Delete(path)
    Next
   End If
   'Keep files after an uncertain SQL outcome; the request may have committed.
   litMessage.Text="<div class=""alert alert-danger"" role=""alert"">" & Server.HtmlEncode(CustomerPortalData.ErrorText(ex)) & "</div>"
  End Try
 End Sub
End Class
