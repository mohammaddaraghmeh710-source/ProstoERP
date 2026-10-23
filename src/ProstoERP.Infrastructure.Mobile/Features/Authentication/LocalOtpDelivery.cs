using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ProstoERP.Infrastructure.Mobile.Features.Authentication
{
    // Deliberately confined to Debug binaries and the marked loopback development database.
    public static class LocalOtpDelivery
    {
        private static bool Flag(string name)
        {
            bool value;
            return bool.TryParse(ConfigurationManager.AppSettings[name], out value) && value;
        }

        private static bool Enabled()
        {
            if (!Flag("LocalOtp.Enabled"))
            {
                if (Flag("LocalOtp.FixedCode")) throw new ConfigurationErrorsException("Fixed OTP requires local delivery.");
                return false;
            }
#if DEBUG
            if (!Flag("LocalDevelopment.Enabled")) throw new ConfigurationErrorsException("Local OTP requires development mode.");
            var connection = new SqlConnectionStringBuilder(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
            var host = connection.DataSource.Split(',')[0].Trim();
            if (!(host == "127.0.0.1" || host.Equals("localhost", StringComparison.OrdinalIgnoreCase) || host == "." || host == "(local)") ||
                connection.InitialCatalog != "Prosto_ERP_Development") throw new ConfigurationErrorsException("Local OTP requires the loopback development database.");
            using (var db = new SqlConnection(connection.ConnectionString))
            using (var command = db.CreateCommand())
            {
                command.CommandText = "SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'ProstoLocalDevelopment' AND CONVERT(nvarchar(10),value)=N'1'";
                db.Open();
                if (Convert.ToInt32(command.ExecuteScalar()) != 1) throw new ConfigurationErrorsException("Database is not marked for local development.");
            }
            return true;
#else
            throw new ConfigurationErrorsException("Local OTP delivery is unavailable in Release builds.");
#endif
        }

        public static string FixedCode()
        {
            return Enabled() && Flag("LocalOtp.FixedCode") ? "12345" : null;
        }

        public static bool IsValidCode(string code)
        {
            return code != null && (Regex.IsMatch(code, "\\A[0-9]{6}\\z") || (code == "12345" && FixedCode() == code));
        }

        public static async Task<bool> Send(string recipient, string subject, string body)
        {
            if (!Enabled()) return false;
            using (var mail = new MailMessage("no-reply@prosto.local", recipient))
            using (var smtp = new SmtpClient("127.0.0.1", 1025))
            {
                mail.Subject = subject; mail.Body = body; mail.IsBodyHtml = true;
                mail.SubjectEncoding = Encoding.UTF8; mail.BodyEncoding = Encoding.UTF8;
                smtp.EnableSsl = false; smtp.UseDefaultCredentials = false; smtp.DeliveryMethod = SmtpDeliveryMethod.Network;
                await smtp.SendMailAsync(mail);
            }
            return true;
        }
    }
}
