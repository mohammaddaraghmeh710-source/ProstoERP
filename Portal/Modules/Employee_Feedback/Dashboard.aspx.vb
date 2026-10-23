Imports System.Linq
Imports System.Web
Imports Prosto_ERP_ClassLibrary

Public Class EmployeeFeedbackDashboard
    Inherits EmployeeFeedbackPage
    Protected litMessage As Literal
    Protected litMetrics As Literal
    Protected litDistribution As Literal
    Protected litSources As Literal
    Protected rptLinks As Repeater
    Protected rptRequests As Repeater
    Protected pnlEmpty As Panel
    Private todo As New HashSet(Of Integer)

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireAdmin()
        If IsPostBack Then Return
        Try
            Dim all As List(Of FeedbackRequestRow)
            Using db As New Prosto_ERP_DataClassesDataContext()
                all = db.ExecuteQuery(Of FeedbackRequestRow)("EXEC dbo.Select_Employee_Feedback_Requests @Actor={0},@Mode=2,@Search=N'',@Type=0,@Status=0", ActorID).ToList()
                todo = New HashSet(Of Integer)(db.ExecuteQuery(Of FeedbackRequestRow)("EXEC dbo.Select_Employee_Feedback_Requests @Actor={0},@Mode=3,@Search=N'',@Type=0,@Status=0", ActorID).Select(Function(r) r.ID))
            End Using
            Dim closed = all.Where(Function(r) r.Status = 3).Count()
            litMetrics.Text = "<div class=""row row-cols-2 row-cols-xl-4 g-3 mb-4"">" &
                FeedbackPresentation.Metric("إجمالي الطلبات", all.Count, "bx-collection", "primary", "ManageEmployeeFeedback.aspx") &
                FeedbackPresentation.Metric("الطلبات الفعالة", all.Count - closed, "bx-time-five", "info", "ManageEmployeeFeedback.aspx?view=active") &
                FeedbackPresentation.Metric("بانتظار إجرائك", todo.Count, "bx-task", "warning", "ManageEmployeeFeedback.aspx?view=todo") &
                FeedbackPresentation.Metric("الطلبات المغلقة", closed, "bx-check-circle", "success", "ManageEmployeeFeedback.aspx?view=closed") & "</div>"
            rptLinks.DataSource = New Object() {
                New With {.Title = "متابعة الطلبات", .Description = "جميع الطلبات الواردة من الموظفين والعملاء", .Icon = "bx-conversation", .Color = "primary", .Url = "ManageEmployeeFeedback.aspx"},
                New With {.Title = "أنواع الطلبات", .Description = "إضافة الأنواع وتعديلها وتفعيلها", .Icon = "bx-category", .Color = "info", .Url = "/Modules/Employee_Feedback_Types/ManageEmployeeFeedbackTypes.aspx"},
                New With {.Title = "مواضيع الطلبات", .Description = "تنظيم المواضيع حسب النوع والعلامة التجارية", .Icon = "bx-list-check", .Color = "warning", .Url = "/Modules/Employee_Feedback_Topics/ManageEmployeeFeedbackTopics.aspx"},
                New With {.Title = "الصلاحيات والمستلمون", .Description = "صلاحيات التقديم والتحويل والإغلاق للموظفين", .Icon = "bx-check-shield", .Color = "success", .Url = "/Modules/Employee_Feedback_Permissions/ManageEmployeeFeedbackPermissions.aspx"},
                New With {.Title = "الإحصائيات والتقارير", .Description = "تحليل الحالات والفروع والأنواع ومصادر الطلبات", .Icon = "bx-bar-chart-alt-2", .Color = "primary", .Url = "EmployeeFeedbackReports.aspx"},
                New With {.Title = "سجل المشاهدات والإجراءات", .Description = "متابعة المشاهدة والتقديم والتحويل والإغلاق والتنبيهات", .Icon = "bx-history", .Color = "secondary", .Url = "EmployeeFeedbackLogs.aspx"}
            }
            rptLinks.DataBind()
            litDistribution.Text = Distribution("جديد", all.Where(Function(r) r.Status = 1).Count(), all.Count, "warning") & Distribution("قيد المعالجة", all.Where(Function(r) r.Status = 2).Count(), all.Count, "primary") & Distribution("مغلق", closed, all.Count, "success")
            litSources.Text = Distribution("الموظفون", all.Where(Function(r) r.SourceType = 1).Count(), all.Count, "primary") & Distribution("العملاء", all.Where(Function(r) r.SourceType = 2).Count(), all.Count, "info")
            rptRequests.DataSource = all.OrderBy(Function(r) If(todo.Contains(r.ID), 0, 1)).ThenByDescending(Function(r) r.AddedDate).ThenByDescending(Function(r) r.ID).Take(20).ToList()
            rptRequests.DataBind()
            pnlEmpty.Visible = all.Count = 0
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub
    Private Function Distribution(label As String, count As Integer, total As Integer, color As String) As String
        Dim percent = Math.Round(count * 100.0 / Math.Max(total, 1), 1).ToString(System.Globalization.CultureInfo.InvariantCulture)
        Return "<div class=""mb-3""><div class=""feedback-flex justify-content-between mb-2 small""><span>" & HttpUtility.HtmlEncode(label) & "</span><strong>" & count.ToString() & "</strong></div><div class=""progress"" style=""height:7px""><div class=""progress-bar bg-" & color & """ role=""progressbar"" aria-label=""" & HttpUtility.HtmlAttributeEncode(label) & """ aria-valuenow=""" & percent & """ aria-valuemin=""0"" aria-valuemax=""100"" style=""width:" & percent & "%""></div></div></div>"
    End Function
    Protected Function NeedsAction(id As Object) As Boolean
        Return todo.Contains(Convert.ToInt32(id))
    End Function
    Protected Function DetailLink(id As Object) As String
        Dim value = Convert.ToInt32(id)
        Return "ViewEmployeeFeedback.aspx?ID=" & value.ToString() & If(todo.Contains(value), "", "&report=1")
    End Function
End Class
