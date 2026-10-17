Imports System.Linq

Public Class AddWorkGuideCategory
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrands()
            FillParentCategories()
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

    'Private Sub FillParentCategories()
    '    ddlParentCategory.Items.Clear()
    '    ddlParentCategory.Items.Insert(0, New ListItem("بدون تصنيف أب", "0"))

    '    If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
    '        Return
    '    End If

    '    Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

    '    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
    '        Dim categories = db.Select_Work_Guide_Categories_All(BrandID).ToList()

    '        For Each item In categories
    '            ddlParentCategory.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
    '        Next
    '    End Using
    'End Sub

    Private Sub FillParentCategories()
        ddlParentCategory.Items.Clear()
        ddlParentCategory.Items.Insert(0, New ListItem("بدون تصنيف أب", "0"))

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, Nothing).ToList()

            For Each item In categories
                ddlParentCategory.Items.Add(New ListItem(item.Tree_Title_Ar, item.ID.ToString()))
            Next
        End Using
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillParentCategories()
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        If Not Page.IsValid Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

        Dim ParentID As Integer? = Nothing
        If ddlParentCategory.SelectedValue IsNot Nothing AndAlso ddlParentCategory.SelectedValue <> "0" Then
            ParentID = CInt(ddlParentCategory.SelectedValue)
        End If

        Dim ItemOrder As Integer? = Nothing
        If Not String.IsNullOrWhiteSpace(txtItemOrder.Text) Then
            ItemOrder = CInt(txtItemOrder.Text)
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            db.Insert_Work_Guide_Category(
                BrandID,
                ParentID,
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                txtDescriptionAr.Text.Trim(),
                txtDescriptionEn.Text.Trim(),
                ItemOrder,
                SessionManager.GetInstance.Users.UserID
            )
        End Using

        Response.Redirect("/Modules/WorkGuide_Categories/ManageWorkGuideCategories.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Categories/ManageWorkGuideCategories.aspx")
    End Sub

End Class