Imports System.Data
Public Class ManageInformationPages
    Inherits InformationPagesPage
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e) : RequireAdmin()
    End Sub
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Request.QueryString("saved") = "1" Then litMessage.Text = "<div class=""alert alert-success"">تم حفظ التغييرات. تغييرات صلاحيات الاطلاع مستقلة عن إصدارات المحتوى.</div>"
            BindPages()
        End If
    End Sub
    Private Sub BindPages()
        Try
            lstPages.DataSource = InformationPagesData.Query("dbo.Select_Information_Pages", InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                InformationPagesData.P("@Manage", SqlDbType.Bit, True), InformationPagesData.P("@Deleted", SqlDbType.Bit, ddlDeleted.SelectedValue = "1"),
                InformationPagesData.P("@Search", SqlDbType.NVarChar, txtSearch.Text.Trim(), 250))
            lstPages.DataBind()
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
    End Sub
    Protected Sub Search_Click(sender As Object, e As EventArgs)
        BindPages()
    End Sub
    Protected Sub Page_Command(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName <> "SoftDelete" Then Return
        RequireAdmin()
        Try
            Dim values = CStr(e.CommandArgument).Split(":"c)
            InformationPagesData.Query("dbo.Delete_Information_Page", InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                InformationPagesData.P("@ID", SqlDbType.Int, Integer.Parse(values(0))), InformationPagesData.P("@ExpectedVersion", SqlDbType.Int, Integer.Parse(values(1))))
            litMessage.Text = "<div class=""alert alert-success"">تم حذف الصفحة منطقيًا. الإصدارات والسجلات محفوظة في الأرشيف.</div>"
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
        BindPages()
    End Sub
End Class
