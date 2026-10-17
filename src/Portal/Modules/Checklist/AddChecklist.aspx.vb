Imports System.Linq

Public Class AddChecklist
    Inherits PageBase

    Private Const FixedBrandId As Integer = 29
    Private Const FixedJobTitleItemId As Integer = 0 ' لم يعد مستخدماً، نعتمد على ddlJobTitleItem (اختياري)

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            FillTypes()
            FillBranches()
            fillChecklist_Categories()
            FillShifts()

            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
            ddlJobTitleItem.Items.Insert(0, New ListItem("اختر البند (اختياري)", ""))
        End If
    End Sub

    '=============== تعبئة الانواع 
    Private Sub FillTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Checklist_Types_All().
                            Where(Function(x) x.IsDeleted = 0).ToList()
            ddlType.DataSource = data
            ddlType.DataTextField = "Title_Ar"
            ddlType.DataValueField = "ID"
            ddlType.DataBind()
            ddlType.Items.Insert(0, New ListItem("اختر النوع", ""))
        End Using
    End Sub

    '=============== تعبئة الفروع (Brand = 26)
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
            Dim data = db.Checklist_Categories_SelectAll().
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
        Dim Type As Integer = ddlType.SelectedValue()
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

        Dim brandId As Integer? = FixedBrandId
        Dim branchId As Integer? = If(String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?), CInt(ddlBranch.SelectedValue))
        Dim deptId As Integer? = If(String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?), CInt(ddlDepartment.SelectedValue))
        Dim jobTitleId As Integer? = If(String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?), CInt(ddlJobTitle.SelectedValue))

        ' ✅ JobTitle_Items_ID اختياري
        Dim jobTitleItemId As Integer? = If(String.IsNullOrEmpty(ddlJobTitleItem.SelectedValue), CType(Nothing, Integer?), CInt(ddlJobTitleItem.SelectedValue))

        Dim shiftId As Integer? = If(String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?), CInt(ddlShift.SelectedValue))
        Dim CheckList_CategoryID As Integer? = If(String.IsNullOrEmpty(ddlChecklistCategories.SelectedValue), CType(Nothing, Integer?), CInt(ddlChecklistCategories.SelectedValue))

        Dim addedUser As Integer = SessionManager.GetInstance.Users.UserID

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Insert_Checklist(Type, titleAr,
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
        Response.Redirect("/Modules/Checklist/ManageChecklist.aspx")
    End Sub

    '=============== زر إلغاء
    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Checklist/ManageChecklist.aspx")
    End Sub

End Class
