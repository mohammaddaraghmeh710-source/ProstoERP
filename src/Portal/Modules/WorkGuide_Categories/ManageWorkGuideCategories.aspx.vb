Imports System.Linq

Public Class ManageWorkGuideCategories
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

            ddlBrand.Items.Insert(0, New ListItem("جميع العلامات التجارية", "0"))
        End Using
    End Sub

    Private Sub FillData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            Dim BrandID As Integer? = Nothing

            If ddlBrand.SelectedValue IsNot Nothing AndAlso ddlBrand.SelectedValue <> "0" Then
                BrandID = CInt(ddlBrand.SelectedValue)
            End If

            Dim Data = db.Select_Work_Guide_Categories_All(BrandID).AsQueryable()
            Data = Data.OrderByDescending(Function(x) x.ID)

            lstData.DataSource = Data.ToList()
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillData()
    End Sub

    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName

                    Case "Edit"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        Response.Redirect("/Modules/WorkGuide_Categories/EditWorkGuideCategory.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        db.Update_Work_Guide_Category_IsDelete_ByID(ID, True, SessionManager.GetInstance.Users.UserID)
                        FillData()

                End Select

            Catch ex As Exception
            End Try
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Categories/AddWorkGuideCategory.aspx")
    End Sub

End Class