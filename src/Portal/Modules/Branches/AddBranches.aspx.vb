Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class AddBranches
    Inherits PageBase

    Private WorkingMethodVideo_path As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrands()
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

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then
            Return
        End If

        Dim BrandID = CInt(ddlBrand.SelectedValue)
        Dim NameAr As String = txtTitleAr.Text
        Dim NameEn As String = txtTitleEn.Text

        ' ملفات الفيديو (طريقة العمل)
        Dim WorkingMethodVideo = SaveWorkingMethodVideoFromSession()
        If WorkingMethodVideo IsNot Nothing AndAlso WorkingMethodVideo.Count > 0 Then
            For Each f In WorkingMethodVideo
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        ' ملفات الفيديو (طريقة التقييم)
        Dim EvaluationMethodVideo = SaveEvaluationMethodVideoFromSession()
        If EvaluationMethodVideo IsNot Nothing AndAlso EvaluationMethodVideo.Count > 0 Then
            For Each f In EvaluationMethodVideo
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_DataClassesDataContext
            ' التوقيع المتوقع لـ Insert_Branches بعد التعديل:
            ' Insert_Branches(
            '   @BrandID,
            '   @Title_Ar,
            '   @Title_En,
            '   @AddedUser,
            '   @Policies_Ar,
            '   @Policies_En,
            '   @Working_Method_Video_Ar,
            '   @Working_Method_Video_En,
            '   @Evaluation_Method_Video_Ar,
            '   @Evaluation_Method_Video_En
            ' )

            db.Insert_Branches(
                BrandID,
                NameAr,
                NameEn,
                SessionManager.GetInstance.Users.UserID, Date.Now, Nothing, Nothing, 0, 1, 0,
                txtPolicies_Ar.Text,
                txtPolicies_En.Text,
                WorkingMethodVideo_path,
                WorkingMethodVideo_path,
                EvaluationMethodVideo_path,
                EvaluationMethodVideo_path
                )
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Branches/ManageBranches.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Branches/ManageBranches.aspx")
    End Sub

    ' فيديو طريقة العمل
    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' فيديو طريقة التقييم
    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub
End Class


