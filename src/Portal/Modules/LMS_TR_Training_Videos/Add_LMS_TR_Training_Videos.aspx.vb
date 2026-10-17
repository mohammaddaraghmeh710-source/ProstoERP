Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Add_LMS_TR_Training_Videos
    Inherits PageBase

    Private VideoImagePath As String = Nothing
    Private VideoAR_path As String = Nothing
    Private VideoEn_path As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            ClearFileSession()
            FillBrandsDDL()
            FillLevelsDDL(0)
        End If
    End Sub

    Private Sub FillBrandsDDL()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_ForDDL().ToList()
            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillLevelsDDL(brandId As Integer)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim lv = db.Select_TR_Training_Levels_ForDDL_ByBrandID(brandId).ToList()
            ddlLevel.DataSource = lv
            ddlLevel.DataTextField = "Title_Ar"
            ddlLevel.DataValueField = "ID"
            ddlLevel.DataBind()
        End Using
        ddlLevel.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId = 0
        If Not String.IsNullOrWhiteSpace(ddlBrand.SelectedValue) Then
            brandId = Convert.ToInt32(ddlBrand.SelectedValue)
        End If

        FillLevelsDDL(brandId)
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        lblMsg.Visible = False
        If Not Page.IsValid Then Return

        Try
            Dim userId = SessionManager.GetInstance.Users.UserID

            Dim levelId As Integer = Convert.ToInt32(ddlLevel.SelectedValue)

            Dim orderVal As Nullable(Of Integer) = Nothing
            If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
                Dim o As Integer
                If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
            End If

            Dim durationVal As Nullable(Of Integer) = Nothing
            If Not String.IsNullOrWhiteSpace(txtDuration.Text) Then
                Dim d As Integer
                If Integer.TryParse(txtDuration.Text.Trim(), d) Then durationVal = d
            End If

            ' صورة الفيديو (Uploader -> Session)
            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    VideoImagePath = f.Key
                    Exit For
                Next
            End If


            ' ملفات الفيديو (طريقة العمل)
            Dim VideoAR = SaveWorkingMethodVideoFromSession()
            If VideoAR IsNot Nothing AndAlso VideoAR.Count > 0 Then
                For Each f In VideoAR
                    VideoAR_path = f.Key
                    Exit For
                Next
            End If

            ' ملفات الفيديو (طريقة التقييم)
            Dim VideoEn = SaveEvaluationMethodVideoFromSession()
            If VideoEn IsNot Nothing AndAlso VideoEn.Count > 0 Then
                For Each f In VideoEn
                    VideoEn_path = f.Key
                    Exit For
                Next
            End If


            Dim newId = 0

            Using db As New Prosto_ERP_DataClassesDataContext

                Dim res = db.Insert_TR_Training_Videos(
                    levelId,
                    VideoImagePath,
                    txtTitleAr.Text.Trim(),
                    txtTitleEn.Text.Trim(),
                    If(String.IsNullOrWhiteSpace(txtSummaryAr.Text), Nothing, txtSummaryAr.Text.Trim()),
                    If(String.IsNullOrWhiteSpace(txtSummaryEn.Text), Nothing, txtSummaryEn.Text.Trim()),
                    VideoAR_path,
                    VideoEn_path,
                    orderVal,
                    durationVal,
                    userId
                    )

                Dim row = res.Cast (Of Object)().FirstOrDefault()
                If row IsNot Nothing Then
                    Dim p = row.GetType().GetProperty("NewID")
                    If p IsNot Nothing Then
                        newId = Convert.ToInt32(Convert.ToDecimal(p.GetValue(row, Nothing)))
                    End If
                End If

                If newId = 0 Then
                    Throw _
                        New Exception(
                            "لم يتم الحصول على رقم الفيديو الجديد (NewID). راجع DBML mapping لــ Insert_TR_Training_Videos.")
                End If
            End Using

            LBLPOP_ModalPopupExtender.Show()

        Catch ex As Exception
            lblMsg.Visible = True
            lblMsg.Text = "حدث خطأ أثناء الحفظ: " & ex.Message
        End Try
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx?added=1")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx")
    End Sub

    ' Uploader events
    Protected Sub VideoImageUploader_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub
    'الفيديو باللغة العربية
    Protected Sub VideoAR_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub VideoAR_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    'الفيديو باللغة الانجليزية
    Protected Sub VideoEn_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub VideoEn_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub VideoImageUploader_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub
End Class


