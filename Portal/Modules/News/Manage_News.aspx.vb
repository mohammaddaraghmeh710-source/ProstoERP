Imports System.Linq

Public Class Manage_News
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
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
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_News_All().ToList()
            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Private Sub BindData_Filter()
        Dim kw As String = txtKeyword.Text.Trim()

        Dim isActive As Nullable(Of Boolean) = Nothing
        If ddlStatus.SelectedValue = "1" Then isActive = True
        If ddlStatus.SelectedValue = "0" Then isActive = False

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_News_All().ToList()

            If Not String.IsNullOrWhiteSpace(kw) Then
                data = data.Where(Function(x)
                                      Dim tAr = If(x.Title_AR, "")
                                      Dim tEn = If(x.Title_En, "")
                                      Dim bAr = If(x.Brief_Ar, "")
                                      Dim bEn = If(x.Brief_En, "")
                                      Return tAr.Contains(kw) OrElse tEn.Contains(kw) OrElse bAr.Contains(kw) OrElse bEn.Contains(kw)
                                  End Function).ToList()
            End If

            If isActive.HasValue Then
                data = data.Where(Function(x) x.IsActive = isActive.Value).ToList()
            End If

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnAddNew_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/News/Add_News.aspx")
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindData_Filter()
    End Sub

    Protected Sub btnClear_Click(sender As Object, e As EventArgs)
        txtKeyword.Text = ""
        ddlStatus.SelectedValue = "-1"
        BindData()
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Dim pid As Integer = CInt(e.CommandArgument)

        If e.CommandName = "Edit" Then
            Response.Redirect("/Modules/News/Edit_News.aspx?PID=" & pid)
            Exit Sub
        End If

        If e.CommandName = "DeleteItem" Then
            Dim userId = SessionManager.GetInstance.Users.UserID

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
                db.Update_News_IsDeleted_ByID(pid, userId)
            End Using

            If String.IsNullOrWhiteSpace(txtKeyword.Text) AndAlso ddlStatus.SelectedValue = "-1" Then
                BindData()
            Else
                BindData_Filter()
            End If
        End If
    End Sub
End Class