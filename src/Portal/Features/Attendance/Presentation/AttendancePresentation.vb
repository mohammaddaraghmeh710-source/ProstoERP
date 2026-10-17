Imports System.Globalization

Public NotInheritable Class AttendancePresentation
    Public Shared Function Today() As String
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function

    Public Shared Function ErrorText(ex As Exception) As String
        System.Diagnostics.Trace.TraceWarning("Portal attendance failed ({0}).", ex.GetType().Name)
        If TypeOf ex Is AttendanceDisplayException Then Return ex.Message
        Return "تعذّر تحميل بيانات الدوام. يرجى المحاولة لاحقًا أو مراجعة مدير النظام."
    End Function

    Friend Shared Function State(value As String) As String
        Select Case value
            Case "0" : Return "دخول"
            Case "1" : Return "خروج"
            Case "2" : Return "بداية استراحة"
            Case "3" : Return "نهاية استراحة"
            Case "4" : Return "دخول إضافي"
            Case "5" : Return "خروج إضافي"
            Case Else : Return value
        End Select
    End Function
End Class
