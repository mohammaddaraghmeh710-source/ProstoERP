Imports System.Data.SqlClient
Imports System.Linq

Public Class Add_HR_Leaves_Types
    Inherits HRTypePageBase

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim coreID As Integer
        Dim maxValue As Decimal
        If Not ReadValues(txtCoreID, txtNameAR, txtNameEn, txtMaxValue, True, litMessage, coreID, maxValue) Then Return
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                Dim result = db.Insert_HR_Leaves_Types(coreID, txtNameAR.Text, txtNameEn.Text, maxValue, SessionManager.GetInstance.Users.UserID, chkIsActive.Checked).FirstOrDefault()
                If result Is Nothing Then
                    ShowMessage(litMessage, "تعذّر تأكيد إضافة العنصر.")
                    Return
                End If
            End Using
        Catch ex As SqlException
            ShowDatabaseError(litMessage, ex)
            Return
        End Try
        Response.Redirect("Manage_HR_Leaves_Types.aspx?added=1")
    End Sub
End Class