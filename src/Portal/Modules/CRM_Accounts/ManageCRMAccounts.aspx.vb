Public Class ManageCRMAccounts
    Inherits CRMModulePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Accounts"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property
End Class
