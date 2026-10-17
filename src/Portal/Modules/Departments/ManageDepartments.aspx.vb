Imports Prosto_ERP_ClassLibrary

Public Class ManageDepartments
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillBrandsFilter()
            FillBranchesFilter(0)
            divBranch.Visible = False
            FillData()
        End If
    End Sub

    '========================
    ' Filters Fill
    '========================
    Private Sub FillBrandsFilter()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim brands = db.Select_Brands_All().ToList()

            ddlBrandFilter.DataSource = brands
            ddlBrandFilter.DataTextField = "Title_Ar"
            ddlBrandFilter.DataValueField = "ID"
            ddlBrandFilter.DataBind()

            ddlBrandFilter.Items.Insert(0, New ListItem("الكل", "0"))
        End Using
    End Sub

    Private Sub FillBranchesFilter(Optional brandId As Integer = 0)
        Using db As New Prosto_ERP_DataClassesDataContext

            Dim branches As Object
            If brandId > 0 Then
                branches = db.Select_Branches_ByBrandID(brandId).ToList()
            Else
                branches = db.Select_Branches_All().ToList()
            End If

            ddlBranchFilter.DataSource = branches
            ddlBranchFilter.DataTextField = "Title_Ar"
            ddlBranchFilter.DataValueField = "ID"
            ddlBranchFilter.DataBind()

            ddlBranchFilter.Items.Insert(0, New ListItem("الكل", "0"))
        End Using
    End Sub

    '========================
    ' Data Bind With Filter
    '========================
    Protected Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext

            Dim brandId As String = ddlBrandFilter.SelectedItem.ToString()
            Dim branchId = 0


            Integer.TryParse(ddlBranchFilter.SelectedValue, branchId)

            Dim data = db.Select_Departments_All().AsQueryable()

            If brandId <> "الكل" Then
                data = data.Where(Function(x) x.BrandTitle_Ar = brandId) ' ✅ فلترة بالـ ID
            End If

            If branchId > 0 Then
                data = data.Where(Function(x) x.BranchID = branchId)
            End If

            data = data.OrderByDescending(Function(x) x.ID)

            lstData.DataSource = data.ToList()
            lstData.DataBind()
        End Using
    End Sub

    '========================
    ' Filters Events
    '========================
    Protected Sub ddlBrandFilter_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim brandId = 0
        Integer.TryParse(ddlBrandFilter.SelectedValue, brandId)

        FillBranchesFilter(brandId)
        ddlBranchFilter.SelectedValue = "0"

        divBranch.Visible = (brandId > 0) ' ✅ تظهر فقط عند اختيار Brand محددة
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        FillData()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        ddlBrandFilter.SelectedValue = "0"
        FillBranchesFilter(0)
        ddlBranchFilter.SelectedValue = "0"
        divBranch.Visible = False
        FillData()
    End Sub

    '========================
    ' ListView Commands
    '========================
    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName
                    Case "QRCode"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=departments&ID=" & ID.ToString())

                    Case "Edit"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/departments/EditDepartments.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID = CType(e.CommandArgument, Integer)
                        db.Update_Departments_IsDelete_ByID(ID, True)
                        FillData()
                End Select

            Catch ex As Exception
                ' add log if needed
            End Try
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/modules/departments/AddDepartments.aspx")
    End Sub
End Class


