Imports System.Linq
Imports System.Web
Imports System.Xml.Linq
Imports Prosto_ERP_ClassLibrary

Public Class ManageEmployeeFeedbackTopics
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf FillData)
        RequireAdmin()
        If Not IsPostBack Then
            Try
                EmployeeFeedbackCatalog.FillTypes(ddlType,ActorID,2,"الكل")
                ddlBrand.Items.Add(New ListItem("الكل","0"))
                Using db As New Prosto_ERP_DataClassesDataContext()
                    For Each b In db.Select_Brands_All() : ddlBrand.Items.Add(New ListItem(b.Title_Ar,b.ID.ToString())) : Next
                End Using
                FillData()
            Catch ex As Exception : ShowError(ex) : End Try
        End If
    End Sub
    Private Sub FillData()
        Using db As New Prosto_ERP_DataClassesDataContext()
            Dim rows=db.Select_Employee_Feedback_Topics(ActorID,0,Number(ddlType),Number(ddlBrand),True).ToList()
            If ddlActive.SelectedValue<>"" Then rows=rows.Where(Function(t) t.IsActive=(ddlActive.SelectedValue="1")).ToList()
            lstData.DataSource=rows : lstData.DataBind()
        End Using
    End Sub
    Protected Sub Search_Click(sender As Object,e As EventArgs)
        Try : FillData() : Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub Item_Command(sender As Object,e As ListViewCommandEventArgs)
        If e.CommandName<>"DeleteTopic" Then Return
        Try
            Using db As New Prosto_ERP_DataClassesDataContext()
                db.Delete_Employee_Feedback_Topic(ActorID,Convert.ToInt32(e.CommandArgument))
            End Using
            FillData()
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
End Class
