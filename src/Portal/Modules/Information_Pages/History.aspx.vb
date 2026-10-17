

Public Class InformationPageHistory
    Inherits InformationPagesPage

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        RequireAdmin()
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return
        lnkLogs.NavigateUrl = "Logs.aspx?ID=" & PageID.ToString()
        BindHistory()
    End Sub

    Private Sub BindHistory()
        Try
            lstVersions.DataSource = InformationPagesData.Query("dbo.Select_Information_Page_History",
                                                                InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                                                InformationPagesData.P("@ID", SqlDbType.Int, PageID))
            lstVersions.DataBind()
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
    End Sub

    Protected Sub Version_Command(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName <> "RestoreVersion" Then Return
        RequireAdmin()
        Try
            Dim values = CStr(e.CommandArgument).Split(":"c)
            InformationPagesData.Query("dbo.Restore_Information_Page",
                                       InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                       InformationPagesData.P("@ID", SqlDbType.Int, PageID),
                                       InformationPagesData.P("@SourceVersion", SqlDbType.Int, Integer.Parse(values(0))),
                                       InformationPagesData.P("@ExpectedVersion", SqlDbType.Int,
                                                              Integer.Parse(values(1))))
            litMessage.Text =
                "<div class=""alert alert-success"">تم استرجاع الإصدار كنسخة جديدة. صلاحيات الاطلاع الحالية لم تتغير.</div>"
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
        BindHistory()
    End Sub
End Class


