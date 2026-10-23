Public Class ManageCRMContractTypes
    Inherits CRMCatalogManagePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Contract_Types"
        End Get
    End Property
    Protected Overrides ReadOnly Property RecordTitle As String
        Get
            Return "نوع العقد"
        End Get
    End Property
    Protected Overrides ReadOnly Property NewRecordTitle As String
        Get
            Return "نوع عقد"
        End Get
    End Property
End Class
