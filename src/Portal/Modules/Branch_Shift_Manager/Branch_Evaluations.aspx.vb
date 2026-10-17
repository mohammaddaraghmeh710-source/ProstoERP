Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Text
Imports System.Web.Security

Public Class Branch_Evaluations
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected DepartmentID As Integer
    Protected BranchID As Integer
    Protected ShiftID As Integer?

    ' كاش للتقييمات
    Private _deptEvaluations As List(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByBranchIDResult)

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

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()
        LoadDepartmentAndBranch()
        LoadDeptEvaluations()

        If Not IsPostBack Then
            BindGaugeAndSummary()
            BindViolations()
        End If
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

    Private Sub LoadDepartmentAndBranch()


        ' جلب الفرع/العلامة للعرض فقط
        If BranchID > 0 Then
            Dim br = db.Select_Branches_ByID(BranchID).FirstOrDefault()
            If br IsNot Nothing Then
                litBranchHeader.Text = br.Title_Ar
            Else
                litBranchHeader.Text = "-"
            End If
        Else
            litBranchHeader.Text = "-"
        End If
    End Sub

    Private Sub LoadDeptEvaluations()
        _deptEvaluations = New List(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByBranchIDResult)()

        If BranchID <= 0 Then Return

        ' جلب تقييمات الفرع (حسب الوردية إن وجدت) ثم فلترة بالقسم
        Dim branchEvals As List(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByBranchIDResult)

        If ShiftID.HasValue Then
            branchEvals = db.Select_Evaluations_ByBranchID(BranchID, ShiftID.Value).ToList()
        Else
            branchEvals = db.Select_Evaluations_ByBranchID(BranchID, Nothing).ToList()
        End If

        _deptEvaluations = branchEvals.
            Where(Function(ev) ev.Department_ID.HasValue AndAlso ev.Department_ID.Value = DepartmentID).
            ToList()
    End Sub

    ' ======== حساب السكور (نفس منطق صفحة الفرع) ========
    Private Function CalculateScore(evals As IEnumerable(Of Prosto_ERP_ClassLibrary.Select_Evaluations_ByBranchIDResult)) As Decimal
        If evals Is Nothing Then Return 100D

        Dim evaluationCount As Integer = evals.Count()
        If evaluationCount = 0 Then Return 100D

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

    Private Sub BindGaugeAndSummary()
        ' السكور مبني على (مخالفات + شكاوي) إن وجدت
        Dim evalsAll = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 OrElse ev.Evaluation_Type = 2
        ).ToList()

        Dim score As Decimal = CalculateScore(evalsAll)
        litDeptScore.Text = score.ToString("0.0", CultureInfo.InvariantCulture) & "%"

        divDeptGauge.Attributes("data-value") = score.ToString("0.##", CultureInfo.InvariantCulture)
        divDeptGauge.Attributes("class") = GetGaugeCss(score)

        Dim violations = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        Dim complaints = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
        ).ToList()

        litViolationsCount.Text = violations.Count.ToString()
        litComplaintsCount.Text = complaints.Count.ToString()
        litViolationsHeaderCount.Text = violations.Count.ToString()
        litTotalEvals.Text = _deptEvaluations.Count.ToString()

        pnlNoViolations.Visible = (violations.Count = 0)
    End Sub

    Private Sub BindViolations()
        Dim evals = _deptEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 1
        ).ToList()

        If evals Is Nothing OrElse evals.Count = 0 Then
            rptViolations.DataSource = Nothing
            rptViolations.DataBind()
            pnlNoViolations.Visible = True
            Return
        End If

        pnlNoViolations.Visible = False

        Dim jobIds = evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().ToList()
        Dim shiftIds = evals.Where(Function(e) e.Shift_ID.HasValue).Select(Function(e) e.Shift_ID.Value).Distinct().ToList()
        Dim brandIds = evals.Where(Function(e) e.Brand_ID.HasValue).Select(Function(e) e.Brand_ID.Value).Distinct().ToList()

        Dim jobDict = (From j In db.Select_JobTitles_All()
                       Where jobIds.Contains(j.ID)
                       Select j.ID, j.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim shiftsDict = (From s In db.Select_Shift_All()
                          Where shiftIds.Contains(s.ID)
                          Select s.ID, s.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brands = (From b In db.Select_Brands_All()
                      Where brandIds.Contains(b.ID)
                      Select b.ID, b.Logo).ToList()

        Dim brandLogoDefault As String = "/assets/img/Prosto/Logo_Circle.png"
        Dim brandLogoDict As New Dictionary(Of Integer, String)
        For Each b In brands
            Dim logo As String = b.Logo
            If String.IsNullOrEmpty(logo) Then logo = brandLogoDefault
            brandLogoDict(b.ID) = logo
        Next

        ' تجميع كل Checklist IDs لاستخراج العناوين
        Dim allChecklistIds As New HashSet(Of Integer)()
        For Each ev In evals
            If ev.Checklist_IDs IsNot Nothing Then
                For Each p In ev.Checklist_IDs.Split(","c)
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
                                 .CheckList_CategoryID = c.CheckList_CategoryID
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
                For Each p In ev.Checklist_IDs.Split(","c)
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)

                        Dim css As String = "badge-chip badge-primary-soft"
                        Select Case c.CheckList_CategoryID
                            Case 1 : css = "badge-chip badge-danger-soft"
                            Case 2 : css = "badge-chip badge-warning-soft"
                            Case 3 : css = "badge-chip badge-primary-soft"
                            Case Else : css = "badge-chip badge-info-soft"
                        End Select

                        viols.Add(New ViolationDto With {.Title = c.Title_Ar, .CssClass = css})
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

        rptViolations.DataSource = tasks.OrderByDescending(Function(x) x.EvalDate).ToList()
        rptViolations.DataBind()
    End Sub

    ' ===== Attachments =====
    Protected Sub rptViolations_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        End If
    End Sub

    Private Sub BindAttachments(evaluationId As Integer)
        Dim atts = (From a In db.Select_Evaluations_Attachments_ByEvaluation_ID(evaluationId)
                    Select New With {.Title = a.Title, .FilePath = a.File_Path}).ToList()

        If atts Is Nothing OrElse atts.Count = 0 Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noAttAlert", "alert('لا يوجد مرفقات لهذا التقييم');", True)
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

End Class
