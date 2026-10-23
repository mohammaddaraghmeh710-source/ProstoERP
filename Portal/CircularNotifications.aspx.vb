Imports System.Data
Imports System.Web
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization
Public Class CircularNotifications
 Inherits System.Web.UI.Page
 Protected Overrides Sub OnLoad(e As EventArgs)
  MyBase.OnLoad(e) : Response.ContentType="application/json; charset=utf-8" : Response.Cache.SetNoStore() : Response.AddHeader("X-Content-Type-Options","nosniff")
  Try
   If Request.HttpMethod<>"GET" Then Throw New HttpException(405,"استخدم GET.")
   Dim customer=CustomerPortalData.Current IsNot Nothing, rows As DataTable
   If customer Then
    rows=CustomerPortalData.CustomerQuery("dbo.Customer_CircularNotifications")
   Else
    If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401,"سجّل الدخول مجددًا.")
    rows=CircularsData.Query("dbo.Circular_Notifications",CircularsData.P("@Actor",SqlDbType.Int,SessionManager.GetInstance.Users.UserID)).Tables(0)
   End If
   Dim feedback As New DataTable()
   Dim procedure=If(customer,"dbo.Customer_FeedbackNotifications","dbo.Feedback_WorkspaceNotifications")
   If FeedbackInstalled(procedure) Then
    If customer Then
     feedback=CustomerPortalData.CustomerQuery(procedure)
    Else
     feedback=CRMData.Query(procedure,CRMData.P("@Actor",SqlDbType.Int,SessionManager.GetInstance.Users.UserID))
    End If
   End If
   Response.Write((New JavaScriptSerializer()).Serialize(New With {.customer=customer,.rows=ContentManagementData.Records(rows),.feedback=ContentManagementData.Records(feedback)}))
  Catch ex As Exception
   Dim http=TryCast(ex,HttpException),sql=TryCast(ex,SqlException)
   Response.StatusCode=If(http IsNot Nothing,http.GetHttpCode(),If(sql IsNot Nothing AndAlso sql.Number=51911,401,If(sql IsNot Nothing AndAlso (sql.Number=51500 OrElse sql.Number=51801),403,500))) : Response.TrySkipIisCustomErrors=True
   Response.Write("{""rows"":[]}")
  End Try
  Context.ApplicationInstance.CompleteRequest()
 End Sub
 Private Shared Function FeedbackInstalled(procedure As String) As Boolean
  Using cn As New SqlConnection(Global.System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString),cmd As New SqlCommand("SELECT CASE WHEN OBJECT_ID(@Procedure,'P') IS NULL THEN 0 ELSE 1 END",cn)
   cmd.Parameters.AddWithValue("@Procedure",procedure) : cn.Open() : Return CInt(cmd.ExecuteScalar())=1
  End Using
 End Function
 Protected Overrides Sub Render(writer As System.Web.UI.HtmlTextWriter)
 End Sub
End Class
