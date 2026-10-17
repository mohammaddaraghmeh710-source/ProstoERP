Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Edit_LMS_Training_Level_Types
    Inherits PageBase

    Private LevelImagePath As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            ClearFileSession()
            Dim idStr As String = Request.QueryString("ID")
            Dim id As Integer
            If Not Integer.TryParse(idStr, id) Then
                Response.Redirect("/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx")
            End If

            hfID.Value = id.ToString()
            FillData(id)
        End If
    End Sub

    Private Sub FillData(id As Integer)
        Using db As New Prosto_ERP_DataClassesDataContext
            ' ✅ لازم يكون SP مربوط في DBML باسم Select_TR_Level_Types_ByID
            Dim row = db.Select_TR_Level_Types_ByID(id).FirstOrDefault()

            If row Is Nothing Then
                Response.Redirect("/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx")
                Exit Sub
            End If

            txtTitleAr.Text = If(row.Title_Ar, "")
            txtTitleEn.Text = If(row.Title_En, "")
            txtNotesAr.Text = If(row.Notes_Ar, "")
            txtNotesEn.Text = If(row.Notes_En, "")
            txtOrder.Text = If(row.Item_Order Is Nothing, "", row.Item_Order.ToString())
            chkIsActive.Checked = row.IsActive


            hfLevelImagePath.Value = If(row.Image, "")
            If Not String.IsNullOrWhiteSpace(hfLevelImagePath.Value) Then
                litCurrentImage.Text =
                    "<div class='mt-2'><small class='text-muted'>الصورة الحالية:</small><div><a target='_blank' href='" &
                    hfLevelImagePath.Value & "'>" & hfLevelImagePath.Value & "</a></div></div>"
            Else
                litCurrentImage.Text = ""
            End If

        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim userId = SessionManager.GetInstance.Users.UserID
        Dim id As Integer = Convert.ToInt32(hfID.Value)

        Dim orderVal As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
            Dim o As Integer
            If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
        End If

        Using db As New Prosto_ERP_DataClassesDataContext

            LevelImagePath = hfLevelImagePath.Value

            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    LevelImagePath = f.Key
                    Exit For
                Next
            End If

            db.Update_TR_Level_Types_ByID(
                id,
                If(String.IsNullOrWhiteSpace(LevelImagePath), Nothing, LevelImagePath),
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                If(String.IsNullOrWhiteSpace(txtNotesAr.Text), Nothing, txtNotesAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtNotesEn.Text), Nothing, txtNotesEn.Text.Trim()),
                orderVal,
                chkIsActive.Checked,
                userId
                )
        End Using

        Response.Redirect("/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx")
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


