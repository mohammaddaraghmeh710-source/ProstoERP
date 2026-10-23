Imports System.Data
Imports System.IO
Imports System.Linq
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Web.UI

Public Class ContentManagementAjax
    Inherits PageBase
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Response.Cache.SetCacheability(HttpCacheability.NoCache) : Response.Cache.SetNoStore()
        Response.ContentType = "application/json; charset=utf-8"
        Response.AddHeader("X-Content-Type-Options", "nosniff")
        Dim staged As String = Nothing
        Try
            If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401, "يلزم تسجيل الدخول.")
            If Request.HttpMethod <> "POST" Then Throw New HttpException(405, "طلب غير مسموح.")
            Dim token = TryCast(Session("ContentManagementCSRF"), String)
            If String.IsNullOrEmpty(token) OrElse Request.Headers("X-Content-CSRF") <> token Then Throw New HttpException(403, "انتهت صلاحية النموذج؛ أعد فتح الصفحة.")
            Dim actor = SessionManager.GetInstance.Users.UserID, kind = Request.QueryString("kind"), action = Request.QueryString("action")
            ContentManagementData.RequireAdmin(actor)
            If Not {"pages", "news"}.Contains(kind) OrElse Not {"list", "editor", "save", "delete"}.Contains(action) Then Throw New HttpException(400, "طلب غير صحيح.")
            If Request.ContentLength > 11534336 Then Throw New ArgumentException("الملف أكبر من الحجم المسموح.")
            Dim serializer As New JavaScriptSerializer With {.MaxJsonLength = 1000000}
            ' Only this explicit JSON payload can contain HTML; all fields are validated/sanitized before writes.
            Dim raw = Request.Unvalidated.Form("payload")
            If raw Is Nothing OrElse raw.Length > 300000 Then Throw New ArgumentException("بيانات النموذج غير صحيحة.")
            Dim data = serializer.Deserialize(Of Collections.Generic.Dictionary(Of String, Object))(raw), result As Object
            Select Case action
                Case "list"
                    result = ContentManagementData.Listing(actor, kind)
                Case "editor"
                    result = ContentManagementData.Editor(actor, kind, ContentManagementData.Number(data, "id"))
                Case "save"
                    If Not {"0", "1"}.Contains(ContentManagementData.Text(data, "active", 1, True)) Then Throw New ArgumentException("اختر حالة صحيحة.")
                    Dim id As Integer
                    If kind = "pages" Then
                        id = ContentManagementData.SavePage(actor, data)
                    Else
                        staged = StageImage(Request.Files("image"))
                        id = ContentManagementData.WriteNews(actor, data, False, staged)
                    End If
                    staged = Nothing
                    result = New With {.id = id}
                Case Else
                    If kind = "pages" Then
                        InformationPagesData.Query("dbo.Delete_Information_Page", InformationPagesData.P("@Actor", SqlDbType.Int, actor), InformationPagesData.P("@ID", SqlDbType.Int, ContentManagementData.Number(data, "id", 1)), InformationPagesData.P("@ExpectedVersion", SqlDbType.Int, ContentManagementData.Number(data, "version", 1)))
                    Else
                        ContentManagementData.WriteNews(actor, data, True, Nothing)
                    End If
                    result = New With {.deleted = True}
            End Select
            Response.Write(serializer.Serialize(result))
        Catch ex As Exception
            If staged IsNot Nothing Then
                Try
                    File.Delete(Server.MapPath("~" & staged))
                Catch cleanup As Exception
                    System.Diagnostics.Trace.TraceError("Staged news image cleanup: {0}", cleanup.GetType().Name)
                End Try
            End If
            Dim sql = TryCast(ex, System.Data.SqlClient.SqlException), http = TryCast(ex, HttpException)
            Response.StatusCode = If(http IsNot Nothing, http.GetHttpCode(), If(TypeOf ex Is ArgumentException, 422, If(sql IsNot Nothing AndAlso {51600, 51604, 51950, 51951, 51952}.Contains(sql.Number), 409, 500)))
            Response.TrySkipIisCustomErrors = True
            Dim message = If(TypeOf ex Is ArgumentException OrElse http IsNot Nothing OrElse (sql IsNot Nothing AndAlso {51600, 51604}.Contains(sql.Number)), ex.Message, "تعذر الحفظ؛ راجع صلاحية الحساب والعلامة التجارية ثم حاول مجددًا.")
            Response.Write((New JavaScriptSerializer()).Serialize(New With {.message = message}))
            If Response.StatusCode = 500 Then System.Diagnostics.Trace.TraceError("Content management: {0}", ex.GetType().Name)
        End Try
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Private Function StageImage(upload As HttpPostedFile) As String
        If upload Is Nothing OrElse (upload.ContentLength = 0 AndAlso String.IsNullOrEmpty(upload.FileName)) Then Return Nothing
        If upload.ContentLength < 12 OrElse upload.ContentLength > 10485760 Then Throw New ArgumentException("ارفع صورة صحيحة حتى 10 ميجابايت.")
        Dim extension = Path.GetExtension(upload.FileName).ToLowerInvariant(), bytes As Byte()
        If Not {".png", ".jpg", ".jpeg", ".gif", ".webp"}.Contains(extension) Then Throw New ArgumentException("يسمح بصور PNG أو JPG أو GIF أو WebP فقط.")
        Using stream As New MemoryStream()
            upload.InputStream.CopyTo(stream) : bytes = stream.ToArray()
        End Using
        If extension = ".webp" Then
            ' WebP is a raster-only RIFF container. Reject wrong/truncated/mislabeled containers.
            If bytes.Length < 30 OrElse System.Text.Encoding.ASCII.GetString(bytes, 0, 4) <> "RIFF" OrElse System.Text.Encoding.ASCII.GetString(bytes, 8, 4) <> "WEBP" OrElse BitConverter.ToUInt32(bytes, 4) <> bytes.Length - 8 OrElse Not {"VP8 ", "VP8L", "VP8X"}.Contains(System.Text.Encoding.ASCII.GetString(bytes, 12, 4)) Then Throw New ArgumentException("ملف WebP غير صحيح.")
            Dim offset = 12
            While offset < bytes.Length
                If offset + 8 > bytes.Length Then Throw New ArgumentException("ملف WebP غير صحيح.")
                Dim size = CLng(BitConverter.ToUInt32(bytes, offset + 4))
                If offset + 8L + size + (size Mod 2) > bytes.Length Then Throw New ArgumentException("ملف WebP غير صحيح.")
                offset = CInt(offset + 8L + size + (size Mod 2))
            End While
        Else
            Try
                Using input As New MemoryStream(bytes), image = System.Drawing.Image.FromStream(input, True, True)
                    If image.Width > 8000 OrElse image.Height > 8000 OrElse CLng(image.Width) * image.Height > 24000000 Then Throw New ArgumentException("أبعاد الصورة كبيرة جدًا.")
                    If Not {System.Drawing.Imaging.ImageFormat.Png.Guid, System.Drawing.Imaging.ImageFormat.Jpeg.Guid, System.Drawing.Imaging.ImageFormat.Gif.Guid}.Contains(image.RawFormat.Guid) Then Throw New ArgumentException("صيغة الصورة غير صحيحة.")
                    Using clean As New System.Drawing.Bitmap(image.Width, image.Height), graphics = System.Drawing.Graphics.FromImage(clean), output As New MemoryStream()
                        graphics.DrawImage(image, 0, 0, image.Width, image.Height) : clean.Save(output, System.Drawing.Imaging.ImageFormat.Png) : bytes = output.ToArray()
                    End Using
                End Using
            Catch ex As ArgumentException
                Throw New ArgumentException("الصورة غير صحيحة أو أبعادها كبيرة جدًا.")
            End Try
            extension = ".png"
        End If
        Dim url = "/FileManager/News/" & Guid.NewGuid().ToString("N") & extension, target = Server.MapPath("~" & url)
        Directory.CreateDirectory(Path.GetDirectoryName(target))
        Try
            Using output As New FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None)
                output.Write(bytes, 0, bytes.Length)
            End Using
        Catch
            If File.Exists(target) Then File.Delete(target)
            Throw
        End Try
        Return url
    End Function
    Protected Overrides Sub Render(writer As HtmlTextWriter)
    End Sub
End Class
