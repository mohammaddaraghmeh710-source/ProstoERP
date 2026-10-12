Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Web
Imports System.Xml
Imports System.Xml.Linq
Imports System.Linq
Imports System.Text.RegularExpressions

Public NotInheritable Class InformationPagesData
    Public Shared Function Query(procedure As String, ParamArray parameters As SqlParameter()) As DataTable
        Using cn As New SqlConnection(Global.System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString), cmd As New SqlCommand(procedure, cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddRange(parameters)
            Dim result As New DataTable()
            cn.Open()
            Using reader = cmd.ExecuteReader()
                result.Load(reader)
            End Using
            Return result
        End Using
    End Function

    Public Shared Function P(name As String, kind As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Dim parameter As New SqlParameter(name, kind)
        If size <> 0 Then parameter.Size = size
        parameter.Value = If(value, DBNull.Value)
        Return parameter
    End Function

    Public Shared Function LocalDate(value As Object, Optional input As Boolean = False) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return If(input, "", "—")
        Dim utc = DateTime.SpecifyKind(CDate(value), DateTimeKind.Utc)
        Return TimeZoneInfo.ConvertTimeFromUtc(utc, TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString(If(input, "yyyy-MM-ddTHH:mm", "yyyy/MM/dd HH:mm"), CultureInfo.InvariantCulture)
    End Function

    Public Shared Function ParseDate(value As String) As DateTime
        Dim local As DateTime
        If Not DateTime.TryParseExact(value, "yyyy-MM-ddTHH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, local) Then Throw New ArgumentException("أدخل تاريخ البداية والنهاية مع الوقت.")
        Return TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(local, DateTimeKind.Unspecified), TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time"))
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

    Public Shared Function RequiredText(value As String, maximum As Integer, label As String) As String
        value = If(value, "").Trim()
        If value.Length = 0 OrElse value.Length > maximum Then Throw New ArgumentException(label & ": مطلوب، والحد الأقصى " & maximum.ToString() & " حرف.")
        Return value
    End Function

    ' CKEditor emits XHTML. Parse it without DTD/entity resolution, then rebuild a small allowlist.
    ' No raw attribute or tag from the source is copied into the returned HTML.
    Public Shared Function CleanHtml(value As String) As String
        value = RequiredText(value, 100000, "التفاصيل")
        value = Regex.Replace(value, "&(?:#[0-9]+|#x[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]+);", Function(m) HttpUtility.HtmlEncode(HttpUtility.HtmlDecode(m.Value)))
        value = Regex.Replace(value, "<(br|hr)\s*/?>", "<$1 />", RegexOptions.IgnoreCase)
        Dim settings As New XmlReaderSettings With {.DtdProcessing = DtdProcessing.Prohibit, .XmlResolver = Nothing, .MaxCharactersInDocument = 150000}
        Try
            Using input As New IO.StringReader("<root>" & value & "</root>"), reader = XmlReader.Create(input, settings)
                Dim root = XElement.Load(reader, LoadOptions.PreserveWhitespace)
                Dim result = String.Concat(root.Nodes().Select(Function(node) RenderNode(node, 0)))
                Dim text = HttpUtility.HtmlDecode(Regex.Replace(result, "<[^>]*>", ""))
                If String.IsNullOrWhiteSpace(text) Then Throw New ArgumentException("أدخل نص التفاصيل باللغتين.")
                Return result
            End Using
        Catch ex As XmlException
            Throw New ArgumentException("تنسيق التفاصيل غير صالح. أعد لصق النص داخل المحرر باستخدام لصق كنص عادي.")
        End Try
    End Function

    Private Shared Function RenderNode(node As XNode, depth As Integer) As String
        If depth > 40 Then Throw New ArgumentException("تنسيق التفاصيل متداخل أكثر من المسموح.")
        Dim text = TryCast(node, XText)
        If text IsNot Nothing Then Return HttpUtility.HtmlEncode(text.Value)
        Dim element = TryCast(node, XElement)
        If element Is Nothing Then Return ""
        Dim tag = element.Name.LocalName.ToLowerInvariant()
        If element.Name.NamespaceName <> "" OrElse {"script", "style", "iframe", "object", "embed", "svg", "math", "form", "input", "img"}.Contains(tag) Then Return ""
        Dim children = String.Concat(element.Nodes().Select(Function(child) RenderNode(child, depth + 1)))
        If Not {"p", "div", "span", "br", "hr", "strong", "b", "em", "i", "u", "s", "sub", "sup", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li", "blockquote", "pre", "code", "a", "table", "thead", "tbody", "tfoot", "tr", "th", "td", "caption"}.Contains(tag) Then Return children
        Dim attributes As New Text.StringBuilder()
        For Each attr In element.Attributes()
            If attr.Name.NamespaceName <> "" Then Continue For
            Dim name = attr.Name.LocalName.ToLowerInvariant(), value = attr.Value
            Dim allowed As Boolean = False
            If name = "dir" Then allowed = {"rtl", "ltr", "auto"}.Contains(value)
            If name = "title" Then allowed = True
            If (tag = "td" OrElse tag = "th") AndAlso (name = "colspan" OrElse name = "rowspan") Then
                Dim number As Integer
                allowed = Integer.TryParse(value, number) AndAlso number > 0 AndAlso number <= 50
            End If
            If name = "style" Then
                Dim styles As New List(Of String)()
                For Each declaration In value.Split(";"c)
                    Dim parts = declaration.Split(":"c)
                    If parts.Length <> 2 Then Continue For
                    Dim key = parts(0).Trim().ToLowerInvariant(), setting = parts(1).Trim().ToLowerInvariant()
                    If (key = "text-align" AndAlso {"left", "right", "center", "justify"}.Contains(setting)) OrElse
                       (key = "direction" AndAlso {"rtl", "ltr"}.Contains(setting)) Then styles.Add(key & ":" & setting)
                Next
                value = String.Join(";", styles) : allowed = value.Length > 0
            End If
            If tag = "a" AndAlso name = "href" Then
                Dim uri As Uri = Nothing
                allowed = Not value.Any(Function(c) Char.IsControl(c)) AndAlso Not value.Contains("\") AndAlso
                    ((value.StartsWith("/") AndAlso Not value.StartsWith("//")) OrElse value.StartsWith("#") OrElse
                    (Uri.TryCreate(value, UriKind.Absolute, uri) AndAlso {"http", "https", "mailto"}.Contains(uri.Scheme)))
            End If
            If allowed Then attributes.Append(" " & name & "=""" & HttpUtility.HtmlAttributeEncode(value) & """")
        Next
        If tag = "br" OrElse tag = "hr" Then Return "<" & tag & " />"
        Return "<" & tag & attributes.ToString() & ">" & children & "</" & tag & ">"
    End Function
End Class
