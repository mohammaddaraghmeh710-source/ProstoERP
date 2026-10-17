Imports Prosto_ERP_ClassLibrary

Public Class LMS_TR_Level_Types
    Inherits PageBase

    Private Class LevelTypeCardVM
        Public Property LevelTypeID As Integer
        Public Property TitleAr As String
        Public Property NotesAr As String
        Public Property ImageUrl As String

        Public Property LevelsCount As Integer
        Public Property VideosCount As Integer
        Public Property TotalDurationSeconds As Integer
        Public Property TotalDurationHHMMSS As String

        Public Property CompletionPercentAvg As Integer
        Public Property HasLevels As Boolean
        Public Property FirstLevelID As Integer

        Public Property LevelsUrl As String
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindData()
        End If
    End Sub

    Private Sub BindData()

        Dim userId = 0
        Dim userTypeId = 0

        Try
            userId = SessionManager.GetInstance.Users.UserID
            userTypeId = SessionManager.GetInstance.Users.UserType
        Catch
            userId = 0
            userTypeId = 0
        End Try

        Dim cards As New List(Of LevelTypeCardVM)()

        Using ctx As New Prosto_ERP_DataClassesDataContext()

            ' 1) جلب أنواع التدريب
            Dim types = ctx.Select_TR_Level_Types_All().ToList()

            For Each t In types

                Dim typeId As Integer = SafeInt(t.ID)
                Dim titleAr As String = SafeStr(t.Title_Ar)
                Dim notesAr As String = SafeStr(t.Notes_Ar)
                Dim img As String = SafeStr(t.Image)

                ' صورة افتراضية في حال فاضية
                Dim imgUrl As String = If(String.IsNullOrWhiteSpace(img),
                                          ResolveUrl("~/Assets/images/level-types/type-default.jpg"),
                                          ResolveUrl(img))

                ' 2) جلب مستويات هذا النوع (مع الإحصائيات) حسب المستخدم ونوعه
                Dim rows =
                        ctx.Select_TR_Training_Levels_WithStats_ByUserType_And_LevelType(userId, userTypeId, typeId).
                        ToList()

                Dim levelsCount As Integer = rows.Count

                Dim videosSum = 0
                Dim durationSumSeconds = 0
                Dim completionSum = 0

                Dim firstLevelId = 0

                If levelsCount > 0 Then
                    ' أول مستوى حسب Item_Order ثم ID
                    Dim first =
                            rows.OrderBy(Function(r) If(r.Item_Order Is Nothing, Integer.MaxValue, CInt(r.Item_Order))) _
                            .ThenBy(Function(r) CInt(r.ID)) _
                            .FirstOrDefault()

                    If first IsNot Nothing Then
                        firstLevelId = SafeInt(first.ID)
                    End If

                    For Each r In rows
                        videosSum += SafeInt(r.VideosCount)
                        durationSumSeconds += SafeInt(r.TotalDurationSeconds)

                        ' CompletionPercent قد تكون Null
                        completionSum += SafeInt(r.CompletionPercent)
                    Next
                End If

                Dim avgCompletion = 0
                If levelsCount > 0 Then
                    avgCompletion = CInt(Math.Round(completionSum/CDbl(levelsCount), MidpointRounding.AwayFromZero))
                    If avgCompletion < 0 Then avgCompletion = 0
                    If avgCompletion > 100 Then avgCompletion = 100
                End If

                Dim durHHMMSS As String = FormatDurationHHMMSS(durationSumSeconds)

                Dim url As String = String.Format("/Modules/LMS/LMS_TR_Training_Levels.aspx?UserID={0}&Level_Types={1}",
                                                  userId, typeId)

                Dim vm As New LevelTypeCardVM() With {
                        .LevelTypeID = typeId,
                        .TitleAr = titleAr,
                        .NotesAr = If(String.IsNullOrWhiteSpace(notesAr), " ", notesAr),
                        .ImageUrl = imgUrl,
                        .LevelsCount = levelsCount,
                        .VideosCount = videosSum,
                        .TotalDurationSeconds = durationSumSeconds,
                        .TotalDurationHHMMSS = durHHMMSS,
                        .CompletionPercentAvg = avgCompletion,
                        .HasLevels = (levelsCount > 0 AndAlso firstLevelId > 0),
                        .FirstLevelID = firstLevelId,
                        .LevelsUrl = url
                        }

                cards.Add(vm)
            Next
        End Using

        If cards.Count = 0 Then
            pnlGrid.Visible = False
            pnlEmpty.Visible = True
            Return
        End If

        pnlGrid.Visible = True
        pnlEmpty.Visible = False

        rptTypes.DataSource = cards
        rptTypes.DataBind()
    End Sub

    ' ===== Helpers =====

    Private Function SafeStr(obj As Object) As String
        If obj Is Nothing Then Return ""
        Return Convert.ToString(obj).Trim()
    End Function

    Private Function SafeInt(obj As Object) As Integer
        If obj Is Nothing Then Return 0
        Dim v = 0
        Integer.TryParse(Convert.ToString(obj), v)
        Return v
    End Function

    Private Function FormatDurationHHMMSS(totalSeconds As Integer) As String
        If totalSeconds <= 0 Then Return "00:00:00"

        Dim ts As TimeSpan = TimeSpan.FromSeconds(totalSeconds)

        ' نعرض بالساعات الكاملة حتى لو أكثر من 24 ساعة
        Dim totalHours = CInt(Math.Floor(ts.TotalHours))
        Dim mm As Integer = ts.Minutes
        Dim ss As Integer = ts.Seconds

        Return totalHours.ToString("00") & ":" & mm.ToString("00") & ":" & ss.ToString("00")
    End Function
End Class


