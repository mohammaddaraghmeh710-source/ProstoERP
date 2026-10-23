Imports System.Linq
Public Class EditEmployeeFeedbackTypes
    Inherits EmployeeFeedbackPage
    Private Const Editing As Boolean=True
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        RequireAdmin()
        If Editing AndAlso RequestID=0 Then SystemAdministrationUI.Redirect(Me, "ManageEmployeeFeedbackTypes.aspx")
        If Not IsPostBack AndAlso Editing Then
            Try
                Dim row=EmployeeFeedbackCatalog.Types(ActorID,1).Single(Function(r) r.ID=RequestID)
                txtAr.Text=row.Title_Ar : txtEn.Text=row.Title_En : txtOrder.Text=row.Item_Order.ToString() : chkActive.Checked=row.IsActive
                ViewState("Version")=row.RowVersion
            Catch ex As Exception : ShowError(ex) : btnSave.Enabled=False : End Try
        End If
    End Sub
    Protected Sub Save_Click(sender As Object,e As EventArgs)
        Try
            Dim order As Integer
            If Not Integer.TryParse(txtOrder.Text,order) OrElse order<0 Then Throw New ArgumentException("أدخل ترتيب عرض صحيحًا.")
            If String.IsNullOrWhiteSpace(txtAr.Text) OrElse String.IsNullOrWhiteSpace(txtEn.Text) OrElse txtAr.Text.Length>200 OrElse txtEn.Text.Length>200 Then Throw New ArgumentException("أدخل الاسم بالعربية والإنجليزية بحد أقصى 200 حرف.")
            EmployeeFeedbackCatalog.SaveType(ActorID,If(Editing,RequestID,0),txtAr.Text.Trim(),txtEn.Text.Trim(),order,chkActive.Checked,TryCast(ViewState("Version"),Byte()))
        Catch ex As Exception : ShowError(ex) : Return : End Try
        SystemAdministrationUI.Redirect(Me, "ManageEmployeeFeedbackTypes.aspx")
    End Sub
End Class
