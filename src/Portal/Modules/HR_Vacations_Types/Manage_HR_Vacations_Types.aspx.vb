Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class Manage_HR_Vacations_Types
    Inherits HRTypePageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf BindData)
        If Not IsPostBack Then
            If Request.QueryString("added") = "1" Then ShowMessage(litMessage, "تمت الإضافة بنجاح.", True)
            If Request.QueryString("updated") = "1" Then ShowMessage(litMessage, "تم حفظ التعديلات بنجاح.", True)
            If Request.QueryString("missing") = "1" Then ShowMessage(litMessage, "العنصر غير موجود أو تم حذفه.")
            BindData()
        End If
    End Sub

    Private Sub BindData()
        Dim active As Boolean? = Nothing
        If ddlStatus.SelectedValue = "1" Then active = True
        If ddlStatus.SelectedValue = "0" Then active = False
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                Dim rows =
                        db.Select_HR_Vacations_Types_Filter(
                            If(String.IsNullOrWhiteSpace(txtKeyword.Text), Nothing, txtKeyword.Text.Trim()), active).
                        ToList()
                lstData.DataSource = rows
                lstData.DataBind()
                lblEmpty.Visible = rows.Count = 0
            End Using
        Catch ex As SqlException
            ShowDatabaseError(litMessage, ex)
        End Try
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        BindData()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        txtKeyword.Text = ""
        ddlStatus.SelectedValue = "-1"
        litMessage.Text = ""
        BindData()
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName <> "Activate" AndAlso e.CommandName <> "Deactivate" AndAlso e.CommandName <> "DeleteItem" Then _
            Return
        Dim id As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then
            ShowMessage(litMessage, "رقم العنصر غير صالح.")
            Return
        End If
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                Dim affected = 0
                Dim userID = SessionManager.GetInstance.Users.UserID
                If e.CommandName = "DeleteItem" Then
                    Dim result = db.Update_HR_Vacations_Types_IsDeleted_ByID(id, userID).FirstOrDefault()
                    If result IsNot Nothing Then affected = result.AffectedRows
                Else
                    Dim result =
                            db.Update_HR_Vacations_Types_IsActive_ByID(id, e.CommandName = "Activate", userID).
                            FirstOrDefault()
                    If result IsNot Nothing Then affected = result.AffectedRows
                End If
                If affected = 1 Then
                    ShowMessage(litMessage,
                                If _
                                   (e.CommandName = "DeleteItem", "تم حذف العنصر.",
                                    If(e.CommandName = "Activate", "تم تفعيل العنصر.", "تم إيقاف العنصر.")), True)
                Else
                    ShowMessage(litMessage, "العنصر غير موجود أو تم حذفه.")
                End If
            End Using
        Catch ex As SqlException
            ShowDatabaseError(litMessage, ex)
            Return
        End Try
        BindData()
    End Sub
End Class

