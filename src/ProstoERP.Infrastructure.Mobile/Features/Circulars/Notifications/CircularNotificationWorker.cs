using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using System.Web.Hosting;
using Prosto_ERP_ClassLibrary;

namespace Prosto_ERP_API.Notifications
{
 // SQL is the durable queue. App-pool shutdown never silently retries an uncertain SMTP submission.
 public sealed class CircularNotificationWorker : IRegisteredObject
 {
  static CircularNotificationWorker instance;
  readonly Timer timer;
  readonly CancellationTokenSource stopping = new CancellationTokenSource();
  int running;
  public static void Start()
  {
   if (!string.Equals(ConfigurationManager.AppSettings["CircularNotifications.Enabled"], "true", StringComparison.OrdinalIgnoreCase)) return;
   if (instance == null) instance = new CircularNotificationWorker();
  }
  CircularNotificationWorker()
  {
   HostingEnvironment.RegisterObject(this);
   timer = new Timer(Tick, null, TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(30));
  }
  async void Tick(object state)
  {
   if (stopping.IsCancellationRequested || Interlocked.Exchange(ref running, 1) != 0) return;
   try
   {
    using (var cn = new SqlConnection(Connection))
    using (var cmd = new SqlCommand("SELECT CASE WHEN OBJECT_ID('dbo.Circular_Mail','U') IS NULL THEN 0 ELSE 1 END",cn))
    { await cn.OpenAsync(stopping.Token); if (Convert.ToInt32(await cmd.ExecuteScalarAsync(stopping.Token)) == 0) return; }
    await ProcessBatch(BrandEmailSender.SendGmail, stopping.Token);
   }
   catch (OperationCanceledException) { }
   catch (Exception e) { System.Diagnostics.Trace.TraceWarning("Circular notification worker: {0}", e.GetType().Name); }
   finally { Interlocked.Exchange(ref running, 0); }
  }
  static string Connection { get { return ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString; } }
  static DataTable Query(string name,params SqlParameter[] parameters)
  {
   using(var cn=new SqlConnection(Connection)) using(var cmd=new SqlCommand(name,cn))
   {cmd.CommandType=CommandType.StoredProcedure;cmd.Parameters.AddRange(parameters);cmd.CommandTimeout=60;cn.Open();var table=new DataTable();using(var reader=cmd.ExecuteReader()){if(reader.FieldCount>0)table.Load(reader);}return table;}
  }
  internal static async Task ProcessBatch(Func<MailMessage,NetworkCredential,Task> send,CancellationToken cancellation)
  {
   Query("dbo.Circular_Dispatch");
   var store=new AttendanceIntegration(Connection);
   for(int i=0;i<25&&!cancellation.IsCancellationRequested;i++)
   {
    var claim=Query("dbo.Circular_MailClaim");if(claim.Rows.Count==0)return;
    var row=claim.Rows[0];var status="failed";var code="MAIL_PREPARATION_FAILED";bool sending=false;
    try
    {
     string to=Convert.ToString(row["Email"]);
     if(!BareEmail(to)){code="MISSING_RECIPIENT_EMAIL";continue;}
     var settings=store.Query("dbo.EmailNotification_Credentials",new SqlParameter("@BrandID",row["BrandID"]));
     if(settings.Rows.Count!=1||!(bool)settings.Rows[0]["Enabled"]||settings.Rows[0].IsNull("AppPassword")){code="BRAND_EMAIL_NOT_CONFIGURED";continue;}
     var setting=settings.Rows[0];var sender=Convert.ToString(setting["SenderEmail"]);
     if(!BareEmail(sender)){code="INVALID_SENDER_EMAIL";continue;}
     Uri origin;
     if(!Uri.TryCreate(ConfigurationManager.AppSettings["CircularNotifications.PortalBaseUrl"],UriKind.Absolute,out origin)||(!origin.IsLoopback&&origin.Scheme!="https")||!string.IsNullOrEmpty(origin.UserInfo)){code="INVALID_PORTAL_ORIGIN";continue;}
     string route=Convert.ToString(row["RecipientKind"])=="customer"?"CustomerPortal/Circulars.aspx?ID=":"Modules/Circulars/Index.aspx?ID=";
     var url=new Uri(origin,route+Convert.ToInt32(row["CircularID"])).AbsoluteUri;
     string subject=("تعميم جديد: "+Convert.ToString(row["Title"])).Replace("\r"," ").Replace("\n"," ");
     using(var mail=new MailMessage())
     {
      mail.From=new MailAddress(sender,Convert.ToString(setting["BrandName"]),Encoding.UTF8);mail.To.Add(new MailAddress(to));
      mail.Subject=subject;mail.SubjectEncoding=Encoding.UTF8;mail.BodyEncoding=Encoding.UTF8;mail.IsBodyHtml=true;
      mail.Body="<div dir=\"rtl\"><h2>"+HttpUtility.HtmlEncode(Convert.ToString(row["Title"]))+"</h2><p>"+HttpUtility.HtmlEncode(Convert.ToString(row["Summary"]))+"</p></div><div dir=\"ltr\"><h2>"+HttpUtility.HtmlEncode(Convert.ToString(row["Title_EN"]))+"</h2><p>"+HttpUtility.HtmlEncode(Convert.ToString(row["Summary_EN"]))+"</p></div><p><a href=\""+HttpUtility.HtmlAttributeEncode(url)+"\">عرض التعميم / Open circular</a></p>";
      // The link always revalidates current recipient/brand/version authorization.
      var current=Query("dbo.Circular_MailValidate",new SqlParameter("@ID",row["ID"]),new SqlParameter("@Email",to.Trim()));
      if(current.Rows.Count==0){status="cancelled";code="UNAVAILABLE";continue;}
      cancellation.ThrowIfCancellationRequested();
      var password=AttendanceIntegration.Unprotect((byte[])setting["AppPassword"]);
      sending=true;await send(mail,new NetworkCredential(sender,password));status="submitted";code=null;
     }
    }
    catch(Exception e)
    {
     status=sending?"unknown":"failed";code=sending?"SMTP_OUTCOME_UNCERTAIN":"MAIL_PREPARATION_FAILED";
     System.Diagnostics.Trace.TraceWarning("Circular mail processing: {0}",e.GetType().Name);
    }
    finally
    {
     Query("dbo.Circular_MailComplete",new SqlParameter("@ID",row["ID"]),new SqlParameter("@Status",status),new SqlParameter("@ErrorCode",(object)code??DBNull.Value));
    }
   }
  }
  static bool BareEmail(string value)
  {if(string.IsNullOrWhiteSpace(value)||value.Contains("\r")||value.Contains("\n"))return false;try{return new MailAddress(value.Trim()).Address==value.Trim();}catch(FormatException){return false;}}
  public void Stop(bool immediate)
  {stopping.Cancel();timer.Dispose();HostingEnvironment.UnregisterObject(this);}
 }
}
