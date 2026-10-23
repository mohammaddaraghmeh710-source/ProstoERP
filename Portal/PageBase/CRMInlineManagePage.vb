Imports System.Data
Imports System.Linq
Imports System.Collections.Generic
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public MustInherit Class CRMInlineManagePage
    Inherits CRMModulePage
    Private reopenEditor As Boolean
    Private reopenDelete As Boolean
    Private branchBrands As New Dictionary(Of String, String)

    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If Not CRMAccessAllowed OrElse EntityName <> "Accounts" Then Return
        Page.Form.Enctype = "multipart/form-data"
        Dim brands = Field(Of DropDownList)("filterBrand")
        brands.Items.Clear()
        brands.Items.Add(New ListItem("اختر العلامة التجارية", ""))
        For Each row As DataRow In CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Kind", SqlDbType.NVarChar, "Brands", 30)).Rows
            brands.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
        Next
        LoadBranchOptions(Field(Of DropDownList)("filterBranch"), "اختر الفرع")
    End Sub

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        If Not CRMAccessAllowed Then Return
        If EntityName = "Accounts" Then
            Field(Of Panel)("pnlCredentials").Visible = CRMIsAdmin
            Field(Of Panel)("pnlLoginState").Visible = CRMIsAdmin
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
            Response.Cache.SetNoStore()
        ElseIf Not IsPostBack Then
            Dim optionValue = Request.QueryString("account")
            Dim list = Field(Of DropDownList)("filterAccount")
            If optionValue IsNot Nothing AndAlso list.Items.FindByValue(optionValue) IsNot Nothing Then list.SelectedValue = optionValue
        End If
        If Not IsPostBack Then
            Dim optionList = Field(Of DropDownList)(If(EntityName = "Accounts", "filterType", "filterAccount"))
            optionList.Items(0).Text = If(EntityName = "Accounts", "اختر نوع العميل", "اختر العميل")
            If EntityName = "Accounts" Then
                Try
                    If Request.QueryString("new") = "1" Then
                        NewRecord_Click(Me, EventArgs.Empty)
                    ElseIf Request.QueryString("edit") IsNot Nothing Then
                        Dim id As Integer
                        If Not Integer.TryParse(Request.QueryString("edit"), id) OrElse id <= 0 Then Throw New InvalidOperationException("رقم السجل غير صحيح.")
                        Dim rows = CRMData.Rows("Accounts", CrmUserId(), id)
                        If rows.Rows.Count = 0 Then Throw New InvalidOperationException("السجل غير متاح أو لا تملك صلاحية الوصول إليه.")
                        OpenInlineEditor(id, rows.Rows(0))
                    End If
                Catch ex As Exception
                    ShowError(ex)
                End Try
            End If
        End If
    End Sub

    Private Sub FillEditorOptions()
        For Each definition In CRMModel.InlineFields(EntityName)
            Dim list = Field(Of DropDownList)("f_" & definition.Name)
            If list Is Nothing OrElse definition.Kind = "gender" OrElse definition.Kind = "Branches" Then Continue For
            Dim kind = definition.Kind
            Dim rows = If(kind = "Users" OrElse kind = "Brands", CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Kind", SqlDbType.NVarChar, kind, 30)), CRMData.Rows(kind, CrmUserId()))
            list.Items.Clear()
            list.Items.Add(New ListItem("— اختر —", ""))
            For Each row As DataRow In rows.Rows
                If rows.Columns.Contains("Is_Active") AndAlso Not CBool(row("Is_Active")) Then Continue For
                list.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
            Next
        Next
        If EntityName = "Accounts" Then
            Field(Of DropDownList)("f_Owner_ID").Enabled = CRMIsAdmin
        End If
    End Sub

    Private Function OrganizationOptions(accountID As Integer) As DataTable
        Dim key = "CRMAccountOrganization:" & accountID.ToString()
        Dim rows = TryCast(Context.Items(key), DataTable)
        If rows Is Nothing Then
            rows = CRMData.Query("dbo.CRM_Account_Organization", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Account_ID", SqlDbType.Int, accountID))
            Context.Items(key) = rows
        End If
        Return rows
    End Function

    Private Sub FillAccountOrganization(accountID As Integer)
        Dim brands = Field(Of ListBox)("f_Account_Brands"), branches = Field(Of ListBox)("f_Account_Branches")
        brands.Items.Clear()
        branches.Items.Clear()
        For Each row As DataRow In OrganizationOptions(accountID).Rows
            Dim branch = String.Equals(Convert.ToString(row("Kind")), "Branch", StringComparison.OrdinalIgnoreCase)
            Dim name = Convert.ToString(row("Name_AR")), english = Convert.ToString(row("Name_EN"))
            If String.IsNullOrWhiteSpace(name) Then name = english : english = ""
            Dim label = name & If(String.IsNullOrWhiteSpace(english), "", " / " & english)
            If branch Then label = Convert.ToString(row("BrandName")) & " — " & label
            If Not CBool(row("Is_Active")) Then label &= " (غير متاح)"
            Dim item As New ListItem(label, Convert.ToString(row("ID"))) With {.Selected = CBool(row("Is_Selected"))}
            item.Attributes("data-available") = If(CBool(row("Is_Active")), "1", "0")
            If branch Then item.Attributes("data-brand-id") = Convert.ToString(row("Brand_ID"))
            If branch Then branches.Items.Add(item) Else brands.Items.Add(item)
        Next
    End Sub

    Private Sub RestoreOrganizationMetadata(accountID As Integer)
        Dim rows As New Dictionary(Of String, DataRow)(StringComparer.Ordinal)
        For Each row As DataRow In OrganizationOptions(accountID).Rows
            rows(Convert.ToString(row("Kind")) & ":" & Convert.ToString(row("ID"))) = row
        Next
        For Each kind In {"Brand", "Branch"}
            Dim control = Field(Of ListBox)(If(kind = "Brand", "f_Account_Brands", "f_Account_Branches"))
            For Each item As ListItem In control.Items
                Dim key = kind & ":" & item.Value
                If rows.ContainsKey(key) Then
                    item.Attributes("data-available") = If(CBool(rows(key)("Is_Active")), "1", "0")
                    If kind = "Branch" Then item.Attributes("data-brand-id") = Convert.ToString(rows(key)("Brand_ID"))
                Else
                    item.Attributes("data-available") = "0"
                    If kind = "Branch" Then item.Attributes("data-brand-id") = ""
                End If
            Next
        Next
    End Sub

    Private Sub AddAccountOrganization(xml As XElement, accountID As Integer)
        Dim brands = Field(Of ListBox)("f_Account_Brands").Items.Cast(Of ListItem)().Where(Function(item) item.Selected).ToArray()
        Dim branches = Field(Of ListBox)("f_Account_Branches").Items.Cast(Of ListItem)().Where(Function(item) item.Selected).ToArray()
        If brands.Length = 0 Then Throw New InvalidOperationException("اختر علامة تجارية واحدة على الأقل للعميل.")
        Dim selectedBrands As New HashSet(Of String)(brands.Select(Function(item) item.Value), StringComparer.Ordinal)
        Dim branchRows = OrganizationOptions(accountID).Rows.Cast(Of DataRow)().Where(Function(row) Convert.ToString(row("Kind")) = "Branch").ToDictionary(Function(row) Convert.ToString(row("ID")), Function(row) row)
        If branches.Any(Function(item) Not branchRows.ContainsKey(item.Value) OrElse Not selectedBrands.Contains(Convert.ToString(branchRows(item.Value)("Brand_ID")))) Then Throw New InvalidOperationException("اختر فروعًا تابعة للعلامات التجارية المحددة فقط.")
        xml.Add(New XElement("Account_Brands", brands.Select(Function(item) New XElement("Brand", New XAttribute("ID", item.Value)))))
        xml.Add(New XElement("Account_Branches", branches.Select(Function(item) New XElement("Branch", New XAttribute("ID", item.Value)))))
    End Sub

    Private Sub LoadBranchOptions(list As DropDownList, placeholder As String)
        list.Items.Clear()
        list.Items.Add(New ListItem(placeholder, ""))
        Dim rows = CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Kind", SqlDbType.NVarChar, "Branches", 30))
        For Each row As DataRow In rows.Rows
            Dim item As New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID")))
            item.Attributes("data-brand-id") = Convert.ToString(row("BrandID"))
            branchBrands(item.Value) = Convert.ToString(row("BrandID"))
            list.Items.Add(item)
        Next
    End Sub

    Private Sub SelectValue(list As DropDownList, value As String, Optional label As String = Nothing)
        If value <> "" AndAlso list.Items.FindByValue(value) Is Nothing Then list.Items.Add(New ListItem(If(label, "عنصر غير متاح") & " (غير متاح)", value))
        list.SelectedValue = value
    End Sub

    Protected Sub NewRecord_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Try
            FillEditorOptions()
            For Each definition In CRMModel.InlineFields(EntityName)
                Dim control = Field(Of Control)("f_" & definition.Name)
                If TypeOf control Is DropDownList Then
                    DirectCast(control, DropDownList).SelectedIndex = 0
                Else
                    DirectCast(control, TextBox).Text = ""
                End If
            Next
            ViewState("InlineID") = 0
            ViewState.Remove("InlineVersion")
            Field(Of Literal)("litEditorTitle").Text = If(EntityName = "Accounts", "إضافة عميل", "إضافة جهة اتصال")
            Field(Of CheckBox)("chkIsActive").Checked = True
            If EntityName = "Accounts" Then
                FillAccountOrganization(0)
                Field(Of Image)("logoPreview").ImageUrl = CRMAccountLogo.DefaultUrl
                If Not CRMIsAdmin Then SelectValue(Field(Of DropDownList)("f_Owner_ID"), CrmUserId().ToString())
                Field(Of TextBox)("txtUsername").Text = ""
                Field(Of CheckBox)("chkLoginActive").Checked = True
                ViewState("LoginUsername") = ""
                ViewState("LoginActive") = True
                ViewState.Remove("LoginVersion")
            Else
                Dim account = Field(Of DropDownList)("filterAccount").SelectedValue
                If Field(Of DropDownList)("f_Account_ID").Items.FindByValue(account) IsNot Nothing Then SelectValue(Field(Of DropDownList)("f_Account_ID"), account)
            End If
            reopenEditor = True
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub Inline_RowCommand(sender As Object, e As ListViewCommandEventArgs)
        If Not CRMAccessAllowed Then Return
        If e.CommandName <> "EditRecord" AndAlso e.CommandName <> "AskDelete" Then
            MyBase.Row_Command(sender, e)
            Return
        End If
        Try
            Dim id As Integer
            If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then Throw New InvalidOperationException("رقم السجل غير صحيح.")
            Dim key = Field(Of ListView)("lstData").DataKeys(e.Item.DataItemIndex)
            If CInt(key.Values("ID")) <> id Then Throw New InvalidOperationException("حدّث القائمة وأعد المحاولة.")
            Dim data = CRMData.Rows(EntityName, CrmUserId(), id)
            If data.Rows.Count = 0 Then Throw New InvalidOperationException("السجل غير متاح أو لا تملك صلاحية الوصول إليه.")
            Dim row = data.Rows(0)
            If e.CommandName = "AskDelete" Then
                ViewState("InlineDeleteID") = id
                ViewState("InlineDeleteVersion") = key.Values("Row_Version")
                Field(Of Literal)("litDeleteName").Text = Convert.ToString(row("Name_AR"))
                reopenDelete = True
                Return
            End If
            OpenInlineEditor(id, row)
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Private Sub OpenInlineEditor(id As Integer, row As DataRow)
        FillEditorOptions()
        ViewState("InlineID") = id
        ViewState("InlineVersion") = row("Row_Version")
        For Each definition In CRMModel.InlineFields(EntityName)
            Dim control = Field(Of Control)("f_" & definition.Name), value = Convert.ToString(row(definition.Name))
            If TypeOf control Is DropDownList Then
                Dim labelColumn = If(definition.Name = "Account_ID", "Account_Name", If(definition.Name = "Account_Type_ID", "Type_Name", If(definition.Name = "Owner_ID", "Owner_Name", If(definition.Name = "Brand_ID", "Brand_Name", "Branch_Name"))))
                SelectValue(DirectCast(control, DropDownList), value, If(row.Table.Columns.Contains(labelColumn), Convert.ToString(row(labelColumn)), Nothing))
                If definition.Name = "Branch_ID" AndAlso value <> "" Then DirectCast(control, DropDownList).SelectedItem.Attributes("data-brand-id") = Convert.ToString(row("Brand_ID"))
            Else
                DirectCast(control, TextBox).Text = value
            End If
        Next
        Field(Of CheckBox)("chkIsActive").Checked = CBool(row("Is_Active"))
        Field(Of Literal)("litEditorTitle").Text = If(EntityName = "Accounts", "تعديل بيانات العميل", "تعديل جهة الاتصال")
        If EntityName = "Accounts" Then
            FillAccountOrganization(id)
            Field(Of Image)("logoPreview").ImageUrl = CRMAccountLogo.Url(id, DirectCast(row("Row_Version"), Byte()))
        End If
        If EntityName = "Accounts" AndAlso CRMIsAdmin Then
            Dim login = CustomerPortalData.Query("dbo.Customer_AdminData", CustomerPortalData.P("@Actor", SqlDbType.Int, CrmUserId()), CustomerPortalData.P("@AccountID", SqlDbType.Int, id), CustomerPortalData.P("@Section", SqlDbType.VarChar, "login", 20)).Rows(0)
            Field(Of TextBox)("txtUsername").Text = Convert.ToString(login("Username"))
            Field(Of CheckBox)("chkLoginActive").Checked = IsDBNull(login("IsActive")) OrElse CBool(login("IsActive"))
            ViewState("LoginUsername") = Convert.ToString(login("Username"))
            ViewState("LoginActive") = Field(Of CheckBox)("chkLoginActive").Checked
            ViewState("LoginVersion") = If(IsDBNull(login("Version")), Nothing, login("Version"))
        End If
        reopenEditor = True
    End Sub

    Protected Sub SaveRecord_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        reopenEditor = True
        Page.Validate("CRMEditor")
        If Not Page.IsValid Then Return
        Try
            If ViewState("InlineID") Is Nothing Then Throw New InvalidOperationException("افتح نموذج الإضافة أو التعديل أولًا.")
            Dim id = CInt(ViewState("InlineID")), xml As New XElement("row")
            For Each definition In CRMModel.InlineFields(EntityName)
                Dim control = Field(Of Control)("f_" & definition.Name)
                Dim value = If(TypeOf control Is DropDownList, DirectCast(control, DropDownList).SelectedValue, DirectCast(control, TextBox).Text.Trim())
                If definition.Kind = "email" AndAlso value <> "" Then
                    Dim address As New System.Net.Mail.MailAddress(value)
                    If address.Address <> value Then Throw New InvalidOperationException("البريد الإلكتروني غير صحيح.")
                End If
                If definition.Kind = "url" AndAlso value <> "" Then
                    Dim uri As Uri = Nothing
                    If Not Uri.TryCreate(value, UriKind.Absolute, uri) OrElse Not {"http", "https"}.Contains(uri.Scheme) Then Throw New InvalidOperationException("أدخل رابطًا يبدأ بـ https أو http.")
                End If
                xml.Add(New XElement(definition.Name, value))
            Next
            xml.Add(New XElement("Is_Active", If(Field(Of CheckBox)("chkIsActive").Checked, "1", "0")))
            If EntityName = "Accounts" Then
                AddAccountOrganization(xml, id)
                Dim logo = CRMAccountLogo.ReadUpload(Field(Of FileUpload)("logoUpload").PostedFile)
                Dim username As String = "", password As String = "", loginActive As Boolean = False, changed As Boolean = False
                If CRMIsAdmin Then
                    username = Field(Of TextBox)("txtUsername").Text.Trim()
                    password = Field(Of TextBox)("txtPassword").Text
                    loginActive = Field(Of CheckBox)("chkLoginActive").Checked
                    changed = username <> Convert.ToString(ViewState("LoginUsername")) OrElse password <> "" OrElse (ViewState("LoginVersion") IsNot Nothing AndAlso loginActive <> CBool(ViewState("LoginActive")))
                End If
                CRMData.SaveAccountProfile(CrmUserId(), id, xml, TryCast(ViewState("InlineVersion"), Byte()), username, password, loginActive, TryCast(ViewState("LoginVersion"), Byte()), changed, logo)
            Else
                CRMData.Save(EntityName, CrmUserId(), id, xml, TryCast(ViewState("InlineVersion"), Byte()))
            End If
            ViewState.Remove("InlineID")
            ViewState.Remove("InlineVersion")
            ViewState.Remove("LoginVersion")
            reopenEditor = False
            ShowSuccess(If(id = 0, "تمت الإضافة بنجاح.", "تم حفظ التعديلات بنجاح."))
        Catch ex As Exception
            Field(Of Literal)("litEditorMessage").Text = AlertMarkup(ErrorText(ex), True)
        End Try
    End Sub

    Protected Sub ConfirmDelete_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Try
            If ViewState("InlineDeleteID") Is Nothing OrElse ViewState("InlineDeleteVersion") Is Nothing Then Throw New InvalidOperationException("اختر السجل المراد حذفه أولًا.")
            Dim id = CInt(ViewState("InlineDeleteID")), version = DirectCast(ViewState("InlineDeleteVersion"), Byte())
            ViewState.Remove("InlineDeleteID")
            ViewState.Remove("InlineDeleteVersion")
            CRMData.Query("dbo.CRM_Delete", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Entity", SqlDbType.NVarChar, EntityName, 80), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Version", SqlDbType.Binary, version, 8))
            ShowSuccess("تم حذف السجل بنجاح.")
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub ResetFilters_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        For Each name In {"filterName", "filterEmail", "filterJob", "filterPhone"}
            Dim input = Field(Of TextBox)(name)
            If input IsNot Nothing Then input.Text = ""
        Next
        For Each name In {"filterType", "filterAccount", "filterStatus", "filterBrand", "filterBranch"}
            Dim list = Field(Of DropDownList)(name)
            If list IsNot Nothing Then list.SelectedIndex = 0
        Next
        MyBase.Search_Click(sender, e)
    End Sub

    Protected Overrides Sub PrepareListData(data As DataTable)
        Dim active = data.Rows.Cast(Of DataRow)().Count(Function(row) CBool(row("Is_Active")))
        Field(Of Literal)("statTotal").Text = data.Rows.Count.ToString("N0")
        Field(Of Literal)("statActive").Text = active.ToString("N0")
        Field(Of Literal)("statInactive").Text = (data.Rows.Count - active).ToString("N0")
        If EntityName = "Accounts" Then
            Dim logos = CRMData.Query("dbo.CRM_Select_Account_Logos", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId())).Rows.Cast(Of DataRow)().ToDictionary(Function(row) CInt(row("Account_ID")), Function(row) DirectCast(row("Row_Version"), Byte()))
            data.Columns.Add("Logo_Url", GetType(String))
            Dim contacts = CRMData.Rows("Contacts", CrmUserId()).Rows.Cast(Of DataRow)().GroupBy(Function(row) CInt(row("Account_ID"))).ToDictionary(Function(group) group.Key, Function(group) group.Count())
            data.Columns.Add("Contact_Count", GetType(Integer))
            For Each row As DataRow In data.Rows
                Dim id = CInt(row("ID"))
                row("Contact_Count") = If(contacts.ContainsKey(id), contacts(id), 0)
                row("Logo_Url") = If(logos.ContainsKey(id), CRMAccountLogo.Url(id, logos(id)), CRMAccountLogo.DefaultUrl)
            Next
        End If
    End Sub

    Private Function ErrorText(ex As Exception) As String
        Dim sql = TryCast(ex, System.Data.SqlClient.SqlException)
        If sql IsNot Nothing AndAlso sql.Number >= 51910 AndAlso sql.Number <= 51912 Then Return CustomerPortalData.ErrorText(ex)
        If TypeOf ex Is FormatException Then Return "البريد الإلكتروني غير صحيح."
        Return CRMData.ErrorMessage(ex)
    End Function

    Private Function AlertMarkup(message As String, failed As Boolean) As String
        Return "<div class=""alert alert-" & If(failed, "danger", "success") & " alert-dismissible"" role=""alert""><h6 class=""alert-heading mb-1""><i class=""bx " & If(failed, "bx-error-circle", "bx-check-circle") & " me-2"" aria-hidden=""true""></i>" & If(failed, "تعذّر إكمال العملية", "تمت العملية بنجاح") & "</h6>" & CRMData.H(message) & "<button type=""button"" class=""btn-close"" data-bs-dismiss=""alert"" aria-label=""إغلاق""></button></div>"
    End Function

    Protected Overrides Sub ShowSuccess(message As String)
        Field(Of Literal)("litMessage").Text = AlertMarkup(message, False)
    End Sub

    Protected Overrides Sub ShowError(ex As Exception)
        Field(Of Literal)("litMessage").Text = AlertMarkup(ErrorText(ex), True)
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        If Not CRMAccessAllowed Then Return
        If EntityName = "Accounts" Then
            Field(Of TextBox)("txtPassword").Text = ""
            If ViewState("InlineID") IsNot Nothing Then RestoreOrganizationMetadata(CInt(ViewState("InlineID")))
            ' ViewState may rebuild filter items after Init; restore the client-side relationship metadata.
            For Each name In {"filterBranch"}
                For Each item As ListItem In Field(Of DropDownList)(name).Items
                    If branchBrands.ContainsKey(item.Value) Then item.Attributes("data-brand-id") = branchBrands(item.Value)
                Next
            Next
        End If
        If reopenEditor OrElse reopenDelete Then
            Dim id = If(reopenDelete, "crmDeleteModal", "crmEditor"), kind = If(reopenDelete, "Modal", "Offcanvas")
            Dim script = "(function(){function openCRMPanel(){var panel=document.getElementById('" & id & "');if(panel&&window.bootstrap)bootstrap." & kind & ".getOrCreateInstance(panel).show();}if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',openCRMPanel,{once:true});}else{openCRMPanel();}}());"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "crm-inline-panel", script, True)
        End If
    End Sub
End Class
