Imports System.IO
Imports AjaxControlToolkit
Imports System.Linq
Public Class AddWorkGuide_Documents

    Inherits PageBase

    Private PDF_File_Path As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            ClearFileSession()
            FillBrands()
            FillCategories()
        End If

    End Sub

    Private Sub FillBrands()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All().ToList()

            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()

            ddlBrand.Items.Insert(0, New ListItem("اختر العلامة التجارية", "0"))
        End Using
    End Sub

    'Private Sub FillCategories()
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
    'End Sub

    Private Sub FillCategories()
        ddlCategory.Items.Clear()
        ddlCategory.Items.Insert(0, New ListItem("اختر التصنيف", "0"))

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, Nothing).ToList()

            For Each item In categories
                ddlCategory.Items.Add(New ListItem(item.Tree_Title_Ar, item.ID.ToString()))
            Next
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

        If String.IsNullOrWhiteSpace(PDF_File_Path) Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)
        Dim CategoryID As Integer = CInt(ddlCategory.SelectedValue)

        Dim OriginalFileName As String = Path.GetFileName(PDF_File_Path)
        Dim StoredFileName As String = Path.GetFileName(PDF_File_Path)
        Dim FileExtension As String = ".pdf"
        Dim MimeType As String = "application/pdf"
        Dim FileSize As Long? = Nothing

        Try
            Dim physicalPath As String = Server.MapPath(PDF_File_Path)
            If File.Exists(physicalPath) Then
                Dim fileInfo As New FileInfo(physicalPath)
                FileSize = fileInfo.Length
            End If
        Catch
        End Try

        Dim ItemOrder As Integer? = Nothing
        If Not String.IsNullOrWhiteSpace(txtItemOrder.Text) Then
            ItemOrder = CInt(txtItemOrder.Text)
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            db.Insert_Work_Guide_Document(
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
                SessionManager.GetInstance.Users.UserID
            )

        End Using

        LBLPOP_ModalPopupExtender.Show()

    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Documents/ManageWorkGuide_Documents.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Documents/ManageWorkGuide_Documents.aspx")
    End Sub

End Class