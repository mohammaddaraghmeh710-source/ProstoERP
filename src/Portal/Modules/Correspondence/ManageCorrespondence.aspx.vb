Imports System.Globalization
Imports System.IO
Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class ManageCorrespondence
    Inherits PageBase
    Private conversationBound As Boolean
    Private files As DataTable
    Private senderImage As String
    Private receiverImage As String
    Private senderID As Integer
    Private failedConversation As Boolean
    Private ReadOnly Property IsUploadRequest As Boolean
        Get
            ' The bundled Toolkit marks IsInFileUploadPostBack obsolete (always false).
            Return Request.QueryString("contextKey") IsNot Nothing AndAlso Request.QueryString("controlID") = AttachmentUpload.ClientID
        End Get
    End Property
    Protected IsAdministrator As Boolean

    Protected ReadOnly Property ActorID As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property

    Protected ReadOnly Property Supervisory As Boolean
        Get
            Return Request.QueryString("scope") = "all"
        End Get
    End Property

    Protected ReadOnly Property SelectedThreadID As Integer
        Get
            Dim value As Integer
            If ViewState("SelectedThreadID") IsNot Nothing AndAlso Not IsUploadRequest Then
                value = CInt(ViewState("SelectedThreadID"))
            Else
                Integer.TryParse(Request.QueryString("ID"), value)
            End If
            Return Math.Max(0, value)
        End Get
    End Property
    Protected ReadOnly Property DraftToken As String
        Get
            Dim token As Guid
            If Not Guid.TryParse(Request.QueryString("draft"), token) Then Return ""
            Return token.ToString("N")
        End Get
    End Property
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        ViewStateUserKey = Session.SessionID
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/login.aspx") : Return
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        If Supervisory Then
            ' The portal oversight page is deferred; personal correspondence remains available.
            Try
                Dim options = CorrespondenceData.Query("dbo.Correspondence_Options", CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID), CorrespondenceData.P("@IncludeOrganization", SqlDbType.Bit, False))
                If CInt(options.AsEnumerable().Single(Function(r) CStr(r("Kind")) = "role")("ID")) <> 1 Then Throw New HttpException(403, "غير مسموح")
            Catch ex As System.Data.SqlClient.SqlException
                If ex.Number = 51400 Then Throw New HttpException(403, "غير مسموح")
                Throw
            End Try
            Response.Redirect("Dashboard.aspx")
            Return
        End If
        EnsureUploadDraft()
        If IsUploadRequest Then Return
        hfSendSucceeded.Value = "0"
        litMessage.Text = ""
        For Each control As Control In New Control() {btnSelectThread, btnSearch, btnQuickSearch, ddlBrand, btnSend, btnClearUploads, btnCloseStart, btnCloseCancel, btnCloseConfirm, btnArchive}
            ScriptManager.GetCurrent(Me).RegisterAsyncPostBackControl(control)
        Next
        Try
            Dim options = CorrespondenceData.Query("dbo.Correspondence_Options", CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID), CorrespondenceData.P("@IncludeOrganization", SqlDbType.Bit, Not IsPostBack AndAlso Supervisory))
            Dim currentType = CInt(options.AsEnumerable().Single(Function(r) CStr(r("Kind")) = "role")("ID"))
            IsAdministrator = currentType = 1
            If Supervisory AndAlso Not IsAdministrator Then Throw New HttpException(403, "غير مسموح")
            pnlNavigation.Visible = False
            pnlAdminFilters.Visible = Supervisory
            pnlList.Visible = Not Supervisory
            pnlOversight.Visible = Supervisory
            lnkNew.Visible = {1, 2, 3, 4}.Contains(currentType)
            If Not IsPostBack Then
                ViewState("SelectedThreadID") = SelectedThreadID
                CorrespondencePresentation.FillCatalog(ddlPriority, ActorID, "P", 1)
                For Each row In options.AsEnumerable().Where(Function(r) CStr(r("Kind")) = "brand").GroupBy(Function(r) CInt(r("ID"))).Select(Function(g) g.First())
                    ddlBrand.Items.Add(New ListItem(Convert.ToString(row("Title")), CStr(row("ID"))))
                Next
                FillBranches(options)
                txtPerson.Text = If(Request.QueryString("person"), "")
                txtTitleSearch.Text = If(Request.QueryString("title"), "")
                Dim filter = ddlFilter.Items.FindByValue(Request.QueryString("filter"))
                If filter IsNot Nothing Then ddlFilter.SelectedValue = filter.Value
                Dim kind = ddlKind.Items.FindByValue(Request.QueryString("kind"))
                If kind IsNot Nothing Then ddlKind.SelectedValue = kind.Value
                FillConversation(Not Supervisory)
                FillData()
            End If
            Dim timer = TryCast(Master.FindControl("tmCorrespondenceCount"), Timer)
            If timer IsNot Nothing Then AddHandler timer.Tick, AddressOf Refresh_Tick
        Catch ex As HttpException
            Throw
        Catch ex As Exception
            HideConversation() : ShowError(ex)
        End Try
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        If Supervisory Then
            MyBase.OnPreRender(e) : Return
        End If
        If IsUploadRequest Then
            MyBase.OnPreRender(e) : Return
        End If
        If SelectedThreadID > 0 AndAlso Not conversationBound AndAlso Not failedConversation Then
            Try
                FillConversation(False)
            Catch ex As Exception
                HideConversation() : ShowError(ex)
            End Try
        End If
        If SelectedThreadID = 0 OrElse failedConversation Then
            pnlConversation.Visible = False : pnlEmpty.Visible = True
            WriteSync(False, False, "")
        End If
        hfThread.Value = If(failedConversation, "0", SelectedThreadID.ToString())
        hfNavigation.Value = "0"
        pnlCompose.Style("display") = If(SelectedThreadID > 0 AndAlso Not failedConversation AndAlso ViewState("CanReply") IsNot Nothing AndAlso CBool(ViewState("CanReply")), "", "none")
        If SelectedThreadID > 0 Then ShowQueuedUploads()
        upConversation.Update()
        upFeedback.Update()
        MyBase.OnPreRender(e)
    End Sub

    Private Sub FillBranches(options As DataTable)
        ddlBranch.Items.Clear()
        ddlBranch.Items.Add(New ListItem("جميع الفروع", "0"))
        For Each row In _
            options.AsEnumerable().Where(
                Function(r) _
                                            CStr(r("Kind")) = "branch" AndAlso
                                            (ddlBrand.SelectedValue = "0" OrElse
                                             Convert.ToString(r("ParentID")) = ddlBrand.SelectedValue)).GroupBy(
                                                 Function(r) CInt(r("ID"))).Select(Function(g) g.First())
            ddlBranch.Items.Add(New ListItem(Convert.ToString(row("Title")), CStr(row("ID"))))
        Next
    End Sub

    Protected Sub Brand_Changed(sender As Object, e As EventArgs)
        Try
            FillBranches(CorrespondenceData.Query("dbo.Correspondence_Options",
                                                  CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID)))
            FillData()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Private Function FilterDate(value As String, endDate As Boolean) As Object
        If String.IsNullOrWhiteSpace(value) Then Return Nothing
        Dim parsed As DateTime
        If Not DateTime.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, parsed) _
            Then Throw New ArgumentException("التاريخ غير صحيح.")
        If endDate Then parsed = parsed.AddDays(1)
        Return _
            TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(parsed, DateTimeKind.Unspecified),
                                          TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time"))
    End Function

    Protected Sub FillData()
        Dim fromDate = FilterDate(txtFrom.Text, False), toDate = FilterDate(txtTo.Text, True)
        If fromDate IsNot Nothing AndAlso toDate IsNot Nothing AndAlso CDate(fromDate) >= CDate(toDate) Then Throw New ArgumentException("نهاية الفترة يجب ألا تسبق بدايتها.")
        ' Name, title and number are filtered locally over the complete authorized result.
        Dim rows = CorrespondenceData.Query("dbo.Correspondence_Browse",
            CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID), CorrespondenceData.P("@All", SqlDbType.Bit, Supervisory),
            CorrespondenceData.P("@Person", SqlDbType.NVarChar, "", 200), CorrespondenceData.P("@Title", SqlDbType.NVarChar, "", 200),
            CorrespondenceData.P("@Filter", SqlDbType.VarChar, ddlFilter.SelectedValue, 16),
            CorrespondenceData.P("@Brand", SqlDbType.Int, If(Supervisory, CInt(ddlBrand.SelectedValue), 0)), CorrespondenceData.P("@Branch", SqlDbType.Int, If(Supervisory, CInt(ddlBranch.SelectedValue), 0)),
            CorrespondenceData.P("@Sender", SqlDbType.NVarChar, If(Supervisory, txtSender.Text.Trim(), ""), 200), CorrespondenceData.P("@Receiver", SqlDbType.NVarChar, If(Supervisory, txtReceiver.Text.Trim(), ""), 200),
            CorrespondenceData.P("@From", SqlDbType.DateTime, fromDate), CorrespondenceData.P("@To", SqlDbType.DateTime, toDate),
            CorrespondenceData.P("@Kind", SqlDbType.Int, CInt(ddlKind.SelectedValue)), CorrespondenceData.P("@Priority", SqlDbType.Int, CInt(ddlPriority.SelectedValue)))
        Dim allRows = rows.AsEnumerable().ToList()
        rows.DefaultView.Sort = "PriorityRank DESC, LastMessageDate DESC, ID DESC"
        lstThreads.DataSource = rows.DefaultView
        lstThreads.DataBind()
        If Supervisory Then
            lstOversight.DataSource = rows.DefaultView : lstOversight.DataBind()
        End If
        Dim noReply = allRows.Where(Function(r) IsDBNull(r("FirstReplyDate")) AndAlso IsOpen(r)).Count()
        Dim overdue =
                allRows.Where(Function(r) CStr(r("State")) = "overdue" AndAlso Bool(r("RequiresCompletion"))).Count()
        Dim inactive = allRows.Where(Function(r) CBool(r("InactiveParty")) AndAlso IsOpen(r)).Count()
        litStatistics.Text = "<div class=""row row-cols-2 row-cols-lg-4 g-3 mb-3"">" &
                             Metric("المراسلات المطابقة", allRows.Count) & Metric("مفتوحة دون رد", noReply) &
                             Metric("تكليفات متأخرة", overdue) & Metric("تحتاج متابعة حساب معطل", inactive) & "</div>"
        pnlReport.Visible = Supervisory
        If Supervisory Then
            Dim report As New DataTable()
            For Each name In _
                {"Organization", "Count", "NoReply", "Overdue", "Completed", "NotCompleted", "Archived", "AverageReply"}
                report.Columns.Add(name)
            Next
            For Each group In _
                allRows.GroupBy(
                    Function(r) _
                                   If _
                                   (CBool(r("LegacyOrganization")), "بيانات تنظيمية تاريخية غير متاحة",
                                    Convert.ToString(r("ReceiverBrandName")) & " / " &
                                    Convert.ToString(r("ReceiverBranchName"))))
                Dim answered = group.Where(Function(r) Not IsDBNull(r("FirstReplySeconds"))).ToList()
                report.Rows.Add(group.Key, group.Count(),
                                group.Count(Function(r) IsOpen(r) AndAlso IsDBNull(r("FirstReplyDate"))),
                                group.Count(
                                    Function(r) CStr(r("State")) = "overdue" AndAlso Bool(r("RequiresCompletion"))),
                                group.Count(
                                    Function(r) _
                                               CStr(r("State")) = "closed" AndAlso Bool(r("RequiresCompletion")) AndAlso
                                               Bool(r("IsCompleted"))),
                                group.Count(
                                    Function(r) _
                                               CStr(r("State")) = "closed" AndAlso Bool(r("RequiresCompletion")) AndAlso
                                               Not IsDBNull(r("IsCompleted")) AndAlso Not CBool(r("IsCompleted"))),
                                group.Count(Function(r) CStr(r("State")) = "archived"),
                                If _
                                   (answered.Count = 0, "—",
                                    (answered.Average(Function(r) CDbl(r("FirstReplySeconds")))/3600).ToString("0.0") &
                                    " ساعة"))
            Next
            rptReport.DataSource = report
            rptReport.DataBind()
        End If
        upList.Update()
    End Sub

    Private Shared Function Bool(value As Object) As Boolean
        Return Not IsDBNull(value) AndAlso value IsNot Nothing AndAlso CBool(value)
    End Function

    Private Shared Function IsOpen(row As DataRow) As Boolean
        Return IsDBNull(row("CloseDate")) AndAlso IsDBNull(row("ArchivedAt"))
    End Function

    Private Function Metric(title As String, count As Integer) As String
        Return _
            "<div class=""col""><div class=""card h-100""><div class=""card-body""><div class=""text-muted small mb-2"">" &
            Server.HtmlEncode(title) & "</div><h4 class=""mb-0"">" & count.ToString() & "</h4></div></div></div>"
    End Function

    Private Function GetThread() As DataRow
        Return _
            CorrespondenceData.Query("dbo.Correspondence_Detail", CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID),
                                     CorrespondenceData.P("@ThreadID", SqlDbType.Int, SelectedThreadID),
                                     CorrespondenceData.P("@Supervisory", SqlDbType.Bit, Supervisory)).Rows(0)
    End Function

    Private Sub FillConversation(markRead As Boolean)
        If SelectedThreadID = 0 Then Return
        Dim thread = GetThread()
        If Supervisory OrElse Not CBool(thread("IsParticipant")) Then
            Dim eventKey = "ViewEvent:" & SelectedThreadID.ToString()
            If ViewState(eventKey) Is Nothing Then ViewState(eventKey) = Guid.NewGuid()
            CorrespondenceData.Query("dbo.Correspondence_LogView", CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID), CorrespondenceData.P("@ThreadID", SqlDbType.Int, SelectedThreadID), CorrespondenceData.P("@EventID", SqlDbType.UniqueIdentifier, CType(ViewState(eventKey), Guid)))
        End If
        Dim messages = CorrespondenceData.ThreadQuery("dbo.Correspondence_Messages", ActorID, SelectedThreadID)
        files = CorrespondenceData.ThreadQuery("dbo.Correspondence_Files", ActorID, SelectedThreadID)
        If markRead AndAlso Not Supervisory AndAlso CBool(thread("IsParticipant")) Then
            Dim ids =
                    messages.AsEnumerable().Where(
                        Function(m) CInt(m("ReceivedID")) = ActorID AndAlso Not CBool(m("IsRead"))).Select(
                            Function(m) CInt(m("ID"))).ToList()
            If ids.Count > 0 Then
                Using db As New Prosto_ERP_DataClassesDataContext()
                    db.Update_Correspondence_Messages_Read(ActorID, SelectedThreadID,
                                                           New XElement("items",
                                                                        ids.Select(
                                                                            Function(id) _
                                                                                      New XElement("item",
                                                                                                   New XAttribute("id",
                                                                                                                  id)))))
                End Using
                messages = CorrespondenceData.ThreadQuery("dbo.Correspondence_Messages", ActorID, SelectedThreadID)
            End If
        End If
        litRefresh.Text = ""
        senderID = CInt(thread("SenderID"))
        senderImage = CorrespondencePresentation.Avatar(thread("SenderImage"))
        receiverImage = CorrespondencePresentation.Avatar(thread("ReceiverImage"))
        pnlConversation.Visible = True
        pnlEmpty.Visible = False
        litThreadID.Text = SelectedThreadID.ToString()
        litOtherName.Text = Convert.ToString(thread("OtherName"))
        imgOther.ImageUrl = CorrespondencePresentation.Avatar(thread("OtherImage"))
        litTitle.Text = Convert.ToString(thread("Title"))
        litBrief.Text = Convert.ToString(thread("Brief"))
        lblState.Text = CorrespondencePresentation.StateText(thread("State"))
        lblState.CssClass = "badge " & CorrespondencePresentation.StateCss(thread("State"))
        litDates.Text = DetailItem("تاريخ الإنشاء", CorrespondencePresentation.DisplayDate(thread("CreatedDate")))
        If Not IsDBNull(thread("CloseDate")) Then _
            litDates.Text &= DetailItem("تاريخ الإغلاق", CorrespondencePresentation.DisplayDate(thread("CloseDate")))
        If Not IsDBNull(thread("ArchivedAt")) Then _
            litDates.Text &= DetailItem("تاريخ الأرشفة", CorrespondencePresentation.DisplayDate(thread("ArchivedAt")))
        Dim detail =
                DetailItem("النوع", CorrespondencePresentation.KindText(thread("RequiresCompletion")), "bg-label-primary") &
                DetailItem("الأولوية", Convert.ToString(thread("PriorityName")),
                           If(CBool(thread("PriorityUrgent")), "bg-label-danger", "bg-label-secondary"))
        If Not IsDBNull(thread("DueDate")) Then _
            detail &= DetailItem("الموعد المحدد", CorrespondencePresentation.DisplayDate(thread("DueDate")))
        If Bool(thread("RequiresCompletion")) Then _
            detail &= DetailItem("الإنجاز",
                                 If _
                                    (CStr(thread("State")) = "archived", "غير محدد — أرشفة إدارية",
                                     If _
                                        (IsDBNull(thread("IsCompleted")), "غير محدد — يقرره المنشئ",
                                         If(CBool(thread("IsCompleted")), "تم الإنجاز", "لم يتم الإنجاز"))))
        litDetails.Text = detail
        ViewState("CanReply") = CBool(thread("CanReply"))
        ' Keep the button in a participant's DOM so the first incoming reply can enable it without replacing the draft.
        btnCloseStart.Visible = True
        btnCloseStart.Style("display") = If(CBool(thread("CanClose")), "", "none")
        pnlClosedNote.Visible = Not CBool(thread("CanReply"))
        litClosedText.Text =
            If _
                (CStr(thread("State")) = "archived",
                 "مؤرشفة إداريًا — نتيجة الإنجاز غير محددة. السبب: " & Convert.ToString(thread("ArchiveReason")),
                 If _
                    (IsOpen(thread), "اطلاع إداري للقراءة فقط؛ لا يؤثر على قراءة المستلم.",
                     "مراسلة منتهية — " & Convert.ToString(thread("ClosureReasonName")) & ". " &
                     Convert.ToString(thread("CloseReason"))))
        pnlArchive.Visible = CBool(thread("CanArchive"))
        pnlArchiveAction.Visible = pnlArchive.Visible
        WriteSync(CBool(thread("CanReply")), CBool(thread("CanClose")), If(CBool(thread("CanReply")), "", litClosedText.Text))
        lnkTransfer.Visible = Not IsDBNull(thread("CreatedBy")) AndAlso CInt(thread("CreatedBy")) = ActorID AndAlso Not Supervisory AndAlso Convert.ToString(thread("ClosureKind")) = "transfer"
        lnkTransfer.NavigateUrl = "AddCorrespondence.aspx?related=" & SelectedThreadID.ToString()
        Dim organization = CorrespondenceData.ThreadQuery("dbo.Correspondence_Organization", ActorID, SelectedThreadID)
        litOrganization.Text =
            If _
                (CBool(thread("LegacyOrganization")),
                 "<div class=""alert alert-warning"">هذه المراسلة سابقة لحفظ التبعية التنظيمية؛ بيانات وقت الإنشاء غير متاحة، ولا تُستبدل بالبيانات الحالية في التقارير.</div>",
                 "")
        For Each row As DataRow In organization.Rows
            litOrganization.Text &= "<div class=""border-bottom pb-2 mb-2""><strong>" &
                                    Server.HtmlEncode(Convert.ToString(row("FullName"))) &
                                    "</strong><div class=""small mt-1"">وقت الإنشاء: " & OrgText(row, False) &
                                    "</div><div class=""small text-muted mt-1"">حاليًا: " & OrgText(row, True) &
                                    "</div></div>"
        Next
        Dim related = CorrespondenceData.ThreadQuery("dbo.Correspondence_Related", ActorID, SelectedThreadID)
        litRelated.Text = ""
        For Each row As DataRow In related.Rows
            litRelated.Text &= "<a class=""btn btn-sm btn-label-secondary me-1 mb-2"" data-thread-id=""" & CInt(row("ID")).ToString() & """ href=""" & ThreadLink(row("ID")) & """>مراسلة مرتبطة #" & CInt(row("ID")).ToString() & " — " & Server.HtmlEncode(CStr(row("Title"))) & "</a>"
        Next
        pnlAudit.Visible = IsAdministrator
        If IsAdministrator Then
            rptAudit.DataSource = CorrespondenceData.ThreadQuery("dbo.Correspondence_AuditList", ActorID,
                                                                 SelectedThreadID)
            rptAudit.DataBind()
        End If
        rptMessages.DataSource = messages
        rptMessages.DataBind()
        conversationBound = True
    End Sub
    Private Sub WriteSync(canReply As Boolean, canClose As Boolean, note As String)
        Dim items = If(SelectedThreadID > 0, TryCast(Session(UploadKey), List(Of FileAttribute)), Nothing)
        litSync.Text = "<span id=""correspondence-sync"" hidden data-thread=""" & If(failedConversation, "0", SelectedThreadID.ToString()) & """ data-reply=""" & If(canReply, "1", "0") & """ data-close=""" & If(canClose, "1", "0") & """ data-queued=""" & If(items Is Nothing, 0, items.Count).ToString() & """ data-note=""" & HttpUtility.HtmlAttributeEncode(note) & """></span>"
    End Sub
    Private Sub HideConversation()
        failedConversation = True : conversationBound = True
        pnlConversation.Visible = False : pnlEmpty.Visible = True
        ViewState("CanReply") = False
        ViewState("SelectedThreadID") = 0
        WriteSync(False, False, "")
        upComposer.Update()
    End Sub
    Protected Function MessageAvatar(id As Object) As String
        Return If(CInt(id) = senderID, senderImage, receiverImage)
    End Function
    Protected Function IsImage(name As Object) As Boolean
        Return {".png", ".jpg", ".jpeg", ".gif"}.Contains(IO.Path.GetExtension(Convert.ToString(name)).ToLowerInvariant())
    End Function
    Private Function OrgText(row As DataRow, current As Boolean) As String
        Dim names =
                If _
                (current,
                 New String() {"CurrentBrand", "CurrentBranch", "CurrentDepartment", "CurrentJobTitle", "CurrentShift"},
                 New String() {"BrandName", "BranchName", "DepartmentName", "JobTitleName", "ShiftName"})
        Return _
            Server.HtmlEncode(String.Join(" / ",
                                          names.Select(
                                              Function(n) _
                                                          If _
                                                          (
                                                              IsDBNull(row(n)) OrElse
                                                              String.IsNullOrWhiteSpace(CStr(row(n))), "غير محدد",
                                                              CStr(row(n))))))
    End Function

    Private Function DetailItem(title As String, value As String, Optional css As String = "bg-label-secondary") _
        As String
        Return _
            "<span class=""badge " & css & " text-wrap text-start me-1 mb-1"">" & Server.HtmlEncode(title) & ": " &
            Server.HtmlEncode(value) & "</span>"
    End Function

    Protected Function AttachmentsFor(id As Object) As DataView
        Dim view As New DataView(files)
        view.RowFilter = "MessageID=" & Convert.ToInt32(id).ToString(CultureInfo.InvariantCulture)
        Return view
    End Function

    Protected Function ThreadLink(id As Object) As String
        Return "ManageCorrespondence.aspx?ID=" & Convert.ToInt32(id).ToString() & If(Supervisory, "&scope=all", "")
    End Function
    Protected Sub SelectThread_Click(sender As Object, e As EventArgs)
        Dim requested As Integer
        Try
            If Not Integer.TryParse(hfThread.Value, requested) OrElse requested < 0 Then Throw New ArgumentException("المراسلة غير صحيحة.")
            ' Other actions use the ViewState selection, never a client-supplied thread ID.
            ViewState("SelectedThreadID") = requested
            txtReply.Text = ""
            If requested > 0 Then FillConversation(hfVisible.Value = "1")
            FillData()
        Catch ex As Exception
            HideConversation() : ShowError(ex)
        End Try
        upComposer.Update()
    End Sub
    Protected Sub Search_Click(sender As Object, e As EventArgs)
        Try
            FillData()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub Refresh_Tick(sender As Object, e As EventArgs)
        Try
            FillConversation(hfVisible.Value = "1")
            FillData()
        Catch ex As Exception
            HideConversation() : ShowError(ex)
        End Try
    End Sub

    Protected Sub Send_Click(sender As Object, e As EventArgs)
        Dim saved As New List(Of String)
        Try
            If Not CBool(GetThread()("CanReply")) Then Throw New ArgumentException("غير مسموح بالرد.")
            If txtReply.Text.Length > 4000 Then Throw New ArgumentException("الحد الأقصى للرسالة 4000 حرف.")
            Dim attachments = CorrespondenceAttachments.SaveQueuedAttachments(
                TryCast(Session(UploadKey), List(Of FileAttribute)), saved)
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.Insert_Correspondence_Thread_Message(ActorID, SelectedThreadID, txtReply.Text.Trim(), attachments).
                    ToList()
            End Using
            ' Once committed, refresh failures must never delete the saved message's files.
            saved.Clear()
            Session.Remove(UploadKey) : txtReply.Text = "" : hfSendSucceeded.Value = "1"
            FillConversation(False) : FillData()
        Catch ex As Exception
            CorrespondenceAttachments.Cleanup(saved)
            ShowError(ex)
        End Try
        upComposer.Update()
    End Sub

    Protected Sub CloseStart_Click(sender As Object, e As EventArgs)
        Try
            Dim thread = GetThread()
            If Not CBool(thread("CanClose")) Then _
                Throw New ArgumentException("يمكن للمنشئ إنهاء المحادثة بعد رد الطرف الآخر.")
            pnlOutcome.Visible = Bool(thread("RequiresCompletion"))
            CorrespondencePresentation.FillCatalog(ddlClosureKind, ActorID, "R", 0, pnlOutcome.Visible)
            If ddlClosureKind.Items.FindByValue("3") IsNot Nothing Then ddlClosureKind.SelectedValue = "3"
            txtCloseReason.Text = ""
            rblOutcome.ClearSelection()
            litCloseError.Text = ""
            CloseModal.Show()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub CloseCancel_Click(sender As Object, e As EventArgs)
        CloseModal.Hide()
    End Sub

    Protected Sub CloseConfirm_Click(sender As Object, e As EventArgs)
        Try
            If Not CBool(GetThread()("CanClose")) Then Throw New ArgumentException("غير مسموح بالإغلاق.")
            Dim outcome As Boolean? = Nothing
            If rblOutcome.SelectedValue = "1" Then outcome = True
            If rblOutcome.SelectedValue = "0" Then outcome = False
            If txtCloseReason.Text.Length > 1000 Then Throw New ArgumentException("السبب لا يتجاوز 1000 حرف.")
            CorrespondenceData.Query("dbo.Update_Correspondence_Thread_Close",
                                     CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID),
                                     CorrespondenceData.P("@ThreadID", SqlDbType.Int, SelectedThreadID),
                                     CorrespondenceData.P("@IsCompleted", SqlDbType.Bit, outcome),
                                     CorrespondenceData.P("@ClosureReasonID", SqlDbType.Int,
                                                          CInt(ddlClosureKind.SelectedValue)),
                                     CorrespondenceData.P("@CloseReason", SqlDbType.NVarChar, txtCloseReason.Text.Trim(),
                                                          1000))
            CloseModal.Hide()
            FillConversation(False) : FillData()
        Catch ex As Exception
            litCloseError.Text = "<div class=""alert alert-danger"">" &
                                 Server.HtmlEncode(CorrespondencePresentation.ErrorText(ex)) & "</div>"
            CloseModal.Show()
        End Try
    End Sub

    Protected Sub Archive_Click(sender As Object, e As EventArgs)
        Try
            If txtArchiveReason.Text.Length > 1000 Then Throw New ArgumentException("السبب لا يتجاوز 1000 حرف.")
            CorrespondenceData.Query("dbo.Correspondence_Archive",
                                     CorrespondenceData.P("@Actor", SqlDbType.Int, ActorID),
                                     CorrespondenceData.P("@ThreadID", SqlDbType.Int, SelectedThreadID),
                                     CorrespondenceData.P("@Reason", SqlDbType.NVarChar, txtArchiveReason.Text.Trim(),
                                                          1000))
            txtArchiveReason.Text = ""
            FillConversation(False) : FillData()
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Private ReadOnly Property UploadKey As String
        Get
            If DraftToken = "" OrElse Session("CorrespondencePage:" & DraftToken) Is Nothing Then Throw New ArgumentException("يرجى إعادة فتح الصفحة.")
            Return "CorrespondenceFiles:" & ActorID.ToString() & ":" & DraftToken & ":" & SelectedThreadID.ToString()
        End Get
    End Property

    Private Sub EnsureUploadDraft()
        Dim token As Guid
        If Not Guid.TryParse(Request.QueryString("draft"), token) Then Response.Redirect(Request.RawUrl & If(Request.QueryString.Count=0,"?","&") & "draft=" & Guid.NewGuid().ToString("N"))
        Dim key = "CorrespondencePage:" & token.ToString("N")
        If IsUploadRequest Then
            If Session(key) Is Nothing Then Throw New HttpException(403, "انتهت صلاحية المسودة؛ أعد فتح الصفحة.")
        Else
            Session(key) = True
        End If
    End Sub

    Protected Sub AttachmentUpload_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401, "انتهت الجلسة")
        If Not CBool(GetThread()("CanReply")) Then Throw New HttpException(403, "غير مسموح بالرد")
    End Sub

    Protected Sub AttachmentUpload_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401, "انتهت الجلسة")
        If Not CBool(GetThread()("CanReply")) Then Throw New HttpException(403, "غير مسموح بالرد")
        Dim extension = Path.GetExtension(e.FileName).ToLowerInvariant()
        If Not {".pdf", ".doc", ".docx", ".xls", ".xlsx", ".jpg", ".jpeg", ".png", ".gif"}.Contains(extension) Then _
            Throw New ArgumentException("نوع الملف غير مسموح.")
        Dim contents = e.GetContents()
        If contents.Length = 0 OrElse contents.Length > CorrespondenceData.MaxFileBytes Then _
            Throw New ArgumentException("الحد الأقصى للمرفق 10 ميجابايت.")
        Dim items = TryCast(Session(UploadKey), List(Of FileAttribute))
        If items Is Nothing Then items = New List(Of FileAttribute)
        If items.Count >= CorrespondenceData.MaxFiles Then _
            Throw New ArgumentException("الحد الأقصى خمسة مرفقات. امسح المرفقات المحددة لإعادة الاختيار.")
        items.Add(New FileAttribute With {.NameFile=e.FileName,.Type=e.ContentType,.FileByte=contents})
        Session(UploadKey) = items
    End Sub

    Protected Sub ClearUploads_Click(sender As Object, e As EventArgs)
        Session.Remove(UploadKey)
        upComposer.Update()
    End Sub

    Private Sub ShowQueuedUploads()
        Dim items=TryCast(Session(UploadKey),List(Of FileAttribute))
        lblQueued.Text=If(items Is Nothing OrElse items.Count=0, "", "(" & items.Count.ToString() & " محفوظة)")
    End Sub

    Private Sub ShowError(ex As Exception)
        litMessage.Text = "<div class=""alert alert-danger"" role=""alert"">" &
                          Server.HtmlEncode(CorrespondencePresentation.ErrorText(ex)) & "</div>"
    End Sub
End Class


