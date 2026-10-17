Imports System.Linq

Public Class AddChecklist_Employees
    Inherits PageBase

    Private Const FixedBrandId As Integer = 26
    Private Const FixedJobTitleItemId As Integer = 0 ' لم يعد مستخدماً، نعتمد على ddlJobTitleItem (اختياري)

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            FillUsersTypes()
            FillBrands()
            fillChecklist_Categories()
            FillShifts()

            ddlBranch.Items.Insert(0, New ListItem("الكل", ""))
            ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))
            ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))
            ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))
        End If
    End Sub

    Private Sub FillUsersTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim UsersTypes = db.Select_Users_Types_All().
                              Where(Function(x) x.IsDeleted = 0 And x.ID <> 1).OrderBy(Function(o) o.Item_Order).ToList()

            ddlUsersType.DataSource = UsersTypes
            ddlUsersType.DataTextField = "Title_Ar"
            ddlUsersType.DataValueField = "ID"
            ddlUsersType.DataBind()
            ddlUsersType.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub


    '=============== تعبئة العلامة التجارية 
    Private Sub FillBrands()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim branches = db.Select_Brands_All().
                              Where(Function(x) x.IsDeleted = 0).ToList()

            ddlBrands.DataSource = branches
            ddlBrands.DataTextField = "Title_Ar"
            ddlBrands.DataValueField = "ID"
            ddlBrands.DataBind()
            ddlBrands.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    '=============== تعبئة الافرع حسب الالعلامة التجارية
    Protected Sub ddlBrands_SelectedIndexChanged(sender As Object, e As EventArgs)

        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("الكل", ""))

        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))


        If ddlBrands.SelectedValue <> 0 Then

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                Dim BrandID As Integer = CInt(ddlBrands.SelectedValue)
                Dim Branches = db.Select_Branches_ByBrandID(BrandID).
                                       Where(Function(x) x.IsDeleted = 0).ToList()

                ddlBranch.DataSource = Branches
                ddlBranch.DataTextField = "Title_Ar"
                ddlBranch.DataValueField = "ID"
                ddlBranch.DataBind()
                ddlBranch.Items.Insert(0, New ListItem("الكل", ""))
            End Using

        End If


    End Sub




    Private Sub FillBranches()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(FixedBrandId).
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        End Using
    End Sub

    '=============== تعبئة تصنيفات الـ Checklist
    Private Sub fillChecklist_Categories()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Checklist_Employee_Categories_SelectAll().
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlChecklistCategories.DataSource = data
            ddlChecklistCategories.DataTextField = "Title_Ar"
            ddlChecklistCategories.DataValueField = "ID"
            ddlChecklistCategories.DataBind()
            ddlChecklistCategories.Items.Insert(0, New ListItem("اختر التصنيف", ""))
        End Using
    End Sub

    '=============== تعبئة الأقسام حسب الفرع
    Private Sub FillDepartments(branchId As Integer?)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))

        If Not branchId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Departments_ByBranchID(branchId.Value).
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlDepartment.DataSource = data
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()
            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        End Using
    End Sub

    '=============== تعبئة المحطات التعريفية حسب القسم
    Private Sub FillJobTitles(deptId As Integer?)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))

        If Not deptId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_ByDepartmentID(deptId.Value).
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlJobTitle.DataSource = data
            ddlJobTitle.DataTextField = "Title_Ar"
            ddlJobTitle.DataValueField = "ID"
            ddlJobTitle.DataBind()
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
        End Using
    End Sub

    '=============== تعبئة Items الخاصة بالمحطة التعريفية
    Private Sub FillJobTitleItems(jobTitleId As Integer?)
        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))

        If Not jobTitleId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitle_Items_ByJobTitle_ID(jobTitleId.Value).
                            Where(Function(x) x.IsDeleted = 0 AndAlso x.IsActive = True).ToList()

            ddlJobTitleItem.DataSource = data
            ddlJobTitleItem.DataTextField = "Title_Ar"
            ddlJobTitleItem.DataValueField = "ID"
            ddlJobTitleItem.DataBind()
            ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))
        End Using
    End Sub

    '=============== تعبئة فترات العمل (Shift)
    Private Sub FillShifts()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Shift_All().
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlShift.DataSource = data
            ddlShift.DataTextField = "Title_Ar"
            ddlShift.DataValueField = "ID"
            ddlShift.DataBind()
            ddlShift.Items.Insert(0, New ListItem("اختر الوردية", ""))
        End Using
    End Sub

    '=============== حدث تغيير الفرع
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

        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))
    End Sub

    '=============== حدث تغيير القسم
    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer?
        If Integer.TryParse(ddlDepartment.SelectedValue, Nothing) Then
            deptId = CInt(ddlDepartment.SelectedValue)
        Else
            deptId = Nothing
        End If

        FillJobTitles(deptId)

        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))
    End Sub

    '=============== حدث تغيير المحطة التعريفية (لتعبئة الـ Items)
    Protected Sub ddlJobTitle_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim jobId As Integer?
        If Integer.TryParse(ddlJobTitle.SelectedValue, Nothing) Then
            jobId = CInt(ddlJobTitle.SelectedValue)
        Else
            jobId = Nothing
        End If

        FillJobTitleItems(jobId)
    End Sub

    '=============== زر حفظ
    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim titleAr = txtTitleAr.Text.Trim()
        Dim titleEn = txtTitleEn.Text.Trim()
        Dim briefAr = txtBriefAr.Text.Trim()
        Dim briefEn = txtBriefEn.Text.Trim()

        Dim weightVal As Double?
        If Not String.IsNullOrWhiteSpace(txtWeight.Text) Then
            Dim tmp As Double
            If Double.TryParse(txtWeight.Text, tmp) Then
                weightVal = tmp
            End If
        End If

        Dim User_TypeID As Integer? = If(String.IsNullOrEmpty(ddlUsersType.SelectedValue), CType(Nothing, Integer?), CInt(ddlUsersType.SelectedValue))
        Dim brandId As Integer? = If(String.IsNullOrEmpty(ddlBrands.SelectedValue), CType(Nothing, Integer?), CInt(ddlBrands.SelectedValue))
        Dim branchId As Integer? = If(String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?), CInt(ddlBranch.SelectedValue))
        Dim deptId As Integer? = If(String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?), CInt(ddlDepartment.SelectedValue))
        Dim jobTitleId As Integer? = If(String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?), CInt(ddlJobTitle.SelectedValue))

        ' ✅ JobTitle_Items_ID اختياري
        Dim jobTitleItemId As Integer? = If(String.IsNullOrEmpty(ddlJobTitleItem.SelectedValue), CType(Nothing, Integer?), CInt(ddlJobTitleItem.SelectedValue))

        Dim shiftId As Integer? = If(String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?), CInt(ddlShift.SelectedValue))
        Dim CheckList_CategoryID As Integer? = If(String.IsNullOrEmpty(ddlChecklistCategories.SelectedValue), CType(Nothing, Integer?), CInt(ddlChecklistCategories.SelectedValue))

        Dim addedUser As Integer = SessionManager.GetInstance.Users.UserID

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Insert_Checklist_Employee(User_TypeID, titleAr,
                                titleEn,
                                briefAr,
                                briefEn,
                                brandId,
                                branchId,
                                deptId,
                                jobTitleId,
                                jobTitleItemId,
                                shiftId,
                                CheckList_CategoryID,
                                weightVal,
                                addedUser)
        End Using

        ' عرض Popup نجاح
        LBLPOP_ModalPopupExtender.Show()
    End Sub

    '=============== إغلاق Popup النجاح
    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Checklist_Employees/ManageChecklist_Employees.aspx")
    End Sub

    '=============== زر إلغاء
    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Checklist_Employees/ManageChecklist_Employees.aspx")
    End Sub

End Class
