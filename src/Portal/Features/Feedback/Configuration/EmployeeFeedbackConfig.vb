Imports Prosto_ERP_ClassLibrary

Public NotInheritable Class EmployeeFeedbackConfig
    Public Shared Function Permissions(actor As Integer, Optional manage As Boolean = False) _
        As List(Of FeedbackPermission)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackPermission)(
                    "EXEC dbo.Select_Employee_Feedback_Permissions @Actor={0},@Manage={1}", actor, manage).ToList()
        End Using
    End Function

    Public Shared Function Mine(actor As Integer) As FeedbackPermission
        Return Permissions(actor).SingleOrDefault()
    End Function

    Public Shared Function Targets(actor As Integer) As List(Of FeedbackTargetType)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackTargetType)("EXEC dbo.Select_Employee_Feedback_TargetTypes @Actor={0}",
                                                        actor).ToList()
        End Using
    End Function

    Public Shared Sub FillTargets(list As DropDownList, actor As Integer)
        list.Items.Clear()
        list.Items.Add(New ListItem("اختر نوع المستلم", "0"))
        For Each row In Targets(actor)
            list.Items.Add(New ListItem(row.Title, row.ID.ToString()))
        Next
    End Sub

    Public Shared Function Logs(actor As Integer, id As Integer) As List(Of FeedbackLog)
        Using db As New Prosto_ERP_DataClassesDataContext()
            Return _
                db.ExecuteQuery (Of FeedbackLog)("EXEC dbo.Select_Employee_Feedback_Logs @Actor={0},@ID={1}", actor, id) _
                    .ToList()
        End Using
    End Function

    Public Shared Sub Save(actor As Integer, role As Integer, canSubmit As Boolean, canTransfer As Boolean,
                           canClose As Boolean, targets As XElement, version As Byte())
        Using db As New Prosto_ERP_DataClassesDataContext()
            db.ExecuteCommand(
                "EXEC dbo.Save_Employee_Feedback_Permissions @Actor={0},@Role={1},@Submit={2},@Transfer={3},@Close={4},@Targets={5},@Version={6}",
                actor, role, canSubmit, canTransfer, canClose, targets.ToString(), If(version, New Byte() {}))
        End Using
    End Sub
End Class


