Imports System.Data.SqlClient
Imports System.IO
Imports System.IO.Compression
Imports System.Web
Imports System.Xml.Linq
Imports System.Linq

Public Enum CorrespondenceStatus
    Active = 1
    Overdue = 2
    Closed = 3
End Enum

Public NotInheritable Class CorrespondenceData
    Public Shared Function P(name As String, type As System.Data.SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return WorkGuideAccess.Parameter(name, type, value, size)
    End Function
    Public Shared Function Query(procedure As String, ParamArray parameters As SqlParameter()) As System.Data.DataTable
        Return WorkGuideAccess.Query(procedure, parameters)
    End Function
    Public Shared Function ThreadQuery(procedure As String, actor As Integer, thread As Integer) As System.Data.DataTable
        Return Query(procedure, P("@Actor", System.Data.SqlDbType.Int, actor), P("@ThreadID", System.Data.SqlDbType.Int, thread))
    End Function
    Public Shared Function KindText(value As Object) As String
        Return If(value IsNot Nothing AndAlso Not IsDBNull(value) AndAlso CBool(value), "تكليف", "مراسلة عادية")
    End Function
    Public Shared Sub FillCatalog(list As System.Web.UI.WebControls.DropDownList, actor As Integer, kind As String, Optional mode As Integer = 0, Optional task As Boolean = True)
        list.Items.Clear()
        list.Items.Add(New System.Web.UI.WebControls.ListItem(If(mode = 1, "جميع الأولويات", "اختر من الخيارات الفعالة"), "0"))
        For Each row As System.Data.DataRow In Query("dbo.Correspondence_CatalogList", P("@Actor", System.Data.SqlDbType.Int, actor), P("@Kind", System.Data.SqlDbType.Char, kind, 1), P("@Mode", System.Data.SqlDbType.Int, mode), P("@Task", System.Data.SqlDbType.Bit, task)).Rows
            list.Items.Add(New System.Web.UI.WebControls.ListItem(CStr(row("Title")) & If(CBool(row("IsActive")), "", " (موقوف)"), CStr(row("ID"))))
        Next
        If mode = 0 AndAlso list.Items.Count = 1 Then list.Items(0).Text = "لا توجد خيارات فعالة؛ راجع مدير النظام"
    End Sub
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
    Public Const MaxFiles As Integer = 5
    Public Const MaxFileBytes As Integer = 10 * 1024 * 1024
    Public Shared Function StatusValue(due As Object, closed As Object) As CorrespondenceStatus
        If closed IsNot Nothing AndAlso Not IsDBNull(closed) Then Return CorrespondenceStatus.Closed
        If due IsNot Nothing AndAlso Not IsDBNull(due) AndAlso CDate(due) < DateTime.UtcNow Then Return CorrespondenceStatus.Overdue
        Return CorrespondenceStatus.Active
    End Function
    Public Shared Function StatusText(due As Object, closed As Object) As String
        Select Case StatusValue(due, closed)
            Case CorrespondenceStatus.Closed : Return "منتهية"
            Case CorrespondenceStatus.Overdue : Return "متأخرة"
            Case Else : Return "فعالة"
        End Select
    End Function
    Public Shared Function StatusCss(due As Object, closed As Object) As String
        Return If(StatusValue(due, closed) = CorrespondenceStatus.Active, "bg-label-success", "bg-label-danger")
    End Function
    Public Shared Function DisplayDate(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(CDate(value), DateTimeKind.Utc), TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString("yyyy/MM/dd HH:mm")
    End Function
    Public Shared Function MessageHtml(value As Object) As String
        Return HttpUtility.HtmlEncode(Convert.ToString(value)).Replace(vbCrLf, vbLf).Replace(vbLf, "<br />")
    End Function
    Public Shared Function SaveQueuedAttachments(items As List(Of FileAttribute), saved As List(Of String)) As XElement
        Dim result As New XElement("files")
        If items Is Nothing Then Return result
        If items.Count > MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
        For Each item In items
            SaveFileBytes(item.NameFile, item.FileByte, result, saved)
        Next
        Return result
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
        System.Diagnostics.Trace.TraceError("Correspondence: {0}", ex)
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing AndAlso sql.Number = 51400 Then Return sql.Message
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Return "تعذّر تنفيذ العملية. يرجى المحاولة مجددًا."
    End Function
    Public Shared Function SaveAttachments(uploads As IEnumerable(Of HttpPostedFile), saved As List(Of String)) As XElement
        Dim files As New XElement("files")
        Dim items = uploads.Where(Function(f) f.ContentLength > 0).ToList()
        If items.Count > MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات للرسالة.")
        For Each item In items
            SaveFile(item, files, saved)
        Next
        Return files
    End Function
    Public Shared Sub Cleanup(saved As IEnumerable(Of String))
        For Each path In saved
            Try
                File.Delete(path)
            Catch ex As IOException
                System.Diagnostics.Trace.TraceError("Correspondence file cleanup: {0}", ex)
            End Try
        Next
    End Sub
    Private Shared Sub SaveFile(upload As HttpPostedFile, files As XElement, saved As List(Of String))
        If upload.ContentLength = 0 OrElse upload.ContentLength > MaxFileBytes Then Throw New ArgumentException("حجم كل مرفق يجب ألا يتجاوز 10 ميجابايت، ولا يمكن رفع ملف فارغ.")
        Dim bytes As Byte()
        Using stream As New MemoryStream()
            upload.InputStream.CopyTo(stream) : bytes = stream.ToArray()
        End Using
        SaveFileBytes(upload.FileName, bytes, files, saved)
    End Sub
    Private Shared Sub SaveFileBytes(originalName As String, bytes As Byte(), files As XElement, saved As List(Of String))
        If bytes Is Nothing OrElse bytes.Length=0 OrElse bytes.Length>MaxFileBytes Then Throw New ArgumentException("حجم المرفق غير صحيح؛ الحد الأعلى 10 ميجابايت.")
        Dim extension = Path.GetExtension(originalName).ToLowerInvariant()
        Dim types As New Dictionary(Of String, String) From {{".pdf", "application/pdf"}, {".doc", "application/msword"}, {".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"}, {".xls", "application/vnd.ms-excel"}, {".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}, {".jpg", "image/jpeg"}, {".jpeg", "image/jpeg"}, {".png", "image/png"}, {".gif", "image/gif"}}
        If Not types.ContainsKey(extension) Then Throw New ArgumentException("الملفات المسموحة: PDF وWord وExcel والصور JPG وPNG وGIF.")
        If types(extension).StartsWith("image/") Then
            Using input As New MemoryStream(bytes)
                Using source = System.Drawing.Image.FromStream(input, True, True)
                    If CLng(source.Width) * source.Height > 20000000 Then Throw New ArgumentException("أبعاد الصورة كبيرة جدًا.")
                    Using clean As New System.Drawing.Bitmap(source.Width, source.Height)
                        Using graphics = System.Drawing.Graphics.FromImage(clean)
                            graphics.DrawImage(source, 0, 0, source.Width, source.Height)
                        End Using
                        Using output As New MemoryStream()
                            clean.Save(output, System.Drawing.Imaging.ImageFormat.Png) : bytes = output.ToArray()
                        End Using
                    End Using
                End Using
            End Using
            extension = ".png"
        ElseIf extension = ".pdf" Then
            If bytes.Length < 5 OrElse System.Text.Encoding.ASCII.GetString(bytes, 0, 5) <> "%PDF-" Then Throw New ArgumentException("ملف PDF غير صالح.")
        ElseIf extension = ".docx" OrElse extension = ".xlsx" Then
            Using stream As New MemoryStream(bytes), archive As New ZipArchive(stream, ZipArchiveMode.Read)
                Dim entry = If(extension = ".docx", "word/document.xml", "xl/workbook.xml")
                If archive.GetEntry(entry) Is Nothing OrElse archive.GetEntry("[Content_Types].xml") Is Nothing Then Throw New ArgumentException("ملف Office غير صالح.")
                If archive.Entries.Any(Function(item) item.FullName.EndsWith("vbaProject.bin", StringComparison.OrdinalIgnoreCase)) Then Throw New ArgumentException("ملفات Office التي تحتوي على وحدات ماكرو غير مسموحة.")
            End Using
        Else
            Dim signature As Byte() = {&HD0, &HCF, &H11, &HE0, &HA1, &HB1, &H1A, &HE1}
            If bytes.Length < 8 OrElse Not bytes.Take(8).SequenceEqual(signature) Then Throw New ArgumentException("ملف Office غير صالح.")
        End If
        If bytes.Length > MaxFileBytes Then Throw New ArgumentException("حجم الصورة بعد المعالجة يتجاوز 10 ميجابايت.")
        Dim folder = HttpContext.Current.Server.MapPath("~/FileManager/Correspondence/")
        Directory.CreateDirectory(folder)
        Dim fileName = Guid.NewGuid().ToString("N") & extension
        Dim destination = Path.Combine(folder, fileName)
        saved.Add(destination)
        File.WriteAllBytes(destination, bytes)
        files.Add(New XElement("file", New XAttribute("name", fileName), New XAttribute("type", types(extension)), New XAttribute("size", bytes.LongLength)))
    End Sub
End Class
