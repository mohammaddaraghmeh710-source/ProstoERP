Imports System.Data.SqlClient

Public NotInheritable Class CustomerPortalPresentation
    Public Shared Function ErrorText(ex As Exception) As String
        Trace.TraceError("Customer portal: {0}", ex.GetType().Name)
        Dim sql = TryCast(ex, SqlException)
        If _
            sql IsNot Nothing AndAlso
            ({51910, 51911, 51912, 51500}.Contains(sql.Number) OrElse (sql.Number >= 51100 AndAlso sql.Number <= 51109)) _
            Then Return sql.Message
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Return "تعذر تنفيذ العملية. يرجى المحاولة مرة أخرى."
    End Function

    Public Shared Sub BindOptions(list As DropDownList, rows As DataTable,
                                  Optional hint As String = "اختر")
        list.Items.Clear()
        list.Items.Add(New ListItem(hint, "0"))
        For Each row As DataRow In rows.Rows
            list.Items.Add(New ListItem(CStr(row("Title")), CStr(row("ID"))))
        Next
    End Sub
End Class


