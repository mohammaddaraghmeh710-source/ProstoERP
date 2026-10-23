Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

Public NotInheritable Class CircularsData
    Public Shared Function Query(name As String, ParamArray parameters() As SqlParameter) As DataSet
        Using cn As New SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString),
              cmd As New SqlCommand(name, cn), adapter As New SqlDataAdapter(cmd)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddRange(parameters)
            Dim result As New DataSet()
            adapter.Fill(result)
            Return result
        End Using
    End Function
    Public Shared Function P(name As String, kind As SqlDbType, value As Object, Optional size As Integer = 0) As SqlParameter
        Return InformationPagesData.P(name, kind, value, size)
    End Function
    Public Shared Function Label(value As Object) As String
        Select Case Convert.ToString(value)
            Case "active" : Return "فعال"
            Case "scheduled" : Return "لم تبدأ صلاحيته"
            Case "expired" : Return "منتهي"
            Case "disabled" : Return "غير مفعّل"
            Case "all" : Return "جميع الموظفين"
            Case "customers" : Return "عملاء محددون بالاسم"
            Case "customerTypes" : Return "أنواع العملاء"
            Case "roles" : Return "أنواع مستخدمين محددة"
            Case "organization" : Return "معايير تنظيمية"
            Case "role" : Return "نوع المستخدم"
            Case "brand" : Return "العلامة التجارية"
            Case "branch" : Return "الفرع"
            Case "department" : Return "القسم"
            Case "shift" : Return "الوردية"
            Case "view" : Return "مشاهدة الملف"
            Case "download" : Return "تنزيل الملف"
            Case "preview" : Return "معاينة إدارية"
            Case "create" : Return "إنشاء التعميم"
            Case "update" : Return "تحديث التعميم"
            Case "Mobile" : Return "تطبيق الهاتف"
            Case "CustomerPortal" : Return "بوابة العميل"
            Case "Service" : Return "خدمة الإرسال"
            Case "email" : Return "إرسال بريد إلكتروني"
            Case "pending" : Return "بانتظار الإرسال"
            Case "sending" : Return "جارٍ الإرسال"
            Case "submitted" : Return "قبله خادم البريد"
            Case "failed" : Return "تعذر الإرسال"
            Case "cancelled" : Return "أُلغي الإرسال"
            Case "unknown" : Return "النتيجة غير مؤكدة"
            Case "Portal" : Return "البوابة"
            Case Else : Return "—"
        End Select
    End Function
    Public Shared Function ErrorText(ex As Exception) As String
        If TypeOf ex Is ArgumentException Then Return ex.Message
        Dim sql=TryCast(ex,SqlException)
        If sql IsNot Nothing Then
            Select Case sql.Number
                Case 51800 : Return "تحقق من الحقول والصلاحية والمستهدفين. اختر فروعًا تابعة للعلامات المختارة، وقيمًا فعالة، وملف PDF لا يتجاوز 10MB."
                Case 51801 : Return "لا تملك صلاحية تنفيذ هذه العملية."
                Case 51803 : Return "تنزيل هذا الملف غير مسموح."
                Case 51804 : Return "التعميم غير متاح أو انتهت صلاحيته."
                Case 51809 : Return "تغير التعميم منذ فتح الصفحة. أعد تحميل الصفحة قبل الحفظ."
            End Select
        End If
        System.Diagnostics.Trace.TraceError("Circular operation failed ({0}).",ex.GetType().Name)
        Return "تعذر تنفيذ العملية. حاول مرة أخرى."
    End Function
    Public Shared Function Pdf(file As HttpPostedFile) As Byte()
        If file Is Nothing OrElse file.ContentLength=0 OrElse file.ContentLength>10485760 OrElse Not String.Equals(IO.Path.GetExtension(file.FileName),".pdf",StringComparison.OrdinalIgnoreCase) Then Throw New ArgumentException("اختر ملف PDF لا يتجاوز 10MB.")
        For Each character As Char In file.FileName
            If Char.IsControl(character) Then Throw New ArgumentException("اسم الملف غير صالح.")
        Next
        Dim bytes(file.ContentLength-1) As Byte
        Dim offset=0
        While offset<bytes.Length
            Dim read=file.InputStream.Read(bytes,offset,bytes.Length-offset)
            If read=0 Then Throw New ArgumentException("لم يكتمل رفع الملف.")
            offset+=read
        End While
        If bytes.Length<8 OrElse Text.Encoding.ASCII.GetString(bytes,0,5)<>"%PDF-" OrElse Not Text.Encoding.ASCII.GetString(bytes,Math.Max(0,bytes.Length-2048),Math.Min(2048,bytes.Length)).Contains("%%EOF") Then Throw New ArgumentException("محتوى الملف ليس PDF صالحًا.")
        Return bytes
    End Function
End Class

Public Class CircularsPage
    Inherits InformationPagesPage
    Protected ReadOnly Property AdminMode As Boolean
        Get
            Return IsAdministrator AndAlso (Request.QueryString("admin")="1" OrElse (PageID=0 AndAlso Request.Path.EndsWith("/View.aspx",StringComparison.OrdinalIgnoreCase)))
        End Get
    End Property
    Protected ReadOnly Property CsrfToken As String
        Get
            If Session("CircularCsrf") Is Nothing Then Session("CircularCsrf")=Guid.NewGuid().ToString("N")
            Return CStr(Session("CircularCsrf"))
        End Get
    End Property
    Protected Function H(value As Object) As String
        Return Server.HtmlEncode(Convert.ToString(value))
    End Function
    Protected Function Stamp(value As Object) As String
        Return InformationPagesData.LocalDate(value)
    End Function
    Protected Function NameOfState(value As Object) As String
        Return CircularsData.Label(value)
    End Function
    Protected Sub Failure(target As Literal,ex As Exception)
        target.Text="<div class='alert alert-danger' role='alert'>" & H(CircularsData.ErrorText(ex)) & "</div>"
    End Sub
End Class
