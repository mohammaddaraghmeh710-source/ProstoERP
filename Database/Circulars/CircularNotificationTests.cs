using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Net.Mail;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using Prosto_ERP_ClassLibrary;

public static class CircularNotificationTests
{
 static string Connection {get{return ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString;}}
 static void Sql(string text,params SqlParameter[] args){using(var cn=new SqlConnection(Connection))using(var cmd=new SqlCommand(text,cn)){cmd.Parameters.AddRange(args);cn.Open();cmd.ExecuteNonQuery();}}
 static int Count(string text){using(var cn=new SqlConnection(Connection))using(var cmd=new SqlCommand(text,cn)){cn.Open();return Convert.ToInt32(cmd.ExecuteScalar());}}
 static void Check(bool ok,string message){if(!ok)throw new Exception(message);Console.WriteLine("PASS: "+message);}
 static Task Process(Func<MailMessage,NetworkCredential,Task> sender)
 {var type=typeof(Prosto_ERP_API.Controllers.EmailNotificationController).Assembly.GetType("Prosto_ERP_API.Notifications.CircularNotificationWorker",true);return (Task)type.GetMethod("ProcessBatch",BindingFlags.NonPublic|BindingFlags.Static).Invoke(null,new object[]{sender,CancellationToken.None});}
 public static int Main()
 {
  try{
   var cs=new SqlConnectionStringBuilder(Connection);if(!cs.InitialCatalog.StartsWith("Prosto_Customer_Test_",StringComparison.Ordinal))throw new Exception("Isolated database required");
   Sql("UPDATE UsersMembers SET Email='employee@fixture.invalid',Brand_ID=1,Branch_ID=1 WHERE ID=2;UPDATE CRM_Accounts SET Email='customer@fixture.invalid',Brand_ID=1 WHERE ID=1;DELETE EmailNotificationSettings WHERE BrandID=1;INSERT EmailNotificationSettings(BrandID,SenderEmail,AppPassword,Enabled) VALUES(1,'sender@fixture.invalid',@Password,1)",new SqlParameter("@Password",AttendanceIntegration.Protect("synthetic-app-password")));
   int submitted=0;
   Process((mail,credentials)=>{Check(mail.To.Count==1&&mail.Bcc.Count==0,"One recipient per isolated email");Check(mail.IsBodyHtml&&mail.Body.Contains("Open circular")&&mail.Body.Contains("http://localhost:52219/")&&mail.Body.Contains("dir=\"rtl\"")&&mail.Body.Contains("dir=\"ltr\""),"Email includes encoded bilingual content and protected portal link");Check(credentials.UserName=="sender@fixture.invalid"&&credentials.Password=="synthetic-app-password","Brand sender credentials remain server-side");submitted++;return Task.FromResult(0);}).GetAwaiter().GetResult();
   Check(Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status IN ('failed','unknown')")==0,"Valid configured deliveries have no hidden errors");
   Check(submitted>=2,"Both employee and customer circular deliveries reach the injected SMTP boundary");
   Check(Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status='submitted'")==submitted,"SMTP acceptance is persisted as submitted");
   int second=0;Process((m,c)=>{second++;return Task.FromResult(0);}).GetAwaiter().GetResult();Check(second==0,"Dispatcher and worker do not send the same circular version twice");
   Sql("UPDATE CRM_Accounts SET Email='' WHERE ID=1;UPDATE Circulars SET Version=Version+1 WHERE Audience='customerTypes' AND IsEnabled=1");
   Process((m,c)=>{throw new Exception("No SMTP call expected for missing email");}).GetAwaiter().GetResult();
   Check(Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status='failed' AND ErrorCode='MISSING_RECIPIENT_EMAIL'")>0,"Missing recipient address is visible as a failed delivery, not a false success");
   Sql("UPDATE CRM_Accounts SET Email='customer@fixture.invalid' WHERE ID=1;UPDATE Circulars SET Version=Version+1 WHERE Audience='customerTypes' AND IsEnabled=1");
   int uncertain=0;Process((m,c)=>{uncertain++;throw new InvalidOperationException("Simulated transport uncertainty");}).GetAwaiter().GetResult();
   Check(uncertain>0&&Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status='unknown'")>0,"Uncertain transport outcome is recorded separately");
   int retried=0;Process((m,c)=>{retried++;return Task.FromResult(0);}).GetAwaiter().GetResult();Check(retried==0,"Uncertain submissions are not silently retried");
   Sql("UPDATE Circulars SET Version=Version+1 WHERE Audience='customerTypes';EXEC dbo.Circular_Dispatch;UPDATE Circulars SET IsEnabled=0 WHERE Audience='customerTypes'");
   int revoked=0;Process((m,c)=>{revoked++;return Task.FromResult(0);}).GetAwaiter().GetResult();Check(revoked==0&&Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status='cancelled' AND ErrorCode='UNAVAILABLE'")>0,"Revoked circulars cancel queued deliveries before SMTP");
   Sql("UPDATE Circulars SET IsEnabled=1,Version=Version+1 WHERE Audience='customerTypes';EXEC dbo.Circular_Dispatch;UPDATE Circular_Mail SET Status='sending',ClaimedUtc=DATEADD(minute,-10,SYSUTCDATETIME()) WHERE Status='pending';EXEC dbo.Circular_Dispatch");
   Check(Count("SELECT COUNT(*) FROM Circular_Mail WHERE Status='unknown' AND ErrorCode='WORKER_INTERRUPTED'")>0,"Interrupted in-flight delivery remains auditable without duplicate retry");
   Console.WriteLine("PASS: Circular notifications use a durable versioned queue; all SMTP operations were injected, no email was sent.");return 0;
  }catch(Exception e){Console.Error.WriteLine(e.GetType().Name+": "+e.Message);return 1;}
 }
}
