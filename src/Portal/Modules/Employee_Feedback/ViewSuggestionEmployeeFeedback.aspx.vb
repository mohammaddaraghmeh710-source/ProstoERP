

Public Class ViewSuggestionEmployeeFeedback
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Response.Redirect(
            If _
                             (RequestID > 0,
                              "ViewEmployeeFeedback.aspx?ID=" & RequestID.ToString() & If(ReportMode, "&report=1", ""),
                              "ManageEmployeeFeedback.aspx"))
    End Sub
End Class


