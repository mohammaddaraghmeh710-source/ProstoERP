Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class ManageWorkGuideAccessRequests
    Inherits HRTypePageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Using db As New Prosto_ERP_DataClassesDataContext()
                ddlBrand.DataSource = db.Select_Brands_All().ToList()
                ddlBrand.DataTextField = "Title_Ar"
                ddlBrand.DataValueField = "ID"
                ddlBrand.DataBind()
                ddlBrand.Items.Insert(0, New ListItem("جميع العلامات التجارية", "0"))
            End Using
            Dim statusItem = ddlStatus.Items.FindByValue(Request.QueryString("status"))
            If statusItem IsNot Nothing Then ddlStatus.SelectedValue = statusItem.Value
            Dim brandItem = ddlBrand.Items.FindByValue(Request.QueryString("brand"))
            If brandItem IsNot Nothing Then ddlBrand.SelectedValue = brandItem.Value
            txtKeyword.Text = Convert.ToString(Request.QueryString("keyword"))
            If txtKeyword.Text.Length > 200 Then txtKeyword.Text = txtKeyword.Text.Substring(0, 200)
            BindRequests()
            If Request.QueryString("saved") = "1" Then _
                ShowMessage(litMessage, "تم حفظ القرار وتحديث صلاحيات التصنيف حسب القرار المعتمد.", True)
        End If
    End Sub

    Private Sub BindRequests()
        Try
            Dim brand As Integer? = Nothing
            If ddlBrand.SelectedValue <> "0" Then brand = Integer.Parse(ddlBrand.SelectedValue)
            Dim rows = WorkGuideAccess.Requests(SessionManager.GetInstance.Users.UserID, ddlStatus.SelectedValue, brand,
                                                txtKeyword.Text.Trim(), Nothing, 1, 50, True)
            lstRequests.DataSource = rows
            lstRequests.DataBind()
        Catch ex As SqlException
            ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
        End Try
    End Sub

    Private Sub OpenReviewModal()
        ClientScript.RegisterStartupScript(Me.GetType(), "review-request-modal",
                                           "window.addEventListener('load', openReviewRequestModal);", True)
    End Sub

    Protected Sub lstRequests_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName <> "ApproveRequest" AndAlso e.CommandName <> "RejectRequest" Then Return
        litMessage.Text = ""
        litReviewMessage.Text = ""
        ViewState.Remove("ReviewRequestID")
        ViewState.Remove("ReviewBatchID")
        Dim item = TryCast(e.Item, ListViewDataItem)
        If item Is Nothing Then Return
        Dim requestID = Convert.ToInt32(lstRequests.DataKeys(item.DataItemIndex)("ID"))
        Dim batchID = DirectCast(lstRequests.DataKeys(item.DataItemIndex)("Batch_ID"), Guid)
        Try
            Dim rows = WorkGuideAccess.Requests(SessionManager.GetInstance.Users.UserID, Nothing, Nothing, Nothing,
                                                batchID, 1, 200)
            Dim row = rows.AsEnumerable().FirstOrDefault(Function(value) Convert.ToInt32(value("ID")) = requestID)
            If row Is Nothing OrElse Convert.ToString(row("Status")) <> "P" Then
                ShowMessage(litMessage, "الطلب غير موجود أو تمت مراجعته بالفعل. تم تحديث القائمة.")
                BindRequests()
                Return
            End If
            Dim roles = WorkGuideAccess.Query("dbo.Select_Work_Guide_Request_Roles",
                                              WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int,
                                                                        SessionManager.GetInstance.Users.UserID))
            ddlReviewRole.Items.Clear()
            ddlReviewRole.Items.Add(New ListItem("اختر الدور والصلاحيات", "0"))
            For Each role As DataRow In roles.Rows
                Dim roleItem As New ListItem(Convert.ToString(role("Title_Ar")), Convert.ToString(role("ID")))
                roleItem.Attributes("data-permissions") = "عرض الوثائق" &
                                                          If _
                                                              (Convert.ToBoolean(role("Can_Print_Document")), " · طباعة",
                                                               " · دون طباعة") &
                                                          If _
                                                              (Convert.ToBoolean(role("Can_Download_Document")),
                                                               " · تحميل حسب إعداد الملف", " · دون تحميل")
                ddlReviewRole.Items.Add(roleItem)
            Next
            litReviewSummary.Text = "<div class='border rounded p-3 mb-3' style='overflow-wrap:anywhere'><strong>" &
                                    Server.HtmlEncode(Convert.ToString(row("User_Name"))) &
                                    "</strong><div>العلامة التجارية: " &
                                    Server.HtmlEncode(Convert.ToString(row("Brand_Name"))) & "</div><div>التصنيف: " &
                                    Server.HtmlEncode(Convert.ToString(row("Category_Name"))) &
                                    "</div><div class='mt-2' style='white-space:pre-wrap'>سبب الطلب: " &
                                    Server.HtmlEncode(Convert.ToString(row("Reason"))) & "</div></div>"
            ddlReviewDecision.SelectedValue = If(e.CommandName = "ApproveRequest", "A", "R")
            txtReviewNote.Text = ""
            ViewState("ReviewRequestID") = requestID
            ViewState("ReviewBatchID") = batchID
            OpenReviewModal()
        Catch ex As SqlException
            ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
        End Try
    End Sub

    Protected Sub btnSaveReview_Click(sender As Object, e As EventArgs)
        litReviewMessage.Text = ""
        If ViewState("ReviewRequestID") Is Nothing OrElse ViewState("ReviewBatchID") Is Nothing Then
            ShowMessage(litMessage, "اختر طلبًا معلّقًا من القائمة أولًا.")
            Return
        End If
        Dim decision = ddlReviewDecision.SelectedValue
        Dim note = txtReviewNote.Text.Trim()
        Dim roleID = 0
        If decision = "A" Then Integer.TryParse(ddlReviewRole.SelectedValue, roleID)
        If _
            (decision <> "A" AndAlso decision <> "R") OrElse (decision = "A" AndAlso roleID <= 0) OrElse
            (decision = "R" AndAlso note.Length = 0) OrElse note.Length > 1000 Then
            ShowMessage(litReviewMessage,
                        "اختر دورًا عند الموافقة، واكتب سببًا عند الرفض. الحد الأقصى للشروحات 1000 حرف.")
            OpenReviewModal()
            Return
        End If
        Dim _
            decisions As _
                New XElement("items",
                             New XElement("item", New XAttribute("id", CInt(ViewState("ReviewRequestID"))),
                                          New XAttribute("status", decision), New XAttribute("role", roleID),
                                          New XAttribute("note", note)))
        Try
            WorkGuideAccess.Query("dbo.Review_Work_Guide_Access_Request",
                                  WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int,
                                                            SessionManager.GetInstance.Users.UserID),
                                  WorkGuideAccess.Parameter("@Batch_ID", SqlDbType.UniqueIdentifier,
                                                            DirectCast(ViewState("ReviewBatchID"), Guid)),
                                  WorkGuideAccess.Parameter("@Decisions", SqlDbType.Xml, decisions.ToString()))
        Catch ex As SqlException
            ShowMessage(litReviewMessage, WorkGuideAccess.ErrorText(ex))
            OpenReviewModal()
            Return
        End Try
        ViewState.Remove("ReviewRequestID")
        ViewState.Remove("ReviewBatchID")
        Response.Redirect(
            "ManageWorkGuideAccessRequests.aspx?saved=1&status=" & Server.UrlEncode(ddlStatus.SelectedValue) & "&brand=" &
            Server.UrlEncode(ddlBrand.SelectedValue) & "&keyword=" & Server.UrlEncode(txtKeyword.Text.Trim()))
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        BindRequests()
    End Sub
End Class


