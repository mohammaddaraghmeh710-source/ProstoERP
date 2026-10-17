Imports Prosto_ERP_ClassLibrary

Public Class EditChecklist_Employees
    Inherits PageBase

    Private Const FixedJobTitleItemId As Integer = 0 ' لم نعد نعتمد عليه، الـ Item اختياري من الـ DropDown

    Private ReadOnly Property ChecklistId As Integer
        Get
            Return CInt(Request.QueryString("ID"))
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
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

            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
            ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))

            FillData()
        End If
    End Sub

    '=============== تعبئة بيانات البند للتعديل
    Private Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim c = db.Select_Checklist_Employee_ByID(ChecklistId).FirstOrDefault()
            If c Is Nothing Then Exit Sub

            ' بيانات البند
            txtTitleAr.Text = c.Title_Ar
            txtTitleEn.Text = c.Title_En
            txtBriefAr.Text = c.Brief_Ar
            txtBriefEn.Text = c.Brief_En
            txtWeight.Text = If(c.Weight.HasValue, c.Weight.Value.ToString(), "")

            cbIsActive.Checked = If(c.IsActive.HasValue, c.IsActive.Value, False)

            Dim checklistCategoryId As Integer? = c.CheckList_CategoryID
            Dim User_TypeID As Integer? = c.Users_TypesID
            Dim brandId As Integer? = c.Brand_ID
            Dim branchId As Integer? = c.Branch_ID
            Dim deptId As Integer? = c.Department_ID
            Dim jobTitleId As Integer? = c.JobTitle_ID
            Dim jobTitleItemId As Integer? = c.JobTitle_Items_ID
            Dim shiftId As Integer? = c.Shift_ID

            ' التصنيف
            If checklistCategoryId.HasValue Then
                Dim catItem = ddlChecklistCategories.Items.FindByValue(checklistCategoryId.Value.ToString())
                If catItem IsNot Nothing Then
                    ddlChecklistCategories.ClearSelection()
                    catItem.Selected = True
                End If
            End If

            ' User Type
            If User_TypeID.HasValue Then
                Dim UserType = ddlUsersType.Items.FindByValue(User_TypeID.Value.ToString())
                If UserType IsNot Nothing Then
                    ddlUsersType.ClearSelection()
                    UserType.Selected = True
                End If
            End If


            ' Brand
            If brandId.HasValue Then
                '  تعبئة العلامات التجارية للتأكد من وجود الخيار
                FillBrands()
                Dim brandItem = ddlBrands.Items.FindByValue(brandId.Value.ToString())
                If brandItem IsNot Nothing Then
                    ddlBrands.ClearSelection()
                    brandItem.Selected = True
                End If

                FillBranches(brandId)
            End If


            ' Branch
            If branchId.HasValue Then
                ' إعادة تعبئة الفروع للتأكد من وجود الخيار
                Dim brItem = ddlBranch.Items.FindByValue(branchId.Value.ToString())
                If brItem IsNot Nothing Then
                    ddlBranch.ClearSelection()
                    brItem.Selected = True
                End If

                FillDepartments(branchId)
            End If

            ' Department
            If deptId.HasValue Then
                Dim dItem = ddlDepartment.Items.FindByValue(deptId.Value.ToString())
                If dItem IsNot Nothing Then
                    ddlDepartment.ClearSelection()
                    dItem.Selected = True
                End If

                FillJobTitles(deptId)
            End If

            ' JobTitle
            If jobTitleId.HasValue Then
                Dim jItem = ddlJobTitle.Items.FindByValue(jobTitleId.Value.ToString())
                If jItem IsNot Nothing Then
                    ddlJobTitle.ClearSelection()
                    jItem.Selected = True
                End If

                ' تعبئة البنود الخاصة بالمحطة التعريفية
                FillJobTitleItems(jobTitleId)
            End If

            ' JobTitle_Item (اختياري)
            If jobTitleItemId.HasValue Then
                Dim jtItem = ddlJobTitleItem.Items.FindByValue(jobTitleItemId.Value.ToString())
                If jtItem IsNot Nothing Then
                    ddlJobTitleItem.ClearSelection()
                    jtItem.Selected = True
                End If
            End If

            ' Shift
            If shiftId.HasValue Then
                Dim shItem = ddlShift.Items.FindByValue(shiftId.Value.ToString())
                If shItem IsNot Nothing Then
                    ddlShift.ClearSelection()
                    shItem.Selected = True
                End If
            End If
        End Using
    End Sub

    Private Sub FillUsersTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_DataClassesDataContext
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

            Using db As New Prosto_ERP_DataClassesDataContext
                Dim BrandID = CInt(ddlBrands.SelectedValue)
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


    '=============== تعبئة تصنيفات الـ Checklist
    Private Sub fillChecklist_Categories()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Checklist_Categories_SelectAll().
                    Where(Function(x) x.IsDeleted = 0).ToList()
            ddlChecklistCategories.DataSource = data
            ddlChecklistCategories.DataTextField = "Title_Ar"
            ddlChecklistCategories.DataValueField = "ID"
            ddlChecklistCategories.DataBind()
            ddlChecklistCategories.Items.Insert(0, New ListItem("اختر التصنيف", ""))
        End Using
    End Sub


    Private Sub FillBranches(brandId As Integer?)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(brandId).
                    Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        End Using
    End Sub

    '=============== تعبئة الأقسام حسب الفرع
    Private Sub FillDepartments(branchId As Integer?)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))

        If Not branchId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_DataClassesDataContext
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

        Dim User_TypeID As Integer? =
                If _
                (String.IsNullOrEmpty(ddlUsersType.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlUsersType.SelectedValue))
        Dim brandId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlBrands.SelectedValue), CType(Nothing, Integer?), CInt(ddlBrands.SelectedValue))
        Dim branchId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?), CInt(ddlBranch.SelectedValue))
        Dim deptId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlDepartment.SelectedValue))
        Dim jobTitleId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlJobTitle.SelectedValue))

        ' ✅ JobTitle_Items_ID اختياري
        Dim jobTitleItemId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlJobTitleItem.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlJobTitleItem.SelectedValue))

        Dim shiftId As Integer? =
                If(String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?), CInt(ddlShift.SelectedValue))
        Dim checklistCategoryId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlChecklistCategories.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlChecklistCategories.SelectedValue))

        Dim isActive As Boolean = cbIsActive.Checked
        Dim modifyUser As Integer = SessionManager.GetInstance.Users.UserID

        Using db As New Prosto_ERP_DataClassesDataContext
            db.Update_Checklist_Employee_ByID(ChecklistId, User_TypeID,
                                              titleAr,
                                              titleEn,
                                              briefAr,
                                              briefEn,
                                              brandId,
                                              branchId,
                                              deptId,
                                              jobTitleId,
                                              jobTitleItemId,
                                              shiftId,
                                              checklistCategoryId,
                                              weightVal,
                                              isActive,
                                              modifyUser)
        End Using

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


