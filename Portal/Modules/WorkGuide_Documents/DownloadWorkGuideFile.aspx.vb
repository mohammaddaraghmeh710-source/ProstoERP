Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Linq
Imports System.Text
Imports System.Web

Public Class DownloadWorkGuideFile
    Inherits PageBase

    Protected Sub Page_Load(
        ByVal sender As Object,
        ByVal e As System.EventArgs
    ) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx", False)
            HttpContext.Current.ApplicationInstance.CompleteRequest()
            Return
        End If

        Dim documentID As Integer = 0

        If String.IsNullOrWhiteSpace(Request.QueryString("id")) OrElse
           Not Integer.TryParse(Request.QueryString("id"), documentID) Then

            ShowAccessDenied()
            Return
        End If

        Try

            Dim currentUserID As Integer =
                SessionManager.GetInstance.Users.UserID

            Dim currentBrandID As Integer =
                GetCurrentUserBrandID(currentUserID)

            If currentBrandID = 0 Then
                ShowAccessDenied()
                Return
            End If

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim doc =
                    db.Select_Work_Guide_Document_ByID(documentID).
                    FirstOrDefault()

                If doc Is Nothing Then
                    ShowFileNotFound()
                    Return
                End If

                'التحقق من أن المستند يتبع نفس الشركة
                If Convert.ToInt32(doc.Brand_ID) <> currentBrandID Then
                    ShowAccessDenied()
                    Return
                End If

                'التحقق من صلاحية التحميل
                If Not UserCanDownloadDocument(
                    currentUserID,
                    documentID
                ) Then

                    ShowAccessDenied()
                    Return
                End If

                Dim filePath As String =
                    Convert.ToString(doc.File_Path)

                If String.IsNullOrWhiteSpace(filePath) Then
                    ShowFileNotFound()
                    Return
                End If

                Dim physicalPath As String =
                    GetPhysicalFilePath(filePath)

                If String.IsNullOrWhiteSpace(physicalPath) OrElse
                   Not File.Exists(physicalPath) Then

                    ShowFileNotFound()
                    Return
                End If

                'التأكد من أن الملف PDF
                Dim fileExtension As String =
                    Path.GetExtension(physicalPath)

                If Not String.Equals(
                    fileExtension,
                    ".pdf",
                    StringComparison.OrdinalIgnoreCase
                ) Then

                    ShowFileNotFound()
                    Return
                End If

                'تجهيز اسم الملف عند التحميل
                Dim downloadFileName As String =
                    Convert.ToString(doc.Title_Ar)

                If String.IsNullOrWhiteSpace(downloadFileName) Then
                    downloadFileName = "WorkGuide"
                End If

                If Not downloadFileName.EndsWith(
                    ".pdf",
                    StringComparison.OrdinalIgnoreCase
                ) Then

                    downloadFileName &= ".pdf"
                End If

                downloadFileName =
                    CleanFileName(downloadFileName)

                Dim categoryID As Integer =
                    Convert.ToInt32(doc.Category_ID)

                'تسجيل عملية التحميل
                InsertDownloadActivityLog(
                    currentUserID,
                    currentBrandID,
                    categoryID,
                    documentID,
                    downloadFileName
                )

                'إرسال الملف للمستخدم
                SendFileToBrowser(
                    physicalPath,
                    downloadFileName
                )

            End Using

        Catch ex As Exception

            System.Diagnostics.Trace.WriteLine(
                "DownloadWorkGuideFile Error: " &
                ex.ToString()
            )

            ShowGeneralError()

        End Try

    End Sub

    Private Function GetCurrentUserBrandID(
        ByVal userID As Integer
    ) As Integer

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim user =
                db.Select_UsersMembers_ByID(userID).FirstOrDefault()

            If user IsNot Nothing AndAlso
               user.Brand_ID IsNot Nothing Then

                Return Convert.ToInt32(user.Brand_ID)
            End If

        End Using

        Return 0

    End Function

    Private Function UserCanDownloadDocument(
        ByVal userID As Integer,
        ByVal documentID As Integer
    ) As Boolean

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim result =
                db.Check_Work_Guide_User_Document_Permission(
                    userID,
                    documentID
                ).FirstOrDefault()

            If result Is Nothing Then
                Return False
            End If

            Return Convert.ToBoolean(
                result.Can_Download_Document
            )

        End Using

    End Function

    Private Function GetPhysicalFilePath(
        ByVal filePath As String
    ) As String

        If String.IsNullOrWhiteSpace(filePath) Then
            Return Nothing
        End If

        filePath = filePath.Trim()

        If filePath.StartsWith(
            "~",
            StringComparison.Ordinal
        ) Then

            Return Server.MapPath(filePath)
        End If

        If filePath.StartsWith(
            "/",
            StringComparison.Ordinal
        ) Then

            Return Server.MapPath(filePath)
        End If

        If Path.IsPathRooted(filePath) Then
            Return filePath
        End If

        filePath =
            filePath.TrimStart("/"c)

        Return Server.MapPath(
            "~/" & filePath
        )

    End Function

    Private Sub SendFileToBrowser(
        ByVal physicalPath As String,
        ByVal downloadFileName As String
    )

        Dim fileInfo As New FileInfo(physicalPath)

        Response.Clear()
        Response.ClearHeaders()
        Response.ClearContent()

        Response.Buffer = False
        Response.ContentType = "application/pdf"

        Response.AddHeader(
            "X-Content-Type-Options",
            "nosniff"
        )

        Response.AddHeader(
            "Content-Disposition",
            BuildContentDisposition(downloadFileName)
        )

        Response.AddHeader(
            "Content-Length",
            fileInfo.Length.ToString()
        )

        Response.Cache.SetCacheability(
            HttpCacheability.NoCache
        )

        Response.Cache.SetNoStore()

        Response.Cache.SetExpires(
            DateTime.UtcNow.AddYears(-1)
        )

        Response.AddHeader(
            "Pragma",
            "no-cache"
        )

        Response.AddHeader(
            "Expires",
            "0"
        )

        Response.TransmitFile(physicalPath)
        Response.Flush()

        HttpContext.Current.ApplicationInstance.
            CompleteRequest()

    End Sub

    Private Function BuildContentDisposition(
        ByVal fileName As String
    ) As String

        Dim asciiFileName As String =
            ConvertToSafeAsciiFileName(fileName)

        Dim encodedFileName As String =
            Uri.EscapeDataString(fileName)

        Dim headerValue As String =
            "attachment; filename=""" &
            asciiFileName &
            """; filename*=UTF-8''" &
            encodedFileName

        Return headerValue

    End Function

    Private Function ConvertToSafeAsciiFileName(
        ByVal fileName As String
    ) As String

        If String.IsNullOrWhiteSpace(fileName) Then
            Return "WorkGuide.pdf"
        End If

        Dim builder As New StringBuilder()

        For Each character As Char In fileName

            Dim characterCode As Integer =
                AscW(character)

            If characterCode >= 32 AndAlso
               characterCode <= 126 Then

                builder.Append(character)
            Else
                builder.Append("_"c)
            End If

        Next

        Dim result As String =
            builder.ToString()

        Dim normalizedResult As String =
            result.Replace("_", "")

        normalizedResult =
            normalizedResult.Replace(".", "")

        If String.IsNullOrWhiteSpace(result) OrElse
           String.IsNullOrWhiteSpace(normalizedResult) Then

            Return "WorkGuide.pdf"
        End If

        Return result

    End Function

    Private Function CleanFileName(
        ByVal fileName As String
    ) As String

        If String.IsNullOrWhiteSpace(fileName) Then
            Return "WorkGuide.pdf"
        End If

        For Each invalidCharacter As Char In
            Path.GetInvalidFileNameChars()

            fileName =
                fileName.Replace(
                    invalidCharacter,
                    "_"c
                )

        Next

        fileName =
            fileName.Replace(
                ControlChars.Cr,
                ""
            )

        fileName =
            fileName.Replace(
                ControlChars.Lf,
                ""
            )

        fileName = fileName.Trim()

        If String.IsNullOrWhiteSpace(fileName) Then
            Return "WorkGuide.pdf"
        End If

        Return fileName

    End Function

    Private Sub InsertDownloadActivityLog(
        ByVal userID As Integer,
        ByVal brandID As Integer,
        ByVal categoryID As Integer,
        ByVal documentID As Integer,
        ByVal downloadFileName As String
    )

        Try

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim sqlConnection As SqlConnection =
                    DirectCast(
                        db.Connection,
                        SqlConnection
                    )

                Dim shouldCloseConnection As Boolean =
                    sqlConnection.State <> ConnectionState.Open

                If shouldCloseConnection Then
                    sqlConnection.Open()
                End If

                Try

                    Using command As New SqlCommand(
                        "dbo.Insert_Work_Guide_Activity_Logs",
                        sqlConnection
                    )

                        command.CommandType =
                            CommandType.StoredProcedure

                        command.Parameters.Add(
                            "@User_ID",
                            SqlDbType.Int
                        ).Value = userID

                        command.Parameters.Add(
                            "@Brand_ID",
                            SqlDbType.Int
                        ).Value = brandID

                        command.Parameters.Add(
                            "@Category_ID",
                            SqlDbType.Int
                        ).Value = categoryID

                        command.Parameters.Add(
                            "@Document_ID",
                            SqlDbType.Int
                        ).Value = documentID

                        command.Parameters.Add(
                            "@Action_Type",
                            SqlDbType.NVarChar,
                            100
                        ).Value = "2"

                        command.Parameters.Add(
                            "@Action_Details",
                            SqlDbType.NVarChar,
                            -1
                        ).Value =
                            "تم تحميل الملف: " &
                            downloadFileName

                        command.Parameters.Add(
                            "@IPAddress",
                            SqlDbType.NVarChar,
                            100
                        ).Value =
                            GetClientIPAddress()

                        command.Parameters.Add(
                            "@UserAgent",
                            SqlDbType.NVarChar,
                            -1
                        ).Value =
                            GetSafeUserAgent()

                        command.ExecuteNonQuery()

                    End Using

                Finally

                    If shouldCloseConnection AndAlso
                       sqlConnection.State =
                       ConnectionState.Open Then

                        sqlConnection.Close()
                    End If

                End Try

            End Using

        Catch ex As Exception

            'فشل تسجيل الـLog لا يمنع تحميل الملف
            System.Diagnostics.Trace.WriteLine(
                "InsertDownloadActivityLog Error: " &
                ex.ToString()
            )

        End Try

    End Sub

    Private Function GetClientIPAddress() As String

        Dim forwardedFor As String =
            Convert.ToString(
                Request.ServerVariables(
                    "HTTP_X_FORWARDED_FOR"
                )
            )

        Dim ipAddress As String = ""

        If Not String.IsNullOrWhiteSpace(
            forwardedFor
        ) Then

            Dim forwardedAddresses() As String =
                forwardedFor.Split(","c)

            If forwardedAddresses.Length > 0 Then
                ipAddress =
                    forwardedAddresses(0).Trim()
            End If

        Else

            ipAddress =
                Convert.ToString(
                    Request.ServerVariables(
                        "REMOTE_ADDR"
                    )
                )

        End If

        If String.IsNullOrWhiteSpace(ipAddress) Then
            Return ""
        End If

        If ipAddress.Length > 100 Then
            ipAddress =
                ipAddress.Substring(0, 100)
        End If

        Return ipAddress

    End Function

    Private Function GetSafeUserAgent() As String

        Dim userAgent As String =
            Convert.ToString(
                Request.UserAgent
            )

        If String.IsNullOrWhiteSpace(userAgent) Then
            Return ""
        End If

        If userAgent.Length > 4000 Then
            userAgent =
                userAgent.Substring(0, 4000)
        End If

        Return userAgent

    End Function

    Private Sub ShowAccessDenied()

        Response.Clear()
        Response.StatusCode = 403
        Response.TrySkipIisCustomErrors = True
        Response.ContentType = "text/plain"
        Response.ContentEncoding = Encoding.UTF8

        Response.Write(
            "لا تملك صلاحية تحميل هذا الملف."
        )

        HttpContext.Current.ApplicationInstance.
            CompleteRequest()

    End Sub

    Private Sub ShowFileNotFound()

        Response.Clear()
        Response.StatusCode = 404
        Response.TrySkipIisCustomErrors = True
        Response.ContentType = "text/plain"
        Response.ContentEncoding = Encoding.UTF8

        Response.Write(
            "الملف غير موجود أو تم نقله من المسار المحدد."
        )

        HttpContext.Current.ApplicationInstance.
            CompleteRequest()

    End Sub

    Private Sub ShowGeneralError()

        Response.Clear()
        Response.StatusCode = 500
        Response.TrySkipIisCustomErrors = True
        Response.ContentType = "text/plain"
        Response.ContentEncoding = Encoding.UTF8

        Response.Write(
            "حدث خطأ أثناء تحميل الملف."
        )

        HttpContext.Current.ApplicationInstance.
            CompleteRequest()

    End Sub

End Class