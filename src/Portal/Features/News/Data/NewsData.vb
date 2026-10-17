Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Configuration
Imports System.Linq

Public NotInheritable Class NewsData
    Private Shared Function Store() As Prosto_ERP_ClassLibrary.AttendanceIntegration
        Return New Prosto_ERP_ClassLibrary.AttendanceIntegration(ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString)
    End Function
    Private Shared Function P(name As String, value As Object) As SqlParameter
        Return New SqlParameter(name, If(value, DBNull.Value))
    End Function
    Public Shared Function Listing(actor As Integer, Optional keyword As String = Nothing, Optional active As Boolean? = Nothing, Optional brand As Integer? = Nothing) As DataTable
        Return Store().Query("dbo.News_AdminList", P("@Actor", actor), P("@Keyword", If(String.IsNullOrWhiteSpace(keyword), Nothing, keyword)), P("@IsActive", active), P("@BrandID", brand))
    End Function
    Public Shared Function Brand(pid As Integer) As Integer?
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of Integer?)("SELECT Brand_ID FROM dbo.News WHERE PID={0} AND ISNULL(IsDeleted,0)=0", pid).FirstOrDefault()
        End Using
    End Function
    Public Shared Sub Save(actor As Integer, brand As Integer, pid As Integer?, ar As String, en As String, briefAr As String, briefEn As String, details As String, image As String, newsDate As DateTime?, order As Integer?, active As Boolean)
        Store().Query("dbo.News_AdminSave", P("@Actor", actor), P("@BrandID", brand), P("@PID", pid), P("@Title_AR", ar), P("@Title_En", en), P("@Brief_Ar", briefAr), P("@Brief_En", briefEn), P("@Details", details), P("@Image", image), P("@Date", newsDate), P("@Item_Order", order), P("@IsActive", active))
    End Sub
    Public Shared Sub FillBrands(list As System.Web.UI.WebControls.DropDownList, prompt As String)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            NewsPresentation.BindBrands(list, db.Select_Brands_All().Where(Function(b) b.IsActive.GetValueOrDefault() AndAlso Not b.IsDeleted.GetValueOrDefault()).OrderBy(Function(b) b.Title_Ar).ToList())
        End Using
        NewsPresentation.InsertPrompt(list, prompt)
    End Sub
End Class
