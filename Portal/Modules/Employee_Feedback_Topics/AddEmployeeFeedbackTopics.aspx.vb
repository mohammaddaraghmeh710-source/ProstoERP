Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class AddEmployeeFeedbackTopics
    Inherits EmployeeFeedbackPage
    Private Const Editing As Boolean=False
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        RequireAdmin()
        If Editing AndAlso RequestID=0 Then SystemAdministrationUI.Redirect(Me, "ManageEmployeeFeedbackTopics.aspx")
        If Not IsPostBack Then
            Try
                EmployeeFeedbackCatalog.FillTypes(ddlType,ActorID,0,"اختر النوع")
                ddlBrand.Items.Add(New ListItem("اختر العلامة التجارية","0"))
                Using db As New Prosto_ERP_DataClassesDataContext()
                    For Each b In db.Select_Brands_All() : ddlBrand.Items.Add(New ListItem(b.Title_Ar,b.ID.ToString())) : Next
                    If Editing Then
                        Dim t=db.Select_Employee_Feedback_Topics(ActorID,RequestID,0,0,True).Single()
                        ddlType.SelectedValue=t.Type.ToString() : ddlBrand.SelectedValue=t.Brand_ID.ToString() : txtAr.Text=t.Title_Ar : txtEn.Text=t.Title_En : txtOrder.Text=t.Item_Order.ToString() : chkActive.Checked=t.IsActive
                    End If
                End Using
            Catch ex As Exception : ShowError(ex) : btnSave.Enabled=False : End Try
        End If
    End Sub
    Protected Sub Save_Click(sender As Object,e As EventArgs)
        Try
            Dim order As Integer
            If Not Integer.TryParse(txtOrder.Text,order) OrElse order<0 Then Throw New ArgumentException("ترتيب العرض يجب أن يكون عددًا صحيحًا موجبًا أو صفرًا.")
            If String.IsNullOrWhiteSpace(txtAr.Text) OrElse String.IsNullOrWhiteSpace(txtEn.Text) OrElse txtAr.Text.Length>200 OrElse txtEn.Text.Length>200 Then Throw New ArgumentException("أدخل اسم الموضوع بالعربية والإنجليزية، بحد أقصى 200 حرف.")
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.Save_Employee_Feedback_Topic(ActorID,If(Editing,RequestID,0),Number(ddlType),Number(ddlBrand),txtAr.Text.Trim(),txtEn.Text.Trim(),order,chkActive.Checked).ToList()
            End Using
        Catch ex As Exception : ShowError(ex) : Return : End Try
        SystemAdministrationUI.Redirect(Me, "ManageEmployeeFeedbackTopics.aspx")
    End Sub
End Class
