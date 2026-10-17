Public Class EditCRMContractTypes
    Inherits CRMModulePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Contract_Types"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Edit"
        End Get
    End Property
End Class
