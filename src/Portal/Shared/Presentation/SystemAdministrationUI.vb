Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Web.UI
Imports System.Web.UI.WebControls

' An explicit UI allowlist: existing page authorization, validators and domain saves remain authoritative.
Public NotInheritable Class SystemAdministrationUI
 Public Class ModuleDefinition
  Public Property Title As String
  Public Property Manage As String
  Public Property Add As String
  Public Property Edit As String
  Public Property Special As String
 End Class
 Private Shared ReadOnly Modules As ModuleDefinition()={
  Define("صلاحيات الشكاوى والاقتراحات","Employee_Feedback_Permissions","ManageEmployeeFeedbackPermissions",Nothing,Nothing,"permissions"),
  Define("أنواع الشكاوى والاقتراحات","Employee_Feedback_Types","ManageEmployeeFeedbackTypes","AddEmployeeFeedbackTypes","EditEmployeeFeedbackTypes"),
  Define("مواضيع الشكاوى والاقتراحات","Employee_Feedback_Topics","ManageEmployeeFeedbackTopics","AddEmployeeFeedbackTopics","EditEmployeeFeedbackTopics"),
  Define("العلامات التجارية","Brands","ManageBrands","AddBrands","EditBrands"),
  Define("الأفرع","Branches","ManageBranches","AddBranches","EditBranches"),
  Define("الأقسام","Departments","ManageDepartments","AddDepartments","EditDepartments"),
  Define("المحطات التعريفية","JobTitles","ManageJobTitles","AddJobTitles","EditJobTitles"),
  Define("أنواع الأدوات","JobTitle_Items_Types","ManageJobTitle_Items_types","AddJobTitle_Items_types","EditJobTitle_Items_types"),
  Define("الأدوات","JobTitle_Items","Manage_JobTitle_Items","Add_JobTitle_Items","Edit_JobTitle_Items"),
  Define("شركات الصيانة","Maintenance_Companies","ManageMaintenance_Companies","AddMaintenance_Companies","EditMaintenance_Companies"),
  Define("فترات العمل","Shift","ManageShift","AddShift","EditShift"),
  Define("أنواع الإجازات","HR_Vacations_Types","Manage_HR_Vacations_Types","Add_HR_Vacations_Types","Edit_HR_Vacations_Types"),
  Define("أنواع المغادرات","HR_Leaves_Types","Manage_HR_Leaves_Types","Add_HR_Leaves_Types","Edit_HR_Leaves_Types"),
  Define("الجنس","Genders","ManageGenders","AddGenders","EditGenders"),
  Define("الجنسيات","Nationalities","ManageNationalities","AddNationalities","EditNationalities"),
  Define("أنواع الموظفين","Users_Types","Manage_Users_Types","Add_Users_Types","Edit_Users_Types"),
  Define("إعدادات API","Attendance_Integration","ManageAttendanceIntegration",Nothing,Nothing,"integration"),
  Define("الموظفون","Users","ManageUsers","AddUsers","EditUsers")}
 Private Shared Function Define(title As String,folder As String,manage As String,add As String,edit As String,Optional special As String="") As ModuleDefinition
  Dim root="/Modules/" & folder & "/"
  Return New ModuleDefinition With {.Title=title,.Manage=root & manage & ".aspx",.Add=If(add Is Nothing,"",root & add & ".aspx"),.Edit=If(edit Is Nothing,"",root & edit & ".aspx"),.Special=special}
 End Function
 Public Shared Function Definition(page As Page) As ModuleDefinition
  Dim path=page.Request.Url.AbsolutePath
  Return Modules.FirstOrDefault(Function(m) String.Equals(m.Manage,path,StringComparison.OrdinalIgnoreCase) OrElse String.Equals(m.Add,path,StringComparison.OrdinalIgnoreCase) OrElse String.Equals(m.Edit,path,StringComparison.OrdinalIgnoreCase))
 End Function
 Public Shared Sub Prepare(page As Page)
  If Definition(page) Is Nothing Then Return
  If SessionManager.GetInstance.Users Is Nothing Then page.Response.Redirect("~/Login.aspx") : Return
  ContentManagementData.RequireAdmin(SessionManager.GetInstance.Users.UserID)
  page.ViewStateUserKey=page.Session.SessionID
  page.Response.Cache.SetNoStore()
  page.Response.AddHeader("X-Frame-Options","SAMEORIGIN")
  Dim info=Definition(page)
  If page.Request.HttpMethod="GET" AndAlso Not IsEditor(page) AndAlso Not String.Equals(page.Request.Url.AbsolutePath,info.Manage,StringComparison.OrdinalIgnoreCase) Then
   Dim id As Integer,query=If(String.Equals(page.Request.Url.AbsolutePath,info.Add,StringComparison.OrdinalIgnoreCase),"?new=1",If(Integer.TryParse(page.Request.QueryString("ID"),id) AndAlso id>0,"?edit=" & id.ToString(),""))
   page.Response.Redirect(info.Manage & query)
  End If
 End Sub
 Public Shared Function IsEditor(page As Page) As Boolean
  Dim token=page.Request.QueryString("saEditor"),moduleInfo=Definition(page)
  Return moduleInfo IsNot Nothing AndAlso token IsNot Nothing AndAlso token.Length=32 AndAlso String.Equals(TryCast(page.Session("SystemAdminEditor:" & token),String),moduleInfo.Manage,StringComparison.OrdinalIgnoreCase)
 End Function
 Public Shared Sub RegisterRefresh(page As Page,refresh As Action)
  page.Items("SystemAdminRefresh")=refresh
 End Sub
 Public Shared Sub Refresh(page As Page)
  Dim reload=TryCast(page.Items("SystemAdminRefresh"),Action)
  If reload IsNot Nothing Then reload()
 End Sub
 Public Shared Function Statistics(page As Page) As Object
  Dim info=Definition(page)
  If info.Special="permissions" Then
   Dim rows=EmployeeFeedbackConfig.Permissions(SessionManager.GetInstance.Users.UserID,True)
   Return New With {.total=rows.Count,.active=rows.Where(Function(r) r.CanSubmit).Count(),.inactive=rows.Where(Function(r) r.CanTransfer).Count()}
  End If
  Dim table=info.Manage.Split("/"c)(2),active="IsActive"
  If table="Users" Then table="UsersMembers"
  If table="HR_Vacations_Types" OrElse table="HR_Leaves_Types" Then active="Is_Active"
  Dim sql="SELECT COUNT(*) Total,COALESCE(SUM(CASE WHEN " & active & "=1 THEN 1 ELSE 0 END),0) Active FROM dbo.[" & table & "] WHERE ISNULL(IsDeleted,0)=0"
  If active="Is_Active" Then sql=sql.Replace("IsDeleted","Is_Deleted")
  If info.Special="integration" Then sql="SELECT COUNT(*) Total,COALESCE(SUM(CASE WHEN a.Enabled=1 THEN 1 ELSE 0 END),0) Active,COALESCE(SUM(CASE WHEN a.Enabled=0 THEN 1 ELSE 0 END),0) Inactive FROM dbo.Brands b LEFT JOIN dbo.AttendanceIntegrationSettings a ON a.BrandID=b.ID WHERE ISNULL(b.IsDeleted,0)=0 AND b.IsActive=1"
  Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext(),cn As New SqlConnection(db.Connection.ConnectionString),cmd As New SqlCommand(sql,cn)
   cn.Open()
   Using reader=cmd.ExecuteReader()
    reader.Read()
    Dim total=Convert.ToInt32(reader("Total")),enabled=Convert.ToInt32(reader("Active"))
    Return New With {.total=total,.active=enabled,.inactive=If(info.Special="integration",Convert.ToInt32(reader("Inactive")),total-enabled)}
   End Using
  End Using
 End Function
 Public Shared Function Json(value As Object) As String
  Return (New JavaScriptSerializer()).Serialize(value).Replace("<","\u003c").Replace(">","\u003e").Replace("&","\u0026")
 End Function
 Public Shared Function Complete(page As Page,Optional cancelled As Boolean=False) As Boolean
  If Not IsEditor(page) Then Return False
  Dim recordID As Integer,info=Definition(page)
  Integer.TryParse(page.Request.QueryString("ID"),recordID)
  If info.Special<>"" Then
   Dim content=page.Master.FindControl("ContentPlaceHolder1"),selector=TryCast(content.FindControl(If(info.Special="integration","ddlBrand","ddlRole")),ListControl)
   If selector IsNot Nothing Then Integer.TryParse(selector.SelectedValue,recordID)
  End If
  Dim payload=Json(New With {.type="system-admin-complete",.token=page.Request.QueryString("saEditor"),.cancelled=cancelled,.recordId=recordID})
  ScriptManager.RegisterStartupScript(page,page.GetType(),"system-admin-complete","window.parent.postMessage(" & payload & ",window.location.origin);",True)
  Return True
 End Function
 Public Shared Sub Redirect(page As Page,url As String,Optional cancelled As Boolean=False)
  Dim moduleInfo=Definition(page),target As New Uri(page.Request.Url,url)
  If moduleInfo IsNot Nothing AndAlso String.Equals(target.AbsolutePath,moduleInfo.Manage,StringComparison.OrdinalIgnoreCase) AndAlso Complete(page,cancelled) Then Return
  page.Response.Redirect(url)
 End Sub
 Public Shared Function State(item As Object) As String
  For Each name In {"IsActive","Is_Active"}
   Try
    Dim value=DataBinder.Eval(item,name)
    Return If(value Is Nothing OrElse value Is DBNull.Value,"0",If(Convert.ToBoolean(value),"1","0"))
   Catch ex As HttpException
   End Try
  Next
  Return ""
 End Function
 Public Shared Function SearchName(item As Object) As String
  Dim properties=Global.System.ComponentModel.TypeDescriptor.GetProperties(item),names As New Collections.Generic.List(Of String)()
  For Each name In {"Title_Ar","Title_En","Name_AR","Name_EN","FullName_Ar","Fullname_En","UserName","Title"}
   Dim field=properties.Find(name,True)
   If field IsNot Nothing Then names.Add(Convert.ToString(field.GetValue(item)))
  Next
  Return String.Join(" ",names)
 End Function
 Public Shared Function UploadExtension(fileName As String,imageOnly As Boolean) As String
  Dim extension=IO.Path.GetExtension(fileName).ToLowerInvariant()
  Dim allowed=If(imageOnly,New String(){".jpg",".jpeg",".png"},New String(){".mp4",".avi",".mov",".wmv",".jpg",".jpeg",".png"})
  If Not allowed.Contains(extension) Then Throw New ArgumentException("نوع الملف غير مسموح.")
  Return extension
 End Function
 Public Shared Function IntegrationRows(page As Page) As String
  ContentManagementData.RequireAdmin(SessionManager.GetInstance.Users.UserID)
  Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext(),cn As New SqlConnection(db.Connection.ConnectionString),cmd As New SqlCommand("SELECT b.ID,b.Title_Ar,b.Title_En,a.Enabled ApiEnabled,e.Enabled EmailEnabled FROM dbo.Brands b LEFT JOIN dbo.AttendanceIntegrationSettings a ON a.BrandID=b.ID LEFT JOIN dbo.EmailNotificationSettings e ON e.BrandID=b.ID WHERE ISNULL(b.IsDeleted,0)=0 AND b.IsActive=1 ORDER BY b.Title_Ar",cn)
   cn.Open()
   Dim html As New Text.StringBuilder("<table id='ERPTable' data-enhanced='1' class='table type-table'><thead><tr><th>العلامة التجارية</th><th>الاسم بالإنجليزية</th><th>تكامل API</th><th>إرسال البريد</th><th>الإجراءات</th></tr></thead><tbody>")
   Using reader=cmd.ExecuteReader()
    While reader.Read()
     Dim active=If(reader.IsDBNull(3),"",If(reader.GetBoolean(3),"1","0"))
     html.Append("<tr data-admin-id='").Append(reader.GetInt32(0)).Append("' data-admin-active='").Append(active).Append("'><td data-title='العلامة التجارية'>").Append(HttpUtility.HtmlEncode(Convert.ToString(reader(1)))).Append("</td><td data-title='الاسم بالإنجليزية' dir='ltr'>").Append(HttpUtility.HtmlEncode(Convert.ToString(reader(2)))).Append("</td><td data-title='تكامل API'>").Append(If(active="","غير مُعدّ",If(active="1","فعال","موقوف"))).Append("</td><td data-title='إرسال البريد'>").Append(If(reader.IsDBNull(4),"غير مُعدّ",If(Convert.ToBoolean(reader(4)),"فعال","موقوف"))).Append("</td><td data-title='الإجراءات'><a data-admin-edit href='ManageAttendanceIntegration.aspx?brand=").Append(reader.GetInt32(0)).Append("' class='btn btn-icon' title='تعديل الإعدادات'><i class='fa-solid fa-pen-to-square'></i></a></td></tr>")
    End While
   End Using
   Return html.Append("</tbody></table>").ToString()
  End Using
 End Function
End Class
