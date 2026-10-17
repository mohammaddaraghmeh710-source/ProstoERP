Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Add_LMS_Training_Levels
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
            FillBrandsDDL()
            FillLevelTypesDDL()
            FillUserTypes()
        End If
    End Sub

    Private Sub FillBrandsDDL()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All().ToList()
            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillLevelTypesDDL()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim types = db.Select_TR_Level_Types_All().ToList()
            ddlLevelType.DataSource = types
            ddlLevelType.DataTextField = "Title_Ar"
            ddlLevelType.DataValueField = "ID"
            ddlLevelType.DataBind()
        End Using
        ddlLevelType.Items.Insert(0, New ListItem("اختر", ""))
    End Sub

    Private Sub FillUserTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim ut = db.Select_User_Types_ForDDL().ToList()
            rptUserTypes.DataSource = ut
            rptUserTypes.DataBind()
        End Using
    End Sub

    Private Function GetSelectedUserTypesCSV() As String
        Dim ids = New List(Of String)()

        For Each it As RepeaterItem In rptUserTypes.Items
            Dim cb = TryCast(it.FindControl("cbUT"), HtmlInputCheckBox)
            Dim hf = TryCast(it.FindControl("hfUTID"), HiddenField)

            If cb IsNot Nothing AndAlso hf IsNot Nothing AndAlso cb.Checked Then
                ids.Add(hf.Value)
            End If
        Next

        Return String.Join(",", ids)
    End Function

    Protected Sub cvUserTypes_ServerValidate(source As Object, args As ServerValidateEventArgs)
        args.IsValid = GetSelectedUserTypesCSV().Length > 0
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        lblMsg.Visible = False
        If Not Page.IsValid Then Return

        Try
            Dim userId = SessionManager.GetInstance.Users.UserID

            Dim brandId As Integer = Convert.ToInt32(ddlBrand.SelectedValue) ' ✅ NEW
            Dim levelTypeId As Integer = Convert.ToInt32(ddlLevelType.SelectedValue)

            Dim orderVal As Nullable(Of Integer) = Nothing
            If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
                Dim o As Integer
                If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
            End If

            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    LevelImagePath = f.Key
                    Exit For
                Next
            End If

            Dim newLevelId = 0
            Dim csvUserTypes As String = GetSelectedUserTypesCSV()

            Using db As New Prosto_ERP_DataClassesDataContext

                ' ✅ توقيع Insert أصبح: (BrandID, LevelTypeID, Level_Image, Title_Ar, Title_En, Summary_Ar, Summary_En, Notes_Ar, Notes_En, Item_Order, AddedUser)
                Dim res = db.Insert_TR_Training_Levels(
                    brandId,
                    levelTypeId,
                    LevelImagePath,
                    txtTitleAr.Text.Trim(),
                    txtTitleEn.Text.Trim(),
                    txtSummaryAr.Text.Trim(),
                    txtSummaryEn.Text.Trim(),
                    If(String.IsNullOrWhiteSpace(txtNotesAr.Text), Nothing, txtNotesAr.Text.Trim()),
                    If(String.IsNullOrWhiteSpace(txtNotesEn.Text), Nothing, txtNotesEn.Text.Trim()),
                    orderVal,
                    userId
                    )

                Dim row = res.Cast (Of Object)().FirstOrDefault()
                If row IsNot Nothing Then
                    Dim p = row.GetType().GetProperty("NewID")
                    If p IsNot Nothing Then
                        newLevelId = Convert.ToInt32(Convert.ToDecimal(p.GetValue(row, Nothing)))
                    End If
                End If

                If newLevelId = 0 Then
                    Throw _
                        New Exception(
                            "لم يتم الحصول على رقم المستوى الجديد (NewID). راجع DBML mapping لــ Insert_TR_Training_Levels.")
                End If

                db.Insert_TR_Level_UserTypes_Bulk(newLevelId, csvUserTypes, userId)
            End Using

            LBLPOP_ModalPopupExtender.Show()

        Catch ex As Exception
            lblMsg.Visible = True
            lblMsg.Text = "حدث خطأ أثناء الحفظ: " & ex.Message
        End Try
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx?added=1")
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


