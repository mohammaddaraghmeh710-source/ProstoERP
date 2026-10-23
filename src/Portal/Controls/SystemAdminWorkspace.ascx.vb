Imports System.Linq
Imports System.Web.UI
Imports System.Web.UI.WebControls
Public Class SystemAdminWorkspace
 Inherits UserControl
 Protected WithEvents reloadAdmin As Button
 Private moduleInfo As SystemAdministrationUI.ModuleDefinition
 Protected Property ConfigurationJson As String="{}"
 Protected Overrides Sub OnInit(e As EventArgs)
  MyBase.OnInit(e)
  moduleInfo=SystemAdministrationUI.Definition(Page)
  Dim styles=Page.Master.FindControl("systemAdminStyles")
  If styles IsNot Nothing Then styles.Visible=moduleInfo IsNot Nothing
  If moduleInfo Is Nothing Then Visible=False : Return
 End Sub
 Protected Overrides Sub OnLoad(e As EventArgs)
  MyBase.OnLoad(e)
  If moduleInfo Is Nothing Then Return
  ScriptManager.GetCurrent(Page).RegisterAsyncPostBackControl(reloadAdmin)
  Dim key="SystemAdminPage:" & moduleInfo.Manage,token=TryCast(Session(key),String)
  If token Is Nothing Then token=Guid.NewGuid().ToString("N") : Session(key)=token
  Session("SystemAdminEditor:" & token)=moduleInfo.Manage
  If SystemAdministrationUI.IsEditor(Page) Then
   Dim timer=TryCast(Page.Master.FindControl("tmCorrespondenceCount"),Timer)
   If timer IsNot Nothing Then timer.Enabled=False
  End If
  ConfigurationJson=SystemAdministrationUI.Json(New With {.title=moduleInfo.Title,.manage=moduleInfo.Manage,.add=moduleInfo.Add,.edit=moduleInfo.Edit,.special=moduleInfo.Special,.editor=SystemAdministrationUI.IsEditor(Page),.token=token})
  If Page.Title="" Then Page.Title=moduleInfo.Title
 End Sub
 Protected Sub Reload_Click(sender As Object,e As EventArgs)
  SystemAdministrationUI.Refresh(Page)
  Dim content=Page.Master.FindControl("ContentPlaceHolder1"),panel=TryCast(content.FindControl("systemAdminPanel"),UpdatePanel)
  If panel IsNot Nothing Then panel.Update()
 End Sub
 Private Sub RegisterCommands(root As Control, manager As ScriptManager)
  If root Is Nothing Then Return
  For Each child As Control In root.Controls
   If TypeOf child Is LinkButton Then manager.RegisterAsyncPostBackControl(child)
   RegisterCommands(child,manager)
  Next
 End Sub
 Protected Overrides Sub OnPreRender(e As EventArgs)
  MyBase.OnPreRender(e)
  If moduleInfo Is Nothing Then Return
  Dim manager=ScriptManager.GetCurrent(Page)
  RegisterCommands(Page.Master.FindControl("ContentPlaceHolder1"),manager)
  Dim target=If(Page.Request.Form("__EVENTTARGET"),"")
  If manager.IsInAsyncPostBack AndAlso Not target.Contains("ContentPlaceHolder1") AndAlso Not target.Contains("reloadAdmin") Then Return
  If manager.IsInAsyncPostBack AndAlso target.Contains("ContentPlaceHolder1") Then
   Dim content=Page.Master.FindControl("ContentPlaceHolder1"),panel=TryCast(content.FindControl("systemAdminPanel"),UpdatePanel)
   If panel IsNot Nothing Then panel.Update()
  End If
  Dim script="if(window.SystemAdministration){"
  If Not SystemAdministrationUI.IsEditor(Page) Then script &= "SystemAdministration.setCounts(" & SystemAdministrationUI.Json(SystemAdministrationUI.Statistics(Page)) & ");"
  script &= "SystemAdministration.initialize();}"
  ScriptManager.RegisterStartupScript(Page,Page.GetType(),"system-admin-initialize",script,True)
 End Sub
End Class
