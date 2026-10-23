Imports System.Data
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Linq
Imports System.Web.Script.Serialization
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public Class ManageCRMWorkGuide
    Inherits CRMModulePage
    Private categories As DataTable
    Private showGuide As Boolean, showCategories As Boolean, showGuideDelete As Boolean, showCategoryDelete As Boolean
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "WorkGuide_Items"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If Not CRMAccessAllowed Then Return
        Form.Enctype = "multipart/form-data"
        Try
            LoadCategories() : FillBrandLists() : FillCategoryLists()
        Catch ex As Exception
            Field(Of Panel)("pnlBody").Visible = False : ShowError(ex)
        End Try
    End Sub

    Private Sub LoadCategories()
        If categories Is Nothing Then categories = CRMData.Query("dbo.CRM_Select_WorkGuide_Categories", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()))
    End Sub

    Private Sub FillBrandLists()
        Dim brands = CRMData.Query("dbo.CRM_Select_Options", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Kind", SqlDbType.NVarChar, "Brands", 30))
        For Each name In New String() {"filterBrand", "guideBrand", "categoryBrand"}
            Dim list = Field(Of DropDownList)(name)
            list.Items.Clear() : list.Items.Add(New ListItem(If(name = "filterBrand", "كل العلامات التجارية", "اختر العلامة التجارية أولًا"), ""))
            For Each row As DataRow In brands.Rows
                list.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
            Next
            For Each row As DataRow In categories.Rows
                Dim id = Convert.ToString(row("Brand_ID"))
                If list.Items.FindByValue(id) Is Nothing Then list.Items.Add(New ListItem(Convert.ToString(row("Brand_Name")) & " (غير فعالة)", id))
            Next
            Dim posted = Request.Form(list.UniqueID)
            If posted IsNot Nothing AndAlso list.Items.FindByValue(posted) IsNot Nothing Then list.SelectedValue = posted
        Next
    End Sub

    Protected Sub CategoryBrand_Changed(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Field(Of HiddenField)("categorySelected").Value = "" : NewCategory("")
    End Sub

    Private Function Descendants(id As Integer) As HashSet(Of Integer)
        Dim result As New HashSet(Of Integer) From {id}, previous As Integer
        Do
            previous = result.Count
            For Each row As DataRow In categories.Rows
                If Not IsDBNull(row("Parent_ID")) AndAlso result.Contains(CInt(row("Parent_ID"))) Then result.Add(CInt(row("ID")))
            Next
        Loop While result.Count <> previous
        Return result
    End Function

    Private Sub FillCategoryLists()
        Dim filter = Field(Of DropDownList)("filterCategory"), parent = Field(Of DropDownList)("categoryParent")
        Dim selectedFilter = filter.SelectedValue, selectedParent = parent.SelectedValue
        filter.Items.Clear() : filter.Items.Add(New ListItem("كل التصنيفات", ""))
        parent.Items.Clear() : parent.Items.Add(New ListItem("تصنيف رئيسي", ""))
        Dim current = If(ViewState("CategoryEditorID") Is Nothing, 0, CInt(ViewState("CategoryEditorID")))
        Dim excluded = If(current = 0, New HashSet(Of Integer)(), Descendants(current))
        AddCategoryOptions("", "", filter, parent, excluded)
        If filter.Items.FindByValue(selectedFilter) IsNot Nothing Then filter.SelectedValue = selectedFilter
        If parent.Items.FindByValue(selectedParent) IsNot Nothing Then parent.SelectedValue = selectedParent
    End Sub

    Private Sub AddCategoryOptions(parentID As String, indent As String, filter As DropDownList, parent As DropDownList, excluded As HashSet(Of Integer))
        For Each row As DataRow In categories.Rows
            If Convert.ToString(row("Parent_ID"), CultureInfo.InvariantCulture) <> parentID Then Continue For
            Dim id = Convert.ToString(row("ID"), CultureInfo.InvariantCulture), label = indent & Convert.ToString(row("Name_AR")) & " / " & Convert.ToString(row("Name_EN"))
            Dim optionItem As New ListItem(Convert.ToString(row("Brand_Name")) & " — " & label, id)
            optionItem.Attributes("data-brand-id") = Convert.ToString(row("Brand_ID")) : filter.Items.Add(optionItem)
            If Not excluded.Contains(CInt(row("ID"))) AndAlso Convert.ToString(row("Brand_ID")) = Field(Of DropDownList)("categoryBrand").SelectedValue Then parent.Items.Add(New ListItem(label, id))
            AddCategoryOptions(id, indent & "— ", filter, parent, excluded)
        Next
    End Sub

    Protected Overrides Sub PrepareListData(data As DataTable)
        Dim active = data.Rows.Cast(Of DataRow)().Count(Function(r) CBool(r("Is_Active")))
        Field(Of Literal)("statTotal").Text = data.Rows.Count.ToString("N0")
        Field(Of Literal)("statActive").Text = active.ToString("N0")
        Field(Of Literal)("statInactive").Text = (data.Rows.Count - active).ToString("N0")
        Dim category As Integer
        If Integer.TryParse(Field(Of DropDownList)("filterCategory").SelectedValue, category) Then
            Dim ids = Descendants(category)
            For Each row In data.Rows.Cast(Of DataRow)().ToArray()
                Dim linked = Convert.ToString(row("Category_IDs")).Split({","c}, StringSplitOptions.RemoveEmptyEntries)
                If Not linked.Any(Function(id) ids.Contains(Integer.Parse(id, CultureInfo.InvariantCulture))) Then data.Rows.Remove(row)
            Next
        End If
    End Sub

    Protected Sub ResetSearch_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Field(Of DropDownList)("filterBrand").SelectedValue = "" : Field(Of TextBox)("filterName").Text = "" : Field(Of DropDownList)("filterCategory").SelectedValue = "" : Field(Of DropDownList)("filterStatus").SelectedValue = ""
        MyBase.Search_Click(sender, e)
    End Sub

    Protected Sub NewGuide_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        ViewState("GuideEditorID") = 0 : ViewState.Remove("GuideEditorVersion")
        Field(Of DropDownList)("guideBrand").SelectedValue = Field(Of DropDownList)("filterBrand").SelectedValue
        For Each name In New String() {"guideNameAr", "guideNameEn", "guideSummaryAr", "guideSummaryEn", "guideDetailsAr", "guideDetailsEn"}
            Field(Of TextBox)(name).Text = ""
        Next
        Field(Of TextBox)("guideOrder").Text = "0" : Field(Of CheckBox)("guideActive").Checked = True
        Field(Of HiddenField)("guideCategoryIDs").Value = "" : Field(Of Literal)("litGuideFile").Text = "أرفق ملف PDF أو Word (حتى 10 ميجابايت)."
        Field(Of Literal)("litGuideTitle").Text = "إضافة دليل عمل" : showGuide = True
    End Sub

    Private Function RenderedGuideKey(e As ListViewCommandEventArgs) As DataKey
        Dim id As Integer, key = Field(Of ListView)("lstData").DataKeys(e.Item.DataItemIndex)
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 OrElse CInt(key.Values("ID")) <> id Then Throw New InvalidOperationException("حدّث القائمة وأعد المحاولة.")
        Return key
    End Function

    Protected Sub Guide_RowCommand(sender As Object, e As ListViewCommandEventArgs)
        If Not CRMAccessAllowed Then Return
        Try
            Dim key = RenderedGuideKey(e), id = CInt(key.Values("ID")), version = DirectCast(key.Values("Row_Version"), Byte())
            Dim data = CRMData.Rows(EntityName, CrmUserId(), id)
            If data.Rows.Count = 0 Then Throw New InvalidOperationException("الدليل غير متاح؛ حدّث القائمة.")
            Dim row = data.Rows(0)
            Select Case e.CommandName
                Case "EditGuide"
                    ViewState("GuideEditorID") = id : ViewState("GuideEditorVersion") = row("Row_Version")
                    Field(Of DropDownList)("guideBrand").SelectedValue = Convert.ToString(row("Brand_ID"))
                    Dim fields As New Dictionary(Of String, String) From {{"guideNameAr", "Name_AR"}, {"guideNameEn", "Name_EN"}, {"guideSummaryAr", "Summary_AR"}, {"guideSummaryEn", "Summary_EN"}, {"guideDetailsAr", "Details_AR"}, {"guideDetailsEn", "Details_EN"}, {"guideOrder", "Sort_Order"}}
                    For Each pair In fields : Field(Of TextBox)(pair.Key).Text = Convert.ToString(row(pair.Value)) : Next
                    Field(Of HiddenField)("guideCategoryIDs").Value = Convert.ToString(row("Category_IDs"))
                    Field(Of CheckBox)("guideActive").Checked = CBool(row("Is_Active"))
                    Field(Of Literal)("litGuideFile").Text = "الملف الحالي: " & Convert.ToString(row("File_Name")) & "؛ اترك التحميل فارغًا للاحتفاظ به."
                    Field(Of Literal)("litGuideTitle").Text = "تعديل دليل العمل" : showGuide = True
                    LogRead("WorkGuide_Items", id)
                Case "AskDelete"
                    ViewState("GuideDeleteID") = id : ViewState("GuideDeleteVersion") = version
                    Field(Of Literal)("litGuideDeleteName").Text = Convert.ToString(row("Name_AR")) : showGuideDelete = True
                Case "Activate", "Deactivate"
                    CRMData.Query("dbo.CRM_Set_WorkGuide_Active", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Is_Active", SqlDbType.Bit, e.CommandName = "Activate"), CRMData.P("@Version", SqlDbType.Binary, version, 8))
                    ShowSuccess("تم تحديث حالة دليل العمل.")
            End Select
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Private Function SelectedGuideCategories() As XElement
        Dim value = Field(Of HiddenField)("guideCategoryIDs").Value
        If value.Length > 20000 Then Throw New InvalidOperationException("التصنيفات المحددة غير صحيحة.")
        Dim selected As New HashSet(Of Integer), available = New HashSet(Of Integer)(categories.Rows.Cast(Of DataRow)().Where(Function(r) Convert.ToString(r("Brand_ID")) = Field(Of DropDownList)("guideBrand").SelectedValue).Select(Function(r) CInt(r("ID"))))
        For Each item In value.Split({","c}, StringSplitOptions.RemoveEmptyEntries)
            Dim id As Integer
            If Not Integer.TryParse(item, id) OrElse Not available.Contains(id) Then Throw New InvalidOperationException("أحد التصنيفات غير متاح؛ حدّث القائمة.")
            selected.Add(id)
        Next
        If selected.Count = 0 OrElse selected.Count > 1000 Then Throw New InvalidOperationException("اختر تصنيفًا واحدًا على الأقل (حتى 1000 تصنيف).")
        Return New XElement("categories", selected.Select(Function(id) New XElement("id", id)))
    End Function

    Protected Sub SaveGuide_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        showGuide = True : Validate("GuideEditor") : If Not IsValid Then Return
        Dim staged As CRMWorkGuideFile = Nothing
        Try
            If ViewState("GuideEditorID") Is Nothing Then Throw New InvalidOperationException("افتح نموذج الإضافة أو التعديل أولًا.")
            Dim id = CInt(ViewState("GuideEditorID")), selected = SelectedGuideCategories()
            Dim data As New XElement("row", New XElement("Brand_ID", Field(Of DropDownList)("guideBrand").SelectedValue), New XElement("Name_AR", Field(Of TextBox)("guideNameAr").Text.Trim()), New XElement("Name_EN", Field(Of TextBox)("guideNameEn").Text.Trim()), New XElement("Summary_AR", Field(Of TextBox)("guideSummaryAr").Text.Trim()), New XElement("Summary_EN", Field(Of TextBox)("guideSummaryEn").Text.Trim()), New XElement("Sort_Order", Field(Of TextBox)("guideOrder").Text.Trim()), New XElement("Is_Active", If(Field(Of CheckBox)("guideActive").Checked, "1", "0")))
            Dim detailsAr = CRMWorkGuideContent.Clean(Field(Of TextBox)("guideDetailsAr").Text), detailsEn = CRMWorkGuideContent.Clean(Field(Of TextBox)("guideDetailsEn").Text)
            If (detailsAr = "") <> (detailsEn = "") Then Throw New ArgumentException("أدخل التفاصيل بالعربية والإنجليزية معًا.")
            data.Add(New XElement("Details_AR", detailsAr), New XElement("Details_EN", detailsEn))
            staged = CRMWorkGuideFile.SaveUpload(Field(Of FileUpload)("guideUpload").PostedFile)
            If staged IsNot Nothing Then data.Add(New XElement("File_Url", staged.Url), New XElement("File_Name", staged.OriginalName), New XElement("File_Extension", staged.Extension), New XElement("File_Size", staged.Size))
            CRMData.Query("dbo.CRM_Save_WorkGuide_Item", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Data", SqlDbType.Xml, data.ToString()), CRMData.P("@Categories", SqlDbType.Xml, selected.ToString()), CRMData.P("@Version", SqlDbType.Binary, ViewState("GuideEditorVersion"), 8))
            staged = Nothing : showGuide = False : ViewState.Remove("GuideEditorID") : ViewState.Remove("GuideEditorVersion")
            ShowSuccess("تم حفظ دليل العمل بنجاح.")
        Catch ex As Exception
            If staged IsNot Nothing Then staged.Cleanup()
            Field(Of Literal)("litGuideMessage").Text = AlertMarkup(ErrorText(ex), True)
        End Try
    End Sub

    Protected Sub ConfirmGuideDelete_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Try
            If ViewState("GuideDeleteID") Is Nothing Then Throw New InvalidOperationException("اختر الدليل المراد حذفه أولًا.")
            Dim id = ViewState("GuideDeleteID"), version = ViewState("GuideDeleteVersion")
            ViewState.Remove("GuideDeleteID") : ViewState.Remove("GuideDeleteVersion")
            CRMData.Query("dbo.CRM_Delete_WorkGuide_Item", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Version", SqlDbType.Binary, version, 8))
            ShowSuccess("تم حذف دليل العمل بنجاح.")
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Private Sub NewCategory(parent As String)
        ViewState("CategoryEditorID") = 0 : ViewState.Remove("CategoryEditorVersion") : FillCategoryLists()
        Field(Of TextBox)("categoryNameAr").Text = "" : Field(Of TextBox)("categoryNameEn").Text = "" : Field(Of TextBox)("categoryOrder").Text = "0"
        If Field(Of DropDownList)("categoryParent").Items.FindByValue(parent) Is Nothing Then Throw New InvalidOperationException("التصنيف الأب غير متاح.")
        Field(Of DropDownList)("categoryParent").SelectedValue = parent
        Field(Of Literal)("litCategoryTitle").Text = If(parent = "", "إضافة تصنيف رئيسي", "إضافة تصنيف فرعي") : showCategories = True
    End Sub

    Protected Sub ManageCategories_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        If Field(Of DropDownList)("filterBrand").SelectedValue <> "" Then Field(Of DropDownList)("categoryBrand").SelectedValue = Field(Of DropDownList)("filterBrand").SelectedValue
        NewCategory("") : LogRead("WorkGuide_Categories", Nothing)
    End Sub

    Private Function SelectedCategoryID() As Integer
        Dim id As Integer, versions = TryCast(ViewState("CategoryVersions"), Dictionary(Of Integer, Byte()))
        If Not Integer.TryParse(Field(Of HiddenField)("categorySelected").Value, id) OrElse versions Is Nothing OrElse Not versions.ContainsKey(id) Then Throw New InvalidOperationException("اختر تصنيفًا من الشجرة أولًا.")
        If Not categories.Rows.Cast(Of DataRow)().Any(Function(r) CInt(r("ID")) = id AndAlso Convert.ToString(r("Brand_ID")) = Field(Of DropDownList)("categoryBrand").SelectedValue) Then Throw New InvalidOperationException("اختر تصنيفًا تابعًا للعلامة التجارية المحددة.")
        Return id
    End Function

    Protected Sub CategoryAction_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        showCategories = True
        Try
            Dim action = DirectCast(sender, LinkButton).CommandName
            If action = "Root" Then NewCategory("") : Return
            Dim id = SelectedCategoryID()
            Dim rows = categories.Rows.Cast(Of DataRow)().Where(Function(r) CInt(r("ID")) = id).ToArray()
            If rows.Length = 0 Then Throw New InvalidOperationException("التصنيف غير متاح؛ حدّث القائمة.")
            Dim row = rows(0)
            Select Case action
                Case "Child"
                    NewCategory(id.ToString(CultureInfo.InvariantCulture))
                Case "Edit"
                    ViewState("CategoryEditorID") = id : ViewState("CategoryEditorVersion") = row("Row_Version") : FillCategoryLists()
                    Field(Of TextBox)("categoryNameAr").Text = Convert.ToString(row("Name_AR")) : Field(Of TextBox)("categoryNameEn").Text = Convert.ToString(row("Name_EN")) : Field(Of TextBox)("categoryOrder").Text = Convert.ToString(row("Sort_Order"))
                    Field(Of DropDownList)("categoryParent").SelectedValue = Convert.ToString(row("Parent_ID"))
                    Field(Of Literal)("litCategoryTitle").Text = "تعديل التصنيف" : LogRead("WorkGuide_Categories", id)
                Case "Delete"
                    ViewState("CategoryDeleteID") = id : ViewState("CategoryDeleteVersion") = DirectCast(ViewState("CategoryVersions"), Dictionary(Of Integer, Byte()))(id)
                    Field(Of Literal)("litCategoryDeleteName").Text = Convert.ToString(row("Name_AR")) : showCategoryDelete = True : showCategories = False
            End Select
        Catch ex As Exception
            Field(Of Literal)("litCategoryMessage").Text = AlertMarkup(ErrorText(ex), True)
        End Try
    End Sub

    Protected Sub SaveCategory_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        showCategories = True : Validate("CategoryEditor") : If Not IsValid Then Return
        Try
            If ViewState("CategoryEditorID") Is Nothing Then Throw New InvalidOperationException("افتح نموذج التصنيف أولًا.")
            Dim data As New XElement("row", New XElement("Brand_ID", Field(Of DropDownList)("categoryBrand").SelectedValue), New XElement("Name_AR", Field(Of TextBox)("categoryNameAr").Text.Trim()), New XElement("Name_EN", Field(Of TextBox)("categoryNameEn").Text.Trim()), New XElement("Sort_Order", Field(Of TextBox)("categoryOrder").Text.Trim()), New XElement("Parent_ID", Field(Of DropDownList)("categoryParent").SelectedValue))
            Dim result = CRMData.Query("dbo.CRM_Save_WorkGuide_Category", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, ViewState("CategoryEditorID")), CRMData.P("@Data", SqlDbType.Xml, data.ToString()), CRMData.P("@Version", SqlDbType.Binary, ViewState("CategoryEditorVersion"), 8))
            Field(Of HiddenField)("categorySelected").Value = Convert.ToString(result.Rows(0)("ID"))
            categories = Nothing : LoadCategories() : NewCategory("")
            Field(Of Literal)("litCategoryMessage").Text = AlertMarkup("تم حفظ التصنيف بنجاح.", False)
        Catch ex As Exception
            Field(Of Literal)("litCategoryMessage").Text = AlertMarkup(ErrorText(ex), True)
        End Try
    End Sub

    Protected Sub ConfirmCategoryDelete_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        showCategories = True
        Try
            If ViewState("CategoryDeleteID") Is Nothing Then Throw New InvalidOperationException("اختر التصنيف المراد حذفه أولًا.")
            Dim id = ViewState("CategoryDeleteID"), version = ViewState("CategoryDeleteVersion")
            ViewState.Remove("CategoryDeleteID") : ViewState.Remove("CategoryDeleteVersion")
            CRMData.Query("dbo.CRM_Delete_WorkGuide_Category", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Version", SqlDbType.Binary, version, 8))
            categories = Nothing : LoadCategories() : Field(Of HiddenField)("categorySelected").Value = "" : NewCategory("")
            Field(Of Literal)("litCategoryMessage").Text = AlertMarkup("تم حذف التصنيف بنجاح.", False)
        Catch ex As Exception
            Field(Of Literal)("litCategoryMessage").Text = AlertMarkup(ErrorText(ex), True)
        End Try
    End Sub

    Private Sub LogRead(entity As String, id As Object)
        CRMData.Query("dbo.CRM_Log_Read", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Entity", SqlDbType.NVarChar, entity, 80), CRMData.P("@ID", SqlDbType.Int, id))
    End Sub

    Private Function ErrorText(ex As Exception) As String
        Return If(TypeOf ex Is ArgumentException, ex.Message, CRMData.ErrorMessage(ex))
    End Function
    Private Function AlertMarkup(message As String, failed As Boolean) As String
        Return "<div class='alert alert-" & If(failed, "danger", "success") & " alert-dismissible' role='alert'><span>" & CRMData.H(message) & "</span><button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='إغلاق'></button></div>"
    End Function
    Protected Overrides Sub ShowError(ex As Exception)
        Field(Of Literal)("litMessage").Text = AlertMarkup(ErrorText(ex), True)
    End Sub
    Protected Overrides Sub ShowSuccess(message As String)
        Field(Of Literal)("litMessage").Text = AlertMarkup(message, False)
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        If CRMAccessAllowed Then
            Try
                LoadCategories() : FillCategoryLists()
                Dim versions As New Dictionary(Of Integer, Byte()), nodes As New List(Of Object)
                For Each row As DataRow In categories.Rows
                    Dim id = CInt(row("ID")) : versions(id) = DirectCast(row("Row_Version"), Byte())
                    nodes.Add(New With {.id = id.ToString(CultureInfo.InvariantCulture), .brandId = Convert.ToString(row("Brand_ID")), .parent = If(IsDBNull(row("Parent_ID")), "#", Convert.ToString(row("Parent_ID"), CultureInfo.InvariantCulture)), .text = Convert.ToString(row("Name_AR")) & " / " & Convert.ToString(row("Name_EN")), .icon = "bx bx-folder", .state = New With {.opened = True}})
                Next
                ViewState("CategoryVersions") = versions
                Field(Of Literal)("litTreeData").Text = New JavaScriptSerializer().Serialize(nodes).Replace("<", "\u003c").Replace(">", "\u003e").Replace("&", "\u0026")
            Catch ex As Exception
                ShowError(ex)
            End Try
        End If
        MyBase.OnPreRender(e)
        If Not CRMAccessAllowed Then Return
        If showGuide Then OpenPanel("crmGuideEditor", "Offcanvas")
        If showCategories Then OpenPanel("crmCategories", "Offcanvas")
        If showGuideDelete Then OpenPanel("crmGuideDeleteModal", "Modal")
        If showCategoryDelete Then OpenPanel("crmCategoryDeleteModal", "Modal")
    End Sub
    Private Sub OpenPanel(id As String, kind As String)
        Dim script = "(function(){function openPanel(){var el=document.getElementById('" & id & "');if(el&&window.bootstrap)bootstrap." & kind & ".getOrCreateInstance(el).show();}if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',openPanel,{once:true});}else{openPanel();}}());"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), id, script, True)
    End Sub
End Class
