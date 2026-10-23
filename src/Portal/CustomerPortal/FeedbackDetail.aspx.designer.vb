Partial Public Class CustomerFeedbackDetail
 Protected WithEvents head As Global.System.Web.UI.WebControls.Content
 Protected WithEvents body As Global.System.Web.UI.WebControls.Content
 Protected WithEvents litID As Global.System.Web.UI.WebControls.Literal
 Protected WithEvents litTitle As Global.System.Web.UI.WebControls.Literal
 Protected WithEvents lblSource As Global.System.Web.UI.WebControls.Label
 Protected WithEvents lblType As Global.System.Web.UI.WebControls.Label
 Protected WithEvents lblStatus As Global.System.Web.UI.WebControls.Label
 Protected WithEvents litMeta As Global.System.Web.UI.WebControls.Literal
 Protected WithEvents litDetails As Global.System.Web.UI.WebControls.Literal
 Protected WithEvents litContact As Global.System.Web.UI.WebControls.Literal
 Protected WithEvents attachments As Global.System.Web.UI.WebControls.Repeater
 Protected WithEvents workflow As Global.System.Web.UI.WebControls.Repeater
 Protected WithEvents lblNoFiles As Global.System.Web.UI.WebControls.Label
    Public Shadows ReadOnly Property Master() As CRM.CustomerMaster
        Get
            Return CType(MyBase.Master, CRM.CustomerMaster)
        End Get
    End Property
End Class
