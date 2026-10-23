Imports Prosto_ERP_ClassLibrary

Public Class ManageMaintenance_Companies
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf BindData)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            BindData()
        End If
    End Sub

    Private Sub BindData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Maintenance_Companies_All().ToList()
            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Maintenance_Companies/AddMaintenance_Companies.aspx")
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Dim id = CInt(e.CommandArgument)

        If e.CommandName = "Edit" Then
            Response.Redirect("/Modules/Maintenance_Companies/EditMaintenance_Companies.aspx?ID=" & id)
            Exit Sub
        End If

        If e.CommandName = "DeleteItem" Then
            Dim userId = SessionManager.GetInstance.Users.UserID

            Using db As New Prosto_ERP_DataClassesDataContext
                db.Update_Maintenance_Companies_IsDeleted_ByID(id, True, userId)
            End Using

            BindData()
        End If
    End Sub
End Class


