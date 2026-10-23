Public Class ManageCRMActivityLogs
    Inherits PageBase

    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        Response.Redirect("~/Modules/CRM_Account_Types/Overview.aspx#crmActivity", False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub
End Class
