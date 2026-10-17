using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Mail;
using System.Net.Sockets;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using MailKit.Net.Smtp;
using MailKit.Security;
using Prosto_ERP_API.Authentication;

namespace Prosto_ERP_API.Mobile
{
    public sealed partial class UsersController
    {
        private readonly PasswordResetService resetService;

        public UsersController()
        {
        }

        public UsersController(PasswordResetService service)
        {
            resetService = service;
        }

        private PasswordResetService ResetService()
        {
            return resetService ?? new PasswordResetService();
        }

        [HttpPost]
        [Route("RequestPasswordReset")]
        [IntegrationBasicAuthentication]
        public Task<HttpResponseMessage> RequestPasswordReset(ResetRequest model)
        {
            if (model == null || !ModelState.IsValid || model.HasExtra)
                return Task.FromResult(ResetError(HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "أدخل رقمًا وظيفيًا صحيحًا فقط."));
            return ResetAction(
                async () => await ResetService().Request(model.EmployeeNumber,
                    HttpContext.Current == null ? "unknown" : HttpContext.Current.Request.UserHostAddress),
                "تم إرسال رمز التحقق إلى بريدك الإلكتروني.");
        }

        [HttpPost]
        [Route("VerifyPasswordResetOTP")]
        [IntegrationBasicAuthentication]
        public Task<HttpResponseMessage> VerifyPasswordResetOTP(VerifyResetRequest model)
        {
            if (model == null || !ModelState.IsValid || model.HasExtra || model.ChallengeID == Guid.Empty)
                return Task.FromResult(ResetError(HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "أرسل معرف الطلب ورمز التحقق المكوّن من 6 أرقام."));
            return ResetAction(() => Task.FromResult(ResetService().Verify(model.ChallengeID, model.OTP)),
                "تم التحقق من الرمز. يمكنك تعيين كلمة مرور جديدة.");
        }

        [HttpPost]
        [Route("ResetPassword")]
        [IntegrationBasicAuthentication]
        public Task<HttpResponseMessage> ResetPassword(CompleteResetRequest model)
        {
            if (model == null || !ModelState.IsValid || model.HasExtra ||
                MobileApiSupport.TokenHash(model.ResetToken) == null || string.IsNullOrWhiteSpace(model.NewPassword))
                return Task.FromResult(ResetError(HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "أرسل تصريح تغيير صالحًا وكلمة مرور من 8 إلى 128 حرفًا."));
            return ResetAction(() => Task.FromResult(ResetService().Complete(model.ResetToken, model.NewPassword)),
                "تم تغيير كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.");
        }

        private HttpResponseMessage ResetError(HttpStatusCode status, string code, string message)
        {
            var response = MobileApiSupport.Error(Request, status, code, message);
            response.Headers.WwwAuthenticate.Clear();
            return response;
        }

        private async Task<HttpResponseMessage> ResetAction(Func<Task<object>> action, string message)
        {
            try
            {
                return Success(new { Success = true, Data = await action(), Message = message });
            }
            catch (ResetException ex)
            {
                return ResetError(ex.Status, ex.Code, ex.Message);
            }
            catch (SqlException ex) when (ex.Number >= 51900 && ex.Number <= 51903)
            {
                var codes = new[] { "RESET_RATE_LIMITED", "OTP_UNAVAILABLE", "OTP_INVALID", "RESET_TOKEN_INVALID" };
                var messages = new[]
                {
                    "انتظر دقيقة بين الطلبات؛ الحد الأقصى 5 طلبات في الساعة.",
                    "انتهت صلاحية الرمز أو تم استخدامه أو تجاوز عدد المحاولات. اطلب رمزًا جديدًا.",
                    "رمز التحقق غير صحيح. لديك 5 محاولات كحد أقصى.",
                    "تصريح تغيير كلمة المرور غير صالح أو منتهي. ابدأ الاستعادة مجددًا."
                };
                return ResetError(ex.Number == 51900 ? (HttpStatusCode)429 : HttpStatusCode.BadRequest,
                    codes[ex.Number - 51900], messages[ex.Number - 51900]);
            }
            catch (OperationCanceledException)
            {
                return ResetError(HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة الإرسال. تحقق من بريدك قبل إعادة المحاولة.");
            }
            catch (TimeoutException)
            {
                return ResetError(HttpStatusCode.GatewayTimeout, "SMTP_TIMEOUT",
                    "انتهت مهلة الإرسال. أعد المحاولة بعد دقيقة.");
            }
            catch (AuthenticationException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_AUTH_FAILED",
                    "تعذّر تسجيل الدخول إلى بريد العلامة التجارية. يرجى التواصل مع مدير النظام.");
            }
            catch (SslHandshakeException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_TLS_FAILED", "تعذّر الاتصال الآمن بخدمة البريد.");
            }
            catch (SmtpCommandException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_SEND_FAILED",
                    "رفض خادم البريد إرسال رمز التحقق. يرجى التواصل مع مدير النظام.");
            }
            catch (SmtpProtocolException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_SEND_FAILED", "انقطع اتصال خدمة البريد.");
            }
            catch (IOException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED", "تعذّر الاتصال بخدمة البريد.");
            }
            catch (SocketException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_CONNECTION_FAILED", "تعذّر الاتصال بخدمة البريد.");
            }
            catch (SmtpException)
            {
                return ResetError(HttpStatusCode.BadGateway, "SMTP_SEND_FAILED", "تعذّر إرسال رمز التحقق عبر البريد.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Password reset failed ({0}).", ex.GetType().Name);
                return ResetError(HttpStatusCode.ServiceUnavailable, "RESET_SERVICE_UNAVAILABLE",
                    "خدمة استعادة كلمة المرور غير متاحة حاليًا. يرجى التواصل مع مدير النظام.");
            }
        }
    }
}
