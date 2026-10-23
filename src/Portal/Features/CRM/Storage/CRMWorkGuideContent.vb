Imports System.Text.RegularExpressions
Imports System.Web

Public NotInheritable Class CRMWorkGuideContent
    Public Shared Function Clean(value As String) As String
        If String.IsNullOrWhiteSpace(value) OrElse String.IsNullOrWhiteSpace(PlainText(value)) Then Return ""
        Return InformationPagesData.CleanHtml(value)
    End Function

    Public Shared Function PlainText(value As String) As String
        Dim text = Regex.Replace(If(value, ""), "</(?:p|div|h[1-6]|li|tr)>|<br\s*/?>", " ", RegexOptions.IgnoreCase)
        text = HttpUtility.HtmlDecode(Regex.Replace(text, "<[^>]*>", ""))
        Return Regex.Replace(text, "\s+", " ").Trim()
    End Function
End Class
