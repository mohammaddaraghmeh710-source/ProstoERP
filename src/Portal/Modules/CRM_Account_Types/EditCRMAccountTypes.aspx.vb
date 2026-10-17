Public Class EditCRMAccountTypes
    Inherits CRMModulePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Account_Types"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Edit"
        End Get
    End Property
End Class
