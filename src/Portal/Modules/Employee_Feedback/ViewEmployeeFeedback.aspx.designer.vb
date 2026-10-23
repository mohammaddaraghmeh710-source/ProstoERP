Partial Public Class ViewEmployeeFeedback
    Protected WithEvents litMessage As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litID As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lnkBack As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents pnlDetails As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litTitle As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents lblType As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lblStatus As Global.System.Web.UI.WebControls.Label
    Protected WithEvents litMeta As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litDetails As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptFiles As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents lblNoFiles As Global.System.Web.UI.WebControls.Label
    Protected WithEvents rptWorkflow As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents rptActionFiles As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlReadOnly As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents pnlActions As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents btnTransfer As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnClose As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlActionModal As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litActionTitle As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litActionError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents txtComment As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents AttachmentUpload As Global.AjaxControlToolkit.AjaxFileUpload
    Protected WithEvents lblQueued As Global.System.Web.UI.WebControls.Label
    Protected WithEvents btnClearUploads As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnCancel As Global.System.Web.UI.WebControls.Button
    Protected WithEvents btnConfirm As Global.System.Web.UI.WebControls.Button
    Protected WithEvents lblModalTarget As Global.System.Web.UI.WebControls.Label
    Protected WithEvents ActionModal As Global.AjaxControlToolkit.ModalPopupExtender
    Protected WithEvents lnkLogs As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents pnlTransferTarget As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents ddlTransferTarget As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents lblTransferRouting As Global.System.Web.UI.WebControls.Label
    Protected WithEvents liLogs As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents pnlLogs As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents rptLogs As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents lblSource As Global.System.Web.UI.WebControls.Label
    Protected WithEvents lnkContact As Global.System.Web.UI.WebControls.HyperLink
    Protected WithEvents litContact As Global.System.Web.UI.WebControls.Literal
    Public Shadows ReadOnly Property Master() As CRM.Site
        Get
            Return CType(MyBase.Master, CRM.Site)
        End Get
    End Property
End Class
