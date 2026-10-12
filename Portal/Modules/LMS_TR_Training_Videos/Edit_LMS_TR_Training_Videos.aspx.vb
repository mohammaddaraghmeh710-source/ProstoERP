Imports System.Linq
Imports AjaxControlToolkit

Public Class Edit_LMS_TR_Training_Videos
    Inherits PageBase

    Private VideoImagePath As String = Nothing
    Private VideoAR_path As String = Nothing
    Private VideoEn_path As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            ClearFileSession()
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("ID"), id) Then
                Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx")
            End If

            hfID.Value = id.ToString()

            FillBrandsDDL()
            ' Levels will be filled after we know brand from data
            FillData(id)

            cbIsActive.Enabled = True
        End If
    End Sub

    Private Sub FillBrandsDDL()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_ForDDL().ToList()
            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillLevelsDDL(brandId As Integer)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim lv = db.Select_TR_Training_Levels_ForDDL_ByBrandID(brandId).ToList()
            ddlLevel.DataSource = lv
            ddlLevel.DataTextField = "Title_Ar"
            ddlLevel.DataValueField = "ID"
            ddlLevel.DataBind()
        End Using
        ddlLevel.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId As Integer = 0
        If Not String.IsNullOrWhiteSpace(ddlBrand.SelectedValue) Then
            brandId = Convert.ToInt32(ddlBrand.SelectedValue)
        End If

        FillLevelsDDL(brandId)
    End Sub

    Private Sub FillData(id As Integer)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim row = db.Select_TR_Training_Videos_ByID(id).FirstOrDefault()
            If row Is Nothing Then
                Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx")
                Exit Sub
            End If

            ' نحتاج نعرف Brand من مستوى الفيديو
            Dim levelRow = db.Select_TR_Training_Levels_ByID(row.LevelID).FirstOrDefault()
            Dim brandId As Integer = 0
            If levelRow IsNot Nothing AndAlso levelRow.BrandID IsNot Nothing Then
                brandId = Convert.ToInt32(levelRow.BrandID)
            End If

            ddlBrand.SelectedValue = If(brandId = 0, "", brandId.ToString())

            FillLevelsDDL(brandId)
            ddlLevel.SelectedValue = row.LevelID.ToString()

            txtTitleAr.Text = If(row.Title_Ar, "")
            txtTitleEn.Text = If(row.Title_En, "")
            txtSummaryAr.Text = If(row.Summary_Ar, "")
            txtSummaryEn.Text = If(row.Summary_En, "")
            hfVideoARPath.Value = row.VideoUrl_Ar
            hfVideoEnPath.Value = row.VideoUrl_En


            txtOrder.Text = If(row.Item_Order Is Nothing, "", row.Item_Order.ToString())
            txtDuration.Text = If(row.DurationSeconds Is Nothing, "", row.DurationSeconds.ToString())

            hfVideoImagePath.Value = If(row.Video_Image, "")
            If Not String.IsNullOrWhiteSpace(hfVideoImagePath.Value) Then
                litCurrentImage.Text = "<div class='mt-2'><small class='text-muted'>الصورة الحالية:</small><div><a target='_blank' href='" &
                                       hfVideoImagePath.Value & "'>" & hfVideoImagePath.Value & "</a></div></div>"
            Else
                litCurrentImage.Text = ""
            End If

            cbIsActive.Checked = row.IsActive
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        lblMsg.Visible = False
        If Not Page.IsValid Then Return

        Try
            Dim userId = SessionManager.GetInstance.Users.UserID
            Dim id As Integer = Convert.ToInt32(hfID.Value)

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

            ' ابدأ بالقيمة القديمة
            VideoImagePath = hfVideoImagePath.Value

            ' لو تم رفع صورة جديدة
            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    VideoImagePath = f.Key
                    Exit For
                Next
            End If


            ' نبدأ من القيم القديمة المخزنة
            VideoAR_path = hfVideoARPath.Value
            VideoEn_path = hfVideoEnPath.Value

            ' لو تم رفع فيديو جديد باللغة العربية
            Dim VideoAR = SaveWorkingMethodVideoFromSession()
            If VideoAR IsNot Nothing AndAlso VideoAR.Count > 0 Then
                For Each f In VideoAR
                    VideoAR_path = f.Key
                    Exit For
                Next
            End If

            ' لو تم رفع فيديو جديد باللغة الانجليزية
            Dim VideoEn = SaveEvaluationMethodVideoFromSession()
            If VideoEn IsNot Nothing AndAlso VideoEn.Count > 0 Then
                For Each f In VideoEn
                    VideoEn_path = f.Key
                    Exit For
                Next
            End If

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                db.Update_TR_Training_Videos_ByID(
                    id,
                    levelId,
                    If(String.IsNullOrWhiteSpace(VideoImagePath), Nothing, VideoImagePath),
                    txtTitleAr.Text.Trim(),
                    txtTitleEn.Text.Trim(),
                    If(String.IsNullOrWhiteSpace(txtSummaryAr.Text), Nothing, txtSummaryAr.Text.Trim()),
                    If(String.IsNullOrWhiteSpace(txtSummaryEn.Text), Nothing, txtSummaryEn.Text.Trim()),
                    VideoAR_path,
                    VideoEn_path,
                    orderVal,
                    durationVal,
                    cbIsActive.Checked,
                    userId
                )
            End Using

            LBLPOP_ModalPopupExtender.Show()

        Catch ex As Exception
            lblMsg.Visible = True
            lblMsg.Text = "حدث خطأ أثناء الحفظ: " & ex.Message
        End Try
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_TR_Training_Videos/Manage_LMS_TR_Training_Videos.aspx")
    End Sub

    Protected Sub VideoImageUploader_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub VideoImageUploader_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' فيديو باللغة العربية
    Protected Sub VideoAR_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveWorkingMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub VideoAR_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' فيديو باللغة الانجليزية
    Protected Sub VideoEn_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveEvaluationMethodVideoOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub VideoEn_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

End Class
