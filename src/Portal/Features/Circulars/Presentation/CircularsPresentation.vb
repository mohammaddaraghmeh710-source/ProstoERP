Imports System.Data.SqlClient

Public NotInheritable Class CircularsPresentation
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
        Dim sql = TryCast(ex, SqlException)
        If sql IsNot Nothing Then
            Select Case sql.Number
                Case 51800 _
                    : Return _
                        "تحقق من الحقول والصلاحية والمستهدفين. اختر فروعًا تابعة للعلامات المختارة، وقيمًا فعالة، وملف PDF لا يتجاوز 10MB."
                Case 51801 : Return "لا تملك صلاحية تنفيذ هذه العملية."
                Case 51803 : Return "تنزيل هذا الملف غير مسموح."
                Case 51804 : Return "التعميم غير متاح أو انتهت صلاحيته."
                Case 51809 : Return "تغير التعميم منذ فتح الصفحة. أعد تحميل الصفحة قبل الحفظ."
            End Select
        End If
        Trace.TraceError("Circular operation failed ({0}).", ex.GetType().Name)
        Return "تعذر تنفيذ العملية. حاول مرة أخرى."
    End Function
End Class


