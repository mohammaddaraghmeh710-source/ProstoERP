Imports System.Data.SqlClient
Imports System.Web

Public NotInheritable Class FeedbackPresentation
    Public Shared Function Metric(title As String,value As Integer,icon As String,color As String,Optional href As String="") As String
        Dim body="<div class=""card-body p-3""><div class=""row g-2 align-items-center""><div class=""col""><span class=""text-muted small"">" & HttpUtility.HtmlEncode(title) & "</span><h3 class=""mb-0 mt-1"">" & value.ToString() & "</h3></div><div class=""col-auto""><div class=""avatar""><span class=""avatar-initial rounded bg-label-" & color & """><i class=""bx " & icon & """ aria-hidden=""true""></i></span></div></div></div></div>"
        Return "<div class=""col""><" & If(href="","section","a") & If(href="",""," href=""" & HttpUtility.HtmlAttributeEncode(href) & """") & " class=""card h-100 text-body"">" & body & "</" & If(href="","section","a") & "></div>"
    End Function
    Public Shared Function Info(label As String,value As Object,icon As String) As String
        Return "<div class=""col-sm-6 col-xl-4""><div class=""d-inline-flex align-items-start gap-2""><i class=""bx " & icon & " text-primary mt-1"" aria-hidden=""true""></i><div><div class=""small text-muted mb-1"">" & HttpUtility.HtmlEncode(label) & "</div><div class=""text-break"">" & HttpUtility.HtmlEncode(EmployeeFeedbackCatalog.Display(value)) & "</div></div></div></div>"
    End Function
    Public Shared Function Contact(row As FeedbackApplicant) As String
        If Not row.CanViewContact Then Return "<div class=""alert alert-secondary mb-0"" role=""status""><i class=""bx bx-lock-alt me-2"" aria-hidden=""true""></i>اختار مقدم الطلب إخفاء هويته؛ بيانات التواصل غير متاحة.</div>"
        Return "<div class=""row g-3"">" & Info("الاسم",row.ApplicantName,"bx-user") & Info("الاسم بالإنجليزية",row.ApplicantNameEn,"bx-user-circle") & Info("الرقم الوظيفي",row.ApplicantEmployeeNumber,"bx-id-card") & Info("رقم الجوال",row.ApplicantMobile,"bx-mobile-alt") & Info("رقم الهاتف",row.ApplicantPhone,"bx-phone") & Info("البريد الإلكتروني",row.ApplicantEmail,"bx-envelope") & "</div>"
    End Function

    Public Shared Function LogDate(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "—"
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(CDate(value),DateTimeKind.Utc),TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString("yyyy/MM/dd HH:mm:ss")
    End Function

    Public Shared Function StatusText(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "جديد"
            Case 2 : Return "قيد المعالجة"
            Case Else : Return "مغلق"
        End Select
    End Function

    Public Shared Function StatusCss(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "badge bg-label-warning"
            Case 2 : Return "badge bg-label-success"
            Case Else : Return "badge bg-label-danger"
        End Select
    End Function

    Public Shared Function ActionText(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "تقديم"
            Case 2 : Return "تحويل"
            Case Else : Return "إغلاق"
        End Select
    End Function

    Public Shared Function TypeText(value As Object) As String
        Return EmployeeFeedbackCatalog.TypeName(Convert.ToInt32(value))
    End Function

    Public Shared Function ErrorText(ex As Exception) As String
        System.Diagnostics.Trace.TraceError("EmployeeFeedback: {0}", ex)
        Dim sql=TryCast(ex,SqlException)
        If sql IsNot Nothing AndAlso sql.Number=51500 Then Return sql.Message
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Return "تعذر تنفيذ العملية، يرجى المحاولة مجددًا."
    End Function

    Public Shared Sub FillTypes(list As System.Web.UI.WebControls.DropDownList,actor As Integer,mode As Integer,placeholder As String)
        list.Items.Clear() : list.Items.Add(New System.Web.UI.WebControls.ListItem(placeholder,"0"))
        For Each row In EmployeeFeedbackCatalog.Types(actor,mode)
            list.Items.Add(New System.Web.UI.WebControls.ListItem(row.Title_Ar & If(row.IsDeleted," (مؤرشف)",If(row.IsActive,""," (غير فعال)")),row.ID.ToString()))
        Next
    End Sub

    Public Shared Function SourceName(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "موظف"
            Case 2 : Return "زبون"
            Case Else : Return "غير محدد"
        End Select
    End Function

    Public Shared Function Display(value As Object) As String
        Return If(value Is Nothing OrElse IsDBNull(value) OrElse String.IsNullOrWhiteSpace(Convert.ToString(value)),"غير مسجل",Convert.ToString(value))
    End Function
End Class
