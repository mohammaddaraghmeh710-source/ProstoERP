Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Linq
Imports System.Web

Public Class ViewWorkGuideFile
    Inherits PageBase

    Protected Property AllowDocumentPrint As Boolean
    Private CurrentUserID As Integer
    Private RequestedDocumentID As Integer
    Private RequestedType As String
    Private DocumentInfo As WorkGuideDocumentInfo

    Protected Sub Page_Load(
        ByVal sender As Object,
        ByVal e As EventArgs
    ) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then

            If IsStreamRequest() Then
                SendStatusCode(401)
            Else
                Response.Redirect("/login.aspx")
            End If

            Return
        End If

        CurrentUserID = SessionManager.GetInstance.Users.UserID
        RequestedType = Convert.ToString(Request.QueryString("type"))

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
            InsertViewActivityLog()
        End If

    End Sub

    Private Function IsStreamRequest() As Boolean

        Return String.Equals(
            Request.QueryString("stream"),
            "1",
            StringComparison.OrdinalIgnoreCase
        )

    End Function

    Private Sub PrepareViewer()

        lblDocumentTitle.Text =
            Server.HtmlEncode(DocumentInfo.TitleAr)

        Dim streamUrl As String =
            ResolveUrl(
                "~/Modules/WorkGuide_Documents/ViewWorkGuideFile.aspx" &
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

    Private Function UserCanViewDocument(
        userID As Integer,
        documentID As Integer
    ) As Boolean

        Using db As New _
            Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim permission =
                db.Check_Work_Guide_User_Document_Permission(
                    userID,
                    documentID
                ).FirstOrDefault()

            If permission Is Nothing Then
                Return False
            End If

            'استخدم اسم العمود الذي يعيده الإجراء المخزن لديك.
            'الاسم المتوقع بناءً على النظام الحالي:
            AllowDocumentPrint = permission.Can_Print_Document.GetValueOrDefault()
            Return Convert.ToBoolean(permission.Can_View_Document)

        End Using

    End Function

    Private Function GetDocumentInformation(
        requestedID As Integer,
        requestedType As String
    ) As WorkGuideDocumentInfo

        Using db As New _
            Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim connection As SqlConnection =
                DirectCast(db.Connection, SqlConnection)

            Dim shouldCloseConnection As Boolean =
                connection.State <> ConnectionState.Open

            If shouldCloseConnection Then
                connection.Open()
            End If

            Try
                If String.Equals(
                    requestedType,
                    "version",
                    StringComparison.OrdinalIgnoreCase
                ) Then

                    Return GetVersionInformation(
                        connection,
                        requestedID
                    )
                End If

                Return GetCurrentDocumentInformation(
                    connection,
                    requestedID
                )

            Finally
                If shouldCloseConnection AndAlso
                    connection.State = ConnectionState.Open Then

                    connection.Close()
                End If
            End Try

        End Using

    End Function

    Private Function GetCurrentDocumentInformation(
        connection As SqlConnection,
        documentID As Integer
    ) As WorkGuideDocumentInfo

        Const sql As String =
            "SELECT TOP 1 " &
            "D.ID AS Document_ID, " &
            "D.Brand_ID, " &
            "D.Category_ID, " &
            "D.Title_Ar, " &
            "D.File_Path, " &
            "D.Original_File_Name " &
            "FROM dbo.Work_Guide_Documents D " &
            "WHERE D.ID = @Document_ID;"

        Using command As New SqlCommand(sql, connection)

            command.Parameters.Add(
                "@Document_ID",
                SqlDbType.Int
            ).Value = documentID

            Using reader As SqlDataReader =
                command.ExecuteReader()

                If Not reader.Read() Then
                    Return Nothing
                End If

                Return New WorkGuideDocumentInfo With {
                    .DocumentID =
                        Convert.ToInt32(reader("Document_ID")),
                    .BrandID =
                        GetNullableInteger(reader("Brand_ID")),
                    .CategoryID =
                        GetNullableInteger(reader("Category_ID")),
                    .TitleAr =
                        GetSafeString(reader("Title_Ar"),
                                      "مشاهدة الملف"),
                    .FilePath =
                        GetSafeString(reader("File_Path"), ""),
                    .OriginalFileName =
                        GetSafeString(reader("Original_File_Name"),
                                      "WorkGuide.pdf")
                }

            End Using
        End Using

    End Function

    Private Function GetVersionInformation(
        connection As SqlConnection,
        versionID As Integer
    ) As WorkGuideDocumentInfo

        'تأكد من اسم جدول الإصدارات واسم Document_ID
        'حسب الأسماء الموجودة لديك في قاعدة البيانات.

        Const sql As String =
            "SELECT TOP 1 " &
            "D.ID AS Document_ID, " &
            "D.Brand_ID, " &
            "D.Category_ID, " &
            "D.Title_Ar, " &
            "V.File_Path, " &
            "V.Original_File_Name " &
            "FROM dbo.Work_Guide_Document_Versions V " &
            "INNER JOIN dbo.Work_Guide_Documents D " &
            "ON D.ID = V.Document_ID " &
            "WHERE V.ID = @Version_ID;"

        Using command As New SqlCommand(sql, connection)

            command.Parameters.Add(
                "@Version_ID",
                SqlDbType.Int
            ).Value = versionID

            Using reader As SqlDataReader =
                command.ExecuteReader()

                If Not reader.Read() Then
                    Return Nothing
                End If

                Return New WorkGuideDocumentInfo With {
                    .DocumentID =
                        Convert.ToInt32(reader("Document_ID")),
                    .BrandID =
                        GetNullableInteger(reader("Brand_ID")),
                    .CategoryID =
                        GetNullableInteger(reader("Category_ID")),
                    .TitleAr =
                        GetSafeString(reader("Title_Ar"),
                                      "مشاهدة الملف"),
                    .FilePath =
                        GetSafeString(reader("File_Path"), ""),
                    .OriginalFileName =
                        GetSafeString(reader("Original_File_Name"),
                                      "WorkGuide.pdf")
                }

            End Using
        End Using

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
                DateTime.UtcNow.AddYears(-1)
            )

            Response.AddHeader("Pragma", "no-cache")
            Response.AddHeader("Expires", "0")

            Dim fileLength As Long =
                New FileInfo(physicalPath).Length

            Response.AddHeader(
                "Content-Length",
                fileLength.ToString()
            )

            Response.TransmitFile(physicalPath)
            Response.Flush()

            HttpContext.Current.ApplicationInstance.
                CompleteRequest()

        Catch ex As HttpException
            'قد يحدث عند إغلاق المستخدم للصفحة أثناء التحميل.
        End Try

    End Sub

    Private Sub InsertViewActivityLog()

        Try
            Using db As New _
                Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim connection As SqlConnection =
                    DirectCast(db.Connection, SqlConnection)

                Dim shouldCloseConnection As Boolean =
                    connection.State <> ConnectionState.Open

                If shouldCloseConnection Then
                    connection.Open()
                End If

                Try
                    Using command As New SqlCommand(
                        "dbo.Insert_Work_Guide_Activity_Logs",
                        connection
                    )

                        command.CommandType =
                            CommandType.StoredProcedure

                        command.Parameters.Add(
                            "@User_ID",
                            SqlDbType.Int
                        ).Value = CurrentUserID

                        AddNullableIntegerParameter(
                            command,
                            "@Brand_ID",
                            DocumentInfo.BrandID
                        )

                        AddNullableIntegerParameter(
                            command,
                            "@Category_ID",
                            DocumentInfo.CategoryID
                        )

                        command.Parameters.Add(
                            "@Document_ID",
                            SqlDbType.Int
                        ).Value = DocumentInfo.DocumentID

                        command.Parameters.Add(
                            "@Action_Type",
                            SqlDbType.NVarChar,
                            100
                        ).Value = "1"

                        command.Parameters.Add(
                            "@Action_Details",
                            SqlDbType.NVarChar,
                            -1
                        ).Value =
                            "تمت مشاهدة الملف من خلال عارض دليل العمل."

                        command.Parameters.Add(
                            "@IPAddress",
                            SqlDbType.NVarChar,
                            100
                        ).Value = GetClientIPAddress()

                        command.Parameters.Add(
                            "@UserAgent",
                            SqlDbType.NVarChar,
                            -1
                        ).Value =
                            Convert.ToString(
                                Request.UserAgent
                            )

                        command.ExecuteNonQuery()

                    End Using

                Finally
                    If shouldCloseConnection AndAlso
                        connection.State = ConnectionState.Open Then

                        connection.Close()
                    End If
                End Try

            End Using

        Catch ex As Exception
            'يفضل تسجيل الخطأ في نظام الـ Error Logs العام.
            'لا نوقف مشاهدة الملف بسبب تعذر حفظ سجل النشاط.
        End Try

    End Sub

    Private Function GetClientIPAddress() As String

        Dim forwardedFor As String =
            Convert.ToString(
                Request.ServerVariables("HTTP_X_FORWARDED_FOR")
            )

        If Not String.IsNullOrWhiteSpace(forwardedFor) Then

            Dim firstIPAddress As String =
                forwardedFor.Split(","c)(0).Trim()

            If firstIPAddress.Length > 100 Then
                firstIPAddress =
                    firstIPAddress.Substring(0, 100)
            End If

            Return firstIPAddress
        End If

        Dim remoteAddress As String =
            Convert.ToString(
                Request.ServerVariables("REMOTE_ADDR")
            )

        If remoteAddress.Length > 100 Then
            remoteAddress =
                remoteAddress.Substring(0, 100)
        End If

        Return remoteAddress

    End Function

    Private Function GetCurrentUserDisplayName() As String

        Try
            Using db As New _
                Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim user = db.Select_UsersMembers_ByID(CurrentUserID).FirstOrDefault()

                If user Is Nothing Then
                    Return "User #" &
                        CurrentUserID.ToString()
                End If

                'عدل اسم الحقل حسب الحقل الموجود لديك.
                Return Convert.ToString(user.FullName_Ar)

            End Using

        Catch
            Return "User #" &
                CurrentUserID.ToString()
        End Try

    End Function

    Private Sub AddNullableIntegerParameter(
        command As SqlCommand,
        parameterName As String,
        value As Integer?
    )

        Dim parameter As SqlParameter =
            command.Parameters.Add(
                parameterName,
                SqlDbType.Int
            )

        If value.HasValue Then
            parameter.Value = value.Value
        Else
            parameter.Value = DBNull.Value
        End If

    End Sub

    Private Function GetNullableInteger(
        value As Object
    ) As Integer?

        If value Is Nothing OrElse
            Convert.IsDBNull(value) Then

            Return Nothing
        End If

        Return Convert.ToInt32(value)

    End Function

    Private Function GetSafeString(
        value As Object,
        defaultValue As String
    ) As String

        If value Is Nothing OrElse
            Convert.IsDBNull(value) Then

            Return defaultValue
        End If

        Dim result As String =
            Convert.ToString(value)

        If String.IsNullOrWhiteSpace(result) Then
            Return defaultValue
        End If

        Return result

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