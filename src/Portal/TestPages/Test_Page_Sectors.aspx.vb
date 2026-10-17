Imports System
Imports System.Collections.Generic
Imports System.Linq
Imports Prosto_ERP_ClassLibrary

Public Class Test_Page_Sectors
    Inherits PageBase

    ' كلاس بسيط لموظفي القسم داخل كرت الأقسام
    Private Class DeptEmployeeVM
        Public Property ID As Integer
        Public Property FullName_Ar As String
        Public Property UserImage As String
    End Class

    Private Class DepartmentCardVM
        Public Property DeptID As Integer
        Public Property DeptName As String
        Public Property EmployeesCount As Integer
        Public Property Employees As List(Of DeptEmployeeVM)
    End Class

    Protected BranchID As Integer = 0
    Protected BranchName As String = ""
    Protected ManagerName As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' التحقق من تسجيل الدخول
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        Dim currentUser = SessionManager.GetInstance.Users
        Dim currentUserId As Integer = currentUser.UserID

        Using db As New Prosto_ERP_DataClassesDataContext
            ' نجلب بيانات المدير من UsersMembers (مش من UserEntity)
            Dim userRow = db.Select_UsersMembers_ByID(currentUserId).FirstOrDefault()
            If userRow IsNot Nothing Then
                ManagerName = userRow.FullName_Ar
                BranchID = If(userRow.Branch_ID, 0)
            End If

            Dim branch = db.Select_Branches_ByID(BranchID).FirstOrDefault()
            If branch IsNot Nothing Then
                BranchName = branch.Title_Ar
            End If
        End Using

        If Not Page.IsPostBack Then
            'lblManagerName.Text = ManagerName
            lblBranchNameCard1.Text = BranchName
            lblBranchNameCard2.Text = BranchName
            lblBranchNameCard3.Text = BranchName
            lblBranchNameHeader.Text = BranchName
            lblTodayDate.Text = DateTime.Now.ToString("dd/MM/yyyy")

            LoadStats()
            BindUnassignedEmployees()
            BindDepartmentsCards()
        End If
    End Sub

    ' =================== تحميل الإحصائيات ===================

    Private Sub LoadStats()
        Using db As New Prosto_ERP_DataClassesDataContext
            ' الموظفون في هذا الفرع (UserType = 3)
            Dim employeesInBranch = db.Select_UsersMembers_All().
                Where(Function(u) _
                    (u.IsDeleted = False Or u.IsDeleted Is Nothing) AndAlso
                    u.Branch_ID = BranchID AndAlso
                    u.Type = 3).
                ToList()

            Dim totalCount As Integer = employeesInBranch.Count

            ' هنا كنا نستخدم employeesInBranch.Count(Function(...))
            ' عدّلناها إلى Where(...).Count() حتى نتجنب تعارض الخاصية Count
            Dim activeCount As Integer = employeesInBranch.
                Where(Function(u) u.Status = 1).Count()

            Dim onLeaveCount As Integer = employeesInBranch.
                Where(Function(u) u.Status = 2).Count()

            lblTotalEmployees.Text = totalCount.ToString()
            lblTotalEmployeesSmall.Text = totalCount.ToString()

            lblActiveEmployees.Text = activeCount.ToString()
            lblActiveEmployeesSmall.Text = activeCount.ToString()

            lblOnLeaveEmployees.Text = onLeaveCount.ToString()
            lblOnLeaveEmployeesSmall.Text = onLeaveCount.ToString()
        End Using
    End Sub

    ' =================== الموظفون بدون قسم/مسمى ===================

    Private Sub BindUnassignedEmployees()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim employees = db.Select_UsersMembers_All().
                Where(Function(u) _
                    (u.IsDeleted = False Or u.IsDeleted Is Nothing) AndAlso
                    u.Branch_ID = BranchID AndAlso
                    u.Type = 3 AndAlso
                    u.Status = 1 AndAlso
                    (u.Department_ID Is Nothing OrElse u.Department_ID = 0) AndAlso
                    (u.JobTitle_ID Is Nothing OrElse u.JobTitle_ID = 0)).
                OrderBy(Function(u) u.FullName_Ar).
                ToList()

            If employees.Any() Then
                pnlNoUnassignedEmployees.Visible = False
                rptUnassignedEmployees.DataSource = employees
                rptUnassignedEmployees.DataBind()
            Else
                rptUnassignedEmployees.DataSource = Nothing
                rptUnassignedEmployees.DataBind()
                pnlNoUnassignedEmployees.Visible = True
            End If
        End Using
    End Sub

    Protected Sub rptUnassignedEmployees_ItemCommand(sender As Object, e As RepeaterCommandEventArgs)
        If e.CommandName = "EditEmployee" Then
            Dim employeeId As Integer = Convert.ToInt32(e.CommandArgument)
            OpenEmployeePopup(employeeId)
        End If
    End Sub

    ' =================== فتح الـ Popup لموظف معين ===================

    Private Sub OpenEmployeePopup(employeeId As Integer)
        lblPopupError.Text = ""
        hdPopupEmployeeID.Value = employeeId.ToString()

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim emp = db.Select_UsersMembers_ByID(employeeId).FirstOrDefault()
            If emp Is Nothing Then
                lblPopupError.Text = "تعذر تحميل بيانات الموظف."
                LBLPOP_ModalPopupExtender.Show()
                Return
            End If

            txtPopupEmployeeName.Text = emp.FullName_Ar

            Dim branch = db.Select_Branches_ByID(emp.Branch_ID).FirstOrDefault()
            txtPopupBranchName.Text = If(branch IsNot Nothing, branch.Title_Ar, "")

            ' تعبئة الأقسام
            FillDepartmentsDropDown(emp.Branch_ID, emp.Department_ID)

            ' تعبئة الشفتات
            FillShiftsDropDown(emp.Shif_ID)

            ' تعبئة المسميات الوظيفية على حسب القسم الحالي (إن وجد)
            Dim deptId As Integer = If(emp.Department_ID, 0)
            FillJobTitlesDropDown(deptId, emp.JobTitle_ID)
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Private Sub FillDepartmentsDropDown(branchId As Integer, selectedDeptId As Integer?)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim depts = db.Select_Departments_All().
                Where(Function(d) _
                    (d.IsDeleted = False Or d.IsDeleted Is Nothing) AndAlso
                    (d.IsActive = True OrElse d.IsActive Is Nothing) AndAlso
                    d.BranchID = branchId).
                OrderBy(Function(d) d.Title_Ar).
                ToList()

            ddlPopupDepartment.Items.Clear()
            ddlPopupDepartment.Items.Add(New ListItem("الرجاء الاختيار", "0"))

            For Each d In depts
                ddlPopupDepartment.Items.Add(New ListItem(d.Title_Ar, d.ID))
            Next

            If selectedDeptId.HasValue AndAlso selectedDeptId.Value > 0 Then
                Dim item = ddlPopupDepartment.Items.FindByValue(selectedDeptId.Value.ToString())
                If item IsNot Nothing Then
                    ddlPopupDepartment.ClearSelection()
                    item.Selected = True
                End If
            End If
        End Using
    End Sub

    Private Sub FillJobTitlesDropDown(deptId As Integer, selectedJobTitleId As Integer?)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim jobs = db.Select_JobTitles_All().
                Where(Function(j) _
                    (j.IsDeleted = False Or j.IsDeleted Is Nothing) AndAlso
                    (j.IsActive = True OrElse j.IsActive Is Nothing) AndAlso
                    j.DepartmentID = deptId).
                OrderBy(Function(j) j.Title_Ar).
                ToList()

            ddlPopupJobTitle.Items.Clear()
            ddlPopupJobTitle.Items.Add(New ListItem("الرجاء الاختيار", "0"))

            For Each jt In jobs
                ddlPopupJobTitle.Items.Add(New ListItem(jt.Title_Ar, jt.ID))
            Next

            If selectedJobTitleId.HasValue AndAlso selectedJobTitleId.Value > 0 Then
                Dim item = ddlPopupJobTitle.Items.FindByValue(selectedJobTitleId.Value.ToString())
                If item IsNot Nothing Then
                    ddlPopupJobTitle.ClearSelection()
                    item.Selected = True
                End If
            End If
        End Using
    End Sub

    Private Sub FillShiftsDropDown(selectedShiftId As Integer?)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim shifts = db.Select_Shift_All().
                Where(Function(s) (s.IsDeleted = False Or s.IsDeleted Is Nothing) AndAlso (s.IsActive = True OrElse s.IsActive Is Nothing)).
                OrderBy(Function(s) s.Title_Ar).
                ToList()

            ddlPopupShift.Items.Clear()
            ddlPopupShift.Items.Add(New ListItem("الرجاء الاختيار", "0"))

            For Each s In shifts
                ddlPopupShift.Items.Add(New ListItem(s.Title_Ar, s.ID))
            Next

            If selectedShiftId.HasValue AndAlso selectedShiftId.Value > 0 Then
                Dim item = ddlPopupShift.Items.FindByValue(selectedShiftId.Value.ToString())
                If item IsNot Nothing Then
                    ddlPopupShift.ClearSelection()
                    item.Selected = True
                End If
            End If
        End Using
    End Sub

    Protected Sub ddlPopupDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer = Convert.ToInt32(ddlPopupDepartment.SelectedValue)
        FillJobTitlesDropDown(deptId, Nothing)
        LBLPOP_ModalPopupExtender.Show()
    End Sub

    ' =================== حفظ تعيين الموظف ===================

    Protected Sub btnSaveEmployeeSector_Click(sender As Object, e As EventArgs)
        lblPopupError.Text = ""
        pnlPageMessage.Visible = False
        lblPageMessage.Text = ""

        Dim empId As Integer = If(String.IsNullOrEmpty(hdPopupEmployeeID.Value), 0, Convert.ToInt32(hdPopupEmployeeID.Value))
        If empId = 0 Then
            lblPopupError.Text = "حدث خطأ في تحديد الموظف."
            LBLPOP_ModalPopupExtender.Show()
            Return
        End If

        If ddlPopupDepartment.SelectedValue = "0" Then
            lblPopupError.Text = "يرجى اختيار القسم."
            LBLPOP_ModalPopupExtender.Show()
            Return
        End If

        If ddlPopupJobTitle.SelectedValue = "0" Then
            lblPopupError.Text = "يرجى اختيار المسمى الوظيفي."
            LBLPOP_ModalPopupExtender.Show()
            Return
        End If

        If ddlPopupShift.SelectedValue = "0" Then
            lblPopupError.Text = "يرجى اختيار فترة العمل."
            LBLPOP_ModalPopupExtender.Show()
            Return
        End If

        Dim deptIdSelected As Integer = Convert.ToInt32(ddlPopupDepartment.SelectedValue)
        Dim jobTitleIdSelected As Integer = Convert.ToInt32(ddlPopupJobTitle.SelectedValue)
        Dim shiftIdSelected As Integer = Convert.ToInt32(ddlPopupShift.SelectedValue)

        Try
            Using db As New Prosto_ERP_DataClassesDataContext
                Dim emp = db.Select_UsersMembers_ByID(empId).FirstOrDefault()
                If emp Is Nothing Then
                    lblPopupError.Text = "تعذر العثور على الموظف في النظام."
                    LBLPOP_ModalPopupExtender.Show()
                    Return
                End If

                Dim modifyUserId As Integer = SessionManager.GetInstance.Users.UserID

                'db.Update_UsersMembers_ByID(
                '    emp.ID,
                '    emp.FullName_Ar,
                '    emp.Fullname_En,
                '    emp.UserName,
                '    emp.Password,
                '    emp.UserImage,
                '    emp.PhoneNumber,
                '    emp.MobileNumber,
                '    emp.Email,
                '    emp.Employee_Number,
                '    emp.Brand_ID,
                '    emp.Branch_ID,
                '    deptIdSelected,
                '    jobTitleIdSelected,
                '    shiftIdSelected,
                '    emp.Employee_Status,
                '    modifyUserId,
                '    DateTime.Now
                ')
            End Using

            ' تحديث البيانات على الشاشة
            BindUnassignedEmployees()
            BindDepartmentsCards()
            LoadStats()

            pnlPageMessage.Visible = True
            pnlPageMessage.CssClass = "alert alert-success mb-0 py-2 px-3"
            lblPageMessage.Text = "تم تحديث بيانات الموظف بنجاح."

            LBLPOP_ModalPopupExtender.Hide()

        Catch ex As Exception
            lblPopupError.Text = "حدث خطأ أثناء الحفظ، يرجى المحاولة مرة أخرى."
            LBLPOP_ModalPopupExtender.Show()
        End Try
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Hide()
    End Sub

    ' =================== كروت الأقسام ===================

    Private Sub BindDepartmentsCards()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim depts = db.Select_Departments_All().
                Where(Function(d) _
                    (d.IsDeleted = False Or d.IsDeleted Is Nothing) AndAlso
                    (d.IsActive = True OrElse d.IsActive Is Nothing) AndAlso
                    d.BranchID = BranchID).
                ToList()

            Dim employees = db.Select_UsersMembers_All().
                Where(Function(u) _
                    (u.IsDeleted = False Or u.IsDeleted Is Nothing) AndAlso
                    u.Branch_ID = BranchID AndAlso
                    u.Type = 3 AndAlso
                    (u.Department_ID IsNot Nothing AndAlso u.Department_ID <> 0)).
                ToList()

            Dim cards As New List(Of DepartmentCardVM)

            For Each d In depts
                Dim deptEmployees = employees.
                    Where(Function(u) u.Department_ID = d.ID).
                    OrderBy(Function(u) u.FullName_Ar).
                    ToList()

                Dim vm As New DepartmentCardVM With {
                    .DeptID = d.ID,
                    .DeptName = d.Title_Ar,
                    .EmployeesCount = deptEmployees.Count,
                    .Employees = deptEmployees.
                        Take(5).
                        Select(Function(u) New DeptEmployeeVM With {
                                   .ID = u.ID,
                                   .FullName_Ar = u.FullName_Ar,
                                   .UserImage = If(String.IsNullOrEmpty(u.User_Image), "../../assets/img/avatars/2.png", u.User_Image)
                               }).ToList()
                }

                cards.Add(vm)
            Next

            If cards.Any() Then
                pnlNoDepartments.Visible = False
                rptDepartments.DataSource = cards
                rptDepartments.DataBind()
            Else
                rptDepartments.DataSource = Nothing
                rptDepartments.DataBind()
                pnlNoDepartments.Visible = True
            End If
        End Using
    End Sub

    Protected Sub rptDepartments_ItemDataBound(sender As Object, e As RepeaterItemEventArgs)
        If e.Item.ItemType = ListItemType.Item OrElse e.Item.ItemType = ListItemType.AlternatingItem Then
            Dim card As DepartmentCardVM = CType(e.Item.DataItem, DepartmentCardVM)
            Dim rpt As Repeater = CType(e.Item.FindControl("rptDeptEmployees"), Repeater)
            If rpt IsNot Nothing Then
                rpt.DataSource = card.Employees
                rpt.DataBind()
            End If
        End If
    End Sub

End Class
