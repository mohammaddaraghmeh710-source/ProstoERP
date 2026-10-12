Imports System.Data.SqlClient
Imports System.IO
Imports System.IO.Compression
Imports System.Web
Imports System.Xml.Linq
Imports System.Linq

Public NotInheritable Class EmployeeFeedbackData
    Public Const MaxFiles As Integer = 5
    Public Const MaxFileBytes As Integer = 10 * 1024 * 1024
    Public Const SubmitAction As Integer = 1
    Public Const TransferAction As Integer = 2
    Public Const CloseAction As Integer = 3
    Public Shared Function LogDate(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(CDate(value),DateTimeKind.Utc),TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString("yyyy/MM/dd HH:mm:ss")
    End Function
    Public Shared Function StatusText(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "جديد"
            Case 2 : Return "قيد المعالجة"
            Case Else : Return "مغلق"
        End Select
    End Function
    Public Shared Function StatusCss(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "badge bg-label-warning"
            Case 2 : Return "badge bg-label-success"
            Case Else : Return "badge bg-label-danger"
        End Select
    End Function
    Public Shared Function ActionText(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "تقديم"
            Case 2 : Return "تحويل"
            Case Else : Return "إغلاق"
        End Select
    End Function
    Public Shared Function TypeText(value As Object) As String
        Return EmployeeFeedbackCatalog.TypeName(Convert.ToInt32(value))
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        System.Diagnostics.Trace.TraceError("EmployeeFeedback: {0}", ex)
        Dim sql=TryCast(ex,SqlException)
        If sql IsNot Nothing AndAlso sql.Number=51500 Then Return sql.Message
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Return "تعذر تنفيذ العملية، يرجى المحاولة مجددًا."
    End Function
    Public Shared Function SaveQueuedAttachments(items As List(Of FileAttribute), saved As List(Of String)) As XElement
        Dim result As New XElement("files")
        If items Is Nothing Then Return result
        If items.Count>MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
        For Each item In items
            SaveFileBytes(item.NameFile,item.FileByte,result,saved)
        Next
        Return result
    End Function
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
        Dim folder = HttpContext.Current.Server.MapPath("~/App_Data/EmployeeFeedback/")
        Directory.CreateDirectory(folder)
        Dim fileName = Guid.NewGuid().ToString("N") & extension
        Dim destination = Path.Combine(folder, fileName)
        saved.Add(destination)
        File.WriteAllBytes(destination, bytes)
        files.Add(New XElement("file", New XAttribute("name", fileName), New XAttribute("type", extension.TrimStart("."c)), New XAttribute("original", Path.GetFileName(originalName)), New XAttribute("size", bytes.LongLength)))
    End Sub
End Class
