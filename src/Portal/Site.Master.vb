Imports Newtonsoft.Json
Imports Prosto_ERP_ClassLibrary

Public Class Site
    Inherits MasterPage
    Private ReadOnly db As New Prosto_ERP_DataClassesDataContext()

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        tmCorrespondenceCount.Enabled = True
        liNotification.Visible = True
        If Not IsPostBack Then
            If Not SessionManager.GetInstance.Users Is Nothing Then
                FillUserData()
                If tmCorrespondenceCount.Enabled Then BindCorrespondenceCount()
                If SessionManager.GetInstance.Users.UserType <> 1 Then
                    divmenu.Visible = True
                    liQuicklinks.Visible = False
                End If
            Else
                Session.Abandon()
                Session.Clear()
                Response.Redirect("~/Login.aspx")
            End If
        End If
    End Sub

    Protected Sub FillUserData()
        Try
            Dim user = SessionManager.GetInstance.Users

            If user IsNot Nothing Then

                Dim UserType As String = db.Select_Users_Types_ByID(user.UserType).FirstOrDefault().Title_Ar

                ' ===================== اسم و نوع المستخدم =====================
                ' عدّل أسماء الخصائص حسب الكلاس عندك (مثلاً Name, FullName, UserTypeTitle ...)
                lblUserFullName.Text = Convert.ToString(user.NameAr)
                lblUserType.Text = UserType

                ' ===================== صورة المستخدم =====================
                Dim imgPath = ""
                If user.UserImage IsNot Nothing Then
                    imgPath = Convert.ToString(user.UserImage)
                End If

                If String.IsNullOrWhiteSpace(imgPath) Then
                    ' لا يوجد صورة – نحدد Avatar حسب الجنس
                    Dim gender As String = Convert.ToString(user.Gender).ToLower()

                    ' عدّل القيم حسب ما تخزنها في قاعدة البيانات (m/f أو 1/2 إلخ)
                    If gender = "f" Or gender = "female" Or gender = "2" Or gender = "أنثى" Then
                        imgPath = "/assets/img/Prosto/avatar-female.png"
                    Else
                        imgPath = "/assets/img/Prosto/avatar-male.png"
                    End If
                End If

                imgUserAvatarNavbar.ImageUrl = imgPath
                imgUserAvatarDropdown.ImageUrl = imgPath

                ' ===================== رابط "ملفي الشخصي" =====================
                ' استعمال UserID من السيشن
                Dim employeeId As Integer = Convert.ToInt32(user.UserID)
                lnkMyProfile.HRef = "/modules/Employees/MyProfile.aspx?EmployeeID=" & employeeId.ToString()

            End If

        Catch ex As Exception
            ' ممكن تضيف Logging هنا إذا حاب
        End Try
    End Sub

    Protected Sub btnLogout_Click(sender As Object, e As EventArgs) Handles btnLogout.Click
        Session.Abandon()
        Session.Clear()
        Response.Redirect("~/Login.aspx")
    End Sub

    Protected Function CanUseCRM() As Boolean
        If SessionManager.GetInstance.Users Is Nothing Then Return False
        If Context.Items("CRM.Enabled") Is Nothing Then
            Try
                CRMData.Query("dbo.CRM_CheckUser",
                              CRMData.P("@Actor_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID))
                Context.Items("CRM.Enabled") = True
            Catch ex As Exception
                Context.Items("CRM.Enabled") = False
            End Try
        End If
        Return CBool(Context.Items("CRM.Enabled"))
    End Function

    Protected Sub BindCorrespondenceCount()
        BindFeedbackCount()
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Try
            Using data As New Prosto_ERP_DataClassesDataContext()
                litCorrespondenceCount.Text =
                    data.Select_Correspondence_UnreadCount(SessionManager.GetInstance.Users.UserID).First().
                        UnreadThreads.ToString()
            End Using
        Catch ex As Exception
            Diagnostics.Trace.TraceError("Correspondence count: {0}", ex)
        End Try
    End Sub

    Protected Sub CorrespondenceCount_Tick(sender As Object, e As EventArgs)
        BindCorrespondenceCount()
    End Sub

    Protected Sub BindFeedbackCount()
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Try
            Using data As New Prosto_ERP_DataClassesDataContext()
                litFeedbackCount.Text =
                    data.Select_Employee_Feedback_UnreadCount(SessionManager.GetInstance.Users.UserID).Single().
                        UnreadRequests.ToString()
                upFeedbackCount.Update()
            End Using
        Catch ex As Exception
            Diagnostics.Trace.TraceError("Feedback count: {0}", ex)
        End Try
    End Sub
End Class


