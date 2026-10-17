

Public Class ManageEmployeeFeedbackPermissions
    Inherits EmployeeFeedbackPage
    Private roleRows As List(Of FeedbackPermission)

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        RequireAdmin()
        For Each box In New CheckBox() {chkSubmit, chkTransfer, chkClose}
            box.InputAttributes("class") = "form-check-input"
            box.LabelAttributes("class") = "form-check-label"
        Next
        If Not IsPostBack Then
            Try
                Dim rows = EmployeeFeedbackConfig.Permissions(ActorID, True)
                ddlRole.DataSource = rows
                ddlRole.DataTextField = "Title"
                ddlRole.DataValueField = "UserTypeID"
                ddlRole.DataBind()
                lstTargets.DataSource = rows
                lstTargets.DataTextField = "Title"
                lstTargets.DataValueField = "UserTypeID"
                lstTargets.DataBind()
                If ddlRole.Items.FindByValue(Request.QueryString("role")) IsNot Nothing Then _
                    ddlRole.SelectedValue = Request.QueryString("role")
                FillRole()
            Catch ex As Exception : ShowError(ex)
            End Try
        End If
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        Try
            roleRows = EmployeeFeedbackConfig.Permissions(ActorID, True)
            rptRoles.DataSource = roleRows
            rptRoles.DataBind()
        Catch ex As Exception : ShowError(ex)
        End Try
        MyBase.OnPreRender(e)
    End Sub

    Protected Function TargetNames(value As Object) As String
        Dim ids = Convert.ToString(value).Split(","c)
        Dim names =
                roleRows.Where(Function(r) ids.Contains(r.UserTypeID.ToString())).Select(Function(r) r.Title).ToList()
        Return If(names.Count = 0, "—", String.Join("، ", names))
    End Function

    Private Sub FillRole()
        Dim row = EmployeeFeedbackConfig.Permissions(ActorID, True).Single(Function(p) p.UserTypeID = Number(ddlRole))
        chkSubmit.Checked = row.CanSubmit
        chkTransfer.Checked = row.CanTransfer
        chkClose.Checked = row.CanClose
        ViewState("PermissionVersion") = row.RowVersion
        Dim targets = row.Targets.Split(","c)
        For Each item As ListItem In lstTargets.Items : item.Selected = targets.Contains(item.Value) : Next
    End Sub

    Protected Sub Role_Changed(sender As Object, e As EventArgs)
        Try : FillRole()
        Catch ex As Exception : ShowError(ex)
        End Try
    End Sub

    Protected Sub Save_Click(sender As Object, e As EventArgs)
        Try
            Dim targets As New XElement("targets")
            For Each item As ListItem In lstTargets.Items
                If item.Selected Then targets.Add(New XElement("target", New XAttribute("id", item.Value)))
            Next
            EmployeeFeedbackConfig.Save(ActorID, Number(ddlRole), chkSubmit.Checked, chkTransfer.Checked,
                                        chkClose.Checked, targets, TryCast(ViewState("PermissionVersion"), Byte()))
            FillRole()
            litMessage.Text = "<div class=""alert alert-success"">تم حفظ الصلاحيات وتطبيقها على الطلبات.</div>"
        Catch ex As Exception : ShowError(ex)
        End Try
    End Sub
End Class

