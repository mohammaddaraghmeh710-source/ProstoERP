using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;

class CorrespondenceApiTests
{
    static HttpClient client;static int checks;
    static string password="Correspondence-test-"+Guid.NewGuid().ToString("N");
    static byte[] pdf=Encoding.ASCII.GetBytes("%PDF-1.4\n1 0 obj<</Type /Catalog>>endobj\n%%EOF");
    const string root="api/v1/correspondence/";
    static void Check(bool value,string name){if(!value)throw new Exception("FAIL: "+name);Console.WriteLine("PASS: "+name);checks++;}
    static object Sql(string sql,params SqlParameter[] parameters){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand(sql,cn)){cn.Open();cmd.Parameters.AddRange(parameters);return cmd.ExecuteScalar();}}
    static int Count(string table){return Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo."+table));}
    static async Task<HttpResponseMessage> Send(string path,string token=null,object body=null,bool post=false){var request=new HttpRequestMessage(post?HttpMethod.Post:HttpMethod.Get,path);request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));if(token!=null)request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);if(body!=null)request.Content=new StringContent(JsonConvert.SerializeObject(body),Encoding.UTF8,"application/json");return await client.SendAsync(request);}
    static async Task<JToken> Data(HttpResponseMessage response){string json=await response.Content.ReadAsStringAsync();if(!response.IsSuccessStatusCode)throw new Exception("HTTP "+response.StatusCode+": "+json);return JObject.Parse(json)["Data"];}
    static async Task<string> Login(int number){return (string)(await Data(await Send("api/Users/Login",body:new{Username="cm_"+number,Password=password,AppVersion="1.0.0",Device=new{DeviceID="cm-test-"+number,Platform="Android",Model="Test device",OSVersion="14"}},post:true)))["AccessToken"];}
    static JObject Event(int number){return JObject.FromObject(new{EmployeeNumber=number,OperationID=Guid.NewGuid(),OccurredAt=DateTimeOffset.UtcNow.AddMinutes(-1).ToString("o")});}
    static JObject Create(int number,int recipient,bool task=false){var data=Event(number);data["Title"]="API correspondence";data["Body"]="First message";data["PriorityID"]=2;data["RecipientIDs"]=new JArray(recipient);data["RequiresCompletion"]=task;return data;}
    static async Task<HttpResponseMessage> Upload(string path,string token,JObject data,byte[] bytes=null,string name="note.pdf",int copies=1){using(var form=new MultipartFormDataContent()){form.Add(new StringContent(data.ToString(),Encoding.UTF8,"application/json"),"data");for(int i=0;bytes!=null&&i<copies;i++)form.Add(new ByteArrayContent(bytes),"files",name);var request=new HttpRequestMessage(HttpMethod.Post,path){Content=form};request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));return await client.SendAsync(request);}}
    static async Task Run()
    {
        Sql(@"SET IDENTITY_INSERT dbo.UsersMembers ON;
INSERT dbo.UsersMembers(ID,Type,Employee_Number,UserName,Password,FullName_Ar,Fullname_En,IsActive,IsDeleted,Brand_ID,Branch_ID,Shif_ID)
SELECT ID,Role,Number,CONCAT('cm_',Number),@Password,CONCAT(N'Test ',Number),CONCAT(N'Test ',Number),1,0,29,Branch,1
FROM (VALUES(1,1,82001,25),(2,2,82002,25),(3,2,82003,26),(4,4,82004,25),(5,4,82005,25))v(ID,Role,Number,Branch);
SET IDENTITY_INSERT dbo.UsersMembers OFF;",new SqlParameter("@Password",new Echo.Encrptor.TripleDesEncryptor().Encrypt(password)));
        var config=new HttpConfiguration();WebApiConfig.Register(config);config.Services.Replace(typeof(System.Web.Http.Dispatcher.IAssembliesResolver),new Assemblies());config.EnsureInitialized();
        client=new HttpClient(new HttpServer(config)){BaseAddress=new Uri("https://localhost/")};
        string admin=await Login(82001),manager=await Login(82002),employee=await Login(82004),peer=await Login(82003);
        Check((await Send(root+"options?employeeNumber=82004")).StatusCode==HttpStatusCode.Unauthorized,"Bearer required");
        Check((await Send("http://localhost/"+root+"options?employeeNumber=82004",employee)).StatusCode==HttpStatusCode.Forbidden,"HTTPS required");
        Check((await Send(root+"options?employeeNumber=4",employee)).StatusCode==HttpStatusCode.Forbidden,"employee number is not account ID");
        Check((await Send(root+"options?employeeNumber=82002",employee)).StatusCode==HttpStatusCode.Forbidden,"actor spoofing rejected");
        var options=await Data(await Send(root+"options?employeeNumber=82004",employee));
        Check(options["Priorities"].Count()==2&&options["ClosureReasons"].Count()==1&&!(bool)options["Permissions"]["CanCreateTask"],"dynamic catalogs and employee permissions");
        var recipients=await Data(await Send(root+"recipients?employeeNumber=82004",employee));
        Check((int)recipients["TotalItems"]==1&&(int)recipients["Items"][0]["ID"]==2,"recipients follow current branch");
        Check((await Send(root+"threads?employeeNumber=82004&supervisory=true",employee)).StatusCode==HttpStatusCode.BadRequest,"employee cannot supervise");
        var create=Create(82002,4,true);
        int id=(int)(await Data(await Upload(root+"threads",manager,create,pdf)))["ThreadIDs"][0];
        Check(id>0&&Count("Correspondence_Thread_Messages")==1&&Count("Correspondence_Message_Attachments")==1,"create task and shared attachment");
        Check((bool)(await Data(await Upload(root+"threads",manager,create,pdf)))["Replayed"]&&Count("Correspondence_Threads")==1,"retry does not duplicate threads or files");
        create["Title"]="Changed";Check((await Upload(root+"threads",manager,create,pdf)).StatusCode==HttpStatusCode.Conflict,"operation ID binds payload");
        Check((await Upload(root+"threads",employee,Create(82004,2,true))).StatusCode==HttpStatusCode.Forbidden,"employee cannot create tasks");
        Check((await Upload(root+"threads",employee,Create(82004,3))).StatusCode==HttpStatusCode.Forbidden,"cross-branch recipient denied");
        int fileCount=Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.CorrespondenceStoragePath"]).Length;
        Check((await Upload(root+"threads",employee,Create(82004,2),Encoding.ASCII.GetBytes("bad"))).StatusCode==HttpStatusCode.BadRequest,"invalid PDF denied");
        Check((await Upload(root+"threads",employee,Create(82004,2),pdf,"bad.exe")).StatusCode==HttpStatusCode.BadRequest,"unsupported file denied");
        Check((await Upload(root+"threads",employee,Create(82004,2),pdf,"note.pdf",6)).StatusCode==(HttpStatusCode)413,"file count enforced");
        var disabled=Create(82004,2);disabled["PriorityID"]=1;Sql("UPDATE Correspondence_Catalog SET IsActive=0 WHERE ID=1");
        Check((await Upload(root+"threads",employee,disabled,pdf)).StatusCode==HttpStatusCode.BadRequest&&Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.CorrespondenceStoragePath"]).Length==fileCount,"inactive priority rejected and files cleaned");
        Sql("UPDATE Correspondence_Catalog SET IsActive=1 WHERE ID=1");
        var opened=await Data(await Send(root+"threads/"+id+"/open",employee,Event(82004),true));
        Check(opened["Organization"].Count()==2&&!(bool)opened["Thread"]["CanClose"],"detail contains snapshots and creator-only completion");
        var messages=await Data(await Send(root+"threads/"+id+"/messages?employeeNumber=82004",employee));
        int first=(int)messages["Items"][0]["ID"];
        Check(!(bool)messages["Items"][0]["IsRead"]&&((string)messages["Attachments"][0]["Url"]).Contains("/FileManager/Correspondence/"),"fetch does not read; original attachment URL retained");
        Check((await Send(root+"threads/"+id+"/open",peer,Event(82003),true)).StatusCode==HttpStatusCode.NotFound,"nonparticipant manager denied");
        Check((await Send(root+"threads/"+id+"/messages?employeeNumber=82001",admin)).StatusCode==HttpStatusCode.NotFound,"administrator must explicitly choose supervision");
        Check((await Send(root+"threads/"+id+"/messages?employeeNumber=82001&supervisory=true&visitID="+Guid.NewGuid(),admin)).StatusCode==HttpStatusCode.Forbidden,"supervision requires audited open");
        var visit=Event(82001);visit["Supervisory"]=true;
        await Data(await Send(root+"threads/"+id+"/open",admin,visit,true));await Data(await Send(root+"threads/"+id+"/open",admin,visit,true));
        Check(Count("Correspondence_Audit")==1,"repeated supervisory open audited once");
        await Data(await Send(root+"threads/"+id+"/messages?employeeNumber=82001&supervisory=true&visitID="+visit["OperationID"],admin));
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Correspondence_Thread_Messages WHERE IsRead=1"))==0,"supervision never acknowledges recipient reading");
        var notices=await Data(await Send(root+"notifications?employeeNumber=82004",employee));int notice=(int)notices["Items"][0]["ID"];
        Check((int)notices["UnreadThreads"]==1&&(int)notices["UnreadNotifications"]==1,"separate unread counters");
        Check((await Send(root+"notifications/"+notice+"/read",manager,Event(82002),true)).StatusCode==HttpStatusCode.NotFound,"notification owner enforced");
        await Data(await Send(root+"notifications/"+notice+"/read",employee,Event(82004),true));
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Correspondence_Thread_Messages WHERE IsRead=1"))==0,"notification read is independent");
        var read=Event(82004);read["MessageIDs"]=new JArray(first);await Data(await Send(root+"threads/"+id+"/read",employee,read,true));
        object firstRead=Sql("SELECT ReadDate FROM Correspondence_Thread_Messages WHERE ID="+first);
        await Data(await Send(root+"threads/"+id+"/read",employee,read,true));
        Check(firstRead.Equals(Sql("SELECT ReadDate FROM Correspondence_Thread_Messages WHERE ID="+first)),"first reading timestamp stable across retries");
        var reply=Event(82004);reply["Body"]="Reply";
        var saved=await Data(await Upload(root+"threads/"+id+"/messages",employee,reply));
        await Data(await Upload(root+"threads/"+id+"/messages",employee,reply));
        Check(Count("Correspondence_Thread_Messages")==2,"reply retry is idempotent");
        messages=await Data(await Send(root+"threads/"+id+"/messages?employeeNumber=82004&pageSize=1",employee));
        Check((bool)messages["HasMore"]&&(int)messages["LatestID"]==(int)saved["MessageID"],"initial message page loads latest");
        messages=await Data(await Send(root+"threads/"+id+"/messages?employeeNumber=82004&pageSize=1&beforeID="+saved["MessageID"],employee));
        Check(!(bool)messages["HasMore"]&&(int)messages["OldestID"]==first,"older message cursor has no gaps");
        messages=await Data(await Send(root+"threads/"+id+"/messages?employeeNumber=82004&afterID="+first,employee));
        Check(messages["Items"].Count()==1&&(int)messages["LatestID"]==(int)saved["MessageID"],"new message polling cursor");
        var close=Event(82004);close["ClosureReasonID"]=3;close["IsCompleted"]=true;
        Check((await Send(root+"threads/"+id+"/close",employee,close,true)).StatusCode==HttpStatusCode.Conflict,"recipient cannot set outcome");
        close=Event(82002);close["ClosureReasonID"]=3;
        Check((await Send(root+"threads/"+id+"/close",manager,close,true)).StatusCode==HttpStatusCode.BadRequest,"task requires explicit outcome");
        close["IsCompleted"]=true;await Data(await Send(root+"threads/"+id+"/close",manager,close,true));
        Check((bool)(await Data(await Send(root+"threads/"+id+"/close",manager,close,true)))["Replayed"],"closing retry succeeds without duplicate notice");
        reply=Event(82004);reply["Body"]="Too late";Check((await Upload(root+"threads/"+id+"/messages",employee,reply)).StatusCode==HttpStatusCode.Conflict,"closed thread blocks replies");
        int transfer=(int)(await Data(await Upload(root+"threads",manager,Create(82002,4,true))))["ThreadIDs"][0];
        close=Event(82002);close["ClosureReasonID"]=4;close["IsCompleted"]=false;close["Explanation"]="Reassigned";
        await Data(await Send(root+"threads/"+transfer+"/close",manager,close,true));
        var replacement=Create(82002,5,true);replacement["RelatedThreadID"]=transfer;
        int next=(int)(await Data(await Upload(root+"threads",manager,replacement)))["ThreadIDs"][0];
        Check(Convert.ToInt32(Sql("SELECT RelatedThreadID FROM Correspondence_Threads WHERE ID="+next))==transfer,"replacement task retains link");
        var list=await Data(await Send(root+"threads?employeeNumber=82001&supervisory=true&pageSize=1",admin));
        Check(list["Items"].Count()==1&&(int)list["TotalItems"]==3&&(int)list["Counts"]["Completed"]==1,"paged oversight and report counts");
        var archive=Event(82001);archive["Explanation"]="Creator disabled";
        Check((await Send(root+"threads/"+next+"/archive",admin,archive,true)).StatusCode==HttpStatusCode.BadRequest,"cannot archive active creator");
        Sql("UPDATE UsersMembers SET IsActive=0 WHERE ID=2");
        await Data(await Send(root+"threads/"+next+"/archive",admin,archive,true));
        Check(Sql("SELECT IsCompleted FROM Correspondence_Threads WHERE ID="+next)==DBNull.Value,"archive does not fabricate completion");
        Check((await Send(root+"options?employeeNumber=82002",manager)).StatusCode==HttpStatusCode.Unauthorized,"disabled session rejected");
        Sql("UPDATE UsersMembers SET IsActive=1 WHERE ID=2");
        Check((await Upload(root+"threads",employee,Create(82004,2),pdf,"fake.docx")).StatusCode==HttpStatusCode.BadRequest,"malformed Office archive rejected");
        Check((await Upload(root+"threads",employee,Create(82004,2),new byte[10*1024*1024+1])).StatusCode==(HttpStatusCode)413,"per-file size limit");
        var spoof=Create(82004,2);spoof["SenderID"]=1;
        Check((await Upload(root+"threads",employee,spoof)).StatusCode==HttpStatusCode.BadRequest,"multipart unknown identity field rejected");
        byte[] docx;
        using(var buffer=new MemoryStream()) {using(var zip=new System.IO.Compression.ZipArchive(buffer,System.IO.Compression.ZipArchiveMode.Create,true)){zip.CreateEntry("[Content_Types].xml");zip.CreateEntry("word/document.xml");}docx=buffer.ToArray();}
        int office=(int)(await Data(await Upload(root+"threads",employee,Create(82004,2),docx,"test.docx")))["ThreadIDs"][0];
        var officeMessages=await Data(await Send(root+"threads/"+office+"/messages?employeeNumber=82004",employee));
        Check((string)officeMessages["Attachments"][0]["File_Type"]=="application/vnd.openxmlformats-officedocument.wordprocessingml.document","Office attachments use portal MIME contract");
        byte[] jpg;using(var bitmap=new System.Drawing.Bitmap(8,8))using(var buffer=new MemoryStream()){bitmap.Save(buffer,System.Drawing.Imaging.ImageFormat.Jpeg);jpg=buffer.ToArray();}
        var fileReply=Event(82004);
        await Data(await Upload(root+"threads/"+office+"/messages",employee,fileReply,jpg,"test.jpg"));
        officeMessages=await Data(await Send(root+"threads/"+office+"/messages?employeeNumber=82004",employee));
        Check(officeMessages["Items"].Count()==2&&(string)officeMessages["Attachments"][1]["File_Type"]=="image/png","attachment-only reply normalizes image");
        Sql("UPDATE Correspondence_Catalog SET Title=N'Renamed priority' WHERE ID=2; UPDATE UsersMembers SET Branch_ID=26 WHERE ID=4");
        opened=await Data(await Send(root+"threads/"+office+"/open",employee,Event(82004),true));
        Check((string)opened["Thread"]["PriorityName"]=="عاجلة"&&opened["Organization"].Any(p=>(int)p["UserID"]==4&&(int)p["BranchID"]==25),"catalog edits and employee transfer preserve original snapshots");
        recipients=await Data(await Send(root+"recipients?employeeNumber=82004",employee));
        Check((int)recipients["TotalItems"]==1&&(int)recipients["Items"][0]["ID"]==3,"new recipients reflect employee transfer");
        int beforeConcurrent=Count("Correspondence_Threads");
        var concurrent=Create(82004,3);
        var requests=await Task.WhenAll(Upload(root+"threads",employee,concurrent,pdf),Upload(root+"threads",employee,concurrent,pdf));
        var results=await Task.WhenAll(requests.Select(Data));
        Check(results.Count(r=>(bool)r["Replayed"])==1&&results.Select(r=>(int)r["ThreadIDs"][0]).Distinct().Count()==1&&Count("Correspondence_Threads")==beforeConcurrent+1,"concurrent retry creates exactly one thread");
        Console.WriteLine("Correspondence integration checks: "+checks);
    }
    sealed class Assemblies:System.Web.Http.Dispatcher.DefaultAssembliesResolver {public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}}
    public static int Main(){try{Run().GetAwaiter().GetResult();return 0;}catch(Exception ex){Console.Error.WriteLine(ex);return 1;}}
}
