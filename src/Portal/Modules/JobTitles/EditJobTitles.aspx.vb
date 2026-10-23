Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class EditJobTitles
    Inherits PageBase

    Private WorkingMethodVideo_path As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If

        If Not Page.IsPostBack Then

            FillData()
            cbIsActive.Disabled = False
        End If
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

    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim branchId As Integer?
        If Integer.TryParse(ddlBranch.SelectedValue, Nothing) Then
            branchId = CInt(ddlBranch.SelectedValue)
        Else
            branchId = Nothing
        End If

        FillDepartments(branchId)
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

    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer?
        If Integer.TryParse(ddlDepartment.SelectedValue, Nothing) Then
            deptId = CInt(ddlDepartment.SelectedValue)
        Else
            deptId = Nothing
        End If
    End Sub


    Private Sub FillData()
        Dim ID = CInt(Request.QueryString("ID"))

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim item = db.Select_JobTitles_ByID(ID).FirstOrDefault()

            Dim DepartmentID = db.Select_JobTitles_ByID(ID).FirstOrDefault().DepartmentID
            Dim BranchID = db.Select_Departments_ByID(DepartmentID).FirstOrDefault().BranchID
            Dim BrandID = db.Select_Branches_ByID(BranchID).FirstOrDefault().BrandID

            If item IsNot Nothing Then

                FillBrands()
                FillBranches(BrandID)
                FillDepartments(BranchID)

                ' العلامة التجارية
                Dim brndID As String = BrandID.ToString()
                If ddlBrand.Items.FindByValue(brndID) IsNot Nothing Then
                    ddlBrand.SelectedValue = brndID
                End If

                ' الفرع
                Dim brnchID As String = BranchID.ToString()
                If ddlBranch.Items.FindByValue(brnchID) IsNot Nothing Then
                    ddlBranch.SelectedValue = brnchID
                End If

                ' القسم
                Dim depId As String = item.DepartmentID.Value.ToString()
                If ddlDepartment.Items.FindByValue(depId) IsNot Nothing Then
                    ddlDepartment.SelectedValue = depId
                End If


                ' الأسماء
                txtTitleAr.Text = item.Title_Ar
                txtTitleEn.Text = item.Title_En

                ' السياسات والفيديوهات (يتطلب تعديل Select_JobTitles_ByID ليعيدها)
                txtPolicies_Ar.Text = item.Policies_Ar
                txtPolicies_En.Text = item.Policies_En

                hfWorkingMethodVideoPath.Value = item.Working_Method_Video_Ar
                hfEvaluationMethodVideoPath.Value = item.Evaluation_Method_Video_Ar

                ' التفعيل
                cbIsActive.Checked = If(item.IsActive, True, False)
            End If
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then
            Return
        End If

        Dim ID = CInt(Request.QueryString("ID"))
        Dim DepartmentID = CInt(ddlDepartment.SelectedValue)
        Dim NameAr As String = txtTitleAr.Text
        Dim NameEn As String = txtTitleEn.Text
        Dim ChActive As Boolean = cbIsActive.Checked

        ' نبدأ من القيم القديمة
        WorkingMethodVideo_path = hfWorkingMethodVideoPath.Value
        EvaluationMethodVideo_path = hfEvaluationMethodVideoPath.Value

        ' فيديو طريقة العمل
        Dim WorkingMethodVideo = SaveWorkingMethodVideoFromSession()
        If WorkingMethodVideo IsNot Nothing AndAlso WorkingMethodVideo.Count > 0 Then
            For Each f In WorkingMethodVideo
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        ' فيديو طريقة التقييم
        Dim EvaluationMethodVideo = SaveEvaluationMethodVideoFromSession()
        If EvaluationMethodVideo IsNot Nothing AndAlso EvaluationMethodVideo.Count > 0 Then
            For Each f In EvaluationMethodVideo
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            ' التوقيع المفترض بعد التعديل:
            ' Update_JobTitles_ByID(
            '   @ID,
            '   @DepartmentID,
            '   @Title_Ar,
            '   @Title_En,
            '   @ModifyUser,
            '   @ModifyDate,
            '   @IsActive,
            '   @Policies_Ar,
            '   @Policies_En,
            '   @Working_Method_Video_Ar,
            '   @Working_Method_Video_En,
            '   @Evaluation_Method_Video_Ar,
            '   @Evaluation_Method_Video_En
            ' )
            db.Update_JobTitles_ByID(
                ID,
                DepartmentID,
                NameAr,
                NameEn,
                SessionManager.GetInstance.Users.UserID,
                Date.Now,
                ChActive,
                txtPolicies_Ar.Text,
                txtPolicies_En.Text,
                WorkingMethodVideo_path,
                WorkingMethodVideo_path,
                EvaluationMethodVideo_path,
                EvaluationMethodVideo_path
                )
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitles/ManageJobTitles.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitles/ManageJobTitles.aspx", True)
    End Sub

    ' فيديو طريقة العمل
    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' فيديو طريقة التقييم
    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub
End Class


