Imports System
Imports System.Linq

Public Class Login
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            SessionManager.GetInstance.Users = Nothing
            CustomerPortalData.Current = Nothing
            Session.Remove("LogIn")
            If Request.QueryString("kind")="customer" Then ddlAccountKind.SelectedValue="customer"
            HideAlerts()
        End If
    End Sub

    Private Sub HideAlerts()
        pnlAlert.Visible = False
        lblAlert.Text = ""
        pnlInfo.Visible = False
        lblInfo.Text = ""
    End Sub

    Private Sub ShowError(message As String)
        pnlAlert.Visible = True
        lblAlert.Text = message
        pnlInfo.Visible = False
        lblInfo.Text = ""
    End Sub

    Private Sub ShowInfo(message As String)
        pnlInfo.Visible = True
        lblInfo.Text = message
        pnlAlert.Visible = False
        lblAlert.Text = ""
    End Sub

    Private Function GetCurrentShiftId() As Integer
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim nowTime As TimeSpan = DateTime.Now.TimeOfDay
            Dim shifts = (From s In db.Select_Shift_All()
                          Where (s.IsDeleted = False OrElse s.IsDeleted Is Nothing) _
                            AndAlso (s.IsActive = True OrElse s.IsActive Is Nothing)
                          Select s).ToList()

            For Each s In shifts
                If Not s.Start_Time.HasValue OrElse Not s.End_Time.HasValue Then Continue For

                Dim startT As TimeSpan = s.Start_Time.Value
                Dim endT As TimeSpan = s.End_Time.Value
                Dim isMatch As Boolean

                If startT <= endT Then
                    isMatch = (nowTime >= startT AndAlso nowTime <= endT)
                Else
                    isMatch = (nowTime >= startT OrElse nowTime <= endT)
                End If

                If isMatch Then Return s.ID
            Next

            Return 0
        End Using
    End Function

    Protected Sub btnLogin_Click(sender As Object, e As EventArgs)
        Try
            HideAlerts()

            If String.IsNullOrWhiteSpace(txtUserName.Text) OrElse String.IsNullOrWhiteSpace(txtPassword.Text) Then
                ShowError("يرجى إدخال اسم المستخدم وكلمة المرور.")
                Return
            End If

            If ddlAccountKind.SelectedValue="customer" Then
                Dim identity=CustomerPortalData.Login(txtUserName.Text.Trim(),txtPassword.Text)
                If identity Is Nothing Then
                    ShowError("اسم المستخدم أو كلمة المرور غير صحيحة، أو الحساب غير متاح.") : Return
                End If
                Session.Clear() : SessionManager.GetInstance.Users=Nothing : CustomerPortalData.Current=identity
                Response.Redirect("~/CustomerPortal/Dashboard.aspx",False) : Context.ApplicationInstance.CompleteRequest() : Return
            End If
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                Dim encryptor As New Echo.Encrptor.TripleDesEncryptor()
                Dim encryptedPassword As String = encryptor.Encrypt(txtPassword.Text)
                Dim loginRow = db.Select_UsersMembers_ByUserName_Password(txtUserName.Text.Trim(), encryptedPassword).FirstOrDefault()

                If loginRow Is Nothing Then
                    ShowError("اسم المستخدم أو كلمة المرور غير صحيحة.")
                    Return
                End If

                Dim user As UserEntity = GetUsersByUsername(txtUserName.Text.Trim())
                user.Password = encryptedPassword
                If user.UserType=7 Then
                    ShowError("هذا الحساب غير متاح. يرجى التواصل مع مدير النظام لإنشاء حساب عميل.") : Return
                End If
                CustomerPortalData.Current=Nothing
                Session("LogIn") = loginRow.ID
                SessionManager.GetInstance.Users = user

                If SessionManager.GetInstance.Users Is Nothing OrElse SessionManager.GetInstance.Users.UserID = 0 Then
                    ShowError("تعذر تسجيل الدخول، يرجى المحاولة مرة أخرى.")
                    Return
                End If

                Select Case SessionManager.GetInstance.Users.UserType
                    Case 1
                        Response.Redirect("~/modules/Brands_Dashboards/Brands_Dashboards.aspx", False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return

                    Case 2, 3
                        Dim shiftID As Integer = GetCurrentShiftId()
                        Dim branchID As Integer = loginRow.Branch_ID
                        Dim url As String = "~/Modules/Branch_Shift_Manager/Branch_Shift_Manager_Dashboard.aspx?BranchID=" & branchID.ToString() & "&ShiftID=" & shiftID.ToString()
                        Response.Redirect(url, False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return

                    Case 4
                        Response.Redirect("/Modules/LMS/LMS_Dashboard.aspx?EmployeeID=" & SessionManager.GetInstance.Users.UserID.ToString(), False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return

                    Case 5
                        Response.Redirect("~/modules/Brands_Dashboards/Brands_Dashboards.aspx", False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return

                    Case 6
                        Dim shiftID As Integer = GetCurrentShiftId()
                        Dim departmentID As Integer = loginRow.Department_ID
                        Dim url As String = "~/Modules/Departments_Dashboards/Department_Dashboard.aspx?DepartmentID=" & departmentID.ToString() & "&ShiftID=" & shiftID.ToString()
                        Response.Redirect(url, False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return

                    Case Else
                        Response.Redirect("~/Default.aspx", False)
                        Context.ApplicationInstance.CompleteRequest()
                        Return
                End Select
            End Using
        Catch ex As Exception
            ShowError("حدث خطأ غير متوقع أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى.")
        End Try
    End Sub

    Protected Sub lnkCreateAccount_Click(sender As Object, e As EventArgs)
        ShowInfo("سيتم تفعيل هذه الخدمة قريباً.")
    End Sub

    Protected Function GetUsersByUsername(ByVal username As String) As UserEntity
        Dim user As New UserEntity()

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            If db.Select_UsersMembers_ByUserName(username).Any() Then
                For Each userobj As Prosto_ERP_ClassLibrary.Select_UsersMembers_ByUserNameResult In db.Select_UsersMembers_ByUserName(username)
                    user.UserID = userobj.ID
                    user.Username = userobj.UserName
                    user.Email = userobj.Email
                    user.PhoneNumber = userobj.PhoneNumber
                    user.NameAr = userobj.FullName_Ar
                    user.NameEn = userobj.Fullname_En
                    user.IsPublisher = Nothing
                    user.UserType = userobj.Type
                    user.UserImage = userobj.User_Image
                    user.IsDeleted = userobj.IsDeleted
                    user.GroupID = 0
                Next
            End If
        End Using

        Return user
    End Function
End Class
