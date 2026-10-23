using System;
using System.Net;
using System.Net.Mail;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using MailKit.Security;
using MimeKit;
using SmtpClient = MailKit.Net.Smtp.SmtpClient;

namespace Prosto_ERP_API.Notifications
{
 public static class BrandEmailSender
 {
  public static async Task SendGmail(MailMessage mail,NetworkCredential credentials)
  {
   using(var deadline=new CancellationTokenSource(TimeSpan.FromSeconds(30)))
   using(var message=MimeKit.MimeMessage.CreateFromMailMessage(mail))
   using(var smtp=new MailKit.Net.Smtp.SmtpClient(){Timeout=30000}) {
    var timer=Stopwatch.StartNew();
    // Fail unreachable SMTP connections promptly; keep the 30s total send budget.
    using(var connectDeadline=CancellationTokenSource.CreateLinkedTokenSource(deadline.Token)) {
     connectDeadline.CancelAfter(TimeSpan.FromSeconds(8));
     try {await smtp.ConnectAsync("smtp.gmail.com",465,MailKit.Security.SecureSocketOptions.SslOnConnect,connectDeadline.Token);}
     finally {Trace.TraceInformation("Gmail connect elapsed ms={0}.",timer.ElapsedMilliseconds);}
    }
    smtp.AuthenticationMechanisms.Remove("XOAUTH2");
    timer.Restart();
    try {await smtp.AuthenticateAsync(credentials.UserName,credentials.Password,deadline.Token);}
    finally {Trace.TraceInformation("Gmail authentication elapsed ms={0}.",timer.ElapsedMilliseconds);}
    timer.Restart();
    try {await smtp.SendAsync(message,deadline.Token);}
    finally {Trace.TraceInformation("Gmail submit elapsed ms={0}.",timer.ElapsedMilliseconds);}
    // Dispose without QUIT: acceptance must not be reported as failure on disconnect.
   }
  }
 }
}
