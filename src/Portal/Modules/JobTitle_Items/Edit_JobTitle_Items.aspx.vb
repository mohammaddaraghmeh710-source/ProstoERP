Imports System.Linq
Imports AjaxControlToolkit

Public Class Edit_JobTitle_Items
    Inherits PageBase

    Private WorkingMethodVideo_path As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then

            ' تعبئة القوائم العامة
            FillSuppliers()
            FillMaintenanceCompanies()
            FillItemTypes()
            FillBrands()

            ResetBranchDepartmentJob()

            ' قراءة ID من QueryString
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("ID"), id) Then
                Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
                Return
            End If

            hdnID.Value = id.ToString()

            ' تعبئة بيانات العنصر
            LoadItem(id)
        End If

    End Sub

    '================= تحميل بيانات العنصر =================

    Private Sub LoadItem(ByVal id As Integer)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim row = db.Select_JobTitle_Items_ByID(id).FirstOrDefault()
            If row Is Nothing Then
                Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
                Return
            End If

            ' الحقول الأساسية
            txtTitleAr.Text = row.Title_Ar
            txtTitleEn.Text = row.Title_En
            txtToolNumber.Text = If(row.Tool_Number, "")

            ' DropDowns (Supplier / Maintenance / Type)
            If row.SupplierID IsNot Nothing Then
                ddlSupplier.SelectedValue = row.SupplierID.ToString()
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
            litWorkingCurrent.Text = If(String.IsNullOrEmpty(hdnWorkingVideoAr.Value), "<span class='text-muted'>لا يوجد فيديو حالي</span>", "<span class='text-success'>يوجد فيديو حالي</span>")
            litEvalCurrent.Text = If(String.IsNullOrEmpty(hdnEvalVideoAr.Value), "<span class='text-muted'>لا يوجد فيديو حالي</span>", "<span class='text-success'>يوجد فيديو حالي</span>")

            '================ الهيكل التنظيمي =================
            Dim jobTitleId As Integer = CInt(row.JobTitle_ID)

            Dim org = GetOrgByJobTitleId(jobTitleId)
            ' org: BrandID/BranchID/DepartmentID

            ' Brand
            ddlBrand.SelectedValue = org.BrandID.ToString()

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

    Private Function GetOrgByJobTitleId(ByVal jobTitleId As Integer) As OrgResult
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_ByDepartmentID(departmentId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
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

    Private Sub FillSuppliers()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Suppliers_All().ToList()
            ddlSupplier.DataSource = data
            ddlSupplier.DataTextField = "Title_Ar"
            ddlSupplier.DataValueField = "ID"
            ddlSupplier.DataBind()
        End Using
        ddlSupplier.Items.Insert(0, New ListItem("اختر الشركة الموردة", ""))
    End Sub

    Private Sub FillMaintenanceCompanies()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Maintenance_Companies_All().ToList()
            ddlMaintenanceCompany.DataSource = data
            ddlMaintenanceCompany.DataTextField = "Title_Ar"
            ddlMaintenanceCompany.DataValueField = "ID"
            ddlMaintenanceCompany.DataBind()
        End Using
        ddlMaintenanceCompany.Items.Insert(0, New ListItem("اختر شركة الصيانة", ""))
    End Sub

    Private Sub FillItemTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Dim id As Integer = CInt(hdnID.Value)
        Dim jobTitleId As Integer = CInt(ddlJobTitle.SelectedValue)

        Dim toolNumber As String = txtToolNumber.Text.Trim()
        Dim supplierId As Integer? = If(String.IsNullOrEmpty(ddlSupplier.SelectedValue), CType(Nothing, Integer?), CInt(ddlSupplier.SelectedValue))
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Update_JobTitle_Items_ByID(
                id,
                jobTitleId,
                nameAr,
                nameEn,
                toolNumber,
                supplierId,
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

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
    End Sub

    '================= Ajax Upload =================

    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

End Class
