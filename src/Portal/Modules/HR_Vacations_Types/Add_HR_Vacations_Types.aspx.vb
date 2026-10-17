Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class Add_HR_Vacations_Types
    Inherits HRTypePageBase

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim coreID As Integer
        Dim maxValue As Decimal
        If Not ReadValues(txtCoreID, txtNameAR, txtNameEn, txtMaxValue, False, litMessage, coreID, maxValue) Then Return
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                Dim result =
                        db.Insert_HR_Vacations_Types(coreID, txtNameAR.Text, txtNameEn.Text, CInt(maxValue),
                                                     SessionManager.GetInstance.Users.UserID, chkIsActive.Checked).
                        FirstOrDefault()
                If result Is Nothing Then
                    ShowMessage(litMessage, "تعذّر تأكيد إضافة العنصر.")
                    Return
                End If
            End Using
        Catch ex As SqlException
            ShowDatabaseError(litMessage, ex)
            Return
        End Try
        Response.Redirect("Manage_HR_Vacations_Types.aspx?added=1")
    End Sub
End Class

