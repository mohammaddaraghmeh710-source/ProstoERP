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
        Return HttpUtility.HtmlEncode(Convert.ToString(value, CultureInfo.InvariantCulture))
    End Function

    Public Shared Function Link(entity As String, Optional mode As String = "Manage", Optional id As Integer = 0) As String
        Dim page = mode & "CRM" & entity.Replace("_", "") & ".aspx"
        Return "/Modules/CRM_" & entity & "/" & page & If(id = 0, "", "?id=" & id.ToString(CultureInfo.InvariantCulture))
    End Function

    Public Shared Function ErrorMessage(ex As Exception) As String
        System.Diagnostics.Trace.TraceError("CRM: {0}", ex.ToString())
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing Then
            If sql.Number = 51200 OrElse sql.Number = 51201 Then Return sql.Message
            If sql.Number = 2601 OrElse sql.Number = 2627 Then Return "الاسم أو رقم تسجيل العميل مستخدم مسبقًا."
        End If
        If TypeOf ex Is InvalidOperationException Then Return ex.Message
        Return "تعذّر تنفيذ العملية. أعد المحاولة أو راجع مدير النظام."
    End Function
End Class

Public Class CRMField
    Public Property Name As String
    Public Property Label As String
    Public Property Kind As String
    Public Property MaxLength As Integer
    Public Sub New(name As String, label As String, kind As String, length As Integer)
        Me.Name = name : Me.Label = label : Me.Kind = kind : Me.MaxLength = length
    End Sub
End Class

Public Class CRMDefinition
    Public Property Title As String
    Public Property Fields As List(Of CRMField)
    Public Sub New(title As String, fields As CRMField())
        Me.Title = title : Me.Fields = New List(Of CRMField)(fields)
    End Sub
End Class
