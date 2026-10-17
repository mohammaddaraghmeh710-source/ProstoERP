Imports Prosto_ERP_ClassLibrary

Public Class ManageJobTitles
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrands()
            ResetFiltersUI()
            FillData()
        End If
    End Sub

    '========================
    ' Fill Filters
    '========================
    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All.Where(Function(x) x.IsDeleted = False).OrderBy(Function(x) x.ID).ToList()

            ddlBrandFilter.Items.Clear()
            ddlBrandFilter.Items.Add(New ListItem("-- الكل --", "0"))

            For Each b In brands
                ddlBrandFilter.Items.Add(New ListItem(b.Title_Ar, b.ID.ToString()))
            Next
        End Using
    End Sub

    Private Sub FillBranches(brandId As Integer)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim branches = db.Select_Branches_All.
                    Where(Function(x) x.IsDeleted = False AndAlso x.BrandID = brandId).
                    OrderByDescending(Function(x) x.ID).ToList()

            ddlBranchFilter.Items.Clear()
            ddlBranchFilter.Items.Add(New ListItem("-- الكل --", "0"))

            For Each br In branches
                ddlBranchFilter.Items.Add(New ListItem(br.Title_Ar, br.ID.ToString()))
            Next
        End Using
    End Sub

    Private Sub FillDepartments(branchId As Integer)
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim depts = db.Select_Departments_All.
                    Where(Function(x) x.IsDeleted = False AndAlso x.BranchID = branchId).
                    OrderByDescending(Function(x) x.ID).ToList()

            ddlDepartmentFilter.Items.Clear()
            ddlDepartmentFilter.Items.Add(New ListItem("-- الكل --", "0"))

            For Each d In depts
                ddlDepartmentFilter.Items.Add(New ListItem(d.Title_Ar, d.ID.ToString()))
            Next
        End Using
    End Sub

    Private Sub ResetFiltersUI()
        divBranch.Visible = False
        divDepartment.Visible = False

        ddlBrandFilter.SelectedValue = "0"

        ddlBranchFilter.Items.Clear()
        ddlBranchFilter.Items.Add(New ListItem("-- الكل --", "0"))

        ddlDepartmentFilter.Items.Clear()
        ddlDepartmentFilter.Items.Add(New ListItem("-- الكل --", "0"))
    End Sub

    Protected Sub ddlBrandFilter_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId = 0
        Integer.TryParse(ddlBrandFilter.SelectedValue, brandId)

        ddlDepartmentFilter.Items.Clear()
        ddlDepartmentFilter.Items.Add(New ListItem("-- الكل --", "0"))
        divDepartment.Visible = False

        If brandId > 0 Then
            FillBranches(brandId)
            divBranch.Visible = True
        Else
            ddlBranchFilter.Items.Clear()
            ddlBranchFilter.Items.Add(New ListItem("-- الكل --", "0"))
            divBranch.Visible = False
        End If
    End Sub

    Protected Sub ddlBranchFilter_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim branchId = 0
        Integer.TryParse(ddlBranchFilter.SelectedValue, branchId)

        If branchId > 0 Then
            FillDepartments(branchId)
            divDepartment.Visible = True
        Else
            ddlDepartmentFilter.Items.Clear()
            ddlDepartmentFilter.Items.Add(New ListItem("-- الكل --", "0"))
            divDepartment.Visible = False
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        FillData()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        FillBrands()
        ResetFiltersUI()
        FillData()
    End Sub

    '========================
    ' Data
    '========================
    Protected Sub FillData()
        Dim brandId = 0, branchId = 0, deptId = 0
        Integer.TryParse(ddlBrandFilter.SelectedValue, brandId)
        Integer.TryParse(ddlBranchFilter.SelectedValue, branchId)
        Integer.TryParse(ddlDepartmentFilter.SelectedValue, deptId)

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_All().AsQueryable()

            ' Filter by IDs returned from SP (BrandID / BranchID / DepartmentID)
            If brandId > 0 Then
                data = data.Where(Function(x) x.BrandID = brandId)
            End If

            If branchId > 0 Then
                data = data.Where(Function(x) x.BranchID = branchId)
            End If

            If deptId > 0 Then
                data = data.Where(Function(x) x.DepartmentID = deptId)
            End If

            data = data.OrderByDescending(Function(x) x.ID)

            lstData.DataSource = data.ToList()
            lstData.DataBind()
        End Using
    End Sub

    '========================
    ' Commands
    '========================
    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName

                    Case "QRCode"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=jobtitles&ID=" & ID.ToString())

                    Case "Edit"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/jobtitles/EditJobTitles.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID = CType(e.CommandArgument, Integer)
                        db.Update_JobTitles_IsDelete_ByID(ID, True)
                        FillData()

                End Select
            Catch ex As Exception
                ' optional: log
            End Try
        End Using
    End Sub

    Protected Sub lstData_ItemDataBound(sender As Object, e As ListViewItemEventArgs) Handles lstData.ItemDataBound
        If e.Item.ItemType = ListViewItemType.DataItem Then
            ' any extra formatting
        End If
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/modules/jobtitles/AddJobTitles.aspx")
    End Sub
End Class


