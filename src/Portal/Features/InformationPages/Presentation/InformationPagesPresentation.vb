Imports System.Globalization

Public NotInheritable Class InformationPagesPresentation
    Public Shared Function LocalDate(value As Object, Optional input As Boolean = False) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return If(input, "", "—")
        Dim utc = DateTime.SpecifyKind(CDate(value), DateTimeKind.Utc)
        Return _
            TimeZoneInfo.ConvertTimeFromUtc(utc, TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString(
                If(input, "yyyy-MM-ddTHH:mm", "yyyy/MM/dd HH:mm"), CultureInfo.InvariantCulture)
    End Function

    Public Shared Function StatusText(value As Object) As String
        Select Case Convert.ToString(value)
            Case "draft" : Return "مسودة"
            Case "scheduled" : Return "مجدولة"
            Case "expired" : Return "منتهية"
            Case "deleted" : Return "محذوفة"
            Case Else : Return "منشورة"
        End Select
    End Function

    Public Shared Function ActionText(value As Object) As String
        Select Case Convert.ToString(value)
            Case "create" : Return "إنشاء"
            Case "update" : Return "تعديل"
            Case "delete" : Return "حذف منطقي"
            Case "view" : Return "زيارة"
            Case "preview" : Return "معاينة مدير النظام"
            Case "access" : Return "تعديل صلاحيات الاطلاع"
            Case "restore" : Return "استرجاع إصدار سابق"
            Case Else : Return ""
        End Select
    End Function
End Class


