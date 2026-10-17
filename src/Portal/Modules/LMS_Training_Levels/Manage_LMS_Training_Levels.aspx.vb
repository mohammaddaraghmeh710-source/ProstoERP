Imports System.Linq

Public Class Manage_LMS_Training_Levels
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrandsDDL()
            FillLevelTypesDDL()
            BindData()
        End If
    End Sub

    Private Sub FillBrandsDDL()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            ' يفترض عندك SP جاهزة للبراند للـ DDL
            Dim brands = db.Select_Brands_All().ToList()

            ddlBrand.DataSource = brands
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using

        ddlBrand.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillLevelTypesDDL()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim types = db.Select_TR_Level_Types_All().ToList()
            ddlLevelType.DataSource = types
            ddlLevelType.DataTextField = "Title_Ar"
            ddlLevelType.DataValueField = "ID"
            ddlLevelType.DataBind()
        End Using

        ddlLevelType.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub BindData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_TR_Training_Levels_All().ToList()
            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Private Sub BindData_Filter()
        Dim brandId As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(ddlBrand.SelectedValue) Then
            brandId = Convert.ToInt32(ddlBrand.SelectedValue)
        End If

        Dim levelTypeId As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(ddlLevelType.SelectedValue) Then
            levelTypeId = Convert.ToInt32(ddlLevelType.SelectedValue)
        End If

        Dim kw As String = txtKeyword.Text.Trim()

        Dim isActive As Nullable(Of Boolean) = Nothing
        If ddlStatus.SelectedValue = "1" Then isActive = True
        If ddlStatus.SelectedValue = "0" Then isActive = False

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            ' ✅ توقيع SP أصبح: (BrandID, LevelTypeID, Keyword, IsActive)
            Dim data = db.Select_TR_Training_Levels_Filter(
                brandId,
                levelTypeId,
                If(String.IsNullOrWhiteSpace(kw), Nothing, kw),
                If(isActive.HasValue, CType(isActive.Value, Boolean?), Nothing)
            ).ToList()

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_Training_Levels/Add_LMS_Training_Levels.aspx")
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindData_Filter()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        ddlBrand.SelectedIndex = 0
        ddlLevelType.SelectedIndex = 0
        txtKeyword.Text = ""
        ddlStatus.SelectedValue = "-1"
        BindData()
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Dim id As Integer = CInt(e.CommandArgument)

        If e.CommandName = "Edit" Then
            Response.Redirect("/Modules/LMS_Training_Levels/Edit_LMS_Training_Levels.aspx?ID=" & id)
            Exit Sub
        End If

        If e.CommandName = "DeleteItem" Then
            Dim userId = SessionManager.GetInstance.Users.UserID

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                db.Update_TR_Training_Levels_IsDeleted_ByID(id, True, userId)
            End Using

            ' keep filters
            BindData_Filter()
        End If
    End Sub

End Class
