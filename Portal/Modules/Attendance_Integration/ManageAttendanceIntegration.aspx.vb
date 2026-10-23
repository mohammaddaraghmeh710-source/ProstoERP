Imports System.Web.UI.WebControls
Imports System.Data.SqlClient
Imports System.Linq

Public Class ManageAttendanceIntegration
    Inherits HRTypePageBase
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        chkEmailEnabled.InputAttributes("class") = "form-check-input" : chkEmailEnabled.LabelAttributes("class") = "form-check-label"
        chkEnabled.InputAttributes("class") = "form-check-input" : chkEnabled.LabelAttributes("class") = "form-check-label"
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        If Not IsPostBack Then
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                ddlBrand.DataSource = db.Select_Brands_All().Where(Function(b) b.IsActive.GetValueOrDefault() AndAlso Not b.IsDeleted.GetValueOrDefault()).OrderBy(Function(b) b.Title_Ar).ToList()
                ddlBrand.DataValueField = "ID" : ddlBrand.DataTextField = "Title_Ar" : ddlBrand.DataBind()
            End Using
            ddlBrand.Items.Insert(0, New ListItem("اختر العلامة التجارية", "0"))
            ResetConnections()
            chkEnabled.Checked = True
            Dim brand As Integer
            If Integer.TryParse(Request.QueryString("brand"),brand) AndAlso ddlBrand.Items.FindByValue(brand.ToString()) IsNot Nothing Then
                ddlBrand.SelectedValue=brand.ToString() : BrandChanged(Me,EventArgs.Empty)
            End If
        End If
    End Sub
    Protected Sub BrandChanged(sender As Object, e As EventArgs)
        litMessage.Text = "" : txtApiUser.Text = "" : txtBioUser.Text = "" : txtApiPassword.Text = "" : txtBioPassword.Text = "" : txtHrPassword.Text = "" : ViewState("SettingsVersion") = Nothing : chkEnabled.Checked = True
        ResetConnections()
        txtSenderEmail.Text = "" : txtSmtpPassword.Text = "" : litEmailMessage.Text = "" : chkEmailEnabled.Checked = False : ViewState("EmailVersion") = Nothing
        If ddlBrand.SelectedValue = "0" Then Return
        Try
            LoadSettings()
        Catch ex As Exception
            ShowMessage(litMessage, AttendanceData.ErrorText(ex))
        End Try
    End Sub
    Private Sub ResetConnections()
        txtApiUrl.Text = System.Configuration.ConfigurationManager.AppSettings("AttendanceApi.BaseUrl")
        If String.IsNullOrWhiteSpace(txtApiUrl.Text) Then txtApiUrl.Text = "http://92.253.126.181:1098/"
        txtBioUrl.Text = "http://127.0.0.1:8089/"
        txtHrUrl.Text = "" : txtHrUser.Text = "" : txtHrPassword.Text = ""
        ViewState("HasHrPassword") = False : ViewState("NeedsHrSecrets") = False
    End Sub
    Private Sub LoadSettings()
        LoadEmailSettings()
        Dim data = AttendanceData.Store().Metadata(SessionManager.GetInstance.Users.UserID, CInt(ddlBrand.SelectedValue))
        If data.Rows.Count = 0 Then Return
        Dim row = data.Rows(0)
        txtApiUser.Text = CStr(row("ApiUsername"))
        txtApiUrl.Text = CStr(row("ApiUrl")) : txtBioUrl.Text = CStr(row("BioTimeUrl"))
        txtHrUrl.Text = Convert.ToString(row("HrUrl"))
        ViewState("HasHrPassword") = CBool(row("HasHrPassword"))
        ViewState("NeedsHrSecrets") = False
        If Not Convert.IsDBNull(row("HrUsername")) Then
            Try
                txtHrUser.Text = Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("HrUsername"), Byte()))
            Catch ex As System.Security.Cryptography.CryptographicException
                txtHrUser.Text = "" : ViewState("NeedsHrSecrets") = True
            End Try
        End If
        chkEnabled.Checked = CBool(row("Enabled"))
        ViewState("SettingsVersion") = Convert.ToBase64String(DirectCast(row("Version"), Byte()))
        ViewState("NeedsSecrets") = False
        Try
            txtBioUser.Text = Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("BioUsername"), Byte()))
        Catch ex As System.Security.Cryptography.CryptographicException
            txtBioUser.Text = "" : ViewState("NeedsSecrets") = True
            ShowMessage(litMessage, "تعذّر فتح البيانات المحفوظة على هذا الخادم. أعد إدخال اسم مستخدم BioTime وكلمتي المرور.")
        End Try
    End Sub
    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        RenderEmailPassword()
        If ddlBrand.SelectedValue = "0" OrElse ViewState("SettingsVersion") Is Nothing Then Return
        Try
            Dim data = AttendanceData.Store().Query("dbo.AttendanceIntegration_AdminSecrets", New SqlParameter("@Actor", SessionManager.GetInstance.Users.UserID), New SqlParameter("@BrandID", CInt(ddlBrand.SelectedValue)))
            If data.Rows.Count <> 1 Then Return
            Dim row = data.Rows(0)
            ' Never combine a stale edit with credentials from a newer settings version.
            If Convert.ToBase64String(DirectCast(row("Version"), Byte())) <> CStr(ViewState("SettingsVersion")) Then Return
            RenderPassword(txtApiPassword, row("ApiPassword"))
            RenderPassword(txtBioPassword, row("BioPassword"))
            RenderPassword(txtHrPassword, row("HrPassword"))
        Catch ex As Exception
            ShowMessage(litMessage, "تعذّر عرض كلمات المرور المحفوظة على هذا الخادم.")
        End Try
    End Sub
    Private Sub RenderPassword(control As TextBox, encrypted As Object)
        control.Attributes.Remove("value")
        If Not Convert.IsDBNull(encrypted) Then control.Attributes("value") = Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(encrypted, Byte()))
    End Sub
    Protected Sub SaveSettings(sender As Object, e As EventArgs)
        Try
            If ddlBrand.SelectedValue = "0" OrElse String.IsNullOrWhiteSpace(txtApiUser.Text) OrElse String.IsNullOrWhiteSpace(txtBioUser.Text) Then
                ShowMessage(litMessage, "اختر العلامة التجارية وأدخل اسمي المستخدم.") : Return
            End If
            Dim version As Byte() = If(ViewState("SettingsVersion") Is Nothing, Nothing, Convert.FromBase64String(CStr(ViewState("SettingsVersion"))))
            If (version Is Nothing OrElse Convert.ToBoolean(ViewState("NeedsSecrets"))) AndAlso (String.IsNullOrWhiteSpace(txtApiPassword.Text) OrElse String.IsNullOrWhiteSpace(txtBioPassword.Text)) Then
                ShowMessage(litMessage, "أدخل كلمتي المرور عند الإعداد لأول مرة أو إعادة إعداد التكامل على خادم آخر.") : Return
            End If
            If (txtApiPassword.Text.Length > 0 AndAlso String.IsNullOrWhiteSpace(txtApiPassword.Text)) OrElse (txtBioPassword.Text.Length > 0 AndAlso String.IsNullOrWhiteSpace(txtBioPassword.Text)) Then
                ShowMessage(litMessage, "لا يمكن أن تتكون كلمة المرور من مسافات فقط.") : Return
            End If
            Try
                txtApiUrl.Text = Prosto_ERP_ClassLibrary.AttendanceIntegration.NormalizeUrl(txtApiUrl.Text)
                txtBioUrl.Text = Prosto_ERP_ClassLibrary.AttendanceIntegration.NormalizeUrl(txtBioUrl.Text, True)
                If Not String.IsNullOrWhiteSpace(txtHrUrl.Text) Then txtHrUrl.Text = Prosto_ERP_ClassLibrary.AttendanceIntegration.NormalizeUrl(txtHrUrl.Text)
            Catch ex As ArgumentException
                ShowMessage(litMessage, "أدخل عناوين HTTP أو HTTPS صالحة دون بيانات دخول أو query أو fragment؛ عنوان BioTime يجب أن يكون عنوان النظام الأساسي.") : Return
            End Try
            If String.IsNullOrWhiteSpace(txtHrUrl.Text) Then
                If Not String.IsNullOrWhiteSpace(txtHrUser.Text) OrElse txtHrPassword.Text.Length > 0 Then ShowMessage(litMessage, "أدخل URL لنظام HR مع بيانات دخوله.") : Return
            ElseIf String.IsNullOrWhiteSpace(txtHrUser.Text) OrElse ((Not Convert.ToBoolean(ViewState("HasHrPassword")) OrElse Convert.ToBoolean(ViewState("NeedsHrSecrets"))) AndAlso String.IsNullOrWhiteSpace(txtHrPassword.Text)) Then
                ShowMessage(litMessage, "أدخل اسم مستخدم HR وكلمة المرور عند إعداد الاتصال لأول مرة.") : Return
            End If
            If txtHrPassword.Text.Length > 0 AndAlso String.IsNullOrWhiteSpace(txtHrPassword.Text) Then ShowMessage(litMessage, "كلمة مرور HR لا يمكن أن تتكون من مسافات فقط.") : Return
            AttendanceData.Store().Save(SessionManager.GetInstance.Users.UserID, CInt(ddlBrand.SelectedValue), txtApiUser.Text.Trim(), txtApiPassword.Text, txtBioUser.Text.Trim(), txtBioPassword.Text, chkEnabled.Checked, version, txtApiUrl.Text, txtBioUrl.Text, txtHrUrl.Text.Trim(), txtHrUser.Text.Trim(), txtHrPassword.Text)
            LoadSettings()
            ShowMessage(litMessage, "تم حفظ إعدادات API.", True)
            SystemAdministrationUI.Complete(Me)
        Catch ex As SqlException
            System.Diagnostics.Trace.TraceWarning("Attendance settings SQL failed ({0}).", ex.Number)
            ShowMessage(litMessage, If(ex.Number = 2601 OrElse ex.Number = 2627, "اسم المستخدم للـAPI مستخدم في علامة تجارية أخرى.", If(ex.Number = 51702, "تغيرت الإعدادات بواسطة مستخدم آخر. أعد اختيار العلامة التجارية قبل الحفظ.", "تعذّر حفظ الإعدادات. تحقق من تجهيز قاعدة البيانات والصلاحيات.")))
        Catch ex As Exception
            ShowMessage(litMessage, AttendanceData.ErrorText(ex))
        Finally
            txtApiPassword.Text = "" : txtBioPassword.Text = "" : txtHrPassword.Text = ""
        End Try
    End Sub
    Private Sub LoadEmailSettings()
        Dim data = AttendanceData.Store().Query("dbo.EmailNotification_Admin", New SqlParameter("@Actor", SessionManager.GetInstance.Users.UserID), New SqlParameter("@BrandID", CInt(ddlBrand.SelectedValue)))
        If data.Rows.Count = 0 Then Return
        txtSenderEmail.Text = CStr(data.Rows(0)("SenderEmail")) : chkEmailEnabled.Checked = CBool(data.Rows(0)("Enabled"))
        ViewState("EmailVersion") = Convert.ToBase64String(DirectCast(data.Rows(0)("Version"), Byte()))
    End Sub
    Private Sub RenderEmailPassword()
        txtSmtpPassword.Attributes.Remove("value")
        If ddlBrand.SelectedValue = "0" OrElse ViewState("EmailVersion") Is Nothing Then Return
        Try
            Dim data = AttendanceData.Store().Query("dbo.EmailNotification_AdminSecret", New SqlParameter("@Actor", SessionManager.GetInstance.Users.UserID), New SqlParameter("@BrandID", CInt(ddlBrand.SelectedValue)))
            If data.Rows.Count = 1 AndAlso Convert.ToBase64String(DirectCast(data.Rows(0)("Version"), Byte())) = CStr(ViewState("EmailVersion")) Then RenderPassword(txtSmtpPassword, data.Rows(0)("AppPassword"))
        Catch ex As Exception
            ShowMessage(litEmailMessage, "تعذّر فتح App Password على هذا الخادم؛ أعد إدخاله عند الحفظ.")
        End Try
    End Sub
    Protected Sub SaveEmailSettings(sender As Object, e As EventArgs)
        Try
            If ddlBrand.SelectedValue = "0" OrElse String.IsNullOrWhiteSpace(txtSenderEmail.Text) Then ShowMessage(litEmailMessage, "اختر العلامة التجارية وأدخل بريد Gmail المرسل.") : Return
            Dim address As New System.Net.Mail.MailAddress(txtSenderEmail.Text.Trim())
            If address.Address <> txtSenderEmail.Text.Trim() OrElse txtSenderEmail.Text.Contains(vbCr) OrElse txtSenderEmail.Text.Contains(vbLf) Then Throw New FormatException()
            Dim password = txtSmtpPassword.Text.Replace(" ", "").Trim()
            If txtSmtpPassword.Text.Length > 0 AndAlso password.Length = 0 Then ShowMessage(litEmailMessage, "App Password لا يمكن أن يتكون من مسافات.") : Return
            Dim version As Byte() = If(ViewState("EmailVersion") Is Nothing, Nothing, Convert.FromBase64String(CStr(ViewState("EmailVersion"))))
            AttendanceData.Store().Query("dbo.EmailNotification_Save", New SqlParameter("@Actor", SessionManager.GetInstance.Users.UserID), New SqlParameter("@BrandID", CInt(ddlBrand.SelectedValue)),
                New SqlParameter("@SenderEmail", address.Address), New SqlParameter("@AppPassword", SqlDbType.VarBinary, -1) With {.Value = If(password.Length = 0, CType(DBNull.Value, Object), Prosto_ERP_ClassLibrary.AttendanceIntegration.Protect(password))},
                New SqlParameter("@Enabled", chkEmailEnabled.Checked), New SqlParameter("@Version", SqlDbType.Binary, 8) With {.Value = If(version Is Nothing, CType(DBNull.Value, Object), version)})
            LoadEmailSettings() : ShowMessage(litEmailMessage, "تم حفظ إعدادات Gmail لهذه العلامة التجارية.", True)
            SystemAdministrationUI.Complete(Me)
        Catch ex As FormatException
            ShowMessage(litEmailMessage, "أدخل عنوان بريد إلكتروني واحدًا صالحًا دون اسم عرض.")
        Catch ex As SqlException
            ShowMessage(litEmailMessage, If(ex.Number = 51802, "تغيّرت إعدادات البريد. أعد اختيار العلامة التجارية.", If(ex.Number = 51801, "أدخل App Password عند التفعيل لأول مرة أو تغيير البريد.", "تعذّر حفظ إعدادات البريد. تحقق من الصلاحيات وتجهيز قاعدة البيانات.")))
        Catch ex As Exception
            ShowMessage(litEmailMessage, "تعذّر حفظ إعدادات البريد.")
        Finally
            txtSmtpPassword.Text = ""
        End Try
    End Sub
End Class
