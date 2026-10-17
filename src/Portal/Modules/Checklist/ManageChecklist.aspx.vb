Imports Prosto_ERP_ClassLibrary

Public Class Managechecklist
    Inherits PageBase

    Private Const ProstoBrandId As Integer = 26  ' في حال احتجناه لاحقاً

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBranches()
            ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))
            ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))
            ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))
            FillShifts()
            FillData()
        End If
    End Sub

    '=============== تعبئة الفروع (Prosto فقط)
    Private Sub FillBranches()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim branches = db.Select_Branches_ByBrandID(ProstoBrandId).
                    Where(Function(x) x.IsDeleted = 0).ToList()

            ddlBranch.DataSource = branches
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()

            ddlBranch.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    '=============== تعبئة الأقسام حسب الفرع
    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))

        If String.IsNullOrEmpty(ddlBranch.SelectedValue) Then
            FillData()
            Exit Sub
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim branchId = CInt(ddlBranch.SelectedValue)
            Dim departments = db.Select_Departments_ByBranchID(branchId).
                    Where(Function(x) x.IsDeleted = 0).ToList()

            ddlDepartment.DataSource = departments
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()

            ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))
        End Using

        FillData()
    End Sub

    '=============== تعبئة المحطة التعريفية حسب القسم
    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))

        If String.IsNullOrEmpty(ddlDepartment.SelectedValue) Then
            FillData()
            Exit Sub
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim deptId = CInt(ddlDepartment.SelectedValue)
            Dim jobs = db.Select_JobTitles_ByDepartmentID(deptId).
                    Where(Function(x) x.IsDeleted = 0).ToList()

            ddlJobTitle.DataSource = jobs
            ddlJobTitle.DataTextField = "Title_Ar"
            ddlJobTitle.DataValueField = "ID"
            ddlJobTitle.DataBind()

            ddlJobTitle.Items.Insert(0, New ListItem("الكل", ""))
        End Using

        FillData()
    End Sub

    '=============== تعبئة Items الخاصة بالمحطة التعريفية
    Private Sub FillJobTitleItems(jobTitleId As Integer?)
        ddlJobTitleItem.Items.Clear()
        ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))

        If Not jobTitleId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim items = db.Select_JobTitle_Items_ByJobTitle_ID(jobTitleId.Value).
                    Where(Function(x) x.IsDeleted = 0 AndAlso x.IsActive = True).ToList()

            ddlJobTitleItem.DataSource = items
            ddlJobTitleItem.DataTextField = "Title_Ar"
            ddlJobTitleItem.DataValueField = "ID"
            ddlJobTitleItem.DataBind()

            ddlJobTitleItem.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    '=============== حدث اختيار المحطة التعريفية
    Protected Sub ddlJobTitle_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim jobId As Integer?

        If Integer.TryParse(ddlJobTitle.SelectedValue, Nothing) Then
            jobId = CInt(ddlJobTitle.SelectedValue)
        Else
            jobId = Nothing
        End If

        FillJobTitleItems(jobId)
        FillData()
    End Sub

    '=============== حدث اختيار البند الوظيفي
    Protected Sub ddlJobTitleItem_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillData()
    End Sub

    '=============== تعبئة فترات العمل (Shift)
    Private Sub FillShifts()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim shifts = db.Select_Shift_All().
                    Where(Function(x) x.IsDeleted = 0).ToList()

            ddlShift.DataSource = shifts
            ddlShift.DataTextField = "Title_Ar"
            ddlShift.DataValueField = "ID"
            ddlShift.DataBind()

            ddlShift.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    '=============== تعبئة البيانات من الـ Stored Procedure
    Protected Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext

            Dim branchId As Integer? =
                    If _
                    (String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?),
                     CInt(ddlBranch.SelectedValue))
            Dim deptId As Integer? =
                    If _
                    (String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?),
                     CInt(ddlDepartment.SelectedValue))
            Dim jobId As Integer? =
                    If _
                    (String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?),
                     CInt(ddlJobTitle.SelectedValue))
            Dim shiftId As Integer? =
                    If _
                    (String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?),
                     CInt(ddlShift.SelectedValue))
            Dim jobTitleItemId As Integer? =
                    If _
                    (String.IsNullOrEmpty(ddlJobTitleItem.SelectedValue), CType(Nothing, Integer?),
                     CInt(ddlJobTitleItem.SelectedValue))
            Dim search As String = If(String.IsNullOrWhiteSpace(txtSearch.Text), Nothing, txtSearch.Text.Trim())

            ' استدعاء SP الجديدة Select_Checklist_ForManage مع JobTitleItemID
            Dim data = db.Select_Checklist_ForManage(
                branchId,
                deptId,
                jobId,
                shiftId,
                search,
                jobTitleItemId
                ).ToList()

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    '=============== زر البحث
    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        FillData()
    End Sub

    '=============== أوامر الجدول (تعديل / حذف)
    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Using db As New Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName
                    Case "Edit"
                        Dim ID = CInt(e.CommandArgument)
                        Response.Redirect("/Modules/Checklist/EditChecklist.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID = CInt(e.CommandArgument)
                        ' هنا استخدم SP الحذف الناعمة (تحديث IsDeleted = 1)
                        db.Delete_Checklist_ByID(ID, SessionManager.GetInstance.Users.UserID)
                        FillData()
                End Select
            Catch ex As Exception
                ' ممكن تخزين الـ Log هنا لو حابب
            End Try
        End Using
    End Sub

    '=============== زر إضافة جديد
    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Checklist/AddChecklist.aspx")
    End Sub
End Class


