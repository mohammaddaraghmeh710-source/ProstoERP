Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Configuration
Imports System.Linq

Public NotInheritable Class NewsData
    Public Shared Function CleanDetails(value As String) As String
        Dim text = System.Web.HttpUtility.HtmlDecode(System.Text.RegularExpressions.Regex.Replace(If(value, ""), "<[^>]*>", ""))
        If String.IsNullOrWhiteSpace(text) Then Return ""
        Return InformationPagesData.CleanHtml(value)
    End Function
    Public Shared Function CustomerItems(Optional id As Integer? = Nothing) As DataTable
        Return CustomerPortalData.CustomerQuery("dbo.Customer_News", CustomerPortalData.P("@ID", SqlDbType.Int, id))
    End Function
    Public Shared Function CustomerImage(value As Object) As String
        Dim path = Convert.ToString(value)
        If path.StartsWith("~/", StringComparison.Ordinal) Then path = path.Substring(1)
        If Not path.Contains("..") AndAlso System.Text.RegularExpressions.Regex.IsMatch(path, "^/FileManager/(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_.-]+\.(?:png|jpg|jpeg|gif|webp)$", System.Text.RegularExpressions.RegexOptions.IgnoreCase) Then Return path
        Return "/assets/img/illustrations/customer-default.svg"
    End Function
    Public Shared Function CustomerDate(value As Object) As String
        If value Is Nothing OrElse Convert.IsDBNull(value) Then Return "بدون تاريخ"
        Return Convert.ToDateTime(value).ToString("dd/MM/yyyy", Globalization.CultureInfo.InvariantCulture)
    End Function
    Private Shared Function Store() As Prosto_ERP_ClassLibrary.AttendanceIntegration
        Return New Prosto_ERP_ClassLibrary.AttendanceIntegration(ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString)
    End Function
    Private Shared Function P(name As String, value As Object) As SqlParameter
        Return New SqlParameter(name, If(value, DBNull.Value))
    End Function
    Public Shared Function Listing(actor As Integer, Optional keyword As String = Nothing, Optional active As Boolean? = Nothing, Optional brand As Integer? = Nothing) As DataTable
        Return Store().Query("dbo.News_AdminList", P("@Actor", actor), P("@Keyword", If(String.IsNullOrWhiteSpace(keyword), Nothing, keyword)), P("@IsActive", active), P("@BrandID", brand))
    End Function
    Public Shared Function EnglishDetails(pid As Integer) As String
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of String)("SELECT Details_EN FROM dbo.News WHERE PID={0} AND ISNULL(IsDeleted,0)=0", pid).FirstOrDefault()
        End Using
    End Function
    Public Shared Function Brand(pid As Integer) As Integer?
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of Integer?)("SELECT Brand_ID FROM dbo.News WHERE PID={0} AND ISNULL(IsDeleted,0)=0", pid).FirstOrDefault()
        End Using
    End Function
    Public Shared Sub Save(actor As Integer, brand As Integer, pid As Integer?, ar As String, en As String, briefAr As String, briefEn As String, details As String, image As String, newsDate As DateTime?, order As Integer?, active As Boolean, Optional detailsEn As String = Nothing)
        Store().Query("dbo.News_AdminSave", P("@Actor", actor), P("@BrandID", brand), P("@PID", pid), P("@Title_AR", ar), P("@Title_En", en), P("@Brief_Ar", briefAr), P("@Brief_En", briefEn), P("@Details", NewsData.CleanDetails(details)), P("@Details_EN", If(detailsEn Is Nothing, Nothing, NewsData.CleanDetails(detailsEn))), P("@Image", image), P("@Date", newsDate), P("@Item_Order", order), P("@IsActive", active))
    End Sub
    Public Shared Sub FillBrands(list As System.Web.UI.WebControls.DropDownList, prompt As String)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            list.DataSource = db.Select_Brands_All().Where(Function(b) b.IsActive.GetValueOrDefault() AndAlso Not b.IsDeleted.GetValueOrDefault()).OrderBy(Function(b) b.Title_Ar).ToList()
            list.DataValueField = "ID" : list.DataTextField = "Title_Ar" : list.DataBind()
        End Using
        list.Items.Insert(0, New System.Web.UI.WebControls.ListItem(prompt, "0"))
    End Sub
End Class
