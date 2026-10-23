Imports System.Web.UI.HtmlControls

Public Class EditGenders
    Inherits PageBase

    Private ReadOnly Property GenderID As Integer
        Get
            Return CInt(Request.QueryString("ID"))
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            SystemAdministrationUI.Redirect(Me, "/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            SystemAdministrationUI.Redirect(Me, "/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillData()
        End If
    End Sub

    Private Sub FillData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim item = db.Select_Genders_ByID(GenderID).FirstOrDefault()
            If item Is Nothing Then Exit Sub

            txtTitleAr.Text = item.Title_Ar
            txtTitleEn.Text = item.Title_En

            If item.IsActive.HasValue Then
                cbIsActive.Checked = item.IsActive.Value
            Else
                cbIsActive.Checked = False
            End If
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then Exit Sub

        Dim titleAr = txtTitleAr.Text.Trim()
        Dim titleEn = txtTitleEn.Text.Trim()
        Dim isActive As Boolean = cbIsActive.Checked
        Dim userId = SessionManager.GetInstance.Users.UserID

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Update_Genders_ByID(GenderID, titleAr, titleEn, userId, isActive)
        End Using

        If Not SystemAdministrationUI.Complete(Me) Then LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Genders/ManageGenders.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        SystemAdministrationUI.Redirect(Me, "/Modules/Genders/ManageGenders.aspx", True)
    End Sub

End Class
