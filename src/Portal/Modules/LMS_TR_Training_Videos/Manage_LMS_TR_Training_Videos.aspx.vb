Imports Prosto_ERP_ClassLibrary

Public Class Manage_LMS_TR_Training_Videos
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrandsDDL()
            FillLevelsDDL(Nothing)
            BindData()
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

        ddlBrand.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillLevelsDDL(brandId As Nullable(Of Integer))
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim bid As Integer = If(brandId.HasValue, brandId.Value, 0)
            Dim lv = db.Select_TR_Training_Levels_ForDDL_ByBrandID(bid).ToList()

            ddlLevel.DataSource = lv
            ddlLevel.DataTextField = "Title_Ar"
            ddlLevel.DataValueField = "ID"
            ddlLevel.DataBind()
        End Using

        ddlLevel.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(ddlBrand.SelectedValue) Then
            brandId = Convert.ToInt32(ddlBrand.SelectedValue)
        End If

        FillLevelsDDL(brandId)

        ' خيار: مباشرة اعرض نتائج حسب البراند
        BindData_Filter()
    End Sub

    Private Sub BindData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_TR_Training_Videos_All().ToList()
            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Private Sub BindData_Filter()
        Dim brandId As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(ddlBrand.SelectedValue) Then
            brandId = Convert.ToInt32(ddlBrand.SelectedValue)
        End If

        Dim levelId As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(ddlLevel.SelectedValue) Then
            levelId = Convert.ToInt32(ddlLevel.SelectedValue)
        End If

        Dim kw As String = txtKeyword.Text.Trim()

        Dim isActive As Nullable(Of Boolean) = Nothing
        If ddlStatus.SelectedValue = "1" Then isActive = True
        If ddlStatus.SelectedValue = "0" Then isActive = False

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_TR_Training_Videos_Filter(
                brandId,
                levelId,
                If(String.IsNullOrWhiteSpace(kw), Nothing, kw),
                If(isActive.HasValue, CType(isActive.Value, Boolean?), Nothing)
                ).ToList()

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_TR_Training_Videos/Add_LMS_TR_Training_Videos.aspx")
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindData_Filter()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        ddlBrand.SelectedIndex = 0
        FillLevelsDDL(Nothing)
        ddlLevel.SelectedIndex = 0

        txtKeyword.Text = ""
        ddlStatus.SelectedValue = "-1"
        BindData()
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Dim id = CInt(e.CommandArgument)

        If e.CommandName = "Edit" Then
            Response.Redirect("/Modules/LMS_TR_Training_Videos/Edit_LMS_TR_Training_Videos.aspx?ID=" & id)
            Exit Sub
        End If

        If e.CommandName = "DeleteItem" Then
            Dim userId = SessionManager.GetInstance.Users.UserID

            Using db As New Prosto_ERP_DataClassesDataContext
                db.Update_TR_Training_Videos_IsDeleted_ByID(id, True, userId)
            End Using

            BindData_Filter()
        End If
    End Sub
End Class


