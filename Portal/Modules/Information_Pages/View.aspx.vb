Imports System.Data
Imports System.Data.SqlClient
Public Class ViewInformationPage
    Inherits InformationPagesPage
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim preview = Request.QueryString("preview") = "1"
        If preview Then RequireAdmin()
        Dim showEnglish = If(IsPostBack, detailLanguage.Value = "en", English)
        Try
            Dim version = QueryNumber("version")
            Dim data = InformationPagesData.Query("dbo.Select_Information_Page", InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                InformationPagesData.P("@ID", SqlDbType.Int, PageID), InformationPagesData.P("@Admin", SqlDbType.Bit, preview),
                InformationPagesData.P("@Version", SqlDbType.Int, version), InformationPagesData.P("@LogVisit", SqlDbType.Bit, Not IsPostBack),
                InformationPagesData.P("@Language", SqlDbType.VarChar, If(showEnglish, "en", "ar"), 2))
            Dim row = data.Rows(0)
            pnlPage.Attributes("data-detail-language") = If(showEnglish, "en", "ar")
            detailLanguage.Value = If(showEnglish, "en", "ar")
            litTitle.Text = CStr(row("Title_Ar")) : litTitleEn.Text = CStr(row("Title_En"))
            litDetails.Text = InformationPagesData.CleanHtml(CStr(row("Details_Ar")))
            litDetailsEn.Text = InformationPagesData.CleanHtml(CStr(row("Details_En")))
            litVersion.Text = "الإصدار " & row("VersionNumber").ToString()
            litVersionEn.Text = "Version " & row("VersionNumber").ToString()
            litVersionDate.Text = InformationPagesData.LocalDate(row("OccurredUtc"))
            Title = If(showEnglish, litTitleEn.Text, litTitle.Text)
            lnkLanguage.Text = If(showEnglish, "العربية", "English")
            lnkHistory.NavigateUrl = "History.aspx?ID=" & PageID.ToString()
            pnlPreview.Visible = preview : pnlPage.Visible = True
        Catch ex As Exception
            pnlPage.Visible = False
            Dim sql = TryCast(ex, SqlException)
            If sql IsNot Nothing AndAlso sql.Number = 51604 Then
                Dim manager = ScriptManager.GetCurrent(Page)
                If manager IsNot Nothing AndAlso manager.IsInAsyncPostBack Then
                    ScriptManager.RegisterStartupScript(Page, Page.GetType(), "information-unavailable", "window.location.replace('Index.aspx" & If(English, "?lang=en", "") & "');", True)
                Else
                    Response.StatusCode = 404 : Response.TrySkipIisCustomErrors = True
                End If
            End If
            ShowError(litMessage, ex)
        End Try
    End Sub
End Class
