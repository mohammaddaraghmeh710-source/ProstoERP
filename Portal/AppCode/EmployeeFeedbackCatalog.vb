Imports System.Linq
Imports System.Web
Imports Prosto_ERP_ClassLibrary

Public Class FeedbackType
    Public Property ID As Integer
    Public Property Title_Ar As String
    Public Property Title_En As String
    Public Property Item_Order As Integer
    Public Property IsActive As Boolean
    Public Property IsDeleted As Boolean
    Public Property RowVersion As Byte()
End Class

' Shared template cards for feedback and correspondence pages.
Public NotInheritable Class FeedbackPresentation
    Public Shared Function Metric(title As String,value As Integer,icon As String,color As String,Optional href As String="") As String
        Dim body="<div class=""card-body p-3""><div class=""row g-2 align-items-center""><div class=""col""><span class=""text-muted small"">" & HttpUtility.HtmlEncode(title) & "</span><h3 class=""mb-0 mt-1"">" & value.ToString() & "</h3></div><div class=""col-auto""><div class=""avatar""><span class=""avatar-initial rounded bg-label-" & color & """><i class=""bx " & icon & """ aria-hidden=""true""></i></span></div></div></div></div>"
        Return "<div class=""col""><" & If(href="","section","a") & If(href="",""," href=""" & HttpUtility.HtmlAttributeEncode(href) & """") & " class=""card h-100 text-body"">" & body & "</" & If(href="","section","a") & "></div>"
    End Function
    Public Shared Function Info(label As String,value As Object,icon As String) As String
        Return "<div class=""col-sm-6 col-xl-4""><div class=""d-inline-flex align-items-start gap-2""><i class=""bx " & icon & " text-primary mt-1"" aria-hidden=""true""></i><div><div class=""small text-muted mb-1"">" & HttpUtility.HtmlEncode(label) & "</div><div class=""text-break"">" & HttpUtility.HtmlEncode(EmployeeFeedbackCatalog.Display(value)) & "</div></div></div></div>"
    End Function
    Public Shared Function RequestField(label As String,value As Object) As String
        Return "<div class=""col-12 col-md-6 col-xl-4 d-flex flex-wrap align-items-baseline gap-1""><dt class=""text-muted"">" & HttpUtility.HtmlEncode(label) & ":</dt><dd class=""text-break""><bdi>" & HttpUtility.HtmlEncode(EmployeeFeedbackCatalog.Display(value)) & "</bdi></dd></div>"
    End Function
    Public Shared Function Contact(row As FeedbackApplicant,Optional compact As Boolean=False) As String
        If compact Then
            Dim fields=""
            If row.CanViewContact Then
                fields=RequestField("الاسم",row.ApplicantName)
                If Not String.IsNullOrWhiteSpace(row.ApplicantNameEn) Then fields &= RequestField("الاسم بالإنجليزية",row.ApplicantNameEn)
                If row.ApplicantEmployeeNumber.HasValue Then fields &= RequestField("الرقم الوظيفي",row.ApplicantEmployeeNumber.Value)
                fields &= RequestField("رقم الجوال",row.ApplicantMobile) & RequestField("البريد الإلكتروني",row.ApplicantEmail)
                If Not String.IsNullOrWhiteSpace(row.ApplicantPhone) Then fields &= RequestField("رقم الهاتف",row.ApplicantPhone)
            End If
            fields &= RequestField("العلامة التجارية",row.BrandName) & RequestField("الفرع",row.BranchName)
            Dim details="<dl class=""row g-2 mb-0 feedback-request-meta"">" & fields & "</dl>"
            If Not row.CanViewContact Then details="<div class=""alert alert-secondary mb-3"" role=""status""><i class=""bx bx-lock-alt me-2"" aria-hidden=""true""></i>اختار مقدم الطلب إخفاء هويته؛ بيانات التواصل غير متاحة.</div>" & details
            Return details
        End If
        If Not row.CanViewContact Then Return "<div class=""alert alert-secondary mb-0"" role=""status""><i class=""bx bx-lock-alt me-2"" aria-hidden=""true""></i>اختار مقدم الطلب إخفاء هويته؛ بيانات التواصل غير متاحة.</div>"
        Return "<div class=""row g-3"">" & Info("الاسم",row.ApplicantName,"bx-user") & Info("الاسم بالإنجليزية",row.ApplicantNameEn,"bx-user-circle") & Info("الرقم الوظيفي",row.ApplicantEmployeeNumber,"bx-id-card") & Info("رقم الجوال",row.ApplicantMobile,"bx-mobile-alt") & Info("رقم الهاتف",row.ApplicantPhone,"bx-phone") & Info("البريد الإلكتروني",row.ApplicantEmail,"bx-envelope") & "</div>"
    End Function
End Class
Public Class FeedbackApplicantSummary
    Public Property SourceType As Integer
    Public Property BrandName As String
    Public Property BranchName As String
    Public Property CapturedAt As DateTime?
    Public Property IsBackfilled As Boolean
End Class
Public Class FeedbackApplicant
    Public Property SourceType As Integer
    Public Property BrandName As String
    Public Property BranchName As String
    Public Property CapturedAt As DateTime?
    Public Property IsBackfilled As Boolean
    Public Property CanViewContact As Boolean
    Public Property ApplicantName As String
    Public Property ApplicantNameEn As String
    Public Property ApplicantEmployeeNumber As Integer?
    Public Property ApplicantPhone As String
    Public Property ApplicantMobile As String
    Public Property ApplicantEmail As String
End Class
Public NotInheritable Class EmployeeFeedbackCatalog
    Public Shared Function Types(actor As Integer,mode As Integer) As List(Of FeedbackType)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of FeedbackType)("EXEC dbo.Select_Employee_Feedback_Types @Actor={0},@Mode={1}",actor,mode).ToList()
        End Using
    End Function
    Public Shared Sub FillTypes(list As System.Web.UI.WebControls.DropDownList,actor As Integer,mode As Integer,placeholder As String)
        list.Items.Clear() : list.Items.Add(New System.Web.UI.WebControls.ListItem(placeholder,"0"))
        For Each row In Types(actor,mode)
            list.Items.Add(New System.Web.UI.WebControls.ListItem(row.Title_Ar & If(row.IsDeleted," (مؤرشف)",If(row.IsActive,""," (غير فعال)")),row.ID.ToString()))
        Next
    End Sub
    Public Shared Function TypeName(id As Integer) As String
        Dim actor=SessionManager.GetInstance.Users
        If actor Is Nothing Then Return "نوع غير محدد"
        Dim rows As List(Of FeedbackType)=Nothing
        If HttpContext.Current IsNot Nothing Then rows=TryCast(HttpContext.Current.Items("FeedbackTypeNames"),List(Of FeedbackType))
        If rows Is Nothing Then
            rows=Types(actor.UserID,2)
            If HttpContext.Current IsNot Nothing Then HttpContext.Current.Items("FeedbackTypeNames")=rows
        End If
        Dim row=rows.SingleOrDefault(Function(r) r.ID=id)
        Return If(row Is Nothing,"نوع غير محدد",row.Title_Ar)
    End Function
    Public Shared Function SourceName(value As Object) As String
        Select Case Convert.ToInt32(value)
            Case 1 : Return "موظف"
            Case 2 : Return "زبون"
            Case Else : Return "غير محدد"
        End Select
    End Function
    Public Shared Function OwnApplicant(actor As Integer) As FeedbackApplicant
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of FeedbackApplicant)("EXEC dbo.Select_Employee_Feedback_Applicant @Actor={0}",actor).Single()
        End Using
    End Function
    Public Shared Function Summary(actor As Integer,id As Integer,report As Boolean) As FeedbackApplicantSummary
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of FeedbackApplicantSummary)("EXEC dbo.Select_Employee_Feedback_ApplicantSummary @Actor={0},@ID={1},@Report={2}",actor,id,report).Single()
        End Using
    End Function
    Public Shared Function Contact(actor As Integer,id As Integer,report As Boolean) As FeedbackApplicant
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return db.ExecuteQuery(Of FeedbackApplicant)("EXEC dbo.Select_Employee_Feedback_Contact @Actor={0},@ID={1},@Report={2}",actor,id,report).Single()
        End Using
    End Function
    Public Shared Function Display(value As Object) As String
        Return If(value Is Nothing OrElse IsDBNull(value) OrElse String.IsNullOrWhiteSpace(Convert.ToString(value)),"غير مسجل",Convert.ToString(value))
    End Function
    Public Shared Sub SaveType(actor As Integer,id As Integer,titleAr As String,titleEn As String,order As Integer,active As Boolean,version As Byte())
        Using db As New Prosto_ERP_DataClassesDataContext()
            db.ExecuteCommand("EXEC dbo.Save_Employee_Feedback_Type @Actor={0},@ID={1},@TitleAr={2},@TitleEn={3},@Order={4},@Active={5},@Version={6}",actor,id,titleAr,titleEn,order,active,If(version,New Byte() {}))
        End Using
    End Sub
    Public Shared Sub DeleteType(actor As Integer,id As Integer,version As Byte())
        Using db As New Prosto_ERP_DataClassesDataContext()
            db.ExecuteCommand("EXEC dbo.Delete_Employee_Feedback_Type @Actor={0},@ID={1},@Version={2}",actor,id,version)
        End Using
    End Sub
End Class
