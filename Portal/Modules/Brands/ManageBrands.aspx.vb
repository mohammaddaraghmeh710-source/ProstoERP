Public Class ManageBrands
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf FillData)
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
    Protected Sub FillData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim Data = db.Select_Brands_All().AsQueryable()

            'If Not IsNothing(txtName.Text) And txtName.Text <> "" Then
            '    Data = Data.Where(Function(x) x.Title.Contains(txtName.Text))
            'End If

            Data = Data.OrderByDescending(Function(x) x.ID)
            lstData.DataSource = Data.ToList()
            lstData.DataBind()
        End Using
    End Sub
    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName

                    Case "Edit"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/brands/editBrands.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        db.Update_Brands_IsDelete_ByID(ID, True, SessionManager.GetInstance.Users.UserID)
                        FillData()

                    Case "QRCode"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=brands&ID=" & ID.ToString())

                End Select
            Catch ex As Exception
            End Try
        End Using
    End Sub

    Protected Sub lstNews_ItemDataBound(sender As Object, e As ListViewItemEventArgs) Handles lstData.ItemDataBound
        If e.Item.ItemType = ListViewItemType.DataItem Then
            'Dim lblAddedDate As Label = DirectCast(e.Item.FindControl("lblAddedDate"), Label)
            'lblAddedDate.Text = Convert.ToDateTime(lblAddedDate.Text).ToShortDateString()
        End If
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/modules/brands/AddBrands.aspx")
    End Sub
End Class