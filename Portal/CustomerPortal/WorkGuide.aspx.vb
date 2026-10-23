Imports System.Data
Imports System.Linq
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Web.Script.Serialization

Public Class CustomerWorkGuide
    Inherits CustomerPortalPage
    Private available As DataTable
    Protected Property GuideCsrf As String
    Private Function F(Of T As Control)(id As String) As T
        Return DirectCast(Master.FindControl("ContentPlaceHolder1").FindControl(id), T)
    End Function
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If CustomerPortalData.Current Is Nothing Then Return
        If Session("CRMGuideCSRF") Is Nothing Then Session("CRMGuideCSRF") = Guid.NewGuid().ToString("N")
        GuideCsrf = CStr(Session("CRMGuideCSRF"))
        Try
            available = CustomerPortalData.CustomerQuery("dbo.Customer_WorkGuide_List")
            Dim brands = F(Of DropDownList)("customerGuideBrand")
            brands.Items.Add(New ListItem("كل العلامات التجارية", ""))
            For Each group In available.Rows.Cast(Of DataRow)().GroupBy(Function(r) CInt(r("Brand_ID")))
                brands.Items.Add(New ListItem(Convert.ToString(group.First()("Brand_Name")), group.Key.ToString()))
            Next
            Dim list = F(Of DropDownList)("category")
            list.Items.Add(New ListItem("كل التصنيفات المسموحة", ""))
            For Each row As DataRow In available.Rows
                Dim optionItem As New ListItem(Convert.ToString(row("Brand_Name")) & " — " & Convert.ToString(row("Name_AR")) & " / " & Convert.ToString(row("Name_EN")), Convert.ToString(row("ID")))
                optionItem.Attributes("data-brand") = Convert.ToString(row("Brand_ID"))
                optionItem.Attributes("data-view") = If(CBool(row("Can_View")), "1", "0")
                optionItem.Attributes("data-download") = If(CBool(row("Can_Download")), "1", "0")
                list.Items.Add(optionItem)
            Next
            Dim hierarchy = CustomerPortalData.CustomerQuery("dbo.Customer_WorkGuide_Tree")
            Dim nodes As New List(Of Object)
            For Each group In hierarchy.Rows.Cast(Of DataRow)().GroupBy(Function(r) CInt(r("Brand_ID")))
                nodes.Add(New With {.id = "customer-brand-" & group.Key.ToString(), .parent = "#", .text = Convert.ToString(group.First()("Brand_Name")), .icon = "bx bx-buildings", .state = New With {.opened = True, .disabled = True}, .data = New With {.brandId = group.Key.ToString(), .isBrand = True}})
            Next
            For Each row As DataRow In hierarchy.Rows
                Dim parent = If(IsDBNull(row("Parent_ID")), "", Convert.ToString(row("Parent_ID")))
                nodes.Add(New With {.id = "customer-category-" & Convert.ToString(row("ID")), .parent = If(parent = "", "customer-brand-" & Convert.ToString(row("Brand_ID")), "customer-category-" & parent), .text = Convert.ToString(row("Name_AR")) & " / " & Convert.ToString(row("Name_EN")) & If(CBool(row("Has_Access")), "", " (تصنيف أب)"), .icon = If(parent = "", "bx bx-folder", "bx bx-subdirectory-left"), .a_attr = New With {.title = If(CBool(row("Has_Access")), Convert.ToString(row("Name_AR")), "تصنيف أب للتوضيح فقط؛ لا يمنح صلاحية على أدلته.")}, .state = New With {.opened = True, .disabled = Not CBool(row("Has_Access"))}, .data = New With {.categoryId = Convert.ToString(row("ID")), .brandId = Convert.ToString(row("Brand_ID")), .hasAccess = CBool(row("Has_Access"))}})
            Next
            F(Of Literal)("litCategoryTree").Text = (New JavaScriptSerializer With {.MaxJsonLength = 8388608}).Serialize(nodes).Replace("<", "\u003c").Replace(">", "\u003e").Replace("&", "\u0026")
            F(Of Literal)("statCategories").Text = available.Rows.Count.ToString("N0")
            If Not IsPostBack Then
                Dim selected = list.Items.FindByValue(If(Request.QueryString("category"), ""))
                If selected IsNot Nothing Then
                    list.SelectedValue = selected.Value
                    Dim selectedRow = available.Rows.Cast(Of DataRow)().FirstOrDefault(Function(r) Convert.ToString(r("ID")) = selected.Value)
                    If selectedRow IsNot Nothing Then brands.SelectedValue = Convert.ToString(selectedRow("Brand_ID"))
                End If
                Dim query = If(Request.QueryString("search"), "")
                F(Of TextBox)("filterName").Text = If(query.Length > 200, query.Substring(0, 200), query)
            End If
        Catch ex As Exception
            F(Of Panel)("pnlBody").Visible = False : Notice(CustomerPortalData.ErrorText(ex))
        End Try
    End Sub
    Protected Sub Search_Click(sender As Object, e As EventArgs)
    End Sub
    Protected Function DetailsUrl(id As Object, category As Object) As String
        Return "WorkGuideDetail.aspx?id=" & Convert.ToInt32(id).ToString() & "&category=" & Convert.ToInt32(category).ToString() & "&search=" & Server.UrlEncode(F(Of TextBox)("filterName").Text.Trim())
    End Function
    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        If available Is Nothing Then Return
        Try
            Dim category As Integer, selected As Object = Nothing
            Dim choice = F(Of DropDownList)("category").SelectedValue
            F(Of Literal)("litRight").Text = "حسب التصنيف الموضح لكل دليل"
            If choice <> "" Then
                If Not Integer.TryParse(choice, category) OrElse Not available.Rows.Cast(Of DataRow)().Any(Function(r) CInt(r("ID")) = category) Then Throw New ArgumentException("التصنيف غير متاح.")
                selected = category
                Dim grant = available.Rows.Cast(Of DataRow)().Single(Function(r) CInt(r("ID")) = category)
                F(Of Literal)("litRight").Text = If(CBool(grant("Can_View")), If(CBool(grant("Can_Download")), "اطلاع وتحميل", "اطلاع فقط"), "تحميل فقط")
            End If
            If available.Rows.Count = 0 Then Notice("لا توجد تصنيفات مسموحة لحسابك حاليًا. يمكنك التواصل مع الإدارة.")
            Dim data = CustomerPortalData.CustomerQuery("dbo.Customer_WorkGuide_List", CustomerPortalData.P("@Category_ID", SqlDbType.Int, Nothing), CustomerPortalData.P("@Items", SqlDbType.Bit, True))
            Dim name = F(Of TextBox)("filterName").Text.Trim()
            Dim rows = data.Rows.Cast(Of DataRow)().Where(Function(r) name = "" OrElse New String() {Convert.ToString(r("Name_AR")), Convert.ToString(r("Name_EN")), Convert.ToString(r("Summary_AR")), Convert.ToString(r("Summary_EN")), CRMWorkGuideContent.PlainText(Convert.ToString(r("Details_AR"))), CRMWorkGuideContent.PlainText(Convert.ToString(r("Details_EN")))}.Any(Function(text) text.IndexOf(name, StringComparison.CurrentCultureIgnoreCase) >= 0)).ToArray()
            F(Of Literal)("statItems").Text = rows.Select(Function(r) CInt(r("ID"))).Distinct().Count().ToString("N0")
            Dim filtered = data.Clone()
            For Each row In rows : filtered.ImportRow(row) : Next
            F(Of Repeater)("guides").DataSource = filtered : F(Of Repeater)("guides").DataBind()
        Catch ex As Exception
            F(Of Repeater)("guides").DataSource = Nothing : F(Of Repeater)("guides").DataBind()
            Notice(CustomerPortalData.ErrorText(ex))
        End Try
    End Sub
    Private Sub Notice(message As String)
        F(Of Literal)("litMessage").Text = "<div class='alert alert-info' role='alert'>" & CRMData.H(message) & "</div>"
    End Sub
End Class
