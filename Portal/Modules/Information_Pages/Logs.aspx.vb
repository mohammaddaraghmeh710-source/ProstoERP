Imports System.Data
Imports System.Linq
Public Class InformationPageLogs
    Inherits InformationPagesPage
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e) : RequireAdmin()
    End Sub
    Private Property Offset As Integer
        Get
            Return If(ViewState("Offset") Is Nothing, 0, CInt(ViewState("Offset")))
        End Get
        Set(value As Integer)
            ViewState("Offset") = Math.Max(0, value)
        End Set
    End Property
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then BindLogs()
    End Sub
    Private Sub BindLogs()
        Try
            Dim data = InformationPagesData.Query("dbo.Select_Information_Page_Logs", InformationPagesData.P("@Actor", SqlDbType.Int, Actor),
                InformationPagesData.P("@ID", SqlDbType.Int, PageID), InformationPagesData.P("@Action", SqlDbType.VarChar, ddlAction.SelectedValue, 10),
                InformationPagesData.P("@Search", SqlDbType.NVarChar, txtEmployee.Text.Trim(), 250), InformationPagesData.P("@Offset", SqlDbType.Int, Offset))
            lstLogs.DataSource = data : lstLogs.DataBind()
            Dim total = If(data.Rows.Count = 0, 0, CInt(data.Rows(0)("TotalRows")))
            Dim visits = data.Rows.Cast(Of DataRow)().Count(Function(row) {"view", "preview"}.Contains(CStr(row("Action"))))
            statTotal.Text = total.ToString() : statVisits.Text = visits.ToString() : statChanges.Text = (data.Rows.Count - visits).ToString()
            lblCount.Text = "عدد السجلات: " & total.ToString() & " | الدفعة: " & (Offset \ 50 + 1).ToString()
            btnPrevious.Enabled = Offset > 0 : btnNext.Enabled = Offset + 50 < total
        Catch ex As Exception
            ShowError(litMessage, ex)
        End Try
    End Sub
    Protected Sub Search_Click(sender As Object, e As EventArgs)
        Offset = 0 : BindLogs()
    End Sub
    Protected Sub Reset_Click(sender As Object, e As EventArgs)
        txtEmployee.Text = "" : ddlAction.SelectedIndex = 0 : Offset = 0 : BindLogs()
    End Sub
    Protected Sub Previous_Click(sender As Object, e As EventArgs)
        Offset -= 50 : BindLogs()
    End Sub
    Protected Sub Next_Click(sender As Object, e As EventArgs)
        Offset += 50 : BindLogs()
    End Sub
End Class
