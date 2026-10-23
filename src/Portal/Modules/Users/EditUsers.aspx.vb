Imports AjaxControlToolkit
Imports Echo.Encrptor
Imports Prosto_ERP_ClassLibrary

Public Class EditUsers
    Inherits PageBase

    Private ReadOnly Property UserId As Integer
        Get
            Return CInt(Request.QueryString("ID"))
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If

        If Not IsPostBack Then
            If Request.HttpMethod="GET" Then ClearFileSession()
            FillUserTypes()
            FillStatuses()
            FillGenders()
            FillNationalities()
            FillBrands()
            FillShifts()
            FillData()
            ApplyUserTypeRules()
        End If
    End Sub

    '============ تعبئة القوائم ============
    Private Sub FillUserTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Users_Types_All() _
                    .Where(Function(x) x.IsDeleted = 0 AndAlso x.ID <> 7) _
                    .ToList()
            ddlUserType.DataSource = data
            ddlUserType.DataTextField = "Title_Ar"
            ddlUserType.DataValueField = "ID"
            ddlUserType.DataBind()
            ddlUserType.Items.Insert(0, New ListItem("اختر نوع المستخدم", ""))
        End Using
    End Sub

    Private Sub FillStatuses()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Users_Status_All() _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlStatus.DataSource = data
            ddlStatus.DataTextField = "Title_Ar"
            ddlStatus.DataValueField = "ID"
            ddlStatus.DataBind()
            ddlStatus.Items.Insert(0, New ListItem("اختر الحالة", ""))
        End Using
    End Sub

    Private Sub FillGenders()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Genders_All() _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlGender.DataSource = data
            ddlGender.DataTextField = "Title_Ar"
            ddlGender.DataValueField = "ID"
            ddlGender.DataBind()
            ddlGender.Items.Insert(0, New ListItem("اختر الجنس", ""))
        End Using
    End Sub

    Private Sub FillNationalities()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Nationalities_All() _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlNationality.DataSource = data
            ddlNationality.DataTextField = "Title_Ar"
            ddlNationality.DataValueField = "ID"
            ddlNationality.DataBind()
            ddlNationality.Items.Insert(0, New ListItem("اختر الجنسية", ""))
        End Using
    End Sub

    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Brands_All() _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlBrand.DataSource = data
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
            ddlBrand.Items.Insert(0, New ListItem("اختر العلامة", ""))
        End Using
    End Sub

    Private Sub FillBranches(Optional brandId As Integer? = Nothing)
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))

        If Not brandId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(brandId.Value) _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        End Using
    End Sub

    Private Sub FillDepartments(Optional branchId As Integer? = Nothing)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))

        If Not branchId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Departments_ByBranchID(branchId.Value) _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlDepartment.DataSource = data
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()
            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        End Using
    End Sub

    Private Sub FillJobTitles(Optional departmentId As Integer? = Nothing)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))

        If Not departmentId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_ByDepartmentID(departmentId.Value) _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlJobTitle.DataSource = data
            ddlJobTitle.DataTextField = "Title_Ar"
            ddlJobTitle.DataValueField = "ID"
            ddlJobTitle.DataBind()
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
        End Using
    End Sub

    Private Sub FillShifts()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Shift_All() _
                    .Where(Function(x) x.IsDeleted = 0) _
                    .ToList()
            ddlShift.DataSource = data
            ddlShift.DataTextField = "Title_Ar"
            ddlShift.DataValueField = "ID"
            ddlShift.DataBind()
            ddlShift.Items.Insert(0, New ListItem("اختر الوردية", ""))
        End Using
    End Sub


    '============ منطق نوع المستخدم ============

    Private Sub ResetOrgPanels()
        pnlBrand.Visible = False
        pnlBranch.Visible = False
        pnlDepartment.Visible = False
        pnlJobTitle.Visible = False
        pnlShift.Visible = False

        rfvBrand.Enabled = False
        rfvBranch.Enabled = False
        rfvDepartment.Enabled = False
        rfvJobTitle.Enabled = False
        rfvShift.Enabled = False
    End Sub

    Private Sub ApplyUserTypeRules()
        ' إخفاء كل حقول الهيكل التنظيمي وإلغاء إجبارية الفالديشن
        ResetOrgPanels()

        ' لو ما في نوع مستخدم مختار نخرج
        If String.IsNullOrEmpty(ddlUserType.SelectedValue) Then Exit Sub

        ' تحويل القيمة إلى رقم (ID من جدول Users_Types)
        Dim typeId = CInt(ddlUserType.SelectedValue)

        Select Case typeId

            '========================
            ' 1) مدير نظام (ID = 1)
            '   → لا يظهر أي شيء من حقول الهيكل التنظيمي
            '========================
            Case 1
                ' ResetOrgPanels already hides everything

                '========================
                ' 2) مدير فرع (ID = 2)
                '   يظهر: العلامة + الفرع (إجباري)
                '   يخفي: القسم + المسمى + الوردية
                '========================
            Case 2
                pnlBrand.Visible = True
                pnlBranch.Visible = True

                rfvBrand.Enabled = True
                rfvBranch.Enabled = True

                '========================
                ' 3) مدير شفت (ID = 3)
                '   يظهر: العلامة + الفرع + الوردية (كلها إجبارية)
                '   يخفي: القسم + المحطة التعريفية
                '========================
            Case 3
                pnlBrand.Visible = True
                pnlBranch.Visible = True
                pnlShift.Visible = True

                rfvBrand.Enabled = True
                rfvBranch.Enabled = True
                rfvShift.Enabled = True

                '========================
                ' 4) موظف (ID = 4)
                '   يظهر: العلامة + الفرع + القسم + المسمى + الوردية (كلها إجبارية)
                '========================
            Case 4
                pnlBrand.Visible = True
                pnlBranch.Visible = True
                pnlDepartment.Visible = True
                pnlJobTitle.Visible = True
                pnlShift.Visible = True

                rfvBrand.Enabled = True
                rfvBranch.Enabled = True
                rfvDepartment.Enabled = True
                rfvJobTitle.Enabled = True
                rfvShift.Enabled = True

                '========================
                ' 5) مراقب جودة (ID = 5)
                '   يظهر: العلامة + الفرع (إجباري)
                '   يخفي: القسم + المسمى + الوردية
                '========================
            Case 5
                pnlBrand.Visible = True
                pnlBranch.Visible = True

                rfvBrand.Enabled = True
                rfvBranch.Enabled = True

        End Select
    End Sub


    '============ تحميل بيانات المستخدم ============

    Private Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim u = db.Select_UsersMembers_ByID(UserId).FirstOrDefault()
            If u Is Nothing Then Exit Sub
            If u.Type.GetValueOrDefault() = 7 Then
                ddlUserType.Items.Add(New ListItem("مستخدم خارجي سابق (موقوف)", "7"))
                ddlUserType.Enabled = False
                btnSave.Enabled = False
            End If

            ' نوع
            If u.Type.HasValue Then
                Dim it = ddlUserType.Items.FindByValue(u.Type.Value.ToString())
                If it IsNot Nothing Then
                    ddlUserType.ClearSelection()
                    it.Selected = True
                End If
            End If

            txtEmployeeNumber.Text = If(u.Employee_Number.HasValue, u.Employee_Number.Value.ToString(), "")
            txtFullNameAr.Text = u.FullName_Ar
            txtFullNameEn.Text = u.Fullname_En
            txtPhone.Text = u.PhoneNumber
            txtMobile.Text = u.MobileNumber
            txtEmail.Text = u.Email
            txtUserName.Text = u.UserName

            Dim encryptor As New TripleDesEncryptor()
            Dim DecryptPassword As String = encryptor.Decrypt(u.Password)

            hdnPassword.Value = If(DecryptPassword, String.Empty)
            txtPassword.Attributes("value") = hdnPassword.Value


            ' حالة
            If u.Status.HasValue Then
                Dim s = ddlStatus.Items.FindByValue(u.Status.Value.ToString())
                If s IsNot Nothing Then
                    ddlStatus.ClearSelection()
                    s.Selected = True
                End If
            End If

            ' جنس
            If u.Gender.HasValue Then
                Dim g = ddlGender.Items.FindByValue(u.Gender.Value.ToString())
                If g IsNot Nothing Then
                    ddlGender.ClearSelection()
                    g.Selected = True
                End If
            End If

            ' جنسية
            If u.Nationality.HasValue Then
                Dim n = ddlNationality.Items.FindByValue(u.Nationality.Value.ToString())
                If n IsNot Nothing Then
                    ddlNationality.ClearSelection()
                    n.Selected = True
                End If
            End If

            ' Brand → Branch → Dept → JobTitle
            Dim brandId As Integer? = u.Brand_ID
            Dim branchId As Integer? = u.Branch_ID
            Dim deptId As Integer? = u.Department_ID
            Dim jobId As Integer? = u.JobTitle_ID

            If brandId.HasValue Then
                Dim bItem = ddlBrand.Items.FindByValue(brandId.Value.ToString())
                If bItem IsNot Nothing Then
                    ddlBrand.ClearSelection()
                    bItem.Selected = True
                End If

                FillBranches(brandId)
            End If

            If branchId.HasValue Then
                Dim brItem = ddlBranch.Items.FindByValue(branchId.Value.ToString())
                If brItem IsNot Nothing Then
                    ddlBranch.ClearSelection()
                    brItem.Selected = True
                End If

                FillDepartments(branchId)
            End If

            If deptId.HasValue Then
                Dim dItem = ddlDepartment.Items.FindByValue(deptId.Value.ToString())
                If dItem IsNot Nothing Then
                    ddlDepartment.ClearSelection()
                    dItem.Selected = True
                End If

                FillJobTitles(deptId)
            End If

            If jobId.HasValue Then
                Dim jItem = ddlJobTitle.Items.FindByValue(jobId.Value.ToString())
                If jItem IsNot Nothing Then
                    ddlJobTitle.ClearSelection()
                    jItem.Selected = True
                End If
            End If

            ' Shift
            If u.Shif_ID.HasValue Then
                Dim sh = ddlShift.Items.FindByValue(u.Shif_ID.Value.ToString())
                If sh IsNot Nothing Then
                    ddlShift.ClearSelection()
                    sh.Selected = True
                End If
            End If

            ' صورة
            If Not String.IsNullOrEmpty(u.User_Image) Then
                hdnUserImage.Value = u.User_Image
                imgUser.ImageUrl = u.User_Image
            Else
                hdnUserImage.Value = ""
                imgUser.ImageUrl = "/assets/img/Prosto/avatar.png"
            End If

            cbIsActive.Checked = If(u.IsActive.HasValue, u.IsActive.Value, False)
        End Using
    End Sub

    '============ أحداث DropDowns ============

    Protected Sub ddlUserType_SelectedIndexChanged(sender As Object, e As EventArgs)
        ApplyUserTypeRules()
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId As Integer?
        If Integer.TryParse(ddlBrand.SelectedValue, Nothing) Then
            brandId = CInt(ddlBrand.SelectedValue)
        Else
            brandId = Nothing
        End If

        FillBranches(brandId)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim branchId As Integer?
        If Integer.TryParse(ddlBranch.SelectedValue, Nothing) Then
            branchId = CInt(ddlBranch.SelectedValue)
        Else
            branchId = Nothing
        End If

        FillDepartments(branchId)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer?
        If Integer.TryParse(ddlDepartment.SelectedValue, Nothing) Then
            deptId = CInt(ddlDepartment.SelectedValue)
        Else
            deptId = Nothing
        End If

        FillJobTitles(deptId)
    End Sub

    '============ حفظ التعديلات ============

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If ddlUserType.SelectedValue = "7" Then _
            Throw New HttpException(403, "أنشئ حساب العميل من إدارة العملاء.")
        ApplyUserTypeRules()
        If Not Page.IsValid Then Exit Sub

        Dim empNo = 0
        Integer.TryParse(txtEmployeeNumber.Text, empNo)

        Dim typeId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlUserType.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlUserType.SelectedValue))
        Dim statusId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlStatus.SelectedValue), CType(Nothing, Integer?), CInt(ddlStatus.SelectedValue))
        Dim genderId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlGender.SelectedValue), CType(Nothing, Integer?), CInt(ddlGender.SelectedValue))
        Dim nationalityId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlNationality.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlNationality.SelectedValue))

        Dim brandId As Integer? =
                If(String.IsNullOrEmpty(ddlBrand.SelectedValue), CType(Nothing, Integer?), CInt(ddlBrand.SelectedValue))
        Dim branchId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?), CInt(ddlBranch.SelectedValue))
        Dim deptId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlDepartment.SelectedValue))
        Dim jobId As Integer? =
                If _
                (String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?),
                 CInt(ddlJobTitle.SelectedValue))
        Dim shiftId As Integer? =
                If(String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?), CInt(ddlShift.SelectedValue))

        Dim fullNameAr = txtFullNameAr.Text
        Dim fullNameEn = txtFullNameEn.Text
        Dim phone = txtPhone.Text
        Dim mobile = txtMobile.Text
        Dim email = txtEmail.Text
        Dim userName = txtUserName.Text


        Dim password As String
        Dim encryptor As New TripleDesEncryptor()
        ' إذا المستخدم ما غيّر كلمة المرور، خذ القيمة القديمة من HiddenField
        If String.IsNullOrWhiteSpace(txtPassword.Text) Then
            Dim encryptedPassword As String = encryptor.Encrypt(hdnPassword.Value)
            password = encryptedPassword
        Else
            Dim encryptedPassword As String = encryptor.Encrypt(txtPassword.Text)
            password = encryptedPassword
        End If


        Dim userImagePath As String = hdnUserImage.Value
        Dim files = SaveFilesFromSession()
        If files IsNot Nothing AndAlso files.Count > 0 Then
            For Each f In files
                userImagePath = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            db.Update_UsersMembers_ByID(UserId,
                                        typeId,
                                        empNo,
                                        fullNameAr,
                                        fullNameEn,
                                        userImagePath,
                                        phone,
                                        mobile,
                                        email,
                                        brandId,
                                        branchId,
                                        deptId,
                                        jobId,
                                        shiftId,
                                        genderId,
                                        nationalityId,
                                        userName,
                                        password,
                                        statusId,
                                        Nothing,
                                        SessionManager.GetInstance.Users.UserID)

            db.Update_UsersMembers_IsActive_ByID(UserId,
                                                 cbIsActive.Checked,
                                                 SessionManager.GetInstance.Users.UserID)
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    '============ AjaxFileUpload ============

    Protected Sub UserImageUpload_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,True), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub UserImageUpload_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    '============ أزرار أخرى ============

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Users/ManageUsers.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Users/ManageUsers.aspx", True)
    End Sub
End Class


