Imports System.IO
Imports AjaxControlToolkit

Public Class Test_Page
    Inherits PageBase

    ' المسار الافتراضي داخل الموقع (لا يظهر للمستخدم)
    Private Const VideoVirtualPath As String = "~/FileManager/Videos/file_example_MP4_480_1_5MG.mp4"

    ' خاصية ترجع رابط التشغيل الآمن للفيديو (نفس الصفحة لكن بوضع stream)
    Protected ReadOnly Property VideoUrl As String
        Get
            ' يمكن إضافة رقم ID أو Token في المستقبل بدل الثابت
            Return ResolveUrl("~/Test_Page.aspx?mode=stream")
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' إذا كان الطلب هدفه تشغيل الفيديو (stream) لا نرسم الـ HTML بل نرسل البايتات فقط
        Dim mode As String = Convert.ToString(Request.QueryString("mode"))

        If String.Equals(mode, "stream", StringComparison.OrdinalIgnoreCase) Then
            StreamProtectedVideo()
            Return
        End If

        ' هنا كود الصفحة العادي (إن احتجت شيء إضافي مستقبلاً)
        If Not IsPostBack Then
            ' أي تهيئة إضافية للواجهة
        End If
    End Sub

    ''' <summary>
    ''' إرسال الفيديو للمتصفح من ملفات الخادم بدون كشف المسار الفعلي.
    ''' يمكن إضافة تحقق من الجلسة/الصلاحيات قبل الإرسال.
    ''' </summary>
    Private Sub StreamProtectedVideo()
        ' مثال بسيط: تأكد أن المستخدم مسجّل دخول (من PageBase أو SessionManager)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.StatusCode = 401
            Response.End()
            Return
        End If

        Dim fullPath As String = Server.MapPath(VideoVirtualPath)

        If Not File.Exists(fullPath) Then
            Response.StatusCode = 404
            Response.End()
            Return
        End If

        Try
            Dim fileInfo As New FileInfo(fullPath)

            Response.Clear()
            Response.Buffer = True
            Response.ContentType = "video/mp4"
            ' inline لعرضه داخل الصفحة، وليس كتحميل ملف
            Response.AddHeader("Content-Disposition", "inline; filename=""training.mp4""")
            Response.AddHeader("Content-Length", fileInfo.Length.ToString())

            ' يمكن استخدام TransmitFile أو WriteFile
            Response.TransmitFile(fullPath)
            Response.Flush()
        Catch ex As Exception
            ' في الإنتاج يمكنك تسجيل الخطأ في الـ log
            Response.StatusCode = 500
        Finally
            ' إنهاء الاستجابة حتى لا يتم إدخال الـ MasterPage/HTML
            Response.End()
        End Try
    End Sub

End Class
