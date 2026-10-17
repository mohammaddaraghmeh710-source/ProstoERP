Public Class EditCRMPaymentMethods
    Inherits CRMModulePage

    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Payment_Methods"
        End Get
    End Property

    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Edit"
        End Get
    End Property
End Class


