using System;
using System.Data;
using System.Diagnostics;
using System.Globalization;
using System.Net;
using System.Security.Claims;
using System.Threading;
using System.Web;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Mobile
{
    public sealed class MobileSessionAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            if (context.Response != null) return;
            if (!MobileApiSupport.TransportAllowed(context.Request))
            {
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Forbidden, "HTTPS_REQUIRED",
                    "Use HTTPS for mobile API requests.");
                return;
            }

            var authorization = context.Request.Headers.Authorization;
            var hash = authorization != null &&
                       string.Equals(authorization.Scheme, "Bearer", StringComparison.OrdinalIgnoreCase)
                ? MobileApiSupport.TokenHash(authorization.Parameter)
                : null;
            if (hash == null)
            {
                Unauthorized(context);
                return;
            }

            try
            {
                var session = Prosto_ERP_API.Composition.MobileBackend.Current.SessionAuthentication.Employee(hash);
                if (session == null)
                {
                    Unauthorized(context);
                    return;
                }

                var identity = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier,
                        Convert.ToString(session["UserID"], CultureInfo.InvariantCulture))
                }, "Bearer");
                var principal = new ClaimsPrincipal(identity);
                context.RequestContext.Principal = principal;
                Thread.CurrentPrincipal = principal;
                if (HttpContext.Current != null) HttpContext.Current.User = principal;
                context.Request.Properties["MobileSession"] = session;
                context.Request.Properties["MobileTokenHash"] = hash;
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API authentication failed ({0}).", ex.GetType().Name);
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.InternalServerError,
                    "SERVER_ERROR", "Unable to authenticate the request.");
            }
        }

        private static void Unauthorized(HttpActionContext context)
        {
            context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Unauthorized,
                "SESSION_INVALID", "Sign in again. The session is missing, expired, or revoked.");
        }
    }
}
