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

class FeedbackApiTests
{
    static HttpClient client; static int checks;
    static string password="Feedback-test-"+Guid.NewGuid().ToString("N");
    static readonly byte[] pdf=Encoding.ASCII.GetBytes("%PDF-1.4\n1 0 obj<</Type /Catalog>>endobj\n%%EOF");
    static void Check(bool value,string name) { if(!value)throw new Exception("FAIL: "+name); Console.WriteLine("PASS: "+name); checks++; }
    static object Sql(string sql,params SqlParameter[] parameters) {
        using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))
        using(var cmd=new SqlCommand(sql,cn)) { cn.Open();cmd.Parameters.AddRange(parameters); return cmd.ExecuteScalar(); }
    }
    static int Count(string table) { return Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo."+table)); }
    static async Task<HttpResponseMessage> Send(string path,string token=null,object body=null,bool post=false) {
        var request=new HttpRequestMessage(post?HttpMethod.Post:HttpMethod.Get,path);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        if(token!=null)request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);
        if(body!=null)request.Content=new StringContent(JsonConvert.SerializeObject(body),Encoding.UTF8,"application/json");
        return await ApiPerformanceProbe.Send(client,request);
    }
    static async Task<JToken> Data(HttpResponseMessage response) {
        string json=await response.Content.ReadAsStringAsync();
        if(!response.IsSuccessStatusCode)throw new Exception("HTTP "+response.StatusCode+": "+json);
        return JObject.Parse(json)["Data"];
    }
    static async Task<string> Login(int number) { return (string)(await Data(await Send("api/Users/Login",body:new{Username="fb_"+number,Password=password,AppVersion="1.0.0",Device=new{DeviceID="feedback-test-"+number,Platform="Android",Model="Test device",OSVersion="14"}},post:true)))["AccessToken"]; }
    static JObject Event(int number) { return JObject.FromObject(new{EmployeeNumber=number,OperationID=Guid.NewGuid(),OccurredAt=DateTimeOffset.UtcNow.AddMinutes(-2).ToString("o")}); }
    static JObject Create(int number=81004,int target=2,bool disclose=false) {
        var data=Event(number); data["TypeID"]=1;data["TopicID"]=1;data["Title"]="Test feedback";data["Details"]="Details";data["DiscloseIdentity"]=disclose;data["RecipientTypeID"]=target;return data;
    }
    static JObject Action(int number,string version,string action="close",int? target=null) {
        var data=Event(number);data["RowVersion"]=version;data["Action"]=action;data["Comment"]="Follow-up explanation";if(target.HasValue)data["RecipientTypeID"]=target.Value;return data;
    }
    static async Task<HttpResponseMessage> Upload(string path,string token,JObject data,byte[] bytes=null,string name="note.pdf",int copies=1) {
        using(var form=new MultipartFormDataContent()) {
            form.Add(new StringContent(data.ToString(),Encoding.UTF8,"application/json"),"data");
            for(int i=0;bytes!=null && i<copies;i++)form.Add(new ByteArrayContent(bytes),"files",name);
            var request=new HttpRequestMessage(HttpMethod.Post,path){Content=form}; request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));return await ApiPerformanceProbe.Send(client,request);
        }
    }
    const string root="api/v1/feedback/";
    static async Task Run() {
        Sql(@"SET IDENTITY_INSERT dbo.UsersMembers ON;
INSERT dbo.UsersMembers(ID,Type,Employee_Number,UserName,Password,FullName_Ar,Fullname_En,IsActive,IsDeleted,Brand_ID,Branch_ID,PhoneNumber,MobileNumber,Email)
SELECT ID,Role,Number,CONCAT('fb_',Number),@Password,CONCAT(N'Private employee ',Number),CONCAT(N'Private employee ',Number),1,0,29,25,N'555123',N'555456',N'private@example.test'
FROM (VALUES(1,1,81001),(2,2,81002),(3,2,81003),(4,4,81004),(5,4,81005),(6,1,81006))v(ID,Role,Number);
SET IDENTITY_INSERT dbo.UsersMembers OFF;
INSERT dbo.Employee_Feedback_Topics(Type,Brand_ID,Title_Ar,Title_En,AddedUser) VALUES(1,29,N'Test topic',N'Test topic',1);",new SqlParameter("@Password",new Echo.Encrptor.TripleDesEncryptor().Encrypt(password)));
        var config=new HttpConfiguration();WebApiConfig.Register(config);
        config.Services.Replace(typeof(System.Web.Http.Dispatcher.IAssembliesResolver),new Assemblies());config.EnsureInitialized();
        client=new HttpClient(new HttpServer(config)){BaseAddress=new Uri("https://localhost/")};
        string employee=await Login(81004),manager=await Login(81002),peer=await Login(81003),admin=await Login(81001),adminPeer=await Login(81006),other=await Login(81005);
        Check((await Send(root+"options?employeeNumber=81004")).StatusCode==HttpStatusCode.Unauthorized,"Bearer required");
        Check((await Send(root+"options?employeeNumber=4",employee)).StatusCode==HttpStatusCode.Forbidden,"employee number is not internal user ID");
        Check((await Send(root+"options?employeeNumber=81002",employee)).StatusCode==HttpStatusCode.Forbidden,"employee spoofing rejected");
        var options=await Data(await Send(root+"options?employeeNumber=81004",employee));
        Check(options["Types"].Count()==2 && options["Topics"].Count()==1 && options["RecipientTypes"].Count()==4,"dynamic options and permissions");
        var routing=await Data(await Send(root+"routing-preview",employee,new{EmployeeNumber=81004,RecipientTypeID=2},true));
        Check(routing["Recipients"].Count()==2 && !(bool)routing["IsFallback"],"routes to all branch managers");
        routing=await Data(await Send(root+"routing-preview",employee,new{EmployeeNumber=81004,RecipientTypeID=3},true));
        Check(routing["Recipients"].Count()==2 && (bool)routing["IsFallback"],"missing shift manager falls back to all administrators");
        var create=Create();
        var created=await Data(await Upload(root+"requests",employee,create,pdf));int id=(int)created["RequestID"];
        Check(id>0 && Count("Employee_Feedback_Attachments")==1 && Count("Employee_Feedback_Workflow")==2,"single submission persists request, file and all recipients");
        Check(Convert.ToInt32(Sql("SELECT ApplicantEmployeeNumber FROM dbo.Employee_Feedback_Requests WHERE ID="+id))==81004 && Convert.ToInt32(Sql("SELECT SourceType FROM dbo.Employee_Feedback_Requests WHERE ID="+id))==1,"server captures employee snapshot and source");
        Check((bool)(await Data(await Upload(root+"requests",employee,create,pdf)))["Replayed"] && Count("Employee_Feedback_Requests")==1,"submission retry is idempotent");
        create["Title"]="changed";
        Check((await Upload(root+"requests",employee,create,pdf)).StatusCode==HttpStatusCode.Conflict,"operation ID cannot be reused with changed payload");
        Check((await Upload(root+"requests",employee,Create(),Encoding.ASCII.GetBytes("fake"))).StatusCode==HttpStatusCode.BadRequest,"invalid PDF rejected");
        Check((await Upload(root+"requests",employee,Create(),pdf,"note.docx")).StatusCode==HttpStatusCode.BadRequest,"Office upload rejected on mobile");
        Check((await Upload(root+"requests",employee,Create(),new byte[10*1024*1024+1])).StatusCode==(HttpStatusCode)413,"10MB limit enforced");
        var invalid=Create();invalid["TopicID"]=99999;
        int beforeFiles=Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.FeedbackStoragePath"]).Length;
        Check((await Upload(root+"requests",employee,invalid,pdf)).StatusCode==HttpStatusCode.BadRequest && Count("Employee_Feedback_Requests")==1 && beforeFiles==Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.FeedbackStoragePath"]).Length,"failed business validation rolls back SQL and files");
        var list=await Data(await Send(root+"requests?employeeNumber=81002",manager));
        Check((int)list["Counts"]["ActionRequiredRequests"]==1 && (string)list["Items"][0]["BranchName"]=="عبدالله غوشة" && (string)list["Items"][0]["BrandName"]=="Test brand","follow-up counts, branch and brand mapping");
        Check((int)(await Data(await Send(root+"notifications?employeeNumber=81002",manager)))["UnreadCount"]==1 && Count("Employee_Feedback_Views")==0,"listing requests and notifications does not mark read");
        Check((await Send(root+"requests/"+id+"/open",other,Event(81005),true)).StatusCode==HttpStatusCode.NotFound,"unrelated employee cannot view request");
        Check((await Send(root+"requests/"+id+"/open",admin,Event(81001),true)).StatusCode==HttpStatusCode.NotFound,"administrator has no mobile report bypass");
        var openedEvent=Event(81002);var detail=await Data(await Send(root+"requests/"+id+"/open",manager,openedEvent,true));
        Check((int)detail["Request"]["Status"]==2 && detail["AllowedActions"].Count()==2 && detail["Attachments"].Count()==1 && detail["Workflow"].Count()==1,"open returns central detail and server allowed actions");
        Check(!(bool)detail["Contact"]["CanViewContact"] && detail["Contact"]["ApplicantEmployeeNumber"].Type==JTokenType.Null && !detail.ToString().Contains("private@example.test") && !detail.ToString().Contains("Private employee 81004"),"anonymous identity hidden in detail, contact and workflow");
        Check((int)(await Data(await Send(root+"notifications?employeeNumber=81002",manager)))["UnreadCount"]==0 && Count("Employee_Feedback_Views")==1,"opening alone marks related notifications read and logs view");
        await Data(await Send(root+"requests/"+id+"/open",manager,openedEvent,true));
        Check(Count("Employee_Feedback_Views")==1,"open network retry does not duplicate view log");
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.MobileApi_FeedbackEvents WHERE EventType='open' AND ViewID IS NOT NULL AND DATEDIFF(second,OccurredAt,ReceivedUtc)>60"))==1,"client event time and server receipt time preserved separately");
        var file=detail["Attachments"][0];
        Check((string)file["PreviewUrl"]!=null && !file.ToString().Contains("FileName\": \"note"),"ready protected attachment URLs and neutral filenames");
        var downloaded=await Send((string)file["PreviewUrl"],manager);
        Check(downloaded.IsSuccessStatusCode && downloaded.Content.Headers.ContentType.MediaType=="application/pdf" && (await downloaded.Content.ReadAsByteArrayAsync()).SequenceEqual(pdf),"preview serves actual PDF bytes");
        Check((await Send(root+"attachments/"+file["ID"]+"?employeeNumber=81005",other)).StatusCode==HttpStatusCode.NotFound,"attachment access is authorized independently");
        var own=await Data(await Send(root+"requests/"+id+"/open",employee,Event(81004),true));
        Check((bool)own["Contact"]["CanViewContact"] && own["AllowedActions"].Count()==0,"owner can inspect snapshot but cannot act");
        Check((await Upload(root+"requests/"+id+"/actions",employee,Action(81004,(string)own["Request"]["RowVersion"]))).StatusCode==HttpStatusCode.Forbidden,"employee cannot close own request");
        var blank=Action(81002,(string)detail["Request"]["RowVersion"]);blank["Comment"]=" ";
        Check((await Upload(root+"requests/"+id+"/actions",manager,blank)).StatusCode==HttpStatusCode.BadRequest,"mandatory action explanation");
        var peerDetail=await Data(await Send(root+"requests/"+id+"/open",peer,Event(81003),true));
        var transfer=Action(81002,(string)detail["Request"]["RowVersion"],"transfer",1);
        await Data(await Upload(root+"requests/"+id+"/actions",manager,transfer,pdf));
        Check((await Upload(root+"requests/"+id+"/actions",peer,Action(81003,(string)peerDetail["Request"]["RowVersion"]))).StatusCode==HttpStatusCode.Conflict,"first recipient action disables peer action");
        Check((bool)(await Data(await Upload(root+"requests/"+id+"/actions",manager,transfer,pdf)))["Replayed"],"action retry does not duplicate transfer or attachments");
        var oldDetail=await Data(await Send(root+"requests/"+id+"/open",manager,Event(81002),true));
        Check(oldDetail["AllowedActions"].Count()==0 && oldDetail["Attachments"].Count()==2,"former recipient keeps read-only complete history");
        var adminDetail=await Data(await Send(root+"requests/"+id+"/open",admin,Event(81001),true));
        var adminPeerDetail=await Data(await Send(root+"requests/"+id+"/open",adminPeer,Event(81006),true));
        Check(adminDetail["AllowedActions"].Count()==1 && (string)adminDetail["AllowedActions"][0]["Code"]=="close" && !(bool)adminDetail["Contact"]["CanViewContact"],"administrator close-only and anonymous privacy");
        var concurrent=await Task.WhenAll(Upload(root+"requests/"+id+"/actions",admin,Action(81001,(string)adminDetail["Request"]["RowVersion"])),Upload(root+"requests/"+id+"/actions",adminPeer,Action(81006,(string)adminPeerDetail["Request"]["RowVersion"])));
        Check(concurrent.Count(r=>r.IsSuccessStatusCode)==1 && concurrent.Count(r=>r.StatusCode==HttpStatusCode.Conflict)==1,"concurrent administrators have exactly one winner");
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.MobileApi_FeedbackEvents WHERE EventType IN('submit','transfer','close')"))==3,"logs generated by successful server operations only");
        var second=await Data(await Upload(root+"requests",employee,Create(target:1,disclose:true)));
        var third=await Data(await Upload(root+"requests",employee,Create()));
        list=await Data(await Send(root+"requests?employeeNumber=81002&pageSize=1",manager));
        Check((int)list["Items"][0]["ID"]==(int)third["RequestID"] && (int)list["Counts"]["ClosedRequests"]==1 && (int)list["TotalItems"]==2,"actionable before closed and correct pagination totals");
        list=await Data(await Send(root+"requests?employeeNumber=81004",employee));
        Check((int)list["Counts"]["TotalRequests"]==3 && (int)list["Counts"]["SentRequests"]==3 && list["Items"].Count()==3,"own follow-up union is deduplicated");
        Check((await Send(root+"notifications/read",employee,new{},true)).StatusCode==HttpStatusCode.NotFound,"no standalone notification-read endpoint");
        var missingTime=Create();missingTime["OccurredAt"]="2026-01-01T12:00:00";
        Check((await Upload(root+"requests",employee,missingTime)).StatusCode==HttpStatusCode.BadRequest,"timestamps require an explicit timezone");
        var future=Create();future["OccurredAt"]=DateTimeOffset.UtcNow.AddHours(1).ToString("o");
        Check((await Upload(root+"requests",employee,future)).StatusCode==HttpStatusCode.BadRequest,"future device clock rejected");
        Check((await Upload(root+"requests",employee,Create(),pdf,"note.pdf",6)).StatusCode==(HttpStatusCode)413,"at most five attachments");
        Check((await Upload(root+"requests",employee,Create(),new byte[]{1,2,3},"invalid.png")).StatusCode==HttpStatusCode.BadRequest,"invalid image rejected");
        byte[] jpg;
        using(var bitmap=new System.Drawing.Bitmap(8,8))using(var stream=new MemoryStream()) { bitmap.Save(stream,System.Drawing.Imaging.ImageFormat.Jpeg);jpg=stream.ToArray(); }
        int imageId=(int)(await Data(await Upload(root+"requests",employee,Create(),jpg,"private-name.jpg")))["RequestID"];
        var imageDetail=await Data(await Send(root+"requests/"+imageId+"/open",employee,Event(81004),true));
        Check((string)imageDetail["Attachments"][0]["File_Type"]=="png","images normalized to PNG to strip metadata");
        var imageResponse=await Send((string)imageDetail["Attachments"][0]["PreviewUrl"],employee);
        Check(imageResponse.IsSuccessStatusCode && imageResponse.Content.Headers.ContentType.MediaType=="image/png" && (await imageResponse.Content.ReadAsByteArrayAsync())[0]==137,"normalized image can be previewed");
        Sql("UPDATE dbo.Employee_Feedback_Permissions SET CanSubmit=0 WHERE UserTypeID=4");
        Check((await Upload(root+"requests",employee,Create())).StatusCode==HttpStatusCode.Forbidden,"CMS permission change takes effect immediately");
        Sql("UPDATE dbo.Employee_Feedback_Permissions SET CanSubmit=1 WHERE UserTypeID=4; UPDATE dbo.Employee_Feedback_Types SET IsActive=0 WHERE ID=1;");
        Check((await Upload(root+"requests",employee,Create())).StatusCode==HttpStatusCode.BadRequest,"inactive request type cannot be submitted");
        var visible=await Data(await Send(root+"requests/"+second["RequestID"]+"/open",admin,Event(81001),true));
        Check((bool)visible["Contact"]["CanViewContact"] && (int)visible["Contact"]["ApplicantEmployeeNumber"]==81004 && (string)visible["Request"]["TypeName"]=="شكوى","disclosed contact and historical inactive type label remain available");
        checks+=await CustomerFeedbackApiTests.Run(client,employee,admin,adminPeer,manager,peer);
        Console.WriteLine("TOTAL PASSED: "+checks);
    }
    static int Main() { try {Run().GetAwaiter().GetResult();ApiPerformanceProbe.Save("feedback");return 0;}catch(Exception ex){Console.WriteLine(ex);return 1;} }
    class Assemblies : System.Web.Http.Dispatcher.DefaultAssembliesResolver {
        public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}
    }
}
