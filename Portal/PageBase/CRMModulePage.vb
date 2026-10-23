Imports System.Data
Imports System.Globalization
Imports System.Linq
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public MustInherit Class CRMModulePage
    Inherits PageBase
    Protected MustOverride ReadOnly Property EntityName As String
    Protected MustOverride ReadOnly Property Mode As String
    Private actor As Integer
    Private recordID As Integer
    Private admin As Boolean
    Private allowed As Boolean
    Private content As Control
    Private current As DataRow

    Protected Function Field(Of T As Control)(name As String) As T
        Return TryCast(content.FindControl(name), T)
    End Function

    Protected ReadOnly Property CRMAccessAllowed As Boolean
        Get
            Return allowed
        End Get
    End Property

    Protected ReadOnly Property CRMIsAdmin As Boolean
        Get
            Return admin
        End Get
    End Property

    Protected Overrides Sub OnInit(e As EventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("~/Login.aspx") : Return
        actor = SessionManager.GetInstance.Users.UserID
        ViewStateUserKey = Session.SessionID
        MyBase.OnInit(e)
        content = Master.FindControl("ContentPlaceHolder1")
        Try
            admin = CBool(CRMData.Query("dbo.CRM_CheckUser", CRMData.P("@Actor_ID", SqlDbType.Int, actor)).Rows(0)("Is_Admin"))
            If New String() {"Account_Types", "Contract_Types", "Payment_Methods", "WorkGuide_Items"}.Contains(EntityName) AndAlso Not admin Then Throw New InvalidOperationException("إدارة التعريفات متاحة لمدير النظام فقط.")
            allowed = True
            If Mode = "Edit" Then
                If Not Integer.TryParse(Request.QueryString("id"), recordID) OrElse recordID <= 0 Then Throw New InvalidOperationException("رقم السجل غير صحيح.")
                Dim data = CRMData.Rows(EntityName, actor, recordID)
                If data.Rows.Count = 0 Then Throw New InvalidOperationException("السجل غير متاح أو لا تملك صلاحية الوصول إليه.")
                current = data.Rows(0)
            End If
            ' Keep legacy account links on the current editor, including organizational memberships.
            ' Existing form submissions still run their original validation and are never redirected first.
            If EntityName = "Accounts" AndAlso Mode <> "Manage" AndAlso String.Equals(Request.HttpMethod, "GET", StringComparison.OrdinalIgnoreCase) Then
                allowed = False
                Response.Redirect(CRMData.Link("Accounts") & If(Mode = "Edit", "?edit=" & recordID.ToString(), "?new=1"), False)
                Context.ApplicationInstance.CompleteRequest()
                Return
            End If
            If Mode <> "Manage" Then
                For Each f In CRMModel.Entities(EntityName).Fields
                    If CRMModel.Entities.ContainsKey(f.Kind) OrElse f.Kind = "Users" OrElse f.Kind = "Brands" Then FillOptions(Field(Of DropDownList)("f_" & f.Name), f.Kind)
                Next
                If EntityName = "Accounts" Then
                    Dim brand = Field(Of DropDownList)("f_Brand_ID")
                    If current IsNot Nothing AndAlso Not IsDBNull(current("Brand_ID")) AndAlso brand.Items.FindByValue(Convert.ToString(current("Brand_ID"))) Is Nothing Then
                        brand.Items.Add(New ListItem(Convert.ToString(current("Brand_Name")) & " (غير متاحة)", Convert.ToString(current("Brand_ID"))))
                    End If
                    Dim selected = If(IsPostBack, Request.Form(brand.UniqueID), If(current Is Nothing, "", Convert.ToString(current("Brand_ID"))))
                    FillAccountBranches(selected)
                End If
                If EntityName = "Accounts" AndAlso Not admin Then Field(Of DropDownList)("f_Owner_ID").Enabled = False
            Else
                If Field(Of DropDownList)("filterAccount") IsNot Nothing Then FillOptions(Field(Of DropDownList)("filterAccount"), "Accounts")
                If Field(Of DropDownList)("filterType") IsNot Nothing Then FillOptions(Field(Of DropDownList)("filterType"), "Account_Types")
                If Field(Of DropDownList)("filterUser") IsNot Nothing Then FillOptions(Field(Of DropDownList)("filterUser"), "Users")
            End If
        Catch ex As Exception
            allowed = False : Field(Of Panel)("pnlBody").Visible = False : ShowError(ex)
        End Try
    End Sub

    Private Sub FillOptions(ddl As DropDownList, entity As String)
        ddl.Items.Clear() : ddl.Items.Add(New ListItem("— اختر —", ""))
        Dim data = If(entity = "Users" OrElse entity = "Brands", CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Kind", SqlDbType.NVarChar, entity, 30)), CRMData.Rows(entity, actor))
        For Each row As DataRow In data.Rows
            ddl.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
        Next
    End Sub

    Private Sub FillAccountBranches(brandValue As String)
        Dim branches = Field(Of DropDownList)("f_Branch_ID")
        branches.Items.Clear()
        branches.Items.Add(New ListItem("بدون فرع (اختياري)", ""))
        Dim brandID As Integer
        If Not Integer.TryParse(brandValue, brandID) OrElse brandID <= 0 Then Return
        Dim options = CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Kind", SqlDbType.NVarChar, "Branches", 30))
        For Each row As DataRow In options.Rows
            If CInt(row("BrandID")) = brandID Then branches.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
        Next
        If current IsNot Nothing AndAlso Convert.ToString(current("Brand_ID")) = brandValue AndAlso Not IsDBNull(current("Branch_ID")) AndAlso branches.Items.FindByValue(Convert.ToString(current("Branch_ID"))) Is Nothing Then
            branches.Items.Add(New ListItem(Convert.ToString(current("Branch_Name")) & " (غير متاح)", Convert.ToString(current("Branch_ID"))))
        End If
    End Sub

    Protected Sub Brand_Changed(sender As Object, e As EventArgs)
        If allowed AndAlso EntityName = "Accounts" AndAlso Mode <> "Manage" Then
            FillAccountBranches(Field(Of DropDownList)("f_Brand_ID").SelectedValue)
        End If
    End Sub

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        If Not allowed OrElse IsPostBack Then Return
        If Mode <> "Manage" Then
            For Each f In CRMModel.Entities(EntityName).Fields
                If current Is Nothing Then Continue For
                Dim ctrl = Field(Of Control)("f_" & f.Name), value = Convert.ToString(current(f.Name))
                If TypeOf ctrl Is DropDownList Then
                    Dim ddl = DirectCast(ctrl, DropDownList)
                    If ddl.Items.FindByValue(value) IsNot Nothing Then ddl.SelectedValue = value
                Else
                    DirectCast(ctrl, TextBox).Text = value
                End If
            Next
            If current IsNot Nothing Then
                ViewState("version") = DirectCast(current("Row_Version"), Byte())
                Field(Of CheckBox)("chkIsActive").Checked = CBool(current("Is_Active"))
            ElseIf EntityName = "Accounts" AndAlso Not admin Then
                Field(Of DropDownList)("f_Owner_ID").SelectedValue = actor.ToString()
            End If
        End If
        AuditRead()
    End Sub

    Private Sub AuditRead()
        Dim account As Object = Nothing
        If current IsNot Nothing AndAlso EntityName = "Accounts" Then account = recordID
        If current IsNot Nothing AndAlso current.Table.Columns.Contains("Account_ID") Then account = current("Account_ID")
        CRMData.Query("dbo.CRM_Log_Read", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Entity", SqlDbType.NVarChar, EntityName, 80), CRMData.P("@ID", SqlDbType.Int, If(recordID = 0, CType(Nothing, Object), recordID)), CRMData.P("@Account_ID", SqlDbType.Int, account))
    End Sub

    Protected Sub Save_Click(sender As Object, e As EventArgs)
        If Not allowed Then Return
        Page.Validate()
        If Not Page.IsValid Then Return
        Try
            Dim xml As New XElement("row")
            For Each f In CRMModel.Entities(EntityName).Fields
                Dim ctrl = Field(Of Control)("f_" & f.Name)
                Dim value = If(TypeOf ctrl Is DropDownList, DirectCast(ctrl, DropDownList).SelectedValue, DirectCast(ctrl, TextBox).Text.Trim())
                If f.Kind = "email" AndAlso value <> "" Then
                    Dim address As New System.Net.Mail.MailAddress(value)
                    If address.Address <> value Then Throw New InvalidOperationException("البريد الإلكتروني غير صحيح.")
                End If
                If f.Kind = "url" AndAlso value <> "" Then
                    Dim uri As Uri = Nothing
                    If Not Uri.TryCreate(value, UriKind.Absolute, uri) OrElse Not New String() {"https", "http"}.Contains(uri.Scheme) Then Throw New InvalidOperationException("أدخل رابطًا يبدأ بـ https أو http.")
                End If
                xml.Add(New XElement(f.Name, value))
            Next
            xml.Add(New XElement("Is_Active", If(Field(Of CheckBox)("chkIsActive").Checked, "1", "0")))
            CRMData.Save(EntityName, actor, recordID, xml, TryCast(ViewState("version"), Byte()))
            Response.Redirect(CRMData.Link(EntityName) & "?saved=1", False)
            Context.ApplicationInstance.CompleteRequest()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub Row_Command(sender As Object, e As ListViewCommandEventArgs)
        If Not allowed OrElse Mode <> "Manage" Then Return
        If Not New String() {"Activate", "Deactivate", "DeleteItem"}.Contains(e.CommandName) Then Return
        Try
            Dim id As Integer
            If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then Throw New InvalidOperationException("رقم العنصر غير صحيح.")
            Dim list = Field(Of ListView)("lstData")
            Dim key = list.DataKeys(e.Item.DataItemIndex)
            If CInt(key.Values("ID")) <> id Then Throw New InvalidOperationException("حدّث الجدول وأعد المحاولة.")
            If e.CommandName = "DeleteItem" Then
                CRMData.Query("dbo.CRM_Delete", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Entity", SqlDbType.NVarChar, EntityName, 80), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Version", SqlDbType.Binary, key.Values("Row_Version"), 8))
            Else
                CRMData.Query("dbo.CRM_Set_Active", CRMData.P("@Actor_ID", SqlDbType.Int, actor), CRMData.P("@Entity", SqlDbType.NVarChar, EntityName, 80), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Is_Active", SqlDbType.Bit, e.CommandName = "Activate"), CRMData.P("@Version", SqlDbType.Binary, key.Values("Row_Version"), 8))
            End If
            ShowSuccess(If(e.CommandName = "DeleteItem", "تم حذف العنصر.", If(e.CommandName = "Activate", "تم تفعيل العنصر.", "تم إيقاف العنصر.")))
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub Search_Click(sender As Object, e As EventArgs)
        If allowed Then AuditRead()
    End Sub

    Private Function TextValue(id As String) As String
        Dim control = Field(Of Control)(id)
        If control Is Nothing Then Return ""
        If TypeOf control Is DropDownList Then Return DirectCast(control, DropDownList).SelectedValue
        Return DirectCast(control, TextBox).Text.Trim()
    End Function

    Private Sub BindData()
        Dim data = LoadListData()
        PrepareListData(data)
        Dim rows = data.Rows.Cast(Of DataRow)()
        For Each pair In New String() {"filterName=Name_AR", "filterEmail=Email", "filterJob=Job_Title", "filterPhone=Phone"}
            Dim p = pair.Split("="c), value = TextValue(p(0)), col = p(1)
            If value <> "" Then rows = rows.Where(Function(r) Convert.ToString(r(col)).IndexOf(value, StringComparison.CurrentCultureIgnoreCase) >= 0 OrElse ((col = "Name_AR" OrElse col = "Job_Title") AndAlso data.Columns.Contains(If(col = "Name_AR", "Name_EN", "Job_Title_EN")) AndAlso Convert.ToString(r(If(col = "Name_AR", "Name_EN", "Job_Title_EN"))).IndexOf(value, StringComparison.CurrentCultureIgnoreCase) >= 0))
        Next
        For Each pair In New String() {"filterAccount=Account_ID", "filterType=Account_Type_ID", "filterUser=Actor_ID", "filterEntity=Entity", "filterStatus=Is_Active", "filterBrand=Brand_ID", "filterBranch=Branch_ID"}
            Dim p = pair.Split("="c), value = TextValue(p(0)), col = p(1)
            If value <> "" Then
                If EntityName = "Accounts" AndAlso (col = "Brand_ID" OrElse col = "Branch_ID") AndAlso data.Columns.Contains(If(col = "Brand_ID", "Brand_IDs", "Branch_IDs")) Then
                    Dim memberships = If(col = "Brand_ID", "Brand_IDs", "Branch_IDs")
                    rows = rows.Where(Function(row) Convert.ToString(row(memberships)).Split(","c).Any(Function(id) id.Trim() = value))
                Else
                    rows = rows.Where(Function(r) If(col = "Is_Active", If(CBool(r(col)), "1", "0"), Convert.ToString(r(col))) = value)
                End If
            End If
        Next
        Dim first As DateTime, last As DateTime
        If TextValue("filterFrom") <> "" AndAlso Not DateTime.TryParseExact(TextValue("filterFrom"), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, first) Then Throw New InvalidOperationException("تاريخ البداية غير صحيح.")
        If TextValue("filterTo") <> "" AndAlso Not DateTime.TryParseExact(TextValue("filterTo"), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, last) Then Throw New InvalidOperationException("تاريخ النهاية غير صحيح.")
        If TextValue("filterFrom") <> "" AndAlso TextValue("filterTo") <> "" AndAlso first > last Then Throw New InvalidOperationException("نطاق التاريخ غير صحيح.")
        If TextValue("filterFrom") <> "" Then rows = rows.Where(Function(r) CDate(r("AddedDate")).Date >= first)
        If TextValue("filterTo") <> "" Then rows = rows.Where(Function(r) CDate(r("AddedDate")).Date <= last)
        Dim filtered = data.Clone()
        For Each row In rows : filtered.ImportRow(row) : Next
        Dim list = Field(Of ListView)("lstData")
        list.DataSource = filtered : list.DataBind()
    End Sub

    Protected Overridable Sub PrepareListData(data As DataTable)
    End Sub

    Protected Overridable Function LoadListData() As DataTable
        Return If(EntityName = "Activity_Logs", CRMData.Query("dbo.CRM_Select_Logs", CRMData.P("@Actor_ID", SqlDbType.Int, actor)), CRMData.Rows(EntityName, actor))
    End Function

    Protected Overrides Sub OnPreRender(e As EventArgs)
        If allowed Then
            Try
                If Mode = "Manage" Then BindData()
                If Request.QueryString("saved") = "1" AndAlso Field(Of Literal)("litMessage").Text = "" Then ShowSuccess("تم حفظ البيانات.")
            Catch ex As Exception
                ShowError(ex)
            End Try
        End If
        MyBase.OnPreRender(e)
    End Sub

    Protected Function EntityTitle(value As Object) As String
        Dim name = Convert.ToString(value)
        If name = "Customer_Session" Then Return "دخول العملاء"
        If name = "WorkGuide_Permissions" Then Return "صلاحيات دليل العمل"
        If name = "WorkGuide_Categories" Then Return "تصنيفات دليل العمل"
        If name = "News" Then Return "الأخبار"
        If name = "JobTitle_Items" Then Return "الأدوات"
        If name = "Activity_Logs" Then Return "سجل النشاطات"
        Return If(CRMModel.Entities.ContainsKey(name), CRMModel.Entities(name).Title, name)
    End Function

    Protected Function ActivityActionTitle(value As Object) As String
        Dim action = Convert.ToString(value)
        If action = "news-list" Then Return "عرض أخبار العلامة التجارية"
        If action = "news-details" Then Return "عرض تفاصيل خبر"
        Return action
    End Function

    Protected Overridable Sub ShowSuccess(message As String)
        Field(Of Literal)("litMessage").Text = "<div class='alert alert-success'>" & CRMData.H(message) & "</div>"
    End Sub

    Protected Overridable Sub ShowError(ex As Exception)
        Field(Of Literal)("litMessage").Text = "<div class='alert alert-danger' role='alert'>" & CRMData.H(CRMData.ErrorMessage(ex)) & "</div>"
    End Sub
End Class
