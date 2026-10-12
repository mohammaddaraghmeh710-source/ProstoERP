Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Text
Imports System.Web.Security

Public Class Department_Dashboard
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected DepartmentID As Integer
    Protected ShiftID As Integer?

    Protected BranchID As Integer
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

    Private Class JobTitleEvalDto
        Public Property JobTitleID As Integer
        Public Property JobTitleName As String
        Public Property Score As Decimal
        Public Property EmployeesCount As Integer
    End Class

    Private Class DeptUserDto
        Public Property ID As Integer
        Public Property FullName_Ar As String
        Public Property Employee_Number As String
        Public Property User_Image As String
        Public Property Gender As Integer?
        Public Property Department_ID As Integer?
        Public Property JobTitle_ID As Integer?
        Public Property Shif_ID As Integer?
        Public Property Status As Integer?
        Public Property IsActive As Boolean?
    End Class

    ' الكاش
    Private _deptEvaluations As List(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByDepartmentIDResult)
    Private _deptUsers As List(Of DeptUserDto)

    ' ========== Page_Load ==========
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()
        LoadMasterData()
        LoadDeptEvaluations()

        If Not IsPostBack Then
            BindDeptGaugeAndSummary()
            BindJobTitles()
            BindViolations()
            BindComplaints()
        End If
    End Sub

    Private Sub LoadParameters()
        Integer.TryParse(Request.QueryString("DepartmentID"), DepartmentID)

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
        ' القسم
        Dim dept = db.Select_Departments_ByID(DepartmentID).FirstOrDefault()
        If dept Is Nothing Then Return

        lblDeptName.Text = dept.Title_Ar

        ' الفرع + البراند
        BranchID = If(dept.BranchID.HasValue, dept.BranchID.Value, 0)

        Dim br = db.Select_Branches_ByID(BranchID).FirstOrDefault()
        If br IsNot Nothing Then
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
        End If

        ' المستخدمين في الفرع (للاستخدام في عدّ الموظفين لكل مسمى)
        _deptUsers =
            (From u In db.Select_UsersMembers_ByBranchID(BranchID)
             Where (u.IsDeleted = False OrElse u.IsDeleted Is Nothing) _
               AndAlso u.Type = 4
             Select New DeptUserDto With {
                 .ID = u.ID,
                 .FullName_Ar = u.FullName_Ar,
                 .Employee_Number = u.Employee_Number,
                 .User_Image = u.User_Image,
                 .Gender = u.Gender,
                 .Department_ID = u.Department_ID,
                 .JobTitle_ID = u.JobTitle_ID,
                 .Shif_ID = u.Shif_ID,
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

        ' ====== سياسات القسم ======
        If Not String.IsNullOrWhiteSpace(dept.Policies_Ar) Then
            'Dim encoded As String = Server.HtmlEncode(dept.Policies_Ar)
            'encoded = encoded.Replace(Environment.NewLine, "<br />")
            litDeptPolicies.Text = dept.Policies_Ar
        Else
            litDeptPolicies.Text = "<p class='mb-0 text-muted'>لم يتم تعريف سياسات لهذا القسم بعد.</p>"
        End If

        ' ====== روابط الفيديو (طريقة العمل / طريقة التقييم) ======
        If Not String.IsNullOrWhiteSpace(dept.Working_Method_Video_Ar) Then
            hidWorkingMethodUrl.Value = BuildSecureVideoUrl(dept.Working_Method_Video_Ar)
        Else
            hidWorkingMethodUrl.Value = String.Empty
        End If

        If Not String.IsNullOrWhiteSpace(dept.Evaluation_Method_Video_Ar) Then
            hidEvaluationMethodUrl.Value = BuildSecureVideoUrl(dept.Evaluation_Method_Video_Ar)
        Else
            hidEvaluationMethodUrl.Value = String.Empty
        End If
    End Sub

    ' ========== LoadDeptEvaluations ==========
    Private Sub LoadDeptEvaluations()
        If ShiftID.HasValue Then
            _deptEvaluations = db.Select_Evaluations_ByDepartmentID(DepartmentID, ShiftID.Value).ToList()
        Else
            _deptEvaluations = db.Select_Evaluations_ByDepartmentID(DepartmentID, Nothing).ToList()
        End If

        ' آخر تقييم
        If _deptEvaluations IsNot Nothing AndAlso _deptEvaluations.Count > 0 Then
            Dim lastEval = _deptEvaluations.OrderByDescending(Function(e) e.AddedDate).FirstOrDefault()
            If lastEval IsNot Nothing AndAlso lastEval.AddedDate.HasValue Then
                litLastEvalDate.Text = lastEval.AddedDate.Value.ToString("dd/MM/yyyy HH:mm")
            End If
        Else
            litLastEvalDate.Text = "-"
        End If
    End Sub

    ' ======== حساب السكور ========
    Private Function CalculateScore(evals As IEnumerable(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByDepartmentIDResult)) As Decimal
        If evals Is Nothing Then
            Return 100D
        End If

        Dim evaluationCount As Integer = evals.Count()
        If evaluationCount = 0 Then
            Return 100D
        End If

        Dim totalWeight As Decimal =
            evals.Sum(Function(ev) If(ev IsNot Nothing AndAlso ev.Weight.HasValue, CDec(ev.Weight.Value), 0D))

        Dim maxScore As Decimal = evaluationCount * 100D
        Dim score As Decimal = ((maxScore - totalWeight) / maxScore) * 100D

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
    Private Sub BindDeptGaugeAndSummary()
        ' السكور يعتمد على كل التقييمات (نوع 1 و 2) بغض النظر عن IsSolved
        Dim evalsAll = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 OrElse ev.Evaluation_Type = 2
        ).ToList()

        Dim score As Decimal = CalculateScore(evalsAll)
        litDeptScore.Text = score.ToString("0.0", CultureInfo.InvariantCulture) & "%"
        divDeptGauge.Attributes("data-value") = score.ToString("0.##", CultureInfo.InvariantCulture)
        divDeptGauge.Attributes("class") = GetGaugeCss(score)

        ' عدد المخالفات / الشكاوي غير المنجزة فقط
        Dim violations = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        Dim complaints = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        litViolationsCount.Text = violations.Count.ToString()
        litComplaintsCount.Text = complaints.Count.ToString()
        litViolationsHeaderCount.Text = violations.Count.ToString()
        litComplaintsHeaderCount.Text = complaints.Count.ToString()
        litTotalEvals.Text = _deptEvaluations.Count.ToString()

        pnlNoViolations.Visible = (violations.Count = 0)
        pnlNoComplaints.Visible = (complaints.Count = 0)
    End Sub

    ' ========== Job Titles Evaluation ==========
    Private Sub BindJobTitles()
        Dim jobTitles = db.Select_JobTitles_ByDepartmentID(DepartmentID).ToList()

        If jobTitles Is Nothing OrElse jobTitles.Count = 0 Then
            rptJobTitles.DataSource = Nothing
            rptJobTitles.DataBind()
            pnlNoJobTitles.Visible = True
            Return
        End If

        pnlNoJobTitles.Visible = False

        Dim list As New List(Of JobTitleEvalDto)()

        For Each j In jobTitles
            Dim jtId As Integer = j.ID

            ' تقييم المسمى بناءً على كل التقييمات (1 و 2) بغض النظر عن IsSolved
            Dim jtEvals = _deptEvaluations.Where(
                Function(ev) ev.JobTitle_ID.HasValue AndAlso ev.JobTitle_ID.Value = jtId _
                        AndAlso (ev.Evaluation_Type = 1 OrElse ev.Evaluation_Type = 2)
            ).ToList()

            Dim score As Decimal = CalculateScore(jtEvals)

            Dim empCount As Integer = 0
            If _deptUsers IsNot Nothing Then
                empCount = _deptUsers.Where(
                    Function(u) u.Department_ID = DepartmentID _
                            AndAlso u.JobTitle_ID.HasValue _
                            AndAlso u.JobTitle_ID.Value = jtId _
                            AndAlso (u.IsActive = True OrElse u.IsActive Is Nothing)
                ).Count()
            End If

            list.Add(New JobTitleEvalDto With {
                .JobTitleID = jtId,
                .JobTitleName = j.Title_Ar,
                .Score = score,
                .EmployeesCount = empCount
            })
        Next

        rptJobTitles.DataSource = list
        rptJobTitles.DataBind()
    End Sub

    ' ========== Bind Violations ==========
    Private Sub BindViolations()
        Dim evals = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        Dim jobIds = evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().ToList()
        Dim shiftIds = evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds = evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim jobDict = (From j In db.Select_JobTitles_All()
                       Where jobIds.Contains(j.ID)
                       Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From s In db.Select_Shift_All()
                          Where shiftIds.Contains(s.ID)
                          Select s.ID, s.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brandsDict = (From b In db.Select_Brands_All()
                          Where brandIds.Contains(b.ID)
                          Select b.ID, b.Title_Ar, b.Logo).ToList()

        Dim brandLogoDefault As String = "/assets/img/Prosto/Logo_Circle.png"
        Dim brandLogoDict As New Dictionary(Of Integer, String)
        For Each b In brandsDict
            Dim logo As String = b.Logo
            If String.IsNullOrEmpty(logo) Then
                logo = brandLogoDefault
            End If
            brandLogoDict(b.ID) = logo
        Next

        ' Checklist
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
            Dim jobName As String = ""
            Dim shiftName As String = ""
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
                        Dim css As String = "badge-chip badge-primary-soft"
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
        Dim evals = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        Dim jobIds = evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().ToList()
        Dim shiftIds = evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds = evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim jobDict = (From j In db.Select_JobTitles_All()
                       Where jobIds.Contains(j.ID)
                       Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From s In db.Select_Shift_All()
                          Where shiftIds.Contains(s.ID)
                          Select s.ID, s.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brandsDict = (From b In db.Select_Brands_All()
                          Where brandIds.Contains(b.ID)
                          Select b.ID, b.Title_Ar, b.Logo).ToList()

        Dim brandLogoDefault As String = "/assets/img/Prosto/Logo_Circle.png"
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
            Dim jobName As String = ""
            Dim shiftName As String = ""
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
                        Dim css As String = "badge-chip badge-primary-soft"
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
        Dim ids = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).Select(Function(ev) ev.ID).ToList()

        For Each EvaluationID In ids
            CloseEvaluation(EvaluationID)
        Next

        LoadDeptEvaluations()
        BindDeptGaugeAndSummary()
        BindJobTitles()
        BindViolations()
        BindComplaints()
    End Sub

    ' ========== Close ALL Complaints ==========
    Protected Sub btnCloseAllComplaints_Click(sender As Object, e As EventArgs) Handles btnCloseAllComplaints.Click
        Dim ids = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).Select(Function(ev) ev.ID).ToList()

        For Each ComplaintID In ids
            CloseEvaluation(ComplaintID)
        Next

        LoadDeptEvaluations()
        BindDeptGaugeAndSummary()
        BindJobTitles()
        BindViolations()
        BindComplaints()
    End Sub

    ' ========== Attachments & Close One ==========
    Protected Sub rptViolations_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptViolations.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        ElseIf e.CommandName = "CloseOneViolation" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            CloseEvaluation(evalId)
        End If
    End Sub

    Protected Sub rptComplaints_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptComplaints.ItemCommand
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
            Dim scriptNoAtt As String =
                "alert('لا يوجد مرفقات لهذا التقييم');"
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

    ' ========== Secure Video Token (جديد، مستقل عن Test_Page) ==========

    Private Function BuildSecureVideoUrl(relativePath As String) As String
        If String.IsNullOrWhiteSpace(relativePath) Then
            Return String.Empty
        End If

        ' تأكد أن المسار يبدأ بـ ~ أو /
        Dim normPath As String = relativePath.Trim()
        If Not normPath.StartsWith("~") AndAlso Not normPath.StartsWith("/") Then
            normPath = "~" & normPath
        End If

        Dim token As String = GenerateVideoToken(normPath, 60) ' صلاحية 60 دقيقة
        Return ResolveUrl("~/DeptVideoHandler.ashx?t=" & token)
    End Function

    Private Function GenerateVideoToken(virtualPath As String, expiryMinutes As Integer) As String
        Dim expires As Long = DateTime.UtcNow.AddMinutes(expiryMinutes).Ticks
        Dim payload As String = virtualPath & "|" & expires.ToString()

        Dim bytes As Byte() = Encoding.UTF8.GetBytes(payload)
        Dim protectedBytes As Byte() = MachineKey.Protect(bytes, "DeptVideoToken")

        Return HttpServerUtility.UrlTokenEncode(protectedBytes)
    End Function

End Class
