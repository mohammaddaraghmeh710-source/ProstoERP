Imports System.Globalization
Imports System.Threading.Tasks
Imports Prosto_ERP_ClassLibrary

Public Class MyProfile
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_DataClassesDataContext()

    Protected EmployeeID As Integer

    ' ===== DTOs =====
    Private Class ViolationDto
        Public Property Title As String
        Public Property CssClass As String
    End Class

    Private Class EvaluationTaskDto
        Public Property EvaluationID As Integer
        Public Property DepartmentName As String
        Public Property JobTitleName As String
        Public Property ShiftName As String
        Public Property BrandLogoUrl As String
        Public Property EvalDate As DateTime?
        Public Property Notes As String
        Public Property Violations As List(Of ViolationDto)
        Public Property StatusText As String
        Public Property StatusCss As String
    End Class

    Private Class EmployeeChecklistRowDto
        Public Property ID As Integer
        Public Property Title As String
        Public Property Brief As String
        Public Property CategoryID As Integer
        Public Property CategoryTitle As String
        Public Property Weight As Decimal
    End Class

    ' ===== Data caches =====
    Private _employeeEvaluations As List(Of Select_Evaluations_ByEmployeeIDResult) _
    ' قديم (مهام + شكاوي)
    Private _employeeViolations As List(Of Select_EvaluationsEmployees_ByEmployeeIDResult) _
    ' جديد (Evaluations_Employees)

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()
        lnkHRProfile.Visible = EmployeeID > 0 AndAlso (SessionManager.GetInstance.Users.UserType = 1 OrElse EmployeeID = SessionManager.GetInstance.Users.UserID)
        If lnkHRProfile.Visible Then lnkHRProfile.NavigateUrl = "~/Modules/Employees/HRProfile.aspx?EmployeeID=" & EmployeeID.ToString(CultureInfo.InvariantCulture)
        pnlAttendance.Visible = EmployeeID > 0 AndAlso (SessionManager.GetInstance.Users.UserType = 1 OrElse EmployeeID = SessionManager.GetInstance.Users.UserID)
        If pnlAttendance.Visible Then
            lnkAttendance.NavigateUrl = "/Modules/Employees/AttendanceHistory.aspx?EmployeeID=" &
                                        EmployeeID.ToString(CultureInfo.InvariantCulture)
            If Not IsPostBack Then RegisterAsyncTask(New PageAsyncTask(AddressOf BindTodayAttendance))
        End If

        ' تحميل التقييمات دائماً حتى في PostBack
        LoadEmployeeEvaluations()
        LoadEmployeeViolations()

        If Not IsPostBack Then
            BindHeader()

            ' ✅ تقييم نهائي: (تقييم المهام + تقييم المخالفات) / 2
            BindGaugeAndSummary()

            ' القديم
            BindChecklistSummary()
            BindHistoryFilters()
            ddlStatusFilter.SelectedValue = "open"
            BindViolationsHistory()
            BindComplaints()

            ' الجديد
            BindViolationsFilters()
            BindEmployeeViolations()
            BindViolationsSummary()
        End If
    End Sub

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        ViewStateUserKey = Session.SessionID
    End Sub

    Private Async Function BindTodayAttendance() As Task
        Try
            Dim actor = SessionManager.GetInstance.Users.UserID
            Dim employee = AttendanceData.Employee(actor, EmployeeID)
            Dim today = AttendanceData.Today()
            Dim data = Await AttendanceData.Transactions(actor, employee, today, today)
            rptTodayAttendance.DataSource = data
            rptTodayAttendance.DataBind()
            lblNoAttendance.Visible = data.Rows.Count = 0
        Catch ex As Exception
            litAttendanceMessage.Text = "<div role='alert' class='alert alert-warning'>" &
                                        Server.HtmlEncode(AttendanceData.ErrorText(ex)) & "</div>"
        End Try
    End Function

    Private Sub LoadParameters()
        If Not Integer.TryParse(Request.QueryString("EmployeeID"), EmployeeID) Then
            EmployeeID = 0
        End If
    End Sub

    Private Sub LoadEmployeeEvaluations()
        _employeeEvaluations = db.Select_Evaluations_ByEmployeeID(EmployeeID).ToList()
    End Sub

    ' ✅ مخالفات الموظف (Evaluations_Employees)
    Private Sub LoadEmployeeViolations()
        _employeeViolations = db.Select_EvaluationsEmployees_ByEmployeeID(EmployeeID).ToList()
    End Sub

    ' ===== Header =====
    Private Sub BindHeader()
        Dim emp = db.Select_UsersMembers_ByID(EmployeeID).FirstOrDefault()
        If emp Is Nothing Then Return

        lblEmployeeName.Text = emp.FullName_Ar
        litEmployeeCode.Text = emp.Employee_Number

        Dim deptName = ""
        Dim jobName = ""

        If emp.Department_ID.HasValue Then
            Dim d = db.Select_Departments_ByID(emp.Department_ID.Value).FirstOrDefault()
            If d IsNot Nothing Then deptName = d.Title_Ar
        End If

        If emp.JobTitle_ID.HasValue Then
            Dim j = db.Select_JobTitles_ByID(emp.JobTitle_ID.Value).FirstOrDefault()
            If j IsNot Nothing Then jobName = j.Title_Ar
        End If

        Dim deptJob = ""
        If deptName <> "" Then deptJob = deptName
        If jobName <> "" Then
            If deptJob <> "" Then deptJob &= " – " & jobName Else deptJob = jobName
        End If
        litDeptJob.Text = deptJob

        Dim branchText = ""
        If emp.Branch_ID.HasValue Then
            Dim br = db.Select_Branches_ByID(emp.Branch_ID.Value).FirstOrDefault()
            If br IsNot Nothing Then
                Dim brandRow =
                        If(br.BrandID.HasValue, db.Select_Brands_ByID(br.BrandID.Value).FirstOrDefault(), Nothing)
                Dim brandName As String = If(brandRow IsNot Nothing, brandRow.Title_Ar, "")
                Dim branchName As String = br.Title_Ar
                If brandName <> "" Then branchText = brandName & " – " & branchName Else branchText = branchName
            End If
        End If
        litBrandBranch.Text = branchText

        Dim avatar As String = emp.User_Image
        If String.IsNullOrEmpty(avatar) Then
            Dim g As Integer? = emp.Gender
            If g.HasValue AndAlso g.Value = 2 Then
                avatar = "/assets/img/Prosto/avatar-female.png"
            Else
                avatar = "/assets/img/Prosto/avatar-male.png"
            End If
        End If
        imgEmployee.Src = avatar

        ' آخر تقييم (من القديم + الجديد)
        Dim lastOld As DateTime? = Nothing
        If _employeeEvaluations IsNot Nothing AndAlso _employeeEvaluations.Count > 0 Then
            Dim x =
                    _employeeEvaluations.Where(Function(e) e.AddedDate.HasValue).OrderByDescending(
                        Function(e) e.AddedDate).FirstOrDefault()
            If x IsNot Nothing Then lastOld = x.AddedDate
        End If

        Dim lastNew As DateTime? = Nothing
        If _employeeViolations IsNot Nothing AndAlso _employeeViolations.Count > 0 Then
            Dim y =
                    _employeeViolations.Where(Function(e) e.AddedDate.HasValue).OrderByDescending(
                        Function(e) e.AddedDate).FirstOrDefault()
            If y IsNot Nothing Then lastNew = y.AddedDate
        End If

        Dim lastFinal As DateTime? = Nothing
        If lastOld.HasValue AndAlso lastNew.HasValue Then
            lastFinal = If(lastOld.Value > lastNew.Value, lastOld, lastNew)
        ElseIf lastOld.HasValue Then
            lastFinal = lastOld
        ElseIf lastNew.HasValue Then
            lastFinal = lastNew
        End If

        If lastFinal.HasValue Then
            litLastEvalDate.Text = lastFinal.Value.ToString("dd/MM/yyyy HH:mm")
        Else
            litLastEvalDate.Text = "-"
        End If
    End Sub

    ' ===== Score calculation (نفس منطقك) =====
    Private Function CalculateScoreFromWeights(totalWeight As Decimal, count As Integer) As Decimal
        If count <= 0 Then Return 0D

        Dim maxScore As Decimal = count*100D
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

    ' ===== Gauge + Summary (نهائي) =====
    Private Sub BindGaugeAndSummary()

        ' 1) المهام (القديم) - اعتبرناها Evaluation_Type = 1
        Dim tasks = _employeeEvaluations.Where(Function(ev) ev.Evaluation_Type = 1).ToList()

        Dim tasksWeight As Decimal =
                tasks.Sum(Function(ev) If(ev IsNot Nothing AndAlso ev.Weight.HasValue, CDec(ev.Weight.Value), 0D))


        ' 2) المخالفات (الجديد) من Evaluations_Employees
        Dim vCount As Integer = If(_employeeViolations IsNot Nothing, _employeeViolations.Count, 0)
        Dim vWeight = 0D

        If _employeeViolations IsNot Nothing Then
            vWeight =
                _employeeViolations.Sum(
                    Function(ev) If(ev IsNot Nothing AndAlso ev.Weight.HasValue, CDec(ev.Weight.Value), 0D))
        End If

        Dim tasksScore As Decimal = CalculateScoreFromWeights(tasksWeight + vWeight, tasks.Count + vCount)
        Dim finalScore As Decimal = tasksScore
        'Dim violationsScore As Decimal = CalculateScoreFromWeights(vWeight, vCount)

        'Dim finalScore As Decimal
        'If vCount <> 0 Then
        '    finalScore = (tasksScore + violationsScore) / 2D
        'Else
        '    finalScore = (tasksScore)
        'End If

        litEmployeeScore.Text = finalScore.ToString("0.0", CultureInfo.InvariantCulture) & "%"
        divEmployeeGauge.Attributes("data-value") = finalScore.ToString("0.##", CultureInfo.InvariantCulture)
        divEmployeeGauge.Attributes("class") = GetGaugeCss(finalScore)

        ' ===== Counters =====
        Dim openTasks =
                _employeeEvaluations.Where(
                    Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)).
                ToList()
        Dim complaints =
                _employeeEvaluations.Where(
                    Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)).
                ToList()

        litEmployeeViolationsCount.Text = vCount.ToString()
        litOpenTasksCount.Text = openTasks.Count.ToString()
        litComplaintsCount.Text = complaints.Count.ToString()
        litComplaintsBadge.Text = complaints.Count.ToString()
        litTotalEvals.Text = (_employeeEvaluations.Count() + vCount).ToString()


        pnlNoComplaints.Visible = (complaints.Count = 0)
    End Sub

    ' =========================
    ' القديم: ملخص المهام المتكررة + فلاتر المهام + سجل المهام + الشكاوي
    ' (تركته كما هو تقريباً)
    ' =========================

    Private Sub BindChecklistSummary()
        Dim evals = _employeeEvaluations.
                Where(Function(ev) ev.Evaluation_Type = 1 AndAlso Not String.IsNullOrWhiteSpace(ev.Checklist_IDs)).
                ToList()

        If evals.Count = 0 Then
            pnlNoChecklistSummary.Visible = True
            rptChecklistSummary.DataSource = Nothing
            rptChecklistSummary.DataBind()
            Return
        End If

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            Dim parts = ev.Checklist_IDs.Split(","c)
            For Each p In parts
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) Then allChecklistIds.Add(id)
            Next
        Next

        If allChecklistIds.Count = 0 Then
            pnlNoChecklistSummary.Visible = True
            rptChecklistSummary.DataSource = Nothing
            rptChecklistSummary.DataBind()
            Return
        End If

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim counts As New Dictionary(Of Integer, Integer)()
        For Each ev In evals
            Dim parts = ev.Checklist_IDs.Split(","c)
            For Each p In parts
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) AndAlso allChecklistIds.Contains(id) Then
                    If Not counts.ContainsKey(id) Then counts(id) = 0
                    counts(id) += 1
                End If
            Next
        Next

        Dim summary = (From kvp In counts
                Join c In allChecklists On kvp.Key Equals c.ID
                Let catId = c.CategoryID
                Let css = If(catId = 1, "summary-danger",
                             If(catId = 2, "summary-warning", "summary-normal"))
                Select New With {
                .ChecklistID = c.ID,
                .Title = c.Title_Ar,
                .CategoryTitle = c.CategoryTitle,
                .CategoryID = catId,
                .Count = kvp.Value,
                .CssClass = css
                }).
                OrderByDescending(Function(x) x.Count).
                ThenBy(Function(x) x.Title).
                ToList()

        pnlNoChecklistSummary.Visible = (summary.Count = 0)
        rptChecklistSummary.DataSource = summary
        rptChecklistSummary.DataBind()
    End Sub

    Private Sub BindHistoryFilters()
        ' كما هو في كودك (لم أغيره)
        Dim evals = _employeeEvaluations.
                Where(Function(ev) ev.Evaluation_Type = 1 AndAlso Not String.IsNullOrWhiteSpace(ev.Checklist_IDs)).
                ToList()

        ddlChecklistCategoryFilter.Items.Clear()
        ddlChecklistFilter.Items.Clear()

        ddlChecklistCategoryFilter.Items.Add(New ListItem("الكل", ""))
        ddlChecklistFilter.Items.Add(New ListItem("الكل", ""))

        If evals.Count = 0 Then Return

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            Dim parts = ev.Checklist_IDs.Split(","c)
            For Each p In parts
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) Then allChecklistIds.Add(id)
            Next
        Next

        If allChecklistIds.Count = 0 Then Return

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim usedCategoryIds As New HashSet(Of Integer)()
        For Each c In allChecklists
            usedCategoryIds.Add(c.CategoryID)
        Next

        For Each catId In usedCategoryIds.OrderBy(Function(id) id)
            Dim text As String
            Select Case catId
                Case 1 : text = "مهام خطيرة"
                Case 2 : text = "مهام متوسطة"
                Case 3 : text = "مهام عادية"
                Case Else : text = "تصنيف آخر"
            End Select

            ddlChecklistCategoryFilter.Items.Add(New ListItem(text, catId.ToString()))
        Next

        Dim usedChecklistIds As New HashSet(Of Integer)()
        For Each c In allChecklists.OrderBy(Function(x) x.Title_Ar)
            If Not usedChecklistIds.Contains(c.ID) Then
                usedChecklistIds.Add(c.ID)
                ddlChecklistFilter.Items.Add(New ListItem(c.Title_Ar, c.ID.ToString()))
            End If
        Next
    End Sub

    Private Sub BindViolationsHistory()
        ' كما هو في كودك (سجل المهام)
        ' ... (نفس كودك بالكامل)
        ' ملاحظة: أنا لم أحذف شيء هنا — فقط اعتمدنا العنوان الجديد في الـ ASPX.
        ' ==========
        Dim evals = _employeeEvaluations.Where(Function(ev) ev.Evaluation_Type = 1).ToList()

        Dim statusFilter As String = ddlStatusFilter.SelectedValue
        If statusFilter = "open" Then
            evals = evals.Where(Function(ev) ev.IsSolved = False OrElse ev.IsSolved Is Nothing).ToList()
        ElseIf statusFilter = "closed" Then
            evals = evals.Where(Function(ev) ev.IsSolved = True).ToList()
        End If

        Dim fromDate As DateTime?
        Dim toDate As DateTime?

        If Not String.IsNullOrWhiteSpace(txtFromDate.Text) Then
            Dim dt As DateTime
            If _
                DateTime.TryParseExact(txtFromDate.Text.Trim(), {"dd/MM/yyyy", "yyyy-MM-dd"},
                                       CultureInfo.InvariantCulture, DateTimeStyles.None, dt) Then
                fromDate = dt.Date
            End If
        End If

        If Not String.IsNullOrWhiteSpace(txtToDate.Text) Then
            Dim dt As DateTime
            If _
                DateTime.TryParseExact(txtToDate.Text.Trim(), {"dd/MM/yyyy", "yyyy-MM-dd"}, CultureInfo.InvariantCulture,
                                       DateTimeStyles.None, dt) Then
                toDate = dt.Date
            End If
        End If

        If fromDate.HasValue Then
            evals =
                evals.Where(Function(ev) ev.AddedDate.HasValue AndAlso ev.AddedDate.Value.Date >= fromDate.Value).ToList()
        End If
        If toDate.HasValue Then
            evals =
                evals.Where(Function(ev) ev.AddedDate.HasValue AndAlso ev.AddedDate.Value.Date <= toDate.Value).ToList()
        End If

        Dim deptIds =
                evals.Where(Function(e) e.Department_ID.HasValue).Select(Function(e) e.Department_ID.Value).Distinct().
                ToList()
        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        Dim shiftIds =
                evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds =
                evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim deptDict = (From d In db.Select_Departments_All()
                Where deptIds.Contains(d.ID)
                Select d.ID, d.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

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
            If String.IsNullOrEmpty(logo) Then logo = brandLogoDefault
            brandLogoDict(b.ID) = logo
        Next

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) Then allChecklistIds.Add(id)
                Next
            End If
        Next

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = allChecklists.ToDictionary(Function(x) x.ID)

        Dim selectedCatId As Integer?
        Dim selectedChecklistId As Integer?

        If Not String.IsNullOrEmpty(ddlChecklistCategoryFilter.SelectedValue) Then
            Dim cid As Integer
            If Integer.TryParse(ddlChecklistCategoryFilter.SelectedValue, cid) Then selectedCatId = cid
        End If
        If Not String.IsNullOrEmpty(ddlChecklistFilter.SelectedValue) Then
            Dim cid As Integer
            If Integer.TryParse(ddlChecklistFilter.SelectedValue, cid) Then selectedChecklistId = cid
        End If

        Dim result As New List(Of EvaluationTaskDto)()

        For Each ev In evals
            Dim deptName = ""
            Dim jobName = ""
            Dim shiftName = ""
            Dim brandLogo As String = brandLogoDefault

            If ev.Department_ID.HasValue AndAlso deptDict.ContainsKey(ev.Department_ID.Value) Then _
                deptName = deptDict(ev.Department_ID.Value)
            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then _
                jobName = jobDict(ev.JobTitle_ID.Value)
            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then _
                shiftName = shiftsDict(ev.Shift_ID.Value)
            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then _
                brandLogo = brandLogoDict(ev.Brand_ID.Value)

            Dim viols As New List(Of ViolationDto)()
            Dim hasMatchedChecklist = False
            Dim hasMatchedCategory = False

            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)

                        If selectedCatId.HasValue Then
                            If c.CategoryID = selectedCatId.Value Then hasMatchedCategory = True
                        Else
                            hasMatchedCategory = True
                        End If

                        If selectedChecklistId.HasValue Then
                            If id = selectedChecklistId.Value Then hasMatchedChecklist = True
                        Else
                            hasMatchedChecklist = True
                        End If

                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CategoryID
                            Case 1 : css = "badge-chip badge-danger-soft"
                            Case 2 : css = "badge-chip badge-warning-soft"
                            Case 3 : css = "badge-chip badge-primary-soft"
                        End Select

                        viols.Add(New ViolationDto With {.Title = c.Title_Ar, .CssClass = css})
                    End If
                Next
            End If

            Dim passFilter = True
            If selectedCatId.HasValue AndAlso Not hasMatchedCategory Then passFilter = False
            If selectedChecklistId.HasValue AndAlso Not hasMatchedChecklist Then passFilter = False
            If Not passFilter Then Continue For

            Dim isClosed As Boolean = ev.IsSolved.HasValue AndAlso ev.IsSolved.Value
            Dim statusText As String = If(isClosed, "منجزة", "غير منجزة")
            Dim statusCss As String = If(isClosed, "status-badge status-closed", "status-badge status-open")

            result.Add(New EvaluationTaskDto With {
                          .EvaluationID = ev.ID,
                          .DepartmentName = deptName,
                          .JobTitleName = jobName,
                          .ShiftName = shiftName,
                          .BrandLogoUrl = brandLogo,
                          .EvalDate = ev.AddedDate,
                          .Notes = ev.Notes,
                          .Violations = viols,
                          .StatusText = statusText,
                          .StatusCss = statusCss
                          })
        Next

        result = result.OrderByDescending(Function(x) x.EvalDate).ToList()
        pnlNoViolationsHistory.Visible = (result.Count = 0)
        rptViolationsHistory.DataSource = result
        rptViolationsHistory.DataBind()
    End Sub

    Private Sub BindComplaints()
        ' نفس كودك القديم (لم أغيره)
        Dim evals =
                _employeeEvaluations.Where(
                    Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)).
                ToList()

        Dim deptIds =
                evals.Where(Function(e) e.Department_ID.HasValue).Select(Function(e) e.Department_ID.Value).Distinct().
                ToList()
        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        Dim shiftIds =
                evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds =
                evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim deptDict = (From d In db.Select_Departments_All()
                Where deptIds.Contains(d.ID)
                Select d.ID, d.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

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
            If String.IsNullOrEmpty(logo) Then logo = brandLogoDefault
            brandLogoDict(b.ID) = logo
        Next

        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) Then allChecklistIds.Add(id)
                Next
            End If
        Next

        Dim allChecklists = (From c In db.Select_Checklist_All()
                Join cat In db.Checklist_Categories_SelectAll() On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = allChecklists.ToDictionary(Function(x) x.ID)
        Dim complaints As New List(Of EvaluationTaskDto)()

        For Each ev In evals
            Dim deptName = ""
            Dim jobName = ""
            Dim shiftName = ""
            Dim brandLogo As String = brandLogoDefault

            If ev.Department_ID.HasValue AndAlso deptDict.ContainsKey(ev.Department_ID.Value) Then _
                deptName = deptDict(ev.Department_ID.Value)
            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then _
                jobName = jobDict(ev.JobTitle_ID.Value)
            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then _
                shiftName = shiftsDict(ev.Shift_ID.Value)
            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then _
                brandLogo = brandLogoDict(ev.Brand_ID.Value)

            Dim viols As New List(Of ViolationDto)()
            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)
                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CategoryID
                            Case 1 : css = "badge-chip badge-danger-soft"
                            Case 2 : css = "badge-chip badge-warning-soft"
                            Case 3 : css = "badge-chip badge-primary-soft"
                        End Select
                        viols.Add(New ViolationDto With {.Title = c.Title_Ar, .CssClass = css})
                    End If
                Next
            End If

            complaints.Add(New EvaluationTaskDto With {
                              .EvaluationID = ev.ID,
                              .DepartmentName = deptName,
                              .JobTitleName = jobName,
                              .ShiftName = shiftName,
                              .BrandLogoUrl = brandLogo,
                              .EvalDate = ev.AddedDate,
                              .Notes = ev.Notes,
                              .Violations = viols
                              })
        Next

        pnlNoComplaints.Visible = (complaints.Count = 0)
        rptComplaints.DataSource = complaints
        rptComplaints.DataBind()
    End Sub

    ' =========================
    ' ✅ الجديد: فلاتر + سجل المخالفات + ملخص المخالفات
    ' =========================

    Private Sub BindViolationsFilters()
        ddlVCategory.Items.Clear()
        ddlVChecklist.Items.Clear()

        ddlVCategory.Items.Add(New ListItem("الكل", ""))
        ddlVChecklist.Items.Add(New ListItem("الكل", ""))

        ' نملأ الفلاتر من المخالفات الموجودة فعلياً + من جدول checklist employee
        Dim evals =
                If _
                (_employeeViolations,
                 New List(Of Select_EvaluationsEmployees_ByEmployeeIDResult)) _
                .Where(Function(x) Not String.IsNullOrWhiteSpace(x.Checklist_IDs)) _
                .ToList()

        If evals.Count = 0 Then Return

        Dim ids As New HashSet(Of Integer)()
        For Each ev In evals
            For Each p In ev.Checklist_IDs.Split(","c)
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) Then ids.Add(id)
            Next
        Next
        If ids.Count = 0 Then Return

        ' نستخدم جدول Checklist_Employee + Categories
        Dim all = (From c In db.Select_Checklist_Employee_All
                Join cat In db.Checklist_Employee_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                Where ids.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar,
                .ItemOrder = cat.Item_Order
                }).ToList()

        Dim catSet As New HashSet(Of Integer)()
        For Each x In all
            catSet.Add(x.CategoryID)
        Next

        For Each catId In catSet.OrderBy(Function(z) z)
            Dim catTitle =
                    all.Where(Function(a) a.CategoryID = catId).Select(Function(a) a.CategoryTitle).FirstOrDefault()
            ddlVCategory.Items.Add(New ListItem(catTitle, catId.ToString()))
        Next

        For Each x In all.OrderBy(Function(a) a.Title)
            ddlVChecklist.Items.Add(New ListItem(x.Title, x.ID.ToString()))
        Next
    End Sub

    Private Sub BindEmployeeViolations()
        Dim evals =
                If _
                (_employeeViolations,
                 New List(Of Select_EvaluationsEmployees_ByEmployeeIDResult)).ToList()

        ' 1) status
        Dim s = ddlVStatus.SelectedValue
        If s = "open" Then
            evals = evals.Where(Function(ev) ev.IsSolved = False OrElse ev.IsSolved Is Nothing).ToList()
        ElseIf s = "closed" Then
            evals = evals.Where(Function(ev) ev.IsSolved = True).ToList()
        End If

        ' 2) date
        Dim fromDate As DateTime?
        Dim toDate As DateTime?

        If Not String.IsNullOrWhiteSpace(txtVFrom.Text) Then
            Dim dt As DateTime
            If _
                DateTime.TryParseExact(txtVFrom.Text.Trim(), {"dd/MM/yyyy", "yyyy-MM-dd"}, CultureInfo.InvariantCulture,
                                       DateTimeStyles.None, dt) Then
                fromDate = dt.Date
            End If
        End If

        If Not String.IsNullOrWhiteSpace(txtVTo.Text) Then
            Dim dt As DateTime
            If _
                DateTime.TryParseExact(txtVTo.Text.Trim(), {"dd/MM/yyyy", "yyyy-MM-dd"}, CultureInfo.InvariantCulture,
                                       DateTimeStyles.None, dt) Then
                toDate = dt.Date
            End If
        End If

        If fromDate.HasValue Then
            evals =
                evals.Where(Function(ev) ev.AddedDate.HasValue AndAlso ev.AddedDate.Value.Date >= fromDate.Value).ToList()
        End If
        If toDate.HasValue Then
            evals =
                evals.Where(Function(ev) ev.AddedDate.HasValue AndAlso ev.AddedDate.Value.Date <= toDate.Value).ToList()
        End If

        ' dictionaries
        Dim deptIds =
                evals.Where(Function(e) e.Department_ID.HasValue).Select(Function(e) e.Department_ID.Value).Distinct().
                ToList()
        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        Dim shiftIds =
                evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()

        Dim deptDict = (From d In db.Select_Departments_All()
                Where deptIds.Contains(d.ID)
                Select d.ID, d.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim jobDict = (From j In db.Select_JobTitles_All()
                Where jobIds.Contains(j.ID)
                Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From sh In db.Select_Shift_All()
                Where shiftIds.Contains(sh.ID)
                Select sh.ID, sh.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        ' Checklist dictionary from Checklist_Employee
        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                For Each p In ev.Checklist_IDs.Split(","c)
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) Then allChecklistIds.Add(id)
                Next
            End If
        Next

        Dim checklistRows = (From c In db.Select_Checklist_Employee_All
                Join cat In db.Checklist_Employee_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                Where allChecklistIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = checklistRows.ToDictionary(Function(x) x.ID)

        Dim selectedCat As Integer? = Nothing
        Dim selectedItem As Integer? = Nothing

        If Not String.IsNullOrEmpty(ddlVCategory.SelectedValue) Then
            Dim cid As Integer
            If Integer.TryParse(ddlVCategory.SelectedValue, cid) Then selectedCat = cid
        End If

        If Not String.IsNullOrEmpty(ddlVChecklist.SelectedValue) Then
            Dim cid As Integer
            If Integer.TryParse(ddlVChecklist.SelectedValue, cid) Then selectedItem = cid
        End If

        Dim result As New List(Of EvaluationTaskDto)()

        For Each ev In evals
            Dim deptName = ""
            Dim jobName = ""
            Dim shiftName = ""

            If ev.Department_ID.HasValue AndAlso deptDict.ContainsKey(ev.Department_ID.Value) Then _
                deptName = deptDict(ev.Department_ID.Value)
            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then _
                jobName = jobDict(ev.JobTitle_ID.Value)
            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then _
                shiftName = shiftsDict(ev.Shift_ID.Value)

            Dim viols As New List(Of ViolationDto)()
            Dim matchCat As Boolean = (Not selectedCat.HasValue)
            Dim matchItem As Boolean = (Not selectedItem.HasValue)

            If ev.Checklist_IDs IsNot Nothing Then
                For Each p In ev.Checklist_IDs.Split(","c)
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)

                        If selectedCat.HasValue AndAlso c.CategoryID = selectedCat.Value Then matchCat = True
                        If selectedItem.HasValue AndAlso id = selectedItem.Value Then matchItem = True

                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CategoryID
                            Case 1 : css = "badge-chip badge-danger-soft"
                            Case 2 : css = "badge-chip badge-warning-soft"
                            Case 3 : css = "badge-chip badge-primary-soft"
                        End Select

                        viols.Add(New ViolationDto With {.Title = c.Title, .CssClass = css})
                    End If
                Next
            End If

            If selectedCat.HasValue AndAlso Not matchCat Then Continue For
            If selectedItem.HasValue AndAlso Not matchItem Then Continue For

            Dim isClosed As Boolean = ev.IsSolved.HasValue AndAlso ev.IsSolved.Value
            Dim statusText As String = If(isClosed, "منجزة", "غير منجزة")
            Dim statusCss As String = If(isClosed, "status-badge status-closed", "status-badge status-open")

            result.Add(New EvaluationTaskDto With {
                          .EvaluationID = ev.ID,
                          .DepartmentName = deptName,
                          .JobTitleName = jobName,
                          .ShiftName = shiftName,
                          .BrandLogoUrl = "", ' غير مطلوب هنا
                          .EvalDate = ev.AddedDate,
                          .Notes = ev.Notes,
                          .Violations = viols,
                          .StatusText = statusText,
                          .StatusCss = statusCss
                          })
        Next

        result = result.OrderByDescending(Function(x) x.EvalDate).ToList()

        pnlNoViolations.Visible = (result.Count = 0)
        rptEmployeeViolations.DataSource = result
        rptEmployeeViolations.DataBind()
    End Sub

    Private Sub BindViolationsSummary()
        Dim evals =
                If _
                (_employeeViolations,
                 New List(Of Select_EvaluationsEmployees_ByEmployeeIDResult)) _
                .Where(Function(ev) Not String.IsNullOrWhiteSpace(ev.Checklist_IDs)) _
                .ToList()

        If evals.Count = 0 Then
            pnlNoViolationsSummary.Visible = True
            rptViolationsSummary.DataSource = Nothing
            rptViolationsSummary.DataBind()
            Return
        End If

        Dim allIds As New HashSet(Of Integer)()
        For Each ev In evals
            For Each p In ev.Checklist_IDs.Split(","c)
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) Then allIds.Add(id)
            Next
        Next

        If allIds.Count = 0 Then
            pnlNoViolationsSummary.Visible = True
            rptViolationsSummary.DataSource = Nothing
            rptViolationsSummary.DataBind()
            Return
        End If

        Dim all = (From c In db.Select_Checklist_Employee_All
                Join cat In db.Checklist_Employee_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                Where allIds.Contains(c.ID)
                Select New With {
                .ID = c.ID,
                .Title = c.Title_Ar,
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim counts As New Dictionary(Of Integer, Integer)()
        For Each ev In evals
            For Each p In ev.Checklist_IDs.Split(","c)
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) AndAlso allIds.Contains(id) Then
                    If Not counts.ContainsKey(id) Then counts(id) = 0
                    counts(id) += 1
                End If
            Next
        Next

        Dim summary = (From kvp In counts
                Join c In all On kvp.Key Equals c.ID
                Let catId = c.CategoryID
                Let css = If(catId = 1, "summary-danger",
                             If(catId = 2, "summary-warning", "summary-normal"))
                Select New With {
                .ChecklistID = c.ID,
                .Title = c.Title,
                .CategoryTitle = c.CategoryTitle,
                .CategoryID = catId,
                .Count = kvp.Value,
                .CssClass = css
                }).
                OrderByDescending(Function(x) x.Count).
                ThenBy(Function(x) x.Title).
                ToList()

        pnlNoViolationsSummary.Visible = (summary.Count = 0)
        rptViolationsSummary.DataSource = summary
        rptViolationsSummary.DataBind()
    End Sub

    ' ===== Buttons =====
    Protected Sub btnSearchHistory_Click(sender As Object, e As EventArgs)
        BindViolationsHistory()
    End Sub

    Protected Sub btnSearchViolations_Click(sender As Object, e As EventArgs)
        BindEmployeeViolations()
    End Sub


    ' =========================
    ' ✅ Attachments: دعم القديم + دعم مخالفات الموظف
    ' =========================

    Protected Sub rptComplaints_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptComplaints.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments_Old(evalId)
        End If
    End Sub

    Protected Sub rptViolationsHistory_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptViolationsHistory.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments_Old(evalId)
        End If
    End Sub

    Protected Sub rptEmployeeViolations_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptEmployeeViolations.ItemCommand
        If e.CommandName = "ShowVAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments_New(evalId)
        End If
    End Sub

    ' القديم
    Private Sub BindAttachments_Old(evaluationId As Integer)
        Dim atts = (From a In db.Select_Evaluations_Attachments_ByEvaluation_ID(evaluationId)
                Select New With {.Title = a.Title, .FilePath = a.File_Path}).ToList()

        If atts Is Nothing OrElse atts.Count = 0 Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noAttAlert", "alert('لا يوجد مرفقات لهذا التقييم');",
                                                True)
            Return
        End If

        rptAttachmentsCarousel.DataSource = atts
        rptAttachmentsCarousel.DataBind()
        ShowModal("attachmentsModal")
    End Sub

    ' الجديد
    Private Sub BindAttachments_New(evaluationId As Integer)
        Dim atts = (From a In db.Select_EvaluationsEmployees_Attachments_ByEvaluation_ID(evaluationId)
                Select New With {.Title = a.Title, .FilePath = a.File_Path}).ToList()

        If atts Is Nothing OrElse atts.Count = 0 Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noAttAlert2", "alert('لا يوجد مرفقات لهذا التقييم');",
                                                True)
            Return
        End If

        rptAttachmentsCarousel.DataSource = atts
        rptAttachmentsCarousel.DataBind()
        ShowModal("attachmentsModal")
    End Sub

    Private Sub ShowModal(modalId As String)
        Dim script As String =
                "setTimeout(function(){" &
                "var m = new bootstrap.Modal(document.getElementById('" & modalId & "')); m.show();" &
                "}, 100);"
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "show_" & modalId, script, True)
    End Sub

    Protected Sub btnOpenEmployeeEvaluation_Click(sender As Object, e As EventArgs)
        Response.Redirect(
            "/modules/Employees/Employee_Evaluation.aspx?EmployeeID=" & Request.QueryString("EmployeeID").ToString())
    End Sub
End Class


