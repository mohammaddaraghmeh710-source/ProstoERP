Imports System.Data
Imports System.Web.UI
Imports System.Web.UI.WebControls

Public Class CustomerNewsDetail
    Inherits CustomerPortalPage
    Private Function F(Of T As Control)(id As String) As T
        Return DirectCast(Master.FindControl("ContentPlaceHolder1").FindControl(id), T)
    End Function
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Try
            Dim id As Integer
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 Then Throw New ArgumentException()
            Dim row = NewsData.CustomerItems(id).Rows(0)
            Dim english = If(IsPostBack, F(Of System.Web.UI.HtmlControls.HtmlInputHidden)("detailLanguage").Value = "en", Request.QueryString("lang") = "en")
            F(Of Panel)("newsBody").Attributes("data-detail-language") = If(english, "en", "ar")
            F(Of System.Web.UI.HtmlControls.HtmlInputHidden)("detailLanguage").Value = If(english, "en", "ar")
            F(Of Literal)("newsTitle").Text = Convert.ToString(row("Title_AR"))
            F(Of Literal)("newsTitleEn").Text = Convert.ToString(row("Title_En"))
            F(Of Literal)("newsDate").Text = NewsData.CustomerDate(row("Date"))
            F(Of Literal)("newsContent").Text = NewsData.CleanDetails(Convert.ToString(row("Details")))
            Dim detailsEn = NewsData.CleanDetails(Convert.ToString(row("Details_EN")))
            F(Of Literal)("newsContentEn").Text = detailsEn
            F(Of Panel)("newsEnglishEmpty").Visible = String.IsNullOrWhiteSpace(detailsEn)
            F(Of Literal)("language").Text = If(english, "العربية", "English")

        Catch ex As Exception
            F(Of Panel)("newsBody").Visible = False
            F(Of Literal)("newsMessage").Text = "<div class='alert alert-warning' role='alert'>الخبر غير متاح.</div>"
            Response.StatusCode = If(TypeOf ex Is ArgumentException, 404, If(TypeOf ex Is System.Data.SqlClient.SqlException AndAlso DirectCast(ex, System.Data.SqlClient.SqlException).Number = 51912, 404, 500))
            Response.TrySkipIisCustomErrors = True
            If Response.StatusCode = 500 Then System.Diagnostics.Trace.TraceError("Customer news detail failed: {0}", ex.GetType().Name)
        End Try
    End Sub
End Class
