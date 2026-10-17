Imports System.IO
Imports AjaxControlToolkit
Imports System.Data
Imports System.Linq

Public Class AddBrands
    Inherits PageBase

    Private Logo As String = Nothing
    Private EvaluationMethodVideo_path As String = Nothing
    Private WorkingMethodVideo_path As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ClearFileSession()
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim NameAr As String = txtFullNameAr.Text
        Dim NameEn As String = txtFullNameEn.Text

        ' 1) الشعار
        Dim filesAr = SaveFilesFromSession()
        If filesAr IsNot Nothing AndAlso filesAr.Count > 0 Then
            For Each f In filesAr
                Logo = f.Key
                Exit For
            Next
        End If

        ' 2) فيديو طريقة العمل
        Dim WorkingMethodVideo = SaveWorkingMethodVideoFromSession()
        If WorkingMethodVideo IsNot Nothing AndAlso WorkingMethodVideo.Count > 0 Then
            For Each f In WorkingMethodVideo
                WorkingMethodVideo_path = f.Key
                Exit For
            Next
        End If

        ' 3) فيديو طريقة التقييم
        Dim EvaluationMethodVideo = SaveEvaluationMethodVideoFromSession()
        If EvaluationMethodVideo IsNot Nothing AndAlso EvaluationMethodVideo.Count > 0 Then
            For Each f In EvaluationMethodVideo
                EvaluationMethodVideo_path = f.Key
                Exit For
            Next
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            ' الإجراء المعدّل:
            ' Insert_Brands(
            '   @Logo,
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

            db.Insert_Brands(
                Logo,
                NameAr,
                NameEn,
                SessionManager.GetInstance.Users.UserID,
                txtPolicies_Ar.Text,
                txtPolicies_En.Text,
                WorkingMethodVideo_path,
                WorkingMethodVideo_path,      ' يمكن مستقبلاً إضافة فيديو إنجليزي مستقل
                EvaluationMethodVideo_path,
                EvaluationMethodVideo_path    ' نفس الفكرة
            )
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    ' الشعار
    Protected Sub TaskVideoAr_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub TaskVideoAr_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
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

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Brands/ManageBrands.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Brands/ManageBrands.aspx")
    End Sub

End Class
