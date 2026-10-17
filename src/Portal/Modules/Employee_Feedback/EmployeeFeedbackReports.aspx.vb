Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class EmployeeFeedbackReports
    Inherits EmployeeFeedbackPage
    Private Const ListMode As Integer=2
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        If ListMode=2 Then RequireAdmin()
        pnlReport.Visible=ListMode=2
        lnkNew.Visible={2,3,4}.Contains(ActorType) AndAlso ListMode<>2
        If Not IsPostBack Then
            Try
                EmployeeFeedbackCatalog.FillTypes(ddlType,ActorID,2,"الكل")
                ddlBrand.Items.Add(New ListItem("الكل","0")) : ddlBranch.Items.Add(New ListItem("الكل","0")) : ddlShift.Items.Add(New ListItem("الكل","0"))
                If ListMode=2 Then
                    Using db As New Prosto_ERP_DataClassesDataContext()
                        For Each b In db.Select_Brands_All() : ddlBrand.Items.Add(New ListItem(b.Title_Ar,b.ID.ToString())) : Next
                        For Each b In db.Select_Branches_All() : ddlBranch.Items.Add(New ListItem(b.Title_Ar,b.ID.ToString())) : Next
                        For Each s In db.Select_Shift_All() : ddlShift.Items.Add(New ListItem(s.Title_Ar,s.ID.ToString())) : Next
                    End Using
                End If
                For Each entry In New Dictionary(Of String,DropDownList) From {{"type",ddlType},{"status",ddlStatus},{"identity",ddlIdentity},{"brand",ddlBrand},{"branch",ddlBranch},{"source",ddlSource}}
                    Dim value=Request.QueryString(entry.Key)
                    If value IsNot Nothing AndAlso entry.Value.Items.FindByValue(value) IsNot Nothing Then entry.Value.SelectedValue=value
                Next
                txtFrom.Text=If(Request.QueryString("from"),"") : txtTo.Text=If(Request.QueryString("to"),"")
                FillData()
            Catch ex As Exception : ShowError(ex) : End Try
        End If
    End Sub
    Private Function ReadDate(value As String) As DateTime?
        If String.IsNullOrWhiteSpace(value) Then Return Nothing
        Dim result As DateTime
        If Not DateTime.TryParseExact(value,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,result) Then Throw New ArgumentException("أدخل تاريخًا صحيحًا.")
        Return result
    End Function
    Private Function Rows() As List(Of FeedbackRequestRow)
        Dim fromDate=ReadDate(txtFrom.Text),toDate=ReadDate(txtTo.Text)
        If fromDate.HasValue AndAlso toDate.HasValue AndAlso fromDate>toDate Then Throw New ArgumentException("تاريخ البداية يجب ألا يتجاوز تاريخ النهاية.")
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of FeedbackRequestRow)("DECLARE @StartDate date=CONVERT(date,NULLIF({6},N'')); DECLARE @EndDate date=CONVERT(date,NULLIF({7},N'')); EXEC dbo.Select_Employee_Feedback_Requests @Actor={0},@Mode=2,@Search={1},@Type={2},@Status={3},@Brand={4},@Branch={5},@Shift=0,@From=@StartDate,@To=@EndDate,@Identity={8},@Source={9}",ActorID,txtSearch.Text.Trim(),Number(ddlType),Number(ddlStatus),Number(ddlBrand),Number(ddlBranch),If(fromDate.HasValue,fromDate.GetValueOrDefault().ToString("yyyy-MM-dd"),""),If(toDate.HasValue,toDate.GetValueOrDefault().ToString("yyyy-MM-dd"),""),Number(ddlIdentity),Number(ddlSource)).OrderByDescending(Function(r) r.AddedDate).ThenByDescending(Function(r) r.ID).ToList()
        End Using
    End Function
    Private Sub FillData()
        Dim data=Rows() : lstData.DataSource=data : lstData.DataBind() : lblTotal.Text="عدد الطلبات في القائمة: " & data.Count.ToString()
        FillStatistics()
    End Sub
    Protected Sub Brand_Changed(sender As Object,e As EventArgs)
        Try
            ddlBranch.Items.Clear() : ddlBranch.Items.Add(New ListItem("الكل","0"))
            Using db As New Prosto_ERP_DataClassesDataContext()
                If Number(ddlBrand)=0 Then
                    For Each row In db.Select_Branches_All() : ddlBranch.Items.Add(New ListItem(row.Title_Ar,row.ID.ToString())) : Next
                Else
                    For Each row In db.Select_Branches_ByBrandID(Number(ddlBrand)) : ddlBranch.Items.Add(New ListItem(row.Title_Ar,row.ID.ToString())) : Next
                End If
            End Using
            FillData()
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub Reset_Click(sender As Object,e As EventArgs)
        Response.Redirect("EmployeeFeedbackReports.aspx")
    End Sub
    Private Sub FillStatistics()
        Dim rows As List(Of FeedbackStatistic)
        Using db As New Prosto_ERP_DataClassesDataContext()
            rows=db.ExecuteQuery(Of FeedbackStatistic)("DECLARE @StartDate date=CONVERT(date,NULLIF({6},N'')); DECLARE @EndDate date=CONVERT(date,NULLIF({7},N'')); EXEC dbo.Select_Employee_Feedback_Statistics @Actor={0},@Type={1},@Status={2},@Identity={3},@Brand={4},@Branch={5},@From=@StartDate,@To=@EndDate,@Source={8}",ActorID,Number(ddlType),Number(ddlStatus),Number(ddlIdentity),Number(ddlBrand),Number(ddlBranch),txtFrom.Text,txtTo.Text,Number(ddlSource)).ToList()
        End Using
        Dim html As New Text.StringBuilder()
        html.Append("<div class=""row g-4 mb-4"">")
        Dim total=rows.Where(Function(r) r.Dimension="type").Sum(Function(r) r.Total)
        Dim active=rows.Where(Function(r) r.Dimension="status" AndAlso r.Value=4).Sum(Function(r) r.Total)
        Dim closed=rows.Where(Function(r) r.Dimension="status" AndAlso r.Value=3).Sum(Function(r) r.Total)
        Dim index=0
        Dim accents={"primary","warning","success","info"},icons={"bx-file","bx-time-five","bx-check-circle","bx-pie-chart-alt-2"}
        For Each card In New Dictionary(Of String,String) From {{"إجمالي الطلبات",total.ToString()},{"الطلبات الفعالة",active.ToString()},{"الطلبات المنتهية",closed.ToString()},{"نسبة الإغلاق",If(total=0,"0",Math.Round(closed*100.0/Math.Max(1,total),1).ToString()) & "%"}}
            html.Append("<div class=""col-6 col-xl-3""><section class=""card h-100""><div class=""card-body""><div class=""row align-items-center g-2""><div class=""col""><p class=""text-muted mb-2"">" & Server.HtmlEncode(card.Key) & "</p><h3 class=""mb-0"">" & Server.HtmlEncode(card.Value) & "</h3></div><div class=""col-auto""><span class=""avatar""><span class=""avatar-initial rounded bg-label-" & accents(index) & """><i class=""bx " & icons(index) & """ aria-hidden=""true""></i></span></span></div></div></div></section></div>")
            index+=1
        Next
        html.Append("</div><p class=""small text-muted mb-3"">اختر تصنيفًا أو فرعًا لتصفية النتائج. البحث بالعنوان يخص قائمة الطلبات فقط.</p><div class=""row g-3 mb-3"" id=""feedback-dashboard"">")
        Dim today=TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow,TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).Date
        For offset As Integer=-6 To 0
            Dim day=today.AddDays(offset),key=Integer.Parse(day.ToString("yyyyMMdd"))
            If Not rows.Any(Function(r) r.Dimension="day" AndAlso r.Value=key) Then rows.Add(New FeedbackStatistic With {.Dimension="day",.Value=key,.Label=day.ToString("yyyy-MM-dd"),.Total=0})
        Next
        Dim days=rows.Where(Function(r) r.Dimension="day").OrderBy(Function(r) r.Value).ToList()
        Dim weekTotal=days.Sum(Function(r) r.Total),peak=days.OrderByDescending(Function(r) r.Total).First()
        html.Append("<div class=""col-12 col-lg-4""><section class=""card h-100""><div class=""card-header pb-2""><h5 class=""mb-1""><i class=""bx bx-bar-chart-alt-2 text-primary me-2""></i>حركة الطلبات</h5><p class=""small text-muted mb-0"">آخر 7 أيام · بتوقيت الأردن</p></div><div class=""card-body pt-0""><div id=""feedback-chart-day"" role=""img"" aria-label=""الطلبات خلال آخر سبعة أيام""></div><div class=""row g-2 mt-2""><div class=""col""><small class=""text-muted"">إجمالي الأسبوع</small><h4 class=""mb-0"">" & weekTotal.ToString() & "</h4></div><div class=""col""><small class=""text-muted""><i class=""bx bx-trending-up text-success me-1""></i>الأكثر استقبالًا</small><div>" & If(weekTotal=0,"لا توجد طلبات",Server.HtmlEncode(peak.Label) & " · " & peak.Total.ToString() & " طلب") & "</div></div></div></div></section></div>")
        html.Append("<div class=""col-12 col-lg-4""><section class=""card h-100""><div class=""card-header pb-2""><h5 class=""mb-1""><i class=""bx bx-store text-primary me-2""></i>الطلبات حسب الفرع</h5><p class=""small text-muted mb-0"">حصة كل فرع من الطلبات المطابقة</p></div><div class=""card-body pt-2 overflow-auto"" style=""max-height:310px"" id=""feedback-branch-activity"">")
        Dim branchIndex=0,branchColors={"primary","success","warning","info","danger"}
        For Each branch In rows.Where(Function(r) r.Dimension="branch").OrderByDescending(Function(r) r.Total)
            Dim percent=Math.Round(branch.Total*100.0/Math.Max(1,total),1).ToString(System.Globalization.CultureInfo.InvariantCulture),color=branchColors(branchIndex Mod branchColors.Length)
            html.Append("<a class=""d-inline-flex w-100 align-items-center gap-3 mb-3 text-body"" href=""" & Server.HtmlEncode(StatisticLink("branch",branch.Value)) & """><span class=""avatar flex-shrink-0""><span class=""avatar-initial rounded-circle bg-label-" & color & """><i class=""bx bx-store""></i></span></span><span class=""flex-grow-1""><span class=""d-inline-flex w-100 justify-content-between gap-2 mb-2""><span>" & Server.HtmlEncode(branch.Label) & "</span><strong>" & branch.Total.ToString() & "</strong></span><span class=""progress"" style=""height:6px""><span class=""progress-bar bg-" & color & """ role=""progressbar"" aria-label=""" & Server.HtmlEncode(branch.Label) & """ aria-valuenow=""" & percent & """ aria-valuemin=""0"" aria-valuemax=""100"" style=""width:" & percent & "%""></span></span></span></a>")
            branchIndex+=1
        Next
        If branchIndex=0 Then html.Append("<p class=""text-muted small my-4"">لا توجد طلبات مطابقة.</p>")
        html.Append("</div></section></div>")
        Dim labels As New Dictionary(Of String,String) From {{"status","حالة الطلبات"},{"type","أنواع الطلبات"},{"source","مقدّمو الطلبات"},{"identity","الإفصاح عن الهوية"},{"brand","العلامات التجارية"}}
        For Each chart In labels
            Dim compact=chart.Key<>"brand",width=If(compact,"col-md-6 col-lg-4","col-12")
            html.Append("<div class=""col-12 " & width & """><section class=""card h-100""><div class=""card-header py-3""><h5 class=""mb-0"">" & chart.Value & "</h5></div><div class=""card-body pt-0""><div class=""overflow-auto"" style=""max-height:310px""><div id=""feedback-chart-" & chart.Key & """ role=""img"" aria-label=""" & chart.Value & """></div></div>")
            If Not compact Then html.Append("<details><summary class=""small text-muted"">عرض الأرقام</summary>")
            html.Append("<ul class=""list-unstyled mb-0 mt-1"">")
            Dim pointIndex=0
            For Each point In rows.Where(Function(r) r.Dimension=chart.Key).OrderBy(Function(r) r.Value)
                Dim pointColor=If(chart.Key="status",If(point.Value=3,"success","warning"),If(chart.Key="identity",If(pointIndex=0,"primary","secondary"),New String(){"primary","info","warning","success","secondary","danger"}(pointIndex Mod 6)))
                If Not compact Then pointColor="primary"
                Dim href=StatisticLink(chart.Key,point.Value),tag=If(href="","span","a"),link=If(href="",""," href=""" & Server.HtmlEncode(href) & """")
                html.Append("<li><" & tag & link & " class=""d-inline-flex w-100 justify-content-between gap-2 py-1 text-body small""><span><i class=""bx bxs-circle me-2 text-" & pointColor & """ aria-hidden=""true""></i>" & Server.HtmlEncode(point.Label) & "</span><span class=""d-inline-flex gap-2""><strong>" & point.Total.ToString() & "</strong><span class=""text-muted"">" & If(total=0,"0",Math.Round(point.Total*100.0/Math.Max(1,total),1).ToString()) & "%</span></span></" & tag & "></li>")
                pointIndex+=1
            Next
            html.Append("</ul>" & If(compact,"","</details>") & "</div></section></div>")
        Next
        html.Append("</div>") : litStatistics.Text=html.ToString()

        Dim serializer As New System.Web.Script.Serialization.JavaScriptSerializer()
        Dim payload=serializer.Serialize(rows).Replace("<","\u003c").Replace(">","\u003e").Replace("&","\u0026")
        Dim filters=serializer.Serialize(New Dictionary(Of String,String) From {{"type",ddlType.SelectedValue},{"status",ddlStatus.SelectedValue},{"identity",ddlIdentity.SelectedValue},{"brand",ddlBrand.SelectedValue},{"branch",ddlBranch.SelectedValue},{"source",ddlSource.SelectedValue},{"from",txtFrom.Text},{"to",txtTo.Text}}).Replace("<","\u003c")
        Dim script=<script><![CDATA[
window.addEventListener('load', function () {
  const rows = __ROWS__, filters = __FILTERS__;
  const theme = typeof isDarkStyle !== 'undefined' && isDarkStyle ? config.colors_dark : config.colors;
  const palette = [config.colors.primary, config.colors.info, config.colors.warning, config.colors.success, config.colors.secondary, config.colors.danger];
  ['day', 'status', 'type', 'source', 'identity', 'brand'].forEach(function (dimension) {
    const data = rows.filter(x => x.Dimension === dimension).sort((a, b) => a.Value - b.Value);
    const largest = Math.max(0, ...data.map(x => x.Total)), ticks = Math.min(4, largest), axisMax = ticks ? Math.ceil(largest / ticks) * ticks : 1;
    const donut = ['type', 'status', 'source', 'identity'].includes(dimension);
    const horizontal = ['branch', 'brand'].includes(dimension);
    const total = data.reduce((sum, point) => sum + point.Total, 0);
    const colors = dimension === 'status' ? data.map(x => x.Value === 3 ? config.colors.success : config.colors.warning)
      : dimension === 'identity' ? [config.colors.primary, config.colors.secondary] : palette;
    const node = document.querySelector('#feedback-chart-' + dimension);
    if (!total && dimension !== 'day') {
      node.className = 'text-center text-muted py-5';
      node.textContent = 'لا توجد بيانات مطابقة';
      return;
    }
    const options = {
      chart: {
        type: donut ? 'donut' : 'bar', height: donut ? 160 : (horizontal ? Math.max(180, data.length * 48) : 280),
        parentHeightOffset: 0, toolbar: { show: false }, fontFamily: 'inherit', foreColor: theme.axisColor,
        events: { dataPointSelection: function (event, context, selection) {
          if (dimension === 'day' || selection.dataPointIndex < 0) return;
          const point = data[selection.dataPointIndex];
          if (!point || point.Value === 0) return;
          const query = new URLSearchParams(filters);
          query.set(dimension, point.Value);
          window.location.href = 'EmployeeFeedbackReports.aspx?' + query.toString();
        } }
      },
      series: donut ? data.map(x => x.Total) : [{ name: 'عدد الطلبات', data: data.map(x => x.Total) }],
      labels: data.map(x => x.Label), colors: horizontal ? [config.colors.primary] : colors,
      legend: { show: false }, dataLabels: { enabled: false },
      stroke: { width: 0 },
      plotOptions: {
        pie: { expandOnClick: false, donut: { size: '86%', labels: {
          show: true,
          name: { offsetY: 22, color: theme.axisColor, fontSize: '13px' },
          value: { offsetY: -16, color: theme.headingColor, fontSize: '28px', fontWeight: 500 },
          total: { show: true, showAlways: true, label: 'إجمالي الطلبات', color: theme.axisColor, formatter: () => total.toString() }
        } } },
        bar: { horizontal: horizontal, borderRadius: 4, columnWidth: data.length < 4 ? '5%' : '25%', barHeight: '24%',
          colors: { backgroundBarColors: horizontal ? [config.colors_label.primary] : [], backgroundBarRadius: 4 }
        }
      },
      grid: { show: !donut, borderColor: theme.borderColor, strokeDashArray: 3,
        xaxis: { lines: { show: horizontal } }, yaxis: { lines: { show: !horizontal } },
        padding: { top: 0, bottom: 0, left: 8, right: 8 }
      },
      xaxis: { categories: data.map(x => x.Label), min: horizontal ? 0 : undefined,
        max: horizontal ? axisMax : undefined, tickAmount: horizontal ? ticks : undefined,
        axisBorder: { show: false }, axisTicks: { show: false },
        labels: { trim: true, style: { colors: theme.axisColor, fontSize: '12px' },
          formatter: horizontal ? (value => Number(value).toFixed(0)) : undefined }
      },
      yaxis: { min: 0, max: horizontal ? undefined : axisMax, tickAmount: ticks,
        labels: { maxWidth: 170, style: { colors: theme.axisColor, fontSize: '12px' },
          formatter: horizontal ? undefined : (value => Number(value).toFixed(0)) }
      },
      tooltip: { theme: typeof isDarkStyle !== 'undefined' && isDarkStyle ? 'dark' : 'light',
        y: { formatter: value => value + ' طلب' } },
      states: { hover: { filter: { type: 'lighten', value: 0.05 } }, active: { filter: { type: 'none' } } },
      responsive: [{ breakpoint: 576, options: { chart: { height: donut ? 160 : (horizontal ? Math.max(180, data.length * 48) : 240) },
        yaxis: { labels: { maxWidth: 115 } } } }]
    };
    if (dimension === 'day') {
      options.chart.height = 160;
      options.colors = [config.colors.primary];
      options.plotOptions.bar = { columnWidth: '25%', startingShape: 'rounded', endingShape: 'rounded', borderRadius: 5, distributed: true, colors: { backgroundBarColors: [config.colors_label.primary], backgroundBarRadius: 5 } };
      options.grid = { show: false, padding: { top: -15, bottom: 0 } };
      options.xaxis = { categories: data.map(x => new Date(x.Label + 'T12:00:00').toLocaleDateString('ar-JO', { weekday: 'short' })), axisBorder: { show: false }, axisTicks: { show: false }, labels: { style: { colors: theme.axisColor, fontSize: '11px' } } };
      options.yaxis = { min: 0, max: Math.max(1, Math.ceil(largest * 1.25)), labels: { show: false } };
      options.tooltip.x = { formatter: (value, context) => data[context.dataPointIndex].Label };
      options.responsive = [{ breakpoint: 576, options: { chart: { height: 160 } } }];
    }
    new ApexCharts(node, options).render();
  });
});
]]></script>
        Dim chartScript=script.Value.Replace("__ROWS__",payload).Replace("__FILTERS__",filters)
        ScriptManager.RegisterStartupScript(Me,Me.GetType(),"FeedbackStatistics",chartScript,True)
    End Sub
    Private Function StatisticLink(dimension As String,value As Integer) As String
        If dimension="month" OrElse value=0 Then Return ""
        Dim filters As New Dictionary(Of String,String) From {{"type",ddlType.SelectedValue},{"status",ddlStatus.SelectedValue},{"identity",ddlIdentity.SelectedValue},{"brand",ddlBrand.SelectedValue},{"branch",ddlBranch.SelectedValue},{"source",ddlSource.SelectedValue},{"from",txtFrom.Text},{"to",txtTo.Text}}
        filters(dimension)=value.ToString()
        Return "EmployeeFeedbackReports.aspx?" & String.Join("&",filters.Select(Function(entry) entry.Key & "=" & HttpUtility.UrlEncode(entry.Value)))
    End Function
    Protected Function DetailLink(id As Object) As String
        Return "ViewEmployeeFeedback.aspx?ID=" & Convert.ToInt32(id).ToString() & If(ListMode=2,"&report=1","")
    End Function
    Protected Sub Search_Click(sender As Object,e As EventArgs)
        Try : FillData() : Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Private Function Csv(value As String) As String
        If value Is Nothing Then value=""
        If value.Length>0 AndAlso "=+-@".Contains(value.TrimStart().FirstOrDefault()) Then value="'" & value
        Return ChrW(34) & value.Replace(ChrW(34),ChrW(34) & ChrW(34)) & ChrW(34)
    End Function
    Protected Sub Export_Click(sender As Object,e As EventArgs)
        RequireAdmin()
        Try
            Dim output As New Text.StringBuilder("رقم الطلب,النوع,العنوان,مقدم الطلب,المصدر,العلامة التجارية,الفرع,الحالة,تاريخ التقديم" & vbCrLf)
            For Each r In Rows()
                output.AppendLine(String.Join(",",{Csv(r.ID.ToString()),Csv(EmployeeFeedbackData.TypeText(r.Type)),Csv(r.Title),Csv(r.EmployeeName),Csv(EmployeeFeedbackCatalog.SourceName(r.SourceType)),Csv(r.BrandName),Csv(r.BranchName),Csv(EmployeeFeedbackData.StatusText(r.Status)),Csv(CorrespondenceData.DisplayDate(r.AddedDate))}))
            Next
            Response.Clear() : Response.ContentType="text/csv" : Response.ContentEncoding=Text.Encoding.UTF8
            Response.AddHeader("Content-Disposition","attachment; filename=employee-feedback.csv")
            Response.BinaryWrite(Text.Encoding.UTF8.GetPreamble()) : Response.Write(output.ToString()) : Response.End()
        Catch ex As Threading.ThreadAbortException
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
End Class
