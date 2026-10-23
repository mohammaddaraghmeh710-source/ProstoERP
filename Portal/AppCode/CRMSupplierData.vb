Imports System.Data

' Tool suppliers and portal content share the account's canonical brand memberships.
Public NotInheritable Class CRMSupplierData
    Public Shared Function TypeID(actor As Integer) As Integer
        Dim rows = CRMData.Query("dbo.CRM_Supplier_Type", CRMData.P("@Actor_ID", SqlDbType.Int, actor))
        Return If(rows.Rows.Count = 0, 0, CInt(rows.Rows(0)("ID")))
    End Function

    Public Shared Function Brands(actor As Integer, accountId As Integer) As DataTable
        Return CRMData.Query("dbo.CRM_Supplier_Brand_Options", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Account_ID", SqlDbType.Int, accountId))
    End Function

    Public Shared Function Options(actor As Integer, Optional currentAccountId As Integer? = Nothing, Optional includeUnavailable As Boolean = False) As DataTable
        Return CRMData.Query("dbo.CRM_Supplier_Options", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Current_Account_ID", SqlDbType.Int, currentAccountId), CRMData.P("@Include_Unavailable", SqlDbType.Bit, includeUnavailable))
    End Function

    Public Shared Function IsAvailableForBrand(actor As Integer, accountId As Integer, brandId As Integer, Optional currentAccountId As Integer? = Nothing) As Boolean
        For Each row As DataRow In Options(actor, currentAccountId).Rows
            If CInt(row("ID")) <> accountId Then Continue For
            Dim historical = currentAccountId.HasValue AndAlso currentAccountId.Value = accountId
            If Not CBool(row("Is_Available")) AndAlso Not historical Then Return False
            Return ("," & Convert.ToString(row("Brand_IDs")) & ",").Contains("," & brandId.ToString(Globalization.CultureInfo.InvariantCulture) & ",")
        Next
        Return False
    End Function
End Class
