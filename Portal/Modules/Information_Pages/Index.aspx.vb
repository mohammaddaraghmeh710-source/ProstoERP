Imports System.Data
Public Class InformationPagesIndex
    Inherits InformationPagesPage
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Try
            Dim data = InformationPagesData.Query("dbo.Select_Information_Pages", InformationPagesData.P("@Actor", SqlDbType.Int, Actor))
            pages.DataSource = data : pages.DataBind()
            pnlEmpty.Visible = data.Rows.Count = 0
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
    End Sub
End Class
