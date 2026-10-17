Imports System.Web.UI.WebControls

Public NotInheritable Class NewsPresentation
    Public Shared Sub BindBrands(list As DropDownList, rows As Object)
        list.DataSource = rows
        list.DataValueField = "ID" : list.DataTextField = "Title_Ar" : list.DataBind()
    End Sub

    Public Shared Sub InsertPrompt(list As DropDownList, prompt As String)
        list.Items.Insert(0, New System.Web.UI.WebControls.ListItem(prompt, "0"))
    End Sub
End Class
