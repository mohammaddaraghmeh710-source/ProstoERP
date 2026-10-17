Imports Prosto_ERP_ClassLibrary

Public Class ManageWorkGuideRoles
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillData()
        End If
    End Sub

    Private Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim Data = db.Select_Work_Guide_Roles_All().AsQueryable()
            Data = Data.OrderByDescending(Function(x) x.ID)

            lstData.DataSource = Data.ToList()
            lstData.DataBind()
        End Using
    End Sub

    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName

                    Case "Edit"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/Modules/WorkGuide_Roles/EditWorkGuideRole.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID = CType(e.CommandArgument, Integer)
                        db.Update_Work_Guide_Role_IsDelete_ByID(ID, True, SessionManager.GetInstance.Users.UserID)
                        FillData()

                End Select

            Catch ex As Exception
            End Try
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/WorkGuide_Roles/AddWorkGuideRole.aspx")
    End Sub
End Class

