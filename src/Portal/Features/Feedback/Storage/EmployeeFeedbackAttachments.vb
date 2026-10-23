Imports System.Drawing
Imports System.Drawing.Imaging
Imports System.IO
Imports System.IO.Compression

Public NotInheritable Class EmployeeFeedbackAttachments
    Public Const MaxFiles As Integer = 5

    Public Const MaxFileBytes As Integer = 10*1024*1024

    Public Shared Function SaveQueuedAttachments(items As List(Of FileAttribute), saved As List(Of String)) As XElement
        Dim result As New XElement("files")
        If items Is Nothing Then Return result
        If items.Count > MaxFiles Then Throw New ArgumentException("الحد الأقصى خمسة مرفقات.")
        For Each item In items
            SaveFileBytes(item.NameFile, item.FileByte, result, saved)
        Next
        Return result
    End Function

    Private Shared Sub SaveFileBytes(originalName As String, bytes As Byte(), files As XElement,
                                     saved As List(Of String))
        If bytes Is Nothing OrElse bytes.Length = 0 OrElse bytes.Length > MaxFileBytes Then _
            Throw New ArgumentException("حجم المرفق غير صحيح؛ الحد الأعلى 10 ميجابايت.")
        Dim extension = Path.GetExtension(originalName).ToLowerInvariant()
        Dim _
            types As _
                New Dictionary(Of String, String) _
                From {{".pdf", "application/pdf"}, {".doc", "application/msword"},
                {".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
                {".xls", "application/vnd.ms-excel"},
                {".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}, {".jpg", "image/jpeg"},
                {".jpeg", "image/jpeg"}, {".png", "image/png"}, {".gif", "image/gif"}}
        If Not types.ContainsKey(extension) Then _
            Throw New ArgumentException("الملفات المسموحة: PDF وWord وExcel والصور JPG وPNG وGIF.")
        If types(extension).StartsWith("image/") Then
            Using input As New MemoryStream(bytes)
                Using source = Image.FromStream(input, True, True)
                    If CLng(source.Width)*source.Height > 20000000 Then _
                        Throw New ArgumentException("أبعاد الصورة كبيرة جدًا.")
                    Using clean As New Bitmap(source.Width, source.Height)
                        Using graphics = System.Drawing.Graphics.FromImage(clean)
                            graphics.DrawImage(source, 0, 0, source.Width, source.Height)
                        End Using
                        Using output As New MemoryStream()
                            clean.Save(output, ImageFormat.Png)
                            bytes = output.ToArray()
                        End Using
                    End Using
                End Using
            End Using
            extension = ".png"
        ElseIf extension = ".pdf" Then
            If bytes.Length < 5 OrElse Encoding.ASCII.GetString(bytes, 0, 5) <> "%PDF-" Then _
                Throw New ArgumentException("ملف PDF غير صالح.")
        ElseIf extension = ".docx" OrElse extension = ".xlsx" Then
            Using stream As New MemoryStream(bytes), archive As New ZipArchive(stream, ZipArchiveMode.Read)
                Dim entry = If(extension = ".docx", "word/document.xml", "xl/workbook.xml")
                If archive.GetEntry(entry) Is Nothing OrElse archive.GetEntry("[Content_Types].xml") Is Nothing Then _
                    Throw New ArgumentException("ملف Office غير صالح.")
                If _
                    archive.Entries.Any(
                        Function(item) item.FullName.EndsWith("vbaProject.bin", StringComparison.OrdinalIgnoreCase)) _
                    Then Throw New ArgumentException("ملفات Office التي تحتوي على وحدات ماكرو غير مسموحة.")
            End Using
        Else
            Dim signature As Byte() = {&HD0, &HCF, &H11, &HE0, &HA1, &HB1, &H1A, &HE1}
            If bytes.Length < 8 OrElse Not bytes.Take(8).SequenceEqual(signature) Then _
                Throw New ArgumentException("ملف Office غير صالح.")
        End If
        If bytes.Length > MaxFileBytes Then Throw New ArgumentException("حجم الصورة بعد المعالجة يتجاوز 10 ميجابايت.")
        Dim folder = HttpContext.Current.Server.MapPath("~/App_Data/EmployeeFeedback/")
        Directory.CreateDirectory(folder)
        Dim fileName = Guid.NewGuid().ToString("N") & extension
        Dim destination = Path.Combine(folder, fileName)
        saved.Add(destination)
        File.WriteAllBytes(destination, bytes)
        files.Add(New XElement("file", New XAttribute("name", fileName),
                               New XAttribute("type", extension.TrimStart("."c)),
                               New XAttribute("original", Path.GetFileName(originalName)),
                               New XAttribute("size", bytes.LongLength)))
    End Sub
End Class


