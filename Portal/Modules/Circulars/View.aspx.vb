Imports System.Data
Imports System.Globalization
Imports System.Xml.Linq
Imports System.Linq

Public Class CircularsView
    Inherits CircularsPage
    Protected WithEvents litMessage As Literal,litDetails As Literal,litAudience As Literal,litFileName As Literal,litFileInfo As Literal,litLogs As Literal,litLogPaging As Literal
    Protected WithEvents pnlContent As Panel,pnlDownload As Panel,pnlEditor As PlaceHolder,pnlLogs As PlaceHolder
    Protected WithEvents txtTitle As TextBox,txtSummary As TextBox,txtDate As TextBox,txtStart As TextBox,txtEnd As TextBox
    Protected WithEvents chkEnabled As CheckBox,chkDownload As CheckBox,ddlAudience As DropDownList,pdfUpload As FileUpload
    Protected WithEvents roles As ListBox,brands As ListBox,branches As ListBox,departments As ListBox,shifts As ListBox
    Protected WithEvents btnSave As LinkButton,btnRefreshLogs As LinkButton,btnLogPrev As LinkButton,btnLogNext As LinkButton
    Private Property LogPage As Integer
        Get
            Return If(ViewState("LogPage") Is Nothing,1,CInt(ViewState("LogPage")))
        End Get
        Set(value As Integer)
            ViewState("LogPage")=Math.Max(1,value)
        End Set
    End Property
    Private Function Lists() As Dictionary(Of String,ListBox)
        Return New Dictionary(Of String,ListBox) From {{"role",roles},{"brand",brands},{"branch",branches},{"department",departments},{"shift",shifts}}
    End Function
    Protected ReadOnly Property HasSelection As Boolean
        Get
            Return PageID>0 OrElse Request.QueryString("new")="1"
        End Get
    End Property
    Protected ReadOnly Property InitialFileAction As String
        Get
            If IsPostBack Then Return ""
            Return If(Request.QueryString("action")="view","view",If(Request.QueryString("action")="download","download",""))
        End Get
    End Property
    Protected Sub LoadWorkspace(sender As Object,e As EventArgs) Handles Me.Load
        If Not HasSelection Then
            pnlContent.Visible=False
            Return
        End If
        If Request.QueryString("admin")="1" OrElse PageID=0 Then RequireAdmin()
        If AdminMode AndAlso (PageID=0 OrElse Request.QueryString("action")="edit") Then
            Response.Redirect("Manage.aspx?" & If(PageID=0,"new=1","edit=" & PageID.ToString()),False)
            Context.ApplicationInstance.CompleteRequest() : pnlContent.Visible=False : Return
        End If
        If IsPostBack Then Return
        pnlEditor.Visible=False:pnlLogs.Visible=AdminMode AndAlso PageID>0
        Try
            If AdminMode AndAlso pnlEditor.Visible Then
                Dim lookup=CircularsData.Query("dbo.Circular_Lookups",CircularsData.P("@Actor",SqlDbType.Int,Actor)).Tables(0)
                For Each lookupRow As DataRow In lookup.Rows
                    Lists()(CStr(lookupRow("Kind"))).Items.Add(New ListItem(CStr(lookupRow("Title")),CStr(lookupRow("ID"))))
                Next
            End If
            If PageID=0 Then
                ViewState("Version")=0
                Dim nowLocal=TimeZoneInfo.ConvertTimeFromUtc(Date.UtcNow,TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time"))
                txtDate.Text=nowLocal.ToString("yyyy-MM-dd")
                txtStart.Text=nowLocal.ToString("yyyy-MM-ddTHH:mm"):txtEnd.Text=nowLocal.AddDays(7).ToString("yyyy-MM-ddTHH:mm")
                Return
            End If
            Dim data=CircularsData.Query("dbo.Circular_Detail",CircularsData.P("@Actor",SqlDbType.Int,Actor),CircularsData.P("@ID",SqlDbType.Int,PageID),CircularsData.P("@Admin",SqlDbType.Bit,AdminMode))
            Dim row=data.Tables(0).Rows(0)
            ViewState("Version")=CInt(row("Version"))
            litDetails.Text="<div class='d-flex flex-wrap justify-content-between gap-2'><h5 class='mb-2'>" & H(row("Title")) & "</h5><span class='badge bg-label-primary align-self-start'>" & NameOfState(row("Status")) & "</span></div><p class='circular-full-summary'>" & H(row("Summary")) & "</p><div class='row g-3 small text-muted'><div class='col-md-4'><i class='bx bx-calendar me-1'></i>تاريخ التعميم: " & CDate(row("CircularDate")).ToString("yyyy/MM/dd") & "</div><div class='col-md-4'>من " & Stamp(row("StartUtc")) & "</div><div class='col-md-4'>إلى " & Stamp(row("EndUtc")) & "</div></div><div class='mt-3 d-flex gap-2 flex-wrap'><span class='badge bg-label-secondary'>الإصدار " & H(row("Version")) & "</span><span id='circularReadState' class='badge bg-label-warning'>" & If(CBool(row("IsRead")),"مقروء","غير مقروء") & "</span></div>"
            litFileName.Text=H(row("FileName"))
            litFileInfo.Text="PDF · " & (CInt(row("FileSizeBytes"))/1024.0).ToString("N0") & " KB · " & If(CBool(row("AllowDownload")),"التنزيل مسموح","مشاهدة فقط")
            pnlDownload.Visible=CBool(row("AllowDownload"))
            If AdminMode AndAlso pnlEditor.Visible Then
                txtTitle.Text=CStr(row("Title")):txtSummary.Text=CStr(row("Summary")):txtDate.Text=CDate(row("CircularDate")).ToString("yyyy-MM-dd")
                txtStart.Text=InformationPagesData.LocalDate(row("StartUtc"),True):txtEnd.Text=InformationPagesData.LocalDate(row("EndUtc"),True)
                chkEnabled.Checked=CBool(row("IsEnabled")):chkDownload.Checked=CBool(row("AllowDownload")):ddlAudience.SelectedValue=CStr(row("Audience"))
                Dim audience As New Text.StringBuilder(H(NameOfState(row("Audience"))))
                For Each target As DataRow In data.Tables(1).Rows
                    Dim list=Lists()(CStr(target("Kind"))), item=list.Items.FindByValue(CStr(target("TargetID")))
                    If item Is Nothing Then
                        item=New ListItem(Convert.ToString(target("Title")) & " (غير فعال)",CStr(target("TargetID"))):list.Items.Add(item)
                    End If
                    item.Selected=True
                    audience.Append("<span class='badge bg-label-secondary ms-2 my-1'>" & NameOfState(target("Kind")) & ": " & H(target("Title")) & "</span>")
                Next
                litAudience.Text=audience.ToString():BindLogs()
            End If
            If AdminMode AndAlso Not pnlEditor.Visible Then
                litAudience.Text=H(NameOfState(row("Audience"))) & " <a class='btn btn-sm btn-label-secondary' href='Manage.aspx?logs=" & PageID.ToString() & "'>سجل العمليات والاطلاع</a>"
                BindLogs()
            End If
            If row.Table.Columns.Contains("HasPeriod") AndAlso Not CBool(row("HasPeriod")) Then
                litDetails.Text=litDetails.Text.Replace("<div class='col-md-4'>من " & Stamp(row("StartUtc")) & "</div><div class='col-md-4'>إلى " & Stamp(row("EndUtc")) & "</div>","<div class='col-md-8'>دون فترة محددة</div>")
            End If
            If row.Table.Columns.Contains("Title_EN") Then litDetails.Text &= "<div dir='ltr' class='border-top mt-3 pt-3'><h5>" & H(row("Title_EN")) & "</h5><p>" & H(row("Summary_EN")) & "</p></div>"
            If Request.QueryString("saved")="1" Then litMessage.Text="<div class='alert alert-success' role='status'>تم حفظ التعميم بنجاح.</div>"
        Catch ex As Exception
            pnlContent.Visible=False:Failure(litMessage,ex)
        End Try
    End Sub
    Protected Sub Save(sender As Object,e As EventArgs)
        RequireAdmin()
        Response.Redirect("Manage.aspx?" & If(PageID>0,"edit=" & PageID.ToString(),"new=1"),False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
    Private Sub BindLogs()
        RequireAdmin()
        Dim data=CircularsData.Query("dbo.Circular_AdminData",CircularsData.P("@Actor",SqlDbType.Int,Actor),CircularsData.P("@Mode",SqlDbType.VarChar,"logs",10),CircularsData.P("@ID",SqlDbType.Int,PageID),CircularsData.P("@Page",SqlDbType.Int,LogPage))
        Dim html As New Text.StringBuilder("<ul class='timeline mb-0'>")
        For Each row As DataRow In data.Tables(1).Rows
            html.Append("<li class='timeline-item timeline-item-transparent'><span class='timeline-point timeline-point-primary'></span><div class='timeline-event'><div class='timeline-header mb-1'><h6 class='mb-0'>" & NameOfState(row("Action")) & "</h6><small class='text-muted'>" & Stamp(row("RecordedUtc")) & "</small></div><div>" & H(row("ActorName")) & " · " & If(CStr(row("ActorKind"))="customer","عميل","موظف") & " · " & H(row("ActorID")) & "</div><div class='small text-muted'>" & NameOfState(row("Source")) & " · الإصدار " & H(row("Version")) & "</div>")
            If Not IsDBNull(row("DeviceID")) Then html.Append("<div class='small text-muted circular-device'>الجهاز: <bdi>" & H(row("DeviceID")) & "</bdi> · التطبيق " & H(row("AppVersion")) & "</div>")
            If Not IsDBNull(row("OccurredAtUtc")) Then html.Append("<div class='small text-muted'>وقت الهاتف: " & Stamp(row("OccurredAtUtc")) & "</div>")
            If Not IsDBNull(row("MailStatus")) Then html.Append("<div class='small text-muted'>حالة البريد: " & NameOfState(row("MailStatus")) & "</div>")
            html.Append("</div></li>")
        Next
        html.Append("</ul>")
        litLogs.Text=If(data.Tables(1).Rows.Count=0,"<div class='alert alert-info'>لا توجد عمليات مسجلة.</div>",html.ToString())
        Dim total=CInt(data.Tables(0).Rows(0)("Total"))
        litLogPaging.Text="<small class='text-muted'>" & total.ToString() & " عملية · الصفحة " & LogPage.ToString() & "</small>"
        btnLogPrev.Enabled=LogPage>1:btnLogNext.Enabled=LogPage*50<total
    End Sub
    Private Sub ActivateTab(id As String)
        ClientScript.RegisterStartupScript(Me.GetType(),"circularTab","window.addEventListener('load',function(){bootstrap.Tab.getOrCreateInstance(document.getElementById('" & id & "')).show();});",True)
    End Sub
    Protected Sub RefreshLogs(sender As Object,e As EventArgs)
        Try
            BindLogs():ActivateTab("logsTab")
        Catch ex As Exception
            Failure(litMessage,ex)
        End Try
    End Sub
    Protected Sub PreviousLogs(sender As Object,e As EventArgs)
        LogPage-=1:RefreshLogs(sender,e)
    End Sub
    Protected Sub NextLogs(sender As Object,e As EventArgs)
        LogPage+=1:RefreshLogs(sender,e)
    End Sub
End Class
