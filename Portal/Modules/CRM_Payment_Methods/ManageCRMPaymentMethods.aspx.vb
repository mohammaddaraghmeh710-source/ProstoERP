Public Class ManageCRMPaymentMethods
    Inherits CRMCatalogManagePage
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Payment_Methods"
        End Get
    End Property
    Protected Overrides ReadOnly Property RecordTitle As String
        Get
            Return "طريقة الدفع"
        End Get
    End Property
    Protected Overrides ReadOnly Property NewRecordTitle As String
        Get
            Return "طريقة دفع"
        End Get
    End Property
End Class
