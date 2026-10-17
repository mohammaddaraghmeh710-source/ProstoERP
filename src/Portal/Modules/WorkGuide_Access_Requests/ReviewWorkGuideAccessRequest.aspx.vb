Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Xml.Linq

Public Class ReviewWorkGuideAccessRequest
    Inherits HRTypePageBase
    Private Roles As DataTable

    Private ReadOnly Property BatchID As Guid
        Get
            Dim value As Guid
            If Not Guid.TryParse(Request.QueryString("batch"), value) Then
                Response.Redirect("ManageWorkGuideAccessRequests.aspx")
                Return Guid.Empty
            End If
            Return value
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim batch = BatchID
        If Not IsPostBack Then
            Try
                Roles = WorkGuideAccess.Query("dbo.Select_Work_Guide_Request_Roles", WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID))
                Dim rows = WorkGuideAccess.Requests(SessionManager.GetInstance.Users.UserID, Nothing, Nothing, Nothing, batch, 1, 200)
                If rows.Rows.Count = 0 Then
                    ShowMessage(litMessage, "الطلب غير موجود.")
                    btnSave.Visible = False
                    Return
                End If
                Dim first = rows.Rows(0)
                litSummary.Text = "<h6>" & Server.HtmlEncode(Convert.ToString(first("User_Name"))) & " — " & Server.HtmlEncode(Convert.ToString(first("Brand_Name"))) & "</h6><p>سبب الطلب: " & Server.HtmlEncode(Convert.ToString(first("Reason"))) & "</p>"
                lstReview.DataSource = rows
                lstReview.DataBind()
                btnSave.Visible = rows.AsEnumerable().Any(Function(row) Convert.ToString(row("Status")) = "P")
                If Request.QueryString("saved") = "1" Then ShowMessage(litMessage, "تم حفظ القرارات ومنح الصلاحيات المعتمدة.", True)
            Catch ex As SqlException
                ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
                btnSave.Visible = False
            End Try
        End If
    End Sub

    Protected Sub lstReview_ItemDataBound(sender As Object, e As ListViewItemEventArgs)
        Dim selectRole = TryCast(e.Item.FindControl("ddlRole"), DropDownList)
        If selectRole Is Nothing Then Return
        selectRole.Items.Add(New ListItem("اختر الدور", "0"))
        For Each role As DataRow In Roles.Rows
            Dim item As New ListItem(Convert.ToString(role("Title_Ar")), Convert.ToString(role("ID")))
            item.Attributes("data-permissions") = "عرض الوثائق" & If(Convert.ToBoolean(role("Can_Print_Document")), " · طباعة", " · دون طباعة") & If(Convert.ToBoolean(role("Can_Download_Document")), " · تحميل حسب إعداد الملف", " · دون تحميل")
            selectRole.Items.Add(item)
        Next
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        litMessage.Text = ""
        Dim decisions As New XElement("items")
        For Each item As ListViewDataItem In lstReview.Items
            If Convert.ToString(lstReview.DataKeys(item.DataItemIndex)("Status")) <> "P" Then Continue For
            Dim decision = DirectCast(item.FindControl("ddlDecision"), DropDownList).SelectedValue
            If decision = "P" Then Continue For
            Dim roleID = Integer.Parse(DirectCast(item.FindControl("ddlRole"), DropDownList).SelectedValue)
            Dim note = DirectCast(item.FindControl("txtNote"), TextBox).Text.Trim()
            If (decision = "A" AndAlso roleID = 0) OrElse (decision = "R" AndAlso note.Length = 0) OrElse note.Length > 1000 Then
                ShowMessage(litMessage, "حدد دورًا لكل موافقة وسببًا لكل رفض، بحد أقصى 1000 حرف للملاحظة.")
                Return
            End If
            decisions.Add(New XElement("item", New XAttribute("id", lstReview.DataKeys(item.DataItemIndex)("ID")), New XAttribute("status", decision), New XAttribute("role", roleID), New XAttribute("note", note)))
        Next
        If Not decisions.HasElements Then
            ShowMessage(litMessage, "اختر قرارًا لتصنيف واحد على الأقل.")
            Return
        End If
        Try
            WorkGuideAccess.Query("dbo.Review_Work_Guide_Access_Request", WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID), WorkGuideAccess.Parameter("@Batch_ID", SqlDbType.UniqueIdentifier, BatchID), WorkGuideAccess.Parameter("@Decisions", SqlDbType.Xml, decisions.ToString()))
        Catch ex As SqlException
            ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
            Return
        End Try
        Response.Redirect("ReviewWorkGuideAccessRequest.aspx?batch=" & BatchID.ToString() & "&saved=1")
    End Sub
End Class
