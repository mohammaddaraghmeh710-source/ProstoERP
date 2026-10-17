Imports Prosto_ERP_ClassLibrary

Public Class Manage_LMS_Training_Level_Types
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
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
            Dim data = db.Select_TR_Level_Types_All().ToList()
            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Private Sub BindData_Filter()
        Dim kw As String = txtKeyword.Text.Trim()

        Dim isActive As Nullable(Of Boolean) = Nothing
        If ddlStatus.SelectedValue = "1" Then isActive = True
        If ddlStatus.SelectedValue = "0" Then isActive = False

        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_TR_Level_Types_Filter(
                If(String.IsNullOrWhiteSpace(kw), Nothing, kw),
                If(isActive.HasValue, CType(isActive.Value, Boolean?), Nothing)
                ).ToList()

            lstData.DataSource = data
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/LMS_Training_Level_Types/Add_LMS_Training_Level_Types.aspx")
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
        Dim id = CInt(e.CommandArgument)

        If e.CommandName = "Edit" Then
            Response.Redirect("/Modules/LMS_Training_Level_Types/Edit_LMS_Training_Level_Types.aspx?ID=" & id)
            Exit Sub
        End If

        If e.CommandName = "DeleteItem" Then
            Dim userId = SessionManager.GetInstance.Users.UserID

            Using db As New Prosto_ERP_DataClassesDataContext
                ' نفس أسلوب صفحاتكم (Soft Delete)
                db.Update_TR_Level_Types_IsDeleted_ByID(id, userId)
            End Using

            ' إعادة ربط البيانات (مع الحفاظ على البحث إذا كان مستخدم)
            If String.IsNullOrWhiteSpace(txtKeyword.Text) AndAlso ddlStatus.SelectedValue = "-1" Then
                BindData()
            Else
                BindData_Filter()
            End If
        End If
    End Sub
End Class


