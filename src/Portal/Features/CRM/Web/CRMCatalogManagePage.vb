Imports System.Data
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public MustInherit Class CRMCatalogManagePage
    Inherits CRMModulePage
    Private reopenEditor As Boolean
    Private reopenDelete As Boolean

    Protected MustOverride ReadOnly Property RecordTitle As String
    Protected MustOverride ReadOnly Property NewRecordTitle As String

    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property

    Protected Sub NewType_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        ViewState("TypeEditorID") = 0
        ViewState.Remove("TypeEditorVersion")
        Field(Of Literal)("litEditorTitle").Text = "إضافة " & NewRecordTitle
        Field(Of TextBox)("editNameAr").Text = ""
        Field(Of TextBox)("editNameEn").Text = ""
        Field(Of TextBox)("editNotes").Text = ""
        Field(Of CheckBox)("editActive").Checked = True
        reopenEditor = True
    End Sub

    Protected Sub Type_RowCommand(sender As Object, e As ListViewCommandEventArgs)
        If Not CRMAccessAllowed Then Return
        If e.CommandName <> "EditType" AndAlso e.CommandName <> "AskDelete" Then
            MyBase.Row_Command(sender, e)
            Return
        End If
        Try
            Dim id As Integer
            If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then Throw New InvalidOperationException("رقم السجل غير صحيح.")
            Dim key = Field(Of ListView)("lstData").DataKeys(e.Item.DataItemIndex)
            If CInt(key.Values("ID")) <> id Then Throw New InvalidOperationException("حدّث القائمة وأعد المحاولة.")
            Dim data = CRMData.Rows(EntityName, CrmUserId(), id)
            If data.Rows.Count = 0 Then Throw New InvalidOperationException("السجل غير متاح. حدّث القائمة وأعد المحاولة.")
            Dim row = data.Rows(0)
            If e.CommandName = "AskDelete" Then
                ViewState("TypeDeleteID") = id
                ViewState("TypeDeleteVersion") = DirectCast(key.Values("Row_Version"), Byte())
                Field(Of Literal)("litDeleteName").Text = Convert.ToString(row("Name_AR"))
                reopenDelete = True
                Return
            End If
            ViewState("TypeEditorID") = id
            ViewState("TypeEditorVersion") = DirectCast(row("Row_Version"), Byte())
            Field(Of Literal)("litEditorTitle").Text = "تعديل " & RecordTitle
            Field(Of TextBox)("editNameAr").Text = Convert.ToString(row("Name_AR"))
            Field(Of TextBox)("editNameEn").Text = Convert.ToString(row("Name_EN"))
            Field(Of TextBox)("editNotes").Text = Convert.ToString(row("Notes"))
            Field(Of CheckBox)("editActive").Checked = CBool(row("Is_Active"))
            reopenEditor = True
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub ConfirmDelete_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Try
            If ViewState("TypeDeleteID") Is Nothing OrElse ViewState("TypeDeleteVersion") Is Nothing Then Throw New InvalidOperationException("اختر العنصر المراد حذفه من القائمة أولًا.")
            Dim id = CInt(ViewState("TypeDeleteID"))
            Dim version = DirectCast(ViewState("TypeDeleteVersion"), Byte())
            ViewState.Remove("TypeDeleteID")
            ViewState.Remove("TypeDeleteVersion")
            CRMData.Query("dbo.CRM_Delete", CRMData.P("@Actor_ID", SqlDbType.Int, CrmUserId()), CRMData.P("@Entity", SqlDbType.NVarChar, EntityName, 80), CRMData.P("@ID", SqlDbType.Int, id), CRMData.P("@Version", SqlDbType.Binary, version, 8))
            ShowSuccess("تم حذف " & RecordTitle & " بنجاح.")
        Catch ex As Exception
            ShowError(ex)
        End Try
    End Sub

    Protected Sub SaveType_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        reopenEditor = True
        Page.Validate("TypeEditor")
        If Not Page.IsValid Then Return
        Try
            If ViewState("TypeEditorID") Is Nothing Then Throw New InvalidOperationException("افتح نموذج الإضافة أو التعديل من القائمة أولًا.")
            Dim id = CInt(ViewState("TypeEditorID"))
            Dim data As New XElement("row",
                New XElement("Name_AR", Field(Of TextBox)("editNameAr").Text.Trim()),
                New XElement("Name_EN", Field(Of TextBox)("editNameEn").Text.Trim()),
                New XElement("Notes", Field(Of TextBox)("editNotes").Text.Trim()),
                New XElement("Is_Active", If(Field(Of CheckBox)("editActive").Checked, "1", "0")))
            CRMData.Save(EntityName, CrmUserId(), id, data, TryCast(ViewState("TypeEditorVersion"), Byte()))
            ViewState.Remove("TypeEditorID")
            ViewState.Remove("TypeEditorVersion")
            reopenEditor = False
            ShowSuccess(If(id = 0, "تمت إضافة " & RecordTitle & " بنجاح.", "تم حفظ تعديلات " & RecordTitle & " بنجاح."))
        Catch ex As Exception
            Field(Of Literal)("litEditorMessage").Text = AlertMarkup(CRMData.ErrorMessage(ex), True)
        End Try
    End Sub

    Protected Sub ResetSearch_Click(sender As Object, e As EventArgs)
        If Not CRMAccessAllowed Then Return
        Field(Of TextBox)("filterName").Text = ""
        Field(Of DropDownList)("filterStatus").SelectedValue = ""
        MyBase.Search_Click(sender, e)
    End Sub

    Private Function AlertMarkup(message As String, failed As Boolean) As String
        Dim kind = If(failed, "danger", "success")
        Dim icon = If(failed, "bx-error-circle", "bx-check-circle")
        Dim title = If(failed, "تعذّر إكمال العملية", "تمت العملية بنجاح")
        Return "<div class=""alert alert-" & kind & " alert-dismissible"" role=""alert""><h6 class=""alert-heading mb-1""><i class=""bx bx-xs " & icon & " align-top me-2"" aria-hidden=""true""></i>" & title & "</h6><span>" & CRMData.H(message) & "</span><button type=""button"" class=""btn-close"" data-bs-dismiss=""alert"" aria-label=""إغلاق""></button></div>"
    End Function

    Protected Overrides Sub ShowSuccess(message As String)
        Field(Of Literal)("litMessage").Text = AlertMarkup(message, False)
    End Sub

    Protected Overrides Sub ShowError(ex As Exception)
        Field(Of Literal)("litMessage").Text = AlertMarkup(CRMData.ErrorMessage(ex), True)
    End Sub

    Protected Overrides Sub PrepareListData(data As DataTable)
        Dim active As Integer = 0
        For Each row As DataRow In data.Rows
            If CBool(row("Is_Active")) Then active += 1
        Next
        Field(Of Literal)("statTotal").Text = data.Rows.Count.ToString("N0")
        Field(Of Literal)("statActive").Text = active.ToString("N0")
        Field(Of Literal)("statInactive").Text = (data.Rows.Count - active).ToString("N0")
    End Sub

    Protected Overrides Sub OnPreRender(e As EventArgs)
        MyBase.OnPreRender(e)
        If reopenDelete AndAlso CRMAccessAllowed Then
            Dim script = "(function(){function openDelete(){var panel=document.getElementById('typeDeleteModal');if(panel&&window.bootstrap)bootstrap.Modal.getOrCreateInstance(panel).show();}if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',openDelete,{once:true});}else{openDelete();}}());"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "type-delete", script, True)
        End If
        If reopenEditor AndAlso CRMAccessAllowed Then
            Dim script = "(function(){function openEditor(){var panel=document.getElementById('typeEditor');if(!panel||!window.bootstrap)return;panel.addEventListener('shown.bs.offcanvas',function(){var input=document.getElementById('" & Field(Of TextBox)("editNameAr").ClientID & "');if(input)input.focus();},{once:true});bootstrap.Offcanvas.getOrCreateInstance(panel).show();}if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',openEditor,{once:true});}else{openEditor();}}());"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "type-editor", script, True)
        End If
    End Sub
End Class
