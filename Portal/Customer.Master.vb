Public Class CustomerMaster
 Inherits System.Web.UI.MasterPage
 Protected Overrides Sub OnPreRender(e As EventArgs)
  If CustomerPortalData.Current IsNot Nothing Then litCustomer.Text=CustomerPortalData.Current.Name
  If CustomerPortalData.Current IsNot Nothing Then
   Try
    Dim pages = CustomerPortalData.CustomerQuery("dbo.Customer_InformationPages")
    Dim menu As New System.Text.StringBuilder()
    menu.Append("<li class=""menu-item customer-information-menu""><a href=""javascript:void(0)"" class=""menu-link menu-toggle""><i class=""menu-icon tf-icons bx bx-file"" aria-hidden=""true""></i><div>الصفحات المعلوماتية</div></a><ul class=""menu-sub"">")
    For Each row As System.Data.DataRow In pages.Rows
     menu.Append("<li class=""menu-item""><a class=""menu-link"" href=""/CustomerPortal/InformationPage.aspx?id=").Append(CInt(row("ID"))).Append("""><div>").Append(Server.HtmlEncode(Convert.ToString(row("Title_Ar")))).Append("</div></a></li>")
    Next
    If pages.Rows.Count = 0 Then menu.Append("<li class=""menu-item""><span class=""menu-link text-muted"">لا توجد صفحات متاحة</span></li>")
    menu.Append("</ul>")
    litInformationNavigation.Text = menu.Append("</li>").ToString()
   Catch ex As Exception
    litInformationNavigation.Text = ""
    System.Diagnostics.Trace.TraceError("Customer information navigation: {0}", ex.GetType().Name)
   End Try
  End If
  MyBase.OnPreRender(e)
 End Sub
 Protected Sub Logout_Click(sender As Object,e As EventArgs)
  If CustomerPortalData.Current IsNot Nothing Then
   CustomerPortalData.CustomerQuery("dbo.Customer_LogActivity",CustomerPortalData.P("@Action",System.Data.SqlDbType.VarChar,"logout",30))
  End If
  Session.Clear() : Session.Abandon() : Response.Redirect("/Login.aspx?kind=customer")
 End Sub
End Class
