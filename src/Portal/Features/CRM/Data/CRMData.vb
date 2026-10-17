Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Web
Imports System.Xml.Linq

Public NotInheritable Class CRMData
    Public Shared Function P(name As String, type As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return WorkGuideAccess.Parameter(name, type, value, size)
    End Function

    Public Shared Function Query(procedure As String, ParamArray values As SqlParameter()) As DataTable
        Return WorkGuideAccess.Query(procedure, values)
    End Function

    Public Shared Function Rows(entity As String, actor As Integer, Optional id As Integer = 0) As DataTable
        If Not CRMModel.Entities.ContainsKey(entity) Then Throw New InvalidOperationException("نوع السجل غير صحيح.")
        Return Query("dbo.CRM_Select_" & entity, P("@Actor_ID", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, If(id = 0, CType(Nothing, Object), id)))
    End Function

    Public Shared Function Save(entity As String, actor As Integer, id As Integer, data As XElement, version As Byte()) As DataTable
        If Not CRMModel.Entities.ContainsKey(entity) Then Throw New InvalidOperationException("نوع السجل غير صحيح.")
        Return Query("dbo.CRM_Save_" & entity, P("@Actor_ID", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id), P("@Data", SqlDbType.Xml, data.ToString()), P("@Version", SqlDbType.Binary, version, 8))
    End Function

    Public Shared Function H(value As Object) As String
        Return CRMPresentation.H(value)
    End Function

    Public Shared Function Link(entity As String, Optional mode As String = "Manage", Optional id As Integer = 0) As String
        Return CRMPresentation.Link(entity, mode, id)
    End Function

    Public Shared Function ErrorMessage(ex As Exception) As String
        Return CRMPresentation.ErrorMessage(ex)
    End Function
End Class

