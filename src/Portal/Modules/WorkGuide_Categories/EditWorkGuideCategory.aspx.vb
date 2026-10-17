Imports System.Linq

Public Class EditWorkGuideCategory
    Inherits PageBase

    Private CurrentCategoryID As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        CurrentCategoryID = CInt(Request.QueryString("ID"))

        If Not Page.IsPostBack Then
            FillBrands()
            FillData()
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

    'Private Sub FillParentCategories(Optional selectedParentID As Integer? = Nothing)
    '    ddlParentCategory.Items.Clear()
    '    ddlParentCategory.Items.Insert(0, New ListItem("بدون تصنيف أب", "0"))

    '    If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
    '        Return
    '    End If

    '    Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

    '    Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
    '        Dim categories = db.Select_Work_Guide_Categories_All(BrandID).ToList()

    '        For Each item In categories
    '            If item.ID <> CurrentCategoryID Then
    '                ddlParentCategory.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
    '            End If
    '        Next
    '    End Using

    '    If selectedParentID.HasValue AndAlso ddlParentCategory.Items.FindByValue(selectedParentID.Value.ToString()) IsNot Nothing Then
    '        ddlParentCategory.SelectedValue = selectedParentID.Value.ToString()
    '    End If
    'End Sub

    Private Sub FillParentCategories(Optional selectedParentID As Integer? = Nothing)
        ddlParentCategory.Items.Clear()
        ddlParentCategory.Items.Insert(0, New ListItem("بدون تصنيف أب", "0"))

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID As Integer = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, CurrentCategoryID).ToList()

            For Each item In categories
                ddlParentCategory.Items.Add(New ListItem(item.Tree_Title_Ar, item.ID.ToString()))
            Next
        End Using

        If selectedParentID.HasValue AndAlso ddlParentCategory.Items.FindByValue(selectedParentID.Value.ToString()) IsNot Nothing Then
            ddlParentCategory.SelectedValue = selectedParentID.Value.ToString()
        End If
    End Sub

    Private Sub FillData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim item = db.Select_Work_Guide_Category_ByID(CurrentCategoryID).FirstOrDefault()

            If item IsNot Nothing Then
                ddlBrand.SelectedValue = item.Brand_ID.ToString()

                Dim ParentID As Integer? = Nothing
                If item.Parent_ID.HasValue Then
                    ParentID = item.Parent_ID.Value
                End If

                FillParentCategories(ParentID)

                txtTitleAr.Text = item.Title_Ar
                txtTitleEn.Text = item.Title_En
                txtDescriptionAr.Text = item.Description_Ar
                txtDescriptionEn.Text = item.Description_En

                If item.Item_Order.HasValue Then
                    txtItemOrder.Text = item.Item_Order.Value.ToString()
                End If

                cbIsActive.Checked = If(item.IsActive, True, False)
            End If
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
            db.Update_Work_Guide_Category_ByID(
                CurrentCategoryID,
                BrandID,
                ParentID,
                txtTitleAr.Text.Trim(),
                txtTitleEn.Text.Trim(),
                txtDescriptionAr.Text.Trim(),
                txtDescriptionEn.Text.Trim(),
                ItemOrder,
                SessionManager.GetInstance.Users.UserID,
                cbIsActive.Checked
            )
        End Using

        Response.Redirect("/Modules/WorkGuide_Categories/ManageWorkGuideCategories.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Categories/ManageWorkGuideCategories.aspx")
    End Sub

End Class