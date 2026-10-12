Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class ViewNewBranchEmployeeFeedback
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        Response.Redirect(If(RequestID>0,"ViewEmployeeFeedback.aspx?ID=" & RequestID.ToString() & If(ReportMode,"&report=1",""),"ManageEmployeeFeedback.aspx"))
    End Sub
End Class
