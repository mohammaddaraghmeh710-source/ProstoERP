using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;

class CircularTests
{
 static int checks;static HttpClient client;static string token,otherToken;static string password="Circular-test-"+Guid.NewGuid().ToString("N");
 static void Check(bool value,string name){if(!value)throw new Exception("FAIL: "+name);Console.WriteLine("PASS: "+name);checks++;}
 static DataSet Query(string sql,bool proc=false,params SqlParameter[] args){
  using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))
  using(var cmd=new SqlCommand(sql,cn))using(var adapter=new SqlDataAdapter(cmd)){cmd.CommandType=proc?CommandType.StoredProcedure:CommandType.Text;cmd.Parameters.AddRange(args);var ds=new DataSet();adapter.Fill(ds);return ds;}
 }
 static SqlParameter P(string key,object value){return new SqlParameter("@"+key,value??DBNull.Value);}
 static int Number(string sql){return Convert.ToInt32(Query(sql).Tables[0].Rows[0][0]);}
 static byte[] Pdf(){
  var s=new StringBuilder("%PDF-1.4\n");var offsets=new List<int>{0};
  var objects=new[]{"<< /Type /Catalog /Pages 2 0 R >>","<< /Type /Pages /Kids [3 0 R] /Count 1 >>","<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>","<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"};
  string content="BT /F1 20 Tf 50 760 Td (Circular - test document) Tj 0 -40 Td /F1 12 Tf (Abdullah Ghosheh branch - preview fixture) Tj ET";
  foreach(string obj in objects.Concat(new[]{"<< /Length "+content.Length+" >>\nstream\n"+content+"\nendstream"})){offsets.Add(s.Length);s.Append(offsets.Count-1).Append(" 0 obj\n").Append(obj).Append("\nendobj\n");}
  int start=s.Length;s.Append("xref\n0 6\n0000000000 65535 f \n");foreach(int offset in offsets.Skip(1))s.Append(offset.ToString("D10")).Append(" 00000 n \n");
  s.Append("trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n").Append(start).Append("\n%%EOF");return Encoding.ASCII.GetBytes(s.ToString());
 }
 static int Save(string title,string audience="all",string targets="<targets/>",bool download=false,int id=0,int version=0,int actor=1,DateTime? start=null,DateTime? end=null,bool enabled=true,byte[] file=null){
  return Convert.ToInt32(Query("dbo.Circular_Save",true,P("Actor",actor),P("ID",id),P("ExpectedVersion",version),P("Title",title),P("Summary","تعميم تجريبي لفرع عبدالله غوشة"),
   P("CircularDate",DateTime.Today),P("StartUtc",start??DateTime.UtcNow.AddHours(-1)),P("EndUtc",end??DateTime.UtcNow.AddDays(3)),P("IsEnabled",enabled),P("AllowDownload",download),P("Audience",audience),
   new SqlParameter("@Targets",SqlDbType.Xml){Value=targets},P("FileName","test-circular.pdf"),P("FileBytes",file??Pdf())).Tables[0].Rows[0]["ID"]);
 }
 static async Task<HttpResponseMessage> Send(string path,string bearer=null,object body=null){
  var req=new HttpRequestMessage(body==null?HttpMethod.Get:HttpMethod.Post,path);
  if(bearer!=null)req.Headers.Authorization=new AuthenticationHeaderValue("Bearer",bearer);
  if(body!=null)req.Content=new StringContent(Newtonsoft.Json.JsonConvert.SerializeObject(body),Encoding.UTF8,"application/json");
  return await client.SendAsync(req);
 }
 static async Task<JObject> Json(HttpResponseMessage response){return JObject.Parse(await response.Content.ReadAsStringAsync());}
 static async Task<string> Login(string user){
  var response=await Send("api/Users/Login",body:new{Username=user,Password=password,AppVersion="1.2.0",Device=new{DeviceID="circular-"+user,Platform="Android",Model="Test phone",OSVersion="14"}});
  Check(response.StatusCode==HttpStatusCode.OK,"mobile login "+user);return (string)(await Json(response))["Data"]["AccessToken"];
 }
 static object Event(string action="view",Guid? id=null,int employee=901002){return new{EmployeeNumber=employee,Action=action,EventID=id??Guid.NewGuid(),OccurredAt=DateTimeOffset.UtcNow};}
 static async Task<JObject> List(string suffix=""){return await Json(await Send("api/v1/circulars?employeeNumber=901002"+suffix,token));}
 static bool SqlError(Action act,int code){try{act();return false;}catch(SqlException e){return e.Number==code;}}
 static async Task Run(){
  Query(@"SET IDENTITY_INSERT Users_Types ON; INSERT Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'مدير النظام',N'Admin',1,0),(4,N'موظف',N'Employee',1,0); SET IDENTITY_INSERT Users_Types OFF;
SET IDENTITY_INSERT Brands ON; INSERT Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(29,N'علامة تجريبية',N'Test',1,0),(30,N'علامة أخرى',N'Other',1,0);SET IDENTITY_INSERT Brands OFF;
SET IDENTITY_INSERT Branches ON;INSERT Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(25,29,N'عبدالله غوشة',N'Abdullah Ghosheh',1,0),(26,30,N'فرع اختبار آخر',N'Other',1,0);SET IDENTITY_INSERT Branches OFF;
SET IDENTITY_INSERT Departments ON;INSERT Departments(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(11,N'قسم تجريبي',N'Test',1,0),(12,N'قسم آخر',N'Other',1,0);SET IDENTITY_INSERT Departments OFF;
SET IDENTITY_INSERT Shift ON;INSERT Shift(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'الوردية الأولى',N'First',1,0),(2,N'الوردية الثانية',N'Second',1,0);SET IDENTITY_INSERT Shift OFF;
SET IDENTITY_INSERT UsersMembers ON;
INSERT UsersMembers(ID,Type,Employee_Number,UserName,Password,FullName_Ar,IsActive,IsDeleted,Brand_ID,Branch_ID,Department_ID,Shif_ID)
VALUES(1,1,901001,N'circular_admin',@pw,N'مدير تجريبي',1,0,29,25,11,1),(2,4,901002,N'circular_employee',@pw,N'موظف تجريبي',1,0,29,25,11,1),(3,4,901003,N'circular_other',@pw,N'موظف فرع آخر',1,0,30,26,12,2);SET IDENTITY_INSERT UsersMembers OFF;",false,P("pw",new Echo.Encrptor.TripleDesEncryptor().Encrypt(password)));
  var config=new HttpConfiguration();WebApiConfig.Register(config);config.Services.Replace(typeof(System.Web.Http.Dispatcher.IAssembliesResolver),new Assemblies());config.EnsureInitialized();
  client=new HttpClient(new HttpServer(config)){BaseAddress=new Uri("https://localhost/")};token=await Login("circular_employee");otherToken=await Login("circular_other");
  int all=Save("تعميم لجميع الموظفين"),download=Save("تعميم يمكن تنزيله",download:true),roles=Save("تعميم موظفين","roles","<targets><item kind='role' id='4'/></targets>"),
  org=Save("تعميم وردية عبدالله غوشة","organization","<targets><item kind='brand' id='29'/><item kind='branch' id='25'/><item kind='department' id='11'/><item kind='shift' id='1'/></targets>"),
  hidden=Save("تعميم لعلامة أخرى","organization","<targets><item kind='brand' id='30'/></targets>"),
  admin=Save("للمدراء","roles","<targets><item kind='role' id='1'/></targets>"),
  future=Save("لاحق",start:DateTime.UtcNow.AddDays(1)),expired=Save("منته",start:DateTime.UtcNow.AddDays(-3),end:DateTime.UtcNow.AddDays(-1)),disabled=Save("معطل",enabled:false);
  Check((await Send("api/v1/circulars?employeeNumber=901002")).StatusCode==HttpStatusCode.Unauthorized,"anonymous list denied");
  Check((await Send("http://localhost/api/v1/circulars?employeeNumber=901002",token)).StatusCode==HttpStatusCode.Forbidden,"HTTPS required");
  Check((await Send("api/v1/circulars?employeeNumber=901003",token)).StatusCode==HttpStatusCode.Forbidden,"employee number cannot impersonate another employee");
  var list=await List();Check((int)list["Data"]["TotalItems"]==4,"list includes only active matching all/role/organization circulars");
  Check((int)list["Data"]["Counts"]["Unread"]==4,"initial circulars are unread");
  Check(list["Data"]["Items"].All(i=>i["FileBytes"]==null),"list never exposes PDF bytes");
  Check((await List("&pageSize=1"))["Data"]["Items"].Count()==1,"server pagination");
  Check((int)(await List("&search=وردية"))["Data"]["TotalItems"]==1,"search title and summary");
  Check((await Send("api/v1/circulars?employeeNumber=901002&pageSize=101",token)).StatusCode==HttpStatusCode.BadRequest,"invalid paging rejected");
  foreach(int denied in new[]{hidden,admin,future,expired,disabled,9999}){
   Check((await Send("api/v1/circulars/"+denied+"?employeeNumber=901002",token)).StatusCode==HttpStatusCode.NotFound,"unavailable metadata concealed "+denied);
   Check((await Send("api/v1/circulars/"+denied+"/file",token,Event())).StatusCode==HttpStatusCode.NotFound,"unavailable PDF concealed "+denied);
  }
  Check((await Send("api/v1/circulars/"+org+"/file",otherToken,Event(employee:901003))).StatusCode==HttpStatusCode.NotFound,"other branch cannot fetch targeted PDF");
  var details=await Json(await Send("api/v1/circulars/"+all+"?employeeNumber=901002",token));
  Check(!(bool)details["Data"]["IsRead"]&&Number("SELECT COUNT(*) FROM Circular_Reads")==0,"opening metadata does not mark read");
  Check((await Send("api/v1/circulars/"+all+"/file",token,Event("download"))).StatusCode==HttpStatusCode.Forbidden,"download flag enforced by API");
  Check(Number("SELECT COUNT(*) FROM Circular_Logs WHERE Action IN('view','download')")==0,"denied requests write no access logs");
  var id=Guid.NewGuid();var file=await Send("api/v1/circulars/"+all+"/file",token,Event(id:id));
  Check(file.StatusCode==HttpStatusCode.OK && file.Content.Headers.ContentType.MediaType=="application/pdf" && (await file.Content.ReadAsByteArrayAsync()).SequenceEqual(Pdf()),"view returns exact PDF binary");
  Check(file.Headers.CacheControl.NoStore && file.Content.Headers.ContentDisposition.DispositionType=="inline","view no-store and inline headers");
  Check((bool)(await Json(await Send("api/v1/circulars/"+all+"?employeeNumber=901002",token)))["Data"]["IsRead"],"view marks current version read");
  Check(Number("SELECT COUNT(*) FROM Circular_Logs WHERE Action='view' AND DeviceID=N'circular-circular_employee' AND AppVersion=N'1.2.0' AND EmployeeNumber=901002")==1,"logs identity and device metadata come from server session");
  await Send("api/v1/circulars/"+all+"/file",token,Event(id:id));
  Check(Number("SELECT COUNT(*) FROM Circular_Logs WHERE Action='view'")==1,"retry EventID deduplicates log");
  Check((await Send("api/v1/circulars/"+download+"/file",token,Event(id:id))).StatusCode==HttpStatusCode.Conflict,"EventID cannot be reused for a different circular");
  file=await Send("api/v1/circulars/"+download+"/file",token,Event("download"));
  Check(file.StatusCode==HttpStatusCode.OK&&file.Content.Headers.ContentDisposition.DispositionType=="attachment","allowed download returns PDF attachment");
  Check((int)(await List("&unreadOnly=true"))["Data"]["TotalItems"]==2,"download also marks read and unread filter updates");
  Guid concurrent=Guid.NewGuid();var races=await Task.WhenAll(Send("api/v1/circulars/"+roles+"/file",token,Event(id:concurrent)),Send("api/v1/circulars/"+roles+"/file",token,Event(id:concurrent)));
  Check(races.All(r=>r.StatusCode==HttpStatusCode.OK)&&Number("SELECT COUNT(*) FROM Circular_Logs WHERE CircularID="+roles+" AND Action='view'")==1,"concurrent retries produce one log");
  Check(SqlError(()=>Save("not allowed",actor:2),51801),"non-admin cannot create");
  Check(SqlError(()=>Query("dbo.Circular_LogsPage",true,P("Actor",2),P("ID",all)),51801),"non-admin cannot inspect general logs");
  Check(SqlError(()=>Save("bad PDF",file:Encoding.ASCII.GetBytes("not PDF!")),51800),"invalid file rejected at database boundary");
  Check(SqlError(()=>Save("bad dates",end:DateTime.UtcNow.AddDays(-1)),51800),"end must follow start");
  Check(SqlError(()=>Save("empty audience","roles"),51800),"empty restricted audience rejected");
  Check(SqlError(()=>Save("unknown target","roles","<targets><item kind='role' id='999'/></targets>"),51800),"unknown targets rejected");
  Check(SqlError(()=>Save("mismatch","organization","<targets><item kind='brand' id='30'/><item kind='branch' id='25'/></targets>"),51800),"branch must belong to selected brand");
  Save("تعميم محدث",id:all,version:1);
  Check(!(bool)(await Json(await Send("api/v1/circulars/"+all+"?employeeNumber=901002",token)))["Data"]["IsRead"],"new version resets read status");
  Check(Number("SELECT COUNT(*) FROM Circular_Reads WHERE CircularID="+all+" AND Version=1")==1,"old read history retained");
  Check(SqlError(()=>Save("stale",id:all,version:1),51809),"concurrent edit version protected");
  Query("UPDATE UsersMembers SET Shif_ID=2 WHERE ID=2");
  Check((await Send("api/v1/circulars/"+org+"/file",token,Event())).StatusCode==HttpStatusCode.NotFound,"shift changes take effect on file access");
  Query("UPDATE UsersMembers SET Shif_ID=1 WHERE ID=2;UPDATE Circulars SET EndUtc=DATEADD(second,-1,SYSUTCDATETIME()),StartUtc=DATEADD(day,-1,SYSUTCDATETIME()) WHERE ID="+roles);
  Check((await Send("api/v1/circulars/"+roles+"/file",token,Event())).StatusCode==HttpStatusCode.NotFound,"expiry enforced after list was loaded");
  Query("UPDATE Circulars SET IsEnabled=0 WHERE ID="+download);
  Check((await Send("api/v1/circulars/"+download+"/file",token,Event("download"))).StatusCode==HttpStatusCode.NotFound,"disabled circular cannot download from old link");
  Query("dbo.Circular_File",true,P("Actor",1),P("ID",future),P("Action","view"),P("Source","Portal"),P("EventID",Guid.NewGuid()),P("Admin",true));
  Check(Number("SELECT COUNT(*) FROM Circular_Logs WHERE CircularID="+future+" AND Action='preview'")==1 && Number("SELECT COUNT(*) FROM Circular_Reads WHERE UserID=1")==0,"admin previews scheduled circular without employee read");
  Check((await Send("api/v1/circulars/"+all+"/file",token,new{EmployeeNumber=901002,Action="view",EventID=Guid.Empty})).StatusCode==HttpStatusCode.BadRequest,"missing event ID rejected");
  Check((await Send("api/v1/circulars/"+all+"/file",token,new{EmployeeNumber=901002,Action="view",EventID=Guid.NewGuid(),OccurredAt=DateTimeOffset.UtcNow.AddDays(1)})).StatusCode==HttpStatusCode.BadRequest,"invalid client event time rejected");
  Query("UPDATE MobileApi_Devices SET IsApproved=0 WHERE UserID=2");
  Check((await Send("api/v1/circulars?employeeNumber=901002",token)).StatusCode==HttpStatusCode.Unauthorized,"device revocation applies to circular API");
  Query("UPDATE MobileApi_Devices SET IsApproved=1 WHERE UserID=2");
  Console.WriteLine("CIRCULAR CHECKS PASSED: "+checks);
 }
 static int Main(){try{Run().GetAwaiter().GetResult();return 0;}catch(Exception e){Console.WriteLine(e);return 1;}}
 class Assemblies:System.Web.Http.Dispatcher.DefaultAssembliesResolver{public override ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}}
}
