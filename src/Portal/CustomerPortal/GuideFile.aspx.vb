Imports System.IO

Public Class CustomerGuideFile
    Inherits CustomerPortalPage

    Protected Property AllowDocumentPrint As Boolean
    Private CurrentUserID As Integer
    Private RequestedDocumentID As Integer
    Private RequestedType As String
    Private DocumentInfo As WorkGuideDocumentInfo

    Protected Sub Page_Load(
                            sender As Object,
                            e As EventArgs
                            ) Handles Me.Load

        If CustomerPortalData.Current Is Nothing Then

            If IsStreamRequest() Then
                SendStatusCode(401)
            Else
                Response.Redirect("/login.aspx")
            End If

            Return
        End If

        CurrentUserID = CustomerPortalData.Current.AccountID
        RequestedType = "document"

        If String.IsNullOrWhiteSpace(RequestedType) Then
            RequestedType = "document"
        End If

        If Not Integer.TryParse(
            Request.QueryString("id"),
            RequestedDocumentID
            ) Then

            SendStatusCode(400)
            Return
        End If

        DocumentInfo = GetDocumentInformation(
            RequestedDocumentID,
            RequestedType
            )

        If DocumentInfo Is Nothing Then
            SendStatusCode(404)
            Return
        End If

        'مهم: التحقق من الصلاحية داخل صفحة العرض نفسها
        If Not UserCanViewDocument(
            CurrentUserID,
            DocumentInfo.DocumentID
            ) Then

            SendStatusCode(403)
            Return
        End If

        If IsStreamRequest() Then
            StreamPdfFile()
            Return
        End If

        If Not Page.IsPostBack Then
            PrepareViewer()

        End If
    End Sub

    Private Function IsStreamRequest() As Boolean

        Return String.Equals(
            Request.QueryString("stream"),
            "1",
            StringComparison.OrdinalIgnoreCase
            )
    End Function

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        If IsStreamRequest() Then Return
        MyBase.Render(writer)
    End Sub

    Private Sub PrepareViewer()

        lblDocumentTitle.Text =
            Server.HtmlEncode(DocumentInfo.TitleAr)

        Dim streamUrl As String =
                ResolveUrl(
                    "~/CustomerPortal/GuideFile.aspx" &
                    "?stream=1" &
                    "&type=" & HttpUtility.UrlEncode(RequestedType) &
                    "&id=" & RequestedDocumentID.ToString()
                    )

        hfPdfStreamUrl.Value = streamUrl

        Dim currentUserName As String =
                GetCurrentUserDisplayName()

        hfWatermarkText.Value =
            currentUserName &
            " - " &
            DateTime.Now.ToString("dd/MM/yyyy HH:mm")
    End Sub

    Private Function UserCanViewDocument(userID As Integer, documentID As Integer) As Boolean
        Dim rows = CustomerPortalData.Guide("file", 0, documentID)
        If rows.Rows.Count = 0 Then Return False
        AllowDocumentPrint = CBool(rows.Rows(0)("Can_Print_Document"))
        Return True
    End Function

    Private Function GetDocumentInformation(requestedID As Integer, requestedType As String) As WorkGuideDocumentInfo
        Dim rows = CustomerPortalData.Guide("file", 0, requestedID)
        If rows.Rows.Count = 0 Then Return Nothing
        Dim row = rows.Rows(0)
        Return _
            New WorkGuideDocumentInfo _
                With {.DocumentID=CInt(row("ID")),.BrandID=CInt(row("Brand_ID")),.CategoryID=CInt(row("Category_ID")),
                    .TitleAr=CStr(row("Title_Ar")),.FilePath=Convert.ToString(row("File_Path"))}
    End Function

    Private Sub StreamPdfFile()

        If String.IsNullOrWhiteSpace(DocumentInfo.FilePath) Then
            SendStatusCode(404)
            Return
        End If

        Dim physicalPath As String =
                Server.MapPath(DocumentInfo.FilePath)

        If Not File.Exists(physicalPath) Then
            SendStatusCode(404)
            Return
        End If

        Dim extension As String =
                Path.GetExtension(physicalPath)

        If Not String.Equals(
            extension,
            ".pdf",
            StringComparison.OrdinalIgnoreCase
            ) Then

            SendStatusCode(415)
            Return
        End If

        Try
            Response.Clear()
            Response.ClearHeaders()
            Response.Buffer = False

            Response.ContentType = "application/pdf"

            'لا نرسل اسم الملف الأصلي ولا مساره.
            Response.AddHeader(
                "Content-Disposition",
                "inline"
                )

            Response.AddHeader(
                "X-Content-Type-Options",
                "nosniff"
                )

            Response.AddHeader(
                "X-Frame-Options",
                "SAMEORIGIN"
                )

            Response.AddHeader(
                "Content-Security-Policy",
                "frame-ancestors 'self'"
                )

            Response.Cache.SetCacheability(
                HttpCacheability.NoCache
                )

            Response.Cache.SetNoStore()
            Response.Cache.SetExpires(
                DateTime.UtcNow.AddYears(- 1)
                )

            Response.AddHeader("Pragma", "no-cache")
            Response.AddHeader("Expires", "0")

            Dim fileLength As Long =
                    New FileInfo(physicalPath).Length

            Response.AddHeader(
                "Content-Length",
                fileLength.ToString()
                )

            InsertViewActivityLog()
            Response.TransmitFile(physicalPath)
            Response.Flush()

            HttpContext.Current.ApplicationInstance.
                CompleteRequest()

        Catch ex As HttpException
            'قد يحدث عند إغلاق المستخدم للصفحة أثناء التحميل.
        End Try
    End Sub

    Private Sub InsertViewActivityLog()
        CustomerPortalData.LogFile(DocumentInfo.DocumentID, "view")
    End Sub

    Private Function GetCurrentUserDisplayName() As String
        Return CustomerPortalData.Current.Name
    End Function

    Private Sub SendStatusCode(
                               statusCode As Integer
                               )

        Response.Clear()
        Response.StatusCode = statusCode
        Response.TrySkipIisCustomErrors = True

        HttpContext.Current.ApplicationInstance.
            CompleteRequest()
    End Sub

    Private Class WorkGuideDocumentInfo
        Public Property DocumentID As Integer
        Public Property BrandID As Integer?
        Public Property CategoryID As Integer?
        Public Property TitleAr As String
        Public Property FilePath As String
        Public Property OriginalFileName As String
    End Class
End Class


