Option Strict On
Option Explicit On
Partial Public Class InformationPagesIndex
    Protected WithEvents litMessage As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents pages As Global.System.Web.UI.WebControls.Repeater
    Public Shadows ReadOnly Property Master() As CRM.Site
        Get
            Return CType(MyBase.Master, CRM.Site)
        End Get
    End Property
End Class
