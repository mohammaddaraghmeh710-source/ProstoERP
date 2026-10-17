Imports System.Data.SqlClient

Public Class ViewInformationPage
    Inherits InformationPagesPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim preview = Request.QueryString("preview") = "1"
        If preview Then RequireAdmin()
        Try
            Dim version = QueryNumber("version")
            Dim data = InformationPagesData.Query("dbo.Select_Information_Page",
                                                  InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                                                  InformationPagesData.P("@ID", SqlDbType.Int, PageID),
                                                  InformationPagesData.P("@Admin", SqlDbType.Bit, preview),
                                                  InformationPagesData.P("@Version", SqlDbType.Int, version),
                                                  InformationPagesData.P("@LogVisit", SqlDbType.Bit, Not IsPostBack),
                                                  InformationPagesData.P("@Language", SqlDbType.VarChar,
                                                                         If(English, "en", "ar"), 2))
            Dim row = data.Rows(0)
            litTitle.Text = CStr(row(If(English, "Title_En", "Title_Ar")))
            litDetails.Text = InformationPagesData.CleanHtml(CStr(row(If(English, "Details_En", "Details_Ar"))))
            litVersion.Text = If(English, "Version ", "الإصدار ") & row("VersionNumber").ToString()
            litVersionDate.Text = InformationPagesData.LocalDate(row("OccurredUtc"))
            Title = litTitle.Text
            lnkLanguage.Text = If(English, "العربية", "English")
            lnkLanguage.NavigateUrl = "View.aspx?ID=" & PageID.ToString() & If(English, "&lang=ar", "&lang=en") &
                                      If(preview, "&preview=1&version=" & version.ToString(), "")
            lnkHistory.NavigateUrl = "History.aspx?ID=" & PageID.ToString()
            pnlPreview.Visible = preview
            pnlPage.Visible = True
        Catch ex As Exception
            pnlPage.Visible = False
            Dim sql = TryCast(ex, SqlException)
            If sql IsNot Nothing AndAlso sql.Number = 51604 Then
                Dim manager = ScriptManager.GetCurrent(Page)
                If manager IsNot Nothing AndAlso manager.IsInAsyncPostBack Then
                    ScriptManager.RegisterStartupScript(Page, Page.GetType(), "information-unavailable",
                                                        "window.location.replace('Index.aspx" &
                                                        If(English, "?lang=en", "") & "');", True)
                Else
                    Response.StatusCode = 404
                    Response.TrySkipIisCustomErrors = True
                End If
            End If
            ShowError(litMessage, ex)
        End Try
    End Sub
End Class


