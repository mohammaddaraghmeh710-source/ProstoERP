Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Web.UI

Public Class Branches_Dashboards
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected BrandID As Integer

    ' DTO الخاص بالكرت
    Private Class BranchCardDto
        Public Property BranchID As Integer
        Public Property BranchName As String
        Public Property BrandLogo As String
        Public Property Score As Decimal
        Public Property Stars As Integer
        Public Property EmployeesCount As Integer
        Public Property UnfinishedTasksCount As Integer
        Public Property ComplaintsCount As Integer
        Public Property DetailsUrl As String
    End Class

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' حماية الجلسة
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadBrandParameter()

        If Not IsPostBack Then
            BindBranchesDashboard()
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

    ' ربط بيانات الفروع
    Private Sub BindBranchesDashboard()
        If BrandID <= 0 Then
            phNoBranches.Visible = True
            rptBranches.DataSource = Nothing
            rptBranches.DataBind()
            Return
        End If

        ' 1) جلب معلومات البراند
        Dim brandRow = db.Select_Brands_ByID(BrandID).FirstOrDefault()
        Dim brandName As String = If(brandRow IsNot Nothing, brandRow.Title_Ar, String.Empty)
        Dim brandLogo As String = If(brandRow IsNot Nothing AndAlso Not String.IsNullOrEmpty(brandRow.Logo),
                                     brandRow.Logo,
                                     "/assets/img/Prosto/Logo_Circle.png")

        litBrandName.Text = brandName

        ' 2) جلب الفروع التابعة للبراند
        Dim branches = (From b In db.Select_Branches_ByBrandID(BrandID)
                        Where (b.IsDeleted = False OrElse b.IsDeleted Is Nothing) _
                           AndAlso (b.IsActive = True OrElse b.IsActive Is Nothing)
                        Select b).ToList()

        If branches Is Nothing OrElse branches.Count = 0 Then
            phNoBranches.Visible = True
            rptBranches.DataSource = Nothing
            rptBranches.DataBind()
            Return
        End If

        phNoBranches.Visible = False

        Dim branchIds = branches.Select(Function(b) b.ID).ToList()

        ' 3) جلب كل التقييمات للفروع المحددة والبراند الحالي (غير المحلولة)
        Dim evaluations = (From ev In db.Select_Evaluations_All()
                           Where (ev.IsDeleted = False OrElse ev.IsDeleted Is Nothing) _
                              AndAlso branchIds.Contains(ev.Branch_ID) _
                              AndAlso (ev.Brand_ID = BrandID OrElse Not ev.Brand_ID.HasValue)
                           Select ev).ToList()

        ' 4) معرفة الوردية الحالية (نفس منطق صفحة تقييم الفرع)
        Dim currentShiftId As Integer = GetCurrentShiftId()

        ' 5) تجهيز الكروت
        Dim cards As New List(Of BranchCardDto)()

        For Each br In branches
            Dim branchId As Integer = br.ID
            Dim branchNameLocal As String = br.Title_Ar

            ' التقييمات الخاصة بهذا الفرع
            Dim branchEvals = evaluations.Where(Function(ev) ev.Branch_ID = branchId).ToList()

            ' نسبة التقييم
            Dim score As Decimal = CalculateScore(branchEvals)

            ' تحويل النسبة إلى عدد نجوم (0..5)
            Dim stars As Integer = ScoreToStars(score)

            ' عدد المهام غير المنجزة (Evaluation_Type = 1)
            Dim unfinishedTasksCount As Integer =
                branchEvals.Where(Function(ev) ev.Evaluation_Type = 1).Count()

            ' عدد الشكاوي غير المنجزة (Evaluation_Type = 2)
            Dim complaintsCount As Integer =
                branchEvals.Where(Function(ev) ev.Evaluation_Type = 2).Count()

            ' عدد الموظفين في الفرع (Type = 4)
            Dim employeesCount As Integer =
                (From u In db.Select_UsersMembers_ByBranchID(branchId)
                 Where (u.IsDeleted = False OrElse u.IsDeleted Is Nothing) _
                    AndAlso u.Type = 4
                 Select u).Count()

            ' رابط صفحة تفاصيل الفرع (يتم تمرير الوردية الحالية)
            Dim detailsUrl As String =
                String.Format("/Modules/Branch_Shift_Manager/Branch_Shift_Manager_Dashboard.aspx?BranchID={0}&ShiftID={1}",
                              branchId,
                              currentShiftId)

            cards.Add(New BranchCardDto With {
                .BranchID = branchId,
                .BranchName = branchNameLocal,
                .BrandLogo = brandLogo,
                .Score = score,
                .Stars = stars,
                .EmployeesCount = employeesCount,
                .UnfinishedTasksCount = unfinishedTasksCount,
                .ComplaintsCount = complaintsCount,
                .DetailsUrl = detailsUrl
            })
        Next

        ' 6) ربط الريبيتر
        rptBranches.DataSource = cards
        rptBranches.DataBind()
    End Sub

    ' ===== نفس دالة حساب النسبة المستخدمة في صفحة تقييم الفرع =====
    Private Function CalculateScore(evals As IEnumerable(Of Prosto_ERP_ClassLibrary.Select_Evaluations_AllResult)) As Decimal
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

        Dim maxScore As Decimal = evaluationCount * 100D
        Dim score As Decimal = ((maxScore - totalWeight) / maxScore) * 100D

        If score < 0D Then score = 0D
        If score > 100D Then score = 100D

        Return score
    End Function

    ' تحويل النسبة إلى عدد نجوم (0..5)
    Private Function ScoreToStars(score As Decimal) As Integer
        If score >= 90D Then
            Return 5
        ElseIf score >= 75D Then
            Return 4
        ElseIf score >= 60D Then
            Return 3
        ElseIf score >= 40D Then
            Return 2
        ElseIf score > 0D Then
            Return 1
        Else
            Return 0
        End If
    End Function

    ' تستخدم في الـ ItemTemplate لإختيار كلاس الأيقونة لكل نجمة
    Protected Function GetStarClass(starsObj As Object, starIndex As Integer) As String
        Dim stars As Integer = 0
        If starsObj IsNot Nothing Then
            Integer.TryParse(starsObj.ToString(), stars)
        End If

        If starIndex <= stars Then
            ' نجمة ممتلئة
            Return "bx bxs-star text-warning"
        Else
            ' نجمة فارغة
            Return "bx bx-star text-muted"
        End If
    End Function

    ' نفس منطق GetCurrentShiftId من صفحة تقييم الفرع
    Private Function GetCurrentShiftId() As Integer
        Dim nowTime As TimeSpan = DateTime.Now.TimeOfDay

        Dim shifts = (From s In db.Select_Shift_All()
                      Where (s.IsDeleted = False OrElse s.IsDeleted Is Nothing) _
                        AndAlso (s.IsActive = True OrElse s.IsActive Is Nothing)
                      Select s).ToList()

        For Each s In shifts
            If Not s.Start_Time.HasValue OrElse Not s.End_Time.HasValue Then
                Continue For
            End If

            Dim startT As TimeSpan = s.Start_Time.Value
            Dim endT As TimeSpan = s.End_Time.Value

            Dim isMatch As Boolean

            If startT <= endT Then
                ' وردية عادية داخل نفس اليوم
                isMatch = (nowTime >= startT AndAlso nowTime <= endT)
            Else
                ' وردية تمتد بعد منتصف الليل
                isMatch = (nowTime >= startT OrElse nowTime <= endT)
            End If

            If isMatch Then
                Return s.ID
            End If
        Next

        Return 0
    End Function

End Class
