Imports System.Data
Imports System.Linq
Imports System.Web
Imports System.Web.Script.Serialization
Imports System.Xml.Linq

Public Class CircularsAdminAjax
 Inherits PageBase
 Protected Overrides Sub OnLoad(e As EventArgs)
  MyBase.OnLoad(e)
  Response.ContentType="application/json; charset=utf-8" : Response.Cache.SetNoStore() : Response.AddHeader("X-Content-Type-Options","nosniff")
  Try
   If SessionManager.GetInstance.Users Is Nothing Then Throw New HttpException(401,"سجّل الدخول مجددًا.")
   If Request.HttpMethod<>"POST" Then Throw New HttpException(405,"استخدم POST.")
   If Session("CircularCsrf") Is Nothing OrElse Request.Headers("X-Circular-CSRF")<>CStr(Session("CircularCsrf")) Then Throw New HttpException(403,"انتهت صلاحية النموذج؛ أعد فتح الصفحة.")
   Dim actor=SessionManager.GetInstance.Users.UserID
   ContentManagementData.RequireAdmin(actor)
   Dim raw=Request.Unvalidated.Form("payload")
   If raw Is Nothing OrElse raw.Length>50000 Then Throw New ArgumentException("راجع بيانات النموذج.")
   Dim serializer As New JavaScriptSerializer With {.MaxJsonLength=2000000}
   Dim data=serializer.Deserialize(Of Collections.Generic.Dictionary(Of String,Object))(raw), action=Request.QueryString("action"), result As Object=Nothing
   Dim id=If(data.ContainsKey("id"),ContentManagementData.Number(data,"id"),0)
   Select Case action
    Case "list","editor","logs"
     Dim page=If(data.ContainsKey("page"),ContentManagementData.Number(data,"page",1),1)
     Dim ds=CircularsData.Query("dbo.Circular_AdminData",CircularsData.P("@Actor",SqlDbType.Int,actor),CircularsData.P("@Mode",SqlDbType.VarChar,action,10),CircularsData.P("@ID",SqlDbType.Int,id),CircularsData.P("@Page",SqlDbType.Int,page))
     If action="list" Then
      result=New With {.rows=Rows(ds.Tables(0))}
     ElseIf action="editor" Then
      If id>0 AndAlso ds.Tables(0).Rows.Count=0 Then Throw New HttpException(404,"التعميم غير متاح.")
      result=New With {.item=If(ds.Tables(0).Rows.Count=0,Nothing,Rows(ds.Tables(0))(0)),.targets=ContentManagementData.Records(ds.Tables(1)),.lookups=ContentManagementData.Records(ds.Tables(2))}
     Else
      result=New With {.total=CInt(ds.Tables(0).Rows(0)("Total")),.rows=Rows(ds.Tables(1))}
     End If
    Case "toggle"
     Dim enabled=Flag(data,"enabled")
     Dim ds=CircularsData.Query("dbo.Circular_AdminToggle",CircularsData.P("@Actor",SqlDbType.Int,actor),CircularsData.P("@ID",SqlDbType.Int,id),CircularsData.P("@ExpectedVersion",SqlDbType.Int,ContentManagementData.Number(data,"version",1)),CircularsData.P("@Enabled",SqlDbType.Bit,enabled))
     result=New With {.id=CInt(ds.Tables(0).Rows(0)("ID"))}
     Dispatch()
    Case "save"
     Dim dateValue As DateTime
     If Not DateTime.TryParseExact(ContentManagementData.Text(data,"date",10,True),"yyyy-MM-dd",Global.System.Globalization.CultureInfo.InvariantCulture,Global.System.Globalization.DateTimeStyles.None,dateValue) Then Throw New ArgumentException("اختر تاريخ التعميم.")
     Dim period=Flag(data,"period"), enabled=Flag(data,"enabled"),download=Flag(data,"download"), startUtc As Object=Nothing,endUtc As Object=Nothing
     If period Then
      startUtc=InformationPagesData.ParseDate(ContentManagementData.Text(data,"start",20,True)) : endUtc=InformationPagesData.ParseDate(ContentManagementData.Text(data,"end",20,True))
     End If
     Dim targets As New XElement("targets")
     For Each kind In {"role","branch","department","shift","customer","customerType"}
      For Each part In ContentManagementData.Text(data,kind,20000).Split(","c).Where(Function(x) Not String.IsNullOrWhiteSpace(x)).Distinct()
       Dim target As Integer
       If Not Integer.TryParse(part,target) OrElse target<=0 Then Throw New ArgumentException("اختيار غير صحيح.")
       targets.Add(New XElement("item",New XAttribute("kind",kind),New XAttribute("id",target)))
      Next
     Next
     Dim upload=Request.Files("file"), bytes As Byte()=Nothing, filename As String=Nothing
     If upload IsNot Nothing AndAlso upload.ContentLength>0 Then
      bytes=CircularsData.Pdf(upload) : filename=IO.Path.GetFileName(upload.FileName)
      If filename.Length>250 Then Throw New ArgumentException("اسم الملف طويل.")
     ElseIf id=0 Then
      Throw New ArgumentException("أرفق ملف PDF للتعميم.")
     End If
     Dim ds=CircularsData.Query("dbo.Circular_AdminSave",CircularsData.P("@Actor",SqlDbType.Int,actor),CircularsData.P("@ID",SqlDbType.Int,id),CircularsData.P("@ExpectedVersion",SqlDbType.Int,ContentManagementData.Number(data,"version")),CircularsData.P("@BrandID",SqlDbType.Int,ContentManagementData.Number(data,"brand",1)),
      CircularsData.P("@Title",SqlDbType.NVarChar,ContentManagementData.Text(data,"titleAr",250,True),250),CircularsData.P("@Title_EN",SqlDbType.NVarChar,ContentManagementData.Text(data,"titleEn",250,True),250),CircularsData.P("@Summary",SqlDbType.NVarChar,ContentManagementData.Text(data,"summaryAr",2000,True),2000),CircularsData.P("@Summary_EN",SqlDbType.NVarChar,ContentManagementData.Text(data,"summaryEn",2000,True),2000),
      CircularsData.P("@CircularDate",SqlDbType.Date,dateValue),CircularsData.P("@HasPeriod",SqlDbType.Bit,period),CircularsData.P("@StartUtc",SqlDbType.DateTime2,startUtc),CircularsData.P("@EndUtc",SqlDbType.DateTime2,endUtc),CircularsData.P("@IsEnabled",SqlDbType.Bit,enabled),CircularsData.P("@AllowDownload",SqlDbType.Bit,download),CircularsData.P("@Audience",SqlDbType.VarChar,ContentManagementData.Text(data,"audience",16,True),16),CircularsData.P("@Targets",SqlDbType.Xml,targets.ToString()),CircularsData.P("@FileName",SqlDbType.NVarChar,filename,250),CircularsData.P("@FileBytes",SqlDbType.VarBinary,bytes,-1))
     result=New With {.id=CInt(ds.Tables(0).Rows(0)("ID")),.version=CInt(ds.Tables(0).Rows(0)("Version"))}
     Dispatch()
    Case Else
     Throw New HttpException(400,"طلب غير صحيح.")
   End Select
   Response.Write(serializer.Serialize(result))
  Catch ex As Exception
   Dim http=TryCast(ex,HttpException),sql=TryCast(ex,System.Data.SqlClient.SqlException)
   Response.StatusCode=If(http IsNot Nothing,http.GetHttpCode(),If(TypeOf ex Is ArgumentException,422,If(sql IsNot Nothing AndAlso sql.Number=51809,409,If(sql IsNot Nothing AndAlso sql.Number=51801,403,If(sql IsNot Nothing AndAlso sql.Number=51804,404,If(sql IsNot Nothing AndAlso sql.Number=51800,422,500))))))
   Response.TrySkipIisCustomErrors=True
   Response.Write((New JavaScriptSerializer()).Serialize(New With {.message=If(http IsNot Nothing,http.Message,CircularsPresentation.ErrorText(ex))}))
  End Try
  Context.ApplicationInstance.CompleteRequest()
 End Sub
 Private Shared Function Flag(data As Collections.Generic.Dictionary(Of String,Object),key As String) As Boolean
  Dim value=ContentManagementData.Text(data,key,1,True)
  If value<>"0" AndAlso value<>"1" Then Throw New ArgumentException("اختر حالة صحيحة.")
  Return value="1"
 End Function
 Private Shared Sub Dispatch()
  Try
   CircularsData.Query("dbo.Circular_Dispatch")
  Catch ex As Exception
   System.Diagnostics.Trace.TraceError("Circular dispatch deferred: {0}",ex.GetType().Name)
  End Try
 End Sub
 Private Shared Function Rows(table As DataTable) As Object()
  For Each name In {"StartLocal","EndLocal","DateText","TimeText"}
   If Not table.Columns.Contains(name) Then table.Columns.Add(name,GetType(String))
  Next
  For Each row As DataRow In table.Rows
   If table.Columns.Contains("StartUtc") Then row("StartLocal")=InformationPagesData.LocalDate(row("StartUtc"),True)
   If table.Columns.Contains("EndUtc") Then row("EndLocal")=InformationPagesData.LocalDate(row("EndUtc"),True)
   If table.Columns.Contains("CircularDate") Then row("DateText")=CDate(row("CircularDate")).ToString("yyyy/MM/dd")
   If table.Columns.Contains("RecordedUtc") Then row("TimeText")=InformationPagesData.LocalDate(row("RecordedUtc"))
  Next
  Return ContentManagementData.Records(table)
 End Function
 Protected Overrides Sub Render(writer As System.Web.UI.HtmlTextWriter)
 End Sub
End Class
