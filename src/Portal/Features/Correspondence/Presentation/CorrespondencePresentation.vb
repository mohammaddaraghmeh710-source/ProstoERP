Imports System.Data.SqlClient
Imports System.IO

Public NotInheritable Class CorrespondencePresentation
    Public Shared Function KindText(value As Object) As String
        Return If(value IsNot Nothing AndAlso Not IsDBNull(value) AndAlso CBool(value), "تكليف", "مراسلة عادية")
    End Function

    Public Shared Function StateText(value As Object) As String
        Select Case Convert.ToString(value)
            Case "archived" : Return "مؤرشفة إداريًا"
            Case "closed" : Return "منتهية"
            Case "overdue" : Return "متأخرة"
            Case Else : Return "فعالة"
        End Select
    End Function

    Public Shared Function StateCss(value As Object) As String
        Select Case Convert.ToString(value)
            Case "archived" : Return "bg-label-secondary"
            Case "closed" : Return "bg-label-info"
            Case "overdue" : Return "bg-label-danger"
            Case Else : Return "bg-label-success"
        End Select
    End Function

    Public Shared Function StatusText(due As Object, closed As Object) As String
        Select Case CorrespondenceData.StatusValue(due, closed)
            Case CorrespondenceStatus.Closed : Return "منتهية"
            Case CorrespondenceStatus.Overdue : Return "متأخرة"
            Case Else : Return "فعالة"
        End Select
    End Function

    Public Shared Function StatusCss(due As Object, closed As Object) As String
        Return _
            If _
                (CorrespondenceData.StatusValue(due, closed) = CorrespondenceStatus.Active, "bg-label-success",
                 "bg-label-danger")
    End Function

    Public Shared Function DisplayDate(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return _
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(CDate(value), DateTimeKind.Utc),
                                            TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString(
                                                "yyyy/MM/dd HH:mm")
    End Function

    Public Shared Function MessageHtml(value As Object) As String
        Return HttpUtility.HtmlEncode(Convert.ToString(value)).Replace(vbCrLf, vbLf).Replace(vbLf, "<br />")
    End Function

    Public Shared Function Utc(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return ""
        Return CDate(value).ToString("yyyy-MM-ddTHH:mm:ss.fff") & "Z"
    End Function

    Public Shared Function Avatar(value As Object) As String
        Dim url = Convert.ToString(value)
        If url.StartsWith("FileManager/", StringComparison.OrdinalIgnoreCase) Then url = "/" & url
        If url.StartsWith("/") AndAlso Not url.StartsWith("//") Then Return url
        Return "/assets/img/Prosto/avatar-male.png"
    End Function

    Public Shared Function FileUrl(value As Object) As String
        Return "/FileManager/Correspondence/" & HttpUtility.UrlPathEncode(Path.GetFileName(Convert.ToString(value)))
    End Function

    Public Shared Function ErrorText(ex As Exception) As String
        Trace.TraceError("Correspondence: {0}", ex)
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing AndAlso sql.Number = 51400 Then Return sql.Message
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Return "تعذّر تنفيذ العملية. يرجى المحاولة مجددًا."
    End Function

    Public Shared Sub FillCatalog(list As DropDownList, actor As Integer, kind As String,
                                  Optional mode As Integer = 0, Optional task As Boolean = True)
        list.Items.Clear()
        list.Items.Add(New ListItem(If(mode = 1, "جميع الأولويات", "اختر من الخيارات الفعالة"),
                                    "0"))
        For Each row As DataRow In CorrespondenceData.Catalog(actor, kind, mode, task).Rows
            list.Items.Add(
                New ListItem(CStr(row("Title")) & If(CBool(row("IsActive")), "", " (موقوف)"),
                             CStr(row("ID"))))
        Next
        If mode = 0 AndAlso list.Items.Count = 1 Then list.Items(0).Text = "لا توجد خيارات فعالة؛ راجع مدير النظام"
    End Sub
End Class


