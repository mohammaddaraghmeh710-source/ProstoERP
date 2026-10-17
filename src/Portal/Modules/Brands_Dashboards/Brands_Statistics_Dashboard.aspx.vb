Imports System.Globalization
Imports System.Web.Script.Serialization
Imports Prosto_ERP_ClassLibrary

Public Class Brands_Statistics_Dashboard
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_DataClassesDataContext()

    Protected BrandID As Integer

    ' عدد السجلات في كل صفحة في سجل المهام
    Private Const HistoryPageSize As Integer = 5

    Private Property HistoryPageIndex As Integer
        Get
            If ViewState("HistoryPageIndex") IsNot Nothing Then
                Return CInt(ViewState("HistoryPageIndex"))
            End If
            Return 0
        End Get
        Set
            ViewState("HistoryPageIndex") = value
        End Set
    End Property

    ' DTO لعرض الفروع في الكروت الصغيرة
    Private Class BranchMiniDto
        Public Property BranchID As Integer
        Public Property Name As String
        Public Property Score As Decimal
        Public Property ScoreStr As String
        Public Property ColorKey As String
    End Class

    ' DTO لعرض توزيع عناصر التقييم حسب التصنيف
    Private Class CategoryResult
        Public Property Name As String
        Public Property Count As Integer
    End Class

    ' DTO لعناصر Checklist في السجل / الشكاوي
    Private Class ViolationDto
        Public Property Title As String
        Public Property CssClass As String
    End Class

    ' DTO لصف واحد في سجل المخالفات / الشكاوي
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
        Public Property BranchName As String
    End Class

    ' كاش لتقييمات العلامة التجارية
    Private _brandEvaluations As List(Of Select_Evaluations_ByBrandIDResult)

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' حماية الجلسة
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadBrandParameter()
        LoadBrandEvaluations()

        If Not IsPostBack Then
            If BrandID <= 0 Then
                Return
            End If

            LoadDashboardData()

            ' تهيئة فلاتر السجل
            BindHistoryFilters()
            ddlStatusFilter.SelectedValue = "open"
            HistoryPageIndex = 0
            BindViolationsHistory()

            ' شكاوي غير منجزة للعلامة التجارية
            BindComplaints()
        End If
    End Sub

    ' قراءة BrandID من الرابط + تخزينه في ViewState
    Private Sub LoadBrandParameter()
        If Not IsPostBack Then
            Integer.TryParse(Request.QueryString("BrandID"), BrandID)
            ViewState("BrandID") = BrandID
        Else
            BrandID = If(ViewState("BrandID") IsNot Nothing, CInt(ViewState("BrandID")), 0)
        End If
    End Sub

    ' تحميل جميع التقييمات الخاصة بهذه العلامة التجارية
    Private Sub LoadBrandEvaluations()
        If BrandID <= 0 Then
            _brandEvaluations = New List(Of Select_Evaluations_ByBrandIDResult)()
            Return
        End If

        _brandEvaluations = db.Select_Evaluations_ByBrandID(BrandID, Nothing).ToList()
    End Sub

    Private Sub LoadDashboardData()
        Dim serializer As New JavaScriptSerializer()

        ' ===================== 1) جلب الفروع =====================
        Dim branches = (From b In db.Select_Branches_ByBrandID(BrandID)
                Where (b.IsDeleted = False OrElse b.IsDeleted Is Nothing) _
                      AndAlso (b.IsActive = True OrElse b.IsActive Is Nothing)
                Select b).ToList()

        If branches Is Nothing OrElse branches.Count = 0 Then
            litBrandScore.Text = "0"
            litBrandScoreText.Text = "تقييم العلامة التجارية: 0%"
            litCategoriesData.Text = "[]"
            rptBranches.DataSource = Nothing
            rptBranches.DataBind()
            litBrandTasksCount.Text = "0"
            litBrandComplaintsCount.Text = "0"
            Return
        End If

        Dim branchIds = branches.Select(Function(b) b.ID).ToList()

        ' ===================== 2) جميع التقييمات للفروع الحالية (من Select_Evaluations_All) =====================
        Dim evaluations = (From ev In db.Select_Evaluations_All()
                Where (ev.IsDeleted = False OrElse ev.IsDeleted Is Nothing) _
                      AndAlso branchIds.Contains(ev.Branch_ID) _
                      AndAlso (ev.Brand_ID = BrandID OrElse Not ev.Brand_ID.HasValue)
                Select ev).ToList()

        ' ===================== 3) حساب تقييم كل فرع =====================
        Dim miniList As New List(Of BranchMiniDto)()
        Dim colorKeys() As String = {"success", "warning", "danger", "primary", "info"}
        Dim colorIndex = 0

        For Each br In branches
            Dim branchId As Integer = br.ID
            Dim branchNameLocal As String = br.Title_Ar

            Dim branchEvals = evaluations.Where(Function(ev) ev.Branch_ID = branchId).ToList()
            Dim score As Decimal = CalculateScore(branchEvals)

            Dim dto As New BranchMiniDto()
            dto.BranchID = branchId
            dto.Name = branchNameLocal
            dto.Score = score
            dto.ScoreStr = score.ToString("0.0", CultureInfo.InvariantCulture)
            dto.ColorKey = colorKeys(colorIndex Mod colorKeys.Length)
            colorIndex += 1

            miniList.Add(dto)
        Next

        ' ترتيب الفروع حسب الأعلى تقييم
        miniList = miniList.OrderByDescending(Function(x) x.Score).ToList()

        ' ربط الريبيتر
        rptBranches.DataSource = miniList
        rptBranches.DataBind()

        ' ===================== 4) تقييم العلامة التجارية =====================
        Dim brandScore = 0D

        If miniList.Count > 0 Then
            Dim sumScores As Decimal = miniList.Sum(Function(x) x.Score)
            Dim avgScore As Decimal = sumScores/miniList.Count
            brandScore = Math.Round(avgScore, 2)
        End If

        litBrandScore.Text = brandScore.ToString(CultureInfo.InvariantCulture)
        litBrandScoreText.Text = String.Format("تقييم العلامة التجارية: {0:0.##}%", brandScore)

        ' ===================== 5) عدد المهام والشكاوي للعلامة التجارية =====================
        Dim brandEvals =
                If(_brandEvaluations, New List(Of Select_Evaluations_ByBrandIDResult)())

        ' Evaluation_Type للمهام = 1
        ' Evaluation_Type للشكاوي = 2
        Dim tasksCount As Integer =
                brandEvals.Where(Function(ev) ev.Evaluation_Type.HasValue AndAlso ev.Evaluation_Type.Value = 1).Count()
        Dim complaintsCount As Integer =
                brandEvals.Where(Function(ev) ev.Evaluation_Type.HasValue AndAlso ev.Evaluation_Type.Value = 2).Count()

        litBrandTasksCount.Text = tasksCount.ToString("N0", CultureInfo.InvariantCulture)
        litBrandComplaintsCount.Text = complaintsCount.ToString("N0", CultureInfo.InvariantCulture)

        ' ===================== 6) عدد عناصر التقييم + توزيعها حسب التصنيف =====================
        Dim categoriesResult As New List(Of CategoryResult)()

        Dim catsData = db.Brand_Evaluation_Checklist_ByCategory().
                Where(Function(r) r.Brand_ID = BrandID).
                ToList()

        For Each row In catsData
            Dim name = "غير مصنف"

            If row.Category_Title_Ar IsNot Nothing AndAlso row.Category_Title_Ar.Trim() <> "" Then
                name = row.Category_Title_Ar
            ElseIf row.Category_Title_En IsNot Nothing AndAlso row.Category_Title_En.Trim() <> "" Then
                name = row.Category_Title_En
            End If

            Dim cnt = 0
            If row.Evaluation_Items_Count.HasValue Then
                cnt = CInt(row.Evaluation_Items_Count.Value)
            End If

            categoriesResult.Add(New CategoryResult With {
                                    .Name = name,
                                    .Count = cnt
                                    })
        Next

        litCategoriesData.Text = serializer.Serialize(categoriesResult)
    End Sub

    ' ===== نفس دالة حساب النسبة المستخدمة في صفحات أخرى =====
    Private Function CalculateScore(evals As IEnumerable(Of Select_Evaluations_AllResult)) As Decimal
        If evals Is Nothing Then
            Return 100D
        End If

        Dim evaluationCount As Integer = evals.Count()
        If evaluationCount = 0 Then
            Return 100D
        End If

        Dim totalWeight As Decimal = evals.Sum(
            Function(ev)
                If ev IsNot Nothing AndAlso ev.Weight.HasValue Then
                    Return CDec(ev.Weight.Value)
                Else
                    Return 0D
                End If
            End Function)

        Dim maxScore As Decimal = evaluationCount*100D
        Dim score As Decimal = ((maxScore - totalWeight)/maxScore)*100D

        If score < 0D Then score = 0D
        If score > 100D Then score = 100D

        Return score
    End Function

    ' ============== تعبئة فلاتر سجل المخالفات للعلامة التجارية ==============
    Private Sub BindHistoryFilters()
        Dim evals = _brandEvaluations.
                Where(Function(ev) ev.Evaluation_Type = 1 AndAlso Not String.IsNullOrWhiteSpace(ev.Checklist_IDs)).
                ToList()

        ddlChecklistCategoryFilter.Items.Clear()
        ddlChecklistFilter.Items.Clear()
        ddlBranchFilter.Items.Clear()
        ddlDepartmentFilter.Items.Clear()
        ddlJobTitleFilter.Items.Clear()

        ddlChecklistCategoryFilter.Items.Add(New ListItem("الكل", ""))
        ddlChecklistFilter.Items.Add(New ListItem("الكل", ""))
        ddlBranchFilter.Items.Add(New ListItem("الكل", ""))
        ddlDepartmentFilter.Items.Add(New ListItem("الكل", ""))
        ddlJobTitleFilter.Items.Add(New ListItem("الكل", ""))

        If evals.Count = 0 Then
            Return
        End If

        ' فروع من نفس التقييمات
        Dim branchIds =
                evals.Where(Function(e) e.Branch_ID.HasValue).Select(Function(e) e.Branch_ID.Value).Distinct().ToList()
        If branchIds.Count > 0 Then
            Dim branches = (From b In db.Select_Branches_All()
                    Where branchIds.Contains(b.ID)
                    Order By b.Title_Ar
                    Select b.ID, b.Title_Ar).ToList()

            For Each b In branches
                ddlBranchFilter.Items.Add(New ListItem(b.Title_Ar, b.ID.ToString()))
            Next
        End If

        ' أقسام
        Dim deptIds =
                evals.Where(Function(e) e.Department_ID.HasValue).Select(Function(e) e.Department_ID.Value).Distinct().
                ToList()
        If deptIds.Count > 0 Then
            Dim depts = (From d In db.Select_Departments_All()
                    Where deptIds.Contains(d.ID)
                    Order By d.Title_Ar
                    Select d.ID, d.Title_Ar).ToList()

            For Each d In depts
                ddlDepartmentFilter.Items.Add(New ListItem(d.Title_Ar, d.ID.ToString()))
            Next
        End If

        ' مسميات وظيفية
        Dim jobIds =
                evals.Where(Function(e) e.JobTitle_ID.HasValue).Select(Function(e) e.JobTitle_ID.Value).Distinct().
                ToList()
        If jobIds.Count > 0 Then
            Dim jobs = (From j In db.Select_JobTitles_All()
                    Where jobIds.Contains(j.ID)
                    Order By j.Title_Ar
                    Select j.ID, j.Title_Ar).ToList()

            For Each j In jobs
                ddlJobTitleFilter.Items.Add(New ListItem(j.Title_Ar, j.ID.ToString()))
            Next
        End If

        ' Checklist
        Dim allChecklistIds As New HashSet(Of Integer)()

        For Each ev In evals
            Dim parts = ev.Checklist_IDs.Split(","c)
            For Each p In parts
                Dim id As Integer
                If Integer.TryParse(p.Trim(), id) Then
                    allChecklistIds.Add(id)
                End If
            Next
        Next

        If allChecklistIds.Count = 0 Then
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

        ' تصنيفات بدون تكرار
        Dim usedCategoryIds As New HashSet(Of Integer)()

        For Each c In allChecklists
            If Not usedCategoryIds.Contains(c.CategoryID) Then
                usedCategoryIds.Add(c.CategoryID)
            End If
        Next

        For Each catId In usedCategoryIds.OrderBy(Function(id) id)
            Dim text As String
            Select Case catId
                Case 1
                    text = "مهام خطيرة"
                Case 2
                    text = "مهام متوسطة"
                Case 3
                    text = "مهام عادية"
                Case Else
                    text = "تصنيف آخر"
            End Select

            ddlChecklistCategoryFilter.Items.Add(
                New ListItem(text, catId.ToString())
                )
        Next

        ' عناصر Checklist نفسها بدون تكرار
        Dim usedChecklistIds As New HashSet(Of Integer)()

        For Each c In allChecklists.OrderBy(Function(x) x.Title_Ar)
            If Not usedChecklistIds.Contains(c.ID) Then
                usedChecklistIds.Add(c.ID)
                ddlChecklistFilter.Items.Add(
                    New ListItem(c.Title_Ar, c.ID.ToString())
                    )
            End If
        Next
    End Sub

    ' ============== سجل المخالفات للعلامة التجارية (مع Paging + بحث عام ومتقدم) ==============
    Private Sub BindViolationsHistory()
        Dim evals = _brandEvaluations.
                Where(Function(ev) ev.Evaluation_Type = 1).
                ToList()

        ' -------- 1) فلتر الحالة (بحث عام) --------
        Dim statusFilter As String = ddlStatusFilter.SelectedValue

        If statusFilter = "open" Then
            evals = evals.Where(Function(ev) ev.IsSolved = False OrElse ev.IsSolved Is Nothing).ToList()
        ElseIf statusFilter = "closed" Then
            evals = evals.Where(Function(ev) ev.IsSolved = True).ToList()
        End If

        ' -------- 2) فلتر التاريخ (بحث عام) --------
        Dim fromDate As DateTime?
        Dim toDate As DateTime?

        If Not String.IsNullOrWhiteSpace(txtFromDate.Text) Then
            Dim dt As DateTime
            If DateTime.TryParseExact(txtFromDate.Text.Trim(),
                                      {"dd/MM/yyyy", "yyyy-MM-dd"},
                                      CultureInfo.InvariantCulture,
                                      DateTimeStyles.None,
                                      dt) Then
                fromDate = dt.Date
            End If
        End If

        If Not String.IsNullOrWhiteSpace(txtToDate.Text) Then
            Dim dt As DateTime
            If DateTime.TryParseExact(txtToDate.Text.Trim(),
                                      {"dd/MM/yyyy", "yyyy-MM-dd"},
                                      CultureInfo.InvariantCulture,
                                      DateTimeStyles.None,
                                      dt) Then
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

        ' -------- 3) بحث متقدم (فرع/قسم/مسمى/Checklist) --------
        Dim useAdvanced = False

        Dim selectedBranchId As Integer? = Nothing
        Dim selectedDeptId As Integer? = Nothing
        Dim selectedJobId As Integer? = Nothing
        Dim selectedCatId As Integer? = Nothing
        Dim selectedChecklistId As Integer? = Nothing

        If useAdvanced Then
            If Not String.IsNullOrEmpty(ddlBranchFilter.SelectedValue) Then
                Dim bid As Integer
                If Integer.TryParse(ddlBranchFilter.SelectedValue, bid) Then
                    selectedBranchId = bid
                End If
            End If

            If Not String.IsNullOrEmpty(ddlDepartmentFilter.SelectedValue) Then
                Dim did As Integer
                If Integer.TryParse(ddlDepartmentFilter.SelectedValue, did) Then
                    selectedDeptId = did
                End If
            End If

            If Not String.IsNullOrEmpty(ddlJobTitleFilter.SelectedValue) Then
                Dim jid As Integer
                If Integer.TryParse(ddlJobTitleFilter.SelectedValue, jid) Then
                    selectedJobId = jid
                End If
            End If

            If Not String.IsNullOrEmpty(ddlChecklistCategoryFilter.SelectedValue) Then
                Dim cid As Integer
                If Integer.TryParse(ddlChecklistCategoryFilter.SelectedValue, cid) Then
                    selectedCatId = cid
                End If
            End If

            If Not String.IsNullOrEmpty(ddlChecklistFilter.SelectedValue) Then
                Dim cid As Integer
                If Integer.TryParse(ddlChecklistFilter.SelectedValue, cid) Then
                    selectedChecklistId = cid
                End If
            End If
        End If

        ' -------- 4) قواميس الأقسام / المسميات / الشفت / البراند / الفروع --------
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
        Dim branchIds =
                evals.Where(Function(e) e.Branch_ID.HasValue).Select(Function(e) e.Branch_ID.Value).Distinct().ToList()

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

        Dim branchesDict = (From b In db.Select_Branches_All()
                Where branchIds.Contains(b.ID)
                Select b.ID, b.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

        Dim brandLogoDefault = "/assets/img/Prosto/Logo_Circle.png"

        Dim brandLogoDict As New Dictionary(Of Integer, String)
        For Each b In brandsDict
            Dim logo As String = b.Logo
            If String.IsNullOrEmpty(logo) Then
                logo = brandLogoDefault
            End If
            brandLogoDict(b.ID) = logo
        Next

        ' -------- 5) Checklist + التصنيفات --------
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
                .CategoryID = c.CheckList_CategoryID,
                .CategoryTitle = cat.Title_Ar
                }).ToList()

        Dim checklistDict = allChecklists.ToDictionary(Function(x) x.ID)

        Dim result As New List(Of EvaluationTaskDto)()

        ' -------- 6) بناء النتيجة مع تطبيق البحث المتقدم --------
        For Each ev In evals
            ' فلترة الفرع / القسم / المسمى (بحث متقدم)
            If useAdvanced Then
                If selectedBranchId.HasValue Then
                    If Not ev.Branch_ID.HasValue OrElse ev.Branch_ID.Value <> selectedBranchId.Value Then
                        Continue For
                    End If
                End If

                If selectedDeptId.HasValue Then
                    If Not ev.Department_ID.HasValue OrElse ev.Department_ID.Value <> selectedDeptId.Value Then
                        Continue For
                    End If
                End If

                If selectedJobId.HasValue Then
                    If Not ev.JobTitle_ID.HasValue OrElse ev.JobTitle_ID.Value <> selectedJobId.Value Then
                        Continue For
                    End If
                End If
            End If

            Dim deptName = ""
            Dim jobName = ""
            Dim shiftName = ""
            Dim brandLogo As String = brandLogoDefault
            Dim branchName = ""

            If ev.Department_ID.HasValue AndAlso deptDict.ContainsKey(ev.Department_ID.Value) Then
                deptName = deptDict(ev.Department_ID.Value)
            End If

            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then
                jobName = jobDict(ev.JobTitle_ID.Value)
            End If

            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then
                shiftName = shiftsDict(ev.Shift_ID.Value)
            End If

            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then
                brandLogo = brandLogoDict(ev.Brand_ID.Value)
            End If

            If ev.Branch_ID.HasValue AndAlso branchesDict.ContainsKey(ev.Branch_ID.Value) Then
                branchName = branchesDict(ev.Branch_ID.Value)
            End If

            Dim viols As New List(Of ViolationDto)()
            Dim hasMatchedChecklist = False
            Dim hasMatchedCategory = False

            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)

                        ' مطابقة التصنيف (بحث متقدم)
                        If useAdvanced AndAlso selectedCatId.HasValue Then
                            If c.CategoryID = selectedCatId.Value Then
                                hasMatchedCategory = True
                            End If
                        Else
                            hasMatchedCategory = True
                        End If

                        ' مطابقة العنصر نفسه (بحث متقدم)
                        If useAdvanced AndAlso selectedChecklistId.HasValue Then
                            If id = selectedChecklistId.Value Then
                                hasMatchedChecklist = True
                            End If
                        Else
                            hasMatchedChecklist = True
                        End If

                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CategoryID
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

            Dim passFilter = True

            If useAdvanced AndAlso selectedCatId.HasValue AndAlso Not hasMatchedCategory Then
                passFilter = False
            End If

            If useAdvanced AndAlso selectedChecklistId.HasValue AndAlso Not hasMatchedChecklist Then
                passFilter = False
            End If

            If Not passFilter Then
                Continue For
            End If

            Dim isClosed As Boolean = ev.IsSolved.HasValue AndAlso ev.IsSolved.Value
            Dim statusText As String = If(isClosed, "منجزة", "غير منجزة")
            Dim statusCss As String = If(isClosed,
                                         "status-badge status-closed",
                                         "status-badge status-open")

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
                          .StatusCss = statusCss,
                          .BranchName = branchName
                          })
        Next

        result = result.OrderByDescending(Function(x) x.EvalDate).ToList()

        pnlNoViolationsHistory.Visible = (result.Count = 0)

        ' ===== Paging =====
        Dim totalCount As Integer = result.Count
        If totalCount = 0 Then
            rptViolationsHistory.DataSource = Nothing
            rptViolationsHistory.DataBind()

            If pnlHistoryPager IsNot Nothing Then
                pnlHistoryPager.Visible = False
            End If
            Exit Sub
        End If

        Dim totalPages = CInt(Math.Ceiling(totalCount/CDbl(HistoryPageSize)))
        If HistoryPageIndex >= totalPages Then
            HistoryPageIndex = Math.Max(totalPages - 1, 0)
        End If

        Dim pageIndex As Integer = HistoryPageIndex
        Dim paged = result.Skip(pageIndex*HistoryPageSize).Take(HistoryPageSize).ToList()

        rptViolationsHistory.DataSource = paged
        rptViolationsHistory.DataBind()

        If pnlHistoryPager IsNot Nothing Then
            pnlHistoryPager.Visible = True
            btnHistoryPrev.Enabled = (pageIndex > 0)
            btnHistoryNext.Enabled = (pageIndex < totalPages - 1)
            lblHistoryPageInfo.Text = String.Format("الصفحة {0} من {1}", pageIndex + 1, totalPages)
        End If
    End Sub

    ' ============== شكاوي غير منجزة للعلامة التجارية ==============
    Private Sub BindComplaints()
        Dim evals = _brandEvaluations.Where(
            Function(ev) ev.Evaluation_Type = 2 AndAlso (ev.IsSolved = False OrElse ev.IsSolved Is Nothing)
            ).ToList()

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
        Dim branchIds =
                evals.Where(Function(e) e.Branch_ID.HasValue).Select(Function(e) e.Branch_ID.Value).Distinct().ToList()

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

        Dim branchesDict = (From b In db.Select_Branches_All()
                Where branchIds.Contains(b.ID)
                Select b.ID, b.Title_Ar).ToDictionary(Function(x) x.ID, Function(x) x.Title_Ar)

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
            Dim branchName = ""

            If ev.Department_ID.HasValue AndAlso deptDict.ContainsKey(ev.Department_ID.Value) Then
                deptName = deptDict(ev.Department_ID.Value)
            End If

            If ev.JobTitle_ID.HasValue AndAlso jobDict.ContainsKey(ev.JobTitle_ID.Value) Then
                jobName = jobDict(ev.JobTitle_ID.Value)
            End If

            If ev.Shift_ID.HasValue AndAlso shiftsDict.ContainsKey(ev.Shift_ID.Value) Then
                shiftName = shiftsDict(ev.Shift_ID.Value)
            End If

            If ev.Brand_ID.HasValue AndAlso brandLogoDict.ContainsKey(ev.Brand_ID.Value) Then
                brandLogo = brandLogoDict(ev.Brand_ID.Value)
            End If

            If ev.Branch_ID.HasValue AndAlso branchesDict.ContainsKey(ev.Branch_ID.Value) Then
                branchName = branchesDict(ev.Branch_ID.Value)
            End If

            Dim viols As New List(Of ViolationDto)()

            If ev.Checklist_IDs IsNot Nothing Then
                Dim parts = ev.Checklist_IDs.Split(","c)
                For Each p In parts
                    Dim id As Integer
                    If Integer.TryParse(p.Trim(), id) AndAlso checklistDict.ContainsKey(id) Then
                        Dim c = checklistDict(id)
                        Dim css = "badge-chip badge-primary-soft"
                        Select Case c.CategoryID
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
                              .DepartmentName = deptName,
                              .JobTitleName = jobName,
                              .ShiftName = shiftName,
                              .BrandLogoUrl = brandLogo,
                              .EvalDate = ev.AddedDate,
                              .Notes = ev.Notes,
                              .Violations = viols,
                              .BranchName = branchName
                              })
        Next

        pnlNoComplaints.Visible = (complaints.Count = 0)
        litComplaintsBadge.Text = complaints.Count.ToString()
        rptComplaints.DataSource = complaints.OrderByDescending(Function(c) c.EvalDate).ToList()
        rptComplaints.DataBind()
    End Sub

    ' ============== Attachments ==============
    Protected Sub rptComplaints_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptComplaints.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        End If
    End Sub

    Protected Sub rptViolationsHistory_ItemCommand(source As Object, e As RepeaterCommandEventArgs) _
        Handles rptViolationsHistory.ItemCommand
        If e.CommandName = "ShowAttachments" Then
            Dim evalId As Integer = Convert.ToInt32(e.CommandArgument)
            BindAttachments(evalId)
        End If
    End Sub

    Private Sub BindAttachments(evaluationId As Integer)
        Dim atts = (From a In db.Select_Evaluations_Attachments_ByEvaluation_ID(evaluationId)
                Select New With {
                .Title = a.Title,
                .FilePath = a.File_Path
                }).ToList()

        If atts Is Nothing OrElse atts.Count = 0 Then
            Dim scriptNoAtt =
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

    ' ============== زر البحث في سجل المخالفات (Async داخل UpdatePanel) ==============
    Protected Sub btnSearchHistory_Click(sender As Object, e As EventArgs)
        HistoryPageIndex = 0
        BindViolationsHistory()
    End Sub

    ' ============== أزرار Paging لسجل المهام ==============
    Protected Sub HistoryPager_Click(sender As Object, e As EventArgs)
        Dim btn = TryCast(sender, LinkButton)
        If btn Is Nothing Then Return

        Dim direction As Integer
        If Integer.TryParse(btn.CommandArgument, direction) Then
            Dim newIndex = HistoryPageIndex + direction
            If newIndex < 0 Then newIndex = 0
            HistoryPageIndex = newIndex
        End If

        BindViolationsHistory()
    End Sub
End Class


