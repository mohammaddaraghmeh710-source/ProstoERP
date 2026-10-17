using System.Net.Http;
using System.Web.Http;
using System;
using System.Data;
using System.Data.SqlClient;
using Prosto_ERP_ClassLibrary;

static class BrandIntegrationTests
{
 sealed class Upstream : System.Net.Http.HttpMessageHandler
 {
  public int Calls;
  public bool CustomOrigin = true;
  protected override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> SendAsync(System.Net.Http.HttpRequestMessage request,System.Threading.CancellationToken ct)
  { Calls++; CustomOrigin &= request.RequestUri.Host=="biotime.example" && request.RequestUri.Scheme=="https" && request.RequestUri.Port==8443; return System.Threading.Tasks.Task.FromResult(new System.Net.Http.HttpResponseMessage(System.Net.HttpStatusCode.OK){ Content=new System.Net.Http.StringContent(request.Method==System.Net.Http.HttpMethod.Post?"{\"token\":\"internal\"}":"{\"data\":[],\"next\":null}") }); }
 }
 static int count;
 static void Check(bool value,string name){if(!value)throw new Exception(name);count++;Console.WriteLine("PASS "+name);}
 static void Denied(Action operation,int number,string name){try{operation();throw new Exception("Not rejected: "+name);}catch(SqlException ex){Check(ex.Number==number,name);}}
 static byte[] Version(AttendanceIntegration store,int brand){return (byte[])store.Metadata(1,brand).Rows[0]["Version"];}
 public static void Run(string connection)
 {
  var store=new AttendanceIntegration(connection);
  Check(AttendanceIntegration.Unprotect(AttendanceIntegration.Protect("synthetic-secret"))=="synthetic-secret","DPAPI roundtrip");
  Check(store.Authenticate("any","any")==-1,"legacy mode before first configuration");
  var emptyConfig=new HttpConfiguration();
  var emptyRequest=new HttpRequestMessage(HttpMethod.Post,"http://localhost/api/attendance/transactions"); emptyRequest.SetConfiguration(emptyConfig);
  emptyRequest.Headers.Authorization=new System.Net.Http.Headers.AuthenticationHeaderValue("Basic",Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes("synthetic:unconfigured")));
  var emptyContext=new System.Web.Http.Controllers.HttpActionContext { ControllerContext=new System.Web.Http.Controllers.HttpControllerContext { Request=emptyRequest,Configuration=emptyConfig } };
  new Prosto_ERP_API.Controllers.AttendanceAuthenticationAttribute(store).OnAuthorization(emptyContext);
  Check(emptyContext.Response.StatusCode==System.Net.HttpStatusCode.Unauthorized,"database authentication denies unconfigured brands");
  store.Save(1,1,"brand-one-api","api-test-one","bio-one","bio-test-one",true,null,"https://attendance.example/erp/","https://biotime.example:8443/");
  store.Save(1,2,"brand-two-api","api-test-two","bio-two","bio-test-two",true,null);
  Check(store.Authenticate("brand-one-api","api-test-one")==1 && store.Authenticate("brand-two-api","api-test-two")==2,"brand-isolated API credentials");
  Check(store.Authenticate("brand-one-api","api-test-two")==0 && store.Authenticate("missing","wrong")==0,"wrong credentials / no legacy bypass after configuration");
  var meta=store.Metadata(1,1);Check(!meta.Columns.Contains("ApiPassword") && !meta.Columns.Contains("BioPassword") && !meta.Columns.Contains("ApiHash"),"admin metadata excludes passwords and hashes");
  Denied(()=>store.Metadata(10,1),51700,"non-admin cannot read settings metadata");
  Denied(()=>store.Save(10,1,"x","x","x","x",true,null),51700,"non-admin cannot save settings");
  var rows=store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",10),new SqlParameter("@EmployeeID",10));
  Check(rows.Rows.Count==1 && (string)rows.Rows[0]["ApiUsername"]=="brand-one-api" && AttendanceIntegration.Unprotect((byte[])rows.Rows[0]["BioPassword"])=="bio-test-one","own employee gets correct brand settings");
  Denied(()=>store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",10),new SqlParameter("@EmployeeID",20)),51700,"cross-employee secret access denied");
  var v=Version(store,1);
  store.Save(1,1,"brand-one-api","","bio-one-edited","",true,v);
  rows=store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",1),new SqlParameter("@EmployeeID",10));
  Check(AttendanceIntegration.Unprotect((byte[])rows.Rows[0]["ApiPassword"])=="api-test-one" && AttendanceIntegration.Unprotect((byte[])rows.Rows[0]["BioPassword"])=="bio-test-one","blank password edits preserve both secrets");
  Denied(()=>store.Save(1,1,"brand-one-api","","bio-one","",true,v),51702,"optimistic concurrency rejects stale edit");
  store.Save(1,1,"brand-one-api","rotated-api","bio-one","rotated-bio",true,Version(store,1));
  Check(store.Authenticate("brand-one-api","api-test-one")==0 && store.Authenticate("brand-one-api","rotated-api")==1,"API password rotation invalidates previous password");
  store.Save(1,1,"brand-one-api","","bio-one","",false,Version(store,1));
  Check(store.Authenticate("brand-one-api","rotated-api")==0,"disabled integration denies API credentials");
  Check(store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",10),new SqlParameter("@EmployeeID",10)).Rows.Count==0,"disabled integration withholds portal credentials");
  store.Save(1,1,"brand-one-api","","bio-one","",true,Version(store,1));
  rows=store.Query("dbo.AttendanceIntegration_Employee",new SqlParameter("@Actor",10),new SqlParameter("@EmployeeID",20)); Check(rows.Rows.Count==0,"employee cannot query colleague records");
  rows=store.Query("dbo.AttendanceIntegration_Employee",new SqlParameter("@Actor",1),new SqlParameter("@EmployeeCode","26"),new SqlParameter("@BrandID",2));Check(rows.Rows.Count==1 && (int)rows.Rows[0]["ID"]==20,"admin selects duplicate employee number by brand");
  rows=store.Query("dbo.AttendanceIntegration_ApiEmployee",new SqlParameter("@BrandID",1),new SqlParameter("@EmployeeCode","99"));Check(rows.Rows.Count==0,"API brand cannot query foreign employee");
  rows=store.Query("dbo.AttendanceIntegration_ApiEmployee",new SqlParameter("@BrandID",2),new SqlParameter("@EmployeeCode","99"));Check(rows.Rows.Count==1,"API own-brand employee accepted");
  Denied(()=>store.Query("dbo.AttendanceIntegration_Employee",new SqlParameter("@Actor",30)),51700,"inactive actor rejected");
  Denied(()=>store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",40),new SqlParameter("@EmployeeID",40)),51700,"retired customer employee rejected");
  store.Save(1,1,"brand-one-api","colon:password","bio-one","",true,Version(store,1));
  var configuration = new System.Web.Http.HttpConfiguration();
  var request = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post,"http://localhost/api/attendance/transactions");
  request.SetConfiguration(configuration);
  request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic",Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes("brand-one-api:colon:password")));
  var context=new System.Web.Http.Controllers.HttpActionContext { ControllerContext = new System.Web.Http.Controllers.HttpControllerContext { Request=request,Configuration=configuration } };
  new Prosto_ERP_API.Controllers.AttendanceAuthenticationAttribute(store).OnAuthorization(context);
  Check(context.Response==null && (int)request.Properties["AttendanceBrandID"]==1,"authentication filter scopes brand and accepts colon in password");
  var upstream=new Upstream();
  var controller=new Prosto_ERP_API.Controllers.AttendanceController(new Prosto_ERP_API.Attendance.BioTimeAttendanceService(new System.Net.Http.HttpClient(upstream)),store) { Request=request,Configuration=configuration };
  var model=new Prosto_ERP_API.Attendance.AttendanceTransactionsRequest { Username="bio-one",Password="dummy",EmployeeCode="99",FromDate="2026-10-01",ToDate="2026-10-07" };
  var response=controller.Transactions(model,System.Threading.CancellationToken.None).GetAwaiter().GetResult();
  Check(response.StatusCode==System.Net.HttpStatusCode.Forbidden && upstream.Calls==0,"controller rejects foreign employee before BioTime call");
  model=new Prosto_ERP_API.Attendance.AttendanceTransactionsRequest { Username="bio-one",Password="dummy",EmployeeCode="26",FromDate="2026-10-01",ToDate="2026-10-07" };
  response=controller.Transactions(model,System.Threading.CancellationToken.None).GetAwaiter().GetResult();
  Check(response.StatusCode==System.Net.HttpStatusCode.OK && upstream.Calls==2,"controller integrates own-brand employee with BioTime service");
  Check(upstream.CustomOrigin,"authentication and transactions use saved brand BioTime origin");
  request.Headers.Authorization=new System.Net.Http.Headers.AuthenticationHeaderValue("Basic",Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes("brand-one-api:wrong")));
  new Prosto_ERP_API.Controllers.AttendanceAuthenticationAttribute(store).OnAuthorization(context);
  Check(context.Response.StatusCode==System.Net.HttpStatusCode.Unauthorized,"filter rejects incorrect brand password");
  context.Response=null;
  new Prosto_ERP_API.Controllers.AttendanceAuthenticationAttribute(new AttendanceIntegration("")).OnAuthorization(context);
  Check(context.Response.StatusCode==System.Net.HttpStatusCode.InternalServerError && !context.Response.Content.ReadAsStringAsync().Result.Contains("wrong"),"unexpected authentication infrastructure error sanitized");
  store.Save(1,1,"brand-one-api","","bio-one","",true,Version(store,1),"https://attendance.example/erp/","https://biotime.example:8443/","https://hr.example/api/","hr-user","hr-secret");
  meta=store.Metadata(1,1);
  Check((string)meta.Rows[0]["ApiUrl"]=="https://attendance.example/erp/" && store.BioTimeUrl(1)=="https://biotime.example:8443/","saved independent attendance and BioTime URLs");
  Check(!meta.Columns.Contains("HrPassword") && AttendanceIntegration.Unprotect((byte[])meta.Rows[0]["HrUsername"])=="hr-user" && (bool)meta.Rows[0]["HasHrPassword"],"HR metadata hides password and encrypts username");
  var adminSecrets=store.Query("dbo.AttendanceIntegration_AdminSecrets",new SqlParameter("@Actor",1),new SqlParameter("@BrandID",1));
  Check(AttendanceIntegration.Unprotect((byte[])adminSecrets.Rows[0]["HrPassword"])=="hr-secret" && AttendanceIntegration.Unprotect((byte[])adminSecrets.Rows[0]["ApiPassword"])=="colon:password","admin can decrypt saved ERP and HR passwords");
  Denied(()=>store.Query("dbo.AttendanceIntegration_AdminSecrets",new SqlParameter("@Actor",10),new SqlParameter("@BrandID",1)),51700,"employee cannot reveal saved passwords");
  Denied(()=>store.Query("dbo.AttendanceIntegration_AdminSecrets",new SqlParameter("@Actor",30),new SqlParameter("@BrandID",1)),51700,"inactive actor cannot reveal saved passwords");
  store.Save(1,1,"brand-one-api","","bio-one","",true,Version(store,1),null,null,"https://hr.example/api/","hr-user","");
  var secret=store.Query("dbo.AttendanceIntegration_Admin",new SqlParameter("@Actor",1),new SqlParameter("@BrandID",1));
  Check((bool)secret.Rows[0]["HasHrPassword"] && (string)secret.Rows[0]["ApiUrl"]=="https://attendance.example/erp/","blank edits preserve HR password and URLs");
  rows=store.Query("dbo.AttendanceIntegration_Credentials",new SqlParameter("@Actor",1),new SqlParameter("@EmployeeID",10));
  Check(!rows.Columns.Contains("HrPassword") && !rows.Columns.Contains("HrUsername") && (string)rows.Rows[0]["ApiUrl"]=="https://attendance.example/erp/","attendance credentials expose selected URL but exclude HR secrets");
  Check(store.BioTimeUrl(2)=="http://127.0.0.1:8089/","other brand URL remains independent");
  foreach(var bad in new[]{"ftp://host/","https://user:pass@host/","https://host/?secret=x","https://host/#fragment"})
  { try { AttendanceIntegration.NormalizeUrl(bad,false); throw new Exception("URL accepted"); } catch(ArgumentException) { Check(true,"unsafe settings URL rejected"); } }
  try { AttendanceIntegration.NormalizeUrl("https://host/path/",true); throw new Exception("BioTime path accepted"); } catch(ArgumentException) { Check(true,"BioTime URL requires server root"); }
  try { store.Save(1,2,"brand-two-api","","bio-two","",true,Version(store,2),null,null,"https://hr.example/","hr-user",""); throw new Exception("missing HR secret accepted"); } catch(ArgumentException) { Check(true,"first HR configuration requires password"); }
  store.Save(1,1,"brand-one-api","","bio-one","",true,Version(store,1),null,null,"","","");
  meta=store.Metadata(1,1); Check(!(bool)meta.Rows[0]["HasHrPassword"] && meta.Rows[0].IsNull("HrUsername"),"clearing optional HR configuration clears secrets");
  Console.WriteLine("Brand SQL assertions: "+count);
 }
}
