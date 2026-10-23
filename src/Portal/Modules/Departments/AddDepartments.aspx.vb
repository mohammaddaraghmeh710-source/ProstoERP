Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class AddDepartments
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

        If Not IsPostBack Then
            FillBrands()
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

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim branchId = 0
        Integer.TryParse(ddlBranch.SelectedValue, branchId)

        Dim nameAr As String = txtTitleAr.Text.Trim()
        Dim nameEn As String = txtTitleEn.Text.Trim()
        Dim policiesAr As String = txtPolicies_Ar.Text
        Dim policiesEn As String = txtPolicies_En.Text
        Dim isActive As Boolean = cbIsActive.Checked

        ' حفظ مسارات الفيديو من الـ Session
        Dim working = SaveWorkingMethodVideoFromSession()
        If working IsNot Nothing AndAlso working.Count > 0 Then
            For Each f In working
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Dim evaluation = SaveEvaluationMethodVideoFromSession()
        If evaluation IsNot Nothing AndAlso evaluation.Count > 0 Then
            For Each f In evaluation
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            db.Insert_Departments(
                branchId,
                nameAr,
                nameEn,
                SessionManager.GetInstance.Users.UserID, Date.Now, Nothing, Nothing, 0, 1, 0,
                policiesAr,
                policiesEn,
                WorkingMethodVideo_path,
                WorkingMethodVideo_path,
                EvaluationMethodVideo_path,
                EvaluationMethodVideo_path
                )
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub


    Protected Sub btnSaveforAllBranches_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim branchId = 0
        Integer.TryParse(ddlBranch.SelectedValue, branchId)

        Dim nameAr As String = txtTitleAr.Text.Trim()
        Dim nameEn As String = txtTitleEn.Text.Trim()
        Dim policiesAr As String = txtPolicies_Ar.Text
        Dim policiesEn As String = txtPolicies_En.Text
        Dim isActive As Boolean = cbIsActive.Checked

        ' حفظ مسارات الفيديو من الـ Session
        Dim working = SaveWorkingMethodVideoFromSession()
        If working IsNot Nothing AndAlso working.Count > 0 Then
            For Each f In working
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Dim evaluation = SaveEvaluationMethodVideoFromSession()
        If evaluation IsNot Nothing AndAlso evaluation.Count > 0 Then
            For Each f In evaluation
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim branches = db.Select_Branches_ByBrandID(ddlBrand.SelectedValue()).ToList()

            For Each br In branches
                db.Insert_Departments(
                    br.ID,
                    nameAr,
                    nameEn,
                    SessionManager.GetInstance.Users.UserID, Date.Now, Nothing, Nothing, 0, 1, 0,
                    policiesAr,
                    policiesEn,
                    WorkingMethodVideo_path,
                    WorkingMethodVideo_path,
                    EvaluationMethodVideo_path,
                    EvaluationMethodVideo_path
                    )

            Next
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Departments/ManageDepartments.aspx", True)
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Departments/ManageDepartments.aspx")
    End Sub

    ' فيديو طريقة التنفيذ
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


