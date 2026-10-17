Imports System.Data
Public Class CustomerFeedbackDetail
 Inherits CustomerPortalPage
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  Dim id As Integer
  If Not Integer.TryParse(Request.QueryString("id"),id) OrElse id<=0 Then Throw New System.Web.HttpException(404,"الطلب غير متاح")
  Try
   Dim rows=CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackDetail",CustomerPortalData.P("@ID",SqlDbType.Int,id))
   detail.DataSource=rows : detail.DataBind()
   Dim files=CustomerPortalData.CustomerQuery("dbo.Customer_FeedbackDetail",CustomerPortalData.P("@ID",SqlDbType.Int,id),CustomerPortalData.P("@Section",SqlDbType.VarChar,"attachments",16))
   attachments.DataSource=files : attachments.DataBind()
   empty.Text=If(files.Rows.Count=0,"لا توجد مرفقات لهذا الطلب.","")
  Catch ex As System.Data.SqlClient.SqlException
   If ex.Number=51912 Then Throw New System.Web.HttpException(404,"الطلب غير متاح")
   Throw
  End Try
 End Sub
End Class
