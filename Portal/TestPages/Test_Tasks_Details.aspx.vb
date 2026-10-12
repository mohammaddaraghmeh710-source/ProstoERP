Public Class Test_Tasks_Details
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Protected Sub btnEvaluation_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Show()
    End Sub
    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Hide()
    End Sub

    Protected Sub rdAll_CheckedChanged(sender As Object, e As EventArgs)
        If rdAll.Checked = True Then
            divEmployee.Visible = False
        Else
            divEmployee.Visible = True
        End If
    End Sub

    Protected Sub btnClose_Click(sender As Object, e As EventArgs)
        LBLPOP_ModalPopupExtender.Hide()
    End Sub
End Class