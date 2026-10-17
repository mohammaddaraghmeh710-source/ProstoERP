Imports System
Imports System.Configuration
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

Public Class ForgotPassword
    Inherits System.Web.UI.Page
    Protected Overrides Sub OnInit(e As EventArgs)
        ViewStateUserKey = Session.SessionID & ":password-reset"
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        MyBase.OnInit(e)
    End Sub
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ClearReset()
        End If
    End Sub
    Private Sub ClearReset()
        Session.Remove("ResetChallenge") : Session.Remove("ResetPermission")
        Session.Remove("ResetEmployee") : Session.Remove("ResetMail") : Session.Remove("ResetResendUtc")
    End Sub
    Protected Sub StartAgain(sender As Object, e As EventArgs)
        ClearReset() : wizard.ActiveViewIndex = 0 : pnlAlert.Visible = False
    End Sub
    Private Sub ShowError(message As String)
        lblAlert.Text = Server.HtmlEncode(message) : pnlAlert.Visible = True
    End Sub
    Protected Sub RequestCode(sender As Object, e As EventArgs)
        pnlAlert.Visible = False
        RegisterAsyncTask(New PageAsyncTask(Async Function()
            Try
                Dim employee As Integer
                Dim value = If(wizard.ActiveViewIndex = 1, Convert.ToString(Session("ResetEmployee")), txtEmployee.Text.Trim())
                If Not Integer.TryParse(value, employee) OrElse employee <= 0 Then
                    ShowError("أدخل رقمًا وظيفيًا صحيحًا.") : Return
                End If
                If Session("ResetResendUtc") IsNot Nothing AndAlso DateTime.UtcNow < DirectCast(Session("ResetResendUtc"), DateTime) Then
                    ShowError("انتظر دقيقة قبل إعادة إرسال الرمز.") : Return
                End If
                Dim result = Await CallAPI("RequestPasswordReset", New With {.EmployeeNumber = employee})
                If Not CBool(result("Success")) Then
                    ShowError(CStr(result("Error")("Message"))) : Return
                End If
                Session("ResetChallenge") = CStr(result("Data")("ChallengeID"))
                Session("ResetEmployee") = employee : Session("ResetMail") = CStr(result("Data")("MaskedEmail"))
                Session("ResetResendUtc") = DateTime.UtcNow.AddSeconds(60)
                Session.Remove("ResetPermission")
                lblEmail.Text = Server.HtmlEncode(CStr(Session("ResetMail"))) : wizard.ActiveViewIndex = 1
            Catch
                ShowError("تعذّر الاتصال بخدمة الاستعادة. يرجى المحاولة لاحقًا أو التواصل مع مدير النظام.")
            End Try
        End Function))
    End Sub
    Protected Sub VerifyCode(sender As Object, e As EventArgs)
        pnlAlert.Visible = False
        RegisterAsyncTask(New PageAsyncTask(Async Function()
            Try
                If wizard.ActiveViewIndex <> 1 OrElse Session("ResetChallenge") Is Nothing Then
                    ShowError("ابدأ بطلب رمز تحقق جديد.") : Return
                End If
                Dim result = Await CallAPI("VerifyPasswordResetOTP", New With {.ChallengeID = CStr(Session("ResetChallenge")), .OTP = txtOTP.Text.Trim()})
                txtOTP.Text = ""
                If Not CBool(result("Success")) Then
                    ShowError(CStr(result("Error")("Message"))) : Return
                End If
                Session("ResetPermission") = CStr(result("Data")("ResetToken")) : wizard.ActiveViewIndex = 2
            Catch
                ShowError("تعذّر التحقق حاليًا. يرجى المحاولة لاحقًا.")
            End Try
        End Function))
    End Sub
    Protected Sub SavePassword(sender As Object, e As EventArgs)
        pnlAlert.Visible = False
        RegisterAsyncTask(New PageAsyncTask(Async Function()
            Try
                If wizard.ActiveViewIndex <> 2 OrElse Session("ResetPermission") Is Nothing Then
                    ShowError("تحقق من الرمز أولًا.") : Return
                End If
                If String.IsNullOrWhiteSpace(txtNewPassword.Text) OrElse txtNewPassword.Text.Length < 8 OrElse txtNewPassword.Text.Length > 128 OrElse txtNewPassword.Text <> txtConfirm.Text Then
                    ShowError("أدخل كلمة مرور من 8 إلى 128 حرفًا وتأكد من تطابق التأكيد.") : Return
                End If
                Dim result = Await CallAPI("ResetPassword", New With {.ResetToken = CStr(Session("ResetPermission")), .NewPassword = txtNewPassword.Text})
                txtNewPassword.Text = "" : txtConfirm.Text = ""
                If Not CBool(result("Success")) Then
                    ShowError(CStr(result("Error")("Message"))) : Return
                End If
                ClearReset() : wizard.ActiveViewIndex = 3
            Catch
                ShowError("تعذّر حفظ كلمة المرور. يرجى المحاولة لاحقًا.")
            End Try
        End Function))
    End Sub
    Private Async Function CallAPI(route As String, data As Object) As Task(Of JObject)
        Dim origin = New Uri(ConfigurationManager.AppSettings("PasswordReset.ApiBaseUrl"))
        If origin.Scheme <> "https" AndAlso Not (origin.Scheme = "http" AndAlso origin.IsLoopback) Then Throw New ConfigurationErrorsException("Reset API must use HTTPS.")
        Using handler As New HttpClientHandler With {.AllowAutoRedirect = False, .UseCookies = False}, client As New HttpClient(handler)
            client.Timeout = TimeSpan.FromSeconds(40)
            Dim pair = ConfigurationManager.AppSettings("PasswordReset.BasicUsername") & ":" & ConfigurationManager.AppSettings("PasswordReset.BasicPassword")
            client.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes(pair)))
            Using body As New StringContent(Newtonsoft.Json.JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json")
                Using response = Await client.PostAsync(New Uri(origin, "api/Users/" & route), body)
                    Return JObject.Parse(Await response.Content.ReadAsStringAsync())
                End Using
            End Using
        End Using
    End Function
End Class
