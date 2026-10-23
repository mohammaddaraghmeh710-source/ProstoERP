Imports System.Data
Imports System.Collections.Generic
Imports System.Globalization
Imports System.Linq
Imports System.Text
Imports System.Threading
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

Public Class HRProfile
    Inherits PageBase
    Private employeeId As Integer
    Private includeSalary As Boolean
    Private includeAttendance As Boolean
    Private includeOffDates As Boolean
    Private includePenalties As Boolean
    Private salaryDate As DateTime
    Private initialError As String
    Private ReadOnly Property Actor As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("~/Login.aspx") : Return
        ViewStateUserKey = Session.SessionID
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        Response.Cache.SetRevalidation(System.Web.HttpCacheRevalidation.AllCaches)
        Dim idText = Request.QueryString("EmployeeID")
        If idText Is Nothing Then
            employeeId = Actor
        ElseIf Not Integer.TryParse(idText, employeeId) OrElse employeeId <= 0 Then
            Throw New System.Web.HttpException(400, "رقم ملف الموظف غير صالح.")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 AndAlso employeeId <> Actor Then Throw New System.Web.HttpException(403, "غير مسموح بعرض بيانات هذا الموظف.")
        ' Validate every request, including master timer postbacks, before rendering any data.
        Try
            EmployeeHRData.Context(Actor, employeeId)
        Catch ex As Exception
            initialError = EmployeeHRData.ErrorText(ex)
        End Try
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        includeSalary = WasRequested("salary")
        includeAttendance = WasRequested("attendance")
        includeOffDates = WasRequested("offdates")
        includePenalties = WasRequested("penalties")
        If includeSalary AndAlso Not ParseDate(txtSalaryMonth.Text & "-01", salaryDate) Then salaryDate = DateTime.MinValue
        lnkProfile.NavigateUrl = "~/Modules/Employees/MyProfile.aspx?EmployeeID=" & employeeId.ToString(CultureInfo.InvariantCulture)
        If initialError IsNot Nothing Then
            litMessage.Text = Alert(initialError)
            btnRefresh.Enabled = False : btnSalary.Enabled = False
            btnAttendance.Enabled = False : btnOffDates.Enabled = False : btnPenalties.Enabled = False
            Return
        End If
        If Not IsPostBack Then
            txtSalaryMonth.Text = AttendanceData.Today().Substring(0, 7)
            txtOffMonth.Text = txtSalaryMonth.Text
            txtAttendanceFrom.Text = AttendanceData.Today() : txtAttendanceTo.Text = txtAttendanceFrom.Text
            RegisterAsyncTask(New PageAsyncTask(AddressOf LoadHR))
        End If
    End Sub

    ' Persist request intent only; profile/financial results are never in ViewState.
    Private Function WasRequested(name As String) As Boolean
        Return ViewState("HRRequested:" & name) IsNot Nothing AndAlso CBool(ViewState("HRRequested:" & name))
    End Function

    Protected Sub ShowAttendance(sender As Object, e As EventArgs)
        includeAttendance = True : ViewState("HRRequested:attendance") = True
        RefreshData(sender, e)
    End Sub
    Protected Sub ShowOffDates(sender As Object, e As EventArgs)
        includeOffDates = True : ViewState("HRRequested:offdates") = True
        RefreshData(sender, e)
    End Sub
    Protected Sub ShowPenalties(sender As Object, e As EventArgs)
        includePenalties = True : ViewState("HRRequested:penalties") = True
        RefreshData(sender, e)
    End Sub

    Protected Sub RefreshData(sender As Object, e As EventArgs)
        If initialError IsNot Nothing Then Return
        RegisterAsyncTask(New PageAsyncTask(AddressOf LoadHR))
    End Sub

    Protected Sub ShowSalary(sender As Object, e As EventArgs)
        If initialError IsNot Nothing Then Return
        If Not DateTime.TryParseExact(txtSalaryMonth.Text & "-01", "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, salaryDate) OrElse salaryDate.Year < 1900 OrElse salaryDate.Year > 2100 Then
            salaryDate = DateTime.MinValue
        End If
        includeSalary = True : ViewState("HRRequested:salary") = True
        RegisterAsyncTask(New PageAsyncTask(AddressOf LoadHR))
    End Sub

    Private Async Function LoadHR() As Task
        Try
            Dim context = EmployeeHRData.Context(Actor, employeeId)
            Dim empNo = CInt(context("Employee_Number"))
            Dim api = EmployeeHRData.Api(context)
            Dim attendanceTask As Task(Of DataTable) = Nothing
            If includeAttendance AndAlso AttendanceData.ValidDates(txtAttendanceFrom.Text, txtAttendanceTo.Text) Then
                attendanceTask = AttendanceData.Transactions(Actor, context, txtAttendanceFrom.Text, txtAttendanceTo.Text)
            End If
            Dim personal = "", finance = "", shift = "", filesMessage = "", custody = "", salary = Empty("اختر الشهر ثم اضغط عرض قسيمة الراتب لعرض العلاوات والاقتطاعات.")
            Dim apiIdentity As String = ""
            Dim hrEmployee As JObject = Nothing
            Dim files As New List(Of Object)
            Try
                Dim employee = Await api.Employee(empNo)
                hrEmployee = employee
                personal = Fields(employee, PersonalFields)
                finance = Fields(employee, FinanceFields)
                If employee.GetValue("EssSalary", StringComparison.OrdinalIgnoreCase) Is Nothing AndAlso employee.GetValue("TotalSalary", StringComparison.OrdinalIgnoreCase) Is Nothing Then
                    finance &= "<p class='text-muted small mt-3 mb-0'>لم تُرجع خدمة الموارد البشرية الراتب الأساسي أو إجمالي الراتب ضمن بطاقة الموظف.</p>"
                End If
                apiIdentity = "<p class='mb-2'>" & H(EmployeeHRData.Value(employee, "ArEmployeeName")) & " · " & H(EmployeeHRData.Value(employee, "EmpNo")) & "</p>"
                Dim shiftNo = EmployeeHRClient.Number(employee, "ShiftNo")
                If shiftNo > 0 Then
                    Try
                        Dim record = Await api.Shift(shiftNo)
                        shift = If(record Is Nothing, Empty("لا توجد بيانات لهذه الوردية في نظام الموارد البشرية."), Fields(record, {"ShiftNo|رقم الوردية", "ArName|اسم الوردية", "EnName|اسم الوردية بالإنجليزية"}))
                    Catch ex As Exception
                        shift = Alert(EmployeeHRData.ErrorText(ex))
                    End Try
                Else
                    shift = Empty("لا توجد وردية مرتبطة ببطاقة الموظف في نظام الموارد البشرية.")
                End If
            Catch ex As Exception
                personal = Alert(EmployeeHRData.ErrorText(ex))
                finance = Empty("تعذّر تحميل البيانات المالية من بطاقة الموظف.")
                shift = Empty("تعذّر تحديد وردية الموظف.")
            End Try
            ' All unfiltered cards load together, with at most three related reads in flight.
            Dim gate As New SemaphoreSlim(3, 3)
            Dim sections = {"qualification", "specialization", "children", "wives", "references", "education", "experience", "offdates", "penalties"}
            Dim detailTasks = sections.Select(Function(kind) LimitedRelated(api, empNo, hrEmployee, kind, gate)).ToArray()
            Dim attendanceHtmlTask = RelatedDetails(api, empNo, hrEmployee, "attendance", attendanceTask)
            ' Independent file and custody reads retain their existing request bounds.
            Dim filesTask = api.Attachments(empNo)
            Dim custodyTask = api.Custody(empNo)
            Try
                Dim attachments = Await filesTask
                For Each attachment In attachments
                    files.Add(New With {.Name = EmployeeHRData.Value(attachment, "AttachName"), .EntryDate = EmployeeHRData.Value(attachment, "EntryDate"), .ExpiryDate = EmployeeHRData.Value(attachment, "ExpDate"), .Url = EmployeeHRData.FileUrl(EmployeeHRData.Value(attachment, "AttachPath"))})
                Next
                If files.Count = 0 Then filesMessage = Empty("لم تُرجع خدمة الموارد البشرية ملفات لهذا الموظف.")
            Catch ex As Exception
                filesMessage = Alert(EmployeeHRData.ErrorText(ex))
            End Try
            Try
                Dim records = Await custodyTask
                Dim html As New StringBuilder()
                For Each record In records
                    html.Append("<div class='border-bottom mb-3 pb-2'>").Append(Fields(record, CustodyFields)).Append("</div>")
                Next
                custody = If(records.Count = 0, Empty("لم تُرجع خدمة الموارد البشرية عهدًا لهذا الموظف."), html.ToString())
            Catch ex As Exception
                custody = Alert(EmployeeHRData.ErrorText(ex))
            End Try
            If includeSalary Then
                Try
                    Dim slips = Await api.Salary(empNo, salaryDate.Month, salaryDate.Year)
                    Dim html As New StringBuilder()
                    For Each slip In slips
                        Dim rendered = SalaryDetails(slip)
                        If rendered.Length = 0 Then Throw New HRDisplayException("حقول قسيمة الراتب المرتجعة غير موثقة. يلزم تأكيد نموذج الاستجابة لدى مزود الخدمة.")
                        html.Append("<div class='border-bottom mb-3 pb-2'>").Append(rendered).Append("</div>")
                    Next
                    salary = If(slips.Count = 0, Empty("لم تُرجع خدمة الموارد البشرية قسيمة راتب للفترة المحددة."), "<p class='text-muted'>" & H(salaryDate.ToString("yyyy-MM", CultureInfo.InvariantCulture)) & "</p>" & html.ToString())
                Catch ex As Exception
                    salary = Alert(EmployeeHRData.ErrorText(ex))
                End Try
            End If
            Dim details = Await Task.WhenAll(detailTasks)
            gate.Dispose()
            Dim attendance = Await attendanceHtmlTask
            ' Recheck current ownership and tenant after network waits; discard stale data.
            Dim current = EmployeeHRData.Context(Actor, employeeId)
            If CInt(current("Brand_ID")) <> CInt(context("Brand_ID")) OrElse CInt(current("Employee_Number")) <> empNo Then Throw New HRDisplayException("تغير ارتباط الموظف أثناء التحميل. يرجى تحديث الصفحة.")
            litIdentity.Text = apiIdentity
            litPersonal.Text = personal : litFinance.Text = finance : litShift.Text = shift : litSalary.Text = salary
            litCustody.Text = custody
            Dim controls = DetailControls()
            For i = 0 To controls.Length - 1
                controls(i).Text = details(i)
            Next
            litAttendance.Text = attendance
            litFilesMessage.Text = filesMessage
            rptFiles.DataSource = files : rptFiles.DataBind()
        Catch ex As Exception
            litIdentity.Text = "" : litPersonal.Text = "" : litFinance.Text = "" : litShift.Text = "" : litSalary.Text = "" : litFilesMessage.Text = ""
            litCustody.Text = ""
            For Each control In DetailControls()
                control.Text = ""
            Next
            litAttendance.Text = ""
            rptFiles.DataSource = Nothing : rptFiles.DataBind()
            litMessage.Text = Alert(EmployeeHRData.ErrorText(ex))
        End Try
    End Function

    Private Function DetailControls() As System.Web.UI.WebControls.Literal()
        Return {litQualification, litSpecialization, litChildren, litWives, litReferences, litEducation, litExperience, litOffDates, litPenalties}
    End Function

    Private Async Function LimitedRelated(api As EmployeeHRClient, empNo As Integer, employee As JObject, kind As String, gate As SemaphoreSlim) As Task(Of String)
        Await gate.WaitAsync()
        Try
            Return Await RelatedDetails(api, empNo, employee, kind, Nothing)
        Finally
            gate.Release()
        End Try
    End Function

    Private Async Function RelatedDetails(api As EmployeeHRClient, empNo As Integer, employee As JObject, kind As String, attendanceTask As Task(Of DataTable)) As Task(Of String)
        Try
            Dim rows As List(Of JObject)
            Dim specs As String()
            Select Case kind
                Case "qualification", "specialization"
                    If employee Is Nothing Then Return Empty("تعذّر تحديد البيانات المرتبطة ببطاقة الموظف.")
                    Dim key = If(kind = "qualification", "QualificationNo", "SpecializationNo")
                    Dim record = Await api.Catalog(kind, EmployeeHRClient.Number(employee, key))
                    If record Is Nothing Then Return Empty("لم تُرجع الخدمة تعريفًا مرتبطًا ببطاقة الموظف لهذا القسم.")
                    Return Fields(record, {key & "|الرقم", "ArName|الاسم بالعربية", "EnName|الاسم بالإنجليزية"})
                Case "children"
                    specs = {"SrNo|التسلسل", "ChildName|اسم الابن أو الابنة", "BirthDate|تاريخ الميلاد", "InsuranceValue|قيمة التأمين", "ChkInsurance|مشمول بالتأمين", "ChkStudy|يدرس", "Specification|الصفة", "Notes|ملاحظات"}
                Case "wives"
                    specs = {"SrNo|التسلسل", "Name|الاسم", "BirthDate|تاريخ الميلاد", "InsuranceValue|قيمة التأمين", "ChkInsurance|مشمول بالتأمين", "Notes|ملاحظات"}
                Case "references"
                    specs = {"SrNo|التسلسل", "ReferenceName|اسم المعرّف", "PhoneNo|الهاتف", "Address|العنوان"}
                Case "education"
                    specs = {"SrNo|التسلسل", "CollegeOrUniversity|الكلية أو الجامعة", "Country|الدولة", "FromDate|من تاريخ", "ToDate|إلى تاريخ", "Qualification|المؤهل", "Specification|التخصص"}
                Case "experience"
                    specs = {"SrNo|التسلسل", "WorkPlace|مكان العمل", "StartedDate|تاريخ البداية", "FinishedDate|تاريخ النهاية", "WorkType|نوع العمل", "ResponsiblePerson|الشخص المسؤول", "PhoneNo|الهاتف", "Address|العنوان"}
                Case "penalties"
                    If Not includePenalties Then Return Empty("أدخل رقم الجزاء أو الإنذار ثم اضغط عرض الجزاء أو الإنذار.")
                    Dim penaltyNo As Integer
                    If Not Integer.TryParse(txtPenaltyNo.Text, penaltyNo) OrElse penaltyNo <= 0 Then Return Empty("أدخل رقم الجزاء أو الإنذار ثم اضغط زر العرض في البطاقة.")
                    rows = Await api.Penalty(empNo, penaltyNo)
                    Return Records(rows, {"PenaltyNo|رقم الجزاء", "PenaltyDate|تاريخ الجزاء", "PayableDate|تاريخ الاستحقاق", "PenaltyType|رمز نوع الجزاء", "ContraventionNo|رقم المخالفة", "PenaltyDesc|وصف الجزاء", "PenaltyDescription|تفاصيل الجزاء أو الإنذار", "DropPenalty|إسقاط الجزاء", "Overstep|تجاوز", "DiffDay|عدد الأيام"})
                Case "offdates"
                    If Not includeOffDates Then Return Empty("أدخل معايير العطلة ثم اضغط عرض العطلة.")
                    Dim serial As Integer, period, offDate, startDate As DateTime
                    If Not Integer.TryParse(txtOffSerial.Text, serial) OrElse serial <= 0 OrElse Not ParseDate(txtOffMonth.Text & "-01", period) OrElse Not ParseDate(txtOffDate.Text, offDate) OrElse Not ParseDate(txtOffStart.Text, startDate) Then Return Empty("أدخل تسلسل العطلة والشهر وتاريخ العطلة وتاريخ البداية ثم اضغط زر العرض في البطاقة.")
                    rows = Await api.OffDates(empNo, serial, period, offDate, startDate)
                    Return Records(rows, {"SrNo|التسلسل", "MonthNo|الشهر", "YearNo|السنة", "OffDate|تاريخ العطلة", "StartDate|تاريخ البداية", "Notes|ملاحظات"})
                Case "attendance"
                    If Not includeAttendance Then Return Empty("حدد الفترة ثم اضغط عرض كشف الدوام.")
                    If attendanceTask Is Nothing Then Return Alert("أدخل فترة دوام صحيحة بحيث لا يتجاوز تاريخ البداية تاريخ النهاية.")
                    Dim data = Await attendanceTask
                    If data.Rows.Count = 0 Then Return Empty("لم تُرجع خدمة الدوام حركات ضمن الفترة المحددة.")
                    Dim html As New StringBuilder("<div class='table-responsive'><table class='table table-bordered card-list-table'><thead><tr><th>وقت الحركة</th><th>الحركة</th><th>طريقة التحقق</th><th>الجهاز</th><th>المنطقة</th><th>المصدر</th></tr></thead><tbody>")
                    Dim labels = {"وقت الحركة", "الحركة", "طريقة التحقق", "الجهاز", "المنطقة", "المصدر"}
                    Dim names = {"PunchTime", "PunchState", "VerifyType", "Terminal", "Area", "Source"}
                    For Each row As DataRow In data.Rows
                        html.Append("<tr>")
                        For i = 0 To names.Length - 1
                            html.Append("<td data-title='").Append(H(labels(i))).Append("'>").Append(H(Convert.ToString(row(names(i))))).Append("</td>")
                        Next
                        html.Append("</tr>")
                    Next
                    Return html.Append("</tbody></table></div>").ToString()
                Case Else
                    Return Alert("قسم الموارد البشرية غير صالح.")
            End Select
            rows = Await api.Related(empNo, kind)
            Return Records(rows, specs)
        Catch ex As AttendanceDisplayException
            Return Alert(AttendanceData.ErrorText(ex))
        Catch ex As Exception
            Return Alert(EmployeeHRData.ErrorText(ex))
        End Try
    End Function

    Private Shared Function ParseDate(value As String, ByRef result As DateTime) As Boolean
        Return DateTime.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, result) AndAlso result.Year >= 1900 AndAlso result.Year <= 2100
    End Function

    Private Shared Function Records(rows As List(Of JObject), specs As String()) As String
        If rows.Count = 0 Then Return Empty("لم تُرجع خدمة الموارد البشرية بيانات لهذا القسم.")
        Dim html As New StringBuilder()
        For Each row In rows
            html.Append("<div class='border-bottom mb-3 pb-2'>").Append(Fields(row, specs)).Append("</div>")
        Next
        Return html.ToString()
    End Function

    Private Shared ReadOnly PersonalFields As String() = {
        "EmpNo|الرقم الوظيفي", "ArEmployeeName|الاسم بالعربية", "EnEmployeeName|الاسم بالإنجليزية",
        "ArFirstName|الاسم الأول", "ArSecondName|اسم الأب", "ArThirdName|اسم الجد", "ArFourthName|اسم العائلة",
        "DateOfBirth|تاريخ الميلاد", "PlaceOfBirth|مكان الميلاد", "NationalityNo|رقم الجنسية", "IDNumber|رقم الهوية", "NationalNo|الرقم الوطني",
        "Address1|العنوان", "Address2|العنوان الإضافي", "Phone1|الهاتف", "Phone2|الهاتف الإضافي", "EnternalPhone|الهاتف الداخلي", "Email|البريد الإلكتروني",
        "EmpStarted|تاريخ بدء العمل", "JobNo|رقم الوظيفة", "EmpType|رمز نوع التوظيف", "QualificationNo|رقم المؤهل", "SpecializationNo|رقم التخصص",
        "WorkHoursDaily|ساعات العمل اليومية", "ChkFinishWork|منتهي الخدمة", "WorkFinishDate|تاريخ انتهاء الخدمة", "WorkFinishReason|سبب انتهاء الخدمة"}

    Private Shared ReadOnly FinanceFields As String() = {
        "EssSalary|الراتب الأساسي", "Transfer|النقل", "Allowances|العلاوات", "TotalSalary|إجمالي الراتب",
        "EssSalaryCurrency|الراتب بالعملة", "ContractSalary|راتب العقد", "ContractH|ساعات العقد", "AddSal|قيمة الإضافة",
        "MainBankNo|رقم البنك", "SubBankNo|رقم فرع البنك", "AccBankNo|الحساب البنكي", "RecieptMethod|رمز طريقة استلام الراتب",
        "SocialInsuranceChk|مشترك بالضمان", "SocialInsuranceNo|رقم الضمان", "SocialInsuranceSalary|الراتب الخاضع للضمان",
        "SocialInsuranceDate|تاريخ الضمان", "Insurance|قيمة التأمين", "InsuranceCompany|تأمين الشركة", "IncomeTax|خاضع لضريبة الدخل", "IncomeTaxNo|الرقم الضريبي"}

    Private Shared ReadOnly CustodyFields As String() = {
        "SrNo|التسلسل", "ContractNo|رقم العهدة", "NoOfContract|الكمية", "Status|الحالة",
        "UnitCost|تكلفة الوحدة", "Cost|التكلفة", "ReceiptDate|تاريخ الاستلام", "ReturnDate|تاريخ الإرجاع"}

    ' Salary-only mappings verified from a live populated GetSalarySlip response.
    ' Numbered allowances retain generic labels until the provider supplies their names.
    Private Shared ReadOnly SalarySummaryFields As String() = {
        "EssSalary|الراتب الأساسي", "PayableSalary|الراتب المستحق", "TotalSalary|إجمالي الراتب", "NetSalary|صافي الراتب"}
    Private Shared ReadOnly AllowanceFields As String() = {
        "TotalAllowance|إجمالي العلاوات", "Allow1|العلاوة 1", "Allow2|العلاوة 2", "Allow3|العلاوة 3",
        "Allow4|العلاوة 4", "Allow5|العلاوة 5", "Allow6|العلاوة 6", "Allow7|العلاوة 7", "Allow8|العلاوة 8", "Allow9|العلاوة 9",
        "AddOverTime|العمل الإضافي", "AddCommission|العمولات", "AddReward|المكافآت", "AddLeave|إضافات الإجازات",
        "OtherAdditions|إضافات أخرى", "TotalBonus|إجمالي الإضافات"}
    Private Shared ReadOnly DeductionFields As String() = {
        "IncomeTax|ضريبة الدخل", "DedEmpSocialIns|اقتطاع الضمان الاجتماعي", "Deductions|الاقتطاعات",
        "DeductionLoan|اقتطاع القروض", "DedLeave|اقتطاع الإجازات", "DedPenalty|اقتطاع الجزاءات",
        "DedAbsence|اقتطاع الغياب", "DedLate|اقتطاع التأخير", "SavingsBox|صندوق الادخار", "TotalDeduction|إجمالي الاقتطاعات"}

    Private Shared Function SalaryDetails(record As JObject) As String
        Dim summary = Fields(record, SalarySummaryFields, False)
        Dim allowances = Fields(record, AllowanceFields, False)
        Dim deductions = Fields(record, DeductionFields, False)
        If summary.Length = 0 AndAlso allowances.Length = 0 AndAlso deductions.Length = 0 Then Return ""
        Return "<h6>ملخص الراتب</h6>" & If(summary.Length = 0, Empty("لم تُرجع الخدمة ملخص الراتب."), summary) &
            "<div class='row mt-3'><div class='col-lg-6'><h6>العلاوات والإضافات</h6>" & If(allowances.Length = 0, Empty("لم تُرجع الخدمة تفاصيل العلاوات."), allowances) &
            "</div><div class='col-lg-6'><h6>الاقتطاعات</h6>" & If(deductions.Length = 0, Empty("لم تُرجع الخدمة تفاصيل الاقتطاعات."), deductions) & "</div></div>"
    End Function

    Private Shared Function Fields(record As JObject, specs As String(), Optional showEmpty As Boolean = True) As String
        Dim html As New StringBuilder()
        For Each spec In specs
            Dim pair = spec.Split("|"c)
            Dim value = EmployeeHRData.Value(record, pair(0))
            If value.Length = 0 Then Continue For
            html.Append("<dt class='col-sm-5 text-muted fw-normal'>").Append(H(pair(1))).Append("</dt><dd class='col-sm-7 text-break'>").Append(H(value)).Append("</dd>")
        Next
        If html.Length = 0 Then Return If(showEmpty, Empty("لا توجد بيانات متاحة لهذا القسم."), "")
        Return "<dl class='row mb-0'>" & html.ToString() & "</dl>"
    End Function
    Private Shared Function H(value As String) As String
        Return System.Web.HttpUtility.HtmlEncode(value)
    End Function
    Private Shared Function Alert(value As String) As String
        Return "<div class='alert alert-warning mb-0' role='alert'>" & H(value) & "</div>"
    End Function
    Private Shared Function Empty(value As String) As String
        Return "<p class='text-muted mb-0'>" & H(value) & "</p>"
    End Function
End Class
