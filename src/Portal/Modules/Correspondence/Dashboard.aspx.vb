Imports System.Data
Imports System.Linq
Imports System.Web

Public Class CorrespondenceDashboard
    Inherits PageBase
    Protected litMessage As Literal
    Protected litMetrics As Literal
    Protected litStatusChart As Literal
    Protected litKindChart As Literal
    Protected rptLinks As Repeater

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/Login.aspx") : Return
        ViewStateUserKey = Session.SessionID
        Response.Cache.SetNoStore()
        Try
            Dim options = CorrespondenceData.Query("dbo.Correspondence_Options", CorrespondenceData.P("@Actor", SqlDbType.Int, SessionManager.GetInstance.Users.UserID), CorrespondenceData.P("@IncludeOrganization", SqlDbType.Bit, False))
            If CInt(options.AsEnumerable().Single(Function(r) CStr(r("Kind")) = "role")("ID")) <> 1 Then Throw New HttpException(403, "غير مسموح")
        Catch ex As System.Data.SqlClient.SqlException
            If ex.Number = 51400 Then Throw New HttpException(403, "غير مسموح")
            Throw
        End Try
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return
        Try
            ' Authorized global statistics only; this read never opens a thread or acknowledges messages.
            Dim table = CorrespondenceData.Query("dbo.Correspondence_Browse", CorrespondenceData.P("@Actor", SqlDbType.Int, SessionManager.GetInstance.Users.UserID), CorrespondenceData.P("@All", SqlDbType.Bit, True))
            Dim all = table.AsEnumerable().ToList()
            Dim active = all.Where(Function(r) CStr(r("State")) = "active").Count()
            Dim overdue = all.Where(Function(r) CStr(r("State")) = "overdue").Count()
            Dim closed = all.Where(Function(r) CStr(r("State")) = "closed").Count()
            Dim archived = all.Where(Function(r) CStr(r("State")) = "archived").Count()
            Dim tasks = all.Where(Function(r) Bool(r("RequiresCompletion"))).Count()
            Dim overdueTasks = all.Where(Function(r) CStr(r("State")) = "overdue" AndAlso Bool(r("RequiresCompletion"))).Count()
            Dim noReply = all.Where(Function(r) IsDBNull(r("CloseDate")) AndAlso IsDBNull(r("ArchivedAt")) AndAlso IsDBNull(r("FirstReplyDate"))).Count()
            litMetrics.Text = "<div class=""row row-cols-2 row-cols-xl-4 g-3 mb-3"">" &
                Metric("إجمالي المراسلات", all.Count, "fa-envelope", "primary") &
                Metric("المراسلات الفعالة", active, "fa-comments", "success") &
                Metric("مفتوحة دون رد", noReply, "fa-clock", "warning") &
                Metric("تكليفات متأخرة", overdueTasks, "fa-list-check", "danger") & "</div>"
            rptLinks.DataSource = New Object() {
                New With {.Title = "مراسلاتي", .Description = "المحادثات والردود والتكليفات الخاصة بك", .Icon = "fa-comments", .Color = "primary", .Url = "ManageCorrespondence.aspx"},
                New With {.Title = "إدارة الأولويات", .Description = "إضافة الأولويات وترتيبها وتفعيلها", .Icon = "fa-flag", .Color = "warning", .Url = "Catalogs.aspx?kind=P"},
                New With {.Title = "إدارة أسباب الإنهاء", .Description = "أسباب الإنهاء ونقل المسؤولية", .Icon = "fa-circle-check", .Color = "success", .Url = "Catalogs.aspx?kind=R"}
            }
            rptLinks.DataBind()
            litStatusChart.Text = Donut("حالة المراسلات", {"فعالة", "متأخرة", "منتهية", "مؤرشفة إداريًا"}, {active, overdue, closed, archived}, {"success", "danger", "info", "secondary"})
            litKindChart.Text = Donut("أنواع المراسلات", {"مراسلات عادية", "تكليفات"}, {all.Count - tasks, tasks}, {"primary", "warning"})
        Catch ex As Exception
            litMessage.Text = "<div class=""alert alert-danger"" role=""alert"">" & HttpUtility.HtmlEncode(CorrespondencePresentation.ErrorText(ex)) & "</div>"
        End Try
    End Sub

    Private Shared Function Bool(value As Object) As Boolean
        Return value IsNot Nothing AndAlso Not IsDBNull(value) AndAlso CBool(value)
    End Function
    Private Function Metric(title As String, value As Integer, icon As String, color As String) As String
        Return "<div class=""col""><section class=""card h-100 type-stat-card""><div class=""card-body p-3 type-flex align-items-center justify-content-between gap-2""><div><span class=""text-muted small"">" & HttpUtility.HtmlEncode(title) & "</span><div class=""type-stat-count"">" & value.ToString() & "</div></div><span class=""type-stat-icon rounded bg-label-" & color & """><i class=""fa-solid " & icon & """ aria-hidden=""true""></i></span></div></section></div>"
    End Function
    Private Function Donut(title As String, labels As String(), values As Integer(), colors As String()) As String
        If values.Sum() = 0 Then Return "<div class=""text-center text-muted py-5"" role=""status""><i class=""fa-solid fa-chart-pie fs-2 mb-2 d-block"" aria-hidden=""true""></i>لا توجد مراسلات لعرضها.</div>"
        Dim serializer As New System.Web.Script.Serialization.JavaScriptSerializer()
        Dim payload = serializer.Serialize(New With {.labels = labels, .series = values, .colors = colors})
        Dim summary = String.Join("، ", labels.Select(Function(label, index) label & ": " & values(index).ToString()))
        Return "<div data-correspondence-donut='" & HttpUtility.HtmlAttributeEncode(payload) & "' role=""img"" aria-label=""" & HttpUtility.HtmlAttributeEncode(title & " — " & summary) & """></div>"
    End Function
End Class
