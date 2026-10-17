Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Web
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Text
Imports System.Web.Security
Imports System.Web.Services

Public Class LMS_TR_Training_Videos
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected LevelID As Integer
    Protected CurrentUserId As Integer

    Protected UserID_QS As Integer
    Protected LevelTypes_QS As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        CurrentUserId = SessionManager.GetInstance.Users.UserID

        LoadParameters()

        If Not IsPostBack Then
            BindVideos()
        End If
    End Sub

    Private Sub LoadParameters()
        If Not IsPostBack Then
            Integer.TryParse(Request.QueryString("LevelID"), LevelID)
            ViewState("LevelID") = LevelID

            Integer.TryParse(Request.QueryString("UserID"), UserID_QS)
            Integer.TryParse(Request.QueryString("Level_Types"), LevelTypes_QS)

            ViewState("UserID_QS") = UserID_QS
            ViewState("LevelTypes_QS") = LevelTypes_QS
        Else
            LevelID = If(ViewState("LevelID") IsNot Nothing, CInt(ViewState("LevelID")), 0)
            UserID_QS = If(ViewState("UserID_QS") IsNot Nothing, CInt(ViewState("UserID_QS")), 0)
            LevelTypes_QS = If(ViewState("LevelTypes_QS") IsNot Nothing, CInt(ViewState("LevelTypes_QS")), 0)
        End If
    End Sub

    Private Sub SetBackLinks()
        ' ✅ يرجع لصفحة المستويات مع QueryString المطلوب
        Dim u As Integer = UserID_QS
        Dim lt As Integer = LevelTypes_QS
        Dim lvl As Integer = LevelID

        Dim url As String = $"LMS_TR_Training_Levels.aspx?UserID={u}&Level_Types={lt}&LevelID={lvl}"

        lnkBackLevels.HRef = url
        lnkBackLevels2.HRef = url
    End Sub

    ' =========================
    ' Bind page by stored proc
    ' =========================
    Private Sub BindVideos()

        SetBackLinks()

        hfLevelId.Value = LevelID.ToString()

        Dim rows = db.Select_TR_Training_Videos_ByLevelID(LevelID).ToList()

        If rows Is Nothing OrElse rows.Count = 0 Then
            LevelTitleText.InnerText = "—"
            VideosCountText.InnerText = "0"
            pnlPlayer.Visible = False
            pnlStart.Visible = True
            Return
        End If

        ' Level title (same for all rows)
        Dim levelTitle As String = If(rows(0).LevelTitle_Ar, "-")
        LevelTitleText.InnerText = levelTitle
        VideosCountText.InnerText = rows.Count.ToString()

        Dim videos As New List(Of VideoVm)

        For Each r In rows

            Dim userMatch As Boolean = (r.UserID IsNot Nothing AndAlso CInt(r.UserID) = CurrentUserId)

            Dim vm As New VideoVm With {
                .LevelID = r.LevelID,
                .LevelTitle_Ar = r.LevelTitle_Ar,
                .VideoID = r.VideoID,
                .VideoTitle_Ar = If(r.VideoTitle_Ar, "-"),
                .Summary_Ar = If(r.Summary_Ar, "-"),
                .DurationSeconds = If(r.DurationSeconds, 0),
                .Item_Order = If(r.Item_Order, 999999),
                .RawVideoUrl_Ar = If(r.VideoUrl_Ar, ""),
                .SecureUrl = BuildSecureVideoUrl(If(r.VideoUrl_Ar, "")),
                .StartDate = If(userMatch, r.StartDate, Nothing),
                .EndDate = If(userMatch, r.EndDate, Nothing),
                .LastPositionSeconds = If(userMatch, If(r.LastPositionSeconds, 0), 0),
                .CompletionPercent = If(userMatch, Convert.ToInt32(r.CompletionPercent), 0),
                .Status = If(userMatch, Convert.ToInt32(r.Status), 3)
            }

            videos.Add(vm)
        Next

        ' =========================================================
        ' ✅ FIX: Deduplicate safely (pick latest progress per VideoID)
        '     This prevents showing 0% / 0s on reload when SP returns multiple rows
        ' =========================================================
        videos = videos.
            GroupBy(Function(x) x.VideoID).
            Select(Function(g)
                       Return g.
                           OrderByDescending(Function(x) If(x.EndDate.HasValue, x.EndDate.Value, DateTime.MinValue)).
                           ThenByDescending(Function(x) If(x.StartDate.HasValue, x.StartDate.Value, DateTime.MinValue)).
                           ThenByDescending(Function(x) x.LastPositionSeconds).
                           ThenByDescending(Function(x) x.CompletionPercent).
                           First()
                   End Function).
            OrderBy(Function(x) x.Item_Order).
            ThenBy(Function(x) x.VideoID).
            ToList()

        Dim anyOpen As Boolean = videos.Any(Function(x) x.Status = 1)
        Dim anyDone As Boolean = videos.Any(Function(x) x.Status = 2)
        Dim allLocked As Boolean = Not anyOpen AndAlso Not anyDone

        pnlPlayer.Visible = Not allLocked
        pnlStart.Visible = allLocked

        ' Prepare first video info (for Start modal)
        Dim firstVideo = videos.OrderBy(Function(x) x.Item_Order).FirstOrDefault()
        If firstVideo IsNot Nothing Then
            hfFirstVideoId.Value = firstVideo.VideoID.ToString()
            hfFirstVideoTitle.Value = firstVideo.VideoTitle_Ar
            hfFirstVideoSecureUrl.Value = firstVideo.SecureUrl
        End If

        ' Fill extra computed UI fields for repeater
        For Each v In videos
            v.CardTitle = v.VideoTitle_Ar
            v.DurationText = SecondsToText(v.DurationSeconds)
            v.StartDateText = If(v.StartDate.HasValue, v.StartDate.Value.ToString("yyyy-MM-dd HH:mm"), "-")
            v.EndDateText = If(v.EndDate.HasValue, v.EndDate.Value.ToString("yyyy-MM-dd HH:mm"), "-")

            Select Case v.Status
                Case 1
                    v.StatusText = "متاح حاليا"
                    v.StatusCss = "status-green"
                    v.StatusIcon = "bx-play-circle"
                    v.CanWatch = True
                    v.ActionText = "مشاهدة"
                    v.ActionBtnCss = "btn-primary"
                Case 2
                    v.StatusText = "مكتمل"
                    v.StatusCss = "status-blue"
                    v.StatusIcon = "bx-check-circle"
                    v.CanWatch = True
                    v.ActionText = "إعادة العرض"
                    v.ActionBtnCss = "btn-soft"
                Case Else
                    v.StatusText = "مغلق"
                    v.StatusCss = "status-red"
                    v.StatusIcon = "bx-lock"
                    v.CanWatch = False
                    v.ActionText = "غير متاح"
                    v.ActionBtnCss = "btn-soft"
            End Select
        Next


        ' ✅ إذا كل الفيديوهات مكتملة
        Dim allCompleted As Boolean = (videos.Count > 0 AndAlso videos.All(Function(x) x.Status = 2))
        pnlNextLevel.Visible = allCompleted


        rptVideos.DataSource = videos
        rptVideos.DataBind()

        If Not allLocked Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "autoLoadOpenVideo",
                "setTimeout(function(){ if(window.autoLoadFirstOpenVideo) autoLoadFirstOpenVideo(); }, 50);", True)
        End If

    End Sub

    ' =========================
    ' Confirm Start (Insert progress)
    ' =========================
    Protected Sub btnConfirmStart_Click(sender As Object, e As EventArgs)

        Dim firstVideoId As Integer = 0
        Integer.TryParse(hfFirstVideoId.Value, firstVideoId)

        If firstVideoId <= 0 Then
            BindVideos()
            Return
        End If

        Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            If Not ctx.Select_TR_User_Video_Progress_ByUserID_And_VideoID(CurrentUserId, firstVideoId).Any() Then
                ' create progress row for first video => status=1 (open)
                ctx.Insert_TR_User_Video_Progress(CurrentUserId, firstVideoId, DateTime.Now, Nothing, 0, 0, 1, False, CurrentUserId)
            End If
        End Using

        BindVideos()

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideStartModal",
            "try{ var m=document.getElementById('startFirstVideoModal'); if(window.bootstrap) bootstrap.Modal.getOrCreateInstance(m).hide(); }catch(e){}" &
            "setTimeout(function(){ if(window.autoLoadFirstOpenVideo) autoLoadFirstOpenVideo(); }, 80);",
            True)

    End Sub

    ' =========================
    ' ✅ AJAX WebMethods
    ' =========================
    <WebMethod()>
    Public Shared Sub SaveVideoProgress(videoId As Integer, lastPositionSeconds As Integer, completionPercent As Integer, isEnded As Boolean)

        Dim u = GetCurrentUserIdSafe()
        If u <= 0 OrElse videoId <= 0 Then Exit Sub

        lastPositionSeconds = Math.Max(0, lastPositionSeconds)
        completionPercent = Math.Max(0, Math.Min(100, completionPercent))

        Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

            ' ✅ 1) إذا الفيديو مكتمل Status=2 => لا نعمل أي تحديث نهائياً
            Dim existing = ctx.Select_TR_User_Video_Progress_ByUserID_And_VideoID(u, videoId).
            Where(Function(p) p.UserID = u AndAlso p.VideoID = videoId AndAlso p.IsDeleted = False).
            OrderByDescending(Function(p) p.ID).
            FirstOrDefault()

            If existing IsNot Nothing AndAlso existing.Status = 2 Then
                Exit Sub
            End If

            ' تحديث آخر نقطة + نسبة المشاهدة
            ctx.Update_TR_User_Video_Progress_LastPositionSeconds_ByUserID_And_VideoID(u, videoId, lastPositionSeconds, u)
            ctx.Update_TR_User_Video_Progress_CompletionPercent_ByUserID_And_VideoID(u, videoId, completionPercent, u)

            If isEnded Then
                ' تثبيت إكمال الفيديو (بدون فتح التالي هنا)
                ctx.Update_TR_User_Video_Progress_IsCompleted_ByUserID_And_VideoID(u, videoId)
                'ctx.Update_TR_User_Video_Progress_IsCompleted_ByUserID_And_VideoID(u, videoId, True, DateTime.Now, u)
                'ctx.Update_TR_User_Video_Progress_Status_ByUserID_And_VideoID(u, videoId, 2, u)
                'ctx.Update_TR_User_Video_Progress_CompletionPercent_ByUserID_And_VideoID(u, videoId, 100, u)
            End If

        End Using

    End Sub


    <WebMethod()>
    Public Shared Sub CompleteAndUnlockNext(levelId As Integer, currentVideoId As Integer)

        Dim u = GetCurrentUserIdSafe()
        If u <= 0 OrElse levelId <= 0 OrElse currentVideoId <= 0 Then Exit Sub

        Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

            ' 1) تأكيد إكمال الفيديو الحالي
            ctx.Update_TR_User_Video_Progress_IsCompleted_ByUserID_And_VideoID(u, currentVideoId)
            'ctx.Update_TR_User_Video_Progress_IsCompleted_EndDate_ByUserID_And_VideoID(u, currentVideoId, True, DateTime.Now, u)
            'ctx.Update_TR_User_Video_Progress_Status_ByUserID_And_VideoID(u, currentVideoId, 2, u)
            'ctx.Update_TR_User_Video_Progress_CompletionPercent_ByUserID_And_VideoID(u, currentVideoId, 100, u)


            ' 2) حساب نسبة إنجاز المستوى حسب ترتيب الفيديو داخل المستوى
            Dim levelVideos = ctx.Select_TR_Training_Videos_ByLevelID(levelId).ToList()

            If levelVideos IsNot Nothing AndAlso levelVideos.Count > 0 Then

                ' ترتيب الفيديوهات داخل المستوى
                Dim ordered = levelVideos.
                OrderBy(Function(x) If(x.Item_Order, 999999)).
                ThenBy(Function(x) x.VideoID).
                ToList()

                Dim total As Integer = ordered.Count

                ' position = ترتيب الفيديو الحالي (1-based)
                Dim posIndex As Integer = -1
                For i As Integer = 0 To ordered.Count - 1
                    If Convert.ToInt32(ordered(i).VideoID) = currentVideoId Then
                        posIndex = i
                        Exit For
                    End If
                Next

                If posIndex >= 0 AndAlso total > 0 Then
                    Dim position As Integer = posIndex + 1
                    Dim percent As Integer = CInt(Math.Floor((position * 100.0R) / total))

                    ' إذا آخر فيديو => المستوى مكتمل 100% + EndDate + Status=2
                    If position >= total Then
                        ctx.Update_TR_User_Level_Progress_IsComplet_ByUserID_And_LevelID(u, levelId, DateTime.Now, 2, 100, u)
                    Else
                        ' غير ذلك => تحديث نسبة فقط (حسب ترتيب الفيديو)
                        ctx.Update_TR_User_Level_Progress_CompletionPercent_ByUserID_And_LevelID(u, levelId, percent, u)
                    End If
                End If
            End If

            ' 3) جلب الفيديو التالي من الـ SP
            Dim spRow = ctx.Select_TR_Training_Videos_NextVideoID_ByLevelID_And_CurrentVideoID(levelId, currentVideoId).FirstOrDefault()
            If spRow Is Nothing OrElse spRow.NextVideoID Is Nothing Then
                ' لا يوجد فيديو تالي (قد يكون آخر فيديو) => انتهى
                Exit Sub
            End If

            Dim nextVideoID As Integer = Convert.ToInt32(spRow.NextVideoID)
            If nextVideoID <= 0 Then Exit Sub

            ' 4) تفعيل الفيديو التالي (بدون تصفير التقدم إذا كان موجود)
            Dim existing = ctx.Select_TR_User_Video_Progress_ByUserID_And_VideoID(u, nextVideoID).
            Where(Function(p) p.UserID = u AndAlso p.VideoID = nextVideoID AndAlso p.IsDeleted = False).
            OrderByDescending(Function(p) p.ID).
            FirstOrDefault()

            If existing Is Nothing Then
                ctx.Insert_TR_User_Video_Progress(u, nextVideoID, DateTime.Now, Nothing, 0, 0, 1, False, u)
            Else
                If existing.Status <> 2 Then
                    ctx.Update_TR_User_Video_Progress_Status_ByUserID_And_VideoID(u, nextVideoID, 1, u)
                End If
            End If

        End Using

    End Sub

    Protected Sub btnGoNextLevel_Click(sender As Object, e As EventArgs)

        Dim currentUserId As Integer = currentUserId
        Dim userType As Integer = 0


        Try
            userType = SessionManager.GetInstance.Users.UserType
        Catch
            userType = 0
        End Try

        Dim nextLevelId As Integer = GetNextLevelIdSafe(UserID_QS, userType, LevelTypes_QS)

        If nextLevelId > 0 Then

            Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

                ' لا تكرر الإدخال لو موجود progress مسبقاً
                Dim exists = ctx.Select_TR_User_Level_Progress_ByUserID_And_LevelID(UserID_QS, nextLevelId).Any()

                If Not exists Then
                    ctx.Insert_TR_User_Level_Progress(
                    UserID_QS,
                    nextLevelId,
                    DateTime.Now,
                    Nothing,
                    1,
                    0,
                    UserID_QS
                )
                End If

            End Using
        End If

        ' رجّعه لصفحة المستويات
        Response.Redirect($"LMS_TR_Training_Levels.aspx?UserID={UserID_QS}&Level_Types={LevelTypes_QS}", True)

    End Sub

    Private Shared Function GetNextLevelIdSafe(userId As Integer, userType As Integer, levelTypeId As Integer) As Integer
        Try
            Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

                Dim rows = ctx.Select_TR_Training_Levels_WithStats_ByUserType_And_LevelType(userId, userType, levelTypeId).ToList()
                If rows Is Nothing OrElse rows.Count = 0 Then Return 0

                ' أول مستوى غير مكتمل حسب الترتيب (Status <> 2)
                Dim nextRow = rows.
                OrderBy(Function(x) If(x.Item_Order, 999999)).
                ThenBy(Function(x) x.ID).
                FirstOrDefault(Function(x) Convert.ToInt32(x.LevelStatusID) <> 2)

                If nextRow Is Nothing Then Return 0

                Return Convert.ToInt32(nextRow.ID)

            End Using
        Catch
            Return 0
        End Try
    End Function




    Private Shared Function GetCurrentUserIdSafe() As Integer
        Try
            Dim sm = SessionManager.GetInstance()
            If sm IsNot Nothing AndAlso sm.Users IsNot Nothing Then
                Return sm.Users.UserID
            End If
        Catch
        End Try

        ' fallback
        Try
            Dim ctx = HttpContext.Current
            If ctx IsNot Nothing AndAlso ctx.Session IsNot Nothing AndAlso ctx.Session("Users") IsNot Nothing Then
                Dim uObj = ctx.Session("Users")
                Dim p = uObj.GetType().GetProperty("UserID")
                If p IsNot Nothing Then
                    Dim v = p.GetValue(uObj, Nothing)
                    If v IsNot Nothing Then Return Convert.ToInt32(v)
                End If
            End If
        Catch
        End Try

        Return 0
    End Function

    ' =========================
    ' Helpers
    ' =========================
    Private Function SecondsToText(sec As Integer) As String
        If sec < 0 Then sec = 0
        Dim h As Integer = sec \ 3600
        Dim m As Integer = (sec Mod 3600) \ 60
        Dim s As Integer = sec Mod 60
        If h > 0 Then Return $"{h}h {m}m"
        If m > 0 Then Return $"{m}m {s}s"
        Return $"{s}s"
    End Function

    ' ===== نفس دوال الفيديو الآمن =====
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

    ' =========================
    ' ViewModel
    ' =========================
    Private Class VideoVm
        Public Property LevelID As Integer
        Public Property LevelTitle_Ar As String

        Public Property VideoID As Integer
        Public Property VideoTitle_Ar As String
        Public Property Summary_Ar As String
        Public Property DurationSeconds As Integer
        Public Property Item_Order As Integer

        Public Property RawVideoUrl_Ar As String
        Public Property SecureUrl As String

        Public Property StartDate As DateTime?
        Public Property EndDate As DateTime?
        Public Property LastPositionSeconds As Integer
        Public Property CompletionPercent As Integer
        Public Property Status As Integer

        ' UI computed
        Public Property CardTitle As String
        Public Property DurationText As String
        Public Property StartDateText As String
        Public Property EndDateText As String

        Public Property StatusText As String
        Public Property StatusCss As String
        Public Property StatusIcon As String

        Public Property CanWatch As Boolean
        Public Property ActionText As String
        Public Property ActionBtnCss As String
    End Class

End Class
