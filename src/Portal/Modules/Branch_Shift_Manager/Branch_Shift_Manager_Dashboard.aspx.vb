Imports System.Globalization
Imports Prosto_ERP_ClassLibrary

Public Class Branch_Shift_Manager_Dashboard
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_DataClassesDataContext()

    Protected BranchID As Integer
    Protected ShiftID As Integer?
    Protected BrandID As Integer

    ' ===== DTOs =====
    Private Class ViolationDto
        Public Property Title As String
        Public Property CssClass As String
    End Class

    Private Class EvaluationTaskDto
        Public Property EvaluationID As Integer
        Public Property JobTitleName As String
        Public Property ShiftName As String
        Public Property BrandLogoUrl As String
        Public Property EvalDate As DateTime?
        Public Property Notes As String
        Public Property Violations As List(Of ViolationDto)
    End Class

    Private Class DepartmentEvalDto
        Public Property DepartmentID As Integer
        Public Property DepartmentName As String
        Public Property Score As Decimal
        Public Property EmployeesCount As Integer
        Public Property BgClass As String
    End Class


    Private Class BranchUserDto
        Public Property ID As Integer
        Public Property FullName_Ar As String
        Public Property Employee_Number As String
        Public Property User_Image As String
        Public Property Gender As Integer?
        Public Property Department_ID As Integer?
        Public Property JobTitle_ID As Integer?
        Public Property Shift_ID As Integer?
        Public Property Status As Integer?
        Public Property IsActive As Boolean?
    End Class


    Private Class EmployeeListItemDto
        Public Property ID As Integer
        Public Property FullName As String
        Public Property JobTitleName As String
    End Class

    Private Class EmployeesByDeptDto
        Public Property DepartmentID As Integer
        Public Property DepartmentName As String
        Public Property Employees As List(Of EmployeeListItemDto)
    End Class

    Private Property EmployeesFilterType As String
        Get
            Return If(TryCast(ViewState("EmployeesFilterType"), String), String.Empty)
        End Get
        Set
            ViewState("EmployeesFilterType") = value
        End Set
    End Property


    ' الكاش
    Private _branchEvaluations As List(Of Select_Evaluations_ByBranchIDResult)
    Private _branchUsers As List(Of BranchUserDto)

    ' ========== Page_Load ==========
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()
        LoadMasterData()
        LoadBranchEvaluations()

        If Not IsPostBack Then
            BindChecklistTypes()
            BindBranchGaugeAndSummary()
            BindDepartments()
            BindViolations()
            BindComplaints()
            BindEmployeesHeaderStats()
        End If
    End Sub

    Private Sub BindChecklistTypes()
        Dim types = db.Select_Checklist_Types_All().ToList()

        ' اختياري: عرض فقط المفعّل
        types = types.Where(Function(t) (t.IsActive = True OrElse t.IsActive Is Nothing)).ToList()

        If types Is Nothing OrElse types.Count = 0 Then
            pnlNoChecklistTypes.Visible = True
            rptChecklistTypes.DataSource = Nothing
            rptChecklistTypes.DataBind()
            Return
        End If

        pnlNoChecklistTypes.Visible = False
        rptChecklistTypes.DataSource = types
        rptChecklistTypes.DataBind()
    End Sub


    Private Sub LoadParameters()
        Integer.TryParse(Request.QueryString("BranchID"), BranchID)

        Dim shiftStr As String = Request.QueryString("ShiftID")
        Dim tmpShift As Integer
        If Integer.TryParse(shiftStr, tmpShift) Then
            ShiftID = tmpShift
        Else
            ShiftID = Nothing
        End If
    End Sub

    ' ========== LoadMasterData ==========
    Private Sub LoadMasterData()
        ' الفرع
        Dim br = db.Select_Branches_ByID(BranchID).FirstOrDefault()
        If br Is Nothing Then Return

        lblBranchName.Text = br.Title_Ar

        BrandID = If(br.BrandID.HasValue, br.BrandID.Value, 0)

        Dim brandRow = If(br.BrandID.HasValue,
                          db.Select_Brands_ByID(br.BrandID.Value).FirstOrDefault(),
                          Nothing)

        Dim brandName As String = If(brandRow IsNot Nothing, brandRow.Title_Ar, "")
        Dim branchName As String = br.Title_Ar

        If brandName <> "" Then
            litBrandBranch.Text = brandName & " – " & branchName
        Else
            litBrandBranch.Text = branchName
        End If

        ' المستخدمين في الفرع (للاستخدام في عدّ الموظفين لكل قسم)
        _branchUsers =
            (From u In db.Select_UsersMembers_ByBranchID(BranchID)
                Where (u.IsDeleted = False OrElse u.IsDeleted Is Nothing) _
                      AndAlso u.Type = 4
                Select New BranchUserDto With {
                    .ID = u.ID,
                    .FullName_Ar = u.FullName_Ar,
                    .Employee_Number = u.Employee_Number,
                    .User_Image = u.User_Image,
                    .Gender = u.Gender,
                    .Department_ID = u.Department_ID,
                    .JobTitle_ID = u.JobTitle_ID,
                    .Shift_ID = u.Shif_ID,
                    .Status = u.Status,
                    .IsActive = u.IsActive
                    }).ToList()

        ' اسم الوردية (إن وجد)
        If ShiftID.HasValue Then
            Dim sh = db.Select_Shift_ByID(ShiftID.Value).FirstOrDefault()
            If sh IsNot Nothing Then
                litShiftName.Text = "الوردية: " & sh.Title_Ar
            End If
        Else
            litShiftName.Text = "كل الورديات"
        End If

        ' ====== سياسات الفرع ======
        ' مهم: عدّل أسماء الحقول حسب جدول الفروع لديك (هنا افترضت Policies_Ar, Working_Method_Video_Ar, Evaluation_Method_Video_Ar على الفرع).
        If Not String.IsNullOrWhiteSpace(br.Policies_Ar) Then
            'Dim encoded As String = Server.HtmlEncode(br.Policies_Ar)
            'encoded = encoded.Replace(Environment.NewLine, "<br />")
            litBranchPolicies.Text = br.Policies_Ar
        Else
            litBranchPolicies.Text = "<p class='mb-0 text-muted'>لم يتم تعريف سياسات لهذا الفرع بعد.</p>"
        End If

        If Not String.IsNullOrWhiteSpace(br.Working_Method_Video_Ar) Then
            hidWorkingMethodUrl.Value = BuildSecureVideoUrl(br.Working_Method_Video_Ar)
        Else
            hidWorkingMethodUrl.Value = String.Empty
        End If

        If Not String.IsNullOrWhiteSpace(br.Evaluation_Method_Video_Ar) Then
            hidEvaluationMethodUrl.Value = BuildSecureVideoUrl(br.Evaluation_Method_Video_Ar)
        Else
            hidEvaluationMethodUrl.Value = String.Empty
        End If


        ' ===== بيانات المستخدم الحالي =====
        Try
            Dim currentUser = SessionManager.GetInstance.Users
            If currentUser IsNot Nothing Then
                litCurrentUserName.Text = currentUser.NameAr

                If Not String.IsNullOrEmpty(currentUser.UserImage) Then
                    imgCurrentUser.ImageUrl = currentUser.UserImage
                End If
            End If
        Catch
            ' في حال أي خطأ، نخلي القيم الافتراضية
        End Try

        ' نفس نص العلامة التجارية - الفرع المستخدم في الهيدر القديم
        litBrandBranchHeader.Text = litBrandBranch.Text

        ' تاريخ اليوم
        Dim ar As New CultureInfo("ar-JO")
        litTodayDate.Text = DateTime.Now.ToString("dddd dd/MM/yyyy", ar)
    End Sub

    Private Sub BindEmployeesList(filterType As String)
        EmployeesFilterType = filterType

        If _branchUsers Is Nothing Then
            rptEmployeesByDept.DataSource = Nothing
            rptEmployeesByDept.DataBind()
            Return
        End If

        ' فلترة حسب الوردية إن وجدت
        Dim users = _branchUsers.Where(
            Function(u) (u.IsActive = True OrElse u.IsActive Is Nothing) _
                        AndAlso
                        (Not ShiftID.HasValue OrElse (u.Shift_ID.HasValue AndAlso u.Shift_ID.Value = ShiftID.Value))
            ).ToList()

        ' Status mapping (افتراض):
        ' 2 = مجاز, 3 = غياب بدون عذر
        Select Case filterType
            Case "Total"
                litEmployeesFilterTitle.Text = "جميع الموظفين"
                ' users كما هي
            Case "Actual"
                litEmployeesFilterTitle.Text = "الموظفون الحاضرون فعلياً"
                users =
                    users.Where(
                        Function(u) Not (u.Status.HasValue AndAlso (u.Status.Value = 2 OrElse u.Status.Value = 3))).
                        ToList()
            Case "OnLeave"
                litEmployeesFilterTitle.Text = "الموظفون المجازون"
                users = users.Where(Function(u) u.Status.HasValue AndAlso u.Status.Value = 2).ToList()
            Case "Absent"
                litEmployeesFilterTitle.Text = "غياب بدون عذر"
                users = users.Where(Function(u) u.Status.HasValue AndAlso u.Status.Value = 3).ToList()
        End Select

        ' جلب الأقسام
        Dim depts = db.Select_Departments_ByBranchID(BranchID).ToList()
        Dim deptDict = depts.ToDictionary(Function(d) d.ID, Function(d) d.Title_Ar)

        ' جلب المحطات التعريفية
        Dim jobs = db.Select_JobTitles_All().ToList()
        Dim jobsDict = jobs.ToDictionary(Function(j) j.ID, Function(j) j.Title_Ar)

        ' تجميع حسب القسم
        Dim grouped = users.
                GroupBy(Function(u) If(u.Department_ID, 0)).
                Select(Function(g) New EmployeesByDeptDto With {
                          .DepartmentID = g.Key,
                          .DepartmentName =
                          If(g.Key = 0, "بدون قسم", If(deptDict.ContainsKey(g.Key), deptDict(g.Key), "قسم غير معرف")),
                          .Employees = g.Select(Function(u) New EmployeeListItemDto With {
                                                   .ID = u.ID,
                                                   .FullName = u.FullName_Ar,
                                                   .JobTitleName =
                                                   If _
                                                   (
                                                       u.JobTitle_ID.HasValue AndAlso
                                                       jobsDict.ContainsKey(u.JobTitle_ID.Value),
                                                       jobsDict(u.JobTitle_ID.Value),
                                                       "بدون محطة تعريفية")
                                                   }).OrderBy(Function(x) x.FullName).ToList()})

        rptEmployeesByDept.DataSource = grouped
        rptEmployeesByDept.DataBind()

        ' إظهار المودال
        Dim script As String =
                "setTimeout(function(){" &
                "var m = new bootstrap.Modal(document.getElementById('employeesModal')); m.show();" &
                "}, 200);"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "showEmployeesModal", script, True)
    End Sub

    Protected Sub lnkEmpTotal_Click(sender As Object, e As EventArgs) Handles lnkEmpTotal.Click
        BindEmployeesList("Total")
    End Sub

    Protected Sub lnkEmpActual_Click(sender As Object, e As EventArgs) Handles lnkEmpActual.Click
        BindEmployeesList("Actual")
    End Sub

    Protected Sub lnkEmpOnLeave_Click(sender As Object, e As EventArgs) Handles lnkEmpOnLeave.Click
        BindEmployeesList("OnLeave")
    End Sub

    Protected Sub lnkEmpAbsent_Click(sender As Object, e As EventArgs) Handles lnkEmpAbsent.Click
        BindEmployeesList("Absent")
    End Sub

    Protected Sub rptEmployeesInner_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim empId As Integer = Convert.ToInt32(e.CommandArgument)

        If e.CommandName = "ViewProfile" Then
            Response.Redirect("~/modules/Employees/MyProfile.aspx?EmployeeID=" & empId.ToString())
        ElseIf e.CommandName = "EditEmp" Then
            OpenEditEmployeeModal(empId)
        End If
    End Sub

    Private Sub OpenEditEmployeeModal(empId As Integer)
        hidEditEmployeeID.Value = empId.ToString()

        ' 1) جلب الموظف
        Dim emp = db.Select_UsersMembers_ByID(empId).FirstOrDefault()

        ' 2) جلب الأقسام للفرع (نفس الذي استخدمناه في BindDepartments)
        Dim depts = db.Select_Departments_ByBranchID(BranchID).ToList()
        ddlEditDepartment.DataSource = depts
        ddlEditDepartment.DataTextField = "Title_Ar"
        ddlEditDepartment.DataValueField = "ID"
        ddlEditDepartment.DataBind()

        ' 3) اختيار قسم الموظف إن وجد
        Dim selectedDeptId As Integer? = Nothing
        Dim selectedJobId As Integer? = Nothing

        If emp IsNot Nothing Then
            If emp.Department_ID.HasValue Then
                selectedDeptId = emp.Department_ID.Value
            End If
            If emp.JobTitle_ID.HasValue Then
                selectedJobId = emp.JobTitle_ID.Value
            End If
        End If

        If selectedDeptId.HasValue Then
            Dim deptVal = selectedDeptId.Value.ToString()
            If ddlEditDepartment.Items.FindByValue(deptVal) IsNot Nothing Then
                ddlEditDepartment.SelectedValue = deptVal
            End If
        End If

        ' 4) تحميل المحطات التعريفية للقسم المختار فقط
        BindJobTitlesForSelectedDept(selectedJobId)

        ' 5) إظهار المودال
        Dim script As String =
                "setTimeout(function(){" &
                "var m = new bootstrap.Modal(document.getElementById('editEmployeeModal')); m.show();" &
                "}, 200);"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "showEditEmployeeModal", script, True)
    End Sub


    Private Sub BindJobTitlesForSelectedDept(Optional selectedJobId As Integer? = Nothing)
        ddlEditJobTitle.Items.Clear()

        Dim deptId As Integer
        If Not Integer.TryParse(ddlEditDepartment.SelectedValue, deptId) Then
            Return
        End If

        ' *** هنا استخدمت Select_JobTitles_All كما هو موجود في كودك السابق ***
        ' لو عندك جدول ربط JobTitle_Items أو SP مخصص للأقسام،
        ' استبدل الكويري التالي بما يناسبه.

        Dim jobs = db.Select_JobTitles_All().
                Where(Function(j) j.DepartmentID.HasValue AndAlso j.DepartmentID.Value = deptId).
                OrderBy(Function(j) j.Title_Ar).
                ToList()

        ddlEditJobTitle.DataSource = jobs
        ddlEditJobTitle.DataTextField = "Title_Ar"
        ddlEditJobTitle.DataValueField = "ID"
        ddlEditJobTitle.DataBind()

        If selectedJobId.HasValue Then
            Dim v = selectedJobId.Value.ToString()
            If ddlEditJobTitle.Items.FindByValue(v) IsNot Nothing Then
                ddlEditJobTitle.SelectedValue = v
            End If
        End If
    End Sub


    Protected Sub ddlEditDepartment_SelectedIndexChanged(sender As Object, e As EventArgs) _
        Handles ddlEditDepartment.SelectedIndexChanged
        BindJobTitlesForSelectedDept()

        Dim script As String =
                "setTimeout(function(){" &
                "var m = new bootstrap.Modal(document.getElementById('editEmployeeModal')); m.show();" &
                "}, 200);"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reopenEditEmployeeModal", script, True)
    End Sub

    Protected Sub btnSaveEmployeeDeptJob_Click(sender As Object, e As EventArgs) Handles btnSaveEmployeeDeptJob.Click
        Dim empId As Integer
        If Not Integer.TryParse(hidEditEmployeeID.Value, empId) Then Return

        Dim deptId As Integer? = Nothing
        Dim jobId As Integer? = Nothing

        If Not String.IsNullOrEmpty(ddlEditDepartment.SelectedValue) Then
            deptId = Convert.ToInt32(ddlEditDepartment.SelectedValue)
        End If

        If Not String.IsNullOrEmpty(ddlEditJobTitle.SelectedValue) Then
            jobId = Convert.ToInt32(ddlEditJobTitle.SelectedValue)
        End If

        ' عدّل اسم الإجراء حسب الموجود عندك
        db.Update_UsersMembers_DepartmentandJobTitle_ByID(empId, deptId, jobId, SessionManager.GetInstance.Users.UserID)

        ' إعادة تحميل بيانات الفرع/الموظفين
        LoadMasterData()
        LoadBranchEvaluations()
        BindBranchGaugeAndSummary()
        BindDepartments()
        BindEmployeesHeaderStats()

        ' إعادة تحميل قائمة الموظفين على نفس الفلتر
        If Not String.IsNullOrEmpty(EmployeesFilterType) Then
            BindEmployeesList(EmployeesFilterType)
        End If
        Response.Redirect(Request.RawUrl)
        '    ' إغلاق مودال التعديل من جهة العميل (اختياري)
        '    Dim script As String =
        '        "var modalEl = document.getElementById('editEmployeeModal');" &
        '        "var m = bootstrap.Modal.getInstance(modalEl);" &
        '        "if(m){ m.hide(); }"
        '    ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideEditEmployeeModal", script, True)

        '    Dim script2 As String =
        '"var modalEl = document.getElementById('editEmployeeModal');" &
        '"var m = bootstrap.Modal.getInstance(modalEl);" &
        '"if(m){ m.hide(); }" &
        '"cleanupModalBackdrops();"

        '    ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideEditEmployeeModal", script2, True)
    End Sub

    Private Sub BindEmployeesHeaderStats()
        If _branchUsers Is Nothing Then
            litEmpTotal.Text = "0"
            litEmpActual.Text = "0"
            litEmpOnLeave.Text = "0"
            litEmpAbsent.Text = "0"
            Return
        End If

        ' فلترة على الموظفين الفعالين + وردية الصفحة إن أردت
        Dim users = _branchUsers.Where(
            Function(u) (u.IsActive = True OrElse u.IsActive Is Nothing) _
                        AndAlso
                        (Not ShiftID.HasValue OrElse (u.Shift_ID.HasValue AndAlso u.Shift_ID.Value = ShiftID.Value))
            ).ToList()

        Dim total As Integer = users.Count

        ' ملاحظة: هنا افترضت أن:
        ' Status = 2 => مجاز
        ' Status = 3 => غياب بدون عذر
        ' والباقي = موجود فعلياً
        Dim onLeave As Integer = users.Where(Function(u) u.Status.HasValue AndAlso u.Status.Value = 2).Count()
        Dim absent As Integer = users.Where(Function(u) u.Status.HasValue AndAlso u.Status.Value = 3).Count()
        Dim actual As Integer = total - onLeave - absent

        If actual < 0 Then actual = 0

        litEmpTotal.Text = total.ToString()
        litEmpOnLeave.Text = onLeave.ToString()
        litEmpAbsent.Text = absent.ToString()
        litEmpActual.Text = actual.ToString()
    End Sub


    ' ========== LoadBranchEvaluations ==========
    Private Sub LoadBranchEvaluations()
        ' مهم: هنا أفترض وجود Stored Procedure باسم Select_Evaluations_ByBranchID
        ' بالتوقيع: (BranchID, ShiftID As Nullable(Of Integer))
        ' إذا الاسم مختلف عدّله حسب اسم الإجراء عندك.
        If ShiftID.HasValue Then
            _branchEvaluations = db.Select_Evaluations_ByBranchID(BranchID, ShiftID.Value).ToList()
        Else
            _branchEvaluations = db.Select_Evaluations_ByBranchID(BranchID, Nothing).ToList()
        End If

        ' آخر تقييم
        If _branchEvaluations IsNot Nothing AndAlso _branchEvaluations.Count > 0 Then
            Dim lastEval = _branchEvaluations.OrderByDescending(Function(e) e.AddedDate).FirstOrDefault()
            If lastEval IsNot Nothing AndAlso lastEval.AddedDate.HasValue Then
                litLastEvalDate.Text = lastEval.AddedDate.Value.ToString("dd/MM/yyyy HH:mm")
            End If
        Else
            litLastEvalDate.Text = "-"
        End If
    End Sub

    ' ======== حساب السكور ========
    Private Function CalculateScore(evals As IEnumerable(Of Select_Evaluations_ByBranchIDResult)) _
        As Decimal
        If evals Is Nothing Then
            Return 100D
        End If

        Dim evaluationCount As Integer = evals.Count()
        If evaluationCount = 0 Then
            Return 100D
        End If

        Dim totalWeight As Decimal =
                evals.Sum(Function(ev) If(ev IsNot Nothing AndAlso ev.Weight.HasValue, CDec(ev.Weight.Value), 0D))

        Dim maxScore As Decimal = evaluationCount*100D
        Dim score As Decimal = ((maxScore - totalWeight)/maxScore)*100D

        If score < 0D Then score = 0D
        If score > 100D Then score = 100D

        Return score
    End Function

    Private Function GetGaugeCss(score As Decimal) As String
        If score >= 90D Then
            Return "branch-gauge gauge-green"
        ElseIf score >= 60D Then
            Return "branch-gauge gauge-yellow"
        Else
            Return "branch-gauge gauge-red"
        End If
    End Function

    ' ========== Gauge + Summary ==========
    Private Sub BindBranchGaugeAndSummary()
        Dim evalsAll = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 OrElse ev.Evaluation_Type = 2
            ).ToList()

        Dim score As Decimal = CalculateScore(evalsAll)
        litBranchScore.Text = score.ToString("0.0", CultureInfo.InvariantCulture) & "%"
        divBranchGauge.Attributes("data-value") = score.ToString("0.##", CultureInfo.InvariantCulture)
        divBranchGauge.Attributes("class") = GetGaugeCss(score)

        Dim violations = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).ToList()

        Dim complaints = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).ToList()

        litViolationsCount.Text = violations.Count.ToString()
        litComplaintsCount.Text = complaints.Count.ToString()
        litViolationsHeaderCount.Text = violations.Count.ToString()
        litComplaintsHeaderCount.Text = complaints.Count.ToString()
        litTotalEvals.Text = _branchEvaluations.Count.ToString()

        pnlNoViolations.Visible = (violations.Count = 0)
        pnlNoComplaints.Visible = (complaints.Count = 0)
    End Sub

    ' ========== Branch Departments Evaluation ==========
    Private Sub BindDepartments()
        ' جلب الأقسام التابعة للفرع
        ' مهم: افترضت وجود SP اسمها Select_Departments_ByBranchID
        Dim depts = db.Select_Departments_ByBranchID(BranchID).ToList()

        If depts Is Nothing OrElse depts.Count = 0 Then
            rptDepartments.DataSource = Nothing
            rptDepartments.DataBind()
            pnlNoDepartments.Visible = True
            Return
        End If

        pnlNoDepartments.Visible = False

        Dim list As New List(Of DepartmentEvalDto)()

        ' مصفوفة الألوان بالترتيب المطلوب (مثل الصورة)
        Dim colorClasses As String() = { _
                                           "dept-bg-secondary",
                                           "dept-bg-danger",
                                           "dept-bg-primary",
                                           "dept-bg-info",
                                           "dept-bg-success",
                                           "dept-bg-warning"
                                       }

        Dim index = 0

        For Each d In depts
            Dim deptId As Integer = d.ID

            ' تقييم القسم بناءً على كل التقييمات في الفرع لهذا القسم (1 و 2)
            Dim deptEvals = _branchEvaluations.Where(
                Function(ev) ev.Department_ID.HasValue AndAlso ev.Department_ID.Value = deptId _
                             AndAlso (ev.Evaluation_Type = 1 OrElse ev.Evaluation_Type = 2)
                ).ToList()

            Dim score As Decimal = CalculateScore(deptEvals)

            Dim empCount = 0
            If _branchUsers IsNot Nothing Then
                empCount = _branchUsers.Where(
                    Function(u) u.Department_ID.HasValue _
                                AndAlso u.Department_ID.Value = deptId _
                                AndAlso (u.IsActive = True OrElse u.IsActive Is Nothing)
                    ).Count()
            End If

            ' اختيار كلاس اللون حسب ترتيب القسم مع إعادة التكرار عند الانتهاء
            Dim bgClass As String = colorClasses(index Mod colorClasses.Length)
            index += 1

            list.Add(New DepartmentEvalDto With {
                        .DepartmentID = deptId,
                        .DepartmentName = d.Title_Ar,
                        .Score = score,
                        .EmployeesCount = empCount,
                        .BgClass = bgClass
                        })
        Next

        rptDepartments.DataSource = list
        rptDepartments.DataBind()
    End Sub

    ' ========== Bind Violations ==========
    Private Sub BindViolations()
        Dim evals = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).ToList()

        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        Dim shiftIds =
                evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds =
                evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim jobDict = (From j In db.Select_JobTitles_All()
                Where jobIds.Contains(j.ID)
                Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From s In db.Select_Shift_All()
                Where shiftIds.Contains(s.ID)
                Select s.ID, s.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brandsDict = (From b In db.Select_Brands_All()
                Where brandIds.Contains(b.ID)
                Select b.ID, b.Title_Ar, b.Logo).ToList()

        Dim brandLogoDefault = "/assets/img/Prosto/Logo_Circle.png"
        Dim brandLogoDict As New Dictionary(Of Integer, String)
        For Each b In brandsDict
            Dim logo As String = b.Logo
            If String.IsNullOrEmpty(logo) Then
                logo = brandLogoDefault
            End If
            brandLogoDict(b.ID) = logo
        Next

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) Then
                        allChecklistIds.Add(id)
                    End If
                Next
            End If
        Next

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CheckList_CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = allChecklists.ToDictionary(Function(x) x.ID)

        Dim tasks As New List(Of EvaluationTaskDto)()

        For Each ev In evals
            Dim jobName = ""
            Dim shiftName = ""
            Dim brandLogo As String = brandLogoDefault

            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then
                jobName = jobDict(ev.JobTitle_ID.Value)
            End If

            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then
                shiftName = shiftsDict(ev.Shift_ID.Value)
            End If

            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then
                brandLogo = brandLogoDict(ev.Brand_ID.Value)
            End If

            Dim viols As New List(Of ViolationDto)()

            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)
                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CheckList_CategoryID
                            Case 1
                                css = "badge-chip badge-danger-soft"
                            Case 2
                                css = "badge-chip badge-warning-soft"
                            Case 3
                                css = "badge-chip badge-primary-soft"
                        End Select

                        viols.Add(New ViolationDto With {
                                     .Title = c.Title_Ar,
                                     .CssClass = css
                                     })
                    End If
                Next
            End If

            tasks.Add(New EvaluationTaskDto With {
                         .EvaluationID = ev.ID,
                         .JobTitleName = jobName,
                         .ShiftName = shiftName,
                         .BrandLogoUrl = brandLogo,
                         .EvalDate = ev.AddedDate,
                         .Notes = ev.Notes,
                         .Violations = viols
                         })
        Next

        rptViolations.DataSource = tasks
        rptViolations.DataBind()
    End Sub

    ' ========== Bind Complaints ==========
    Private Sub BindComplaints()
        Dim evals = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).ToList()

        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        Dim shiftIds =
                evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds =
                evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim jobDict = (From j In db.Select_JobTitles_All()
                Where jobIds.Contains(j.ID)
                Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From s In db.Select_Shift_All()
                Where shiftIds.Contains(s.ID)
                Select s.ID, s.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brandsDict = (From b In db.Select_Brands_All()
                Where brandIds.Contains(b.ID)
                Select b.ID, b.Title_Ar, b.Logo).ToList()

        Dim brandLogoDefault = "/assets/img/Prosto/Logo_Circle.png"
        Dim brandLogoDict As New Dictionary(Of Integer, String)
        For Each b In brandsDict
            Dim logo As String = b.Logo
            If String.IsNullOrEmpty(logo) Then
                logo = brandLogoDefault
            End If
            brandLogoDict(b.ID) = logo
        Next

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) Then
                        allChecklistIds.Add(id)
                    End If
                Next
            End If
        Next

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CheckList_CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = allChecklists.ToDictionary(Function(x) x.ID)

        Dim complaints As New List(Of EvaluationTaskDto)()

        For Each ev In evals
            Dim jobName = ""
            Dim shiftName = ""
            Dim brandLogo As String = brandLogoDefault

            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then
                jobName = jobDict(ev.JobTitle_ID.Value)
            End If

            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then
                shiftName = shiftsDict(ev.Shift_ID.Value)
            End If

            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then
                brandLogo = brandLogoDict(ev.Brand_ID.Value)
            End If

            Dim viols As New List(Of ViolationDto)()

            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)
                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CheckList_CategoryID
                            Case 1
                                css = "badge-chip badge-danger-soft"
                            Case 2
                                css = "badge-chip badge-warning-soft"
                            Case 3
                                css = "badge-chip badge-primary-soft"
                        End Select

                        viols.Add(New ViolationDto With {
                                     .Title = c.Title_Ar,
                                     .CssClass = css
                                     })
                    End If
                Next
            End If

            complaints.Add(New EvaluationTaskDto With {
                              .EvaluationID = ev.ID,
                              .JobTitleName = jobName,
                              .ShiftName = shiftName,
                              .BrandLogoUrl = brandLogo,
                              .EvalDate = ev.AddedDate,
                              .Notes = ev.Notes,
                              .Violations = viols
                              })
        Next

        rptComplaints.DataSource = complaints
        rptComplaints.DataBind()
    End Sub

    ' ===== Helpers: Close evaluation =====
    Private Sub CloseEvaluation(evalId As Integer)
        db.ExecuteCommand("EXEC Update_Evaluations_IsSolved_ByID {0}, {1}", evalId, 1)

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reloadPage", "window.location.reload();", True)
    End Sub

    ' ========== Close ALL Violations ==========
    Protected Sub btnCloseAllViolations_Click(sender As Object, e As EventArgs) Handles btnCloseAllViolations.Click
        Dim ids = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).Select(Function(ev) ev.ID).ToList()

        For Each EvaluationID In ids
            CloseEvaluation(EvaluationID)
        Next

        LoadBranchEvaluations()
        BindBranchGaugeAndSummary()
        BindDepartments()
        BindViolations()
        BindComplaints()
    End Sub

    ' ========== Close ALL Complaints ==========
    Protected Sub btnCloseAllComplaints_Click(sender As Object, e As EventArgs) Handles btnCloseAllComplaints.Click
        Dim ids = _branchEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).Select(Function(ev) ev.ID).ToList()

        For Each ComplaintID In ids
            CloseEvaluation(ComplaintID)
        Next

        LoadBranchEvaluations()
        BindBranchGaugeAndSummary()
        BindDepartments()
        BindViolations()
        BindComplaints()
    End Sub

    ' ========== Attachments & Close One ==========
    Protected Sub rptViolations_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptViolations.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        ElseIf e.CommandName = "CloseOneViolation" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            CloseEvaluation(evalId)
        End If
    End Sub

    Protected Sub rptComplaints_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptComplaints.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        ElseIf e.CommandName = "CloseOneComplaint" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            CloseEvaluation(evalId)
        End If
    End Sub

    Private Sub BindAttachments(evaluationId As Integer)
        Dim atts = (From a In db.Select_Evaluations_Attachments_ByEvaluation_ID(evaluationId)
                Select New With {
                .Title = a.Title,
                .FilePath = a.File_Path
                }).ToList()

        If atts Is Nothing OrElse atts.Count = 0 Then
            Dim scriptNoAtt = "alert('لا يوجد مرفقات لهذا التقييم');"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noAttAlert", scriptNoAtt, True)
            Return
        End If

        rptAttachmentsCarousel.DataSource = atts
        rptAttachmentsCarousel.DataBind()

        Dim script As String =
                "setTimeout(function(){" &
                "var m = new bootstrap.Modal(document.getElementById('attachmentsModal')); m.show();" &
                "}, 200);"

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "showAttachmentsModal", script, True)
    End Sub

    ' ========== Secure Video Token ==========
    Private Function BuildSecureVideoUrl(relativePath As String) As String
        If String.IsNullOrWhiteSpace(relativePath) Then
            Return String.Empty
        End If

        Dim normPath As String = relativePath.Trim()
        If Not normPath.StartsWith("~") AndAlso Not normPath.StartsWith("/") Then
            normPath = "~" & normPath
        End If

        Dim token As String = GenerateVideoToken(normPath, 60)
        Return ResolveUrl("~/DeptVideoHandler.ashx?t=" & token)
    End Function

    Private Function GenerateVideoToken(virtualPath As String, expiryMinutes As Integer) As String
        Dim expires As Long = DateTime.UtcNow.AddMinutes(expiryMinutes).Ticks
        Dim payload As String = virtualPath & "|" & expires.ToString()

        Dim bytes As Byte() = Encoding.UTF8.GetBytes(payload)
        Dim protectedBytes As Byte() = MachineKey.Protect(bytes, "DeptVideoToken")

        Return HttpServerUtility.UrlTokenEncode(protectedBytes)
    End Function

    Protected Sub btnCloseEdit_Click(sender As Object, e As EventArgs)
        'ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reloadPage", "window.location.reload();", True)
        Response.Redirect(Request.RawUrl)
    End Sub

    Protected Sub btnCloseEditHeader_Click(sender As Object, e As EventArgs)
        'ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reloadPage", "window.location.reload();", True)
        Response.Redirect(Request.RawUrl)
    End Sub
End Class


