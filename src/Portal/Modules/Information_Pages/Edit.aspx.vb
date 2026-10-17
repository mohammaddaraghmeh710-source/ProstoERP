

Public Class EditInformationPage
    Inherits InformationPagesPage

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        RequireAdmin()
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return
        ViewState("Version") = 0
        ViewState("AccessRevision") = 0
        Dim brands = InformationPagesData.Query("dbo.Select_Information_Page_Brands",
                                                InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                                InformationPagesData.P("@ID", SqlDbType.Int, PageID))
        For Each brand As DataRow In brands.Rows
            Dim available = CBool(brand("IsAvailable"))
            Dim _
                item As _
                    New ListItem(
                        Convert.ToString(brand("Title_Ar")) & If(available, "", " (غير متاحة؛ أزلها قبل الحفظ)"),
                        CInt(brand("ID")).ToString())
            item.Selected = CBool(brand("IsSelected"))
            lstBrands.Items.Add(item)
        Next
        Dim roles = InformationPagesData.Query("dbo.Select_Information_Page_Roles",
                                               InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                               InformationPagesData.P("@ID", SqlDbType.Int, PageID))
        For Each role As DataRow In roles.Rows
            Dim item As New ListItem(Server.HtmlEncode(CStr(role("Title_Ar"))), CInt(role("ID")).ToString())
            item.Selected = CBool(role("IsSelected"))
            cblRoles.Items.Add(item)
        Next
        lblVersion.Text = "صفحة جديدة"
        If PageID = 0 Then Return
        Dim data = InformationPagesData.Query("dbo.Select_Information_Page",
                                              InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                              InformationPagesData.P("@ID", SqlDbType.Int, PageID),
                                              InformationPagesData.P("@Admin", SqlDbType.Bit, True))
        Dim row = data.Rows(0)
        If CBool(row("IsDeleted")) Then Throw New HttpException(404, "الصفحة محذوفة")
        ViewState("Version") = CInt(row("VersionNumber"))
        ViewState("AccessRevision") = CInt(row("AccessRevision"))
        ddlAccess.SelectedValue = If(CBool(row("AllUserTypes")), "all", "roles")
        lblVersion.Text = "الإصدار الحالي: " & row("VersionNumber").ToString()
        txtTitleAr.Text = CStr(row("Title_Ar"))
        txtTitleEn.Text = CStr(row("Title_En"))
        txtSummaryAr.Text = CStr(row("Summary_Ar"))
        txtSummaryEn.Text = CStr(row("Summary_En"))
        txtDetailsAr.Text = CStr(row("Details_Ar"))
        txtDetailsEn.Text = CStr(row("Details_En"))
        txtOrder.Text = row("Item_Order").ToString()
        ddlStatus.SelectedValue = If(CBool(row("IsPublished")), "1", "0")
        ddlMode.SelectedValue = CStr(row("PublishMode"))
        txtStart.Text = InformationPagesData.LocalDate(row("StartUtc"), True)
        txtEnd.Text = InformationPagesData.LocalDate(row("EndUtc"), True)
    End Sub

    Protected Sub Save_Click(sender As Object, e As EventArgs)
        RequireAdmin()
        Try
            Dim brands As New XElement("brands")
            For Each item As ListItem In lstBrands.Items
                If item.Selected Then brands.Add(New XElement("brand", New XAttribute("id", Integer.Parse(item.Value))))
            Next
            If Not brands.HasElements Then Throw New ArgumentException("اختر علامة تجارية واحدة على الأقل.")
            Dim roles As New XElement("roles")
            If ddlAccess.SelectedValue = "roles" Then
                For Each item As ListItem In cblRoles.Items
                    If item.Selected Then _
                        roles.Add(New XElement("role", New XAttribute("id", Integer.Parse(item.Value))))
                Next
                If Not roles.HasElements Then _
                    Throw New ArgumentException("اختر نوع مستخدم واحدًا على الأقل لصلاحيات الاطلاع.")
            End If
            Dim order As Integer
            If Not Integer.TryParse(txtOrder.Text, order) OrElse order < 0 Then _
                Throw New ArgumentException("ترتيب العرض يجب أن يكون عددًا صحيحًا لا يقل عن صفر.")
            Dim startUtc As Object = Nothing, endUtc As Object = Nothing
            If ddlMode.SelectedValue = "scheduled" Then
                startUtc = InformationPagesData.ParseDate(txtStart.Text)
                endUtc = InformationPagesData.ParseDate(txtEnd.Text)
                If CDate(endUtc) <= CDate(startUtc) Then _
                    Throw New ArgumentException("يجب أن تكون نهاية العرض بعد بدايته.")
            End If
            InformationPagesData.Query("dbo.Save_Information_Page",
                                       InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                       InformationPagesData.P("@ID", SqlDbType.Int, PageID),
                                       InformationPagesData.P("@ExpectedVersion", SqlDbType.Int,
                                                              CInt(ViewState("Version"))),
                                       InformationPagesData.P("@TitleAr", SqlDbType.NVarChar,
                                                              InformationPagesData.RequiredText(txtTitleAr.Text, 250,
                                                                                                "العنوان العربي"), 250),
                                       InformationPagesData.P("@TitleEn", SqlDbType.NVarChar,
                                                              InformationPagesData.RequiredText(txtTitleEn.Text, 250,
                                                                                                "العنوان الإنجليزي"),
                                                              250),
                                       InformationPagesData.P("@SummaryAr", SqlDbType.NVarChar,
                                                              InformationPagesData.RequiredText(txtSummaryAr.Text, 2000,
                                                                                                "الملخص العربي"), 2000),
                                       InformationPagesData.P("@SummaryEn", SqlDbType.NVarChar,
                                                              InformationPagesData.RequiredText(txtSummaryEn.Text, 2000,
                                                                                                "الملخص الإنجليزي"),
                                                              2000),
                                       InformationPagesData.P("@DetailsAr", SqlDbType.NVarChar,
                                                              InformationPagesData.CleanHtml(txtDetailsAr.Text), - 1),
                                       InformationPagesData.P("@DetailsEn", SqlDbType.NVarChar,
                                                              InformationPagesData.CleanHtml(txtDetailsEn.Text), - 1),
                                       InformationPagesData.P("@Order", SqlDbType.Int, order),
                                       InformationPagesData.P("@Published", SqlDbType.Bit, ddlStatus.SelectedValue = "1"),
                                       InformationPagesData.P("@Mode", SqlDbType.VarChar, ddlMode.SelectedValue, 10),
                                       InformationPagesData.P("@StartUtc", SqlDbType.DateTime2, startUtc),
                                       InformationPagesData.P("@EndUtc", SqlDbType.DateTime2, endUtc),
                                       InformationPagesData.P("@AllTypes", SqlDbType.Bit,
                                                              ddlAccess.SelectedValue = "all"),
                                       InformationPagesData.P("@Roles", SqlDbType.Xml, roles.ToString()),
                                       InformationPagesData.P("@ExpectedAccessRevision", SqlDbType.Int,
                                                              CInt(ViewState("AccessRevision"))),
                                       InformationPagesData.P("@Brands", SqlDbType.Xml, brands.ToString()))
        Catch ex As Exception
            ShowError(litMessage, ex)
            Return
        End Try
        Response.Redirect("Manage.aspx?saved=1", True)
    End Sub
End Class


