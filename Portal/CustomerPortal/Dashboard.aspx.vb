Imports System.Data
Imports System.Linq
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public Class CustomerDashboard
    Inherits CustomerPortalPage
    Private openPanel As String
    Private Shared ReadOnly ProfileFields As String() = {"Name_AR", "Name_EN", "Phone", "Email", "Address", "Country", "Website", "Registration_Number"}
    Private Shared ReadOnly ContactFields As String() = {"Name_AR", "Name_EN", "Job_Title", "Job_Title_EN", "Phone", "Email", "Gender"}
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        Form.Enctype = "multipart/form-data"
    End Sub
    Private Function Field(name As String) As Control
        Return Master.FindControl("ContentPlaceHolder1").FindControl(name)
    End Function
    Private Function Rows(Optional section As String = "profile") As DataTable
        Return CustomerPortalData.CustomerQuery("dbo.Customer_Dashboard", CustomerPortalData.P("@Section", SqlDbType.VarChar, section, 16))
    End Function
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LogRead("dashboard-view")
            Dim requestedCircular = Request.Unvalidated.QueryString("circular")
            If requestedCircular IsNot Nothing Then
                Dim circularID As Integer
                If Not Integer.TryParse(requestedCircular, circularID) OrElse circularID <= 0 Then
                    Response.StatusCode = 400
                    Response.TrySkipIisCustomErrors = True
                    litMessage.Text = AlertMarkup("رقم التعميم غير صحيح.", True)
                Else
                    customerCircularReader.InitialID = circularID
                End If
            End If
        End If
    End Sub
    Private Sub LogRead(action As String, Optional recordID As Integer? = Nothing)
        CustomerPortalData.CustomerQuery("dbo.Customer_LogActivity", CustomerPortalData.P("@Action", SqlDbType.VarChar, action, 30), CustomerPortalData.P("@RecordID", SqlDbType.Int, recordID))
    End Sub
    Protected Overrides Sub OnPreRender(e As EventArgs)
        Dim profile = Rows().Rows(0)
        welcomeName.Text = Convert.ToString(profile("Name_AR")) : customerName.Text = welcomeName.Text
        CustomerPortalData.Current.Name = welcomeName.Text
        DirectCast(Master.FindControl("litCustomer"), Literal).Text = Server.HtmlEncode(welcomeName.Text)
        typeName.Text = DisplayValue(profile("TypeName")) : brandName.Text = DisplayValue(profile("BrandName")) : branchName.Text = DisplayValue(profile("BranchName"))
        phone.Text = DisplayValue(profile("Phone")) : email.Text = DisplayValue(profile("Email")) : contactCount.Text = Convert.ToString(profile("ContactCount"))
        Dim data = Rows("contacts") : contacts.DataSource = data : contacts.DataBind() : emptyContacts.Visible = data.Rows.Count = 0
        Dim news = NewsData.CustomerItems()
        Dim newsBrands = CustomerPortalData.CustomerQuery("dbo.Customer_ContentBrands")
        circularBrandFilter.DataSource = newsBrands : circularBrandFilter.DataTextField = "Name_AR" : circularBrandFilter.DataValueField = "BrandID" : circularBrandFilter.DataBind()
        circularBrandFilter.Items.Insert(0, New ListItem("جميع العلامات التجارية", ""))
        Dim circularData = CustomerPortalData.CustomerQuery("dbo.Customer_Circulars")
        customerCirculars.DataSource = circularData : customerCirculars.DataBind()
        circularCount.Text = circularData.Rows.Count.ToString("N0") & " تعميم"
        Dim newsBrandFilter = DirectCast(Field("newsBrandFilter"), DropDownList)
        newsBrandFilter.DataSource = newsBrands : newsBrandFilter.DataTextField = "Name_AR" : newsBrandFilter.DataValueField = "BrandID" : newsBrandFilter.DataBind()
        newsBrandFilter.Items.Insert(0, New ListItem("جميع العلامات التجارية", ""))
        DirectCast(Field("brandNews"), Repeater).DataSource = news : DirectCast(Field("brandNews"), Repeater).DataBind()
        DirectCast(Field("newsIndicators"), Repeater).DataSource = news : DirectCast(Field("newsIndicators"), Repeater).DataBind()
        Field("newsEmpty").Visible = news.Rows.Count = 0
        Field("newsCarouselBody").Visible = news.Rows.Count > 0
        Field("newsIndicators").Visible = news.Rows.Count > 1
        If openPanel IsNot Nothing Then
            Dim kind = If(openPanel = "contactDeleteModal", "Modal", "Offcanvas")
            ClientScript.RegisterStartupScript(Me.GetType(), "customer-editor", "document.addEventListener('DOMContentLoaded',function(){bootstrap." & kind & ".getOrCreateInstance(document.getElementById('" & openPanel & "')).show();},{once:true});", True)
        End If
        MyBase.OnPreRender(e)
    End Sub
    Protected Sub EditProfile_Click(sender As Object, e As EventArgs)
        Try
            Dim row = Rows("editor").Rows(0)
            For Each name In ProfileFields
                DirectCast(Field("p_" & name), TextBox).Text = Convert.ToString(row(name))
            Next
            ViewState("ProfileVersion") = row("Row_Version")
            logoPreview.ImageUrl = "Logo.aspx?v=" & BitConverter.ToString(DirectCast(row("Row_Version"), Byte())).Replace("-", "")
            Dim profile = Rows().Rows(0)
            editorOrganization.Text = DisplayValue(profile("BrandName")) & " / " & DisplayValue(profile("BranchName")) & " · " & DisplayValue(profile("TypeName"))
            openPanel = "profileEditor"
        Catch ex As Exception
            ShowFailure(ex, litMessage)
        End Try
    End Sub
    Private Function EditorData(prefix As String, names As String()) As XElement
        Dim data As New XElement("row")
        For Each name In names
            Dim control = Field(prefix & name)
            Dim value = If(TypeOf control Is DropDownList, DirectCast(control, DropDownList).SelectedValue, DirectCast(control, TextBox).Text.Trim())
            If name = "Email" AndAlso value <> "" Then
                Dim address As New System.Net.Mail.MailAddress(value)
                If address.Address <> value Then Throw New ArgumentException("البريد الإلكتروني غير صحيح.")
            End If
            If name = "Website" AndAlso value <> "" Then
                Dim uri As Uri = Nothing
                If Not Uri.TryCreate(value, UriKind.Absolute, uri) OrElse Not {"http", "https"}.Contains(uri.Scheme) Then Throw New ArgumentException("أدخل رابطًا يبدأ بـ https أو http.")
            End If
            data.Add(New XElement(name, value))
        Next
        Return data
    End Function
    Protected Sub btnSaveProfile_Click(sender As Object, e As EventArgs)
        openPanel = "profileEditor" : Validate("ProfileEditor") : If Not IsValid Then Return
        Dim stagedLogo As String = Nothing
        Try
            If ViewState("ProfileVersion") Is Nothing Then Throw New ArgumentException("افتح نموذج التعديل أولًا.")
            Dim data = EditorData("p_", ProfileFields), logo = CRMAccountLogo.ReadUpload(logoUpload.PostedFile)
            stagedLogo = CRMAccountLogo.SaveFile(logo)
            CustomerPortalData.CustomerQuery("dbo.Customer_SaveProfile", CustomerPortalData.P("@Data", SqlDbType.Xml, data.ToString()), CustomerPortalData.P("@Version", SqlDbType.Binary, ViewState("ProfileVersion"), 8), CustomerPortalData.P("@Logo_Url", SqlDbType.NVarChar, stagedLogo, 260))
            stagedLogo = Nothing
            ViewState.Remove("ProfileVersion") : openPanel = Nothing : litMessage.Text = AlertMarkup("تم حفظ بياناتك بنجاح.", False)
        Catch ex As Exception
            CRMAccountLogo.RemoveStagedFile(stagedLogo)
            ShowFailure(ex, profileEditorMessage)
        End Try
    End Sub
    Protected Sub NewContact_Click(sender As Object, e As EventArgs)
        For Each name In ContactFields
            Dim control = Field("c_" & name)
            If TypeOf control Is DropDownList Then
                DirectCast(control, DropDownList).SelectedIndex = 0
            Else
                DirectCast(control, TextBox).Text = ""
            End If
        Next
        c_IsActive.Checked = True : ViewState("ContactID") = 0 : ViewState.Remove("ContactVersion")
        contactEditorTitle.Text = "إضافة جهة اتصال" : openPanel = "contactEditor"
    End Sub
    Protected Sub Contact_Command(sender As Object, e As ListViewCommandEventArgs)
        Try
            If e.CommandName <> "EditContact" AndAlso e.CommandName <> "AskDeleteContact" Then Return
            Dim id As Integer
            If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then Throw New ArgumentException("جهة الاتصال غير متاحة.")
            Dim key = contacts.DataKeys(e.Item.DataItemIndex)
            If CInt(key.Values("ID")) <> id Then Throw New ArgumentException("حدّث القائمة وأعد المحاولة.")
            Dim row = Rows("contacts").Rows.Cast(Of DataRow)().FirstOrDefault(Function(item) CInt(item("ID")) = id)
            If row Is Nothing Then Throw New ArgumentException("جهة الاتصال غير متاحة.")
            If e.CommandName = "AskDeleteContact" Then
                ViewState("DeleteContactID") = id : ViewState("DeleteContactVersion") = key.Values("Row_Version")
                deleteName.Text = Convert.ToString(row("Name_AR")) : openPanel = "contactDeleteModal" : Return
            End If
            For Each name In ContactFields
                Dim control = Field("c_" & name), value = Convert.ToString(row(name))
                If TypeOf control Is DropDownList Then
                    DirectCast(control, DropDownList).SelectedValue = value
                Else
                    DirectCast(control, TextBox).Text = value
                End If
            Next
            c_IsActive.Checked = CBool(row("Is_Active")) : ViewState("ContactID") = id : ViewState("ContactVersion") = row("Row_Version")
            contactEditorTitle.Text = "تعديل جهة الاتصال" : openPanel = "contactEditor" : LogRead("contact-view", id)
        Catch ex As Exception
            ShowFailure(ex, litMessage)
        End Try
    End Sub
    Protected Sub btnSaveContact_Click(sender As Object, e As EventArgs)
        openPanel = "contactEditor" : Validate("ContactEditor") : If Not IsValid Then Return
        Try
            If ViewState("ContactID") Is Nothing Then Throw New ArgumentException("افتح نموذج الإضافة أو التعديل أولًا.")
            Dim data = EditorData("c_", ContactFields) : data.Add(New XElement("Is_Active", If(c_IsActive.Checked, "1", "0")))
            CustomerPortalData.CustomerQuery("dbo.Customer_SaveContact", CustomerPortalData.P("@ID", SqlDbType.Int, ViewState("ContactID")), CustomerPortalData.P("@Version", SqlDbType.Binary, ViewState("ContactVersion"), 8), CustomerPortalData.P("@Data", SqlDbType.Xml, data.ToString()))
            ViewState.Remove("ContactID") : ViewState.Remove("ContactVersion") : openPanel = Nothing : litMessage.Text = AlertMarkup("تم حفظ جهة الاتصال بنجاح.", False)
        Catch ex As Exception
            ShowFailure(ex, contactEditorMessage)
        End Try
    End Sub
    Protected Sub DeleteContact_Click(sender As Object, e As EventArgs)
        Try
            If ViewState("DeleteContactID") Is Nothing OrElse ViewState("DeleteContactVersion") Is Nothing Then Throw New ArgumentException("اختر جهة الاتصال المراد حذفها أولًا.")
            Dim id = CInt(ViewState("DeleteContactID")), version = DirectCast(ViewState("DeleteContactVersion"), Byte())
            ViewState.Remove("DeleteContactID") : ViewState.Remove("DeleteContactVersion")
            CustomerPortalData.CustomerQuery("dbo.Customer_DeleteContact", CustomerPortalData.P("@ID", SqlDbType.Int, id), CustomerPortalData.P("@Version", SqlDbType.Binary, version, 8))
            litMessage.Text = AlertMarkup("تم حذف جهة الاتصال بنجاح.", False)
        Catch ex As Exception
            ShowFailure(ex, litMessage)
        End Try
    End Sub
    Private Sub ShowFailure(ex As Exception, output As Literal)
        Dim sql = TryCast(ex, System.Data.SqlClient.SqlException)
        If sql IsNot Nothing AndAlso sql.Number = 51911 Then
            CustomerPortalData.Current = Nothing : Response.Redirect("/Login.aspx?kind=customer") : Return
        End If
        Dim message = If(TypeOf ex Is InvalidOperationException OrElse TypeOf ex Is ArgumentException, ex.Message, CustomerPortalData.ErrorText(ex))
        output.Text = AlertMarkup(message, True)
    End Sub
    Private Function AlertMarkup(message As String, failed As Boolean) As String
        Return "<div class=""alert alert-" & If(failed, "danger", "success") & " alert-dismissible"" role=""alert""><h6 class=""alert-heading mb-1"">" & If(failed, "تعذّر إكمال العملية", "تمت العملية بنجاح") & "</h6>" & Server.HtmlEncode(message) & "<button type=""button"" class=""btn-close"" data-bs-dismiss=""alert"" aria-label=""إغلاق""></button></div>"
    End Function
    Protected Function DisplayValue(value As Object) As String
        Return If(String.IsNullOrWhiteSpace(Convert.ToString(value)), "غير محدد", Convert.ToString(value))
    End Function
End Class
