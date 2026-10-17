Imports System.Linq
Imports AjaxControlToolkit
Imports System.Web.UI.HtmlControls

Public Class Add_LMS_Training_Level_Types
    Inherits PageBase

    Private LevelImagePath As String = Nothing
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ClearFileSession()
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim userId = SessionManager.GetInstance.Users.UserID

        Dim orderVal As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
            Dim o As Integer
            If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext


            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    LevelImagePath = f.Key
                    Exit For
                Next
            End If

            db.Insert_TR_Level_Types(
                LevelImagePath,
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                If(String.IsNullOrWhiteSpace(txtNotesAr.Text), Nothing, txtNotesAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtNotesEn.Text), Nothing, txtNotesEn.Text.Trim()),
                orderVal,
                userId
            )
        End Using

        Response.Redirect("/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx?added=1")
    End Sub


    Protected Sub LevelImageUploader_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub LevelImageUploader_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

End Class
