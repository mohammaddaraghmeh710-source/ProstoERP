Option Strict On
Option Explicit On
Partial Public Class ManageInformationPages
    Public Shadows ReadOnly Property Master() As CRM.Site
        Get
            Return CType(MyBase.Master, CRM.Site)
        End Get
    End Property
End Class
