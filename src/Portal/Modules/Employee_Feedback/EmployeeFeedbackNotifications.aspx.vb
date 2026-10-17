Imports Prosto_ERP_ClassLibrary

Public Class EmployeeFeedbackNotifications
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Try
                Using db As New Prosto_ERP_DataClassesDataContext()
                    Dim rows = db.Select_Employee_Feedback_Notifications(ActorID).ToList()
                    lstData.DataSource = rows
                    lstData.DataBind()
                    litStatistics.Text = "<div class=""row row-cols-2 row-cols-md-3 g-3 mb-3"">" &
                                         FeedbackPresentation.Metric("جميع الإشعارات", rows.Count, "bx-bell", "primary") &
                                         FeedbackPresentation.Metric("إشعارات جديدة",
                                                                     rows.Where(Function(r) Not r.IsRead).Count(),
                                                                     "bx-bell-plus", "warning") &
                                         FeedbackPresentation.Metric("تمت قراءتها",
                                                                     rows.Where(Function(r) r.IsRead).Count(),
                                                                     "bx-check-double", "success") & "</div>"
                End Using
            Catch ex As Exception : ShowError(ex)
            End Try
        End If
    End Sub
End Class


