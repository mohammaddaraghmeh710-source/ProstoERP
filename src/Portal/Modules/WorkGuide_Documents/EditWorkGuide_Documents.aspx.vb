Imports System.IO
Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class EditWorkGuide_Documents
    Inherits PageBase

    Private CurrentDocumentID As Integer
    Private PDF_File_Path As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        CurrentDocumentID = CInt(Request.QueryString("ID"))

        If Not Page.IsPostBack Then
            ClearFileSession()
            FillBrands()
            FillData()
        End If
    End Sub

    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All().ToList()

            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()

            ddlBrand.Items.Insert(0, New ListItem("اختر العلامة التجارية", "0"))
        End Using
    End Sub

    'Private Sub FillCategories(Optional selectedCategoryID As Integer? = Nothing)
    '    ddlCategory.Items.Clear()
    '    ddlCategory.Items.Insert(0, New ListItem("اختر التصنيف", "0"))

    '    If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
    '        Return
    '    End If

    '    Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

    '    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
    '        Dim categories = db.Select_Work_Guide_Categories_All(BrandID).ToList()

    '        For Each item In categories
    '            ddlCategory.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
    '        Next
    '    End Using

    '    If selectedCategoryID.HasValue AndAlso ddlCategory.Items.FindByValue(selectedCategoryID.Value.ToString()) IsNot Nothing Then
    '        ddlCategory.SelectedValue = selectedCategoryID.Value.ToString()
    '    End If
    'End Sub

    Private Sub FillCategories(Optional selectedCategoryID As Integer? = Nothing)
        ddlCategory.Items.Clear()
        ddlCategory.Items.Insert(0, New ListItem("اختر التصنيف", "0"))

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, Nothing).ToList()

            For Each item In categories
                ddlCategory.Items.Add(New ListItem(item.Tree_Title_Ar, item.ID.ToString()))
            Next
        End Using

        If _
            selectedCategoryID.HasValue AndAlso
            ddlCategory.Items.FindByValue(selectedCategoryID.Value.ToString()) IsNot Nothing Then
            ddlCategory.SelectedValue = selectedCategoryID.Value.ToString()
        End If
    End Sub

    Private Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext

            Dim item = db.Select_Work_Guide_Document_ByID(CurrentDocumentID).FirstOrDefault()

            If item IsNot Nothing Then

                ddlBrand.SelectedValue = item.Brand_ID.ToString()
                FillCategories(item.Category_ID)

                txtTitleAr.Text = item.Title_Ar
                txtTitleEn.Text = item.Title_En
                txtDescriptionAr.Text = item.Description_Ar
                txtDescriptionEn.Text = item.Description_En

                If item.Item_Order.HasValue Then
                    txtItemOrder.Text = item.Item_Order.Value.ToString()
                End If

                cbIsActive.Checked = If(item.IsActive, True, False)

                If Not String.IsNullOrWhiteSpace(item.File_Path) Then
                    lnkCurrentFile.NavigateUrl =
                        "/Modules/WorkGuide_Documents/ViewWorkGuideFile.aspx?type=document&id=" &
                        CurrentDocumentID.ToString()
                    lnkCurrentFile.Visible = True
                Else
                    lnkCurrentFile.Visible = False
                End If

            End If

        End Using
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillCategories()
    End Sub

    Protected Sub WorkGuidePDF_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub WorkGuidePDF_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        If Not Page.IsValid Then
            Return
        End If

        Dim files = SaveFilesFromSession()

        If files IsNot Nothing AndAlso files.Count > 0 Then
            For Each f In files
                PDF_File_Path = f.Key
                Exit For
            Next
        End If

        Dim OriginalFileName As String = Nothing
        Dim StoredFileName As String = Nothing
        Dim FileExtension As String = Nothing
        Dim MimeType As String = Nothing
        Dim FileSize As Long? = Nothing

        If Not String.IsNullOrWhiteSpace(PDF_File_Path) Then

            OriginalFileName = Path.GetFileName(PDF_File_Path)
            StoredFileName = Path.GetFileName(PDF_File_Path)
            FileExtension = ".pdf"
            MimeType = "application/pdf"

            Try
                Dim physicalPath As String = Server.MapPath(PDF_File_Path)
                If File.Exists(physicalPath) Then
                    Dim fileInfo As New FileInfo(physicalPath)
                    FileSize = fileInfo.Length
                End If
            Catch
            End Try

        End If

        Dim BrandID = CInt(ddlBrand.SelectedValue)
        Dim CategoryID = CInt(ddlCategory.SelectedValue)

        Dim ItemOrder As Integer? = Nothing
        If Not String.IsNullOrWhiteSpace(txtItemOrder.Text) Then
            ItemOrder = CInt(txtItemOrder.Text)
        End If

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim oldItem = db.Select_Work_Guide_Document_ByID(CurrentDocumentID).FirstOrDefault()

            If oldItem IsNot Nothing AndAlso Not String.IsNullOrWhiteSpace(PDF_File_Path) Then
                db.Insert_Work_Guide_Document_Version(
                    CurrentDocumentID,
                    oldItem.Version_No,
                    oldItem.Original_File_Name,
                    oldItem.Stored_File_Name,
                    oldItem.File_Path,
                    oldItem.File_Extension,
                    oldItem.Mime_Type,
                    oldItem.File_Size,
                    oldItem.File_Hash,
                    "Old version before file replacement",
                    SessionManager.GetInstance.Users.UserID
                    )
            End If

            db.Update_Work_Guide_Document_ByID(
                CurrentDocumentID,
                BrandID,
                CategoryID,
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                txtDescriptionAr.Text.Trim(),
                txtDescriptionEn.Text.Trim(),
                OriginalFileName,
                StoredFileName,
                PDF_File_Path,
                FileExtension,
                MimeType,
                FileSize,
                Nothing,
                ItemOrder,
                SessionManager.GetInstance.Users.UserID,
                cbIsActive.Checked
                )

        End Using

        Response.Redirect("/Modules/WorkGuide_Documents/ManageWorkGuide_Documents.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Documents/ManageWorkGuide_Documents.aspx")
    End Sub
End Class

