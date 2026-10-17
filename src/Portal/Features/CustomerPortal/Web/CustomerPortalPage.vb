Imports System.Data.SqlClient

Public Class CustomerPortalPage
    Inherits PageBase

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If CustomerPortalData.Current Is Nothing Then Response.Redirect("/Login.aspx?kind=customer") : Return
        Try
            CustomerPortalData.Current.Name = CStr(CustomerPortalData.RequireSession()("Name_AR"))
        Catch ex As SqlException
            If ex.Number <> 51911 Then Throw
            CustomerPortalData.Current = Nothing
            Response.Redirect("/Login.aspx?kind=customer")
            Return
        End Try
        ViewStateUserKey = Session.SessionID & ":customer:" & CustomerPortalData.Current.AccountID.ToString() & ":" &
                           CustomerPortalData.Current.Stamp.ToString()
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
    End Sub
End Class


