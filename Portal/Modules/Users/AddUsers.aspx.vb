Imports System.Linq
Imports AjaxControlToolkit

Public Class AddUsers
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
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
        End If
    End Sub

    '============ تعبئة القوائم الأساسية ============

    Private Sub FillUserTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
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


    '============ منطق إظهار/إخفاء الحقول حسب نوع المستخدم ============

    Private Sub SetBasicValidationsEnabled(enabled As Boolean)
        rfvEmpNo.Enabled = enabled
        rfvNameAr.Enabled = enabled
        rfvNameEn.Enabled = enabled
        rfvUserName.Enabled = enabled
        rfvPassword.Enabled = enabled
        rfvGender.Enabled = enabled
        rfvNationality.Enabled = enabled
        rfvStatus.Enabled = enabled
    End Sub

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
        pnlBasicInfo.Visible = Not String.IsNullOrEmpty(ddlUserType.SelectedValue)

        If String.IsNullOrEmpty(ddlUserType.SelectedValue) Then
            SetBasicValidationsEnabled(False)
            ResetOrgPanels()
            Exit Sub
        End If

        ' كل الأنواع: البيانات الأساسية مطلوبة
        SetBasicValidationsEnabled(True)
        ResetOrgPanels()

        ' تحويل القيمة إلى رقم
        Dim typeId As Integer = CInt(ddlUserType.SelectedValue)

        Select Case typeId

        '========================
        ' 1) مدير نظام
        '========================
            Case 1
            ' لا شيء إضافي، كل شيء مخفي (ResetOrgPanels() يقوم بالمطلوب)

        '========================
        ' 2) مدير فرع
        '   يظهر: العلامة + الفرع (إجباري)
        '   يخفي: القسم + المسمى + الوردية
        '========================
            Case 2
                pnlBrand.Visible = True
                pnlBranch.Visible = True
                rfvBrand.Enabled = True
                rfvBranch.Enabled = True

        '========================
        ' 3) مدير شفت
        '   يظهر: العلامة + الفرع + الوردية (إجباري)
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
        ' 4) موظف
        '   يظهر جميع الحقول التنظيمية (كلها إجبارية)
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
        ' 5) مراقب جودة
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



    '============ أحداث DropDowns (PostBack جزئي داخل UpdatePanel) ============

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

    '============ حفظ المستخدم الجديد ============

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If ddlUserType.SelectedValue="7" Then Throw New System.Web.HttpException(403,"أنشئ حساب العميل من إدارة العملاء.")
        ApplyUserTypeRules()
        If Not Page.IsValid Then Exit Sub

        Dim empNo As Integer = 0
        Integer.TryParse(txtEmployeeNumber.Text, empNo)

        Dim typeId As Integer = CInt(ddlUserType.SelectedValue)
        Dim statusId As Integer = CInt(ddlStatus.SelectedValue)

        Dim genderId As Integer? = If(String.IsNullOrEmpty(ddlGender.SelectedValue), CType(Nothing, Integer?), CInt(ddlGender.SelectedValue))
        Dim nationalityId As Integer? = If(String.IsNullOrEmpty(ddlNationality.SelectedValue), CType(Nothing, Integer?), CInt(ddlNationality.SelectedValue))

        Dim brandId As Integer? = If(String.IsNullOrEmpty(ddlBrand.SelectedValue), CType(Nothing, Integer?), CInt(ddlBrand.SelectedValue))
        Dim branchId As Integer? = If(String.IsNullOrEmpty(ddlBranch.SelectedValue), CType(Nothing, Integer?), CInt(ddlBranch.SelectedValue))
        Dim deptId As Integer? = If(String.IsNullOrEmpty(ddlDepartment.SelectedValue), CType(Nothing, Integer?), CInt(ddlDepartment.SelectedValue))
        Dim jobId As Integer? = If(String.IsNullOrEmpty(ddlJobTitle.SelectedValue), CType(Nothing, Integer?), CInt(ddlJobTitle.SelectedValue))
        Dim shiftId As Integer? = If(String.IsNullOrEmpty(ddlShift.SelectedValue), CType(Nothing, Integer?), CInt(ddlShift.SelectedValue))

        Dim fullNameAr = txtFullNameAr.Text
        Dim fullNameEn = txtFullNameEn.Text
        Dim phone = txtPhone.Text
        Dim mobile = txtMobile.Text
        Dim email = txtEmail.Text
        Dim userName = txtUserName.Text

        Dim encryptor As New Echo.Encrptor.TripleDesEncryptor()
        Dim encryptedPassword As String = encryptor.Encrypt(txtPassword.Text)
        Dim password = encryptedPassword



        Dim userImagePath As String = Nothing
        Dim files = SaveFilesFromSession()
        If files IsNot Nothing AndAlso files.Count > 0 Then
            For Each f In files
                userImagePath = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Insert_UsersMembers(typeId,
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
