Imports System.Data

Public Class CustomerFeedbackDetail
 Inherits CustomerPortalPage
 Private actionFiles As DataTable
 Private Function ReadSection(id As Integer,section As String) As DataTable
  Return CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackDetail",CustomerPortalData.P("@ID",SqlDbType.Int,id),CustomerPortalData.P("@Section",SqlDbType.VarChar,section,16))
 End Function
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  Dim id As Integer
  If Not Integer.TryParse(Request.QueryString("id"),id) OrElse id<=0 Then Throw New System.Web.HttpException(404,"الطلب غير متاح")
  Try
   'Every section verifies the authenticated customer's exact request ownership.
   'Only this detail open acknowledges customer notifications.
   Dim rows=ReadSection(id,"detail"),row=rows.Rows(0)
   litID.Text=CInt(row("ID")).ToString() : litTitle.Text=Convert.ToString(row("Title"))
   lblSource.Text="عميل" : lblType.Text=Server.HtmlEncode(Convert.ToString(row("TypeName")))
   lblStatus.Text=EmployeeFeedbackData.StatusText(row("Status")) : lblStatus.CssClass=EmployeeFeedbackData.StatusCss(row("Status"))
   litDetails.Text=CorrespondenceData.MessageHtml(row("Details"))
   litMeta.Text=FeedbackPresentation.RequestField("الموضوع",row("Topic_Title_Ar")) & FeedbackPresentation.RequestField("تاريخ التقديم",CorrespondenceData.DisplayDate(row("AddedDate")))
   If Not IsDBNull(row("CloseDate")) Then litMeta.Text &= FeedbackPresentation.RequestField("تاريخ الإغلاق",CorrespondenceData.DisplayDate(row("CloseDate")))
   litContact.Text=FeedbackPresentation.Contact(New FeedbackApplicant With {.SourceType=2,.CanViewContact=True,.ApplicantName=Convert.ToString(row("ApplicantName")),.ApplicantMobile=Convert.ToString(row("ApplicantMobile")),.ApplicantEmail=Convert.ToString(row("ApplicantEmail")),.BrandName=Convert.ToString(row("Brand_Title_Ar")),.BranchName=Convert.ToString(row("Branch_Title_Ar"))},True)
   Dim files=ReadSection(id,"attachments")
   actionFiles=ReadSection(id,"actionfiles")
   files.Merge(actionFiles,False,MissingSchemaAction.Add)
   attachments.DataSource=files : attachments.DataBind() : lblNoFiles.Visible=files.Rows.Count=0
   workflow.DataSource=ReadSection(id,"workflow") : workflow.DataBind()
  Catch ex As System.Data.SqlClient.SqlException
   If ex.Number=51912 Then Throw New System.Web.HttpException(404,"الطلب غير متاح")
   Throw
  End Try
 End Sub
 Protected Function CanPreview(fileType As Object) As Boolean
  Return {"pdf","jpg","jpeg","png","gif"}.Contains(Convert.ToString(fileType).TrimStart("."c).ToLowerInvariant())
 End Function
 Protected Function FilesFor(group As Object) As DataView
  Dim selected=If(actionFiles Is Nothing,New DataTable(),actionFiles.Clone()),groupID=CType(group,Guid)
  If actionFiles IsNot Nothing Then
   For Each row As DataRow In actionFiles.Rows
    If Not IsDBNull(row("GroupID")) AndAlso CType(row("GroupID"),Guid)=groupID Then selected.ImportRow(row)
   Next
  End If
  'A DataView enumerates DataRowView, whose column properties support ASP.NET Eval.
  Return selected.DefaultView
 End Function
End Class
