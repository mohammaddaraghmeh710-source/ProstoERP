Imports Prosto_ERP_ClassLibrary
Imports System.Linq
Imports System.Collections.Generic

Public Class Manage_JobTitle_Items
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        SystemAdministrationUI.RegisterRefresh(Me, AddressOf BindData)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then

            FillBrands()
            InitEmptyOrgDrops()
            FillSuppliers()
            FillMaintenanceCompanies()
            FillItemTypes()

            BindData() 'عرض الكل
        End If
    End Sub

#Region "Fill Dropdowns"


    Private Sub FillBrands()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Brands_All().Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBrand.DataSource = data
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub InitEmptyOrgDrops()
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("الكل", ""))
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))
        ddlJobTitleAdvanced.Items.Clear()
        ddlJobTitleAdvanced.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillBranches(Optional brandId As Integer? = Nothing)
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("الكل", ""))

        If Not brandId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(brandId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
        End Using
        ddlBranch.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillDepartments(Optional branchId As Integer? = Nothing)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))

        If Not branchId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Departments_ByBranchID(branchId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlDepartment.DataSource = data
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()
        End Using
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillJobTitles(Optional deptId As Integer? = Nothing)
        ddlJobTitleAdvanced.Items.Clear()
        ddlJobTitleAdvanced.Items.Insert(0, New ListItem("الكل", ""))

        If Not deptId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_ByDepartmentID(deptId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlJobTitleAdvanced.DataSource = data
            ddlJobTitleAdvanced.DataTextField = "Title_Ar"
            ddlJobTitleAdvanced.DataValueField = "ID"
            ddlJobTitleAdvanced.DataBind()
        End Using
        ddlJobTitleAdvanced.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    ' ListItem custom attributes are not restored by DropDownList ViewState on AJAX cascades.
    ' Restore metadata without rebinding the registered values or losing the posted selection.
    Protected Sub SupplierMetadata_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Dim currentAccountId As Integer? = Nothing
        Dim rows As New Dictionary(Of String, System.Data.DataRow)(StringComparer.Ordinal)
        For Each row As System.Data.DataRow In CRMSupplierData.Options(SessionManager.GetInstance.Users.UserID, currentAccountId, True).Rows
            rows(Convert.ToString(row("ID"))) = row
        Next
        For Each optionItem As ListItem In ddlSupplier.Items
            If String.IsNullOrEmpty(optionItem.Value) Then Continue For
            If rows.ContainsKey(optionItem.Value) Then
                Dim row = rows(optionItem.Value)
                optionItem.Attributes("data-brand-ids") = Convert.ToString(row("Brand_IDs"))
                optionItem.Attributes("data-available") = If(Convert.ToBoolean(row("Is_Available")), "1", "0")
            Else
                optionItem.Attributes("data-brand-ids") = ""
                optionItem.Attributes("data-available") = "0"
            End If
        Next
    End Sub

    Private Sub FillSuppliers()
        ddlSupplier.Items.Clear()
        For Each row As System.Data.DataRow In CRMSupplierData.Options(SessionManager.GetInstance.Users.UserID, Nothing, True).Rows
            Dim nameAr = Convert.ToString(row("Name_AR"))
            Dim nameEn = Convert.ToString(row("Name_EN"))
            Dim name = nameAr & If(String.IsNullOrWhiteSpace(nameEn), "", " — " & nameEn)
            Dim item As New ListItem(name, Convert.ToString(row("ID")))
            item.Attributes("data-brand-ids") = Convert.ToString(row("Brand_IDs"))
            item.Attributes("data-available") = If(Convert.ToBoolean(row("Is_Available")), "1", "0")
            ddlSupplier.Items.Add(item)
        Next
        ddlSupplier.Items.Insert(0, New ListItem("جميع الموردين", ""))
    End Sub

    Private Sub FillMaintenanceCompanies()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Maintenance_Companies_All().Where(Function(x) x.IsDeleted = 0).ToList()
            ddlMaintenanceCompany.DataSource = data
            ddlMaintenanceCompany.DataTextField = "Title_Ar"
            ddlMaintenanceCompany.DataValueField = "ID"
            ddlMaintenanceCompany.DataBind()
        End Using
        ddlMaintenanceCompany.Items.Insert(0, New ListItem("الكل", ""))
    End Sub

    Private Sub FillItemTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitle_Items_Types_All().Where(Function(x) x.IsDeleted = 0).ToList()

            ddlItemTypeBasic.DataSource = data
            ddlItemTypeBasic.DataTextField = "Title_Ar"
            ddlItemTypeBasic.DataValueField = "ID"
            ddlItemTypeBasic.DataBind()
            ddlItemTypeBasic.Items.Insert(0, New ListItem("الكل", ""))

            ddlItemTypeAdvanced.DataSource = data
            ddlItemTypeAdvanced.DataTextField = "Title_Ar"
            ddlItemTypeAdvanced.DataValueField = "ID"
            ddlItemTypeAdvanced.DataBind()
            ddlItemTypeAdvanced.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

#End Region

#Region "Cascading Org Events"

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim tmp As Integer

        If Integer.TryParse(ddlBrand.SelectedValue, tmp) Then
            FillBranches(tmp)
        Else
            FillBranches(Nothing)
        End If

        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("الكل", ""))

        ddlJobTitleAdvanced.Items.Clear()
        ddlJobTitleAdvanced.Items.Insert(0, New ListItem("الكل", ""))
    End Sub


    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim tmp As Integer

        If Integer.TryParse(ddlBranch.SelectedValue, tmp) Then
            FillDepartments(tmp)
        Else
            FillDepartments(Nothing)
        End If

        ddlJobTitleAdvanced.Items.Clear()
        ddlJobTitleAdvanced.Items.Insert(0, New ListItem("الكل", ""))
    End Sub


    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        Dim tmp As Integer

        If Integer.TryParse(ddlDepartment.SelectedValue, tmp) Then
            FillJobTitles(tmp)
        Else
            FillJobTitles(Nothing)
        End If
    End Sub

#End Region

#Region "Binding"

    Private Sub BindData()

        Dim toolNumber As String = If(String.IsNullOrWhiteSpace(txtToolNumber.Text), Nothing, txtToolNumber.Text.Trim())
        Dim toolName As String = If(String.IsNullOrWhiteSpace(txtToolName.Text), Nothing, txtToolName.Text.Trim())

        Dim itemTypeId As Integer? = Nothing
        Dim tmp As Integer
        If Integer.TryParse(ddlItemTypeBasic.SelectedValue, tmp) Then itemTypeId = tmp

        ' Advanced
        Dim brandId As Integer? = Nothing
        Dim branchId As Integer? = Nothing
        Dim deptId As Integer? = Nothing
        Dim jobTitleId As Integer? = Nothing
        Dim supplierId As Integer? = Nothing
        Dim maintId As Integer? = Nothing
        Dim itemTypeAdvId As Integer? = Nothing

        If Integer.TryParse(ddlBrand.SelectedValue, tmp) Then brandId = tmp
        If Integer.TryParse(ddlBranch.SelectedValue, tmp) Then branchId = tmp
        If Integer.TryParse(ddlDepartment.SelectedValue, tmp) Then deptId = tmp
        If Integer.TryParse(ddlJobTitleAdvanced.SelectedValue, tmp) Then jobTitleId = tmp
        If Integer.TryParse(ddlSupplier.SelectedValue, tmp) Then supplierId = tmp
        If Integer.TryParse(ddlMaintenanceCompany.SelectedValue, tmp) Then maintId = tmp
        If Integer.TryParse(ddlItemTypeAdvanced.SelectedValue, tmp) Then itemTypeAdvId = tmp


        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitle_Items_Search(
                brandId,
                branchId,
                deptId,
                jobTitleId,
                supplierId,
                maintId,
                If(itemTypeAdvId.HasValue, itemTypeAdvId, itemTypeId),
                toolNumber,
                toolName
                ).ToList()

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

#End Region

#Region "Buttons & Filters"

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items/Add_JobTitle_Items.aspx")
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        ' بحث أساسي
        BindData()
    End Sub

    Protected Sub btnAdvancedSearch_Click(sender As Object, e As EventArgs)
        ' بحث متقدم
        BindData()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs)

        txtToolNumber.Text = ""
        txtToolName.Text = ""

        ddlItemTypeBasic.SelectedIndex = 0
        ddlItemTypeAdvanced.SelectedIndex = 0

        ddlBrand.SelectedIndex = 0
        InitEmptyOrgDrops()

        ddlSupplier.SelectedIndex = 0
        ddlMaintenanceCompany.SelectedIndex = 0

        BindData()
    End Sub


#End Region

#Region "ListView Commands"

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName = "Edit" Then
            Dim id = CInt(e.CommandArgument)
            Response.Redirect("/Modules/JobTitle_Items/Edit_JobTitle_Items.aspx?ID=" & id)
        ElseIf e.CommandName = "PrintQrCode" Then
            Dim id = CInt(e.CommandArgument)
            Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=jobitem&ID=" + id.ToString())
        ElseIf e.CommandName = "DeleteItem" Then
            Dim id = CInt(e.CommandArgument)
            Using db As New Prosto_ERP_DataClassesDataContext
                db.Update_JobTitle_Items_IsDeleted_ByID(id, 1, SessionManager.GetInstance.Users.UserID)
            End Using
            BindData()

        End If
    End Sub

#End Region
End Class


