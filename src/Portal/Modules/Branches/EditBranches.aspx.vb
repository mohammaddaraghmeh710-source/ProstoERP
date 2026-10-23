Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class EditBranches
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
            FillBrands()
            FillData()
            ' تأكد أنها مفعّلة فقط للتأكيد (عادةً هي Enabled افتراضياً)
            cbIsActive.Disabled = False
        End If
    End Sub

    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Brands_All().ToList()
            ddlBrand.DataSource = data
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using

        ddlBrand.Items.Insert(0, New ListItem("-- اختر العلامة التجارية --", ""))
    End Sub

    Private Sub FillData()
        Dim ID = CInt(Request.QueryString("ID"))

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim item = db.Select_Branches_ByID(ID).FirstOrDefault()
            If item IsNot Nothing Then
                ' العلامة التجارية
                If item.BrandID.HasValue Then
                    Dim brandIdStr As String = item.BrandID.Value.ToString()
                    If ddlBrand.Items.FindByValue(brandIdStr) IsNot Nothing Then
                        ddlBrand.SelectedValue = brandIdStr
                    End If
                End If

                ' الأسماء
                txtTitleAr.Text = item.Title_Ar
                txtTitleEn.Text = item.Title_En

                ' السياسات
                txtPolicies_Ar.Text = item.Policies_Ar
                txtPolicies_En.Text = item.Policies_En

                ' الملفات الحالية
                hfWorkingMethodVideoPath.Value = item.Working_Method_Video_Ar
                hfEvaluationMethodVideoPath.Value = item.Evaluation_Method_Video_Ar

                ' حالة التفعيل
                cbIsActive.Checked = If(item.IsActive, True, False)
            End If
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then
            Return
        End If

        Dim ID = CInt(Request.QueryString("ID"))
        Dim BrandID = CInt(ddlBrand.SelectedValue)
        Dim NameAr As String = txtTitleAr.Text
        Dim NameEn As String = txtTitleEn.Text
        Dim ChActive As Boolean = cbIsActive.Checked

        ' نبدأ من القيم القديمة المخزنة
        WorkingMethodVideo_path = hfWorkingMethodVideoPath.Value
        EvaluationMethodVideo_path = hfEvaluationMethodVideoPath.Value

        ' لو تم رفع فيديو جديد لطريقة العمل
        Dim WorkingMethodVideo = SaveWorkingMethodVideoFromSession()
        If WorkingMethodVideo IsNot Nothing AndAlso WorkingMethodVideo.Count > 0 Then
            For Each f In WorkingMethodVideo
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        ' لو تم رفع فيديو جديد لطريقة التقييم
        Dim EvaluationMethodVideo = SaveEvaluationMethodVideoFromSession()
        If EvaluationMethodVideo IsNot Nothing AndAlso EvaluationMethodVideo.Count > 0 Then
            For Each f In EvaluationMethodVideo
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            ' Update_Branches_ByID(
            '   @ID,
            '   @BrandID,
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

            db.Update_Branches_ByID(
                ID,
                BrandID,
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
        SystemAdministrationUI.Redirect(Me, "/Modules/Branches/ManageBranches.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Branches/ManageBranches.aspx", True)
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


