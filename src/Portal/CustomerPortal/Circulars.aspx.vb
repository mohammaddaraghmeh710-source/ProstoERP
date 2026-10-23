Imports System
Public Class CustomerCirculars
    Inherits CustomerPortalPage
    Protected WithEvents litMessage As System.Web.UI.WebControls.Literal

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Dim id As Integer
        Dim raw = Request.Unvalidated.QueryString("ID")
        If raw IsNot Nothing AndAlso (Not Integer.TryParse(raw, id) OrElse id <= 0) Then
            Response.StatusCode = 400
            Response.TrySkipIisCustomErrors = True
            litMessage.Text = "<div class='alert alert-warning' role='alert'>رقم التعميم غير صحيح.</div>"
            Return
        End If
        ' Compatibility only: current authorization and file access occur in the dashboard reader.
        Response.Redirect("Dashboard.aspx" & If(id > 0, "?circular=" & id.ToString(System.Globalization.CultureInfo.InvariantCulture), "") & "#customerCirculars", False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
