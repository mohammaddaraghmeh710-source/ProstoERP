using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Mail;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using MailKit.Net.Smtp;
using MailKit.Security;
using Prosto_ERP_API.Authentication;
using Prosto_ERP_API.Mobile;
using Prosto_ERP_API.Notifications;
using Prosto_ERP_ClassLibrary;

namespace Prosto_ERP_API.Controllers
{
    [IntegrationBasicAuthentication]
    [RoutePrefix("api/EmailNotification")]
    public sealed class EmailNotificationController : ApiController
    {
        private readonly Func<MailMessage, NetworkCredential, Task> send;
        private readonly AttendanceIntegration store;

        public EmailNotificationController() : this(null, BrandEmailSender.SendGmail)
        {
        }

        public EmailNotificationController(AttendanceIntegration store,
            Func<MailMessage, NetworkCredential, Task> sender)
        {
            this.store = store;
            send = sender ?? BrandEmailSender.SendGmail;
        }

        [HttpPost]
        [Route("Send")]
        public async Task<HttpResponseMessage> Send(EmailNotificationRequest model)
        {
            if (model == null || !ModelState.IsValid || (model.Extra != null && model.Extra.Count > 0) ||
                !BareEmail(model.To) || string.IsNullOrWhiteSpace(model.Subject) || model.Subject.Contains("\r") ||
                model.Subject.Contains("\n") || string.IsNullOrWhiteSpace(model.Body))
                return Error(HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "أرسل BrandID صحيحًا وبريد مستلم واحدًا وعنوانًا ونص HTML صالحًا دون حقول إضافية.");
            try
            {
                var db = store ?? new AttendanceIntegration(ConfigurationManager
                    .ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
                var data = db.Query("dbo.EmailNotification_Credentials", new SqlParameter("@BrandID", model.BrandID));
                if (data.Rows.Count != 1)
                    return Error(HttpStatusCode.ServiceUnavailable, "SMTP_NOT_CONFIGURED",
                        "لم يضبط مدير النظام إعدادات Gmail لهذه العلامة التجارية.");
                var row = data.Rows[0];
                if (!(bool)row["Enabled"])
                    return Error(HttpStatusCode.Forbidden, "EMAIL_DISABLED",
                        "إرسال البريد موقوف لهذه العلامة التجارية.");
                var address = Convert.ToString(row["SenderEmail"]);
                if (row.IsNull("AppPassword") || !BareEmail(address))
                    return Error(HttpStatusCode.ServiceUnavailable, "SMTP_NOT_CONFIGURED",
                        "إعدادات بريد العلامة التجارية غير مكتملة.");
                var password = AttendanceIntegration.Unprotect((byte[])row["AppPassword"]);
                using (var mail = new MailMessage())
                {
                    mail.From = new MailAddress(address, Convert.ToString(row["BrandName"]), Encoding.UTF8);
                    mail.To.Add(new MailAddress(model.To.Trim()));
                    mail.Subject = model.Subject.Trim();
                    mail.Body = model.Body;
                    mail.IsBodyHtml = true;
                    mail.SubjectEncoding = Encoding.UTF8;
                    mail.BodyEncoding = Encoding.UTF8;
                    await send(mail, new NetworkCredential(address, password));
                }

                var response = Request.CreateResponse(HttpStatusCode.OK,
                    new
                    {
                        Success = true,
                        Data = new { model.BrandID, To = model.To.Trim(), Status = "Submitted" },
                        Message = "قبل خادم SMTP الرسالة للإرسال؛ وصولها النهائي يعتمد على مزود البريد."
                    });
                MobileApiSupport.NoCache(response);
                return response;
            }
            catch (SqlException ex)
            {
                Trace.TraceWarning("Email settings query failed ({0}).", ex.Number);
                return Error(ex.Number == 51803 ? HttpStatusCode.Forbidden : HttpStatusCode.ServiceUnavailable,
                    ex.Number == 51803 ? "BRAND_UNAVAILABLE" : "EMAIL_CONFIG_UNAVAILABLE",
                    ex.Number == 51803
                        ? "العلامة التجارية غير متاحة أو موقوفة."
                        : "تعذّر قراءة إعدادات البريد. راجع مدير النظام.");
            }
            catch (CryptographicException)
            {
                return Error(HttpStatusCode.ServiceUnavailable, "SMTP_CONFIG_DECRYPTION_ERROR",
                    "أعد حفظ App Password على خادم الإرسال الحالي.");
            }
            catch (TimeoutException)
            {
                return Error(HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة SMTP. قد تكون الرسالة قُبلت؛ تحقق قبل إعادة الإرسال.");
            }
            catch (OperationCanceledException)
            {
                return Error(HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة SMTP. قد تكون الرسالة قُبلت؛ تحقق قبل إعادة الإرسال.");
            }
            catch (AuthenticationException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_AUTH_FAILED",
                    "رفض Gmail بيانات الدخول. تحقق من البريد وApp Password للحساب نفسه.");
            }
            catch (SslHandshakeException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_TLS_FAILED",
                    "تعذّر إنشاء اتصال آمن مع Gmail. تحقق من شهادة الاتصال وبرامج فحص البريد على الخادم.");
            }
            catch (SmtpCommandException ex)
            {
                Trace.TraceWarning("SMTP command failed ({0}, {1}).", (int)ex.StatusCode, ex.ErrorCode);
                var code = ex.ErrorCode == SmtpErrorCode.RecipientNotAccepted
                    ? "SMTP_RECIPIENT_REJECTED"
                    : (int)ex.StatusCode == 535 || (int)ex.StatusCode == 534 || (int)ex.StatusCode == 530
                        ? "SMTP_AUTH_FAILED"
                        : "SMTP_SEND_FAILED";
                return Error(HttpStatusCode.BadGateway, code,
                    "رفض Gmail عملية الإرسال. تحقق من حساب المرسل وعنوان المستلم.");
            }
            catch (SmtpProtocolException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_SEND_FAILED",
                    "انقطع اتصال SMTP أو وصل رد غير صالح من خادم البريد.");
            }
            catch (IOException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED",
                    "تعذّر الاتصال بـ smtp.gmail.com على المنفذ 465. تحقق من الشبكة وإعدادات الحماية.");
            }
            catch (SocketException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED",
                    "تعذّر الاتصال بـ smtp.gmail.com على المنفذ 465. تحقق من الشبكة وإعدادات الحماية.");
            }
            catch (SmtpFailedRecipientException)
            {
                return Error(HttpStatusCode.BadGateway, "SMTP_RECIPIENT_REJECTED", "رفض خادم البريد عنوان المستلم.");
            }
            catch (SmtpException ex)
            {
                Trace.TraceWarning("SMTP send failed ({0}).", (int)ex.StatusCode);
                return Error(HttpStatusCode.BadGateway,
                    (int)ex.StatusCode == 535 || (int)ex.StatusCode == 534 || (int)ex.StatusCode == 530
                        ? "SMTP_AUTH_FAILED"
                        : "SMTP_SEND_FAILED",
                    "تعذّر إرسال البريد عبر Gmail. تحقق من App Password والاتصال وصلاحية الحساب.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Email request failed ({0}).", ex.GetType().Name);
                return Error(HttpStatusCode.InternalServerError, "EMAIL_SEND_FAILED", "تعذّر إتمام إرسال البريد.");
            }
        }

        private static bool BareEmail(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Contains("\r") || value.Contains("\n")) return false;
            try
            {
                return new MailAddress(value.Trim()).Address == value.Trim();
            }
            catch (FormatException)
            {
                return false;
            }
        }

        private HttpResponseMessage Error(HttpStatusCode status, string code, string message)
        {
            var response = MobileApiSupport.Error(Request, status, code, message);
            response.Headers.WwwAuthenticate.Clear();
            return response;
        }
    }
}
