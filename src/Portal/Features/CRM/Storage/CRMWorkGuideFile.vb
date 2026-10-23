Imports System.IO
Imports System.IO.Compression
Imports System.Linq
Imports System.Web

Public NotInheritable Class CRMWorkGuideFile
    Public Const MaxBytes As Integer = 10485760
    Public Property Url As String
    Public Property OriginalName As String
    Public Property Extension As String
    Public Property Size As Integer

    Public Shared Function PhysicalPath(url As String) As String
        If url Is Nothing OrElse Not System.Text.RegularExpressions.Regex.IsMatch(url, "\A/FileManager/CRMWorkGuide/[a-f0-9]{32}\.(pdf|docx?)\z") Then Throw New ArgumentException("مسار الملف غير صحيح.")
        Return HttpContext.Current.Server.MapPath("~" & url)
    End Function

    ' Same signature/OpenXML checks and FileManager staging pattern used by correspondence uploads.
    Public Shared Function SaveUpload(upload As HttpPostedFile) As CRMWorkGuideFile
        If upload Is Nothing OrElse (upload.ContentLength = 0 AndAlso String.IsNullOrEmpty(upload.FileName)) Then Return Nothing
        If upload.ContentLength <= 0 OrElse upload.ContentLength > MaxBytes Then Throw New ArgumentException("حجم الملف يجب أن يكون أكبر من صفر ولا يتجاوز 10 ميجابايت.")
        Dim name = Path.GetFileName(upload.FileName), extension = Path.GetExtension(name).ToLowerInvariant()
        If name.Length > 200 OrElse name.IndexOfAny({ChrW(13), ChrW(10), ChrW(0)}) >= 0 Then Throw New ArgumentException("اسم الملف غير صحيح أو طويل جدًا.")
        If Not {".pdf", ".doc", ".docx"}.Contains(extension) Then Throw New ArgumentException("يسمح بملفات PDF وWord بصيغ DOC وDOCX فقط.")
        Dim bytes As Byte()
        Using input As New MemoryStream()
            upload.InputStream.CopyTo(input) : bytes = input.ToArray()
        End Using
        If bytes.Length = 0 OrElse bytes.Length > MaxBytes Then Throw New ArgumentException("حجم الملف غير صحيح.")
        If extension = ".pdf" Then
            If bytes.Length < 5 OrElse System.Text.Encoding.ASCII.GetString(bytes, 0, 5) <> "%PDF-" Then Throw New ArgumentException("ملف PDF غير صالح.")
        ElseIf extension = ".docx" Then
            Try
                Using input As New MemoryStream(bytes), archive As New ZipArchive(input, ZipArchiveMode.Read)
                    If archive.GetEntry("word/document.xml") Is Nothing OrElse archive.GetEntry("[Content_Types].xml") Is Nothing Then Throw New ArgumentException("ملف Word غير صالح.")
                    If archive.Entries.Count > 4096 OrElse archive.Entries.Sum(Function(e) e.Length) > 104857600 Then Throw New ArgumentException("محتويات ملف Word كبيرة جدًا.")
                    If archive.Entries.Any(Function(e) e.FullName.EndsWith("vbaProject.bin", StringComparison.OrdinalIgnoreCase)) Then Throw New ArgumentException("ملفات Word التي تحتوي على وحدات ماكرو غير مسموحة.")
                End Using
            Catch ex As InvalidDataException
                Throw New ArgumentException("ملف Word غير صالح.")
            End Try
        Else
            Dim signature As Byte() = {&HD0, &HCF, &H11, &HE0, &HA1, &HB1, &H1A, &HE1}
            If bytes.Length < 8 OrElse Not bytes.Take(8).SequenceEqual(signature) Then Throw New ArgumentException("ملف Word غير صالح.")
        End If
        Dim result As New CRMWorkGuideFile With {.Url = "/FileManager/CRMWorkGuide/" & Guid.NewGuid().ToString("N") & extension, .OriginalName = name, .Extension = extension, .Size = bytes.Length}
        Dim destination = PhysicalPath(result.Url), created As Boolean = False
        Directory.CreateDirectory(Path.GetDirectoryName(destination))
        Try
            Using output As New FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None)
                created = True : output.Write(bytes, 0, bytes.Length)
            End Using
            Return result
        Catch
            If created Then result.Cleanup()
            Throw
        End Try
    End Function

    Public Sub Cleanup()
        Try
            File.Delete(PhysicalPath(Url))
        Catch ex As Exception
            System.Diagnostics.Trace.TraceError("CRM guide file cleanup: {0}", ex.Message)
        End Try
    End Sub
End Class
