using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http.Controllers;
using Prosto_ERP_API.Mobile;
namespace Prosto_ERP_API.Authentication
{
    // Reuse the current fixed integration credentials; enforce Basic and clear errors on this route only.
    public sealed class IntegrationBasicAuthenticationAttribute : Prosto_ERP_API.Authentication.AuthenticationAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            if (context.Response != null) return;
            if (!MobileApiSupport.TransportAllowed(context.Request)) {
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Forbidden, "HTTPS_REQUIRED", "استخدم HTTPS لإرسال بيانات الدخول."); return;
            }
            var header = context.Request.Headers.Authorization;
            if (header == null || !string.Equals(header.Scheme, "Basic", StringComparison.OrdinalIgnoreCase) || string.IsNullOrWhiteSpace(header.Parameter) || header.Parameter.Length > 4096) {
                Reject(context, "BASIC_AUTH_REQUIRED", "بيانات Basic Auth مطلوبة لهذه الواجهة."); return;
            }
            try {
                base.OnAuthorization(context);
                if (context.Response != null) { context.Response.Dispose(); Reject(context, "BASIC_AUTH_INVALID", "اسم المستخدم أو كلمة المرور الخاصة بـBasic Auth غير صحيحة."); }
            } catch (ArgumentException) { Reject(context, "BASIC_AUTH_INVALID", "بيانات Basic Auth غير صالحة."); }
        }
        private static void Reject(HttpActionContext context, string code, string message)
        {
            context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Unauthorized, code, message);
            context.Response.Headers.WwwAuthenticate.Clear();
            context.Response.Headers.WwwAuthenticate.Add(new AuthenticationHeaderValue("Basic"));
        }
    }
}
