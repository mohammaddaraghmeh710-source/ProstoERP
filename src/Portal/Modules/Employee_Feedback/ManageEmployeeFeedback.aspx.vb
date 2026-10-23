Imports Prosto_ERP_ClassLibrary

Public Class ManageEmployeeFeedback
    Inherits EmployeeFeedbackPage
    Private todoIDs As New HashSet(Of Integer)
    Private mineIDs As New HashSet(Of Integer)
    Private receivedIDs As New HashSet(Of Integer)
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        Dim permission=EmployeeFeedbackConfig.Mine(ActorID)
        lnkNew.Visible=permission IsNot Nothing AndAlso permission.CanSubmit
        If Not IsPostBack Then
            Try
                FeedbackPresentation.FillTypes(ddlType, ActorID, 2, "جميع الأنواع")
                If Session("FeedbackSubmitted") IsNot Nothing Then
                    litMessage.Text =
                        "<div class=""alert alert-success alert-dismissible"" role=""status""><i class=""bx bx-check-circle me-2""></i>تم تقديم طلبك بنجاح. يمكنك متابعة حالته وجميع تفاصيله من هنا.<button type=""button"" class=""btn-close"" data-bs-dismiss=""alert"" aria-label=""إغلاق""></button></div>"
                    Session.Remove("FeedbackSubmitted")
                End If
                FillData()
            Catch ex As Exception : ShowError(ex)
            End Try
        End If
    End Sub

    Private Sub FillData()
        Dim all As New List(Of FeedbackRequestRow)
        Using db As New Prosto_ERP_DataClassesDataContext()
            For Each mode In If(ActorType=1,New Integer(){2,0,1,3},New Integer(){0,1,3})
                Dim part=db.ExecuteQuery(Of FeedbackRequestRow)("EXEC dbo.Select_Employee_Feedback_Requests @Actor={0},@Mode={1},@Search=N'',@Type=0,@Status=0",ActorID,mode).ToList()
                If mode=0 Then receivedIDs=New HashSet(Of Integer)(part.Select(Function(r) r.ID))
                If mode=1 Then mineIDs=New HashSet(Of Integer)(part.Select(Function(r) r.ID))
                If mode=3 Then todoIDs=New HashSet(Of Integer)(part.Select(Function(r) r.ID))
                all.AddRange(part)
            Next
        End Using
        all = all.GroupBy(Function(r) r.ID).Select(Function(g) g.First()).ToList()
        litStatistics.Text = "<div class=""row row-cols-2 row-cols-md-3 row-cols-xl-5 g-3 mb-3"">" &
                             FeedbackPresentation.Metric("إجمالي الطلبات", all.Count, "bx-collection", "primary",
                                                         "ManageEmployeeFeedback.aspx") &
                             FeedbackPresentation.Metric("الطلبات المرسلة", mineIDs.Count, "bx-send", "info",
                                                         "ManageEmployeeFeedback.aspx?view=mine") &
                             FeedbackPresentation.Metric("الطلبات الفعالة", all.Where(Function(r) r.Status <> 3).Count(),
                                                         "bx-time-five", "warning",
                                                         "ManageEmployeeFeedback.aspx?view=active") &
                             FeedbackPresentation.Metric("الطلبات المنتهية", all.Where(Function(r) r.Status = 3).Count(),
                                                         "bx-check-circle", "success",
                                                         "ManageEmployeeFeedback.aspx?view=closed") &
                             FeedbackPresentation.Metric("بانتظار إجرائك", todoIDs.Count, "bx-task", "danger",
                                                         "ManageEmployeeFeedback.aspx?view=todo") & "</div>"
        Dim data As IEnumerable(Of FeedbackRequestRow) = all
        Select Case Request.QueryString("view")
            Case "mine" : data = data.Where(Function(r) mineIDs.Contains(r.ID))
            Case "todo" : data = data.Where(Function(r) todoIDs.Contains(r.ID))
            Case "active" : data = data.Where(Function(r) r.Status <> 3)
            Case "closed" : data = data.Where(Function(r) r.Status = 3)
        End Select
        Dim search = txtSearch.Text.Trim()
        data =
            data.Where(
                Function(r) _
                          (search = "" OrElse r.ID.ToString() = search OrElse
                           r.Title.IndexOf(search, StringComparison.CurrentCultureIgnoreCase) >= 0) AndAlso
                          (Number(ddlType) = 0 OrElse r.Type = Number(ddlType)) AndAlso
                          (Number(ddlStatus) = 0 OrElse r.Status = Number(ddlStatus) OrElse
                           (Number(ddlStatus) = 4 AndAlso r.Status <> 3)))
        Dim sorted =
                data.OrderBy(Function(r) If(todoIDs.Contains(r.ID), 0, If(r.Status <> 3, 1, 2))).ThenByDescending(
                    Function(r) r.AddedDate).ThenByDescending(Function(r) r.ID).ToList()
        lstData.DataSource = sorted
        lstData.DataBind()
        lblTotal.Text = "الطلبات المعروضة: " & sorted.Count.ToString()
    End Sub

    Protected Function NeedsAction(id As Object) As Boolean
        Return todoIDs.Contains(Convert.ToInt32(id))
    End Function

    Protected Function IsSent(id As Object) As Boolean
        Return mineIDs.Contains(Convert.ToInt32(id))
    End Function
    Protected Function RowScope(id As Object) As String
        Return If(IsSent(id),"طلب مرسل",If(receivedIDs.Contains(Convert.ToInt32(id)),"طلب وارد","متابعة إدارية"))
    End Function
    Protected Function DetailLink(id As Object) As String
        Return "ViewEmployeeFeedback.aspx?ID=" & Convert.ToInt32(id).ToString() & If(ActorType=1 AndAlso Not NeedsAction(id),"&report=1","")
    End Function

    Protected Sub Search_Click(sender As Object, e As EventArgs)
        Try : FillData()
        Catch ex As Exception : ShowError(ex)
        End Try
    End Sub
End Class


