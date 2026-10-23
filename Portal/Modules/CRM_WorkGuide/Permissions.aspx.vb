Imports System.Data
Imports System.Linq
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq
Imports System.Web.Script.Serialization

Public Class CRMWorkGuidePermissions
    Inherits PageBase
    Private allowed As Boolean
    Private Function F(Of T As Control)(id As String) As T
        Return DirectCast(Master.FindControl("ContentPlaceHolder1").FindControl(id), T)
    End Function
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/Login.aspx") : Return
        ViewStateUserKey = Session.SessionID
        Response.Cache.SetNoStore()
        Try
            CRMData.Query("dbo.CRM_WorkGuide_CheckAdmin", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()))
            allowed = True
            Dim list = F(Of DropDownList)("account")
            list.Items.Add(New ListItem("اختر العميل", ""))
            For Each row As DataRow In CRMData.Rows("Accounts", CrmUserId()).Rows
                list.Items.Add(New ListItem(Convert.ToString(row("Name_AR")), Convert.ToString(row("ID"))))
            Next
        Catch ex As Exception
            allowed = False : F(Of Panel)("pnlBody").Visible = False : Notice(CRMData.ErrorMessage(ex), True)
        End Try
    End Sub
    Protected Overrides Sub OnLoad(e As EventArgs)
        MyBase.OnLoad(e)
        If allowed AndAlso Not IsPostBack Then
            Dim id As Integer
            If Integer.TryParse(Request.QueryString("account"), id) AndAlso F(Of DropDownList)("account").Items.FindByValue(id.ToString()) IsNot Nothing Then
                F(Of DropDownList)("account").SelectedValue = id.ToString() : Load_Click(Me, EventArgs.Empty)
            End If
        End If
    End Sub
    Protected Sub Load_Click(sender As Object, e As EventArgs)
        If Not allowed Then Return
        Try
            Dim id As Integer
            If Not Integer.TryParse(F(Of DropDownList)("account").SelectedValue, id) Then Throw New ArgumentException("اختر العميل أولًا.")
            BindPermissions(id)
        Catch ex As Exception
            F(Of Panel)("pnlPermissions").Visible = False
            Notice(If(TypeOf ex Is ArgumentException, ex.Message, CRMData.ErrorMessage(ex)), True)
        End Try
    End Sub
    Private Sub BindPermissions(id As Integer)
        Dim data = CRMData.Query("dbo.CRM_WorkGuide_Permissions", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Account_ID", SqlDbType.Int, id))
        data.Columns.Add("Tree_Name", GetType(String))
        Dim ordered = data.Clone()
        AddChildren(data, ordered, Nothing, "")
        Dim ids As New List(Of Integer)
        For Each row As DataRow In ordered.Rows
            ids.Add(CInt(row("ID")))
        Next
        Dim nodes As New List(Of Object)
        For Each group In ordered.Rows.Cast(Of DataRow)().GroupBy(Function(r) CInt(r("Brand_ID")))
            Dim brandRow = group.First()
            nodes.Add(New With {.id = "grant-brand-" & group.Key.ToString(), .parent = "#", .text = Convert.ToString(brandRow("Brand_Name")) & " / " & Convert.ToString(brandRow("Brand_Name_EN")), .icon = "bx bx-buildings", .state = New With {.opened = True}, .data = New With {.brandId = group.Key.ToString(), .isBrand = True}})
        Next
        For Each row As DataRow In ordered.Rows
            nodes.Add(New With {.id = "grant-category-" & Convert.ToString(row("ID")), .parent = If(IsDBNull(row("Parent_ID")), "grant-brand-" & Convert.ToString(row("Brand_ID")), "grant-category-" & Convert.ToString(row("Parent_ID"))), .text = Convert.ToString(row("Name_AR")) & " / " & Convert.ToString(row("Name_EN")), .icon = "bx bx-folder", .state = New With {.opened = True}, .data = New With {.categoryId = Convert.ToString(row("ID"))}})
        Next
        F(Of Literal)("litGrantTreeData").Text = (New JavaScriptSerializer With {.MaxJsonLength = 8388608}).Serialize(nodes).Replace("<", "\u003c").Replace(">", "\u003e").Replace("&", "\u0026")
        ViewState("AccountID") = id : ViewState("CategoryIDs") = ids.ToArray()
        ViewState.Remove("AccessVersion") : ViewState.Remove("AccountVersion")
        If data.Rows.Count > 0 AndAlso Not IsDBNull(data.Rows(0)("Account_Version")) Then ViewState("AccountVersion") = DirectCast(data.Rows(0)("Account_Version"), Byte())
        If data.Rows.Count > 0 AndAlso Not IsDBNull(data.Rows(0)("Access_Version")) Then ViewState("AccessVersion") = DirectCast(data.Rows(0)("Access_Version"), Byte())
        F(Of Literal)("litAccount").Text = F(Of DropDownList)("account").SelectedItem.Text & If(data.Rows.Count = 0, "", " — " & String.Join("، ", data.Rows.Cast(Of DataRow)().Select(Function(r) Convert.ToString(r("Brand_Name"))).Distinct()))
        F(Of Literal)("statCategories").Text = data.Rows.Count.ToString("N0")
        F(Of Literal)("statGranted").Text = data.Rows.Cast(Of DataRow)().Count(Function(r) CBool(r("Can_View")) OrElse CBool(r("Can_Download"))).ToString("N0")
        F(Of Repeater)("permissions").DataSource = ordered : F(Of Repeater)("permissions").DataBind()
        F(Of Panel)("pnlPermissions").Visible = True : F(Of LinkButton)("btnSave").Enabled = data.Rows.Count > 0
    End Sub
    Private Sub AddChildren(data As DataTable, ordered As DataTable, parent As Integer?, indent As String)
        For Each row As DataRow In data.Rows
            If (Not parent.HasValue AndAlso IsDBNull(row("Parent_ID"))) OrElse (parent.HasValue AndAlso Not IsDBNull(row("Parent_ID")) AndAlso CInt(row("Parent_ID")) = parent.Value) Then
                row("Tree_Name") = indent & Convert.ToString(row("Name_AR"))

                ordered.ImportRow(row) : AddChildren(data, ordered, CInt(row("ID")), indent & "— ")
            End If
        Next
    End Sub
    Protected Sub Save_Click(sender As Object, e As EventArgs)
        If Not allowed Then Return
        Try
            If ViewState("AccountID") Is Nothing OrElse Convert.ToString(ViewState("AccountID")) <> F(Of DropDownList)("account").SelectedValue Then Throw New ArgumentException("اعرض صلاحيات العميل المختار قبل الحفظ.")
            Dim id = CInt(ViewState("AccountID")), ids = DirectCast(ViewState("CategoryIDs"), Integer()), grants As New XElement("grants")
            Dim rows = F(Of Repeater)("permissions").Items
            If rows.Count <> ids.Length Then Throw New ArgumentException("حدّث التصنيفات وأعد المحاولة.")
            For index = 0 To ids.Length - 1
                Dim view = DirectCast(rows(index).FindControl("canView"), CheckBox).Checked
                Dim download = DirectCast(rows(index).FindControl("canDownload"), CheckBox).Checked
                grants.Add(New XElement("grant", New XAttribute("id", ids(index)), New XAttribute("view", If(view, 1, 0)), New XAttribute("download", If(download, 1, 0))))
            Next
            CRMData.Query("dbo.CRM_Save_WorkGuide_Permissions", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Account_ID", SqlDbType.Int, id), CRMData.P("@Data", SqlDbType.Xml, grants.ToString()), CRMData.P("@Version", SqlDbType.Binary, ViewState("AccessVersion"), 8), CRMData.P("@Account_Version", SqlDbType.Binary, ViewState("AccountVersion"), 8))
            BindPermissions(id) : Notice("تم حفظ صلاحيات دليل العمل.", False)
        Catch ex As Exception
            Notice(If(TypeOf ex Is ArgumentException, ex.Message, CRMData.ErrorMessage(ex)), True)
        End Try
    End Sub
    Private Sub Notice(message As String, failed As Boolean)
        F(Of Literal)("litMessage").Text = "<div class='alert alert-" & If(failed, "danger", "success") & " alert-dismissible' role='alert'>" & CRMData.H(message) & "<button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='إغلاق'></button></div>"
    End Sub
End Class
