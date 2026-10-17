using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Mail;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Dispatcher;
using System.Web;
using System.Web.SessionState;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;
using Prosto_ERP_API.Mobile;
using Prosto_ERP_ClassLibrary;
class ResetTests {
 static int checks,sends;static string otp,recipient,body;static bool fail;static HttpClient client;static AttendanceIntegration db;static PasswordResetService service;
 static void Check(bool ok,string name){if(!ok)throw new Exception("FAIL: "+name);checks++;Console.WriteLine("PASS: "+name);}
 static void SQL(string sql){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString)){cn.Open();using(var cmd=new SqlCommand(sql,cn))cmd.ExecuteNonQuery();}}
 static object Scalar(string sql){using(var cn=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString)){cn.Open();using(var cmd=new SqlCommand(sql,cn))return cmd.ExecuteScalar();}}
 static Task Fake(MailMessage mail,NetworkCredential credential){sends++;recipient=mail.To.Single().Address;body=mail.Body;otp=Regex.Match(body,"letter-spacing:8px'>([0-9]{6})").Groups[1].Value;Check(mail.IsBodyHtml&&mail.SubjectEncoding.WebName=="utf-8"&&otp.Length==6,"branded HTML contains six-digit OTP");Check(credential.Password=="synthetic-app-secret"&&mail.From.Address=="sender@example.test","uses selected brand SMTP credentials");return fail?Task.FromException(new TimeoutException()):Task.CompletedTask;}
 static async Task<JObject> Call(string route,object payload,HttpStatusCode status=HttpStatusCode.OK,bool auth=true,string scheme="Basic",string url="https://localhost/"){
  var request=new HttpRequestMessage(HttpMethod.Post,url+"api/Users/"+route);if(auth)request.Headers.Authorization=new AuthenticationHeaderValue(scheme,Environment.GetEnvironmentVariable("EMAIL_TEST_BASIC"));request.Content=new StringContent(Newtonsoft.Json.JsonConvert.SerializeObject(payload),System.Text.Encoding.UTF8,"application/json");var response=await client.SendAsync(request);var json=JObject.Parse(await response.Content.ReadAsStringAsync());if(response.StatusCode!=status)Console.WriteLine("Unexpected response status="+response.StatusCode+", error="+json["Error"]);Check(response.StatusCode==status,"HTTP "+route+" "+status);Check(response.Headers.CacheControl.NoStore,"no-store "+route);Check(!json.ToString().Contains("synthetic-app-secret"),"secret not leaked");return json;
 }
 static async Task<JObject> Request(int employee=100,HttpStatusCode status=HttpStatusCode.OK){return await Call("RequestPasswordReset",new{EmployeeNumber=employee},status);}
 static object Verify(string id,string code){return new{ChallengeID=id,OTP=code};}
 static async Task<string> Validated(){var request=await Request();var id=(string)request["Data"]["ChallengeID"];var code=otp;var verified=await Call("VerifyPasswordResetOTP",Verify(id,code));return (string)verified["Data"]["ResetToken"];}
 static void Age(){SQL("UPDATE dbo.PasswordReset_Challenges SET CreatedUtc=DATEADD(hour,-2,SYSUTCDATETIME())");}
 static HttpContext PortalContext(){var context=new HttpContext(new HttpRequest("","https://localhost/ForgotPassword.aspx",""),new HttpResponse(new System.IO.StringWriter()));SessionStateUtility.AddHttpSessionStateToContext(context,new HttpSessionStateContainer(Guid.NewGuid().ToString(),new SessionStateItemCollection(),new HttpStaticObjectsCollection(),20,true,HttpCookieMode.UseCookies,SessionStateMode.InProc,false));return context;}
 static async Task Run(){
  db=new AttendanceIntegration(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);service=new PasswordResetService(db,Fake);
  var password=new Echo.Encrptor.TripleDesEncryptor().Encrypt("OldPassword100!");
  SQL("UPDATE dbo.UsersMembers SET Password=N'"+password.Replace("'","''")+"' WHERE ID=1");
  var portal=PortalContext();HttpContext.Current=portal;
  CRM.SessionManager.GetInstance.Users=new CRM.UserEntity{UserID=1,UserType=1,Password=password};
  Check(CRM.SessionManager.GetInstance.Users!=null,"Portal session works before reset");
  var legacy=PortalContext();legacy.Session["UserSessionObject"]=new CRM.UserEntity{UserID=1,UserType=1};
  HttpContext.Current=null;
  db.Query("dbo.EmailNotification_Save",new SqlParameter("@Actor",1),new SqlParameter("@BrandID",1),new SqlParameter("@SenderEmail","sender@example.test"),new SqlParameter("@AppPassword",SqlDbType.VarBinary,-1){Value=AttendanceIntegration.Protect("synthetic-app-secret")},new SqlParameter("@Enabled",true),new SqlParameter("@Version",SqlDbType.Binary,8){Value=DBNull.Value});
  var config=new HttpConfiguration();WebApiConfig.Register(config);config.Services.Replace(typeof(IAssembliesResolver),new Assemblies());config.Services.Replace(typeof(IHttpControllerActivator),new Activator());config.EnsureInitialized();client=new HttpClient(new HttpServer(config));
  await Call("RequestPasswordReset",new{EmployeeNumber=100},HttpStatusCode.Unauthorized,false);
  await Call("RequestPasswordReset",new{EmployeeNumber=100},HttpStatusCode.Unauthorized,true,"Bearer");
  await Call("RequestPasswordReset",new{EmployeeNumber=100},HttpStatusCode.Forbidden,true,"Basic","http://localhost/");
  await Call("VerifyPasswordResetOTP",Verify(Guid.NewGuid().ToString(),"123456"),HttpStatusCode.Unauthorized,false);
  await Call("ResetPassword",new{ResetToken=new string('a',43),NewPassword="NewPassword!"},HttpStatusCode.Unauthorized,false);
  await Call("RequestPasswordReset",new{EmployeeNumber=100,To="attacker@example.test"},HttpStatusCode.BadRequest);
  await Request(0,HttpStatusCode.BadRequest);
  var missing=await Request(999,HttpStatusCode.BadRequest);Check((string)missing["Error"]["Code"]=="ACCOUNT_UNAVAILABLE","unavailable account explained");
  var noEmail=await Request(101,HttpStatusCode.BadRequest);Check((string)noEmail["Error"]["Code"]=="EMAIL_NOT_REGISTERED","missing email explained");
  var request=await Request();var id=(string)request["Data"]["ChallengeID"];var code=otp;
  Check(recipient=="employee@example.test"&&(string)request["Data"]["MaskedEmail"]=="***ee@example.test"&&!request.ToString().Contains(code),"recipient from database and only masked email returned");
  Check(body.Contains("&lt;script&gt;")&&!body.Contains("<script>"),"HTML encodes database names");
  var limited=await Request(100,(HttpStatusCode)429);Check((string)limited["Error"]["Code"]=="RESET_RATE_LIMITED","resend cooldown enforced");
  for(int i=0;i<5;i++){var invalid=await Call("VerifyPasswordResetOTP",Verify(id,code=="000000"?"000001":"000000"),HttpStatusCode.BadRequest);Check((string)invalid["Error"]["Code"]=="OTP_INVALID","failed OTP attempt committed");}
  var locked=await Call("VerifyPasswordResetOTP",Verify(id,code),HttpStatusCode.BadRequest);Check((string)locked["Error"]["Code"]=="OTP_UNAVAILABLE","five attempts block correct OTP");
  Age();request=await Request();id=(string)request["Data"]["ChallengeID"];code=otp;
  SQL("UPDATE dbo.PasswordReset_Challenges SET ExpiresUtc=DATEADD(second,-1,SYSUTCDATETIME())");await Call("VerifyPasswordResetOTP",Verify(id,code),HttpStatusCode.BadRequest);
  Age();request=await Request();id=(string)request["Data"]["ChallengeID"];code=otp;
  Age();var newer=await Request();await Call("VerifyPasswordResetOTP",Verify(id,code),HttpStatusCode.BadRequest);
  SQL("UPDATE dbo.UsersMembers SET Email='changed@example.test' WHERE ID=1");await Call("VerifyPasswordResetOTP",Verify((string)newer["Data"]["ChallengeID"],otp),HttpStatusCode.BadRequest);SQL("UPDATE dbo.UsersMembers SET Email='employee@example.test' WHERE ID=1");
  Age();fail=true;var failed=await Request(100,HttpStatusCode.GatewayTimeout);Check((string)failed["Error"]["Code"]=="SMTP_TIMEOUT","failed delivery not reported as sent");Check(Convert.ToInt32(Scalar("SELECT COUNT(*) FROM dbo.PasswordReset_Challenges WHERE UserID=1 AND Sent=0 AND Invalidated=1"))>0,"failed delivery invalidated");fail=false;
  Age();request=await Request();id=(string)request["Data"]["ChallengeID"];code=otp;
  var verified=await Call("VerifyPasswordResetOTP",Verify(id,code));var token=(string)verified["Data"]["ResetToken"];Check(token.Length==43,"random reset permission issued");
  await Call("VerifyPasswordResetOTP",Verify(id,code),HttpStatusCode.BadRequest);
  await Call("ResetPassword",new{ResetToken=token,NewPassword="short"},HttpStatusCode.BadRequest);
  SQL("UPDATE dbo.PasswordReset_Challenges SET ResetExpiresUtc=DATEADD(second,-1,SYSUTCDATETIME())");await Call("ResetPassword",new{ResetToken=token,NewPassword="NewPassword100!"},HttpStatusCode.BadRequest);
  Age();token=await Validated();SQL("INSERT dbo.MobileApi_Sessions(UserID) VALUES(1);INSERT dbo.MobileApi_BIOCredentials(UserID) VALUES(1)");
  var changed=await Call("ResetPassword",new{ResetToken=token,NewPassword="NewPassword100!"});Check((bool)changed["Data"]["PasswordChanged"],"password reset succeeded");
  Check((string)Scalar("SELECT Password FROM dbo.UsersMembers WHERE ID=1")==new Echo.Encrptor.TripleDesEncryptor().Encrypt("NewPassword100!"),"password uses current encryption contract");
  Check(Convert.ToInt32(Scalar("SELECT COUNT(*) FROM dbo.MobileApi_Sessions WHERE RevokedUtc IS NULL"))==0&&Convert.ToInt32(Scalar("SELECT COUNT(*) FROM dbo.MobileApi_BIOCredentials"))==0,"mobile sessions and BIO credentials invalidated");
  Check(Convert.ToInt64(Scalar("SELECT Epoch FROM dbo.PasswordReset_AccountEpoch WHERE UserID=1"))==1,"Portal reset epoch advanced");
  portal.Items.Remove("EmployeeResetChecked:1");HttpContext.Current=portal;Check(CRM.SessionManager.GetInstance.Users==null,"Portal session invalidated after reset");
  HttpContext.Current=legacy;Check(CRM.SessionManager.GetInstance.Users==null,"pre-feature Portal session invalidated after reset");
  var fresh=PortalContext();HttpContext.Current=fresh;CRM.SessionManager.GetInstance.Users=new CRM.UserEntity{UserID=1,UserType=1,Password=new Echo.Encrptor.TripleDesEncryptor().Encrypt("NewPassword100!")};Check(CRM.SessionManager.GetInstance.Users!=null,"new Portal login works after reset");
  var race=PortalContext();HttpContext.Current=race;CRM.SessionManager.GetInstance.Users=new CRM.UserEntity{UserID=1,UserType=1,Password=password};Check(CRM.SessionManager.GetInstance.Users==null,"stale password login cannot capture reset epoch and survive");
  HttpContext.Current=null;
  await Call("ResetPassword",new{ResetToken=token,NewPassword="AnotherPassword!"},HttpStatusCode.BadRequest);
  Age();token=await Validated();SQL("UPDATE dbo.UsersMembers SET IsActive=0 WHERE ID=1");await Call("ResetPassword",new{ResetToken=token,NewPassword="AnotherPassword!"},HttpStatusCode.BadRequest);SQL("UPDATE dbo.UsersMembers SET IsActive=1 WHERE ID=1");
  Age();token=await Validated();SQL("UPDATE dbo.UsersMembers SET Password='changed' WHERE ID=1");await Call("ResetPassword",new{ResetToken=token,NewPassword="AnotherPassword!"},HttpStatusCode.BadRequest);
  Check(Convert.ToInt32(Scalar("SELECT COUNT(*) FROM dbo.PasswordReset_Challenges WHERE UserID=1 AND OtpHash IS NULL"))==0,"OTP hashes persisted without plaintext");
  Age();SQL("DECLARE @Source binary(32)=(SELECT TOP(1) SourceHash FROM dbo.PasswordReset_Challenges WHERE EmployeeNumber=100); INSERT dbo.PasswordReset_Challenges(ID,EmployeeNumber,SourceHash,OtpHash,CreatedUtc,ExpiresUtc) SELECT TOP(5) NEWID(),100,@Source,0x00,DATEADD(minute,-5,SYSUTCDATETIME()),SYSUTCDATETIME() FROM dbo.PasswordReset_Challenges;");
  var hourly=await Request(100,(HttpStatusCode)429);Check((string)hourly["Error"]["Code"]=="RESET_RATE_LIMITED","five requests per employee per hour enforced");
  Age();SQL("DECLARE @Source binary(32)=(SELECT TOP(1) SourceHash FROM dbo.PasswordReset_Challenges WHERE EmployeeNumber=100),@i int=0;WHILE @i<30 BEGIN INSERT dbo.PasswordReset_Challenges(ID,EmployeeNumber,SourceHash,OtpHash,CreatedUtc,ExpiresUtc) VALUES(NEWID(),200+@i,@Source,0x00,DATEADD(minute,-5,SYSUTCDATETIME()),SYSUTCDATETIME());SET @i=@i+1;END;");
  var sourceLimit=await Request(500,(HttpStatusCode)429);Check((string)sourceLimit["Error"]["Code"]=="RESET_RATE_LIMITED","client request limit includes unavailable numbers");
  Console.WriteLine("PASSWORD RESET CHECKS PASSED: "+checks+"; SMTP simulated; no email sent.");
 }
 static int Main(){try{Run().GetAwaiter().GetResult();return 0;}catch(Exception ex){Console.WriteLine(ex);return 1;}}
 class Assemblies:DefaultAssembliesResolver{public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}}
 class Activator:IHttpControllerActivator{public IHttpController Create(HttpRequestMessage request,HttpControllerDescriptor descriptor,Type type){return new UsersController(service);}}
}
