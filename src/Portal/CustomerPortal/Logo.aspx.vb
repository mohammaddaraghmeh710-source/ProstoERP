Imports System.Data
Imports System.Web
Imports System.Web.UI

Public Class CustomerLogo
    Inherits CustomerPortalPage

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        If CustomerPortalData.Current Is Nothing Then Return
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        If Request.HttpMethod <> "GET" Then
            Response.StatusCode = 405
            Return
        End If
        Dim rows = CustomerPortalData.CustomerQuery("dbo.Customer_Dashboard", CustomerPortalData.P("@Section", SqlDbType.VarChar, "logo", 16))
        Dim bytes = If(rows.Rows.Count = 0, Nothing, CRMAccountLogo.ReadFile(Convert.ToString(rows.Rows(0)("Logo_Url"))))
        If bytes Is Nothing Then
            Response.Redirect(CRMAccountLogo.DefaultUrl, False)
        Else
            Response.ContentType = "image/png"
            Response.BinaryWrite(bytes)
        End If
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        ' Image responses must not include page markup.
    End Sub
End Class
