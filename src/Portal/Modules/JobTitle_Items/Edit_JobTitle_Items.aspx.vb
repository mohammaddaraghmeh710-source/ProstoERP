Imports System.Linq
Imports System.Collections.Generic
Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Edit_JobTitle_Items
    Inherits PageBase

    Private WorkingMethodVideo_path As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If

        If Not IsPostBack Then

            ' تعبئة القوائم العامة
            FillMaintenanceCompanies()
            FillItemTypes()
            FillBrands()

            ResetBranchDepartmentJob()

            ' قراءة ID من QueryString
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("ID"), id) Then
                SystemAdministrationUI.Redirect(Me, "/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
                Return
            End If

            hdnID.Value = id.ToString()

            ' تعبئة بيانات العنصر
            LoadItem(id)
        End If
    End Sub

    '================= تحميل بيانات العنصر =================

    Private Sub LoadItem(id As Integer)

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim row = db.Select_JobTitle_Items_ByID(id).FirstOrDefault()
            If row Is Nothing Then
                SystemAdministrationUI.Redirect(Me, "/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
                Return
            End If

            ' الحقول الأساسية
            txtTitleAr.Text = row.Title_Ar
            txtTitleEn.Text = row.Title_En
            txtToolNumber.Text = If(row.Tool_Number, "")

            ' Keep the current historical supplier available for unchanged edits.
            FillSuppliers(row.Supplier_Account_ID)
            ddlSupplier.Attributes("data-current-account") = Convert.ToString(row.Supplier_Account_ID)
            If row.Supplier_Account_ID IsNot Nothing Then
                ddlSupplier.SelectedValue = row.Supplier_Account_ID.ToString()
            Else
                ddlSupplier.SelectedValue = ""
            End If

            If row.MaintenanceCompanyID IsNot Nothing Then
                ddlMaintenanceCompany.SelectedValue = row.MaintenanceCompanyID.ToString()
            Else
                ddlMaintenanceCompany.SelectedValue = ""
            End If

            If row.ItemTypeID IsNot Nothing Then
                ddlItemType.SelectedValue = row.ItemTypeID.ToString()
            Else
                ddlItemType.SelectedValue = ""
            End If

            ' سياسات
            txtPolicies_Ar.Text = If(row.Policies_Ar, "")
            txtPolicies_En.Text = If(row.Policies_En, "")

            ' الحالة
            ddlIsActive.SelectedValue = If(Convert.ToBoolean(row.IsActive), "1", "0")

            ' فيديوهات حالية (حفظها في Hidden للاحتفاظ بها إن لم يتم رفع جديد)
            hdnWorkingVideoAr.Value = If(row.Working_Method_Video_Ar, "")
            hdnWorkingVideoEn.Value = If(row.Working_Method_Video_En, "")
            hdnEvalVideoAr.Value = If(row.Evaluation_Method_Video_Ar, "")
            hdnEvalVideoEn.Value = If(row.Evaluation_Method_Video_En, "")

            ' عرض اسم الفيديو الحالي (اختياري)
            litWorkingCurrent.Text =
                If _
                    (String.IsNullOrEmpty(hdnWorkingVideoAr.Value), "<span class='text-muted'>لا يوجد فيديو حالي</span>",
                     "<span class='text-success'>يوجد فيديو حالي</span>")
            litEvalCurrent.Text =
                If _
                    (String.IsNullOrEmpty(hdnEvalVideoAr.Value), "<span class='text-muted'>لا يوجد فيديو حالي</span>",
                     "<span class='text-success'>يوجد فيديو حالي</span>")

            '================ الهيكل التنظيمي =================
            Dim jobTitleId = CInt(row.JobTitle_ID)

            Dim org = GetOrgByJobTitleId(jobTitleId)
            ' org: BrandID/BranchID/DepartmentID

            ' Brand
            ddlBrand.SelectedValue = org.BrandID.ToString()
            ddlSupplier.Attributes("data-current-brand") = org.BrandID.ToString()

            ' Branch
            FillBranches(org.BrandID)
            ddlBranch.SelectedValue = org.BranchID.ToString()

            ' Department
            FillDepartments(org.BranchID)
            ddlDepartment.SelectedValue = org.DepartmentID.ToString()

            ' JobTitle
            FillJobTitles(org.DepartmentID)
            ddlJobTitle.SelectedValue = jobTitleId.ToString()

        End Using
    End Sub

    Private Class OrgResult
        Public Property BrandID As Integer
        Public Property BranchID As Integer
        Public Property DepartmentID As Integer
    End Class

    Private Function GetOrgByJobTitleId(jobTitleId As Integer) As OrgResult
        Using db As New Prosto_ERP_DataClassesDataContext

            Dim q = (From jt In db.Select_JobTitles_All
                    Join d In db.Select_Departments_All On jt.DepartmentID Equals d.ID
                    Join b In db.Select_Branches_All On d.BranchID Equals b.ID
                    Where jt.ID = jobTitleId AndAlso jt.IsDeleted = 0 AndAlso d.IsDeleted = 0 AndAlso b.IsDeleted = 0
                    Select New OrgResult With {
                    .DepartmentID = d.ID,
                    .BranchID = b.ID,
                    .BrandID = b.BrandID
                    }).FirstOrDefault()

            If q Is Nothing Then
                ' fallback لو البيانات غير موجودة
                Return New OrgResult With {.BrandID = 0, .BranchID = 0, .DepartmentID = 0}
            End If

            Return q
        End Using
    End Function

    '================= الهيكل التنظيمي (مثل الإضافة) =================

    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Brands_All().Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBrand.DataSource = data
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("اختر العلامة", ""))
    End Sub

    Private Sub FillBranches(Optional brandId As Integer? = Nothing)
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))

        If Not brandId.HasValue OrElse brandId.Value = 0 Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(brandId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        End Using
    End Sub

    Private Sub FillDepartments(Optional branchId As Integer? = Nothing)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))

        If Not branchId.HasValue OrElse branchId.Value = 0 Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Departments_ByBranchID(branchId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlDepartment.DataSource = data
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()
            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        End Using
    End Sub

    Private Sub FillJobTitles(Optional departmentId As Integer? = Nothing)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))

        If Not departmentId.HasValue OrElse departmentId.Value = 0 Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data =
                    db.Select_JobTitles_ByDepartmentID(departmentId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlJobTitle.DataSource = data
            ddlJobTitle.DataTextField = "Title_Ar"
            ddlJobTitle.DataValueField = "ID"
            ddlJobTitle.DataBind()
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
        End Using
    End Sub

    Private Sub ResetBranchDepartmentJob()
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId As Integer?
        If Integer.TryParse(ddlBrand.SelectedValue, Nothing) Then
            brandId = CInt(ddlBrand.SelectedValue)
        Else
            brandId = Nothing
        End If

        FillBranches(brandId)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim branchId As Integer?
        If Integer.TryParse(ddlBranch.SelectedValue, Nothing) Then
            branchId = CInt(ddlBranch.SelectedValue)
        Else
            branchId = Nothing
        End If

        FillDepartments(branchId)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer?
        If Integer.TryParse(ddlDepartment.SelectedValue, Nothing) Then
            deptId = CInt(ddlDepartment.SelectedValue)
        Else
            deptId = Nothing
        End If

        FillJobTitles(deptId)
    End Sub

    '================= قوائم المورد/الصيانة/النوع =================

    ' ListItem custom attributes are not restored by DropDownList ViewState on AJAX cascades.
    ' Restore metadata without rebinding the registered values or losing the posted selection.
    Protected Sub SupplierMetadata_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Dim currentAccountId As Integer? = Nothing
        Dim itemID As Integer
        If Integer.TryParse(Request.QueryString("ID"), itemID) Then
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                Dim item = db.Select_JobTitle_Items_ByID(itemID).FirstOrDefault()
                If item IsNot Nothing Then
                    currentAccountId = item.Supplier_Account_ID
                    ddlSupplier.Attributes("data-current-account") = Convert.ToString(currentAccountId)
                    ddlSupplier.Attributes("data-current-brand") = GetOrgByJobTitleId(CInt(item.JobTitle_ID)).BrandID.ToString()
                End If
            End Using
        End If
        Dim rows As New Dictionary(Of String, System.Data.DataRow)(StringComparer.Ordinal)
        For Each row As System.Data.DataRow In CRMSupplierData.Options(SessionManager.GetInstance.Users.UserID, currentAccountId).Rows
            rows(Convert.ToString(row("ID"))) = row
        Next
        For Each optionItem As ListItem In ddlSupplier.Items
            If String.IsNullOrEmpty(optionItem.Value) Then Continue For
            If rows.ContainsKey(optionItem.Value) Then
                Dim row = rows(optionItem.Value)
                optionItem.Attributes("data-brand-ids") = Convert.ToString(row("Brand_IDs"))
                optionItem.Attributes("data-available") = If(Convert.ToBoolean(row("Is_Available")), "1", "0")
            Else
                optionItem.Attributes("data-brand-ids") = ""
                optionItem.Attributes("data-available") = "0"
            End If
        Next
    End Sub

    Private Sub FillSuppliers(Optional currentAccountId As Integer? = Nothing)
        ddlSupplier.Items.Clear()
        For Each row As System.Data.DataRow In CRMSupplierData.Options(SessionManager.GetInstance.Users.UserID, currentAccountId).Rows
            Dim nameAr = Convert.ToString(row("Name_AR"))
            Dim nameEn = Convert.ToString(row("Name_EN"))
            Dim name = nameAr & If(String.IsNullOrWhiteSpace(nameEn), "", " — " & nameEn)
            Dim item As New ListItem(name, Convert.ToString(row("ID")))
            item.Attributes("data-brand-ids") = Convert.ToString(row("Brand_IDs"))
            item.Attributes("data-available") = If(Convert.ToBoolean(row("Is_Available")), "1", "0")
            ddlSupplier.Items.Add(item)
        Next
        ddlSupplier.Items.Insert(0, New ListItem("اختر المورد من العملاء", ""))
    End Sub

    Private Function SupplierMatchesBrand(accountId As Integer?, brandId As Integer?, Optional currentAccountId As Integer? = Nothing) As Boolean
        If Not accountId.HasValue OrElse Not brandId.HasValue Then Return False
        Dim optionKey = "ToolSupplierOptions:" & If(currentAccountId.HasValue, currentAccountId.Value.ToString(), "available")
        Dim options = TryCast(Context.Items(optionKey), System.Data.DataTable)
        If options Is Nothing Then
            options = CRMSupplierData.Options(SessionManager.GetInstance.Users.UserID, currentAccountId)
            Context.Items(optionKey) = options
        End If
        For Each row As System.Data.DataRow In options.Rows
            If Convert.ToInt32(row("ID")) <> accountId.Value Then Continue For
            Dim brands = Convert.ToString(row("Brand_IDs")).Split(","c)
            Dim belongs = brands.Any(Function(value) value.Trim() = brandId.Value.ToString())
            Return belongs AndAlso (Convert.ToBoolean(row("Is_Available")) OrElse (currentAccountId.HasValue AndAlso currentAccountId.Value = accountId.Value))
        Next
        Return False
    End Function

    Private Sub FillMaintenanceCompanies()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Maintenance_Companies_All().ToList()
            ddlMaintenanceCompany.DataSource = data
            ddlMaintenanceCompany.DataTextField = "Title_Ar"
            ddlMaintenanceCompany.DataValueField = "ID"
            ddlMaintenanceCompany.DataBind()
        End Using
        ddlMaintenanceCompany.Items.Insert(0, New ListItem("اختر شركة الصيانة", ""))
    End Sub

    Private Sub FillItemTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitle_Items_Types_All().ToList()
            ddlItemType.DataSource = data
            ddlItemType.DataTextField = "Title_Ar"
            ddlItemType.DataValueField = "ID"
            ddlItemType.DataBind()
        End Using
        ddlItemType.Items.Insert(0, New ListItem("اختر نوع الأداة", ""))
    End Sub

    '================= حفظ التعديل =================

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Return

        Dim id = CInt(hdnID.Value)
        Dim jobTitleId = CInt(ddlJobTitle.SelectedValue)

        cvSupplier.IsValid = True
        Dim currentSupplier As Integer? = Nothing
        Using currentDb As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim current = currentDb.Select_JobTitle_Items_ByID(id).FirstOrDefault()
            If current Is Nothing Then
                cvSupplier.IsValid = False
                Return
            End If
            Dim originalBrand = GetOrgByJobTitleId(CInt(current.JobTitle_ID)).BrandID
            If ddlBrand.SelectedValue = originalBrand.ToString() Then currentSupplier = current.Supplier_Account_ID
        End Using
        Dim selectedSupplier As Integer
        Dim selectedBrand As Integer
        If Not Integer.TryParse(ddlSupplier.SelectedValue, selectedSupplier) OrElse
           Not Integer.TryParse(ddlBrand.SelectedValue, selectedBrand) OrElse
           Not SupplierMatchesBrand(selectedSupplier, selectedBrand, currentSupplier) Then
            cvSupplier.IsValid = False
            Return
        End If

        Dim toolNumber As String = txtToolNumber.Text.Trim()
        Dim supplierAccountId As Integer? = If(String.IsNullOrEmpty(ddlSupplier.SelectedValue), CType(Nothing, Integer?), CInt(ddlSupplier.SelectedValue))
        Dim maintenanceId As Integer? = If(String.IsNullOrEmpty(ddlMaintenanceCompany.SelectedValue), CType(Nothing, Integer?), CInt(ddlMaintenanceCompany.SelectedValue))
        Dim itemTypeId As Integer? = If(String.IsNullOrEmpty(ddlItemType.SelectedValue), CType(Nothing, Integer?), CInt(ddlItemType.SelectedValue))

        Dim nameAr As String = txtTitleAr.Text
        Dim nameEn As String = txtTitleEn.Text

        '================= الفيديوهات =================
        ' لو تم رفع جديد: نأخذ الجديد، وإلا نحتفظ بالقديم من Hidden

        Dim wm = SaveWorkingMethodVideoFromSession()
        If wm IsNot Nothing AndAlso wm.Count > 0 Then
            For Each f In wm
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        Else
            WorkingMethodVideo_path = hdnWorkingVideoAr.Value
        End If

        Dim ev = SaveEvaluationMethodVideoFromSession()
        If ev IsNot Nothing AndAlso ev.Count > 0 Then
            For Each f In ev
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        Else
            EvaluationMethodVideo_path = hdnEvalVideoAr.Value
        End If

        Dim isActive As Boolean = (ddlIsActive.SelectedValue = "1")

        Using db As New Prosto_ERP_DataClassesDataContext
            db.Update_JobTitle_Items_ByID(
                id,
                jobTitleId,
                nameAr,
                nameEn,
                toolNumber,
                supplierAccountId,
                maintenanceId,
                itemTypeId,
                txtPolicies_Ar.Text,
                txtPolicies_En.Text,
                WorkingMethodVideo_path,
                WorkingMethodVideo_path,
                EvaluationMethodVideo_path,
                EvaluationMethodVideo_path,
                SessionManager.GetInstance.Users.UserID,
                isActive
                )
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx", True)
    End Sub

    '================= Ajax Upload =================

    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub
End Class


