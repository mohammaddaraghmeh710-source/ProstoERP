Public Class MyEmployeeFeedback
    Inherits EmployeeFeedbackPage

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Response.Redirect("ManageEmployeeFeedback.aspx?view=mine")
    End Sub

    Protected Function DetailLink(id As Object) As String
        Return "ViewEmployeeFeedback.aspx?ID=" & Convert.ToInt32(id).ToString()
    End Function

    Protected Sub Search_Click(sender As Object, e As EventArgs)
    End Sub

    Protected Sub Export_Click(sender As Object, e As EventArgs)
    End Sub
End Class


