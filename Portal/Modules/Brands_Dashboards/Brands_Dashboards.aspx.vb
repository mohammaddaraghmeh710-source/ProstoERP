Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Web.UI

Public Class Brands_Dashboards
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Private Class BrandCardDto
        Public Property BrandID As Integer
        Public Property Title As String
        Public Property Logo As String
        Public Property BranchesCount As Integer
        Public Property BranchesUrl As String
        Public Property StatisticsUrl As String

    End Class

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' حماية الجلسة
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        If Not IsPostBack Then
            BindWelcome()
            BindBrands()
        End If
    End Sub

    Private Sub BindWelcome()
        ' حسب ما هو متوفر عندك في Users Session (عدّلها إذا اسم الحقل مختلف)
        Try
            Dim u = SessionManager.GetInstance.Users
            Dim name As String = ""

            If u IsNot Nothing Then
                ' جرّب تستخدم FullName/Name حسب مشروعك
                If Not String.IsNullOrEmpty(TryCast(u.NameAr, String)) Then
                    name = u.NameAr
                ElseIf Not String.IsNullOrEmpty(TryCast(u.NameAr, String)) Then
                    name = u.NameAr
                End If
            End If

            If String.IsNullOrWhiteSpace(name) Then name = "بك"

            litUserName.Text = name
        Catch
            litUserName.Text = "بك"
        End Try
    End Sub

    Private Sub BindBrands()
        ' 1) جلب العلامات
        Dim brands = (From b In db.Select_Brands_All()
                      Where (b.IsDeleted = False OrElse b.IsDeleted Is Nothing) _
                        AndAlso (b.IsActive = True OrElse b.IsActive Is Nothing)
                      Select b).ToList()

        If brands Is Nothing OrElse brands.Count = 0 Then
            phNoBrands.Visible = True
            rptBrands.DataSource = Nothing
            rptBrands.DataBind()
            litBrandsCount.Text = "0"
            Return
        End If

        phNoBrands.Visible = False
        litBrandsCount.Text = brands.Count.ToString()

        ' 2) تجهيز الكروت
        Dim cards As New List(Of BrandCardDto)()

        For Each br In brands
            Dim brandId As Integer = br.ID

            Dim title As String = br.Title_Ar
            If String.IsNullOrWhiteSpace(title) Then title = br.Title_En
            If String.IsNullOrWhiteSpace(title) Then title = "بدون اسم"

            Dim logo As String = If(Not String.IsNullOrEmpty(br.Logo), br.Logo, "/assets/img/Prosto/Logo_Circle.png")

            ' 3) عدد الفروع: باستخدام نفس مصدر صفحة الفروع (Procedure موجود عندك)
            Dim branchesCount As Integer = 0
            Try
                branchesCount =
                    (From x In db.Select_Branches_ByBrandID(brandId)
                     Where (x.IsDeleted = False OrElse x.IsDeleted Is Nothing) _
                       AndAlso (x.IsActive = True OrElse x.IsActive Is Nothing)
                     Select x.ID).Count()
            Catch
                branchesCount = 0
            End Try

            Dim statisticsUrl As String = String.Format("/modules/Brands_Dashboards/Brands_Statistics_Dashboard.aspx?BrandID={0}", brandId)

            Dim branchesUrl As String = String.Format("/modules/Branches_Dashboards/Branches_Dashboards.aspx?BrandID={0}", brandId)

            cards.Add(New BrandCardDto With {
                .BrandID = brandId,
                .Title = title,
                .Logo = logo,
                .BranchesCount = branchesCount,
                .BranchesUrl = branchesUrl,
                .StatisticsUrl = statisticsUrl
            })
        Next

        ' ترتيب جميل: الأكثر فروعاً أولاً
        cards = cards.OrderByDescending(Function(x) x.BranchesCount).ThenBy(Function(x) x.BrandID).ToList()

        rptBrands.DataSource = cards
        rptBrands.DataBind()
    End Sub

End Class
