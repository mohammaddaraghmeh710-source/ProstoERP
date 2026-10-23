Public Class EmployeeFeedbackNotifications
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Response.Redirect(If(ActorType = 1, "EmployeeFeedbackLogs.aspx", "ManageEmployeeFeedback.aspx"), False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
