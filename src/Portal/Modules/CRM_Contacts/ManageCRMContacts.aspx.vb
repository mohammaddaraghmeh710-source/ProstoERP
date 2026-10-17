Public Class ManageCRMContacts
    Inherits CRMModulePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Contacts"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property
End Class
