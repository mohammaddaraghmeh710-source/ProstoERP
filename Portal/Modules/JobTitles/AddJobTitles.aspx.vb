Imports System.IO
Imports AjaxControlToolkit
Imports System.Data
Imports System.Linq

Public Class AddJobTitles
    Inherits PageBase

    Private WorkingMethodVideo_path As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
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

    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim deptId As Integer?
        If Integer.TryParse(ddlDepartment.SelectedValue, Nothing) Then
            deptId = CInt(ddlDepartment.SelectedValue)
        Else
            deptId = Nothing
        End If

    End Sub



    'Private Sub FillDepartments()
    '    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
    '        Dim data = db.Select_Departments_All().ToList()
    '        ddlDepartment.DataSource = data
    '        ddlDepartment.DataTextField = "Title_Ar"
    '        ddlDepartment.DataValueField = "ID"
    '        ddlDepartment.DataBind()
    '    End Using
    '    ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", "0"))
    'End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim deptId As Integer = 0
        Integer.TryParse(ddlDepartment.SelectedValue, deptId)

        Dim nameAr As String = txtTitleAr.Text.Trim()
        Dim nameEn As String = txtTitleEn.Text.Trim()
        Dim policiesAr As String = txtPolicies_Ar.Text
        Dim policiesEn As String = txtPolicies_En.Text
        Dim isActive As Boolean = cbIsActive.Checked

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

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Insert_JobTitles(
                deptId,
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

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitles/ManageJobTitles.aspx", True)
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/JobTitles/ManageJobTitles.aspx")
    End Sub

    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, SystemAdministrationUI.UploadExtension(e.FileName,False), e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub btnSaveforAllDepartments_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim deptId As Integer = 0
        Integer.TryParse(ddlDepartment.SelectedValue, deptId)

        Dim nameAr As String = txtTitleAr.Text.Trim()
        Dim nameEn As String = txtTitleEn.Text.Trim()
        Dim policiesAr As String = txtPolicies_Ar.Text
        Dim policiesEn As String = txtPolicies_En.Text
        Dim isActive As Boolean = cbIsActive.Checked

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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim Departments = db.Select_Departments_All.Where(Function(x) x.Title_Ar = ddlDepartment.SelectedItem.ToString())
            For Each dep In Departments
                db.Insert_JobTitles(
               dep.ID,
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
End Class
