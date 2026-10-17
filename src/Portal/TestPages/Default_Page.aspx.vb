Public Class Default_Page
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If SessionManager.GetInstance.Users Is Nothing Then
                'Response.Redirect("/login.aspx")

            End If
        End If
    End Sub

End Class