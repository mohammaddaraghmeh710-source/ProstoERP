Imports Prosto_ERP_ClassLibrary

Public Class EditWorkGuide_User_Category_Role
    Inherits HRTypePageBase

    Private CurrentUserID As Integer
    Private CurrentBrandID As Integer
    Private CurrentRoleID As Integer

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Request.QueryString("CustomerID") Is Nothing _
           OrElse Request.QueryString("BrandID") Is Nothing _
           OrElse Request.QueryString("RoleID") Is Nothing _
           OrElse Not Integer.TryParse(Request.QueryString("CustomerID"), CurrentUserID) _
           OrElse Not Integer.TryParse(Request.QueryString("BrandID"), CurrentBrandID) _
           OrElse Not Integer.TryParse(Request.QueryString("RoleID"), CurrentRoleID) Then

            Response.Redirect("/Modules/WorkGuide_User_Category_Roles/ManageWorkGuide_User_Category_Roles.aspx")
            Return

        End If

        If Not Page.IsPostBack Then
            FillBrands()
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

            ddlBrand.Items.Insert(0, New ListItem("اختر العلامة التجارية", "0"))

        End Using
    End Sub

    Private Sub FillUsers(Optional selectedUserID As Integer? = Nothing)
        CustomerPortalData.BindOptions(ddlUser, CustomerPortalData.AdminGuide("customers"), "اختر العميل")
        If selectedUserID.HasValue AndAlso ddlUser.Items.FindByValue(selectedUserID.Value.ToString()) IsNot Nothing Then _
            ddlUser.SelectedValue = selectedUserID.Value.ToString()
    End Sub

    Private Sub FillCategories(selectedCategoryIDs As List(Of Integer))

        lstCategories.Items.Clear()

        If ddlBrand.SelectedValue Is Nothing OrElse ddlBrand.SelectedValue = "0" Then
            Return
        End If

        Dim BrandID = CInt(ddlBrand.SelectedValue)

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim categories = db.Select_Work_Guide_Categories_Tree_ByBrand(BrandID, Nothing).ToList()

            For Each item In categories

                Dim listItem As New ListItem(item.Tree_Title_Ar, item.ID.ToString())
                listItem.Attributes("data-parent") = Convert.ToString(item.Parent_ID)
                listItem.Attributes("data-name") = item.Title_Ar
                listItem.Attributes("data-path") = item.Full_Path_Ar

                If selectedCategoryIDs IsNot Nothing AndAlso selectedCategoryIDs.Contains(CInt(item.ID)) Then
                    listItem.Selected = True
                End If

                lstCategories.Items.Add(listItem)

            Next

        End Using
    End Sub

    Private Sub FillRoles(Optional selectedRoleID As Integer? = Nothing)

        ddlRole.Items.Clear()
        ddlRole.Items.Insert(0, New ListItem("اختر الدور / الصلاحية", "0"))

        Using db As New Prosto_ERP_DataClassesDataContext

            Dim roles = db.Select_Work_Guide_Roles_All().ToList()

            For Each item In roles
                Dim roleItem As New ListItem(item.Title_Ar, item.ID.ToString())
                Dim permissions = db.Select_Work_Guide_Role_Permissions_ByRoleID(item.ID).FirstOrDefault()
                If permissions IsNot Nothing Then
                    roleItem.Attributes("data-permissions") =
                        If(permissions.Can_View_Document.GetValueOrDefault(), "عرض الوثائق", "دون عرض الوثائق") &
                        If(permissions.Can_Print_Document.GetValueOrDefault(), " · طباعة", " · دون طباعة") &
                        If _
                            (permissions.Can_Download_Document.GetValueOrDefault(), " · تحميل حسب إعداد الملف",
                             " · دون تحميل")
                End If
                ddlRole.Items.Add(roleItem)
            Next

        End Using

        If selectedRoleID.HasValue AndAlso ddlRole.Items.FindByValue(selectedRoleID.Value.ToString()) IsNot Nothing Then
            ddlRole.SelectedValue = selectedRoleID.Value.ToString()
        End If
    End Sub

    Private Sub FillData()

        lblError.Visible = False
        lblError.Text = ""

        Try

            ddlBrand.SelectedValue = CurrentBrandID.ToString()

            FillUsers(CurrentUserID)
            FillRoles(CurrentRoleID)

            Dim selectedCategoryIDs As New List(Of Integer)

            Dim currentPermissions = CustomerPortalData.AdminGuide("details", CurrentUserID, CurrentBrandID,
                                                                   CurrentRoleID)
            If currentPermissions.Rows.Count = 0 Then Throw New ArgumentException("التفويض غير متاح")
            selectedCategoryIDs = currentPermissions.AsEnumerable().Select(Function(x) CInt(x("Category_ID"))).ToList()
            cbIsActive.Checked = CBool(currentPermissions.Rows(0)("IsActive"))
            ddlBrand.Enabled = False
            ddlUser.Enabled = False

            FillCategories(selectedCategoryIDs)

        Catch ex As Exception

            lblError.Text = "حدث خطأ أثناء تحميل البيانات: " & ex.Message
            lblError.Visible = True

        End Try
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)

        FillUsers()
        FillCategories(New List(Of Integer))
    End Sub

    Protected Sub cvCategories_ServerValidate(source As Object, args As ServerValidateEventArgs)

        args.IsValid = lstCategories.Items.Cast (Of ListItem)().
            Any(Function(x) x.Selected)
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        If Not Page.IsValid Then
            Return
        End If

        lblError.Visible = False
        lblError.Text = ""

        Try

            Dim NewBrandID = CInt(ddlBrand.SelectedValue)
            Dim NewUserID = CInt(ddlUser.SelectedValue)
            Dim NewRoleID = CInt(ddlRole.SelectedValue)

            Dim selectedCategories = lstCategories.Items.Cast (Of ListItem)().
                    Where(Function(x) x.Selected).
                    Select(Function(x) CInt(x.Value)).
                    Distinct().
                    ToList()

            If selectedCategories.Count = 0 Then
                lblError.Text = "يرجى اختيار تصنيف واحد على الأقل."
                lblError.Visible = True
                Return
            End If

            Dim _
                xml As _
                    New XElement("items",
                                 selectedCategories.Select(Function(id) New XElement("item", New XAttribute("id", id))))
            CustomerPortalData.AdminGuide("edit", CurrentUserID, CurrentBrandID, NewRoleID, CurrentRoleID,
                                          xml.ToString(), cbIsActive.Checked)

            Response.Redirect("/Modules/WorkGuide_User_Category_Roles/ManageWorkGuide_User_Category_Roles.aspx")

        Catch ex As Exception

            lblError.Text = Server.HtmlEncode(CustomerPortalData.ErrorText(ex))
            lblError.Visible = True

        End Try
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)

        Response.Redirect("/Modules/WorkGuide_User_Category_Roles/ManageWorkGuide_User_Category_Roles.aspx")
    End Sub
End Class

