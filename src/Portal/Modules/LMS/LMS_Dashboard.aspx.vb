Imports Prosto_ERP_ClassLibrary

Public Class LMS_Dashboard
    Inherits PageBase

    ' ===== Types Cards =====
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

    ' ===== News Cards =====
    Private Class NewsCardVM
        Public Property PID As Integer
        Public Property TitleAr As String
        Public Property BriefAr As String
        Public Property ImageUrl As String
        Public Property DisplayDate As String
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindData()
            BindNews()
        End If
    End Sub

    ' =======================
    ' Types Section
    ' =======================
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

            Dim types = ctx.Select_TR_Level_Types_All().ToList()

            For Each t In types

                Dim typeId As Integer = SafeInt(t.ID)
                Dim titleAr As String = SafeStr(t.Title_Ar)
                Dim notesAr As String = SafeStr(t.Notes_Ar)
                Dim img As String = SafeStr(t.Image)

                Dim imgUrl As String = If(String.IsNullOrWhiteSpace(img),
                                          ResolveUrl("~/Assets/images/level-types/type-default.jpg"),
                                          ResolveUrl(img))

                Dim rows =
                        ctx.Select_TR_Training_Levels_WithStats_ByUserType_And_LevelType(userId, userTypeId, typeId).
                        ToList()

                Dim levelsCount As Integer = rows.Count
                Dim videosSum = 0
                Dim durationSumSeconds = 0
                Dim completionSum = 0
                Dim firstLevelId = 0

                If levelsCount > 0 Then
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

                cards.Add(New LevelTypeCardVM() With {
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
                             })
            Next
        End Using

        If cards.Count = 0 Then
            pnlGrid.Visible = False
            pnlEmpty.Visible = True
        Else
            pnlGrid.Visible = True
            pnlEmpty.Visible = False
            rptTypes.DataSource = cards
            rptTypes.DataBind()
        End If
    End Sub

    ' =======================
    ' News Section
    ' =======================
    Private Sub BindNews()
        Dim newsList As New List(Of NewsCardVM)()

        Using ctx As New Prosto_ERP_DataClassesDataContext()

            Dim rows = ctx.Select_News_All().ToList()

            ' عرض النشط فقط + آخر 6
            Dim activeRows = rows.Where(Function(n) SafeBool(n.IsActive)).Take(6).ToList()

            For Each n In activeRows
                Dim pid As Integer = SafeInt(n.PID)

                Dim titleAr As String = SafeStr(n.Title_AR)
                If String.IsNullOrWhiteSpace(titleAr) Then titleAr = SafeStr(n.Title_En)
                If String.IsNullOrWhiteSpace(titleAr) Then titleAr = "خبر"

                Dim briefAr As String = SafeStr(n.Brief_Ar)
                If String.IsNullOrWhiteSpace(briefAr) Then
                    briefAr = SafeStr(n.Brief_En)
                End If
                If String.IsNullOrWhiteSpace(briefAr) Then
                    Dim det As String = SafeStr(n.Details)
                    briefAr = If(String.IsNullOrWhiteSpace(det), " ", det)
                End If

                Dim img As String = SafeStr(n.Image)
                Dim imgUrl As String = If(String.IsNullOrWhiteSpace(img),
                                          ResolveUrl("~/Assets/images/news/news-default.jpg"),
                                          ResolveUrl(img))

                ' Date nullable, AddedDate not nullable
                Dim dt = CType(n.AddedDate, DateTime)
                Try
                    If n.Date IsNot Nothing Then
                        dt = CType(n.Date, DateTime)
                    End If
                Catch
                End Try

                Dim displayDate As String = dt.ToString("dd/MM/yyyy HH:mm")

                newsList.Add(New NewsCardVM With {
                                .PID = pid,
                                .TitleAr = titleAr,
                                .BriefAr = briefAr,
                                .ImageUrl = imgUrl,
                                .DisplayDate = displayDate
                                })
            Next
        End Using

        If newsList.Count = 0 Then
            pnlNews.Visible = False
            pnlNewsEmpty.Visible = True
        Else
            pnlNews.Visible = True
            pnlNewsEmpty.Visible = False
            rptNews.DataSource = newsList
            rptNews.DataBind()
        End If
    End Sub

    ' عند الضغط على "عرض التفاصيل" داخل الأخبار
    Protected Sub rptNews_ItemCommand(sender As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "NewsDetails" Then Exit Sub

        Dim pid = 0
        Integer.TryParse(Convert.ToString(e.CommandArgument), pid)
        If pid <= 0 Then Exit Sub

        FillNewsModal(pid)

        ' فتح المودال
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openNewsModal",
                                            "setTimeout(function(){ openNewsDetailsModal(); }, 50);", True)
    End Sub

    Private Sub FillNewsModal(pid As Integer)
        Using ctx As New Prosto_ERP_DataClassesDataContext()

            Dim row = ctx.Select_News_ByID(pid).FirstOrDefault()
            If row Is Nothing Then
                litNewsTitle.Text = "الخبر غير متوفر"
                litNewsDate.Text = ""
                litNewsBrief.Text = ""
                litNewsDetails.Text = ""
                pnlNewsImage.Visible = False
                Exit Sub
            End If

            Dim titleAr As String = SafeStr(row.Title_AR)
            If String.IsNullOrWhiteSpace(titleAr) Then titleAr = SafeStr(row.Title_En)
            If String.IsNullOrWhiteSpace(titleAr) Then titleAr = "خبر"

            Dim briefAr As String = SafeStr(row.Brief_Ar)
            If String.IsNullOrWhiteSpace(briefAr) Then briefAr = SafeStr(row.Brief_En)

            Dim details As String = SafeStr(row.Details)

            ' Date nullable, AddedDate not nullable
            Dim dt = CType(row.AddedDate, DateTime)
            Try
                If row.Date IsNot Nothing Then
                    dt = CType(row.Date, DateTime)
                End If
            Catch
            End Try

            Dim img As String = SafeStr(row.Image)
            If String.IsNullOrWhiteSpace(img) Then
                pnlNewsImage.Visible = False
            Else
                pnlNewsImage.Visible = True
                imgNewsModal.Src = ResolveUrl(img)
            End If

            ' عنوان/تاريخ
            litNewsTitle.Text = Server.HtmlEncode(titleAr)
            litNewsDate.Text = dt.ToString("dd/MM/yyyy HH:mm")

            ' النبذة كنص فقط
            litNewsBrief.Text = Server.HtmlEncode(briefAr)

            ' التفاصيل: إذا عندك HTML داخل Details وتريد عرضها كما هي:
            litNewsDetails.Text = If(String.IsNullOrWhiteSpace(details), " ", details)

            ' إذا تريد التفاصيل نص فقط (بدون HTML) استخدم بدل السطر أعلاه:
            ' litNewsDetails.Text = Server.HtmlEncode(details).Replace(vbCrLf, "<br/>")

        End Using
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

    Private Function SafeBool(obj As Object) As Boolean
        If obj Is Nothing Then Return False
        Dim v = False
        Boolean.TryParse(Convert.ToString(obj), v)
        Return v
    End Function

    Private Function FormatDurationHHMMSS(totalSeconds As Integer) As String
        If totalSeconds <= 0 Then Return "00:00:00"
        Dim ts As TimeSpan = TimeSpan.FromSeconds(totalSeconds)
        Dim totalHours = CInt(Math.Floor(ts.TotalHours))
        Dim mm As Integer = ts.Minutes
        Dim ss As Integer = ts.Seconds
        Return totalHours.ToString("00") & ":" & mm.ToString("00") & ":" & ss.ToString("00")
    End Function
End Class

