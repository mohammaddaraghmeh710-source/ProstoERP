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
            NewsData.FillBrands(ddlBrand, "جميع العلامات التجارية")
            BindData()
        End If
    End Sub

    Private Sub BindData()
        lstData.DataSource = NewsData.Listing(SessionManager.GetInstance.Users.UserID)
        lstData.DataBind()
    End Sub
    Private Sub BindData_Filter()
        Dim active As Boolean? = Nothing
        If ddlStatus.SelectedValue = "1" Then active = True
        If ddlStatus.SelectedValue = "0" Then active = False
        Dim brand As Integer? = Nothing
        Dim selected As Integer
        If Integer.TryParse(ddlBrand.SelectedValue, selected) AndAlso selected > 0 Then brand = selected
        lstData.DataSource = NewsData.Listing(SessionManager.GetInstance.Users.UserID, txtKeyword.Text.Trim(), active, brand)
        lstData.DataBind()
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
        ddlBrand.SelectedValue = "0"
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

            If String.IsNullOrWhiteSpace(txtKeyword.Text) AndAlso ddlStatus.SelectedValue = "-1" AndAlso ddlBrand.SelectedValue = "0" Then
                BindData()
            Else
                BindData_Filter()
            End If
        End If
    End Sub
End Class
