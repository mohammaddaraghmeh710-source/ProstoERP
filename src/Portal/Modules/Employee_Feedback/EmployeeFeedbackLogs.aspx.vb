Public Class EmployeeFeedbackLogs
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireAdmin()
        If Not IsPostBack Then
            Try
                lblScope.Text = If(RequestID > 0, "سجل الطلب #" & RequestID.ToString(), "جميع الطلبات")
                lnkBack.NavigateUrl =
                    If _
                        (RequestID > 0, "ViewEmployeeFeedback.aspx?report=1&ID=" & RequestID.ToString(),
                         "EmployeeFeedbackReports.aspx")
                lstData.DataSource = EmployeeFeedbackConfig.Logs(ActorID, RequestID)
                lstData.DataBind()
            Catch ex As Exception : ShowError(ex)
            End Try
        End If
    End Sub
End Class

