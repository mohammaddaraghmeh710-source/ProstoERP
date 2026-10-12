Imports System.Linq

Public Class EditWorkGuideRole
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillData()
        End If
    End Sub

    Private Sub FillData()
        Dim ID As Integer = CInt(Request.QueryString("ID"))

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim item = db.Select_Work_Guide_Role_ByID(ID).FirstOrDefault()

            If item IsNot Nothing Then
                txtTitleAr.Text = item.Title_Ar
                txtTitleEn.Text = item.Title_En
                txtCode.Text = item.Code
                txtDescriptionAr.Text = item.Description_Ar
                txtDescriptionEn.Text = item.Description_En
                cbIsActive.Checked = If(item.IsActive, True, False)
            End If

            Dim permissions = db.Select_Work_Guide_Role_Permissions_ByRoleID(ID).FirstOrDefault()

            If permissions IsNot Nothing Then
                chkViewCategory.Checked = If(permissions.Can_View_Category, True, False)
                chkViewDocument.Checked = If(permissions.Can_View_Document, True, False)
                chkPrintDocument.Checked = If(permissions.Can_Print_Document, True, False)
                chkDownloadDocument.Checked = If(permissions.Can_Download_Document, True, False)
            End If

        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then
            Return
        End If

        Dim ID As Integer = CInt(Request.QueryString("ID"))

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            db.Update_Work_Guide_Role_ByID(
                ID,
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                txtCode.Text.Trim(),
                txtDescriptionAr.Text.Trim(),
                txtDescriptionEn.Text.Trim(),
                SessionManager.GetInstance.Users.UserID,
                cbIsActive.Checked
            )

            db.Upsert_Work_Guide_Role_Permissions(
                ID,
                chkViewCategory.Checked,
                chkViewDocument.Checked,
                chkPrintDocument.Checked,
                chkDownloadDocument.Checked,
                SessionManager.GetInstance.Users.UserID
            )

        End Using

        Response.Redirect("/Modules/WorkGuide_Roles/ManageWorkGuideRoles.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Roles/ManageWorkGuideRoles.aspx")
    End Sub

End Class