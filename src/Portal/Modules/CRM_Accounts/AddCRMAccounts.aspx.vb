Public Class AddCRMAccounts
    Inherits CRMModulePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Accounts"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Add"
        End Get
    End Property
End Class
