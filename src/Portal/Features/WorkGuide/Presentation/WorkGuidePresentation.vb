Imports System.Data.SqlClient

Public NotInheritable Class WorkGuidePresentation
    Public Shared Function StatusCss(value As Object) As String
        Select Case Convert.ToString(value)
            Case "A" : Return "badge wg-status wg-status-approved"
            Case "R" : Return "badge wg-status wg-status-rejected"
            Case Else : Return "badge wg-status wg-status-pending"
        End Select
    End Function

    Public Shared Function StatusText(value As Object) As String
        Select Case Convert.ToString(value)
            Case "A" : Return "تمت الموافقة"
            Case "R" : Return "مرفوض"
            Case Else : Return "بانتظار المراجعة"
        End Select
    End Function

    Public Shared Function ErrorText(ex As SqlException) As String
        Trace.TraceError("Work guide access: {0}", ex.ToString())
        If ex.Number >= 51100 AndAlso ex.Number <= 51109 Then Return ex.Message
        If ex.Number = 2601 OrElse ex.Number = 2627 Then Return "يوجد طلب معلّق لأحد التصنيفات المحددة. حدّث الصفحة."
        Return "تعذّر تنفيذ العملية. يرجى المحاولة مرة أخرى."
    End Function
End Class


