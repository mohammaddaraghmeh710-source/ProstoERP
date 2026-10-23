Public Class ManageCRMAccountTypes
    Inherits CRMCatalogManagePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Account_Types"
        End Get
    End Property
    Protected Overrides ReadOnly Property RecordTitle As String
        Get
            Return "نوع العميل"
        End Get
    End Property
    Protected Overrides ReadOnly Property NewRecordTitle As String
        Get
            Return "نوع عميل"
        End Get
    End Property
End Class
