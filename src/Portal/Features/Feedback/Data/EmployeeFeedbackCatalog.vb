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
    Public Shared Function Types(actor As Integer, mode As Integer) As List(Of FeedbackType)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackType)("EXEC dbo.Select_Employee_Feedback_Types @Actor={0},@Mode={1}", actor,
                                                  mode).ToList()
        End Using
    End Function

    Public Shared Sub FillTypes(list As DropDownList, actor As Integer, mode As Integer,
                                placeholder As String)
        FeedbackPresentation.FillTypes(list, actor, mode, placeholder)
    End Sub

    Public Shared Function TypeName(id As Integer) As String
        Dim actor = SessionManager.GetInstance.Users
        If actor Is Nothing Then Return "نوع غير محدد"
        Dim rows As List(Of FeedbackType) = Nothing
        If HttpContext.Current IsNot Nothing Then _
            rows = TryCast(HttpContext.Current.Items("FeedbackTypeNames"), List(Of FeedbackType))
        If rows Is Nothing Then
            rows = Types(actor.UserID, 2)
            If HttpContext.Current IsNot Nothing Then HttpContext.Current.Items("FeedbackTypeNames") = rows
        End If
        Dim row = rows.SingleOrDefault(Function(r) r.ID = id)
        Return If(row Is Nothing, "نوع غير محدد", row.Title_Ar)
    End Function

    Public Shared Function SourceName(value As Object) As String
        Return FeedbackPresentation.SourceName(value)
    End Function

    Public Shared Function OwnApplicant(actor As Integer) As FeedbackApplicant
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackApplicant)("EXEC dbo.Select_Employee_Feedback_Applicant @Actor={0}", actor).
                    Single()
        End Using
    End Function

    Public Shared Function Summary(actor As Integer, id As Integer, report As Boolean) As FeedbackApplicantSummary
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackApplicantSummary)(
                    "EXEC dbo.Select_Employee_Feedback_ApplicantSummary @Actor={0},@ID={1},@Report={2}", actor, id,
                    report).Single()
        End Using
    End Function

    Public Shared Function Contact(actor As Integer, id As Integer, report As Boolean) As FeedbackApplicant
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackApplicant)(
                    "EXEC dbo.Select_Employee_Feedback_Contact @Actor={0},@ID={1},@Report={2}", actor, id, report).
                    Single()
        End Using
    End Function

    Public Shared Function Display(value As Object) As String
        Return FeedbackPresentation.Display(value)
    End Function

    Public Shared Sub SaveType(actor As Integer, id As Integer, titleAr As String, titleEn As String, order As Integer,
                               active As Boolean, version As Byte())
        Using db As New Prosto_ERP_DataClassesDataContext()
            db.ExecuteCommand(
                "EXEC dbo.Save_Employee_Feedback_Type @Actor={0},@ID={1},@TitleAr={2},@TitleEn={3},@Order={4},@Active={5},@Version={6}",
                actor, id, titleAr, titleEn, order, active, If(version, New Byte() {}))
        End Using
    End Sub

    Public Shared Sub DeleteType(actor As Integer, id As Integer, version As Byte())
        Using db As New Prosto_ERP_DataClassesDataContext()
            db.ExecuteCommand("EXEC dbo.Delete_Employee_Feedback_Type @Actor={0},@ID={1},@Version={2}", actor, id,
                              version)
        End Using
    End Sub
End Class


