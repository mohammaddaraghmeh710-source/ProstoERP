Public Class CustomerMaster
 Inherits System.Web.UI.MasterPage
 Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
  If CustomerPortalData.Current IsNot Nothing Then litCustomer.Text=Server.HtmlEncode(CustomerPortalData.Current.Name)
 End Sub
 Protected Sub Logout_Click(sender As Object,e As EventArgs)
  Session.Clear() : Session.Abandon() : Response.Redirect("/Login.aspx?kind=customer")
 End Sub
End Class
