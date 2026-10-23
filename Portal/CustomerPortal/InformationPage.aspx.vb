Imports System.Data
Imports System.Web.UI
Imports System.Web.UI.WebControls

Public Class CustomerInformationPage
    Inherits CustomerPortalPage
    Private Function F(Of T As Control)(id As String) As T
        Return DirectCast(Master.FindControl("ContentPlaceHolder1").FindControl(id), T)
    End Function
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Try
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 Then Throw New ArgumentException()
            Dim english = If(IsPostBack, F(Of System.Web.UI.HtmlControls.HtmlInputHidden)("detailLanguage").Value = "en", Request.QueryString("lang") = "en")
            Dim row = CustomerPortalData.CustomerQuery("dbo.Customer_InformationPages", CustomerPortalData.P("@ID", SqlDbType.Int, id), CustomerPortalData.P("@Language", SqlDbType.VarChar, If(english, "en", "ar"), 2), CustomerPortalData.P("@LogVisit", SqlDbType.Bit, Not IsPostBack)).Rows(0)
            F(Of Panel)("pageBody").Attributes("data-detail-language") = If(english, "en", "ar")
            F(Of System.Web.UI.HtmlControls.HtmlInputHidden)("detailLanguage").Value = If(english, "en", "ar")
            F(Of Literal)("pageTitle").Text = Convert.ToString(row("Title_Ar"))
            F(Of Literal)("pageTitleEn").Text = Convert.ToString(row("Title_En"))
            F(Of Literal)("details").Text = InformationPagesData.CleanHtml(Convert.ToString(row("Details_Ar")))
            F(Of Literal)("detailsEn").Text = InformationPagesData.CleanHtml(Convert.ToString(row("Details_En")))
            F(Of Literal)("pageVersion").Text = "الإصدار " & Convert.ToString(row("VersionNumber")) & " · " & InformationPagesData.LocalDate(row("OccurredUtc"))
            F(Of Literal)("pageVersionEn").Text = "Version " & Convert.ToString(row("VersionNumber")) & " · " & InformationPagesData.LocalDate(row("OccurredUtc"))
            F(Of Literal)("language").Text = If(english, "العربية", "English")

        Catch ex As Exception
            F(Of Panel)("pageBody").Visible = False
            F(Of Literal)("litMessage").Text = "<div class='alert alert-warning' role='alert'>الصفحة غير متاحة لحسابك.</div>"
            Response.StatusCode = If(TypeOf ex Is ArgumentException OrElse (TypeOf ex Is System.Data.SqlClient.SqlException AndAlso DirectCast(ex, System.Data.SqlClient.SqlException).Number = 51912), 404, 500)
            Response.TrySkipIisCustomErrors = True
            If Response.StatusCode = 500 Then System.Diagnostics.Trace.TraceError("Customer information page failed: {0}", ex.GetType().Name)
        End Try
    End Sub
End Class
