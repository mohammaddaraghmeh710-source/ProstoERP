Imports Prosto_ERP_ClassLibrary

Public Class ManageWorkGuide_User_Category_Roles
    Inherits HRTypePageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrands()
            FillUsers()
            FillRoles()
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

            ddlBrand.Items.Insert(0, New ListItem("جميع العلامات التجارية", "0"))

        End Using
    End Sub

    Private Sub FillUsers(Optional selectedUserID As Integer? = Nothing)
        CustomerPortalData.BindOptions(ddlUser, CustomerPortalData.AdminGuide("customers"), "اختر العميل")
        If selectedUserID.HasValue AndAlso ddlUser.Items.FindByValue(selectedUserID.Value.ToString()) IsNot Nothing Then _
            ddlUser.SelectedValue = selectedUserID.Value.ToString()
    End Sub

    Private Sub FillRoles()

        ddlRole.Items.Clear()
        ddlRole.Items.Insert(0, New ListItem("جميع الأدوار", "0"))

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim roles = db.Select_Work_Guide_Roles_All().ToList()

            For Each item In roles
                ddlRole.Items.Add(New ListItem(item.Title_Ar, item.ID.ToString()))
            Next

        End Using
    End Sub

    Private Sub FillData()
        Try
            lstData.DataSource = CustomerPortalData.AdminGuide("groups", CInt(ddlUser.SelectedValue),
                                                               CInt(ddlBrand.SelectedValue), CInt(ddlRole.SelectedValue))
            lstData.DataBind()
        Catch ex As Exception
            lblError.Text = Server.HtmlEncode(CustomerPortalData.ErrorText(ex))
            lblError.Visible = True
        End Try
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)

        FillUsers()
        FillData()
    End Sub

    Protected Sub ddlUser_SelectedIndexChanged(sender As Object, e As EventArgs)

        FillData()
    End Sub

    Protected Sub ddlRole_SelectedIndexChanged(sender As Object, e As EventArgs)

        FillData()
    End Sub

    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand

        Try

            If String.IsNullOrWhiteSpace(Convert.ToString(e.CommandArgument)) Then
                Return
            End If

            Dim values = e.CommandArgument.ToString().Split("|"c)

            If values.Length < 3 Then
                Return
            End If

            Dim UserID = CInt(values(0))
            Dim BrandID = CInt(values(1))
            Dim RoleID = CInt(values(2))

            Select Case e.CommandName

                Case "Edit"

                    Response.Redirect(
                        "/Modules/WorkGuide_User_Category_Roles/EditWorkGuide_User_Category_Role.aspx?CustomerID=" &
                        UserID.ToString() &
                        "&BrandID=" & BrandID.ToString() &
                        "&RoleID=" & RoleID.ToString()
                        )

                Case "DeleteGroup"

                    CustomerPortalData.AdminGuide("delete", UserID, BrandID, RoleID)

                    FillData()

            End Select

        Catch ex As Exception

            lblError.Text = "حدث خطأ أثناء تنفيذ العملية: " & ex.Message
            lblError.Visible = True

        End Try
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)

        Response.Redirect("/Modules/WorkGuide_User_Category_Roles/AddWorkGuide_User_Category_Role.aspx")
    End Sub
End Class

