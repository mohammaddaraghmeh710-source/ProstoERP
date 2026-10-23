Option Strict On
Option Explicit On
Partial Public Class InformationPageLogs
    Protected WithEvents litMessage As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents txtEmployee As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents ddlAction As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.LinkButton
    Protected WithEvents lstLogs As Global.System.Web.UI.WebControls.ListView
    Protected WithEvents btnPrevious As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lblCount As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnNext As Global.System.Web.UI.WebControls.Button
    Protected WithEvents statTotal As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents statVisits As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents statChanges As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents btnReset As Global.System.Web.UI.WebControls.LinkButton
    Public Shadows ReadOnly Property Master() As CRM.Site
        Get
            Return CType(MyBase.Master, CRM.Site)
        End Get
    End Property
End Class
