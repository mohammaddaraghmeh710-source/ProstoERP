Option Strict On
Option Explicit On
Partial Public Class InformationPageHistory
    Protected WithEvents litMessage As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lstVersions As Global.System.Web.UI.WebControls.ListView
    Protected WithEvents statTotal As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents statUpdates As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents statRestores As Global.System.Web.UI.WebControls.Literal
    Public Shadows ReadOnly Property Master() As CRM.Site
        Get
            Return CType(MyBase.Master, CRM.Site)
        End Get
    End Property
End Class
