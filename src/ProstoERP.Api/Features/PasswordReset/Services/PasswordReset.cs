using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Prosto_ERP_ClassLibrary;
using Prosto_ERP_API.Notifications;

namespace Prosto_ERP_API.Mobile
{
    public sealed class PasswordResetService
    {
        readonly AttendanceIntegration db;
        readonly Func<MailMessage, NetworkCredential, Task> sender;

        public PasswordResetService(AttendanceIntegration store = null,
            Func<MailMessage, NetworkCredential, Task> send = null)
        {
            db = store ?? new AttendanceIntegration(ConfigurationManager
                .ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
            sender = send ?? BrandEmailSender.SendGmail;
        }

        static SqlParameter P(string name, object value)
        {
            return new SqlParameter(name, value ?? DBNull.Value);
        }

        static byte[] Hash(string value)
        {
            var key = Convert.FromBase64String(ConfigurationManager.AppSettings["PasswordReset.HashKey"] ?? "");
            if (key.Length < 32) throw new ConfigurationErrorsException("Password reset key unavailable.");
            using (var h = new HMACSHA256(key)) return h.ComputeHash(Encoding.UTF8.GetBytes(value));
        }

        static string Code()
        {
            using (var rng = RandomNumberGenerator.Create())
            {
                var bytes = new byte[4];
                uint n;
                do
                {
                    rng.GetBytes(bytes);
                    n = BitConverter.ToUInt32(bytes, 0);
                } while (n >= 4294000000u);

                return (n % 1000000).ToString("D6", System.Globalization.CultureInfo.InvariantCulture);
            }
        }

        public async Task<object> Request(int employee, string source)
        {
            var id = Guid.NewGuid();
            var code = Code();
            var row = db.Query("dbo.PasswordReset_Request", P("@EmployeeNumber", employee), P("@ID", id),
                P("@OtpHash", Hash(id.ToString("D") + ":" + code)), P("@SourceHash", Hash("client:" + source))).Rows[0];
            if (row.IsNull("UserID"))
                throw new ResetException(HttpStatusCode.BadRequest, "ACCOUNT_UNAVAILABLE",
                    "الرقم الوظيفي غير متاح. يرجى التواصل مع مدير النظام.");
            var email = Convert.ToString(row["Email"]).Trim();
            if (!BareEmail(email))
                throw new ResetException(HttpStatusCode.BadRequest, "EMAIL_NOT_REGISTERED",
                    "لا يوجد بريد إلكتروني صالح مسجّل، يرجى التواصل مع مدير النظام.");
            if (row.IsNull("BrandName"))
                throw new ResetException(HttpStatusCode.BadRequest, "BRAND_UNAVAILABLE",
                    "العلامة التجارية غير متاحة. يرجى التواصل مع مدير النظام.");
            try
            {
                var settings = db.Query("dbo.EmailNotification_Credentials", P("@BrandID", row["BrandID"]));
                if (settings.Rows.Count != 1 || !(bool)settings.Rows[0]["Enabled"] ||
                    settings.Rows[0].IsNull("AppPassword"))
                    throw new ResetException(HttpStatusCode.ServiceUnavailable, "SMTP_NOT_CONFIGURED",
                        "خدمة البريد غير مفعلة للعلامة التجارية. يرجى التواصل مع مدير النظام.");
                var config = settings.Rows[0];
                var address = Convert.ToString(config["SenderEmail"]);
                if (!BareEmail(address))
                    throw new ResetException(HttpStatusCode.ServiceUnavailable, "SMTP_NOT_CONFIGURED",
                        "إعدادات بريد المرسل غير مكتملة.");
                using (var mail = new MailMessage())
                {
                    mail.From = new MailAddress(address, Convert.ToString(row["BrandName"]), Encoding.UTF8);
                    mail.To.Add(email);
                    mail.Subject = "رمز استعادة كلمة المرور — " + Convert.ToString(row["BrandName"]);
                    mail.SubjectEncoding = Encoding.UTF8;
                    mail.BodyEncoding = Encoding.UTF8;
                    mail.IsBodyHtml = true;
                    mail.Body = EmailBody(Convert.ToString(row["EmployeeName"]), Convert.ToString(row["BrandName"]),
                        code);
                    await sender(mail,
                        new NetworkCredential(address, AttendanceIntegration.Unprotect((byte[])config["AppPassword"])));
                }

                db.Query("dbo.PasswordReset_Delivery", P("@ID", id), P("@Sent", true));
                return new
                {
                    ChallengeID = id, MaskedEmail = Mask(email), ExpiresInSeconds = 600, ResendAfterSeconds = 60
                };
            }
            catch
            {
                try
                {
                    db.Query("dbo.PasswordReset_Delivery", P("@ID", id), P("@Sent", false));
                }
                catch
                {
                    System.Diagnostics.Trace.TraceWarning("Could not invalidate failed OTP delivery.");
                }

                throw;
            }
        }

        public object Verify(Guid id, string code)
        {
            var token = MobileApiSupport.NewToken();
            db.Query("dbo.PasswordReset_Verify", P("@ID", id), P("@OtpHash", Hash(id.ToString("D") + ":" + code)),
                P("@ResetHash", MobileApiSupport.TokenHash(token)));
            return new { ResetToken = token, ExpiresInSeconds = 600 };
        }

        public object Complete(string token, string password)
        {
            db.Query("dbo.PasswordReset_Complete", P("@ResetHash", MobileApiSupport.TokenHash(token)),
                P("@EncryptedPassword", new Echo.Encrptor.TripleDesEncryptor().Encrypt(password)));
            return new { PasswordChanged = true };
        }

        static bool BareEmail(string value)
        {
            try
            {
                return !string.IsNullOrWhiteSpace(value) && !value.Contains("\r") && !value.Contains("\n") &&
                       new MailAddress(value).Address == value;
            }
            catch (FormatException)
            {
                return false;
            }
        }

        static string Mask(string email)
        {
            var at = email.LastIndexOf('@');
            var local = email.Substring(0, at);
            return "***" + (local.Length > 2 ? local.Substring(local.Length - 2) : "") + email.Substring(at);
        }

        public static string EmailBody(string name, string brand, string code)
        {
            return
                "<!doctype html><html lang='ar' dir='rtl'><body style='margin:0;background:#f3f5f8;font-family:Tahoma,Arial,sans-serif;color:#253047'><table role='presentation' width='100%' cellpadding='0' cellspacing='0'><tr><td align='center' style='padding:32px 16px'><table role='presentation' width='100%' style='max-width:560px;background:#fff;border-radius:12px' cellpadding='0' cellspacing='0'><tr><td style='padding:28px;border-bottom:1px solid #e8ecf2;color:#3157b8;font-size:22px;font-weight:bold'>" +
                HttpUtility.HtmlEncode(brand) +
                "</td></tr><tr><td style='padding:28px;text-align:right;line-height:1.9'><h2 style='margin:0 0 16px'>استعادة كلمة المرور</h2><p>مرحبًا " +
                HttpUtility.HtmlEncode(name) +
                "،</p><p>وصلنا طلب لإعادة تعيين كلمة المرور لحسابك. أدخل الرمز التالي في شاشة التحقق لإكمال الطلب:</p><div dir='ltr' style='background:#eef2ff;color:#3157b8;text-align:center;padding:20px;border-radius:8px;font-size:32px;font-weight:bold;letter-spacing:8px'>" +
                HttpUtility.HtmlEncode(code) +
                "</div><p>الرمز صالح لمدة <strong>10 دقائق</strong>، ويُستخدم مرة واحدة فقط.</p><p style='color:#657087'>إذا لم تطلب تغيير كلمة المرور، تجاهل هذه الرسالة. لا تشارك الرمز مع أي شخص.</p></td></tr><tr><td style='padding:18px 28px;background:#f8f9fc;color:#657087;font-size:12px;text-align:center'>رسالة تلقائية من نظام " +
                HttpUtility.HtmlEncode(brand) + ".</td></tr></table></td></tr></table></body></html>";
        }
    }
}
