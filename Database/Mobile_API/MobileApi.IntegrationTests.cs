// Compiled against the built API; run only against the isolated database created by Test-MobileApi.ps1.
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;

class MobileApiTests
{
    static HttpClient client;
    static int checks;
    static bool bioBasic = true;
    static string bioBasicOverride;
    static string password = "Mobile-Test-Only-" + Guid.NewGuid().ToString("N");
    static void Check(bool condition, string name)
    {
        if (!condition) throw new Exception("FAIL: " + name);
        checks++; Console.WriteLine("PASS: " + name);
    }
    static void Sql(string sql, params SqlParameter[] parameters)
    {
        using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))
        using (var cmd = new SqlCommand(sql, cn))
        { cn.Open(); cmd.Parameters.AddRange(parameters); cmd.ExecuteNonQuery(); }
    }
    static async Task<HttpResponseMessage> Send(string path, string token = null, object body = null, bool post = false)
    {
        var request = new HttpRequestMessage(post ? HttpMethod.Post : HttpMethod.Get, path);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        if (token != null) request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (path.IndexOf("Users/LoginViaBIO",StringComparison.OrdinalIgnoreCase)>=0 && bioBasic)
            request.Headers.Authorization=new AuthenticationHeaderValue("Basic",bioBasicOverride??Environment.GetEnvironmentVariable("BIO_TEST_BASIC"));
        if (body != null) request.Content = new StringContent(Newtonsoft.Json.JsonConvert.SerializeObject(body), Encoding.UTF8, "application/json");
        return await ApiPerformanceProbe.Send(client,request);
    }
    static Task<HttpResponseMessage> News(string token=null,int brand=29){return Send("api/Get_News",token,new{BrandID=brand},true);}
    static async Task<JObject> Json(HttpResponseMessage response)
    { return JObject.Parse(await response.Content.ReadAsStringAsync()); }
    static JObject LoginBody(string suppliedPassword=null)
    { return JObject.FromObject(new { Username="mobile_test",Password=suppliedPassword??password,AppVersion="1.0.0",AppBuild="100",
        Device=new{DeviceID="mobile-test-installation-A",Platform="Android",Manufacturer="Test manufacturer",Model="Test phone",OSVersion="14",MACID="aa-bb-cc-dd-ee-02"} }); }
    static object Scalar(string sql,params SqlParameter[] parameters)
    { using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand(sql,cn)) {cn.Open();cmd.Parameters.AddRange(parameters);return cmd.ExecuteScalar();} }
    static DataRow StoredSession(string token)
    { using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))using(var cmd=new SqlCommand("SELECT UserID,EmployeeNumber,AppVersion,AppBuild,DeviceID,DevicePlatform,DeviceManufacturer,DeviceModel,OSVersion,MACID FROM dbo.MobileApi_Sessions WHERE TokenHash=@hash",cn))using(var adapter=new SqlDataAdapter(cmd)) {cmd.Parameters.AddWithValue("@hash",Hash(token));var data=new DataTable();adapter.Fill(data);return data.Rows[0];} }
    static async Task<string> Login()
    {
        var response = await Send("api/Users/Login", body: LoginBody(), post: true);
        Check(response.StatusCode == HttpStatusCode.OK, "login succeeds");
        var data = (await Json(response))["Data"];
        var user = (JObject)data["User"];
        Check(user.Properties().Select(p=>p.Name).OrderBy(x=>x).SequenceEqual(new[]{"BIOID","ID","Employee_Number","FullName_Ar","Fullname_En","User_Image","PhoneNumber","MobileNumber","Email","UserName","userType","brand","branch","department","jobTitle","shift","gender","nationality"}.OrderBy(x=>x)), "public employee DTO exposes only business fields and nested lookups");
        Check((int)user["branch"]["ID"]==12 && (string)user["branch"]["Title_Ar"]=="فرع اختبار" && (string)user["branch"]["Title_En"]=="Test branch", "branch lookup includes ID and both localized names");
        Check((int)user["brand"]["ID"]==29 && (int)user["userType"]["ID"]==4 && (int)user["gender"]["ID"]==1 && (int)user["nationality"]["ID"]==1, "lookup identities remain mapped to employee assignments");
        Check(user["department"].Type==JTokenType.Null && user["jobTitle"].Type==JTokenType.Null && user["shift"].Type==JTokenType.Null, "unassigned organization lookups are null");
        foreach(var name in new[]{"brand","branch","userType","gender","nationality"})
            Check(((JObject)user[name]).Properties().Select(p=>p.Name).OrderBy(x=>x).SequenceEqual(new[]{"ID","Title_Ar","Title_En"}.OrderBy(x=>x)), "lookup object excludes administrative fields: "+name);
        Check(data["User"]["User_Image"].Type == JTokenType.Null, "empty employee image is null");
        Check(response.Headers.CacheControl.NoStore && data["ExpiresAt"] != null && data["AbsoluteExpiresAt"] != null, "login expiry and no-store");
        Check((string)data["Session"]["MACID"]=="AA:BB:CC:DD:EE:02" && (string)data["Session"]["DeviceManufacturer"]=="Test manufacturer","supplied optional device metadata is returned with normalized MAC");
        Check((string)data["User"]["BIOID"]!=(string)data["AccessToken"] && Hash((string)data["User"]["BIOID"]).Length==32,"normal login supplies a separate canonical BIOID secret");
        return (string)data["AccessToken"];
    }
    static void Decide(string action,int? request=null,int? device=null,bool nonAdmin=false)
    {
        Sql(@"DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=@actorName),@user int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'mobile_test');
EXEC dbo.MobileApi_ManageDevices @Actor=@actor,@UserID=@user,@Action=@action,@RequestID=@request,@DeviceRegistrationID=@device,@Comment=N'Test decision';",
            new SqlParameter("@actorName",nonAdmin?"mobile_test":"device_admin"),new SqlParameter("@action",action),
            new SqlParameter("@request",(object)request??DBNull.Value),new SqlParameter("@device",(object)device??DBNull.Value));
    }
    static byte[] Hash(string token)
    { using (var sha = SHA256.Create()) return sha.ComputeHash(Convert.FromBase64String(token.Replace('-', '+').Replace('_', '/') + "=")); }
    static void ChangeSession(string token, string changes)
    { Sql("UPDATE dbo.MobileApi_Sessions SET " + changes + " WHERE TokenHash=@hash", new SqlParameter("@hash", Hash(token))); }
    static async Task Run()
    {
        string encrypted = new Echo.Encrptor.TripleDesEncryptor().Encrypt(password);
        Sql(@"SET IDENTITY_INSERT dbo.Users_Types ON;
INSERT dbo.Users_Types(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(1,N'Admin',N'Admin',1,0),(4,N'Employee',N'Employee',1,0),(7,N'Other',N'Other',1,0);
SET IDENTITY_INSERT dbo.Users_Types OFF;
SET IDENTITY_INSERT dbo.Brands ON;
INSERT dbo.Brands(ID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(29,N'بروستو',N'Prosto',1,0),(30,N'علامة اختبار',N'Test brand',1,0);
SET IDENTITY_INSERT dbo.Brands OFF;
SET IDENTITY_INSERT dbo.Branches ON;
INSERT dbo.Branches(ID,BrandID,Title_Ar,Title_En,IsActive,IsDeleted) VALUES(12,29,N'فرع اختبار',N'Test branch',1,0);
SET IDENTITY_INSERT dbo.Branches OFF;
INSERT dbo.UsersMembers(Type,UserName,Password,FullName_Ar,Fullname_En,IsActive,IsDeleted,Gender,Nationality,Employee_Number)
VALUES(4,N'mobile_test',@password,N'Test',N'Test',1,0,1,1,61004);
UPDATE dbo.UsersMembers SET Brand_ID=29,Branch_ID=12 WHERE UserName=N'mobile_test';
INSERT dbo.News(Brand_ID,Title_AR,Title_En,IsActive,IsDeleted,Item_Order,AddedDate) VALUES(29,N'visible',N'visible',1,0,0,GETDATE()),(29,N'inactive',N'inactive',0,0,0,GETDATE()),(29,N'deleted',N'deleted',1,1,0,GETDATE()),(30,N'other-brand',N'other-brand',1,0,0,GETDATE()),(NULL,N'unassigned',N'unassigned',1,0,0,GETDATE());
INSERT dbo.Information_Pages(Title_Ar,Title_En,Summary_Ar,Summary_En,Details_Ar,Details_En,Item_Order,IsPublished,PublishMode,IsDeleted,VersionNumber,CreatedBy,CreatedUtc,AllUserTypes,AccessRevision)
SELECT name,name,N's',N's',N'd',N'd',0,1,'immediate',0,1,1,SYSUTCDATETIME(),allTypes,0
FROM (VALUES('public',1),('employee',0),('other',0),('draft',1),('future',1),('expired',1),('deleted',1),('scheduled',1),('brand_other',1))v(name,allTypes);
INSERT dbo.Information_Page_Brands(PageID,BrandID) SELECT ID,CASE WHEN Title_En='brand_other' THEN 30 ELSE 29 END FROM dbo.Information_Pages;
UPDATE dbo.Information_Pages SET IsPublished=0 WHERE Title_En='draft';
UPDATE dbo.Information_Pages SET IsDeleted=1 WHERE Title_En='deleted';
UPDATE dbo.Information_Pages SET PublishMode='scheduled',StartUtc=DATEADD(day,1,SYSUTCDATETIME()),EndUtc=DATEADD(day,2,SYSUTCDATETIME()) WHERE Title_En='future';
UPDATE dbo.Information_Pages SET PublishMode='scheduled',StartUtc=DATEADD(day,-2,SYSUTCDATETIME()),EndUtc=DATEADD(day,-1,SYSUTCDATETIME()) WHERE Title_En='expired';
UPDATE dbo.Information_Pages SET PublishMode='scheduled',StartUtc=DATEADD(day,-1,SYSUTCDATETIME()),EndUtc=DATEADD(day,1,SYSUTCDATETIME()) WHERE Title_En='scheduled';
INSERT dbo.Information_Page_Roles(PageID,UserTypeID) SELECT ID,CASE WHEN Title_En='employee' THEN 4 ELSE 7 END FROM dbo.Information_Pages WHERE Title_En IN ('employee','other');", new SqlParameter("@password", encrypted));
        var config = new HttpConfiguration(); WebApiConfig.Register(config);
        // Explicitly load the production controller assembly into the in-memory HTTP pipeline.
        config.Services.Replace(typeof(System.Web.Http.Dispatcher.IAssembliesResolver), new ApiAssemblies());
        config.EnsureInitialized();
        client = new HttpClient(new HttpServer(config)) { BaseAddress = new Uri("https://localhost/") };
        Check((await Send("api/Get_user",body:LoginBody(),post:true)).StatusCode==HttpStatusCode.NotFound,"old login route removed");
        Check((await Send("api/ERPController/GetUser",body:new{Username="mobile_test",Password=password},post:true)).StatusCode==HttpStatusCode.NotFound,"legacy employee login endpoint removed");
        Check((await Send("api/v1/devices/requests",body:LoginBody(),post:true)).StatusCode==HttpStatusCode.NotFound,"old device request route removed");
        Check((await Send("http://localhost/api/Users/Login", post:true)).StatusCode == HttpStatusCode.Forbidden, "HTTP login rejected");
        Check((await Send("api/Users/Login", post:true)).StatusCode == HttpStatusCode.BadRequest, "missing login body rejected");
        Check((await Send("api/Users/Login", body:new { Username="mobile_test" }, post:true)).StatusCode == HttpStatusCode.BadRequest, "missing password rejected");
        Check((await Send("api/Users/Login", body:LoginBody("wrong"), post:true)).StatusCode == HttpStatusCode.Unauthorized, "wrong password rejected");
        Check((await News()).StatusCode == HttpStatusCode.Unauthorized, "anonymous news rejected");
        Check((await Send("api/Get_InfoPages", "bad-token")).StatusCode == HttpStatusCode.Unauthorized, "malformed token rejected");
        string token = await Login();
        var omitted=LoginBody(); omitted.Remove("AppBuild"); ((JObject)omitted["Device"]).Remove("Manufacturer"); ((JObject)omitted["Device"]).Remove("MACID");
        var omittedSession=(await Json(await Send("api/Users/Login",body:omitted,post:true)))["Data"]["Session"];
        Check(omittedSession["DeviceManufacturer"]==null && omittedSession["MACID"]==null && omittedSession["AppBuild"]==null,"unsubmitted optional client fields are absent from session response");
        omitted["Device"]["Manufacturer"]=" "; omitted["Device"]["MACID"]=null; omitted["AppBuild"]=" ";
        var blankSession=(await Json(await Send("api/Users/Login",body:omitted,post:true)))["Data"]["Session"];
        Check(blankSession["DeviceManufacturer"]==null && blankSession["MACID"]==null && blankSession["AppBuild"]==null,"blank/null optional client metadata is not returned");
        var stored=StoredSession(token);
        Check((int)stored["EmployeeNumber"]==61004 && (int)stored["UserID"]==(int)Scalar("SELECT ID FROM dbo.UsersMembers WHERE UserName=N'mobile_test'"),"session employee ID and number come from authenticated account");
        Check((string)stored["DeviceID"]=="mobile-test-installation-A" && (string)stored["DevicePlatform"]=="Android" && (string)stored["DeviceModel"]=="Test phone" && (string)stored["DeviceManufacturer"]=="Test manufacturer" && (string)stored["OSVersion"]=="14","device information saved alongside issued token hash");
        Check((string)stored["AppVersion"]=="1.0.0" && (string)stored["AppBuild"]=="100" && (string)stored["MACID"]=="AA:BB:CC:DD:EE:02","app version, build and normalized MAC saved");
        int count=(int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Sessions");
        var invalid=LoginBody();invalid.Remove("Device");
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"device information required for new login");
        invalid=LoginBody();invalid.Remove("AppVersion");
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"app version required");
        invalid=LoginBody();invalid["Device"]["DeviceID"]=" ";
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"blank installation identifier rejected");
        invalid=LoginBody();invalid["Device"]["OSVersion"]=" ";
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"missing nested OS version rejected");
        invalid=LoginBody();invalid["AppVersion"]=new string('a',51);
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"oversized app version rejected without truncation");
        invalid=LoginBody();invalid["Device"]["Platform"]="unsupported";
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"unsupported platform rejected");
        invalid=LoginBody();invalid["Device"]["MACID"]="not-a-mac";
        Check((await Send("api/Users/Login",body:invalid,post:true)).StatusCode==HttpStatusCode.BadRequest,"malformed MAC rejected");
        Check((int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Sessions")==count,"invalid logins do not create sessions");
        var ios=LoginBody();ios["Device"]["Platform"]="ios";ios["Device"]["DeviceID"]="mobile-test-installation-B";ios["Device"]["MACID"]=null;ios["AppVersion"]="2.0.0";
        var blocked=await Send("api/Users/Login",body:ios,post:true);
        Check(blocked.StatusCode==HttpStatusCode.Forbidden && (string)(await Json(blocked))["Error"]["Code"]=="DEVICE_APPROVAL_REQUIRED","second device cannot obtain token without approval");
        Check((int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Sessions")==count,"blocked device creates no session");
        Check((await Send("api/Users/AddNewDevices",body:LoginBody("wrong"),post:true)).StatusCode==HttpStatusCode.Unauthorized,"device request validates password without a bearer token");
        var requestResponse=await Json(await Send("api/Users/AddNewDevices",body:ios,post:true));
        int deviceRequest=(int)requestResponse["Data"]["RequestID"];
        Check((string)requestResponse["Data"]["Status"]=="Pending" && requestResponse["Data"]["AccessToken"]==null,"request creates pending approval without token");
        Check((int)(await Json(await Send("api/Users/AddNewDevices",body:ios,post:true)))["Data"]["RequestID"]==deviceRequest,"duplicate pending request is idempotent");
        Check((string)(await Json(await Send("api/v1/devices/status",body:ios,post:true)))["Data"]["Status"]=="Pending","status is scoped to verified employee and device");
        Sql("INSERT dbo.UsersMembers(Type,UserName,Password,FullName_Ar,IsActive,IsDeleted,Employee_Number) VALUES(1,N'device_admin',N'unused',N'Test admin',1,0,61099)");
        bool refused=false;try{Decide("ApproveAdd",deviceRequest,nonAdmin:true);}catch(SqlException e){refused=e.Number==51711;}
        Check(refused,"non administrator cannot approve devices");
        Decide("ApproveAdd",deviceRequest);
        bool stale=false;try{Decide("ApproveReplace",deviceRequest);}catch(SqlException e){stale=e.Number==51712;}
        Check(stale,"processed request cannot be decided twice");
        var iosResponse=await Json(await Send("api/Users/Login",body:ios,post:true));string iosToken=(string)iosResponse["Data"]["AccessToken"];
        Check(iosToken!=token && (string)StoredSession(iosToken)["DevicePlatform"]=="iOS" && StoredSession(iosToken)["MACID"]==DBNull.Value,"iOS login succeeds with unavailable MAC and distinct token");
        Check((int)iosResponse["Data"]["Session"]["EmployeeNumber"]==61004 && iosResponse["Data"]["Session"]["TokenHash"]==null,"login response supplies device session summary without token hash");
        Check((string)StoredSession(token)["AppVersion"]=="1.0.0" && (string)StoredSession(iosToken)["AppVersion"]=="2.0.0","new device login preserves earlier session snapshot");
        var spoof=LoginBody();spoof["UserID"]=99999;spoof["EmployeeNumber"]=99999;spoof["EmployeeID"]=99999;
        string spoofToken=(string)(await Json(await Send("api/Users/Login",body:spoof,post:true)))["Data"]["AccessToken"];
        Check((int)StoredSession(spoofToken)["EmployeeNumber"]==61004 && (int)StoredSession(spoofToken)["UserID"]!=99999,"caller identity fields cannot spoof saved session employee");
        var hiddenMac=LoginBody();hiddenMac["Device"]["MACID"]="02:00:00:00:00:00";
        string hiddenToken=(string)(await Json(await Send("api/Users/Login",body:hiddenMac,post:true)))["Data"]["AccessToken"];
        Check(StoredSession(hiddenToken)["MACID"]==DBNull.Value,"OS placeholder MAC saved as unavailable rather than real hardware ID");
        await Send("api/Logout",iosToken,post:true);
        Check((await News(iosToken)).StatusCode==HttpStatusCode.Unauthorized && (await News(token)).StatusCode==HttpStatusCode.OK,"logout revokes only its session while another device stays signed in");
        string legacy=Convert.ToBase64String(Guid.NewGuid().ToByteArray().Concat(Guid.NewGuid().ToByteArray()).ToArray()).TrimEnd('=').Replace('+','-').Replace('/','_');
        Sql(@"INSERT dbo.MobileApi_Sessions(TokenHash,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc)
SELECT @legacy,UserID,PasswordFingerprint,CreatedUtc,LastSeenUtc,ExpiresUtc,AbsoluteExpiresUtc FROM dbo.MobileApi_Sessions WHERE TokenHash=@original;",
            new SqlParameter("@legacy",Hash(legacy)),new SqlParameter("@original",Hash(token)));
        Check((await News(legacy)).StatusCode==HttpStatusCode.Unauthorized && StoredSession(legacy)["DeviceID"]==DBNull.Value,"session without approved device cannot bypass policy");
        Sql("UPDATE dbo.UsersMembers SET Employee_Number=61005 WHERE UserName=N'mobile_test'");
        string renumbered=(string)(await Json(await Send("api/Users/Login",body:LoginBody(),post:true)))["Data"]["AccessToken"];
        Check((int)StoredSession(token)["EmployeeNumber"]==61004 && (int)StoredSession(renumbered)["EmployeeNumber"]==61005,"employee number is an immutable snapshot per login");
        Sql("UPDATE dbo.UsersMembers SET Employee_Number=61004 WHERE UserName=N'mobile_test'");
        var news = await Json(await News(token));
        Check((int)news["Count"]==1 && (string)news["Data"][0]["Title_En"]=="visible", "news excludes inactive and deleted records");
        Check(news["Data"][0]["Image"].Type==JTokenType.Null, "empty news image is null");
        Check((int)news["Data"][0]["Brand_ID"]==29,"news explicitly assigned to requested brand");
        Check((await Send("api/Get_News",token,post:true)).StatusCode==HttpStatusCode.BadRequest,"news requires BrandID");
        Check((await Send("api/Get_News?BrandID=29",token,post:true)).StatusCode==HttpStatusCode.BadRequest,"news does not accept URL brand instead of body");
        Check((await Send("api/Get_News",token,new{},true)).StatusCode==HttpStatusCode.BadRequest,"news rejects missing body brand");
        Check((await Send("api/Get_News",token,new{BrandID=29,UserID=1},true)).StatusCode==HttpStatusCode.BadRequest,"news rejects caller identity in body");
        Check((await Send("api/Get_News?BrandID=30",token,new{BrandID=29},true)).StatusCode==HttpStatusCode.OK,"news takes brand from body and ignores conflicting query");
        Check((await Send("api/Get_News?BrandID=29",token)).StatusCode==HttpStatusCode.MethodNotAllowed,"news old GET method no longer supported");
        Check((await News(token,0)).StatusCode==HttpStatusCode.BadRequest,"news rejects nonpositive brand");
        var deniedNews=await Send("api/Get_News?UserID=1",token,new {BrandID=30},true);
        Check(deniedNews.StatusCode==HttpStatusCode.Forbidden&&(string)(await Json(deniedNews))["Error"]["Code"]=="BRAND_ACCESS_DENIED","news denies other brand despite forged user ID");
        Sql("UPDATE dbo.Brands SET IsActive=0 WHERE ID=29");
        Check((await News(token)).StatusCode==HttpStatusCode.Forbidden,"news denies inactive brand");
        Sql("UPDATE dbo.Brands SET IsActive=1 WHERE ID=29");
        try{Sql("DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'mobile_test');EXEC dbo.News_AdminSave @Actor=@actor,@BrandID=29,@Title_AR=N'forbidden';");throw new Exception("Non-admin save accepted");}catch(SqlException ex){Check(ex.Number==51950,"news saving revalidates administrator");}
        try{Sql("DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'device_admin');EXEC dbo.News_AdminSave @Actor=@actor,@BrandID=999,@Title_AR=N'forbidden';");throw new Exception("Invalid brand accepted");}catch(SqlException ex){Check(ex.Number==51951,"news requires available brand in SQL");}
        Sql("DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'device_admin');EXEC dbo.News_AdminSave @Actor=@actor,@BrandID=30,@Title_AR=N'admin-created',@Title_En=N'admin-created';");
        Check((int)(await Json(await News(token)))["Count"]==1,"saving another brand does not leak it to employee");
        Sql("DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'device_admin'),@pid int=(SELECT PID FROM dbo.News WHERE Title_En=N'admin-created');EXEC dbo.News_AdminSave @Actor=@actor,@BrandID=29,@PID=@pid,@Title_AR=N'admin-updated',@Title_En=N'admin-updated';");
        Check((int)(await Json(await News(token)))["Count"]==2,"edited news brand reflected in API");
        Sql("UPDATE dbo.News SET IsActive=0 WHERE Title_En=N'admin-updated'");
        var pages = await Json(await Send("api/Get_InfoPages?UserID=1&UserTypeID=1&Brand_ID=30&BrandID=30", token));
        Check((int)pages["Count"]==3 && pages["Data"].All(p => new[]{"public","employee","scheduled"}.Contains((string)p["Title_En"])), "pages enforce role, publication schedule and deletion; supplied identity ignored");
        var restricted = pages["Data"].Single(p => (string)p["Title_En"]=="employee");
        Check(restricted["UserTypeIDs"].Select(x => (int)x).SequenceEqual(new[]{1,4}), "restricted page effective user type IDs");
        Check(pages["Data"].Single(p => (string)p["Title_En"]=="public")["UserTypeIDs"].Count()==3, "all-types access expanded");
        Check(!pages["Data"].Any(p => (string)p["Title_En"]=="brand_other"), "other-brand page hidden despite forged brand query");
        Sql("UPDATE dbo.UsersMembers SET Brand_ID=30 WHERE UserName=N'mobile_test'");
        Check((await News(token)).StatusCode==HttpStatusCode.Forbidden,"news uses current employee assignment, not login snapshot");
        Check((string)(await Json(await News(token,30)))["Data"][0]["Title_En"]=="other-brand","news follows newly assigned brand without new token");
        Check((int)(await Json(await Send("api/Get_InfoPages",token)))["Count"]==1,"information pages use current brand without rebinding the token");
        Sql("UPDATE dbo.UsersMembers SET Brand_ID=NULL WHERE UserName=N'mobile_test'");
        Check((await News(token)).StatusCode==HttpStatusCode.Forbidden,"brandless employee cannot select arbitrary news brand");
        Check((int)(await Json(await Send("api/Get_InfoPages",token)))["Count"]==0,"brandless employee receives no information pages");
        Sql("UPDATE dbo.UsersMembers SET Brand_ID=29 WHERE UserName=N'mobile_test'");
        ChangeSession(token,"ExpiresUtc=DATEADD(minute,1,SYSUTCDATETIME())");
        news = await Json(await News(token));
        Check((DateTime)news["Session"]["ExpiresAt"]>DateTime.UtcNow.AddHours(7), "activity renews idle expiry");
        ChangeSession(token,"AbsoluteExpiresUtc=DATEADD(minute,2,SYSUTCDATETIME())");
        news = await Json(await News(token));
        Check((DateTime)news["Session"]["ExpiresAt"]==(DateTime)news["Session"]["AbsoluteExpiresAt"], "renewal capped at absolute expiry");
        ChangeSession(token,"ExpiresUtc=DATEADD(second,-1,SYSUTCDATETIME())");
        Check((await News(token)).StatusCode==HttpStatusCode.Unauthorized,"expired session cannot revive");
        token=await Login();
        Sql("UPDATE dbo.UsersMembers SET Type=7 WHERE UserName='mobile_test'");
        Check((await Send("api/Get_InfoPages",token)).StatusCode==HttpStatusCode.Unauthorized,"retired external employee type cannot use employee token");
        Sql("UPDATE dbo.UsersMembers SET IsActive=0 WHERE UserName='mobile_test'");
        Check((await News(token)).StatusCode==HttpStatusCode.Unauthorized,"disabled account session rejected");
        Check((await Send("api/Users/Login",body:LoginBody(),post:true)).StatusCode==HttpStatusCode.Unauthorized,"disabled login rejected");
        Sql("UPDATE dbo.UsersMembers SET IsActive=1,IsDeleted=1 WHERE UserName='mobile_test'");
        Check((await Send("api/Users/Login",body:LoginBody(),post:true)).StatusCode==HttpStatusCode.Unauthorized,"deleted login rejected");
        Sql("UPDATE dbo.UsersMembers SET IsDeleted=0,Type=4 WHERE UserName='mobile_test'");
        token=await Login();
        Sql("UPDATE dbo.UsersMembers SET Password=N'changed' WHERE UserName='mobile_test'");
        Check((await News(token)).StatusCode==HttpStatusCode.Unauthorized,"password change invalidates session");
        Sql("UPDATE dbo.UsersMembers SET Password=@password WHERE UserName='mobile_test'",new SqlParameter("@password",encrypted));
        token=await Login();
        Check((await Send("api/Logout",token,post:true)).StatusCode==HttpStatusCode.OK,"logout succeeds");
        Check((await Send("api/Get_InfoPages",token)).StatusCode==HttpStatusCode.Unauthorized,"logged-out token rejected");
        token=await Login();
        var third=LoginBody();third["Device"]["DeviceID"]="device-C";
        int thirdRequest=(int)(await Json(await Send("api/Users/AddNewDevices",body:third,post:true)))["Data"]["RequestID"];
        Decide("ApproveReplace",thirdRequest);
        Check((await News(token)).StatusCode==HttpStatusCode.Unauthorized && (await Send("api/Users/Login",body:LoginBody(),post:true)).StatusCode==HttpStatusCode.Forbidden,"replace approval revokes old tokens and blocks old devices");
        string thirdToken=(string)(await Json(await Send("api/Users/Login",body:third,post:true)))["Data"]["AccessToken"];
        int thirdDevice=(int)Scalar("SELECT ID FROM dbo.MobileApi_Devices WHERE DeviceID=N'device-C'");
        Decide("Revoke",device:thirdDevice);
        Check((await News(thirdToken)).StatusCode==HttpStatusCode.Unauthorized && (await Send("api/Users/Login",body:third,post:true)).StatusCode==HttpStatusCode.Forbidden,"single device revocation does not reopen enrollment");
        thirdRequest=(int)(await Json(await Send("api/Users/AddNewDevices",body:third,post:true)))["Data"]["RequestID"];
        Decide("Reject",thirdRequest);
        Check((string)(await Json(await Send("api/v1/devices/status",body:third,post:true)))["Data"]["Status"]=="Rejected","rejected request status returned");
        thirdRequest=(int)(await Json(await Send("api/Users/AddNewDevices",body:third,post:true)))["Data"]["RequestID"];
        Decide("ApproveAdd",thirdRequest);
        Check((await News(thirdToken)).StatusCode==HttpStatusCode.Unauthorized,"reapproval never revives previously revoked tokens");
        thirdToken=(string)(await Json(await Send("api/Users/Login",body:third,post:true)))["Data"]["AccessToken"];
        await Send("api/Users/AddNewDevices",body:LoginBody(),post:true);
        Decide("ResetAll");
        Check((await News(thirdToken)).StatusCode==HttpStatusCode.Unauthorized && (int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_DeviceRequests WHERE Status='Pending'")==0,"reset revokes sessions and cancels pending requests");
        var fourth=LoginBody();fourth["Device"]["DeviceID"]="device-D";
        var fifth=LoginBody();fifth["Device"]["DeviceID"]="device-E";
        var races=await Task.WhenAll(Send("api/Users/Login",body:fourth,post:true),Send("api/Users/Login",body:fifth,post:true));
        Check(races.Count(r=>r.StatusCode==HttpStatusCode.OK)==1 && races.Count(r=>r.StatusCode==HttpStatusCode.Forbidden)==1,"concurrent next logins enroll exactly one device");
        Check((int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Devices WHERE IsApproved=1")==1,"reset leaves one approved device after enrollment");
        Check((int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Devices")>=4 && (int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_DeviceHistory WHERE Action='ResetAll'")==1,"devices and decision history retained");
        for(int i=0;i<5;i++){var limited=LoginBody();limited["Device"]["DeviceID"]="pending-limit-"+i;Check((await Send("api/Users/AddNewDevices",body:limited,post:true)).StatusCode==HttpStatusCode.OK,"pending request within limit "+i);}
        var overflow=LoginBody();overflow["Device"]["DeviceID"]="pending-limit-overflow";
        Check((await Send("api/Users/AddNewDevices",body:overflow,post:true)).StatusCode==(HttpStatusCode)429,"new-device pending request limit enforced");
        Check((await Send("api/Users/AddNewDevices",body:third,post:true)).StatusCode==(HttpStatusCode)429,"previously registered device cannot bypass pending request limit");
        overflow["Device"]["DeviceID"]="pending-limit-0";
        Check((await Send("api/Users/AddNewDevices",body:overflow,post:true)).StatusCode==HttpStatusCode.OK,"pending duplicate still succeeds at limit");
        int historyBefore=(int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_DeviceHistory");
        int approvedBefore=(int)Scalar("SELECT ID FROM dbo.MobileApi_Devices WHERE IsApproved=1");
        string migration=System.IO.File.ReadAllText(Environment.GetCommandLineArgs()[1])+Environment.NewLine+System.IO.File.ReadAllText(Environment.GetCommandLineArgs()[2]);
        foreach(string batch in System.Text.RegularExpressions.Regex.Split(migration,@"(?im)^GO\s*$"))
            if(!string.IsNullOrWhiteSpace(batch))Sql(batch);
        Check(historyBefore==(int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_DeviceHistory") && approvedBefore==(int)Scalar("SELECT ID FROM dbo.MobileApi_Devices WHERE IsApproved=1"),"migration replay preserves approvals and decision history");
        await TestBIO();
        if(!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("API_AUDIT_TIMING_DIRECTORY")))await Benchmark();
        Console.WriteLine("TOTAL PASSED: " + checks);
    }
    static async Task Benchmark()
    {
        Sql("INSERT dbo.UsersMembers(Type,UserName,Password,FullName_Ar,Fullname_En,IsActive,IsDeleted,Brand_ID,Gender,Nationality,Employee_Number) VALUES(4,N'perf_test',@password,N'Perf',N'Perf',1,0,29,1,1,69999)",new SqlParameter("@password",new Echo.Encrptor.TripleDesEncryptor().Encrypt(password)));
        var body=LoginBody();body["Username"]="perf_test";body["Device"]["DeviceID"]="isolated-perf-device";
        var tokens=new System.Collections.Generic.List<string>();
        var loginTimes=new System.Collections.Generic.List<double>();var newsTimes=new System.Collections.Generic.List<double>();
        for(int i=0;i<20;i++){var watch=System.Diagnostics.Stopwatch.StartNew();var response=await Send("api/Users/Login",body:body,post:true);loginTimes.Add(watch.Elapsed.TotalMilliseconds);if(response.StatusCode!=HttpStatusCode.OK)throw new Exception("Perf fixture login failed");tokens.Add((string)(await Json(response))["Data"]["AccessToken"]);}
        for(int i=0;i<50;i++){var watch=System.Diagnostics.Stopwatch.StartNew();var response=await News(tokens[i%tokens.Count]);newsTimes.Add(watch.Elapsed.TotalMilliseconds);if(response.StatusCode!=HttpStatusCode.OK)throw new Exception("Perf fixture news failed");}
        var batchWatch=System.Diagnostics.Stopwatch.StartNew();
        var responses=await Task.WhenAll(Enumerable.Range(0,8).Select(i=>News(tokens[i])));
        if(responses.Any(r=>r.StatusCode!=HttpStatusCode.OK))throw new Exception("Concurrent perf fixture news failed");
        Func<System.Collections.Generic.List<double>,object> summarize=a=>{var sorted=a.OrderBy(v=>v).ToArray();return new{Count=sorted.Length,MedianMs=Math.Round(sorted[sorted.Length/2],2),P95Ms=Math.Round(sorted[(int)Math.Ceiling(sorted.Length*.95)-1],2)};};
        System.IO.File.WriteAllText("C:/Projects/ERPProsto/tmp/api-audit/success-benchmark.json",Newtonsoft.Json.JsonConvert.SerializeObject(new{Scope="Successful requests only, isolated SQL fixture, in-memory HTTP; excludes IIS/network/external SMTP and is not a production load test",Login=summarize(loginTimes),News=summarize(newsTimes),EightConcurrentNewsBatchMs=Math.Round(batchWatch.Elapsed.TotalMilliseconds,2)},Newtonsoft.Json.Formatting.Indented));
        Console.WriteLine("PERF: 20 successful logins, 50 sequential and 8 concurrent news reads; synthetic isolated account only.");
    }
    static async Task BioDenied(string bioID,HttpStatusCode status,string code)
    {
        int before=CountSessions();
        var response=await Send("api/Users/LoginViaBIO",body:new{BIOID=bioID},post:true);
        var json=await Json(response);
        if(status==HttpStatusCode.Unauthorized)
            Check(response.Headers.WwwAuthenticate.Single().Scheme=="Basic","BIO errors challenge with Basic, not employee Bearer");
        Check(response.StatusCode==status && (string)json["Error"]["Code"]==code && !string.IsNullOrWhiteSpace((string)json["Error"]["Message"]),"BIO rejects with explained "+code);
        Check(CountSessions()==before,"failed BIO login creates no session: "+code);
    }
    static int CountSessions(){return (int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Sessions");}
    static void BioDecision(string action,int? request=null,int? device=null)
    {
        Sql("DECLARE @actor int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'device_admin'),@user int=(SELECT ID FROM dbo.UsersMembers WHERE UserName=N'bio_user'); EXEC dbo.MobileApi_ManageDevices @Actor=@actor,@UserID=@user,@Action=@action,@RequestID=@request,@DeviceRegistrationID=@device;",new SqlParameter("@action",action),new SqlParameter("@request",(object)request??DBNull.Value),new SqlParameter("@device",(object)device??DBNull.Value));
    }
    static async Task TestBIO()
    {
        string encrypted=new Echo.Encrptor.TripleDesEncryptor().Encrypt(password);
        Sql("INSERT dbo.UsersMembers(Type,UserName,Password,FullName_Ar,Fullname_En,IsActive,IsDeleted,Employee_Number,Brand_ID,Branch_ID) VALUES(4,N'bio_user',@pw,N'BIO Employee',N'BIO Employee',1,0,62001,29,12)",new SqlParameter("@pw",encrypted));
        var body=LoginBody();body["Username"]="bio_user";body["Device"]["DeviceID"]="bio-device-A";
        var initial=(await Json(await Send("api/Users/Login",body:body,post:true)))["Data"];
        string id=(string)initial["User"]["BIOID"],normalToken=(string)initial["AccessToken"];
        Check((int)Scalar("SELECT COUNT(*) FROM dbo.MobileApi_BIOCredentials WHERE BIOHash=@hash",new SqlParameter("@hash",Hash(id)))==1,"BIO credential stored by SHA256 hash only");
        Check((int)Scalar("SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID('dbo.MobileApi_BIOCredentials') AND name='BIOID'")==0,"database has no plaintext BIOID column");
        bioBasic=false;await BioDenied(id,HttpStatusCode.Unauthorized,"BASIC_AUTH_REQUIRED");bioBasic=true;
        bioBasicOverride=Convert.ToBase64String(Encoding.UTF8.GetBytes("synthetic:wrong"));await BioDenied(id,HttpStatusCode.Unauthorized,"BASIC_AUTH_INVALID");
        bioBasicOverride="not-base64!";await BioDenied(id,HttpStatusCode.Unauthorized,"BASIC_AUTH_INVALID");bioBasicOverride=null;
        Check((await Send("http://localhost/api/Users/LoginViaBIO",body:new{BIOID=id},post:true)).StatusCode==HttpStatusCode.Forbidden,"BIO HTTP rejected under HTTPS policy");
        Check((await Send("api/Users/LoginViaBIO",body:new{BIOID=id,Username="bio_user"},post:true)).StatusCode==HttpStatusCode.BadRequest,"BIO body rejects additional fields");
        Check((await Send("api/Users/LoginViaBIO",body:new{BIOID="bad"},post:true)).StatusCode==HttpStatusCode.BadRequest,"BIO rejects malformed secret");
        await BioDenied(Convert.ToBase64String(Guid.NewGuid().ToByteArray().Concat(Guid.NewGuid().ToByteArray()).ToArray()).TrimEnd('=').Replace('+','-').Replace('/','_'),HttpStatusCode.Unauthorized,"BIOID_INVALID");
        var response=await Send("api/Users/LoginViaBIO",body:new{BIOID=id},post:true);var logged=(await Json(response))["Data"];
        Check(response.StatusCode==HttpStatusCode.OK && response.Headers.CacheControl.NoStore,"BIO successful response and no-store");
        Check(JToken.DeepEquals(initial["User"],logged["User"]),"BIO returns identical public employee DTO including BIOID");
        string token=(string)logged["AccessToken"];
        Check(token!=normalToken && (await News(token)).StatusCode==HttpStatusCode.OK,"BIO issues a fresh usable employee Bearer token");
        ChangeSession(normalToken,"ExpiresUtc=DATEADD(second,-1,SYSUTCDATETIME())");
        Check((await Send("api/Users/LoginViaBIO",body:new{BIOID=id},post:true)).StatusCode==HttpStatusCode.OK,"BIO login remains available after source access token expires");
        Check((string)logged["Session"]["DeviceID"]=="bio-device-A" && (string)logged["Session"]["MACID"]=="AA:BB:CC:DD:EE:02","BIO reuses only previously submitted device snapshot");
        Sql("UPDATE dbo.UsersMembers SET IsActive=0 WHERE UserName='bio_user'");await BioDenied(id,HttpStatusCode.Forbidden,"ACCOUNT_INACTIVE");
        Sql("UPDATE dbo.UsersMembers SET IsActive=1,IsDeleted=1 WHERE UserName='bio_user'");await BioDenied(id,HttpStatusCode.Forbidden,"ACCOUNT_DELETED");
        Sql("UPDATE dbo.UsersMembers SET IsDeleted=0,Type=7 WHERE UserName='bio_user'");await BioDenied(id,HttpStatusCode.Forbidden,"ACCOUNT_TYPE_NOT_ALLOWED");
        Sql("UPDATE dbo.UsersMembers SET Type=4,Password=N'changed' WHERE UserName='bio_user'");await BioDenied(id,HttpStatusCode.Unauthorized,"PASSWORD_CHANGED");
        Sql("UPDATE dbo.UsersMembers SET Password=@pw WHERE UserName='bio_user'",new SqlParameter("@pw",encrypted));
        Sql("UPDATE dbo.MobileApi_BIOCredentials SET ExpiresUtc=DATEADD(second,-1,SYSUTCDATETIME()) WHERE BIOHash=@hash",new SqlParameter("@hash",Hash(id)));await BioDenied(id,HttpStatusCode.Unauthorized,"BIOID_EXPIRED");
        Sql("UPDATE dbo.MobileApi_BIOCredentials SET ExpiresUtc=DATEADD(day,1,SYSUTCDATETIME()) WHERE BIOHash=@hash",new SqlParameter("@hash",Hash(id)));
        var rotated=(await Json(await Send("api/Users/Login",body:body,post:true)))["Data"];
        Check((string)rotated["User"]["BIOID"]!=id,"password login rotates BIOID on that device");await BioDenied(id,HttpStatusCode.Unauthorized,"BIOID_INVALID");id=(string)rotated["User"]["BIOID"];
        int device=(int)Scalar("SELECT ID FROM dbo.MobileApi_Devices WHERE DeviceID=N'bio-device-A'");
        BioDecision("Revoke",device:device);await BioDenied(id,HttpStatusCode.Forbidden,"DEVICE_NOT_APPROVED");
        Check((await News(token)).StatusCode==HttpStatusCode.Unauthorized,"revoking device also invalidates BIO-issued token");
        int request=(int)(await Json(await Send("api/Users/AddNewDevices",body:body,post:true)))["Data"]["RequestID"];
        BioDecision("ApproveAdd",request:request);await BioDenied(id,HttpStatusCode.Unauthorized,"BIOID_REVOKED");
        id=(string)(await Json(await Send("api/Users/Login",body:body,post:true)))["Data"]["User"]["BIOID"];
        var second=(JObject)body.DeepClone();second["Device"]["DeviceID"]="bio-device-B";((JObject)second["Device"]).Remove("Manufacturer");((JObject)second["Device"]).Remove("MACID");second.Remove("AppBuild");
        Check((await Send("api/Users/Login",body:second,post:true)).StatusCode==HttpStatusCode.Forbidden,"BIO enrollment cannot bypass second-device approval");
        request=(int)(await Json(await Send("api/Users/AddNewDevices",body:second,post:true)))["Data"]["RequestID"];BioDecision("ApproveAdd",request:request);
        string other=(string)(await Json(await Send("api/Users/Login",body:second,post:true)))["Data"]["User"]["BIOID"];
        Check(other!=id,"each employee/device gets its own BIOID");
        var secondLogin=(await Json(await Send("api/Users/LoginViaBIO",body:new{BIOID=other},post:true)))["Data"];
        Check((string)secondLogin["Session"]["DeviceID"]=="bio-device-B" && secondLogin["Session"]["MACID"]==null && secondLogin["Session"]["DeviceManufacturer"]==null,"BIO binds its own device and omits unsubmitted optional fields");
        var simultaneous=await Task.WhenAll(Send("api/Users/LoginViaBIO",body:new{BIOID=other},post:true),Send("api/Users/LoginViaBIO",body:new{BIOID=other},post:true));
        Check(simultaneous.All(x=>x.IsSuccessStatusCode),"concurrent BIO logins are serialized and both valid");
        BioDecision("ResetAll");await BioDenied(id,HttpStatusCode.Forbidden,"DEVICE_NOT_APPROVED");await BioDenied(other,HttpStatusCode.Forbidden,"DEVICE_NOT_APPROVED");
        await Send("api/Users/Login",body:body,post:true);await BioDenied(id,HttpStatusCode.Unauthorized,"BIOID_INVALID");
    }
    static int Main() { try { Run().GetAwaiter().GetResult(); ApiPerformanceProbe.Save("mobile"); return 0; } catch(Exception ex) { Console.WriteLine(ex); return 1; } }
    class ApiAssemblies : System.Web.Http.Dispatcher.DefaultAssembliesResolver
    {
        public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies()
        { return new[]{typeof(WebApiConfig).Assembly}; }
    }
}
