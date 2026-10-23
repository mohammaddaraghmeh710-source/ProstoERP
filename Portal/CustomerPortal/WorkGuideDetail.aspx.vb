Imports System.Data
Imports System.Web.UI
Imports System.Web.UI.WebControls

Public Class CustomerWorkGuideDetail
    Inherits CustomerPortalPage
    Private Function F(Of T As Control)(id As String) As T
        Return DirectCast(Master.FindControl("ContentPlaceHolder1").FindControl(id), T)
    End Function
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Try
            Dim id As Integer, category As Integer
            If Not Integer.TryParse(Request.QueryString("id"), id) OrElse id <= 0 OrElse Not Integer.TryParse(Request.QueryString("category"), category) OrElse category <= 0 Then Throw New ArgumentException()
            Dim row = CustomerPortalData.CustomerQuery("dbo.Customer_WorkGuide_File", CustomerPortalData.P("@ID", SqlDbType.Int, id), CustomerPortalData.P("@Category_ID", SqlDbType.Int, category), CustomerPortalData.P("@Action", SqlDbType.VarChar, "details", 10)).Rows(0)
            F(Of Literal)("guideTitleAr").Text = Convert.ToString(row("Name_AR"))
            F(Of Literal)("guideTitleEn").Text = Convert.ToString(row("Name_EN"))
            Dim ar = CRMWorkGuideContent.Clean(Convert.ToString(row("Details_AR"))), en = CRMWorkGuideContent.Clean(Convert.ToString(row("Details_EN")))
            F(Of Literal)("guideTextAr").Text = ar : F(Of Literal)("guideTextEn").Text = en
            F(Of Panel)("guideEmptyAr").Visible = ar = "" : F(Of Panel)("guideEmptyEn").Visible = en = ""
            Dim query = If(Request.QueryString("search"), "")
            If query.Length > 200 Then query = query.Substring(0, 200)
            F(Of TextBox)("guideDetailsSearch").Text = query
            F(Of HyperLink)("backToGuides").NavigateUrl = "WorkGuide.aspx?category=" & category.ToString() & "&search=" & Server.UrlEncode(query)
        Catch ex As Exception
            F(Of Panel)("guideDetailsBody").Visible = False
            F(Of Literal)("detailMessage").Text = "<div class='alert alert-warning' role='alert'>الدليل غير متاح أو لا تملك صلاحية الاطلاع ضمن التصنيف المحدد.</div>"
            Response.StatusCode = If(TypeOf ex Is ArgumentException, 404, If(TypeOf ex Is System.Data.SqlClient.SqlException AndAlso DirectCast(ex, System.Data.SqlClient.SqlException).Number = 51912, 403, 500))
            Response.TrySkipIisCustomErrors = True
            If Response.StatusCode = 500 Then System.Diagnostics.Trace.TraceError("Customer guide detail failed: {0}", ex.GetType().Name)
        End Try
    End Sub
End Class
