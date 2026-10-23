Imports System.Data
Imports System.Data.SqlClient

Public Class CircularsIndex
    Inherits CircularsPage
    Protected WithEvents litMessage As Literal,litStats As Literal,litPaging As Literal
    Protected employeeCircularReader As CircularReader
    Protected WithEvents txtSearch As TextBox,chkUnread As CheckBox,lstCirculars As ListView
    Protected WithEvents btnSearch As LinkButton,btnPrev As LinkButton,btnNext As LinkButton
    Private Property CurrentPage As Integer
        Get
            Return If(ViewState("CurrentPage") Is Nothing,1,CInt(ViewState("CurrentPage")))
        End Get
        Set(value As Integer)
            ViewState("CurrentPage")=Math.Max(1,value)
        End Set
    End Property
    Protected Sub LoadList(sender As Object,e As EventArgs) Handles Me.Load
        If Request.QueryString("admin")="1" OrElse Request.QueryString("new")="1" OrElse Request.QueryString("action")="edit" OrElse Request.QueryString("action")="logs" Then RequireAdmin()
        If IsAdministrator Then
            Dim destination = "Manage.aspx"
            If Request.QueryString("new")="1" Then
                destination &= "?new=1"
            ElseIf PageID>0 Then
                destination &= If(Request.QueryString("action")="edit","?edit=",If(Request.QueryString("action")="logs","?logs=","?view=")) & PageID.ToString()
            End If
            Response.Redirect(destination,False) : Context.ApplicationInstance.CompleteRequest() : Return
        End If
        If Not IsPostBack Then
            txtSearch.Text=If(Request.QueryString("search"),"")
            chkUnread.Checked=Request.QueryString("unread")="1"
            Dim requestedPage As Integer
            If Integer.TryParse(Request.QueryString("page"),requestedPage) AndAlso requestedPage<=100000 Then CurrentPage=requestedPage
            employeeCircularReader.InitialID=PageID
            BindRows()
        End If
    End Sub
    Protected Function PeriodSummary(item As Object) As String
        Dim row=DirectCast(item,DataRowView).Row
        If row.Table.Columns.Contains("HasPeriod") AndAlso Not CBool(row("HasPeriod")) Then Return "<span class='text-muted'>دون فترة محددة</span>"
        Return "<div class='circular-period-value'><div class='type-flex justify-content-between gap-2 mb-1'><span class='text-muted'>بداية الصلاحية</span><bdi>" & Stamp(row("StartUtc")) & "</bdi></div><div class='type-flex justify-content-between gap-2'><span class='text-muted'>نهاية الصلاحية</span><bdi>" & Stamp(row("EndUtc")) & "</bdi></div></div>"
    End Function
    Private Sub BindRows()
        Try
            Dim data=CircularsData.Query("dbo.Circular_List",CircularsData.P("@Actor",SqlDbType.Int,Actor),CircularsData.P("@Admin",SqlDbType.Bit,False),
                CircularsData.P("@Search",SqlDbType.NVarChar,txtSearch.Text.Trim(),250),CircularsData.P("@UnreadOnly",SqlDbType.Bit,chkUnread.Checked),CircularsData.P("@Page",SqlDbType.Int,CurrentPage),CircularsData.P("@PageSize",SqlDbType.Int,25))
            Dim counts=data.Tables(0).Rows(0)
            litStats.Text="<div class='row g-4 mb-4'>" & Metric("إجمالي التعاميم",counts("Total"),"bx-broadcast","primary") & Metric("غير المقروءة",counts("Unread"),"bx-envelope","warning",True) & Metric("التعاميم الفعالة",counts("Active"),"bx-check-shield","success") & "</div>"
            lstCirculars.DataSource=data.Tables(2):lstCirculars.DataBind()
            Dim total=CInt(data.Tables(1).Rows(0)("TotalItems"))
            litPaging.Text="<span class='small text-muted'>" & total.ToString() & " تعميم · الصفحة " & CurrentPage.ToString() & "</span>"
            btnPrev.Enabled=CurrentPage>1:btnNext.Enabled=CurrentPage*25<total
        Catch ex As Exception
            Failure(litMessage,ex)
        End Try
    End Sub
    Private Function Metric(title As String,number As Object,icon As String,color As String,Optional unread As Boolean=False) As String
        Return "<div class='col-12 col-md-4'><div class='card type-stat-card'><div class='card-body type-flex align-items-start justify-content-between'><div><span>" & title & "</span><div class='type-stat-count'" & If(unread," data-circular-unread-count='1' data-count='" & H(number) & "'","") & ">" & H(number) & "</div></div><span class='badge bg-label-" & color & " type-stat-icon'><i class='bx " & icon & "' aria-hidden='true'></i></span></div></div></div>"
    End Function
    Protected Sub Search(sender As Object,e As EventArgs)
        CurrentPage=1:BindRows()
    End Sub
    Protected Sub Previous(sender As Object,e As EventArgs)
        CurrentPage-=1:BindRows()
    End Sub
    Protected Sub NextPage(sender As Object,e As EventArgs)
        CurrentPage+=1:BindRows()
    End Sub
End Class

Public Class CircularsLegacyRedirect
    Inherits CircularsPage
    Protected Sub RedirectToWorkspace(sender As Object,e As EventArgs) Handles Me.Load
        Response.Redirect("Index.aspx?" & If(PageID>0,"ID=" & PageID.ToString(),"new=1") & If(IsAdministrator,"&admin=1","") & "&action=view",False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
