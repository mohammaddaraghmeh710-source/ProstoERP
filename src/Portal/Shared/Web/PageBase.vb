Imports System.IO
Imports System.Net
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Net.Mail

Public Class PageBase
    Inherits Page

    Protected Overrides Sub OnPreInit(e As EventArgs)
        Dim login = String.Equals(Request.AppRelativeCurrentExecutionFilePath, "~/Login.aspx",
                                  StringComparison.OrdinalIgnoreCase)
        Dim employee = SessionManager.GetInstance.Users
        If employee IsNot Nothing AndAlso employee.UserType = 7 AndAlso Not login Then
            Session.Clear()
            Session.Abandon()
            Response.Redirect("~/Login.aspx")
            Return
        End If
        If _
            CustomerPortalData.Current IsNot Nothing AndAlso Not login AndAlso
            Not _
            Request.AppRelativeCurrentExecutionFilePath.StartsWith("~/CustomerPortal/",
                                                                   StringComparison.OrdinalIgnoreCase) Then
            Throw New HttpException(403, "هذه الخدمة مخصصة للموظفين.")
        End If
        SystemAdministrationUI.Prepare(Me)
        MyBase.OnPreInit(e)
    End Sub


    Public Function CrmUserId() As Integer
        Return SessionManager.GetInstance.Users.UserID
    End Function

    Public Property PidOfSession As Integer
    Public Property PIDofForEach As Integer

    Public Sub CrmSessionFound()
        If (SessionManager.GetInstance.Users) Is Nothing Or "0" Then
            Session.Abandon()
            Session.Clear()
            Response.Redirect("~/Login.aspx")
        Else
            ClearFileSession()
            PidOfSession = SessionManager.GetInstance.Users.UserID

        End If
    End Sub


    Public Sub ClearFileSession()
        Session("FileList") = Nothing
        Session("InspectionMethodVideo") = Nothing
        Session("EvaluationMethodVideoList") = Nothing
        Session("WorkingMethodVideoList") = Nothing
        Session("FileEnglishList") = Nothing
    End Sub

    Public Sub FillPrivilegingForAdmin()
        Dim path As String = Request.Url.Authority
        Dim fullurl As String = Request.Url.AbsoluteUri
        fullurl = fullurl.Replace("http://" & path, "")
        Dim url As String = Request.Url.AbsolutePath
        'Using db As New ProstoClassLibrary.ProstoDataClassesDataContext
        Dim PID As Integer = Session("LogIn")
        If PID = 0 Or Nothing Then
            Response.Redirect("~/Login.aspx")
        End If
        'End Using
    End Sub

    Public Function SaveFilesFromSession() As Dictionary(Of String, String)

        Dim files = New Dictionary(Of String, String)

        If Not IsNothing(Session("FileList")) Then
            Dim fileList = DirectCast(Session("FileList"), List(Of FileAttribute))

            For Each item In fileList
                Dim fileNewName = Guid.NewGuid().ToString() + item.Type
                Dim picPath = Server.MapPath(BlogFilePath) + fileNewName
                Using fileStream As FileStream = File.Create(picPath, item.FileByte.Length)
                    fileStream.Write(item.FileByte, 0, item.FileByte.Length)

                    Dim headerImage = BlogFilePath + fileNewName

                    files.Add(headerImage, Path.GetFileNameWithoutExtension(item.NameFile))
                End Using

            Next
        End If
        Return files
    End Function

    Public Sub SaveFileOnSession(fileNmae As String, fileType As String, contentsByte As Byte())
        'Try
        If IsNothing(Session("FileList")) Then
            Session("FileList") = New List(Of FileAttribute)
        End If
        Dim fileList = DirectCast(Session("FileList"), List(Of FileAttribute))
        fileList.Add(New FileAttribute With {.Type = fileType, .FileByte = contentsByte, .NameFile = fileNmae})
        'Catch ex As Exception
        '    Dim UploaderError As String = ex.Message
        'End Try
    End Sub

    Public Function SaveInspectionMethodVideoFromSession() As Dictionary(Of String, String)

        Dim filesEnglish = New Dictionary(Of String, String)

        If Not IsNothing(Session("InspectionMethodVideo")) Then
            Dim fileList = DirectCast(Session("InspectionMethodVideo"), List(Of InspectionMethodVideoAttribute))

            For Each item In fileList
                Dim fileNewName = Guid.NewGuid().ToString() + item.Type
                Dim picPath = Server.MapPath(BlogFilePath) + fileNewName
                Using fileStream As FileStream = File.Create(picPath, item.FileByte.Length)
                    fileStream.Write(item.FileByte, 0, item.FileByte.Length)

                    Dim headerImage = BlogFilePath + fileNewName

                    filesEnglish.Add(headerImage, Path.GetFileNameWithoutExtension(item.NameFile))
                End Using

            Next
        End If
        Return filesEnglish
    End Function

    Public Sub SaveInspectionMethodVideoOnSession(fileNmae As String, fileType As String, contentsByte As Byte())
        Try
            If IsNothing(Session("InspectionMethodVideo")) Then
                Session("InspectionMethodVideo") = New List(Of InspectionMethodVideoAttribute)
            End If
            Dim fileList = DirectCast(Session("InspectionMethodVideo"), List(Of InspectionMethodVideoAttribute))
            fileList.Add(
                New InspectionMethodVideoAttribute _
                            With {.Type = fileType, .FileByte = contentsByte, .NameFile = fileNmae})
        Catch ex As Exception
        End Try
    End Sub

    Public Function SaveWorkingMethodVideoFromSession() As Dictionary(Of String, String)

        Dim files = New Dictionary(Of String, String)

        If Not IsNothing(Session("WorkingMethodVideoList")) Then
            Dim WorkingMethodVideoList = DirectCast(Session("WorkingMethodVideoList"), List(Of FileAttribute))

            For Each item In WorkingMethodVideoList
                Dim fileNewName = Guid.NewGuid().ToString() + item.Type
                Dim picPath = Server.MapPath(BlogFilePath) + fileNewName
                Using fileStream As FileStream = File.Create(picPath, item.FileByte.Length)
                    fileStream.Write(item.FileByte, 0, item.FileByte.Length)

                    Dim headerImage = BlogFilePath + fileNewName

                    files.Add(headerImage, Path.GetFileNameWithoutExtension(item.NameFile))
                End Using

            Next
        End If
        Return files
    End Function

    Public Sub SaveWorkingMethodVideoOnSession(fileNmae As String, fileType As String, contentsByte As Byte())
        'Try
        If IsNothing(Session("WorkingMethodVideoList")) Then
            Session("WorkingMethodVideoList") = New List(Of FileAttribute)
        End If
        Dim WorkingMethodVideoList = DirectCast(Session("WorkingMethodVideoList"), List(Of FileAttribute))
        WorkingMethodVideoList.Add(
            New FileAttribute _
                                      With {.Type = fileType, .FileByte = contentsByte, .NameFile = fileNmae})
        'Catch ex As Exception
        '    Dim UploaderError As String = ex.Message
        'End Try
    End Sub

    Public Function SaveEvaluationMethodVideoFromSession() As Dictionary(Of String, String)

        Dim files = New Dictionary(Of String, String)

        If Not IsNothing(Session("EvaluationMethodVideoList")) Then
            Dim EvaluationMethodVideoList = DirectCast(Session("EvaluationMethodVideoList"), List(Of FileAttribute))

            For Each item In EvaluationMethodVideoList
                Dim fileNewName = Guid.NewGuid().ToString() + item.Type
                Dim picPath = Server.MapPath(BlogFilePath) + fileNewName
                Using fileStream As FileStream = File.Create(picPath, item.FileByte.Length)
                    fileStream.Write(item.FileByte, 0, item.FileByte.Length)

                    Dim headerImage = BlogFilePath + fileNewName

                    files.Add(headerImage, Path.GetFileNameWithoutExtension(item.NameFile))
                End Using

            Next
        End If
        Return files
    End Function

    Public Sub SaveEvaluationMethodVideoOnSession(fileNmae As String, fileType As String, contentsByte As Byte())
        'Try
        If IsNothing(Session("EvaluationMethodVideoList")) Then
            Session("EvaluationMethodVideoList") = New List(Of FileAttribute)
        End If
        Dim EvaluationMethodVideoList = DirectCast(Session("EvaluationMethodVideoList"), List(Of FileAttribute))
        EvaluationMethodVideoList.Add(
            New FileAttribute _
                                         With {.Type = fileType, .FileByte = contentsByte, .NameFile = fileNmae})
        'Catch ex As Exception
        '    Dim UploaderError As String = ex.Message
        'End Try
    End Sub


    Public Function SaveFilesEnglishFromSession() As Dictionary(Of String, String)

        Dim filesEnglish = New Dictionary(Of String, String)

        If Not IsNothing(Session("FileEnglishList")) Then
            Dim fileList = DirectCast(Session("FileEnglishList"), List(Of FileEnglishAttribute))

            For Each item In fileList
                Dim fileNewName = Guid.NewGuid().ToString() + item.Type
                Dim picPath = Server.MapPath(BlogFilePath) + fileNewName
                Using fileStream As FileStream = File.Create(picPath, item.FileByte.Length)
                    fileStream.Write(item.FileByte, 0, item.FileByte.Length)

                    Dim headerImage = BlogFilePath + fileNewName

                    filesEnglish.Add(headerImage, Path.GetFileNameWithoutExtension(item.NameFile))
                End Using

            Next
        End If
        Return filesEnglish
    End Function

    Public Sub SaveFileEnglishOnSession(fileNmae As String, fileType As String, contentsByte As Byte())
        Try
            If IsNothing(Session("FileEnglishList")) Then
                Session("FileEnglishList") = New List(Of FileEnglishAttribute)
            End If
            Dim fileList = DirectCast(Session("FileEnglishList"), List(Of FileEnglishAttribute))
            fileList.Add(
                New FileEnglishAttribute _
                            With {.Type = fileType, .FileByte = contentsByte, .NameFile = fileNmae})
        Catch ex As Exception
        End Try
    End Sub

    Public Sub SaveManufacturingEquation_Items(RefID As Int32, Identification_Number As String,
                                               Item_Description As String, Model As String, Description As String,
                                               Unit As String, Quantity As Int32)
        Try
            If IsNothing(Session("ManufacturingEquation_ItemsList")) Then
                Session("ManufacturingEquation_ItemsList") = New List(Of ManufacturingEquation_Items)
            End If
            Dim DataList = DirectCast(Session("ManufacturingEquation_ItemsList"), List(Of ManufacturingEquation_Items))
            DataList.Add(
                New ManufacturingEquation_Items _
                            With {.RefID = RefID, .Identification_Number = Identification_Number,
                            .Item_Description = Item_Description, .Model = Model, .Description = Description,
                            .Unit = Unit, .Quantity = Quantity})
        Catch ex As Exception
        End Try
    End Sub

    Protected Sub SendEmail(Email As String, BodyMessage As String)
        Dim message As New MailMessage()
        Dim smtpClient As New SmtpClient()
        Dim msg As String = String.Empty
        Try

            Dim userName = System.Configuration.ConfigurationManager.AppSettings("LegacySmtp.Username")
            Dim password = System.Configuration.ConfigurationManager.AppSettings("LegacySmtp.Password")
            Dim msg1 = New MailMessage()
            Dim msg2 = New MailMessage()

            msg1.To.Add(New MailAddress(Email))
            msg1.From = New MailAddress(userName)

            msg1.Subject = "Notification message"
            msg1.Body = BodyMessage

            msg1.IsBodyHtml = True
            Dim client = New SmtpClient()
            client.Host = "10.0.5.11"
            client.Credentials = New NetworkCredential(userName, password)
            client.Port = 25
            'client.EnableSsl = True
            client.Send(msg1)
        Catch ex As Exception
            'lblError.Text = ex.Message
        End Try
    End Sub

    Protected Sub SendSMS(phone As String, Message As String)
        Try
            Dim result = False
            Dim credentials = Convert.ToBase64String(Encoding.ASCII.GetBytes(String.Format("{0}:{1}",
                                                                                           "UserName",
                                                                                           "Password")))
            Using client2 = New HttpClient()
                client2.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Basic", credentials)
                Dim values = New Dictionary(Of String, String)() From {
                        {"mobile_number", phone},
                        {"msg", Message},
                        {"from", "Prosto"},
                        {"tag", "1"}
                        }
                Dim content = New FormUrlEncodedContent(values)
                Dim response2 As HttpResponseMessage =
                        client2.PostAsync("https://bulksms.arabiacell.net/index.php/api/send_bulk_sms_multi_info/send",
                                          content).Result
                Dim responseString = response2.Content.ReadAsStringAsync()
                If response2.IsSuccessStatusCode Then
                    result = True
                End If
            End Using
        Catch ex As Exception
            'lblError.Text = ex.Message
        End Try
    End Sub

    Public Enum StateOfAddTeam
        Unchanged = 0
        Added = 1
        Modified = 2
        Deleted = 3
        Removed = 4
    End Enum

    Public Sub WriteErrorMessage(ex As String, Name As String)

        Try
            Dim fullpath12 As String = HttpRuntime.AppDomainAppPath
            fullpath12 = fullpath12 & Convert.ToString("Logs/Errors/PageName.txt")
            fullpath12 = fullpath12.Replace("/", "\")
            Dim path As String = fullpath12

            If True Then
                Dim fs = New FileStream(path, FileMode.OpenOrCreate)
                Dim str = New StreamWriter(fs)
                str.BaseStream.Seek(0, SeekOrigin.[End])
                str.Write("New  " & Name & " on date time  ")
                str.WriteLine(DateTime.Now.ToLongTimeString() & " " + DateTime.Now.ToLongDateString())
                str.WriteLine(ex)
                str.Flush()
                str.Close()
                fs.Close()
            End If
        Catch exc As Exception

        End Try
    End Sub
End Class


