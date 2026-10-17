Imports System.Linq
Imports System.Xml.Linq
Imports System.Data
Imports System.Data.SqlClient

Public Class CustomerGuide
    Inherits CustomerPortalPage


    Private CurrentUserID As Integer
    Private CurrentBrandID As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        CurrentUserID=CustomerPortalData.Current.AccountID
        pnlRequestArea.Visible=True
        If Not IsPostBack Then
            CustomerPortalData.BindOptions(ddlBrand,CustomerPortalData.WorkGuide("brands"),"اختر العلامة التجارية")
            If ddlBrand.Items.Count>1 Then ddlBrand.SelectedIndex=1
            Dim requestedBrand = ddlBrand.Items.FindByValue(Request.QueryString("brand"))
            If requestedBrand IsNot Nothing Then ddlBrand.SelectedValue = requestedBrand.Value
        End If
        CurrentBrandID=CInt(ddlBrand.SelectedValue)
        btnRequestAccess.Visible=CurrentBrandID>0
        If Not Page.IsPostBack Then

            FillCategories()
            FillRequestCategories()
            BindRequests()
            If Request.QueryString("requested") = "1" Then AccessMessage(litAccessMessage, "تم إرسال طلبك للمراجعة. تابع حالته هنا.", True)
            FillDocuments()
        End If

    End Sub

    Protected Sub BrandChanged(sender As Object,e As EventArgs)
        CurrentBrandID=CInt(ddlBrand.SelectedValue)
        FillCategories() : FillRequestCategories() : BindRequests() : FillDocuments()
    End Sub

    Private Sub FillCategories()

        ddlCategory.Items.Clear()


        If CurrentBrandID = 0 Then
            Return
        End If

        For Each item As DataRow In CustomerPortalData.WorkGuide("categories",CurrentBrandID).Rows
            Dim optionItem As New ListItem(CStr(item("Tree_Title_Ar")),CStr(item("ID")))
            optionItem.Attributes("data-parent")=Convert.ToString(item("Parent_ID"))
            optionItem.Attributes("data-name")=CStr(item("Title_Ar"))
            optionItem.Attributes("data-path")=CStr(item("Full_Path_Ar"))
            ddlCategory.Items.Add(optionItem)
        Next

    End Sub

    Private Sub FillRequestCategories()
        lstRequestCategories.Items.Clear()
        If Not pnlRequestArea.Visible OrElse CurrentBrandID = 0 Then Return
        Try
            For Each row As DataRow In CustomerPortalData.WorkGuide("request-categories",CurrentBrandID).Rows
                Dim item As New ListItem(Convert.ToString(row("Full_Path_Ar")), Convert.ToString(row("ID")))
                item.Enabled = Convert.ToBoolean(row("Can_Request"))
                item.Attributes("data-parent") = Convert.ToString(row("Parent_ID"))
                item.Attributes("data-name") = Convert.ToString(row("Title_Ar"))
                item.Attributes("data-path") = Convert.ToString(row("Full_Path_Ar"))
                item.Attributes("data-state") = If(Convert.ToBoolean(row("Can_View_Document")), "متاح لك", If(row.IsNull("Pending_Request_ID"), "يمكن طلبه", "طلب معلّق"))
                lstRequestCategories.Items.Add(item)
            Next
        Catch ex As SqlException
            AccessMessage(litAccessMessage, CustomerPortalData.ErrorText(ex))
        End Try
    End Sub

    Private Sub FillDocuments()
        Dim selected = ddlCategory.Items.Cast(Of ListItem)().Where(Function(i) i.Selected).Select(Function(i) Integer.Parse(i.Value)).Distinct().ToList()
        Dim categories As New XElement("items", selected.Select(Function(id) New XElement("item", New XAttribute("id", id))))
        Dim documents As New DataTable()
        If CurrentBrandID > 0 Then
            documents = CustomerPortalData.WorkGuide("documents",CurrentBrandID,categories.ToString(),txtSearch.Text.Trim())
        End If
        lstDocuments.DataSource = documents
        lstDocuments.DataBind()
        lblDocumentsCount.Text = documents.Rows.Count.ToString() & " ملفات"
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        FillDocuments()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs)
        txtSearch.Text = ""
        ddlCategory.ClearSelection()
        FillDocuments()
    End Sub

    Public Function FormatFileSize(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return "-"
        End If

        Dim size As Decimal = Convert.ToDecimal(value)

        If size < 1024 Then
            Return size.ToString("N0") & " B"
        ElseIf size < 1024 * 1024 Then
            Return (size / 1024).ToString("N2") & " KB"
        Else
            Return (size / 1024 / 1024).ToString("N2") & " MB"
        End If

    End Function

    Public Function FormatDate(value As Object) As String

        If value Is Nothing OrElse IsDBNull(value) Then
            Return "-"
        End If

        Return Convert.ToDateTime(value).ToString("dd/MM/yyyy")

    End Function

    Private Sub AccessMessage(target As Literal, text As String, Optional success As Boolean = False)
        target.Text = "<div role='alert' class='alert alert-" & If(success, "success", "danger") & "'>" & Server.HtmlEncode(text) & "</div>"
    End Sub

    Private Sub BindRequests()
        If Not pnlRequestArea.Visible Then Return
        Try
            Dim data = CustomerPortalData.WorkGuide("requests",0,status:=ddlRequestStatus.SelectedValue)
            lstRequests.DataSource = data
            lstRequests.DataBind()
        Catch ex As SqlException
            AccessMessage(litAccessMessage, CustomerPortalData.ErrorText(ex))
        End Try
    End Sub

    Protected Sub btnSubmitAccessRequest_Click(sender As Object, e As EventArgs)
        litRequestMessage.Text = ""
        Dim selected = lstRequestCategories.Items.Cast(Of ListItem)().Where(Function(item) item.Selected AndAlso item.Enabled).Select(Function(item) Integer.Parse(item.Value)).ToList()
        Dim reason = txtRequestReason.Text.Trim()
        If selected.Count = 0 OrElse selected.Count > 200 OrElse reason.Length = 0 OrElse reason.Length > 1000 Then
            AccessMessage(litRequestMessage, "حدد من تصنيف واحد إلى 200 تصنيف واكتب سبب الطلب بحد أقصى 1000 حرف.")
            ReopenRequestModal()
            Return
        End If
        Try
            CustomerPortalData.WorkGuide("submit",CurrentBrandID,New XElement("items",selected.Select(Function(id) New XElement("item",New XAttribute("id",id)))).ToString(),reason:=reason)
        Catch ex As SqlException
            AccessMessage(litRequestMessage, CustomerPortalData.ErrorText(ex))
            FillRequestCategories()
            ReopenRequestModal()
            Return
        End Try
        Response.Redirect("Guide.aspx?requested=1&brand=" & CurrentBrandID.ToString() & "#my-access-requests")
    End Sub

    Private Sub ReopenRequestModal()
        ClientScript.RegisterStartupScript(Me.GetType(), "request-modal", "window.addEventListener('load', openRequestAccessModal);", True)
    End Sub

    Protected Sub btnRefreshRequests_Click(sender As Object, e As EventArgs)

        FillCategories()
        FillRequestCategories()

        FillDocuments()
        BindRequests()
    End Sub

    Protected Sub ddlRequestStatus_SelectedIndexChanged(sender As Object, e As EventArgs)

        BindRequests()
    End Sub

End Class
