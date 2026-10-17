Imports System.Linq
Imports AjaxControlToolkit
Imports System.Web.UI.HtmlControls

Public Class Edit_LMS_Training_Levels
    Inherits PageBase

    Private LevelImagePath As String = Nothing

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
                Response.Redirect("/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx")
            End If

            hfID.Value = id.ToString()

            FillBrandsDDL()
            FillLevelTypesDDL()
            FillUserTypes()
            FillData(id)
            FillSelectedUserTypes(id)

            cbIsActive.Enabled = True
        End If
    End Sub

    Private Sub FillBrandsDDL()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All().ToList()
            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using

        ddlBrand.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillLevelTypesDDL()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim types = db.Select_TR_Level_Types_All().ToList()
            ddlLevelType.DataSource = types
            ddlLevelType.DataTextField = "Title_Ar"
            ddlLevelType.DataValueField = "ID"
            ddlLevelType.DataBind()
        End Using

        ddlLevelType.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillUserTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim ut = db.Select_User_Types_ForDDL().ToList()
            rptUserTypes.DataSource = ut
            rptUserTypes.DataBind()
        End Using
    End Sub

    Private Sub FillData(id As Integer)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim row = db.Select_TR_Training_Levels_ByID(id).FirstOrDefault()
            If row Is Nothing Then
                Response.Redirect("/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx")
                Exit Sub
            End If

            ' ✅ Brand
            ddlBrand.SelectedValue = If(row.BrandID Is Nothing, "", row.BrandID.ToString())

            ddlLevelType.SelectedValue = If(row.LevelTypeID Is Nothing, "", row.LevelTypeID.ToString())
            txtTitleAr.Text = If(row.Title_Ar, "")
            txtTitleEn.Text = If(row.Title_En, "")
            txtSummaryAr.Text = If(row.Summary_Ar, "")
            txtSummaryEn.Text = If(row.Summary_En, "")
            txtNotesAr.Text = If(row.Notes_Ar, "")
            txtNotesEn.Text = If(row.Notes_En, "")
            txtOrder.Text = If(row.Item_Order Is Nothing, "", row.Item_Order.ToString())

            hfLevelImagePath.Value = If(row.Level_Image, "")
            If Not String.IsNullOrWhiteSpace(hfLevelImagePath.Value) Then
                litCurrentImage.Text = "<div class='mt-2'><small class='text-muted'>الصورة الحالية:</small><div><a target='_blank' href='" &
                                       hfLevelImagePath.Value & "'>" & hfLevelImagePath.Value & "</a></div></div>"
            Else
                litCurrentImage.Text = ""
            End If

            cbIsActive.Checked = row.IsActive
        End Using
    End Sub

    Private Sub FillSelectedUserTypes(levelId As Integer)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim selected = db.Select_TR_Level_UserTypes_ByLevelID(levelId).
                        Select(Function(x) x.UserType).ToList()

            For Each it As RepeaterItem In rptUserTypes.Items
                Dim cb = TryCast(it.FindControl("chkUT"), CheckBox)
                Dim hf = TryCast(it.FindControl("hfUTID"), HiddenField)

                If cb IsNot Nothing AndAlso hf IsNot Nothing Then
                    Dim v As Integer = Convert.ToInt32(hf.Value)
                    cb.Checked = selected.Contains(v)
                End If
            Next
        End Using
    End Sub

    Protected Sub cvUserTypes_ServerValidate(source As Object, args As ServerValidateEventArgs)
        args.IsValid = GetSelectedUserTypesCSV().Length > 0
    End Sub

    Private Function GetSelectedUserTypesCSV() As String
        Dim ids As New List(Of String)()

        For Each it As RepeaterItem In rptUserTypes.Items
            Dim chk = TryCast(it.FindControl("chkUT"), CheckBox)
            Dim hf = TryCast(it.FindControl("hfUTID"), HiddenField)

            If chk IsNot Nothing AndAlso hf IsNot Nothing AndAlso chk.Checked Then
                ids.Add(hf.Value)
            End If
        Next

        Return String.Join(",", ids)
    End Function

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        lblMsg.Visible = False
        If Not Page.IsValid Then Return

        Try
            Dim userId = SessionManager.GetInstance.Users.UserID
            Dim id As Integer = Convert.ToInt32(hfID.Value)

            Dim brandId As Integer = Convert.ToInt32(ddlBrand.SelectedValue) ' ✅ NEW
            Dim levelTypeId As Integer = Convert.ToInt32(ddlLevelType.SelectedValue)

            Dim orderVal As Nullable(Of Integer) = Nothing
            If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
                Dim o As Integer
                If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
            End If

            LevelImagePath = hfLevelImagePath.Value

            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    LevelImagePath = f.Key
                    Exit For
                Next
            End If

            Dim csvUserTypes As String = GetSelectedUserTypesCSV()

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                ' ✅ توقيع Update أصبح: (ID, BrandID, LevelTypeID, Level_Image, Title_Ar, Title_En, Summary_Ar, Summary_En, Notes_Ar, Notes_En, Item_Order, IsActive, ModifyUser)
                db.Update_TR_Training_Levels_ByID(
                    id,
                    brandId,
                    levelTypeId,
                    If(String.IsNullOrWhiteSpace(LevelImagePath), Nothing, LevelImagePath),
                    txtTitleAr.Text.Trim(),
                    txtTitleEn.Text.Trim(),
                    txtSummaryAr.Text.Trim(),
                    txtSummaryEn.Text.Trim(),
                    If(String.IsNullOrWhiteSpace(txtNotesAr.Text), Nothing, txtNotesAr.Text.Trim()),
                    If(String.IsNullOrWhiteSpace(txtNotesEn.Text), Nothing, txtNotesEn.Text.Trim()),
                    orderVal,
                    cbIsActive.Checked,
                    userId
                )

                db.Sync_TR_Level_UserTypes(id, csvUserTypes, userId)
            End Using

            LBLPOP_ModalPopupExtender.Show()

        Catch ex As Exception
            lblMsg.Visible = True
            lblMsg.Text = "حدث خطأ أثناء الحفظ: " & ex.Message
        End Try
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx")
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
