using ProstoERP.Contracts.Features.PasswordReset;
using System.Web.Http.Description;
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
        private readonly ProstoERP.Application.Features.PasswordReset.IPasswordResetService resetService;

        public UsersController(PasswordResetService service) : this(Prosto_ERP_API.Composition.MobileBackend.Current.EmployeeAccess)
        {
            resetService = service;
        }

        private ProstoERP.Application.Features.PasswordReset.IPasswordResetService ResetService()
        {
            return resetService ?? Prosto_ERP_API.Composition.MobileBackend.Current.CreatePasswordReset();
        }

        [HttpPost]
        [Route("RequestPasswordReset")]
        [IntegrationBasicAuthentication]
        [ResponseType(typeof(PasswordResetResponse<ResetChallengeResponse>))]
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
        [ResponseType(typeof(PasswordResetResponse<ResetVerificationResponse>))]
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
        [ResponseType(typeof(PasswordResetResponse<ResetCompletionResponse>))]
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
            return Prosto_ERP_API.Responses.MobileErrorHandler.PasswordResetError(Request, status, code, message);
        }

        private Task<HttpResponseMessage> ResetAction(Func<Task<object>> action, string message)
        {
            return Prosto_ERP_API.Responses.MobileErrorHandler.PasswordReset(Request, action, message);
        }
    }
}
