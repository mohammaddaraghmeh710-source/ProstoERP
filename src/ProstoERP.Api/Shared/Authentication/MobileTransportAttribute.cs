using System.Net;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Mobile
{
    public sealed class MobileTransportAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            // Never trust caller-supplied forwarding headers as proof of TLS.
            if (!MobileApiSupport.TransportAllowed(context.Request))
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Forbidden, "HTTPS_REQUIRED",
                    "Use HTTPS for mobile API requests.");
        }
    }
}
