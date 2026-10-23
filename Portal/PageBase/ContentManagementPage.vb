Public MustInherit Class ContentManagementPage
    Inherits InformationPagesPage
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e) : RequireAdmin()
        ContentManagementData.RequireAdmin(Actor)
        If Session("ContentManagementCSRF") Is Nothing Then Session("ContentManagementCSRF") = Guid.NewGuid().ToString("N") & Guid.NewGuid().ToString("N")
    End Sub
End Class
