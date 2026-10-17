using System;
using System.Net;
using System.Net.Mail;
using System.Threading;
using System.Threading.Tasks;
using MailKit.Security;
using MimeKit;
using SmtpClient = MailKit.Net.Smtp.SmtpClient;

namespace Prosto_ERP_API.Notifications
{
    internal static class BrandEmailSender
    {
        internal static async Task SendGmail(MailMessage mail, NetworkCredential credentials)
        {
            using (var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(30)))
            using (var message = MimeMessage.CreateFromMailMessage(mail))
            using (var smtp = new SmtpClient { Timeout = 30000 })
            {
                await smtp.ConnectAsync("smtp.gmail.com", 465, SecureSocketOptions.SslOnConnect,
                    deadline.Token);
                smtp.AuthenticationMechanisms.Remove("XOAUTH2");
                await smtp.AuthenticateAsync(credentials.UserName, credentials.Password, deadline.Token);
                await smtp.SendAsync(message, deadline.Token);
                // Dispose without QUIT: acceptance must not be reported as failure on disconnect.
            }
        }
    }
}
