

Public Class CircularsIndex
    Inherits CircularsView
    Protected WithEvents litStats As Literal, litPaging As Literal
    Protected WithEvents txtSearch As TextBox, chkUnread As CheckBox, lstCirculars As ListView
    Protected WithEvents btnSearch As LinkButton, btnPrev As LinkButton, btnNext As LinkButton

    Private Property CurrentPage As Integer
        Get
            Return If(ViewState("CurrentPage") Is Nothing, 1, CInt(ViewState("CurrentPage")))
        End Get
        Set
            ViewState("CurrentPage") = Math.Max(1, value)
        End Set
    End Property

    Protected Sub LoadList(sender As Object, e As EventArgs) Handles Me.Load
        If Request.QueryString("admin") = "1" Then RequireAdmin()
        If Not IsPostBack Then
            txtSearch.Text = If(Request.QueryString("search"), "")
            chkUnread.Checked = Request.QueryString("unread") = "1"
            Dim requestedPage As Integer
            If Integer.TryParse(Request.QueryString("page"), requestedPage) AndAlso requestedPage <= 100000 Then _
                CurrentPage = requestedPage
            BindRows()
        End If
    End Sub

    Protected Function CardUrl(id As Object, action As String) As String
        Return _
            "Index.aspx?ID=" & Convert.ToInt32(id).ToString() & If(AdminMode, "&amp;admin=1", "") & "&amp;action=" &
            action & "&amp;search=" & Server.UrlEncode(txtSearch.Text) & "&amp;unread=" &
            If(chkUnread.Checked, "1", "0") & "&amp;page=" & CurrentPage.ToString()
    End Function

    Private Sub BindRows()
        Try
            Dim data = CircularsData.Query("dbo.Circular_List", CircularsData.P("@Actor", SqlDbType.Int, Actor),
                                           CircularsData.P("@Admin", SqlDbType.Bit, AdminMode),
                                           CircularsData.P("@Search", SqlDbType.NVarChar, txtSearch.Text.Trim(), 250),
                                           CircularsData.P("@UnreadOnly", SqlDbType.Bit, chkUnread.Checked),
                                           CircularsData.P("@Page", SqlDbType.Int, CurrentPage),
                                           CircularsData.P("@PageSize", SqlDbType.Int, 25))
            Dim counts = data.Tables(0).Rows(0)
            litStats.Text = "<div class='row g-3 mb-3'>" &
                            Metric("إجمالي التعاميم", counts("Total"), "bx-broadcast", "primary") &
                            Metric("غير المقروءة", counts("Unread"), "bx-envelope", "warning") &
                            Metric("التعاميم الفعالة", counts("Active"), "bx-check-shield", "success") & "</div>"
            lstCirculars.DataSource = data.Tables(2)
            lstCirculars.DataBind()
            Dim total = CInt(data.Tables(1).Rows(0)("TotalItems"))
            litPaging.Text = "<span class='small text-muted'>" & total.ToString() & " تعميم · الصفحة " &
                             CurrentPage.ToString() & "</span>"
            btnPrev.Enabled = CurrentPage > 1
            btnNext.Enabled = CurrentPage*25 < total
        Catch ex As Exception
            Failure(litMessage, ex)
        End Try
    End Sub

    Private Function Metric(title As String, number As Object, icon As String, color As String) As String
        Return _
            "<div class='col-md-4'><div class='card'><div class='card-body py-3 d-flex justify-content-between align-items-center'><div><span class='small text-muted'>" &
            title & "</span><h4 class='mb-0 mt-1'>" & H(number) &
            "</h4></div><span class='avatar'><span class='avatar-initial rounded bg-label-" & color & "'><i class='bx " &
            icon & "'></i></span></span></div></div></div>"
    End Function

    Protected Sub Search(sender As Object, e As EventArgs)
        CurrentPage = 1
        BindRows()
    End Sub

    Protected Sub Previous(sender As Object, e As EventArgs)
        CurrentPage -= 1
        BindRows()
    End Sub

    Protected Sub NextPage(sender As Object, e As EventArgs)
        CurrentPage += 1
        BindRows()
    End Sub
End Class

Public Class CircularsLegacyRedirect
    Inherits CircularsPage

    Protected Sub RedirectToWorkspace(sender As Object, e As EventArgs) Handles Me.Load
        Response.Redirect(
            "Index.aspx?" & If(PageID > 0, "ID=" & PageID.ToString(), "new=1") & If(IsAdministrator, "&admin=1", "") &
            "&action=view", False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class


