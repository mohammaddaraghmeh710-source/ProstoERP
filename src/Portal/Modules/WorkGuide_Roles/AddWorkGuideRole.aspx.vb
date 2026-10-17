Imports Prosto_ERP_ClassLibrary

Public Class AddWorkGuideRole
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
        If Not Page.IsValid Then
            Return
        End If

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim result = db.Insert_Work_Guide_Role(
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                txtCode.Text.Trim(),
                txtDescriptionAr.Text.Trim(),
                txtDescriptionEn.Text.Trim(),
                SessionManager.GetInstance.Users.UserID
                ).FirstOrDefault()

            Dim RoleID = 0

            If result IsNot Nothing Then
                RoleID = Convert.ToInt32(result.ID)
            End If

            If RoleID > 0 Then
                db.Upsert_Work_Guide_Role_Permissions(
                    RoleID,
                    chkViewCategory.Checked,
                    chkViewDocument.Checked,
                    chkPrintDocument.Checked,
                    chkDownloadDocument.Checked,
                    SessionManager.GetInstance.Users.UserID
                    )
            End If

        End Using

        Response.Redirect("/Modules/WorkGuide_Roles/ManageWorkGuideRoles.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Roles/ManageWorkGuideRoles.aspx")
    End Sub
End Class

