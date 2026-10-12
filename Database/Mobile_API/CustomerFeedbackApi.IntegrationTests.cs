using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

static class CustomerFeedbackApiTests
{
    static HttpClient client; static int checks;
    const string customer="api/v1/customer-feedback/",employeeApi="api/v1/feedback/";
    static byte[] pdf=Encoding.ASCII.GetBytes("%PDF-1.4\nCustomer test attachment\n%%EOF");
    static void Check(bool condition,string label){if(!condition)throw new Exception("FAIL: "+label);checks++;Console.WriteLine("PASS: "+label);}
    static object Sql(string sql){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand(sql,cn)){cn.Open();return cmd.ExecuteScalar();}}
    static DataTable Table(string sql){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand(sql,cn))using(var adapter=new SqlDataAdapter(cmd)){var t=new DataTable();adapter.Fill(t);return t;}}
    static async Task<HttpResponseMessage> Send(string path,string token=null,JObject body=null){var req=new HttpRequestMessage(body==null?HttpMethod.Get:HttpMethod.Post,path);req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));if(token!=null)req.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);if(body!=null)req.Content=new StringContent(body.ToString(),Encoding.UTF8,"application/json");return await client.SendAsync(req);}
    static async Task<JToken> Data(HttpResponseMessage response){var text=await response.Content.ReadAsStringAsync();if(!response.IsSuccessStatusCode)throw new Exception("HTTP "+response.StatusCode+": "+text);return JObject.Parse(text)["Data"];}
    static JObject Event(){return JObject.FromObject(new{OperationID=Guid.NewGuid(),OccurredAt=DateTimeOffset.UtcNow.AddMinutes(-1).ToString("o")});}
    static JObject Create(bool disclose=true){var data=Event();data["TypeID"]=1;data["TopicID"]=1;data["BrandID"]=29;data["BranchID"]=25;data["Name"]="Customer Private Name";data["Mobile"]="+962790001234";data["Email"]="customer@example.test";data["Title"]="Customer test request";data["Details"]="Customer details";data["DiscloseIdentity"]=disclose;return data;}
    static async Task<HttpResponseMessage> Upload(string path,JObject data,byte[] file=null,string token=null){using(var form=new MultipartFormDataContent()){form.Add(new StringContent(data.ToString(),Encoding.UTF8,"application/json"),"data");if(file!=null)form.Add(new ByteArrayContent(file),"files","customer.pdf");var req=new HttpRequestMessage(HttpMethod.Post,path){Content=form};req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));if(token!=null)req.Headers.Authorization=new AuthenticationHeaderValue("Bearer",token);return await client.SendAsync(req);}}
    static async Task<JToken> Open(int id,int number,string token){var data=Event();data["EmployeeNumber"]=number;return await Data(await Send(employeeApi+"requests/"+id+"/open",token,data));}
    static JObject Action(int number,string version,string action="close",int? target=null){var data=Event();data["EmployeeNumber"]=number;data["RowVersion"]=version;data["Action"]=action;data["Comment"]="Customer request handled";if(target.HasValue)data["RecipientTypeID"]=target.Value;return data;}
    static void ResetRate(){Sql("DELETE dbo.Customer_Feedback_RateLimits;");}
    public static async Task<int> Run(HttpClient http,string employee,string admin,string adminPeer,string manager,string managerPeer){
        client=http; Sql("UPDATE dbo.Employee_Feedback_Types SET IsActive=1 WHERE ID=1;");
        Check((await Send("http://localhost/"+customer+"options")).StatusCode==HttpStatusCode.Forbidden,"customer API requires HTTPS without employee login");
        var options=await Data(await Send(customer+"options?brandID=29&typeID=1"));
        Check(options["Brands"].Count()==1 && options["Branches"].Count()==1 && options["Topics"].Count()==1 && options["Types"].Count()==2 && !options.ToString().Contains("Private employee"),"public options expose only active catalog labels");
        Check((await Data(await Send(customer+"options")))["Branches"].Count()==0,"customer chooses brand before branches and topics");
        var before=Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.UsersMembers"));
        var request=Create();
        int id=(int)(await Data(await Upload(customer+"requests",request,pdf)))["RequestID"];
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Employee_Feedback_Requests WHERE ID="+id+" AND SourceType=2 AND EmployeeID IS NULL AND ApplicantEmployeeNumber IS NULL AND Brand_ID=29 AND Branch_ID=25 AND ApplicantEmail=N'customer@example.test'"))==1 && before==Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.UsersMembers")),"customer saved in same table with no synthetic employee");
        bool guarded=false;try{Sql("UPDATE dbo.Employee_Feedback_Requests SET EmployeeID=4 WHERE ID="+id);}catch(SqlException ex){guarded=ex.Number==547;}
        Check(guarded,"database rejects employee linkage on a customer request");
        guarded=false;try{Sql("UPDATE dbo.Employee_Feedback_Requests SET EmployeeID=NULL WHERE ID=(SELECT MIN(ID) FROM dbo.Employee_Feedback_Requests WHERE SourceType=1)");}catch(SqlException ex){guarded=ex.Number==547;}
        Check(guarded,"database still requires employee ID on employee requests");
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID="+id+" AND SenderID IS NULL AND ReceiverID IN(1,6) AND ActionType=1"))==2 && Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID="+id))==2,"customer routes to all administrators and notifies both");
        Check((bool)(await Data(await Upload(customer+"requests",request,pdf)))["Replayed"] && Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Employee_Feedback_Attachments WHERE Request_ID="+id))==1,"public customer retry does not duplicate request or file");
        request["Name"]="Changed identity";
        Check((await Upload(customer+"requests",request,pdf)).StatusCode==HttpStatusCode.Conflict,"public operation ID does not reveal a different payload result");
        var detail=await Open(id,81001,admin);
        Check((bool)detail["Request"]["CanAct"] && (int)detail["Contact"]["SourceType"]==2 && (string)detail["Contact"]["ApplicantName"]=="Customer Private Name" && (string)detail["Contact"]["BrandName"]=="Test brand" && (string)detail["Contact"]["BranchName"]=="عبدالله غوشة","administrator can see customer contact, branch and brand centrally");
        Check(detail["Workflow"].Count()==1 && (string)detail["Workflow"][0]["SenderName"]=="Customer Private Name","timeline preserves external sender with null internal ID");
        Sql("UPDATE dbo.Brands SET Title_Ar=N'Renamed brand' WHERE ID=29; UPDATE dbo.Branches SET Title_Ar=N'Renamed branch' WHERE ID=25;");
        var snapshot=await Open(id,81001,admin);
        Check((string)snapshot["Contact"]["BrandName"]=="Test brand" && (string)snapshot["Contact"]["BranchName"]=="عبدالله غوشة","customer brand and branch names are preserved as submission snapshots");
        Sql("UPDATE dbo.Brands SET Title_Ar=N'Test brand' WHERE ID=29; UPDATE dbo.Branches SET Title_Ar=N'عبدالله غوشة' WHERE ID=25;");
        var listing=await Data(await Send(employeeApi+"requests?employeeNumber=81001&scope=action",admin));
        Check(listing["Items"].Any(x=>(int)x["ID"]==id && (int)x["SourceType"]==2 && (bool)x["CanAct"] && !(bool)x["IsMine"]),"customer request appears in actionable employee API inbox");
        Check((await Send((string)detail["Attachments"][0]["PreviewUrl"])).StatusCode==HttpStatusCode.Unauthorized,"customer attachment cannot be opened anonymously");
        Check((await Send(customer+"requests/"+id)).StatusCode==HttpStatusCode.NotFound,"no public request-detail lookup by ID");
        var blocked=Event();blocked["EmployeeNumber"]=81004;
        Check((await Send(employeeApi+"requests/"+id+"/open",employee,blocked)).StatusCode==HttpStatusCode.NotFound,"unrelated employee cannot read customer data");
        Check(Table("EXEC dbo.Select_Employee_Feedback_Requests @Actor=1,@Mode=2,@Search=N'',@Source=2").Rows.Count==1,"portal report includes customer requests by source");
        var stats=Table("EXEC dbo.Select_Employee_Feedback_Statistics @Actor=1,@Source=2");
        Check(stats.Rows.Cast<DataRow>().Any(r=>(string)r["Dimension"]=="source" && (int)r["Value"]==2 && (int)r["Total"]==1),"dashboard counts customer source correctly");
        var peerDetail=await Open(id,81006,adminPeer);
        var close=Action(81001,(string)detail["Request"]["RowVersion"]);
        await Data(await Upload(employeeApi+"requests/"+id+"/actions",close,pdf,admin));
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Employee_Feedback_Workflow WHERE Request_ID="+id+" AND ActionType=3 AND SenderID=1 AND ReceiverID IS NULL"))==1 && Convert.ToInt32(Sql("SELECT Status FROM dbo.Employee_Feedback_Requests WHERE ID="+id))==3,"customer close records actual manager without fictitious receiver");
        Check((await Upload(employeeApi+"requests/"+id+"/actions",Action(81006,(string)peerDetail["Request"]["RowVersion"]),token:adminPeer)).StatusCode==HttpStatusCode.Conflict,"customer first action revokes peer administrator action");
        var closed=await Open(id,81001,admin);
        Check(closed["Workflow"].Count()==2 && closed["Attachments"].Count()==2 && (string)closed["Workflow"][1]["ReceiverNames"]=="Customer Private Name","closed customer timeline and action attachments stay visible");
        Check(Table("EXEC dbo.Select_Employee_Feedback_Logs @Actor=1,@ID="+id).Rows.Cast<DataRow>().Any(r=>(string)r["EventType"]=="تقديم" && (string)r["ActorName"]=="Customer Private Name"),"portal logs retain customer submission event");
        ResetRate();
        var anonymous=Create(false);int anonID=(int)(await Data(await Upload(customer+"requests",anonymous)))["RequestID"];
        var anonymousDetail=await Open(anonID,81001,admin);
        Check(!(bool)anonymousDetail["Contact"]["CanViewContact"] && !anonymousDetail.ToString().Contains("Customer Private Name") && !anonymousDetail.ToString().Contains("customer@example.test"),"anonymous customer stays private across contact and timeline");
        Check(!string.Join(" ",Table("EXEC dbo.Select_Employee_Feedback_Logs @Actor=1,@ID="+anonID).Rows.Cast<DataRow>().Select(r=>Convert.ToString(r["ActorName"]))).Contains("Customer Private Name"),"anonymous customer hidden in portal logs");
        await Data(await Upload(employeeApi+"requests/"+anonID+"/actions",Action(81001,(string)anonymousDetail["Request"]["RowVersion"]),token:admin));
        var anonymousClosed=await Open(anonID,81001,admin);
        Check(anonymousClosed["Workflow"].Count()==2 && !anonymousClosed.ToString().Contains("Customer Private Name"),"anonymous customer stays hidden as receiver on closing timeline");
        var bad=Create();bad["EmployeeNumber"]=81004;
        Check((await Upload(customer+"requests",bad)).StatusCode==HttpStatusCode.BadRequest,"customer API rejects injected employee identity");
        bad=Create();bad["RecipientTypeID"]=2;
        Check((await Upload(customer+"requests",bad)).StatusCode==HttpStatusCode.BadRequest,"customer cannot override fixed administrator routing");
        bad=Create();bad["Email"]="bad-email";
        Check((await Upload(customer+"requests",bad)).StatusCode==HttpStatusCode.BadRequest,"invalid customer email rejected");
        bad=Create();bad["Mobile"]="";
        Check((await Upload(customer+"requests",bad)).StatusCode==HttpStatusCode.BadRequest,"customer mobile contact required");
        Sql("SET IDENTITY_INSERT dbo.Brands ON; INSERT dbo.Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(30,N'Other brand',N'Other brand',1,0); SET IDENTITY_INSERT dbo.Brands OFF;");
        bad=Create();bad["BrandID"]=30;
        int filesBefore=Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.FeedbackStoragePath"]).Length;
        Check((await Upload(customer+"requests",bad,pdf)).StatusCode==HttpStatusCode.BadRequest && filesBefore==Directory.GetFiles(ConfigurationManager.AppSettings["MobileApi.FeedbackStoragePath"]).Length,"mismatched brand and branch rejected with file cleanup");
        Sql("UPDATE dbo.Branches SET IsActive=0 WHERE ID=25;");
        Check((await Upload(customer+"requests",Create())).StatusCode==HttpStatusCode.BadRequest,"inactive branch rejected at save time");
        Sql("UPDATE dbo.Branches SET IsActive=1 WHERE ID=25; UPDATE dbo.Employee_Feedback_Topics SET IsActive=0 WHERE ID=1;");
        Check((await Upload(customer+"requests",Create())).StatusCode==HttpStatusCode.BadRequest,"inactive customer topic rejected");
        Sql("UPDATE dbo.Employee_Feedback_Topics SET IsActive=1 WHERE ID=1; UPDATE dbo.UsersMembers SET IsActive=0 WHERE Type=1;");
        Check((await Upload(customer+"requests",Create())).StatusCode==HttpStatusCode.BadRequest,"no available administrator rejects submission without orphan request");
        Sql("UPDATE dbo.UsersMembers SET IsActive=1 WHERE Type=1;");ResetRate();
        var same=Create();var concurrent=await Task.WhenAll(Upload(customer+"requests",same),Upload(customer+"requests",same));
        var first=await Data(concurrent[0]);var second=await Data(concurrent[1]);
        Check((int)first["RequestID"]==(int)second["RequestID"] && (bool)first["Replayed"]!=(bool)second["Replayed"],"concurrent public retries create exactly one request");
        Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM dbo.Customer_Feedback_Submissions WHERE RequestID="+id+" AND DATEDIFF(second,OccurredAt,ReceivedUtc)>30 AND WorkflowGroupID IS NOT NULL"))==1,"customer audit captures original event time and workflow group");
        Sql("UPDATE dbo.Employee_Feedback_Permissions SET CanTransfer=1 WHERE UserTypeID=1; INSERT dbo.Employee_Feedback_AllowedRecipients(SenderUserTypeID,RecipientUserTypeID) VALUES(1,2);");
        int transferID=(int)first["RequestID"];var ready=await Open(transferID,81001,admin);
        await Data(await Upload(employeeApi+"requests/"+transferID+"/actions",Action(81001,(string)ready["Request"]["RowVersion"],"transfer",2),token:admin));
        var branch=await Open(transferID,81002,manager);
        Check((bool)branch["Request"]["CanAct"] && branch["Workflow"].Count()==2,"CMS-configured customer transfer resolves managers by selected branch snapshot");
        await Data(await Upload(employeeApi+"requests/"+transferID+"/actions",Action(81002,(string)branch["Request"]["RowVersion"]),token:manager));
        Check((await Open(transferID,81001,admin))["AllowedActions"].Count()==0,"previous administrator retains read-only access after customer transfer and close");
        Sql("UPDATE dbo.Employee_Feedback_Permissions SET CanTransfer=0 WHERE UserTypeID=1; DELETE dbo.Employee_Feedback_AllowedRecipients WHERE SenderUserTypeID=1;");
        Sql("UPDATE dbo.Customer_Feedback_RateLimits SET Attempts=10 WHERE Scope='submit';");
        var limited=await Upload(customer+"requests",Create());
        Check(limited.StatusCode==(HttpStatusCode)429 && limited.Headers.RetryAfter!=null,"public submission rate limit includes Retry-After");
        var spoof=new HttpRequestMessage(HttpMethod.Post,customer+"requests");spoof.Headers.Add("X-Forwarded-For","192.0.2.123");
        Check((await client.SendAsync(spoof)).StatusCode==(HttpStatusCode)429,"caller forwarding headers cannot bypass public rate limits");
        Console.WriteLine("CUSTOMER CHECKS PASSED: "+checks);return checks;
    }
}
