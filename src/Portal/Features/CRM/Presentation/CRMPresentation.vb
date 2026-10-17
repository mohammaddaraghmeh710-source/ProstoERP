Imports System.Data.SqlClient
Imports System.Globalization

Public NotInheritable Class CRMPresentation
    Public Shared Function H(value As Object) As String
        Return HttpUtility.HtmlEncode(Convert.ToString(value, CultureInfo.InvariantCulture))
    End Function

    Public Shared Function Link(entity As String, Optional mode As String = "Manage", Optional id As Integer = 0) _
        As String
        Dim page = mode & "CRM" & entity.Replace("_", "") & ".aspx"
        Return _
            "/Modules/CRM_" & entity & "/" & page & If(id = 0, "", "?id=" & id.ToString(CultureInfo.InvariantCulture))
    End Function

    Public Shared Function ErrorMessage(ex As Exception) As String
        Trace.TraceError("CRM: {0}", ex.ToString())
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing Then
            If sql.Number = 51200 OrElse sql.Number = 51201 Then Return sql.Message
            If sql.Number = 2601 OrElse sql.Number = 2627 Then Return "الاسم أو رقم تسجيل العميل مستخدم مسبقًا."
        End If
        If TypeOf ex Is InvalidOperationException Then Return ex.Message
        Return "تعذّر تنفيذ العملية. أعد المحاولة أو راجع مدير النظام."
    End Function
End Class


