Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging
Imports System.IO
Imports System.Linq
Imports System.Web

Public NotInheritable Class CRMAccountLogo
    Public Const DefaultUrl As String = "/assets/img/illustrations/customer-default.svg"
    Public Const MaxBytes As Integer = 2097152
    Public Const StorageUrl As String = "/FileManager/CustomerLogos/"

    Public Shared Function PhysicalPath(url As String) As String
        If url Is Nothing OrElse Not System.Text.RegularExpressions.Regex.IsMatch(url, "\A/FileManager/CustomerLogos/[a-f0-9]{32}\.png\z") Then Throw New InvalidOperationException("مسار الشعار غير صحيح.")
        Return HttpContext.Current.Server.MapPath("~" & url)
    End Function

    Public Shared Function SaveFile(bytes As Byte()) As String
        If bytes Is Nothing Then Return Nothing
        Dim url = StorageUrl & Guid.NewGuid().ToString("N") & ".png", destination = PhysicalPath(url)
        Directory.CreateDirectory(Path.GetDirectoryName(destination))
        Try
            Using output As New FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None)
                output.Write(bytes, 0, bytes.Length)
            End Using
            Return url
        Catch
            RemoveStagedFile(url)
            Throw
        End Try
    End Function

    Public Shared Sub RemoveStagedFile(url As String)
        If url Is Nothing Then Return
        Try
            File.Delete(PhysicalPath(url))
        Catch ex As Exception
            System.Diagnostics.Trace.TraceError("CRM logo staging cleanup: {0}", ex.Message)
        End Try
    End Sub

    Public Shared Function ReadFile(url As String) As Byte()
        Dim file = PhysicalPath(url)
        If Not System.IO.File.Exists(file) Then Return Nothing
        Return System.IO.File.ReadAllBytes(file)
    End Function

    ' Reuse the correspondence/feedback image decode-and-reencode pattern, with logo-only limits.
    Public Shared Function ReadUpload(upload As HttpPostedFile) As Byte()
        If upload Is Nothing OrElse (upload.ContentLength = 0 AndAlso String.IsNullOrEmpty(upload.FileName)) Then Return Nothing
        If upload.ContentLength <= 0 Then Throw New InvalidOperationException("ملف الشعار فارغ.")
        If upload.ContentLength > MaxBytes Then Throw New InvalidOperationException("حجم الشعار يجب ألا يتجاوز 2 ميجابايت.")
        Dim extension = Path.GetExtension(upload.FileName).ToLowerInvariant()
        If Not {".png", ".jpg", ".jpeg", ".gif"}.Contains(extension) Then Throw New InvalidOperationException("يسمح بصور PNG وJPG وGIF فقط.")
        Try
            Using source = Image.FromStream(upload.InputStream, True, True)
                If source.RawFormat.Guid <> ImageFormat.Png.Guid AndAlso source.RawFormat.Guid <> ImageFormat.Jpeg.Guid AndAlso source.RawFormat.Guid <> ImageFormat.Gif.Guid Then Throw New InvalidOperationException("صيغة الصورة غير مدعومة.")
                If source.Width > 4096 OrElse source.Height > 4096 Then Throw New InvalidOperationException("أبعاد الشعار يجب ألا تتجاوز 4096 × 4096 بكسل.")
                Dim ratio = Math.Min(1.0, 512.0 / Math.Max(source.Width, source.Height))
                Using clean As New Bitmap(Math.Max(1, CInt(source.Width * ratio)), Math.Max(1, CInt(source.Height * ratio)))
                    Using graphics = System.Drawing.Graphics.FromImage(clean)
                        graphics.InterpolationMode = InterpolationMode.HighQualityBicubic
                        graphics.DrawImage(source, 0, 0, clean.Width, clean.Height)
                    End Using
                    Using output As New MemoryStream()
                        clean.Save(output, ImageFormat.Png)
                        If output.Length > MaxBytes Then Throw New InvalidOperationException("حجم الصورة بعد المعالجة كبير جدًا.")
                        Return output.ToArray()
                    End Using
                End Using
            End Using
        Catch ex As ArgumentException
            Throw New InvalidOperationException("الملف المرفوع ليس صورة صالحة.")
        Catch ex As OutOfMemoryException
            Throw New InvalidOperationException("الصورة غير صالحة أو أبعادها كبيرة جدًا.")
        End Try
    End Function

    Public Shared Function Url(id As Integer, version As Byte()) As String
        Return "/Modules/CRM_Accounts/Logo.aspx?id=" & id.ToString(Global.System.Globalization.CultureInfo.InvariantCulture) & "&v=" & BitConverter.ToString(version).Replace("-", "")
    End Function
End Class
