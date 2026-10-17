using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Dispatcher;
using Newtonsoft.Json.Linq;
using Prosto_ERP_API;
using Prosto_ERP_API.Controllers;
using Prosto_ERP_ClassLibrary;
class EmailTests
{
 static int checks,sends;static HttpClient client;static AttendanceIntegration store;static Exception failure;
 static string sender,recipient,html,subject,credential,display;
 static void Check(bool ok,string name){if(!ok)throw new Exception("FAIL: "+name);checks++;Console.WriteLine("PASS: "+name);}
 static SqlParameter P(string n,object v){return new SqlParameter(n,v??DBNull.Value);}
 static DataTable Query(string p,params SqlParameter[] args){return store.Query(p,args);}
 static byte[] Version(int brand){return (byte[])Query("dbo.EmailNotification_Admin",P("@Actor",1),P("@BrandID",brand)).Rows[0]["Version"];}
 static void Save(int brand,string email,string pw,bool enabled,byte[] version=null,int actor=1){Query("dbo.EmailNotification_Save",P("@Actor",actor),P("@BrandID",brand),P("@SenderEmail",email),new SqlParameter("@AppPassword",SqlDbType.VarBinary,-1){Value=pw==null?(object)DBNull.Value:AttendanceIntegration.Protect(pw)},P("@Enabled",enabled),new SqlParameter("@Version",SqlDbType.Binary,8){Value=(object)version??DBNull.Value});}
 static void Denied(Action action,int code){try{action();throw new Exception("SQL call should fail");}catch(SqlException ex){Check(ex.Number==code,"SQL rejection "+code);}}
 static JObject Body(int brand=1){return JObject.FromObject(new{BrandID=brand,To="recipient@example.test",Subject="عنوان تجريبي",Body="<p dir=\"rtl\">رسالة تجريبية</p>"});}
 static async Task<HttpResponseMessage> Send(JObject body,bool auth=true,string supplied=null,string scheme="Basic",string url="https://localhost/api/EmailNotification/Send"){
  var request=new HttpRequestMessage(HttpMethod.Post,url);if(auth)request.Headers.Authorization=new AuthenticationHeaderValue(scheme,supplied??Environment.GetEnvironmentVariable("EMAIL_TEST_BASIC"));
  request.Content=new StringContent(body.ToString(),System.Text.Encoding.UTF8,"application/json");return await client.SendAsync(request);
 }
 static async Task Error(JObject body,HttpStatusCode status,string code,bool auth=true,string supplied=null,string scheme="Basic",string url="https://localhost/api/EmailNotification/Send"){
  int before=sends;var response=await Send(body,auth,supplied,scheme,url);var json=JObject.Parse(await response.Content.ReadAsStringAsync());
  Check(response.StatusCode==status&&(string)json["Error"]["Code"]==code&&!string.IsNullOrWhiteSpace((string)json["Error"]["Message"]),"API explains "+code);
  if(code.StartsWith("SMTP_")&&code!="SMTP_NOT_CONFIGURED"&&code!="SMTP_CONFIG_DECRYPTION_ERROR")Check(sends==before+1,"single SMTP attempt without retries");else Check(sends==before,"rejection makes no SMTP attempt");
  Check(response.Headers.CacheControl.NoStore&&!json.ToString().Contains("synthetic-app-secret"),"errors do not cache or leak credentials");
 }
 static Task Fake(MailMessage message,NetworkCredential creds){sends++;sender=message.From.Address;recipient=message.To.Single().Address;html=message.Body;subject=message.Subject;credential=creds.Password;display=message.From.DisplayName;
  Check(message.IsBodyHtml&&message.BodyEncoding.WebName=="utf-8"&&message.SubjectEncoding.WebName=="utf-8","HTML and UTF8 used");
  Check(message.CC.Count==0&&message.Bcc.Count==0,"exactly requested recipient only");
  using(var mime=MimeKit.MimeMessage.CreateFromMailMessage(message)) {
   Check(mime.HtmlBody==message.Body&&mime.Subject==message.Subject&&mime.From.Mailboxes.Single().Address==message.From.Address&&mime.To.Mailboxes.Single().Address==message.To.Single().Address,"MailKit MIME conversion preserves HTML subject sender and recipient");
  }
  if(failure!=null)return Task.FromException(failure);return Task.CompletedTask;
 }
 static async Task Run(){
  store=new AttendanceIntegration(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
  Denied(()=>Save(1,"brand-one@example.test","synthetic-app-secret-one",true,null,2),51800);
  Denied(()=>Query("dbo.EmailNotification_AdminSecret",P("@Actor",2),P("@BrandID",1)),51800);
  Denied(()=>Query("dbo.EmailNotification_AdminSecret",P("@Actor",4),P("@BrandID",1)),51800);
  Denied(()=>Save(3,"inactive@example.test","synthetic-app-secret",true),51803);
  Save(1,"brand-one@example.test","synthetic-app-secret-one",true);
  Save(2,"brand-two@example.test","synthetic-app-secret-two",true);
  var meta=Query("dbo.EmailNotification_Admin",P("@Actor",1),P("@BrandID",1));Check(!meta.Columns.Contains("AppPassword")&&(bool)meta.Rows[0]["HasPassword"],"settings metadata hides secret");
  var version=Version(1);Save(1,"brand-one@example.test",null,true,version);Denied(()=>Save(1,"brand-one@example.test",null,true,version),51802);
  var secret=(byte[])Query("dbo.EmailNotification_AdminSecret",P("@Actor",1),P("@BrandID",1)).Rows[0]["AppPassword"];
  Check(AttendanceIntegration.Unprotect(secret)=="synthetic-app-secret-one","blank edit preserves encrypted app password");
  Denied(()=>Save(1,"changed@example.test",null,true,Version(1)),51801);
  var config=new HttpConfiguration();WebApiConfig.Register(config);config.Services.Replace(typeof(IAssembliesResolver),new Assemblies());config.Services.Replace(typeof(IHttpControllerActivator),new Activator());config.EnsureInitialized();client=new HttpClient(new HttpServer(config));
  await Error(Body(),HttpStatusCode.Unauthorized,"BASIC_AUTH_REQUIRED",false);
  await Error(Body(),HttpStatusCode.Unauthorized,"BASIC_AUTH_REQUIRED",true,null,"Bearer");
  await Error(Body(),HttpStatusCode.Unauthorized,"BASIC_AUTH_INVALID",true,"bad-base64!");
  await Error(Body(),HttpStatusCode.Unauthorized,"BASIC_AUTH_INVALID",true,Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes("synthetic:wrong")));
  await Error(Body(),HttpStatusCode.Forbidden,"HTTPS_REQUIRED",true,null,"Basic","http://localhost/api/EmailNotification/Send");
  var invalid=Body(0);await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["To"]="a@example.test,b@example.test";await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["To"]="Display <a@example.test>";await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["Subject"]="subject\r\nBcc:other@example.test";await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["From"]="spoof@example.test";await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["Body"]=" ";await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  invalid=Body();invalid["Body"]=new string('x',200001);await Error(invalid,HttpStatusCode.BadRequest,"INVALID_REQUEST");
  await Error(Body(3),HttpStatusCode.Forbidden,"BRAND_UNAVAILABLE");await Error(Body(4),HttpStatusCode.ServiceUnavailable,"SMTP_NOT_CONFIGURED");
  var response=await Send(Body());var data=JObject.Parse(await response.Content.ReadAsStringAsync());Check(response.IsSuccessStatusCode&&(bool)data["Success"]&&(string)data["Data"]["Status"]=="Submitted"&&response.Headers.CacheControl.NoStore,"SMTP acceptance succeeds with no-store");
  Check(sender=="brand-one@example.test"&&credential=="synthetic-app-secret-one"&&display=="العلامة الأولى","first brand uses own configured Gmail identity");
  Check(recipient=="recipient@example.test"&&subject=="عنوان تجريبي"&&html=="<p dir=\"rtl\">رسالة تجريبية</p>","subject HTML and recipient preserved");
  response=await Send(Body(2));Check(response.IsSuccessStatusCode&&sender=="brand-two@example.test"&&credential=="synthetic-app-secret-two","second brand isolated sender and credentials");
  Save(1,"brand-one@example.test",null,false,Version(1));await Error(Body(),HttpStatusCode.Forbidden,"EMAIL_DISABLED");Save(1,"brand-one@example.test",null,true,Version(1));
  failure=new SmtpException((SmtpStatusCode)535,"synthetic-app-secret MUST NOT LEAK");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_AUTH_FAILED");
  failure=new SmtpFailedRecipientException(SmtpStatusCode.MailboxUnavailable,"recipient@example.test","synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_RECIPIENT_REJECTED");
  failure=new SmtpException(SmtpStatusCode.ServiceNotAvailable,"synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_SEND_FAILED");
  failure=new MailKit.Security.AuthenticationException("synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_AUTH_FAILED");
  failure=new MailKit.Security.SslHandshakeException("synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_TLS_FAILED");
  failure=new MailKit.Net.Smtp.SmtpCommandException(MailKit.Net.Smtp.SmtpErrorCode.RecipientNotAccepted,MailKit.Net.Smtp.SmtpStatusCode.MailboxUnavailable,"synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_RECIPIENT_REJECTED");
  failure=new MailKit.Net.Smtp.SmtpCommandException(MailKit.Net.Smtp.SmtpErrorCode.UnexpectedStatusCode,(MailKit.Net.Smtp.SmtpStatusCode)535,"synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_AUTH_FAILED");
  failure=new System.IO.IOException("synthetic-app-secret");await Error(Body(),HttpStatusCode.BadGateway,"SMTP_CONNECTION_FAILED");
  failure=new System.Net.Sockets.SocketException((int)System.Net.Sockets.SocketError.HostNotFound);await Error(Body(),HttpStatusCode.BadGateway,"SMTP_CONNECTION_FAILED");
  failure=new OperationCanceledException("synthetic-app-secret");await Error(Body(),HttpStatusCode.GatewayTimeout,"SMTP_TIMEOUT");
  failure=new TimeoutException();await Error(Body(),HttpStatusCode.GatewayTimeout,"SMTP_TIMEOUT");
  failure=new Exception("synthetic-app-secret");int before=sends;var generic=await Send(Body());var error=JObject.Parse(await generic.Content.ReadAsStringAsync());Check(generic.StatusCode==HttpStatusCode.InternalServerError&&(string)error["Error"]["Code"]=="EMAIL_SEND_FAILED"&&sends==before+1&&!error.ToString().Contains("synthetic-app-secret"),"unexpected errors sanitized");
  Console.WriteLine("EMAIL CHECKS PASSED: "+checks+"; all SMTP operations simulated, no email delivered.");
 }
 static int Main(){try{Run().GetAwaiter().GetResult();return 0;}catch(Exception ex){Console.WriteLine(ex);return 1;}}
 class Assemblies:DefaultAssembliesResolver{public override System.Collections.Generic.ICollection<System.Reflection.Assembly> GetAssemblies(){return new[]{typeof(WebApiConfig).Assembly};}}
 class Activator:IHttpControllerActivator{public IHttpController Create(HttpRequestMessage request,HttpControllerDescriptor descriptor,Type type){return new EmailNotificationController(store,Fake);}}
}
