Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class Add_Users_Types
    Inherits UsersTypesPageBase

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim order As Integer?
        If Not ReadTypeValues(txtNameAR, txtNameEn, txtOrder, litMessage, order) Then Return
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.Connection.Open()
                Using transaction = db.Connection.BeginTransaction()
                    db.Transaction = transaction
                    Dim result =
                            db.Insert_Users_Types(txtNameAR.Text, txtNameEn.Text, order,
                                                  SessionManager.GetInstance.Users.UserID).FirstOrDefault()
                    If result Is Nothing OrElse Not result.NewID.HasValue Then
                        ShowMessage(litMessage, "تعذّر تأكيد إضافة النوع.")
                        Return
                    End If
                    If Not chkIsActive.Checked Then
                        db.Update_Users_Types_IsActive_ByID(Decimal.ToInt32(result.NewID.Value), False,
                                                            SessionManager.GetInstance.Users.UserID)
                    End If
                    transaction.Commit()
                End Using
            End Using
        Catch ex As SqlException
            ReportError(litMessage, ex)
            Return
        End Try
        Response.Redirect("Manage_Users_Types.aspx?added=1")
    End Sub
End Class


