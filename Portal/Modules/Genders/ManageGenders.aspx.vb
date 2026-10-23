Public Class ManageGenders
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
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

    Private Sub FillData()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Genders_All().AsQueryable()
            data = data.Where(Function(x) x.IsDeleted = False)
            data = data.OrderByDescending(Function(x) x.ID)
            lstData.DataSource = data.ToList()
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName
                    Case "Edit"
                        Dim id As Integer = CInt(e.CommandArgument)
                        Response.Redirect("/Modules/Genders/EditGenders.aspx?ID=" & id.ToString())

                    Case "DeleteItem"
                        Dim id As Integer = CInt(e.CommandArgument)
                        db.Update_Genders_IsDeleted_ByID(id, True, SessionManager.GetInstance.Users.UserID)
                        FillData()
                End Select

            Catch ex As Exception
                ' يمكنك تسجيل الخطأ إن أحببت
            End Try
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Genders/AddGenders.aspx")
    End Sub

End Class
