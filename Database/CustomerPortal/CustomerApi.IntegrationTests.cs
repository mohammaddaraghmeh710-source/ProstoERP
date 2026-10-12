using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;
class CustomerApiTests
{
 static HttpClient client;static int checks;const string root="api/v1/customer/",password="Customer-Api-Test!2026";
 static byte[] pdf=Encoding.ASCII.GetBytes("%PDF-1.4\n1 0 obj<</Type /Catalog>>endobj\n%%EOF");
 static void Check(bool value,string name){if(!value)throw new Exception("FAIL: "+name);Console.WriteLine("PASS: "+name);checks++;}
 static object Sql(string text,params SqlParameter[] args){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand(text,cn)){cn.Open();cmd.Parameters.AddRange(args);return cmd.ExecuteScalar();}}
 static async Task<HttpResponseMessage> Send(string path,string token=null,object body=null,bool post=false){var request=new HttpRequestMessage(post?HttpMethod.Post:HttpMethod.Get,path);request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));if(token!=null)request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);if(body!=null)request.Content=new StringContent(JsonConvert.SerializeObject(body),Encoding.UTF8,"application/json");return await client.SendAsync(request);}
 static async Task<JToken> Data(HttpResponseMessage response){string json=await response.Content.ReadAsStringAsync();if(!response.IsSuccessStatusCode)throw new Exception("HTTP "+response.StatusCode+": "+json);return JObject.Parse(json)["Data"];}
 static async Task<string> Login(string user="customer"){return (string)(await Data(await Send(root+"login",body:new{Username=user,Password=password},post:true)))["Token"];}
 static async Task<HttpResponseMessage> Upload(string token,JObject model,byte[] file=null){using(var form=new MultipartFormDataContent()){form.Add(new StringContent(model.ToString(),Encoding.UTF8,"application/json"),"data");if(file!=null)form.Add(new ByteArrayContent(file),"files","note.pdf");var req=new HttpRequestMessage(HttpMethod.Post,root+"feedback/requests"){Content=form};req.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));return await client.SendAsync(req);}}
 static async Task Run(){
  byte[] salt=new byte[32];using(var random=RandomNumberGenerator.Create())random.GetBytes(salt);
  using(var derive=new Rfc2898DeriveBytes(password,salt,210000,HashAlgorithmName.SHA256))Sql("UPDATE Customer_Logins SET PasswordHash=@Hash,Salt=@Salt,Iterations=210000,LockedUntil=NULL,FailedAttempts=0",new SqlParameter("@Hash",derive.GetBytes(32)),new SqlParameter("@Salt",salt));
  string portal=ConfigurationManager.AppSettings["CustomerApi.PortalRoot"];Directory.CreateDirectory(Path.Combine(portal,"App_Data"));File.WriteAllBytes(Path.Combine(portal,"App_Data/customer-test.pdf"),pdf);
  var config=new HttpConfiguration();WebApiConfig.Register(config);config.Services.Replace(typeof(System.Web.Http.Dispatcher.IAssembliesResolver),new Assemblies());config.EnsureInitialized();client=new HttpClient(new HttpServer(config)){BaseAddress=new Uri("https://localhost/")};
  var unauth=await Send(root+"me");Check(unauth.StatusCode==HttpStatusCode.Unauthorized,"Customer bearer required: "+await unauth.Content.ReadAsStringAsync());
  Check((await Send("http://localhost/"+root+"login",body:new{Username="customer",Password=password},post:true)).StatusCode==HttpStatusCode.Forbidden,"HTTPS required before credentials");
  Check((await Send(root+"login",body:new{Username="customer",Password="wrong"},post:true)).StatusCode==HttpStatusCode.Unauthorized,"Wrong password denied");
  string first=await Login(),second=await Login("customer2");
  Check((await Send("api/Get_News",first)).StatusCode==HttpStatusCode.Unauthorized,"Customer token cannot authenticate as employee");
  byte[] employeeBytes=new byte[32];using(var random=RandomNumberGenerator.Create())random.GetBytes(employeeBytes);
  string employee=Convert.ToBase64String(employeeBytes).TrimEnd('=').Replace('+','-').Replace('/','_');
  using(var sha=SHA256.Create()) Sql("UPDATE UsersMembers SET Password=N'test' WHERE ID=2;INSERT MobileApi_Devices(UserID,DeviceID,DevicePlatform,DeviceModel,OSVersion,AppVersion,IsApproved) VALUES(2,'test-device','Android','Test','14','1',1);INSERT MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc,DeviceRegistrationID) SELECT @Hash,2,HASHBYTES('SHA2_256',CONVERT(varbinary(max),Password)),SYSUTCDATETIME(),SYSUTCDATETIME(),DATEADD(hour,1,SYSUTCDATETIME()),DATEADD(day,1,SYSUTCDATETIME()),(SELECT MAX(ID) FROM MobileApi_Devices) FROM UsersMembers WHERE ID=2;",new SqlParameter("@Hash",sha.ComputeHash(employeeBytes)));
  Check((await Send(root+"me",employee)).StatusCode==HttpStatusCode.Unauthorized,"Employee token cannot authenticate as customer");
  Check((int)(await Data(await Send(root+"me",first)))["AccountID"]==1,"Customer identity from token");
  Check((await Send(root+"me",first)).Headers.CacheControl.NoStore,"Private responses no-store");
  Check((await Data(await Send(root+"guide/brands",first))).Count()==2,"Multi-brand guide options");
  Check((int)(await Data(await Send(root+"guide/documents?brandID=1",first)))["Total"]==1,"Authorized document listing");
  Check((await Send(root+"guide/documents?brandID=1&pageSize=101",first)).StatusCode==HttpStatusCode.BadRequest,"Pagination bounds");
  var doc=await Data(await Send(root+"guide/documents/1",first));Check(doc["File_Path"]==null && doc["FileUrl"]!=null,"No physical file paths in metadata");
  Check((await Send(root+"guide/documents/1/file",first)).Content.Headers.ContentType.MediaType=="application/pdf","Authorized PDF stream");
  Check((await Send(root+"guide/documents/1/file?download=true",first)).StatusCode==HttpStatusCode.Forbidden,"View-only download denied");
  Check((await Send(root+"guide/documents/1",second)).StatusCode==HttpStatusCode.NotFound,"Other customer guide denied");
  Sql("UPDATE Customer_Guide_Grants SET IsActive=0 WHERE AccountID=1 AND Brand_ID=2");
  var options=await Data(await Send(root+"guide/access-request-options?brandID=2",first));Check(options.Any(x=>(int)x["ID"]==3 && (bool)x["Can_Request"]),"Unavailable guide categories requestable");
  var access=JObject.FromObject(new{OperationID=Guid.NewGuid(),BrandID=2,CategoryIDs=new[]{3},Reason="API access request"});
  Guid batch=(Guid)(await Data(await Send(root+"guide/access-requests",first,access,true)))["BatchID"];
  Check((bool)(await Data(await Send(root+"guide/access-requests",first,access,true)))["Replayed"],"Guide request retry deduplicated");
  access["Reason"]="different";Check((await Send(root+"guide/access-requests",first,access,true)).StatusCode==HttpStatusCode.Conflict,"Guide operation binds payload");
  Check((int)(await Data(await Send(root+"guide/access-requests",first)))["Total"]==1,"Owned pending guide history");
  Sql("DECLARE @ID int=(SELECT ID FROM Work_Guide_Access_Requests WHERE Batch_ID=@Batch);DECLARE @D xml=CONVERT(xml,CONCAT('<items><item id=\"',@ID,'\" status=\"A\" role=\"1\" note=\"approved\"/></items>'));EXEC Review_Work_Guide_Access_Request 1,@Batch,@D;",new SqlParameter("@Batch",batch));
  Check((int)(await Data(await Send(root+"guide/documents?brandID=2",first)))["Total"]==1,"Existing admin review grants API access");
  Check((await Send(root+"guide/documents/2/file?download=true",first)).StatusCode==HttpStatusCode.Forbidden,"Document download restriction retained");
  var feedback=JObject.FromObject(new{OperationID=Guid.NewGuid(),TypeID=2,TopicID=2,BrandID=1,BranchID=1,Mobile="0790000000",Title="API suggestion",Details="Original suggestion details"});
  Check((await Data(await Send(root+"feedback/options?brandID=1&typeID=2",first)))["Topics"].Count()==1,"Feedback options use existing catalogs");
  int id=(int)(await Data(await Upload(first,feedback,pdf)))["RequestID"];
  Check((bool)(await Data(await Upload(first,feedback,pdf)))["Replayed"],"Feedback and attachment retry deduplicated");
  var detail=await Data(await Send(root+"feedback/requests/"+id,first));int attachment=(int)detail["Attachments"][0]["ID"];
  Check((string)detail["Request"]["Details"]=="Original suggestion details" && detail["Workflow"]==null,"Own original feedback details exposed");
  Check((await Send(root+"feedback/requests/"+id,second)).StatusCode==HttpStatusCode.NotFound,"Other customer complaint details denied");
  Check((await Send(root+"feedback/attachments/"+attachment,second)).StatusCode==HttpStatusCode.NotFound,"Other customer attachment denied");
  Check((await Send(root+"feedback/attachments/"+attachment,first)).StatusCode==HttpStatusCode.OK,"Own initial attachment downloaded");
  Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Customer_Portal_Activity WHERE AccountID=1 AND FeedbackTypeTitle=N'اقتراح'"))==1,"Activity snapshots suggestion type");
  Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Employee_Feedback_Notifications WHERE Request_ID=@ID",new SqlParameter("@ID",id)))>0,"Shared admin notifications created");
  feedback["Title"]="Changed";Check((await Upload(first,feedback,pdf)).StatusCode==HttpStatusCode.Conflict,"Feedback operation binds content");
  feedback["OperationID"]=Guid.NewGuid();Check((await Upload(first,feedback,Encoding.ASCII.GetBytes("bad"))).StatusCode==HttpStatusCode.BadRequest,"Invalid attachment rejected");
  Sql("UPDATE Customer_Logins SET SecurityStamp=NEWID() WHERE AccountID=1");Check((await Send(root+"me",first)).StatusCode==HttpStatusCode.Unauthorized,"Credential stamp change revokes token");
  first=await Login();Sql("UPDATE CRM_Accounts SET Is_Active=0 WHERE ID=1");Check((await Send(root+"me",first)).StatusCode==HttpStatusCode.Unauthorized,"CRM deactivation revokes access immediately");Sql("UPDATE CRM_Accounts SET Is_Active=1 WHERE ID=1");
  first=await Login();await Data(await Send(root+"logout",first,post:true));Check((await Send(root+"me",first)).StatusCode==HttpStatusCode.Unauthorized,"Logout revokes bearer");
  first=await Login();Sql("UPDATE CustomerApi_Sessions SET LastUsedUtc=DATEADD(hour,-9,SYSUTCDATETIME())");Check((await Send(root+"me",first)).StatusCode==HttpStatusCode.Unauthorized,"Idle expiry enforced");
  Sql("UPDATE CustomerApi_LoginRate SET Attempts=30");Check((await Send(root+"login",body:new{Username="customer",Password=password},post:true)).StatusCode==(HttpStatusCode)429,"Login address rate limit enforced");
  Console.WriteLine(checks+" API integration checks passed.");
 }
 sealed class Assemblies:System.Web.Http.Dispatcher.DefaultAssembliesResolver {public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}}
 static int Main(){try{Run().GetAwaiter().GetResult();return 0;}catch(Exception ex){Console.Error.WriteLine(ex);return 1;}}
}
