using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using ProstoERP.Application.Features.Authentication;
using Prosto_ERP_API.Notifications;
using Prosto_ERP_ClassLibrary;

namespace ProstoERP.Infrastructure.Mobile.Features.Authentication
{
    public sealed class AuthenticationOtpSender : IAuthenticationOtpSender
    {
        public async Task Send(OtpRecipient recipient, string code, string purpose)
        {
            var subject = purpose == "device-replacement" ? "Verify mobile device replacement" : "Activate mobile access";
            var body = "<html><body><h2>" + HttpUtility.HtmlEncode(subject) + "</h2><p>Hello " + HttpUtility.HtmlEncode(recipient.EmployeeName) + "</p><p>Your single-use verification code is:</p><p style='font-size:28px'>" + HttpUtility.HtmlEncode(code) + "</p><p>Valid for 10 minutes. Do not share this code.</p></body></html>";
            if (await LocalOtpDelivery.Send(recipient.Email, subject, body)) return;
            var db = new AttendanceIntegration(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
            var settings = db.Query("dbo.EmailNotification_Credentials", new SqlParameter("@BrandID", recipient.BrandID));
            if (settings.Rows.Count != 1 || !(bool)settings.Rows[0]["Enabled"] || settings.Rows[0].IsNull("AppPassword"))
                throw new ConfigurationErrorsException("Employee email delivery is not configured.");
            var row = settings.Rows[0];
            var address = new MailAddress(Convert.ToString(row["SenderEmail"]));
            var email = new MailAddress(recipient.Email);
            if (email.Address != recipient.Email) throw new ConfigurationErrorsException("Employee email is not a bare address.");
            using (var mail = new MailMessage())
            {
                mail.From = new MailAddress(address.Address, recipient.BrandName, Encoding.UTF8);
                mail.To.Add(email);
                mail.Subject = subject;
                mail.SubjectEncoding = Encoding.UTF8; mail.BodyEncoding = Encoding.UTF8; mail.IsBodyHtml = true;
                mail.Body = body;
                await BrandEmailSender.SendGmail(mail, new NetworkCredential(address.Address, AttendanceIntegration.Unprotect((byte[])row["AppPassword"])));
            }
        }
    }
}
