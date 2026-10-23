using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Description;
using Prosto_ERP_API.Mobile;
using Prosto_ERP_API.Responses;
using ProstoERP.Application.Features.Authentication;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Authentication;
using ProstoERP.Contracts.Features.EmployeeAccess;
using ProstoERP.Contracts.Features.PasswordReset;

namespace Prosto_ERP_API.Features.Authentication
{
    [MobileTransport]
    [RoutePrefix("api/v1/auth")]
    public sealed class AuthenticationController : ApiController
    {
        private readonly AuthenticationService service;
        public AuthenticationController() : this(Composition.MobileBackend.Current.CreateAuthentication()) { }
        public AuthenticationController(AuthenticationService service) { this.service = service; }
        private string Source => HttpContext.Current == null ? "unknown" : HttpContext.Current.Request.UserHostAddress;
        private byte[] Token => (byte[])Request.Properties["MobileTokenHash"];
        private HttpResponseMessage Invalid() => MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "Valid authentication fields, app version and device information are required. MACID is optional; FCMToken is required.");
        private HttpResponseMessage Run(Func<object> operation) => AuthenticationResponses.Execute(Request, operation);
        private Task<HttpResponseMessage> RunAsync(Func<Task<object>> operation) => AuthenticationResponses.ExecuteAsync(Request, operation);

        [HttpPost, Route("login")]
        [ResponseType(typeof(BaseResponse<EmployeeLoginResponse>))]
        public HttpResponseMessage Login(MobileLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate()) return Invalid();
            return Run(() => service.Login(model, Source));
        }

        [HttpPost, Route("register")]
        [ResponseType(typeof(BaseResponse<OtpChallengeResponse>))]
        public Task<HttpResponseMessage> Register(MobileLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate()) return Task.FromResult(Invalid());
            return RunAsync(async () => await service.Register(model, Source, false));
        }

        [HttpPost, Route("devices/replace")]
        [ResponseType(typeof(BaseResponse<OtpChallengeResponse>))]
        public Task<HttpResponseMessage> ReplaceDevice(MobileLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate()) return Task.FromResult(Invalid());
            return RunAsync(async () => await service.Register(model, Source, true));
        }

        [HttpPost, Route("verify-otp")]
        [ResponseType(typeof(BaseResponse<OtpVerificationResponse>))]
        public HttpResponseMessage VerifyOtp(VerifyOtpRequest model)
        {
            if (model == null || !ModelState.IsValid || model.ChallengeID == Guid.Empty)
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "A valid ChallengeID, Purpose and verification code are required.");
            return Run(() => service.VerifyOtp(model, Source));
        }

        [HttpPost, Route("forgot-password")]
        [ResponseType(typeof(BaseResponse<OtpChallengeResponse>))]
        public Task<HttpResponseMessage> ForgotPassword(ResetRequest model)
        {
            if (model == null || !ModelState.IsValid || model.HasExtra) return Task.FromResult(Invalid());
            return RunAsync(async () => await service.ForgotPassword(model.EmployeeNumber, Source));
        }

        [HttpPost, Route("reset-password")]
        [ResponseType(typeof(BaseResponse<ResetCompletionResponse>))]
        public HttpResponseMessage ResetPassword(CompleteResetRequest model)
        {
            if (model == null || !ModelState.IsValid || model.HasExtra || MobileApiSupport.TokenHash(model.ResetToken) == null || string.IsNullOrWhiteSpace(model.NewPassword)) return Invalid();
            return Run(() => service.ResetPassword(model, Source));
        }

        [MobileSession, HttpPost, Route("logout")]
        [ResponseType(typeof(BaseResponse))]
        public HttpResponseMessage Logout()
        {
            return AuthenticationResponses.Execute(Request, () => { service.Logout(Token); return null; }, true);
        }

        [MobileSession, HttpPost, Route("devices/current")]
        [ResponseType(typeof(BaseResponse))]
        public HttpResponseMessage UpdateDevice(DeviceContextRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate()) return Invalid();
            return AuthenticationResponses.Execute(Request, () => { service.UpdateDevice(Token, model); return null; }, true);
        }

        [MobileSession, HttpPost, Route("biometric/enroll")]
        [ResponseType(typeof(BaseResponse<BiometricCredentialResponse>))]
        public HttpResponseMessage EnrollBiometric(BiometricEnrollmentRequest model)
        {
            if (model == null || !ModelState.IsValid || string.IsNullOrWhiteSpace(model.Password))
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "The current Password and RSA public key Modulus and Exponent are required.");
            return Run(() => service.EnrollBiometric(Token, model, Source));
        }

        [HttpPost, Route("biometric/challenge")]
        [ResponseType(typeof(BaseResponse<BiometricChallengeResponse>))]
        public HttpResponseMessage BiometricChallenge(BiometricChallengeRequest model)
        {
            if (model == null || !ModelState.IsValid || model.CredentialID == Guid.Empty || !model.NormalizeAndValidate()) return Invalid();
            return Run(() => service.BiometricChallenge(model, Source));
        }

        [HttpPost, Route("biometric/login")]
        [ResponseType(typeof(BaseResponse<EmployeeLoginResponse>))]
        public HttpResponseMessage BiometricLogin(BiometricLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || model.CredentialID == Guid.Empty || model.ChallengeID == Guid.Empty || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "Valid CredentialID, ChallengeID, RSA Signature and app/device information including FCMToken are required.");
            return Run(() => service.BiometricLogin(model, Source));
        }
    }
}
