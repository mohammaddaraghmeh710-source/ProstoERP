Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.IO
Imports System.Linq
Imports System.Collections.Generic
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading
Imports System.Threading.Tasks
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

Public NotInheritable Class EmployeeHRData
    ' The .NET Framework HttpWebRequest backend rejects GET bodies. WinHTTP preserves
    ' Bonanza's documented GET + BodyParam contract without reflection or verb rewriting.
    Private Shared ReadOnly Client As New HttpClient(CreateHandler()) With {.Timeout = TimeSpan.FromSeconds(25)}

    Public Shared Function CreateHandler() As WinHttpHandler
        Return New WinHttpHandler With {.AutomaticRedirection = False, .CookieUsePolicy = CookieUsePolicy.IgnoreCookies, .WindowsProxyUsePolicy = WindowsProxyUsePolicy.DoNotUseProxy, .SendTimeout = TimeSpan.FromSeconds(25), .ReceiveHeadersTimeout = TimeSpan.FromSeconds(25), .ReceiveDataTimeout = TimeSpan.FromSeconds(25)}
    End Function

    ' Existing account/settings data is used only for authorization and routing.
    ' No local profile values are returned to the view and no schema update is needed.
    Private Const ContextSql As String = "
SELECT e.ID,e.Employee_Number,e.Brand_ID,s.HrUrl,s.HrUsername,s.HrPassword
FROM dbo.UsersMembers e
JOIN dbo.Brands b ON b.ID=e.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
LEFT JOIN dbo.AttendanceIntegrationSettings s ON s.BrandID=e.Brand_ID
WHERE e.ID=@EmployeeID AND e.IsActive=1 AND ISNULL(e.IsDeleted,0)=0 AND e.Type<>7
AND e.Employee_Number>0
AND EXISTS(SELECT 1 FROM dbo.UsersMembers actor WHERE actor.ID=@Actor AND actor.IsActive=1
 AND ISNULL(actor.IsDeleted,0)=0 AND actor.Type<>7 AND (actor.Type=1 OR actor.ID=e.ID))
AND NOT EXISTS(SELECT 1 FROM dbo.UsersMembers other WHERE other.ID<>e.ID AND other.Brand_ID=e.Brand_ID
 AND other.Employee_Number=e.Employee_Number AND other.IsActive=1 AND ISNULL(other.IsDeleted,0)=0 AND other.Type<>7)"

    Public Shared Function Context(actor As Integer, employeeId As Integer) As DataRow
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext(), command As New SqlCommand(ContextSql, DirectCast(db.Connection, SqlConnection))
            command.Parameters.Add("@Actor", SqlDbType.Int).Value = actor
            command.Parameters.Add("@EmployeeID", SqlDbType.Int).Value = employeeId
            Using adapter As New SqlDataAdapter(command)
                Dim rows As New DataTable()
                adapter.Fill(rows)
                If rows.Rows.Count <> 1 Then Throw New HRDisplayException("الموظف غير متاح أو رقمه الوظيفي غير محدد بشكل فريد ضمن العلامة التجارية.")
                Return rows.Rows(0)
            End Using
        End Using
    End Function

    Public Shared Function Api(row As DataRow) As EmployeeHRClient
        If row.IsNull("HrUrl") OrElse String.IsNullOrWhiteSpace(CStr(row("HrUrl"))) OrElse row.IsNull("HrUsername") OrElse row.IsNull("HrPassword") Then
            Throw New HRDisplayException("لم يتم إعداد اتصال الموارد البشرية لهذه العلامة التجارية. يرجى مراجعة مدير النظام.")
        End If
        Return New EmployeeHRClient(Client, CStr(row("HrUrl")), Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("HrUsername"), Byte())), Prosto_ERP_ClassLibrary.AttendanceIntegration.Unprotect(DirectCast(row("HrPassword"), Byte())))
    End Function

    Public Shared Function ErrorText(ex As Exception) As String
        ' Never log URLs, credentials, upstream bodies or employee/financial data.
        System.Diagnostics.Trace.TraceWarning("Portal HR failed ({0}).", ex.GetType().Name)
        If TypeOf ex Is HRDisplayException Then Return ex.Message
        Return "تعذّر تحميل بيانات الموارد البشرية. يرجى المحاولة لاحقًا أو مراجعة مدير النظام."
    End Function

    Public Shared Function Value(record As JObject, key As String) As String
        Dim token = record.GetValue(key, StringComparison.OrdinalIgnoreCase)
        If token Is Nothing OrElse token.Type = JTokenType.Null Then Return ""
        If Not TypeOf token Is JValue Then Return ""
        If token.Type = JTokenType.Boolean Then Return If(CBool(token), "نعم", "لا")
        If token.Type = JTokenType.Date Then Return CDate(token).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
        Return token.ToString()
    End Function

    Public Shared Function FileUrl(value As String) As String
        Dim target As Uri = Nothing
        If String.IsNullOrWhiteSpace(value) OrElse value.Length > 2000 OrElse value.Contains("\") OrElse value.Any(Function(c) Char.IsControl(c)) Then Return ""
        If Not Uri.TryCreate(value, UriKind.Absolute, target) OrElse (target.Scheme <> "https" AndAlso target.Scheme <> "http") OrElse target.UserInfo.Length > 0 Then Return ""
        Return target.AbsoluteUri
    End Function
End Class

' Bonanza read-only contract. The caller supplies server-resolved identity only.
Public NotInheritable Class EmployeeHRClient
    Private ReadOnly client As HttpClient
    Private ReadOnly baseUri As Uri
    Private ReadOnly authorization As String
    Public Sub New(http As HttpClient, url As String, username As String, password As String)
        client = http
        baseUri = New Uri(Prosto_ERP_ClassLibrary.AttendanceIntegration.NormalizeUrl(url))
        If String.IsNullOrWhiteSpace(username) OrElse username.Contains(":") OrElse String.IsNullOrEmpty(password) Then Throw New HRDisplayException("إعدادات اتصال الموارد البشرية غير صالحة.")
        authorization = Convert.ToBase64String(Encoding.UTF8.GetBytes(username & ":" & password))
    End Sub

    Public Async Function Employee(empNo As Integer) As Task(Of JObject)
        If empNo <= 0 Then Throw New HRDisplayException("الرقم الوظيفي غير صالح.")
        Dim rows = Await Read("GetPayEmployers", New JObject(New JProperty("EmpNo", empNo)), "EmpNo").ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        If rows.Count <> 1 Then Throw New HRDisplayException("لم يتم العثور على بطاقة موظف واحدة مطابقة في نظام الموارد البشرية.")
        Return rows(0)
    End Function

    Public Async Function Shift(shiftNo As Integer) As Task(Of JObject)
        If shiftNo <= 0 Then Throw New HRDisplayException("رقم الوردية غير صالح.")
        Dim rows = Await Read("GetPayEmployeeWorkHours", New JObject(New JProperty("ShiftNo", shiftNo)), "ShiftNo").ConfigureAwait(False)
        If rows.Count = 0 Then Return Nothing
        If rows.Count <> 1 OrElse Number(rows(0), "ShiftNo") <> shiftNo Then Throw New HRDisplayException("تعذّر التحقق من الوردية المرتبطة بالموظف.")
        Return rows(0)
    End Function

    Public Async Function Attachments(empNo As Integer) As Task(Of List(Of JObject))
        If empNo <= 0 Then Throw New HRDisplayException("الرقم الوظيفي غير صالح.")
        Dim rows = Await Read("GetEmployeeAttach", New JObject(New JProperty("EmpNo", empNo)), "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        Return rows
    End Function

    Public Async Function Salary(empNo As Integer, month As Integer, year As Integer) As Task(Of List(Of JObject))
        If empNo <= 0 OrElse month < 1 OrElse month > 12 OrElse year < 1900 OrElse year > 2100 Then Throw New HRDisplayException("اختر شهرًا وسنة صالحين لقسيمة الراتب.")
        Dim body As New JObject From {{"Months", month}, {"Years", year}, {"FromEmpNo", empNo}, {"ToEmpNo", empNo}, {"Rate", 1}, {"CurrencyNo", 1}}
        Dim rows = Await Read("GetSalarySlip", body, "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        For Each row In rows
            If {"Months", "EmpMonth"}.Any(Function(key) row.GetValue(key, StringComparison.OrdinalIgnoreCase) IsNot Nothing AndAlso Number(row, key) <> month) OrElse
               {"Years", "EmpYear"}.Any(Function(key) row.GetValue(key, StringComparison.OrdinalIgnoreCase) IsNot Nothing AndAlso Number(row, key) <> year) Then Throw New HRDisplayException("قسيمة الراتب المرتجعة لا تطابق الفترة المطلوبة.")
        Next
        Return rows
    End Function

    Public Async Function Custody(empNo As Integer) As Task(Of List(Of JObject))
        If empNo <= 0 Then Throw New HRDisplayException("الرقم الوظيفي غير صالح.")
        Dim rows = Await Read("GetPayContracts", New JObject(New JProperty("EmpNo", empNo)), "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        Return rows
    End Function

    Public Async Function Related(empNo As Integer, section As String) As Task(Of List(Of JObject))
        If empNo <= 0 Then Throw New HRDisplayException("الرقم الوظيفي غير صالح.")
        Dim route As String
        Select Case section
            Case "children" : route = "GetPayChildrens"
            Case "wives" : route = "GetPayWifes"
            Case "references" : route = "GetPayReferences"
            Case "education" : route = "GetPayLearning"
            Case "experience" : route = "GetPayExperienceYears"
            Case Else : Throw New HRDisplayException("قسم الموارد البشرية غير صالح.")
        End Select
        Dim rows = Await Read(route, New JObject(New JProperty("EmpNo", empNo)), "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        Return rows
    End Function

    Public Async Function Catalog(section As String, id As Integer) As Task(Of JObject)
        Dim route, key As String
        Select Case section
            Case "qualification" : route = "GetQualification" : key = "QualificationNo"
            Case "specialization" : route = "GetSpecialization" : key = "SpecializationNo"
            Case Else : Throw New HRDisplayException("قسم الموارد البشرية غير صالح.")
        End Select
        If id <= 0 Then Return Nothing
        Dim rows = Await Read(route, New JObject(New JProperty(key, id)), key, True).ConfigureAwait(False)
        If rows.Count = 0 Then Return Nothing
        If rows.Count <> 1 OrElse Number(rows(0), key) <> id Then Throw New HRDisplayException("تعذّر مطابقة التعريف المرتبط ببطاقة الموظف.")
        Return rows(0)
    End Function

    Public Async Function Penalty(empNo As Integer, penaltyNo As Integer) As Task(Of List(Of JObject))
        If empNo <= 0 OrElse penaltyNo <= 0 Then Throw New HRDisplayException("أدخل رقم الجزاء أو الإنذار المطلوب.")
        Dim rows = Await Read("GetPayTransAllPenalties", New JObject From {{"EmpNo", empNo}, {"PenaltyNo", penaltyNo}}, "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        If rows.Any(Function(row) Number(row, "PenaltyNo") <> penaltyNo) Then Throw New HRDisplayException("الجزاء المرتجع لا يطابق الرقم المطلوب.")
        Return rows
    End Function

    Public Async Function OffDates(empNo As Integer, serial As Integer, period As DateTime, offDate As DateTime, startDate As DateTime) As Task(Of List(Of JObject))
        If empNo <= 0 OrElse serial <= 0 OrElse period.Year < 1900 OrElse period.Year > 2100 OrElse offDate.Year < 1900 OrElse startDate.Year < 1900 Then Throw New HRDisplayException("أدخل تسلسل العطلة والشهر وتاريخ العطلة وتاريخ البداية.")
        Dim body As New JObject From {{"EmpNo", empNo}, {"SrNo", serial}, {"MonthNo", period.Month}, {"YearNo", period.Year}, {"OffDate", offDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}, {"StartDate", startDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}}
        Dim rows = Await Read("GetPayOffDates", body, "EmpNo", True).ConfigureAwait(False)
        ValidateOwner(rows, empNo)
        For Each row In rows
            Dim returnedOff, returnedStart As DateTime
            If Number(row, "SrNo") <> serial OrElse Number(row, "MonthNo") <> period.Month OrElse Number(row, "YearNo") <> period.Year OrElse
                Not DateTime.TryParse(EmployeeHRData.Value(row, "OffDate"), CultureInfo.InvariantCulture, DateTimeStyles.None, returnedOff) OrElse returnedOff.Date <> offDate.Date OrElse
                Not DateTime.TryParse(EmployeeHRData.Value(row, "StartDate"), CultureInfo.InvariantCulture, DateTimeStyles.None, returnedStart) OrElse returnedStart.Date <> startDate.Date Then Throw New HRDisplayException("العطلة المرتجعة لا تطابق معايير الاستعلام.")
        Next
        Return rows
    End Function

    Private Async Function Read(route As String, body As JObject, key As String, Optional allowNull As Boolean = False) As Task(Of List(Of JObject))
        body("Lang") = 1 : body("OperNo") = 2
        ' Preserve an optional virtual application path in the configured HR base URL.
        Using deadline As New CancellationTokenSource(TimeSpan.FromSeconds(25)), request As New HttpRequestMessage(HttpMethod.Get, New Uri(baseUri, "api/values/" & route))
            request.Headers.Authorization = New AuthenticationHeaderValue("Basic", authorization)
            request.Headers.Accept.Add(New MediaTypeWithQualityHeaderValue("application/json"))
            request.Content = New StringContent(New JObject(New JProperty("BodyParam", body)).ToString(Formatting.None), Encoding.UTF8, "application/json")
            Using response = Await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, deadline.Token).ConfigureAwait(False)
                If Not response.IsSuccessStatusCode Then Throw New HRDisplayException("تعذّر استرجاع البيانات من نظام الموارد البشرية. يرجى التحقق من الاتصال والصلاحيات لدى مدير النظام.")
                If response.Content.Headers.ContentLength.HasValue AndAlso response.Content.Headers.ContentLength.Value > 4 * 1024 * 1024 Then Throw New HRDisplayException("حجم استجابة الموارد البشرية يتجاوز الحد المسموح.")
                Using stream = Await response.Content.ReadAsStreamAsync().ConfigureAwait(False), buffer As New MemoryStream()
                    Dim bytes(8191) As Byte
                    Do
                        Dim count = Await stream.ReadAsync(bytes, 0, bytes.Length, deadline.Token).ConfigureAwait(False)
                        If count = 0 Then Exit Do
                        If buffer.Length + count > 4 * 1024 * 1024 Then Throw New HRDisplayException("حجم استجابة الموارد البشرية يتجاوز الحد المسموح.")
                        buffer.Write(bytes, 0, count)
                    Loop
                    Return Decode(Encoding.UTF8.GetString(buffer.ToArray()), key, allowNull)
                End Using
            End Using
        End Using
    End Function

    Public Shared Function Decode(json As String, key As String, Optional allowNull As Boolean = False) As List(Of JObject)
        ' The PDF omits response examples. Recognize explicit common envelopes only;
        ' never recursively collect arbitrary objects or treat an error as an empty result.
        Dim token As JToken
        Using reader As New JsonTextReader(New StringReader(json)) With {.MaxDepth = 32, .DateParseHandling = DateParseHandling.None}
            token = JToken.ReadFrom(reader)
            If reader.Read() Then Throw New HRDisplayException("صيغة استجابة الموارد البشرية غير مدعومة.")
        End Using
        For depth = 0 To 4
            ' Live Bonanza returns JSON null for optional files/slips without records.
            ' Do not accept null as an employee card or shift, or as an error envelope.
            If token.Type = JTokenType.Null AndAlso allowNull Then Return New List(Of JObject)()
            If token.Type = JTokenType.String Then
                If depth = 4 Then Exit For
                Using nested As New JsonTextReader(New StringReader(CStr(token))) With {.MaxDepth = 32, .DateParseHandling = DateParseHandling.None}
                    token = JToken.ReadFrom(nested)
                    If nested.Read() Then Throw New HRDisplayException("صيغة استجابة الموارد البشرية غير مدعومة.")
                End Using
                Continue For
            End If
            If TypeOf token Is JArray Then
                Dim items = DirectCast(token, JArray)
                If items.Count > 1000 OrElse items.Any(Function(item) Not TypeOf item Is JObject OrElse IsError(TryCast(item, JObject))) Then Exit For
                Return items.Cast(Of JObject)().ToList()
            End If
            Dim obj = TryCast(token, JObject)
            If obj Is Nothing Then Exit For
            If IsError(obj) Then Exit For
            If obj.GetValue(key, StringComparison.OrdinalIgnoreCase) IsNot Nothing Then Return New List(Of JObject) From {obj}
            Dim wrappers = {"Data", "Table", "Table1", "Result", "d"}.Select(Function(name) obj.GetValue(name, StringComparison.OrdinalIgnoreCase)).Where(Function(value) value IsNot Nothing).ToList()
            If wrappers.Count <> 1 Then Exit For
            token = wrappers(0)
        Next
        Throw New HRDisplayException("صيغة استجابة الموارد البشرية غير مدعومة. يلزم التحقق من نموذج الاستجابة لدى مزود الخدمة.")
    End Function

    Private Shared Function IsError(obj As JObject) As Boolean
        If obj Is Nothing Then Return True
        Dim success = obj.GetValue("Success", StringComparison.OrdinalIgnoreCase)
        If success IsNot Nothing AndAlso Not String.Equals(success.ToString(), "true", StringComparison.OrdinalIgnoreCase) Then Return True
        Return {"Error", "Errors", "ExceptionMessage"}.Any(Function(name) obj.GetValue(name, StringComparison.OrdinalIgnoreCase) IsNot Nothing AndAlso obj.GetValue(name, StringComparison.OrdinalIgnoreCase).Type <> JTokenType.Null)
    End Function

    Public Shared Function Number(row As JObject, key As String) As Integer
        Dim value As Integer
        Dim token = row.GetValue(key, StringComparison.OrdinalIgnoreCase)
        If token Is Nothing OrElse Not Integer.TryParse(token.ToString(), NumberStyles.None, CultureInfo.InvariantCulture, value) OrElse value <= 0 Then Return 0
        Return value
    End Function

    Private Shared Sub ValidateOwner(rows As List(Of JObject), empNo As Integer)
        If empNo <= 0 OrElse rows.Any(Function(row) Number(row, "EmpNo") <> empNo) Then Throw New HRDisplayException("تعذّر التحقق من مطابقة بيانات الموارد البشرية للموظف المطلوب.")
    End Sub
End Class

Public Class HRDisplayException
    Inherits Exception
    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class
