Imports System.Linq
Public Class ManageEmployeeFeedbackTypes
    Inherits EmployeeFeedbackPage
    Protected Sub Page_Load(sender As Object,e As EventArgs) Handles Me.Load
        RequireAdmin()
        If Not IsPostBack Then
            Try : FillData() : Catch ex As Exception : ShowError(ex) : End Try
        End If
    End Sub
    Private Sub FillData()
        Dim rows=EmployeeFeedbackCatalog.Types(ActorID,1)
        If ddlActive.SelectedValue<>"" Then rows=rows.Where(Function(r) r.IsActive=(ddlActive.SelectedValue="1")).ToList()
        Dim search=txtSearch.Text.Trim()
        If search<>"" Then rows=rows.Where(Function(r) r.Title_Ar.IndexOf(search,StringComparison.OrdinalIgnoreCase)>=0 OrElse r.Title_En.IndexOf(search,StringComparison.OrdinalIgnoreCase)>=0).ToList()
        For Each row In rows : ViewState("TypeVersion:" & row.ID.ToString())=row.RowVersion : Next
        lstData.DataSource=rows : lstData.DataBind()
    End Sub
    Protected Sub Search_Click(sender As Object,e As EventArgs)
        Try : FillData() : Catch ex As Exception : ShowError(ex) : End Try
    End Sub
    Protected Sub Item_Command(sender As Object,e As ListViewCommandEventArgs)
        If e.CommandName<>"DeleteType" Then Return
        Try
            Dim id=Convert.ToInt32(e.CommandArgument),version=TryCast(ViewState("TypeVersion:" & id.ToString()),Byte())
            If version Is Nothing Then Throw New ArgumentException("أعد تحميل الصفحة.")
            EmployeeFeedbackCatalog.DeleteType(ActorID,id,version)
            FillData()
        Catch ex As Exception : ShowError(ex) : End Try
    End Sub
End Class