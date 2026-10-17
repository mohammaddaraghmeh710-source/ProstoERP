Imports System
Imports System.Linq
Imports System.Web
Imports Prosto_ERP_ClassLibrary

Public Class LMS_TR_Training_Levels
    Inherits System.Web.UI.Page

    Private Property CurrentUserID As Integer
        Get
            Dim o = ViewState("CurrentUserID")
            If o Is Nothing Then Return 0
            Return CInt(o)
        End Get
        Set(value As Integer)
            ViewState("CurrentUserID") = value
        End Set
    End Property

    Private Property CurrentLevelTypeID As Integer
        Get
            Dim o = ViewState("CurrentLevelTypeID")
            If o Is Nothing Then Return 0
            Return CInt(o)
        End Get
        Set(value As Integer)
            ViewState("CurrentLevelTypeID") = value
        End Set
    End Property

    Private Property FirstLevelID As Integer
        Get
            Dim o = ViewState("FirstLevelID")
            If o Is Nothing Then Return 0
            Return CInt(o)
        End Get
        Set(value As Integer)
            ViewState("FirstLevelID") = value
        End Set
    End Property

    Private Property FirstLevelTitle As String
        Get
            Dim o = ViewState("FirstLevelTitle")
            If o Is Nothing Then Return ""
            Return CStr(o)
        End Get
        Set(value As String)
            ViewState("FirstLevelTitle") = value
        End Set
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then

            Dim userId As Integer = 0
            Dim levelTypeId As Integer = 0

            Integer.TryParse(Request.QueryString("UserID"), userId)
            Integer.TryParse(Request.QueryString("Level_Types"), levelTypeId)

            CurrentUserID = userId
            CurrentLevelTypeID = levelTypeId

            If userId <= 0 OrElse levelTypeId <= 0 Then
                ShowNoData("—")
                Return
            End If

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                Dim lt = db.Select_TR_Level_Types_ByID(levelTypeId).FirstOrDefault()
                If lt IsNot Nothing Then
                    litTr_TypeName.Text = lt.Title_Ar
                    litTrainingLevelNote.Text = lt.Notes_Ar
                Else
                    litTr_TypeName.Text = "-"
                    litTrainingLevelNote.Text = "-"
                End If
            End Using

            BindHeaderAndLevels(userId, levelTypeId)
        End If
    End Sub

    Private Sub ShowNoData(userName As String)
        pnlNoData.Visible = True
        rptLevels.DataSource = Nothing
        rptLevels.DataBind()

        lblEmployeeName.Text = userName

        litTotalLevels.Text = "0"
        litOpenLevels.Text = "0"
        litDoneLevels.Text = "0"
        litLockedLevels.Text = "0"
        litTotalHours.Text = "0"
        litCompletionPercent.Text = "0"
    End Sub

    Private Sub BindHeaderAndLevels(userId As Integer, levelTypeId As Integer)
        Using db As New Prosto_ERP_DataClassesDataContext()

            ' ===== Load user =====
            Dim usr = (From u In db.Select_UsersMembers_ByID(userId)
                       Where u.ID = userId AndAlso u.IsDeleted = False AndAlso u.IsActive = True
                       Select u).FirstOrDefault()

            If usr Is Nothing Then
                ShowNoData("—")
                Return
            End If

            Dim displayName As String =
                If(Not String.IsNullOrWhiteSpace(Convert.ToString(usr.FullName_Ar)), Convert.ToString(usr.FullName_Ar),
                   If(Not String.IsNullOrWhiteSpace(Convert.ToString(usr.UserName)), Convert.ToString(usr.UserName),
                      Convert.ToString(usr.Email)))

            lblEmployeeName.Text = displayName

            Try
                Dim imgPath As String = Convert.ToString(usr.User_Image)
                If Not String.IsNullOrWhiteSpace(imgPath) Then
                    imgEmployee.Src = imgPath
                End If
            Catch
            End Try

            Dim userType As Integer = 0
            Try
                userType = CInt(usr.Type)
            Catch
                userType = 0
            End Try

            ' ===== Call SP via LINQ =====
            Dim levels = db.Select_TR_Training_Levels_WithStats_ByUserType_And_LevelType(userId, userType, levelTypeId).ToList()
            If levels Is Nothing Then
                levels = New List(Of Select_TR_Training_Levels_WithStats_ByUserType_And_LevelTypeResult)()
            End If

            Dim total As Integer = levels.Count
            litTotalLevels.Text = total.ToString()

            If total = 0 Then
                pnlNoData.Visible = True
                rptLevels.DataSource = Nothing
                rptLevels.DataBind()

                btnContinue.Visible = False
                btnContinue.Enabled = False
                FirstLevelID = 0
                FirstLevelTitle = ""

                litOpenLevels.Text = "0"
                litDoneLevels.Text = "0"
                litLockedLevels.Text = "0"
                litTotalHours.Text = "0"
                litCompletionPercent.Text = "0"
                Return
            End If

            pnlNoData.Visible = False
            rptLevels.DataSource = levels
            rptLevels.DataBind()

            ' ✅ أول مستوى
            Dim first = levels.OrderBy(Function(x) CInt(x.Item_Order)).FirstOrDefault()
            If first IsNot Nothing Then
                FirstLevelID = CInt(first.ID)
                FirstLevelTitle = "المستوى 1: " & Convert.ToString(first.Title_Ar)
            Else
                FirstLevelID = 0
                FirstLevelTitle = ""
            End If

            ' =========================
            ' ✅ Progress Summary (حسب طلبك)
            ' LevelStatusID: 1=open, 2=done, 3=locked
            ' =========================
            Dim openCnt As Integer = levels.Where(Function(x) CInt(x.LevelStatusID) = 1).Count()
            Dim doneCnt As Integer = levels.Where(Function(x) CInt(x.LevelStatusID) = 2).Count()
            Dim lockedCnt As Integer = levels.Where(Function(x) CInt(x.LevelStatusID) = 3).Count()

            litOpenLevels.Text = openCnt.ToString()
            litDoneLevels.Text = doneCnt.ToString()
            litLockedLevels.Text = lockedCnt.ToString()

            ' ✅ إجمالي الساعات = مجموع TotalDurationHours
            Dim totalHours As Decimal = 0D
            Try
                totalHours = levels.Sum(Function(x) Convert.ToDecimal(If(x.TotalDurationHours, 0D)))
            Catch
                totalHours = 0D
            End Try
            litTotalHours.Text = Math.Round(totalHours, 2).ToString("0.##")

            ' ✅ نسبة الإنجاز = المكتمل / الإجمالي
            Dim completionPercent As Integer = 0
            If total > 0 Then
                completionPercent = CInt(Math.Round((doneCnt / CType(total, Decimal)) * 100D, 0))
            End If
            If completionPercent < 0 Then completionPercent = 0
            If completionPercent > 100 Then completionPercent = 100
            litCompletionPercent.Text = completionPercent.ToString()

            ' ✅ إظهار زر (ابدأ رحلتك) فقط إذا كانت كل المستويات مغلقة
            Dim allLocked As Boolean = levels.All(Function(x) CInt(x.LevelStatusID) = 3)
            btnContinue.Visible = allLocked AndAlso FirstLevelID > 0
            btnContinue.Enabled = allLocked AndAlso FirstLevelID > 0
        End Using
    End Sub

    ' =========================
    ' Helpers for UI rendering
    ' =========================

    Protected Function HtmlAttr(val As Object) As String
        Dim s As String = ""
        Try
            s = Convert.ToString(val)
        Catch
            s = ""
        End Try
        If String.IsNullOrEmpty(s) Then Return ""
        Return HttpUtility.HtmlAttributeEncode(s)
    End Function

    Protected Function GetStatusTitleSafe(statusAr As Object) As String
        Dim s As String = Convert.ToString(statusAr)
        If String.IsNullOrWhiteSpace(s) Then Return "غير محدد"
        Return s
    End Function

    ' ✅ حسب المطلوب:
    ' 1=open, 2=done, 3=locked
    Protected Function GetStatusKeyById(statusIdObj As Object) As String
        Dim id As Integer = 0
        Integer.TryParse(Convert.ToString(statusIdObj), id)
        If id = 1 Then Return "open"
        If id = 2 Then Return "done"
        If id = 3 Then Return "locked"
        Return "open"
    End Function

    Protected Function GetStatusCssById(statusIdObj As Object) As String
        Dim id As Integer = 0
        Integer.TryParse(Convert.ToString(statusIdObj), id)
        If id = 1 Then Return "status-green" ' open
        If id = 2 Then Return "status-blue"  ' done
        If id = 3 Then Return "status-red"   ' locked
        Return "status-green"
    End Function

    Protected Function GetStatusIconById(statusIdObj As Object) As String
        Dim id As Integer = 0
        Integer.TryParse(Convert.ToString(statusIdObj), id)
        If id = 1 Then Return "bx bx-play-circle"     ' open
        If id = 2 Then Return "bx bx-check-circle"    ' done
        If id = 3 Then Return "bx bx-lock"            ' locked
        Return "bx bx-info-circle"
    End Function

    Protected Function FormatHours(hoursObj As Object) As String
        Try
            Dim h As Decimal = Convert.ToDecimal(hoursObj)
            Return Math.Round(h, 2).ToString("0.##")
        Catch
            Return "0"
        End Try
    End Function

    Protected Function FormatDate(val As Object) As String
        Try
            If val Is Nothing OrElse val Is DBNull.Value Then Return "-"
            Dim d As DateTime = Convert.ToDateTime(val)
            Return d.ToString("yyyy-MM-dd")
        Catch
            Return "-"
        End Try
    End Function

    Protected Function SafePercent(val As Object) As String
        Try
            If val Is Nothing OrElse val Is DBNull.Value Then Return "0"
            Dim p As Decimal = Convert.ToDecimal(val)
            If p < 0D Then p = 0D
            If p > 100D Then p = 100D
            Return p.ToString(System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return "0"
        End Try
    End Function

    Protected Function GetLockedHintHtmlById(statusIdObj As Object) As String
        If GetStatusKeyById(statusIdObj) <> "locked" Then Return ""
        Return "<div class='mt-2' style='padding:.6rem .75rem;border-radius:.65rem;background:#fbfcfe;border:1px dashed rgba(148,163,184,.7);color:#475569;font-size:.85rem;'>" &
               "<i class='bx bx-lock-alt ms-1'></i> لفتح هذا المستوى يجب أولًا إنهاء المستوى السابق.</div>"
    End Function

    Protected Function GetActionButtonTextById(statusIdObj As Object) As String
        Dim k = GetStatusKeyById(statusIdObj)
        If k = "done" Then Return "عرض المحتوى"
        If k = "locked" Then Return "غير متاح"
        Return "أكمل مشاهدة"
    End Function

    Protected Function GetActionButtonCssById(statusIdObj As Object) As String
        Dim k = GetStatusKeyById(statusIdObj)
        If k = "done" Then Return "btn btn-sm btn-soft"
        If k = "locked" Then Return "btn btn-sm btn-soft btn-disabled"
        Return "btn btn-sm btn-primary"
    End Function

    Protected Function GetLevelContentUrl(levelIdObj As Object, statusIdObj As Object) As String
        Dim levelId As Integer = 0
        Integer.TryParse(Convert.ToString(levelIdObj), levelId)

        If GetStatusKeyById(statusIdObj) = "locked" Then
            Return "javascript:void(0);"
        End If

        Return "/Modules/LMS/LMS_TR_Training_Videos.aspx?UserID=" & CurrentUserID &
               "&Level_Types=" & CurrentLevelTypeID &
               "&LevelID=" & levelId
    End Function

    Protected Sub btnContinue_Click(sender As Object, e As EventArgs) Handles btnContinue.Click
        If CurrentUserID <= 0 OrElse FirstLevelID <= 0 Then Return

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim hasAnyProgress = db.Select_TR_User_Level_Progress_ByUserID(CurrentUserID).Any()
            If Not hasAnyProgress Then
                db.Insert_TR_User_Level_Progress(
                    CurrentUserID,
                    FirstLevelID,
                    Date.Now,
                    Nothing,
                    1,
                    0,
                    SessionManager.GetInstance.Users.UserID
                )
            End If
        End Using

        lblMessage.Text = HttpUtility.HtmlEncode("تم تفعيل " & If(String.IsNullOrWhiteSpace(FirstLevelTitle), "المستوى 1", FirstLevelTitle))
        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Hide()
        Response.Redirect(Request.RawUrl, False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Hide()
        Response.Redirect(Request.RawUrl, False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
