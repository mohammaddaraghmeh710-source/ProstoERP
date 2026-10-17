Public Class EmployeeFeedbackContact
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        Response.Redirect("ViewEmployeeFeedback.aspx?ID=" & RequestID.ToString() & If(ReportMode,"&report=1","") & "&tab=contact")
    End Sub
End Class
