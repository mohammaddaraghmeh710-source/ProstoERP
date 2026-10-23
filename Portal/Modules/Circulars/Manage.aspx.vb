Public Class CircularsManage
 Inherits CircularsPage
 Protected Overrides Sub OnInit(e As EventArgs)
  MyBase.OnInit(e) : RequireAdmin()
  ContentManagementData.RequireAdmin(Actor)
 End Sub
 Public ReadOnly Property FormToken As String
  Get
   Return CsrfToken
  End Get
 End Property
End Class
