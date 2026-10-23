using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Prosto_ERP_API.Mobile;
using Prosto_ERP_API.Responses;
using ProstoERP.Application.Errors;

namespace Prosto_ERP_API.Features.Authentication
{
    internal static class AuthenticationResponses
    {
        internal static HttpResponseMessage Execute(HttpRequestMessage request, Func<object> operation, bool empty = false)
        {
            try
            {
                var data = operation();
                return empty ? ApiResponseHandler.Success(request) : ApiResponseHandler.Success(request, data);
            }
            catch (Exception ex) { return Failure(request, ex); }
        }
        internal static async Task<HttpResponseMessage> ExecuteAsync(HttpRequestMessage request, Func<Task<object>> operation)
        {
            try { return ApiResponseHandler.Success(request, await operation()); }
            catch (Exception ex) { return Failure(request, ex); }
        }
        private static HttpResponseMessage Failure(HttpRequestMessage request, Exception exception)
        {
            var business = exception as MobileBusinessException;
            if (business != null) return MobileApiSupport.Error(request, business.Status, business.Code, business.Message);
            var reset = exception as ResetException;
            if (reset != null) return MobileApiSupport.Error(request, reset.Status, reset.Code, reset.Message);
            var sql = exception as SqlException;
            if (sql != null)
            {
                switch (sql.Number)
                {
                    case 51900:
                    case 51960:
                        var limited = MobileApiSupport.Error(request, (HttpStatusCode)429, "AUTH_RATE_LIMIT", "Too many attempts. Try again later.");
                        limited.Headers.TryAddWithoutValidation("Retry-After", "900"); return limited;
                    case 51961: return MobileApiSupport.Error(request, HttpStatusCode.Conflict, "DEVICE_ALREADY_REGISTERED", "Only one device is allowed. Use email-verified device replacement.");
                    case 51901:
                    case 51902:
                    case 51962: return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "OTP_INVALID_OR_EXPIRED", "The verification code or authentication request is invalid, expired, or already used.");
                    case 51903: return MobileApiSupport.Error(request, HttpStatusCode.BadRequest, "RESET_TOKEN_INVALID", "The reset permission is invalid or expired.");
                    case 51964: return MobileApiSupport.Error(request, HttpStatusCode.Unauthorized, "BIOMETRIC_CREDENTIAL_INVALID", "Sign in with your password and enroll biometrics again.");
                    case 51965: return MobileApiSupport.Error(request, HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS", "Invalid credentials or inactive account.");
                    case 51966: return MobileApiSupport.Error(request, HttpStatusCode.Forbidden, "DEVICE_ACTIVATION_REQUIRED", "Verify your registered device by email before signing in.");
                    case 51968: return MobileApiSupport.Error(request, HttpStatusCode.ServiceUnavailable, "EMPLOYEE_EMAIL_UNAVAILABLE", "Contact your administrator to configure your employee email and brand.");
                }
            }
            Trace.TraceError("Authentication operation failed ({0}).", exception.GetType().Name);
            return MobileApiSupport.Error(request, HttpStatusCode.ServiceUnavailable, "AUTH_SERVICE_UNAVAILABLE", "Authentication is unavailable. Verify the database migration and employee email configuration.");
        }
    }
}
