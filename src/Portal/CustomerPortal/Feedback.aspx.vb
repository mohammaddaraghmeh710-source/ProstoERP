Imports System.Data.SqlClient
Imports System.IO
Imports System.Linq
Imports System.Web.UI.WebControls
Public Class CustomerFeedback
 Inherits CustomerPortalPage
 Protected Property KeepWizardOpen As Boolean
 Private Function Options(section As String) As DataTable
  Return CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackOptions",CustomerPortalData.P("@Section",SqlDbType.VarChar,section,16))
 End Function
 Protected Overrides Sub OnInit(e As EventArgs)
  MyBase.OnInit(e)
  'Register the complete authorized sets before LoadPostData. JavaScript narrows
  'the visible choices; the save procedure independently validates membership.
  CustomerPortalPresentation.BindOptions(ddlType,Options("types"),"اختر نوع الطلب")
  CustomerPortalPresentation.BindOptions(ddlBrand,Options("brands"),"اختر العلامة التجارية")
  Dim branches=Options("allbranches"),topics=Options("alltopics")
  CustomerPortalPresentation.BindOptions(ddlBranch,branches,"اختر الفرع")
  CustomerPortalPresentation.BindOptions(ddlTopic,topics,"اختر الموضوع")
  For Each row As DataRow In branches.Rows
   ddlBranch.Items.FindByValue(CStr(row("ID"))).Attributes("data-brand-id")=CStr(row("BrandID"))
  Next
  For Each row As DataRow In topics.Rows
   Dim item=ddlTopic.Items.FindByValue(CStr(row("ID")))
   item.Attributes("data-brand-id")=CStr(row("BrandID")) : item.Attributes("data-type-id")=CStr(row("TypeID"))
  Next
  noBranches.Visible=branches.Rows.Count=0
  Dim recipients=Options("recipients")
  litRecipients.Text=If(recipients.Rows.Count=0,"لا يوجد مدير نظام فعّال حاليًا. تواصل مع الإدارة.",String.Join("، ",recipients.AsEnumerable().Select(Function(r) CStr(r("Title")))))
  btnSubmit.Enabled=branches.Rows.Count>0 AndAlso recipients.Rows.Count>0
  btnSubmit.Attributes("data-feedback-disabled")=If(btnSubmit.Enabled,"0","1")
  txtDetails.Attributes("maxlength")="10000"
 End Sub
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  If Not IsPostBack Then
   ViewState("Operation")=Guid.NewGuid()
   txtMobile.Text=Convert.ToString(CustomerPortalData.RequireSession()("Phone"))
  End If
  BindHistory()
 End Sub
 Private Sub BindHistory()
  Dim rows=Options("history")
  history.DataSource=rows : history.DataBind()
  Dim active=rows.AsEnumerable().Count(Function(r) CInt(r("Status"))<>3)
  litStatistics.Text="<div class=""row g-4 mb-4"" aria-label=""إحصائيات الطلبات""><div class=""col-12 col-md-4""><div class=""card type-stat-card""><div class=""card-body type-flex align-items-start justify-content-between""><div><span>إجمالي الطلبات</span><div class=""type-stat-count"">" & rows.Rows.Count.ToString() & "</div></div><span class=""badge bg-label-primary rounded type-stat-icon""><i class=""bx bx-collection"" aria-hidden=""true""></i></span></div></div></div><div class=""col-12 col-md-4""><div class=""card type-stat-card""><div class=""card-body type-flex align-items-start justify-content-between""><div><span>الطلبات الفعّالة</span><div class=""type-stat-count"">" & active.ToString() & "</div></div><span class=""badge bg-label-warning rounded type-stat-icon""><i class=""bx bx-time-five"" aria-hidden=""true""></i></span></div></div></div><div class=""col-12 col-md-4""><div class=""card type-stat-card""><div class=""card-body type-flex align-items-start justify-content-between""><div><span>الطلبات المغلقة</span><div class=""type-stat-count"">" & (rows.Rows.Count-active).ToString() & "</div></div><span class=""badge bg-label-success rounded type-stat-icon""><i class=""bx bx-check-circle"" aria-hidden=""true""></i></span></div></div></div></div>"
  Dim brands=rows.AsEnumerable().GroupBy(Function(r) CInt(r("Brand_ID"))).Select(Function(g) g.First()).OrderBy(Function(r) CStr(r("Brand_Title_Ar")))
  litHistoryBrands.Text=String.Join("",brands.Select(Function(r) "<option value=""" & CInt(r("Brand_ID")).ToString() & """>" & Server.HtmlEncode(CStr(r("Brand_Title_Ar"))) & "</option>"))
 End Sub
 Private Function Number(list As DropDownList) As Integer
  Dim value As Integer : Integer.TryParse(list.SelectedValue,value) : Return value
 End Function
 Protected Sub Submit_Click(sender As Object,e As EventArgs)
  Dim saved As New List(Of String),databaseAttempted As Boolean=False
  KeepWizardOpen=True
  Try
   If Number(ddlType)<=0 OrElse Number(ddlBrand)<=0 OrElse Number(ddlBranch)<=0 OrElse Number(ddlTopic)<=0 Then Throw New ArgumentException("يرجى اختيار نوع الطلب والعلامة والفرع والموضوع.")
   If String.IsNullOrWhiteSpace(txtTitle.Text) OrElse txtTitle.Text.Length>300 OrElse String.IsNullOrWhiteSpace(txtDetails.Text) OrElse txtDetails.Text.Length>10000 OrElse String.IsNullOrWhiteSpace(txtMobile.Text) OrElse txtMobile.Text.Length>30 Then Throw New ArgumentException("أكمل العنوان (حتى 300 حرف) ورقم التواصل والتفاصيل (حتى 10000 حرف).")
   Dim items As New List(Of FileAttribute)
   For Each upload As System.Web.HttpPostedFile In uploads.PostedFiles
    If upload.ContentLength=0 Then Continue For
    If upload.ContentLength>EmployeeFeedbackData.MaxFileBytes Then Throw New ArgumentException("حجم الملف يتجاوز 10 ميجابايت.")
    If items.Count>=EmployeeFeedbackData.MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
    Using stream As New MemoryStream()
     upload.InputStream.CopyTo(stream) : items.Add(New FileAttribute With {.NameFile=upload.FileName,.FileByte=stream.ToArray()})
    End Using
   Next
   Dim files=EmployeeFeedbackData.SaveQueuedAttachments(items,saved)
   databaseAttempted=True
   Dim result=CustomerPortalData.CustomerQuery("dbo.Customer_SubmitFeedback",CustomerPortalData.P("@OperationID",SqlDbType.UniqueIdentifier,ViewState("Operation")),CustomerPortalData.P("@Type",SqlDbType.Int,Number(ddlType)),CustomerPortalData.P("@Topic",SqlDbType.Int,Number(ddlTopic)),CustomerPortalData.P("@Brand",SqlDbType.Int,Number(ddlBrand)),CustomerPortalData.P("@Branch",SqlDbType.Int,Number(ddlBranch)),CustomerPortalData.P("@Mobile",SqlDbType.NVarChar,txtMobile.Text.Trim(),30),CustomerPortalData.P("@Title",SqlDbType.NVarChar,txtTitle.Text.Trim(),300),CustomerPortalData.P("@Details",SqlDbType.NVarChar,txtDetails.Text.Trim(),-1),CustomerPortalData.P("@Files",SqlDbType.Xml,files.ToString()))
   If result.Columns.Contains("Replay") AndAlso CBool(result.Rows(0)("Replay")) Then
    For Each path In saved : If File.Exists(path) Then File.Delete(path)
    Next
   End If
   saved.Clear() : ViewState("Operation")=Guid.NewGuid() : txtTitle.Text="" : txtDetails.Text=""
   KeepWizardOpen=False : customerFeedbackWorkspace.Attributes("data-feedback-saved")="1"
   customerFeedbackWorkspace.Attributes("data-feedback-saved-id")=CInt(result.Rows(0)("ID")).ToString()
   litMessage.Text="<div class=""alert alert-success alert-dismissible"" role=""status"">تم إرسال الطلب رقم " & CInt(result.Rows(0)("ID")).ToString() & " إلى مدير النظام.<button type=""button"" class=""btn-close"" data-bs-dismiss=""alert"" aria-label=""إغلاق""></button></div>"
   BindHistory()
  Catch ex As Exception
   Dim sql=TryCast(ex,System.Data.SqlClient.SqlException)
   If Not databaseAttempted OrElse TypeOf ex Is ArgumentException OrElse (sql IsNot Nothing AndAlso {51910,51911,51500}.Contains(sql.Number)) Then
    For Each path In saved
     If File.Exists(path) Then File.Delete(path)
    Next
   End If
   'An uncertain outcome may have committed. Retrying the same operation is safe.
   litWizardMessage.Text="<div class=""alert alert-danger"" role=""alert"">" & Server.HtmlEncode(CustomerPortalData.ErrorText(ex)) & "</div>"
  End Try
 End Sub
End Class


