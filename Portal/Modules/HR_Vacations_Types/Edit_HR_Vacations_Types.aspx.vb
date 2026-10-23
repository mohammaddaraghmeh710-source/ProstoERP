Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Linq

Public Class Edit_HR_Vacations_Types
    Inherits HRTypePageBase

    Private ReadOnly Property ItemID As Integer
        Get
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("ID"), id) OrElse id <= 0 Then
                SystemAdministrationUI.Redirect(Me, "Manage_HR_Vacations_Types.aspx")
                Return 0
            End If
            Return id
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim id As Integer = ItemID
        If Not IsPostBack Then
            Try
                Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                    Dim row = db.Select_HR_Vacations_Types_ByID(id).FirstOrDefault()
                    If row Is Nothing Then
                        SystemAdministrationUI.Redirect(Me, "Manage_HR_Vacations_Types.aspx?missing=1")
                        Return
                    End If
                    txtCoreID.Text = row.Core_ID.ToString(CultureInfo.InvariantCulture)
                    txtNameAR.Text = row.Name_AR
                    txtNameEn.Text = row.Name_En
                    txtMaxValue.Text = row.Max_Value.ToString(CultureInfo.InvariantCulture)
                    chkIsActive.Checked = row.Is_Active
                End Using
            Catch ex As SqlException
                ShowDatabaseError(litMessage, ex)
                btnSave.Enabled = False
            End Try
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim coreID As Integer
        Dim maxValue As Decimal
        If Not ReadValues(txtCoreID, txtNameAR, txtNameEn, txtMaxValue, False, litMessage, coreID, maxValue) Then Return
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                Dim result = db.Update_HR_Vacations_Types_ByID(ItemID, coreID, txtNameAR.Text, txtNameEn.Text, CInt(maxValue), chkIsActive.Checked, SessionManager.GetInstance.Users.UserID).FirstOrDefault()
                If result Is Nothing OrElse result.AffectedRows <> 1 Then
                    ShowMessage(litMessage, "العنصر غير موجود أو تم حذفه. ارجع إلى صفحة الإدارة.")
                    Return
                End If
            End Using
        Catch ex As SqlException
            ShowDatabaseError(litMessage, ex)
            Return
        End Try
        SystemAdministrationUI.Redirect(Me, "Manage_HR_Vacations_Types.aspx?updated=1")
    End Sub
End Class
