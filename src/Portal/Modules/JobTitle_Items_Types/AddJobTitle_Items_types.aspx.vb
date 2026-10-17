Imports Prosto_ERP_ClassLibrary

Public Class AddJobTitle_Items_types
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim titleAr = txtTitleAr.Text.Trim()
        Dim titleEn = txtTitleEn.Text.Trim()
        Dim userId = SessionManager.GetInstance.Users.UserID

        Using db As New Prosto_ERP_DataClassesDataContext
            db.Insert_JobTitle_Items_Types(titleAr, titleEn, userId)
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items_Types/ManageJobTitle_Items_types.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items_Types/ManageJobTitle_Items_types.aspx")
    End Sub
End Class


