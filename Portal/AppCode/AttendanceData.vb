Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

Public NotInheritable Class AttendanceData
    Private Shared ReadOnly Client As New HttpClient(New HttpClientHandler With {.AllowAutoRedirect = False, .UseCookies = False}) With {.Timeout = TimeSpan.FromSeconds(135), .MaxResponseContentBufferSize = 16 * 1024 * 1024}
    Public Shared Function Store() As Prosto_ERP_ClassLibrary.AttendanceIntegration
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
            Return New Prosto_ERP_ClassLibrary.AttendanceIntegration(db.Connection.ConnectionString)
        End Using
    End Function
    Public Shared Function Today() As String
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function
    Public Shared Function Employee(actor As Integer, Optional id As Integer = 0, Optional code As String = Nothing, Optional brand As Integer = 0) As DataRow
        Dim rows = Store().Query("dbo.AttendanceIntegration_Employee", New SqlParameter("@Actor", actor), New SqlParameter("@EmployeeID", id), New SqlParameter("@EmployeeCode", SqlDbType.NVarChar, 200) With {.Value = If(code Is Nothing, CType(DBNull.Value, Object), code)}, New SqlParameter("@BrandID", brand))
        If rows.Rows.Count <> 1 Then Throw New AttendanceDisplayException("الموظف غير متاح أو الرقم الوظيفي غير محدد بشكل فريد. حدد العلامة التجارية والموظف الصحيح.")
        Return rows.Rows(0)
    End Function
    Public Shared Function ValidDates(fromDate As String, toDate As String) As Boolean
        Dim first, last As DateTime
        Return DateTime.TryParseExact(fromDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, first) AndAlso DateTime.TryParseExact(toDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, last) AndAlso first <= last
    End Function
    Public Shared Async Function Transactions(actor As Integer, employee As DataRow, fromDate As String, toDate As String) As Task(Of DataTable)
        If Not ValidDates(fromDate, toDate) Then Throw New AttendanceDisplayException("أدخل تاريخين صالحين بحيث لا يتجاوز تاريخ البداية تاريخ النهاية.")
        ' Revalidate the target against current database identity before retrieving secrets.
        employee = AttendanceData.Employee(actor, CInt(employee("ID")))
        Dim settings = Store().Query("dbo.AttendanceIntegration_Credentials", New SqlParameter("@Actor", actor), New SqlParameter("@EmployeeID", CInt(employee("ID"))))
        If settings.Rows.Count <> 1 Then Throw New AttendanceDisplayException("تكامل الدوام غير مفعّل لهذه العلامة التجارية. يرجى مراجعة مدير النظام.")
        Dim row = settings.Rows(0)
        Dim baseUrl = Convert.ToString(row("ApiUrl"))
        If String.IsNullOrWhiteSpace(baseUrl) Then baseUrl = "http://92.253.126.181:1098/"
        Dim target As Uri = Nothing
        If Not Uri.TryCreate(baseUrl, UriKind.Absolute, target) OrElse (target.Scheme <> "http" AndAlso target.Scheme <> "https") OrElse target.UserInfo.Length <> 0 OrElse target.Query.Length <> 0 OrElse target.Fragment.Length <> 0 Then Throw New AttendanceDisplayException("إعداد عنوان خدمة الدوام غير صالح.")
        Dim result As New DataTable()
        For Each name In {"PunchTime", "PunchState", "VerifyType", "Terminal", "Area", "Source"}
            result.Columns.Add(name, GetType(String))
        Next
        Using request As New HttpRequestMessage(HttpMethod.Post, New Uri(target, "api/attendance/transactions"))
            Dim body = JsonConvert.SerializeObject(New With {.username = Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("BioUsername"), Byte())), .password = Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("BioPassword"), Byte())), .employeeCode = Convert.ToString(employee("Employee_Number"), CultureInfo.InvariantCulture), .fromDate = fromDate, .toDate = toDate})
            request.Content = New StringContent(body, Encoding.UTF8, "application/json")
            body = Nothing
            request.Headers.Authorization = New AuthenticationHeaderValue("Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes(CStr(row("ApiUsername")) & ":" & Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("ApiPassword"), Byte())))))
            request.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))
            Using response = Await Client.SendAsync(request).ConfigureAwait(False)
                If Not response.IsSuccessStatusCode Then
                    Select Case CInt(response.StatusCode)
                        Case 401, 403 : Throw New AttendanceDisplayException("تعذّر التحقق من صلاحيات تكامل الدوام. يرجى مراجعة مدير النظام.")
                        Case 503, 504 : Throw New AttendanceDisplayException("خدمة الدوام غير متاحة حاليًا. يرجى المحاولة لاحقًا.")
                        Case Else : Throw New AttendanceDisplayException("تعذّر استرجاع حركات الدوام. يرجى المحاولة لاحقًا.")
                    End Select
                End If
                Dim payload = JObject.Parse(Await response.Content.ReadAsStringAsync().ConfigureAwait(False))
                Dim records = TryCast(payload("Data"), JArray)
                If payload("Success") Is Nothing OrElse Not CBool(payload("Success")) OrElse records Is Nothing Then Throw New AttendanceDisplayException("استجابة خدمة الدوام غير صالحة.")
                For Each item In records
                    result.Rows.Add(Text(item, "punch_time"), State(Text(item, "punch_state")), Text(item, "verify_type"), Text(item, "terminal_alias"), Text(item, "area_alias"), Text(item, "source"))
                Next
            End Using
        End Using
        result.DefaultView.Sort = "PunchTime ASC"
        Return result.DefaultView.ToTable()
    End Function
    Private Shared Function Text(item As JToken, name As String) As String
        Return If(item(name) Is Nothing, "", item(name).ToString())
    End Function
    Private Shared Function State(value As String) As String
        Select Case value
            Case "0" : Return "دخول"
            Case "1" : Return "خروج"
            Case "2" : Return "بداية استراحة"
            Case "3" : Return "نهاية استراحة"
            Case "4" : Return "دخول إضافي"
            Case "5" : Return "خروج إضافي"
            Case Else : Return value
        End Select
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        System.Diagnostics.Trace.TraceWarning("Portal attendance failed ({0}).", ex.GetType().Name)
        If TypeOf ex Is AttendanceDisplayException Then Return ex.Message
        Return "تعذّر تحميل بيانات الدوام. يرجى المحاولة لاحقًا أو مراجعة مدير النظام."
    End Function
End Class

Public Class AttendanceDisplayException
    Inherits Exception
    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class
