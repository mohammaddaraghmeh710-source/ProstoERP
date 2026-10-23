Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Linq
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web
Imports System.Xml.Linq

' The existing information/news procedures remain the write and authorization contracts.
Public NotInheritable Class ContentManagementData
    Public Shared Sub RequireAdmin(actor As Integer)
        Using cn As New SqlConnection(Global.System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("SELECT COUNT(*) FROM dbo.UsersMembers WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0", cn)
                cmd.Parameters.AddWithValue("@Actor", actor)
                If CInt(cmd.ExecuteScalar()) <> 1 Then Throw New HttpException(403, "هذه الإدارة لمدير النظام فقط.")
            End Using
        End Using
    End Sub
    Public Shared Function Records(table As DataTable) As Object()
        Return table.Rows.Cast(Of DataRow)().Select(Function(row) row.Table.Columns.Cast(Of DataColumn)().ToDictionary(Function(c) c.ColumnName, Function(c) If(IsDBNull(row(c)), Nothing, If(TypeOf row(c) Is DateTime, DirectCast(CDate(row(c)).ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture), Object), row(c))))).Cast(Of Object)().ToArray()
    End Function
    Private Shared Function Q(procedure As String, ParamArray args As SqlParameter()) As DataTable
        Return InformationPagesData.Query(procedure, args)
    End Function
    Private Shared Function P(name As String, type As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return InformationPagesData.P(name, type, value, size)
    End Function
    Private Shared Function Sql(text As String, ParamArray args As SqlParameter()) As DataTable
        Using cn As New SqlConnection(Global.System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString), cmd As New SqlCommand(text, cn)
            cmd.Parameters.AddRange(args) : cn.Open()
            Dim result As New DataTable
            Using reader = cmd.ExecuteReader()
                result.Load(reader)
            End Using
            Return result
        End Using
    End Function
    Public Shared Function Listing(actor As Integer, kind As String) As Object
        RequireAdmin(actor)
        Dim rows As New Collections.Generic.List(Of Object)
        If kind = "pages" Then
            Dim links = Sql("SELECT PageID,BrandID FROM dbo.Information_Page_Brands")
            For Each deleted In New Boolean() {False, True}
                Dim data = Q("dbo.Select_Information_Pages", P("@Actor", SqlDbType.Int, actor), P("@Manage", SqlDbType.Bit, True), P("@Deleted", SqlDbType.Bit, deleted))
                For Each r As DataRow In data.Rows
                    rows.Add(New With {.id = CInt(r("ID")), .nameAr = CStr(r("Title_Ar")), .nameEn = CStr(r("Title_En")), .summary = CStr(r("Summary_Ar")) & " " & CStr(r("Summary_En")), .brandNames = Convert.ToString(r("BrandNames")), .brands = links.Rows.Cast(Of DataRow)().Where(Function(x) CInt(x("PageID")) = CInt(r("ID"))).Select(Function(x) CInt(x("BrandID"))).ToArray(), .active = CBool(r("IsPublished")), .deleted = deleted, .status = InformationPagesData.StatusText(r("DisplayStatus")), .audience = InformationPagesData.AudienceText(r("Audience")), .order = CInt(r("Item_Order")), .version = CInt(r("VersionNumber")), .dateText = If(CStr(r("PublishMode")) = "immediate", "نشر فوري", InformationPagesData.LocalDate(r("StartUtc")) & " — " & InformationPagesData.LocalDate(r("EndUtc"))), .revision = ""})
                Next
            Next
        Else
            For Each r As DataRow In NewsData.Listing(actor).Rows
                rows.Add(New With {.id = CInt(r("PID")), .nameAr = Convert.ToString(r("Title_AR")), .nameEn = Convert.ToString(r("Title_En")), .summary = Convert.ToString(r("Brief_Ar")) & " " & Convert.ToString(r("Brief_En")), .brandNames = Convert.ToString(r("BrandName")), .brands = If(IsDBNull(r("Brand_ID")), New Integer() {}, New Integer() {CInt(r("Brand_ID"))}), .active = Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive")), .deleted = False, .status = If(Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive")), "فعال", "موقوف"), .audience = "", .order = If(IsDBNull(r("Item_Order")), 0, CInt(r("Item_Order"))), .version = 0, .dateText = NewsData.CustomerDate(r("Date")), .revision = Fingerprint(r), .image = NewsData.CustomerImage(r("Image"))})
            Next
        End If
        Return New With {.rows = rows, .brands = Records(Q("dbo.Select_Information_Page_Brands", P("@Actor", SqlDbType.Int, actor)))}
    End Function
    Public Shared Function Editor(actor As Integer, kind As String, id As Integer) As Object
        RequireAdmin(actor)
        If kind = "pages" Then
            Dim page As Object = Nothing, startLocal = "", endLocal = ""
            If id > 0 Then
                Dim data = Q("dbo.Select_Information_Page", P("@Actor", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id), P("@Admin", SqlDbType.Bit, True))
                If data.Rows.Count = 0 OrElse CBool(data.Rows(0)("IsDeleted")) Then Throw New HttpException(404, "الصفحة غير متاحة.")
                page = Records(data)(0) : startLocal = InformationPagesData.LocalDate(data.Rows(0)("StartUtc"), True) : endLocal = InformationPagesData.LocalDate(data.Rows(0)("EndUtc"), True)
            End If
            Return New With {.item = page, .brands = Records(Q("dbo.Select_Information_Page_Brands", P("@Actor", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id))), .roles = Records(Q("dbo.Select_Information_Page_Roles", P("@Actor", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id))), .customers = Records(Q("dbo.Select_Information_Page_Customers", P("@Actor", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, id))), .start = startLocal, .end = endLocal}
        End If
        Dim item As Object = Nothing, revision = ""
        If id > 0 Then
            Dim data = Sql("SELECT n.*,b.Title_Ar BrandName FROM dbo.News n LEFT JOIN dbo.Brands b ON b.ID=n.Brand_ID WHERE n.PID=@ID AND ISNULL(n.IsDeleted,0)=0", P("@ID", SqlDbType.Int, id))
            If data.Rows.Count = 0 Then Throw New HttpException(404, "الخبر غير متاح.")
            item = Records(data)(0) : revision = Fingerprint(data.Rows(0))
        End If
        Return New With {.item = item, .revision = revision, .brands = Records(Q("dbo.Select_Information_Page_Brands", P("@Actor", SqlDbType.Int, actor)))}
    End Function
    Public Shared Function Number(data As Collections.Generic.Dictionary(Of String, Object), name As String, Optional minimum As Integer = 0) As Integer
        Dim value As Integer
        If Not data.ContainsKey(name) OrElse Not Integer.TryParse(Convert.ToString(data(name)), value) OrElse value < minimum Then Throw New ArgumentException("أدخل قيمة صحيحة للحقل: " & name)
        Return value
    End Function
    Public Shared Function Text(data As Collections.Generic.Dictionary(Of String, Object), name As String, max As Integer, Optional required As Boolean = False) As String
        Dim value = If(data.ContainsKey(name), Convert.ToString(data(name)), "")
        If value.Length > max OrElse (required AndAlso String.IsNullOrWhiteSpace(value)) Then Throw New ArgumentException("راجع الحقل: " & name)
        Return value
    End Function
    Private Shared Function IdXml(data As Collections.Generic.Dictionary(Of String, Object), field As String, root As String, child As String) As String
        Dim result As New XElement(root), raw = Text(data, field, 100000)
        For Each part In raw.Split(","c).Where(Function(x) Not String.IsNullOrWhiteSpace(x)).Distinct()
            Dim id As Integer
            If Not Integer.TryParse(part, id) OrElse id <= 0 Then Throw New ArgumentException("اختيار غير صحيح.")
            result.Add(New XElement(child, New XAttribute("id", id)))
        Next
        Return result.ToString()
    End Function
    Public Shared Function SavePage(actor As Integer, data As Collections.Generic.Dictionary(Of String, Object)) As Integer
        Dim audience = Text(data, "audience", 10, True), allTypes = Text(data, "employeeScope", 10) = "all", allCustomers = Text(data, "customerScope", 10) = "all"
        Dim mode = Text(data, "mode", 10, True), startUtc As Object = Nothing, endUtc As Object = Nothing
        If mode = "scheduled" Then
            startUtc = InformationPagesData.ParseDate(Text(data, "start", 20, True))
            endUtc = InformationPagesData.ParseDate(Text(data, "end", 20, True))
        End If
        Dim result = Q("dbo.Save_Information_Page", P("@Actor", SqlDbType.Int, actor), P("@ID", SqlDbType.Int, Number(data, "id")), P("@ExpectedVersion", SqlDbType.Int, Number(data, "version")),
            P("@TitleAr", SqlDbType.NVarChar, InformationPagesData.RequiredText(Text(data, "titleAr", 250, True), 250, "العنوان العربي"), 250), P("@TitleEn", SqlDbType.NVarChar, InformationPagesData.RequiredText(Text(data, "titleEn", 250, True), 250, "العنوان الإنجليزي"), 250),
            P("@SummaryAr", SqlDbType.NVarChar, InformationPagesData.RequiredText(Text(data, "summaryAr", 2000, True), 2000, "الملخص العربي"), 2000), P("@SummaryEn", SqlDbType.NVarChar, InformationPagesData.RequiredText(Text(data, "summaryEn", 2000, True), 2000, "الملخص الإنجليزي"), 2000),
            P("@DetailsAr", SqlDbType.NVarChar, InformationPagesData.CleanHtml(Text(data, "detailsAr", 100000, True)), -1), P("@DetailsEn", SqlDbType.NVarChar, InformationPagesData.CleanHtml(Text(data, "detailsEn", 100000, True)), -1),
            P("@Order", SqlDbType.Int, Number(data, "order")), P("@Published", SqlDbType.Bit, Text(data, "active", 1) = "1"), P("@Mode", SqlDbType.VarChar, mode, 10), P("@StartUtc", SqlDbType.DateTime2, startUtc), P("@EndUtc", SqlDbType.DateTime2, endUtc),
            P("@AllTypes", SqlDbType.Bit, audience <> "employees" OrElse allTypes), P("@Roles", SqlDbType.Xml, IdXml(data, "roles", "roles", "role")), P("@ExpectedAccessRevision", SqlDbType.Int, Number(data, "accessRevision")), P("@Brands", SqlDbType.Xml, IdXml(data, "brands", "brands", "brand")),
            P("@Audience", SqlDbType.VarChar, audience, 10), P("@AllCustomers", SqlDbType.Bit, audience = "all" OrElse (audience = "customers" AndAlso allCustomers)), P("@Customers", SqlDbType.Xml, IdXml(data, "customers", "customers", "customer")))
        Return CInt(result.Rows(0)("ID"))
    End Function
    Private Shared Function Fingerprint(row As DataRow) As String
        Dim builder As New StringBuilder()
        For Each column In row.Table.Columns.Cast(Of DataColumn)().Where(Function(c) c.ColumnName <> "BrandName").OrderBy(Function(c) c.ColumnName)
            Dim value = If(IsDBNull(row(column)), "<null>", If(TypeOf row(column) Is DateTime, CDate(row(column)).ToString("O", CultureInfo.InvariantCulture), Convert.ToString(row(column), CultureInfo.InvariantCulture)))
            builder.Append(column.ColumnName).Append(":").Append(Convert.ToBase64String(Encoding.UTF8.GetBytes(value))).Append("|")
        Next
        Dim text = builder.ToString()
        Using hash = SHA256.Create()
            Return Convert.ToBase64String(hash.ComputeHash(Encoding.UTF8.GetBytes(text)))
        End Using
    End Function
    Public Shared Function WriteNews(actor As Integer, data As Collections.Generic.Dictionary(Of String, Object), delete As Boolean, image As String) As Integer
        Using cn As New SqlConnection(Global.System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString)
            cn.Open()
            Using tx = cn.BeginTransaction()
                Try
                    Dim id = Number(data, "id"), current As DataRow = Nothing
                    Using check As New SqlCommand("IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WITH(HOLDLOCK) WHERE ID=@Actor AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51950,'Administrator required.',1; SELECT * FROM dbo.News WITH(UPDLOCK,HOLDLOCK) WHERE PID=@ID AND ISNULL(IsDeleted,0)=0;", cn, tx)
                        check.Parameters.AddWithValue("@Actor", actor) : check.Parameters.AddWithValue("@ID", id)
                        Dim table As New DataTable
                        Using reader = check.ExecuteReader()
                            table.Load(reader)
                        End Using
                        If id > 0 Then
                            If table.Rows.Count = 0 Then Throw New HttpException(404, "الخبر غير متاح.")
                            current = table.Rows(0)
                            If Fingerprint(current) <> Text(data, "revision", 100, True) Then Throw New HttpException(409, "تغير الخبر؛ أعد فتحه قبل الحفظ.")
                        End If
                    End Using
                    If delete Then
                        If id <= 0 Then Throw New ArgumentException("اختر الخبر المطلوب.")
                        Using cmd As New SqlCommand("UPDATE dbo.News SET IsDeleted=1,ModifyUser=@Actor,ModifyDate=GETDATE() WHERE PID=@ID", cn, tx)
                            cmd.Parameters.AddWithValue("@ID", id) : cmd.Parameters.AddWithValue("@Actor", actor) : cmd.ExecuteNonQuery()
                        End Using
                    Else
                        Dim dateValue As DateTime, dateText = Text(data, "date", 20, True)
                        If Not DateTime.TryParseExact(dateText, "yyyy-MM-ddTHH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, dateValue) Then Throw New ArgumentException("أدخل تاريخ الخبر مع الوقت.")
                        Using cmd As New SqlCommand("dbo.News_AdminSave", cn, tx)
                            cmd.CommandType = CommandType.StoredProcedure
                            cmd.Parameters.AddRange({P("@Actor", SqlDbType.Int, actor), P("@BrandID", SqlDbType.Int, Number(data, "brand", 1)), P("@PID", SqlDbType.Int, If(id = 0, Nothing, DirectCast(id, Object))),
                                P("@Title_AR", SqlDbType.NVarChar, Text(data, "titleAr", 250, True), -1), P("@Title_En", SqlDbType.NVarChar, Text(data, "titleEn", 250), -1), P("@Brief_Ar", SqlDbType.NVarChar, Text(data, "summaryAr", 2000), -1), P("@Brief_En", SqlDbType.NVarChar, Text(data, "summaryEn", 2000), -1),
                                P("@Details", SqlDbType.NVarChar, NewsData.CleanDetails(Text(data, "detailsAr", 100000)), -1), P("@Details_EN", SqlDbType.NVarChar, NewsData.CleanDetails(Text(data, "detailsEn", 100000)), -1),
                                P("@Image", SqlDbType.NVarChar, If(image, If(current Is Nothing, Nothing, Convert.ToString(current("Image")))), -1), P("@Date", SqlDbType.DateTime, dateValue), P("@Item_Order", SqlDbType.Int, Number(data, "order")), P("@IsActive", SqlDbType.Bit, Text(data, "active", 1) = "1")})
                            id = CInt(cmd.ExecuteScalar())
                        End Using
                        ' Legacy create always activates news. Honor the new editor's explicit state atomically.
                        Using cmd As New SqlCommand("UPDATE dbo.News SET IsActive=@Active WHERE PID=@ID", cn, tx)
                            cmd.Parameters.AddWithValue("@ID", id) : cmd.Parameters.AddWithValue("@Active", Text(data, "active", 1) = "1") : cmd.ExecuteNonQuery()
                        End Using
                    End If
                    tx.Commit() : Return id
                Catch
                    If tx.Connection IsNot Nothing Then tx.Rollback()
                    Throw
                End Try
            End Using
        End Using
    End Function
End Class
