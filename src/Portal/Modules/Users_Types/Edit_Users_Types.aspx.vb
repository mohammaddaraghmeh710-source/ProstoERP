Imports System.Data.SqlClient
Imports System.Globalization
Imports Prosto_ERP_ClassLibrary

Public Class Edit_Users_Types
    Inherits UsersTypesPageBase

    Private ReadOnly Property ItemID As Integer
        Get
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("ID"), id) OrElse id <= 0 Then
                Response.Redirect("Manage_Users_Types.aspx")
                Return 0
            End If
            Return id
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim id As Integer = ItemID
        If Not IsPostBack Then
            Try
                Using db As New Prosto_ERP_DataClassesDataContext()
                    Dim row = db.Select_Users_Types_ByID(id).FirstOrDefault()
                    If row Is Nothing OrElse row.IsDeleted.GetValueOrDefault() Then
                        Response.Redirect("Manage_Users_Types.aspx?missing=1")
                        Return
                    End If
                    txtNameAR.Text = If(row.Title_Ar, "")
                    txtNameEn.Text = If(row.Title_En, "")
                    txtOrder.Text =
                        If _
                            (row.Item_Order.HasValue,
                             row.Item_Order.GetValueOrDefault().ToString(CultureInfo.InvariantCulture), "")
                    chkIsActive.Checked = row.IsActive.GetValueOrDefault()
                End Using
            Catch ex As SqlException
                ReportError(litMessage, ex)
                btnSave.Enabled = False
            End Try
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim order As Integer?
        If Not ReadTypeValues(txtNameAR, txtNameEn, txtOrder, litMessage, order) Then Return
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.Connection.Open()
                Using transaction = db.Connection.BeginTransaction(IsolationLevel.Serializable)
                    db.Transaction = transaction
                    Dim id As Integer = ItemID
                    If Not LockExistingType(db, id) Then
                        ShowMessage(litMessage, "النوع غير موجود أو تم حذفه.")
                        Return
                    End If
                    Dim userID = SessionManager.GetInstance.Users.UserID
                    db.Update_Users_Types_ByID(id, txtNameAR.Text, txtNameEn.Text, order, userID)
                    db.Update_Users_Types_IsActive_ByID(id, chkIsActive.Checked, userID)
                    transaction.Commit()
                End Using
            End Using
        Catch ex As SqlException
            ReportError(litMessage, ex)
            Return
        End Try
        Response.Redirect("Manage_Users_Types.aspx?updated=1")
    End Sub
End Class


