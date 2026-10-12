Public Class ManageShift
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
            Dim Data = db.Select_Shift_All().AsQueryable()
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
                        Response.Redirect("/modules/shift/EditShift.aspx?ID=" & ID.ToString())

                    Case "DeleteItem"
                        Dim ID As Integer = CType(e.CommandArgument, Integer)
                        db.Update_Shift_IsDelete_ByID(ID, True)
                        FillData()

                End Select
            Catch ex As Exception
                ' ممكن تضيف Logging هنا لو حبيت
            End Try
        End Using
    End Sub

    Protected Sub lstData_ItemDataBound(sender As Object, e As ListViewItemEventArgs) Handles lstData.ItemDataBound
        If e.Item.ItemType = ListViewItemType.DataItem Then
            ' لو حاب تنسّق التاريخ مثلاً
        End If
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/modules/shift/AddShift.aspx")
    End Sub

End Class
