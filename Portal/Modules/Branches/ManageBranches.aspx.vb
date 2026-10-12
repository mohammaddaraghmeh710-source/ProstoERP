Public Class ManageBranches
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
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

            Dim branches = db.Select_Branches_All().AsQueryable()
            branches = branches.OrderByDescending(Function(x) x.ID)


            Dim brands = db.Select_Brands_All().ToList()


            Dim data =
            (From b In branches.ToList()
             Join br In brands On b.BrandID Equals br.ID
             Select New With {
                 .ID = b.ID,
                 .Title_Ar = b.Title_Ar,
                 .Title_En = b.Title_En,
                 .AddedDate = b.AddedDate,
                 .BrandTitle_Ar = br.Title_Ar
             }).ToList()

            lstData.DataSource = data
            lstData.DataBind()

        End Using
    End Sub


    Private Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs) Handles lstData.ItemCommand
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName
                    Case "QRCode"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=branches&ID=" & ID.ToString())

                    Case "Edit"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/branches/EditBranches.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        db.Update_Branches_IsDelete_ByID(ID, True)
                        FillData()

                End Select
            Catch ex As Exception
            End Try
        End Using
    End Sub


    Protected Sub lstData_ItemDataBound(sender As Object, e As ListViewItemEventArgs) Handles lstData.ItemDataBound
        If e.Item.ItemType = ListViewItemType.DataItem Then

            'Dim lbl As Label = DirectCast(e.Item.FindControl("lblAddedDate"), Label)
            'lbl.Text = Convert.ToDateTime(lbl.Text).ToShortDateString()
        End If
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/modules/branches/AddBranches.aspx")
    End Sub

End Class
