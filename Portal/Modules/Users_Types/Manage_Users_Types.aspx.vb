Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq

Public Class Manage_Users_Types
    Inherits UsersTypesPageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf BindData)
        If Not IsPostBack Then
            If Request.QueryString("added") = "1" Then ShowMessage(litMessage, "تمت إضافة النوع بنجاح.", True)
            If Request.QueryString("updated") = "1" Then ShowMessage(litMessage, "تم حفظ التعديلات بنجاح.", True)
            If Request.QueryString("missing") = "1" Then ShowMessage(litMessage, "النوع غير موجود أو تم حذفه.")
            BindData()
        End If
    End Sub

    Private Sub BindData()
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                Dim keyword As String = txtKeyword.Text.Trim()
                Dim rows = db.Select_Users_Types_All().ToList().Where(Function(row) Not row.IsDeleted.GetValueOrDefault())
                If keyword.Length > 0 Then
                    rows = rows.Where(Function(row) If(row.Title_Ar, "").IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0 OrElse If(row.Title_En, "").IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0)
                End If
                If ddlStatus.SelectedValue <> "-1" Then
                    Dim active As Boolean = ddlStatus.SelectedValue = "1"
                    rows = rows.Where(Function(row) row.IsActive.GetValueOrDefault() = active)
                End If
                Dim data = rows.OrderBy(Function(row) row.Item_Order).ThenBy(Function(row) row.ID).ToList()
                lstData.DataSource = data
                lstData.DataBind()
                lblEmpty.Visible = data.Count = 0
            End Using
        Catch ex As SqlException
            ReportError(litMessage, ex)
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
        If e.CommandName <> "Activate" AndAlso e.CommandName <> "Deactivate" AndAlso e.CommandName <> "DeleteItem" Then Return
        Dim id As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then
            ShowMessage(litMessage, "رقم النوع غير صالح.")
            Return
        End If
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                db.Connection.Open()
                Using transaction = db.Connection.BeginTransaction(IsolationLevel.Serializable)
                    db.Transaction = transaction
                    If Not LockExistingType(db, id) Then
                        ShowMessage(litMessage, "النوع غير موجود أو تم حذفه.")
                        Return
                    End If
                    Dim userID = SessionManager.GetInstance.Users.UserID
                    If e.CommandName = "DeleteItem" Then
                        If id = 1 OrElse HasReferences(db, id) Then
                            ShowMessage(litMessage, "لا يمكن حذف نوع مدير النظام أو نوع مرتبط بموظفين أو قوائم تقييم أو تدريب.")
                            Return
                        End If
                        db.Update_Users_Types_IsActive_ByID(id, False, userID)
                        db.Update_Users_Types_IsDeleted_ByID(id, True, userID)
                    Else
                        db.Update_Users_Types_IsActive_ByID(id, e.CommandName = "Activate", userID)
                    End If
                    transaction.Commit()
                End Using
            End Using
            ShowMessage(litMessage, If(e.CommandName = "DeleteItem", "تم حذف النوع.", If(e.CommandName = "Activate", "تم تفعيل النوع.", "تم إيقاف النوع.")), True)
        Catch ex As SqlException
            ReportError(litMessage, ex)
            Return
        End Try
        BindData()
    End Sub
End Class
