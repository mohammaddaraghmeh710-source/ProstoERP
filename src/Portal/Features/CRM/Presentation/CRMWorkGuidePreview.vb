Imports System.Configuration
Imports System.Diagnostics
Imports System.IO
Imports System.IO.Compression
Imports System.Linq
Imports System.Threading
Imports System.Web
Imports System.Xml
Imports System.Xml.Linq

Public NotInheritable Class CRMWorkGuidePreview
    Private Shared ReadOnly ConversionGate As New SemaphoreSlim(1, 1)
    Private Const MaxPreviewBytes As Long = 52428800

    Public Shared Function PdfPath(url As String) As String
        Dim source = CRMWorkGuideFile.PhysicalPath(url)
        If Not File.Exists(source) Then Throw New ArgumentException("ملف الدليل غير متاح.")
        If Path.GetExtension(source) = ".pdf" Then Return source
        Dim cache = Path.Combine(Path.GetDirectoryName(source), "Previews", Path.GetFileNameWithoutExtension(source) & ".pdf")
        If ValidPdf(cache) Then Return cache
        If Not ConversionGate.Wait(5000) Then Throw New ArgumentException("العارض مشغول بتجهيز مستند آخر؛ أعد المحاولة بعد قليل.")
        Try
            If ValidPdf(cache) Then Return cache
            ConvertWord(source, cache)
            Return cache
        Finally
            ConversionGate.Release()
        End Try
    End Function

    Private Shared Function ValidPdf(file As String) As Boolean
        If Not System.IO.File.Exists(file) Then Return False
        Dim info As New FileInfo(file)
        If info.Length < 5 OrElse info.Length > MaxPreviewBytes Then Return False
        Using input = System.IO.File.OpenRead(file)
            Dim signature(4) As Byte
            Return input.Read(signature, 0, 5) = 5 AndAlso System.Text.Encoding.ASCII.GetString(signature) = "%PDF-"
        End Using
    End Function

    Private Shared Function Converter() As String
        Dim configured = ConfigurationManager.AppSettings("CRMWorkGuide.ConverterPath")
        Dim candidates = {configured, HttpContext.Current.Server.MapPath("~/App_Data/Tools/LibreOffice/program/soffice.exe"), HttpContext.Current.Server.MapPath("~/App_Data/Tools/LibreOffice/LibreOffice/program/soffice.exe"), Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "LibreOffice/program/soffice.exe")}
        For Each candidate In candidates
            If Not String.IsNullOrWhiteSpace(candidate) AndAlso Path.IsPathRooted(candidate) AndAlso File.Exists(candidate) Then Return candidate
        Next
        Throw New ArgumentException("محوّل Word غير متاح حاليًا. يرجى التواصل مع مدير النظام.")
    End Function

    ' Do not let external relationships in OpenXML documents contact remote services during import.
    Private Shared Sub CheckExternalContent(source As String)
        If Path.GetExtension(source) <> ".docx" Then Return
        Using stream = File.OpenRead(source), archive As New ZipArchive(stream, ZipArchiveMode.Read)
            For Each entry In archive.Entries.Where(Function(e) e.FullName.EndsWith(".rels", StringComparison.OrdinalIgnoreCase))
                Dim settings As New XmlReaderSettings With {.DtdProcessing = DtdProcessing.Prohibit, .XmlResolver = Nothing, .MaxCharactersInDocument = 1048576}
                Using input = entry.Open(), reader = XmlReader.Create(input, settings)
                    Dim root = XElement.Load(reader)
                    If root.Elements().Any(Function(r) String.Equals(CStr(r.Attribute("TargetMode")), "External", StringComparison.OrdinalIgnoreCase) AndAlso Not If(CStr(r.Attribute("Type")), "").EndsWith("/hyperlink", StringComparison.OrdinalIgnoreCase)) Then Throw New ArgumentException("تعذر عرض Word لاحتوائه على محتوى مرتبط بملفات خارجية. أرفق نسخة تتضمن الصور والمحتوى داخل الملف.")
                End Using
            Next
        End Using
    End Sub

    Private Shared Sub ConvertWord(source As String, cache As String)
        Dim executable = Converter()
        CheckExternalContent(source)
        Dim workRoot = HttpContext.Current.Server.MapPath("~/App_Data/CRMGuideConversion")
        Dim work = Path.Combine(workRoot, Guid.NewGuid().ToString("N"))
        Directory.CreateDirectory(work)
        Try
            Dim profile = Path.Combine(work, "profile"), profileUser = Path.Combine(profile, "user")
            Directory.CreateDirectory(profileUser)
            ' Fresh, private conversion profile: macros disabled, no trusted locations, no link updates.
            File.WriteAllText(Path.Combine(profileUser, "registrymodifications.xcu"), "<?xml version='1.0' encoding='UTF-8'?><oor:items xmlns:oor='http://openoffice.org/2001/registry'><item oor:path='/org.openoffice.Office.Common/Security/Scripting'><prop oor:name='MacroSecurityLevel' oor:op='fuse'><value>3</value></prop><prop oor:name='DisableMacrosExecution' oor:op='fuse'><value>true</value></prop><prop oor:name='DisableActiveContent' oor:op='fuse'><value>true</value></prop><prop oor:name='DisableOLEAutomation' oor:op='fuse'><value>true</value></prop><prop oor:name='DisablePythonRuntime' oor:op='fuse'><value>true</value></prop></item><item oor:path='/org.openoffice.Office.Writer/Content/Update'><prop oor:name='Link' oor:op='fuse'><value>0</value></prop></item></oor:items>")
            Dim input = Path.Combine(work, "document" & Path.GetExtension(source))
            File.Copy(source, input, False)
            Dim start As New ProcessStartInfo(executable) With {.UseShellExecute = False, .CreateNoWindow = True, .WindowStyle = ProcessWindowStyle.Hidden, .WorkingDirectory = work}
            start.EnvironmentVariables("SAL_DISABLE_OPENCL") = "1"
            start.EnvironmentVariables("SAL_DISABLESKIA") = "1"
            start.Arguments = "-env:UserInstallation=" & Quote(New Uri(profile & Path.DirectorySeparatorChar).AbsoluteUri) & " --headless --nologo --nodefault --norestore --nofirststartwizard --convert-to pdf:writer_pdf_Export --outdir " & Quote(work) & " " & Quote(input)
            Using job As Process = System.Diagnostics.Process.Start(start)
                If Not job.WaitForExit(90000) Then
                    Try
                        ' soffice launches soffice.bin; terminate this private conversion tree only.
                        Dim stopInfo As New ProcessStartInfo(Path.Combine(Environment.SystemDirectory, "taskkill.exe"), "/PID " & job.Id.ToString(System.Globalization.CultureInfo.InvariantCulture) & " /T /F") With {.UseShellExecute = False, .CreateNoWindow = True, .WindowStyle = ProcessWindowStyle.Hidden}
                        Using stopJob = System.Diagnostics.Process.Start(stopInfo)
                            stopJob.WaitForExit(5000)
                        End Using
                    Catch ex As InvalidOperationException
                    End Try
                    Throw New ArgumentException("استغرق تجهيز Word وقتًا طويلًا. جرّب ملفًا أصغر أو نسخة PDF.")
                End If
                If job.ExitCode <> 0 Then Throw New ArgumentException("تعذر تجهيز Word للعرض؛ تحقق من سلامة الملف وأنه غير محمي بكلمة مرور.")
            End Using
            Dim output = Path.Combine(work, "document.pdf")
            If Not ValidPdf(output) Then Throw New ArgumentException("تعذر تجهيز Word للعرض؛ تحقق من سلامة الملف وأنه غير محمي بكلمة مرور.")
            Directory.CreateDirectory(Path.GetDirectoryName(cache))
            ' Original GUID files are immutable; do not overwrite another worker's completed cache.
            Try
                File.Move(output, cache)
            Catch ex As IOException
                If Not ValidPdf(cache) Then Throw
            End Try
        Finally
            Try
                Directory.Delete(work, True)
            Catch ex As IOException
                Trace.TraceWarning("CRM guide conversion temporary cleanup pending.")
            Catch ex As UnauthorizedAccessException
                Trace.TraceWarning("CRM guide conversion temporary cleanup denied.")
            End Try
        End Try
    End Sub
    Private Shared Function Quote(value As String) As String
        If value.Contains(ChrW(34)) Then Throw New ArgumentException("مسار التحويل غير صحيح.")
        Return ChrW(34) & value & ChrW(34)
    End Function
End Class
