using System;
using System.Net;
using System.Net.Http;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Authentication
{
    public class AuthenticationAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            try
            {
                var header = context.Request.Headers.Authorization;
                if (header == null)
                {
                    context.Response = context.Request.CreateResponse(HttpStatusCode.Unauthorized);
                    return;
                }

                var pair = Encoding.UTF8.GetString(Convert.FromBase64String(header.Parameter)).Split(':');
                if (pair.Length < 2 || pair[0] != IntegrationCredentials.Username || pair[1] != IntegrationCredentials.Password)
                    context.Response = context.Request.CreateResponse(HttpStatusCode.Unauthorized);
                else
                    Thread.CurrentPrincipal =
                        new GenericPrincipal(
                            new GenericIdentity(pair[0]), null);
            }
            catch (FormatException)
            {
                context.Response = context.Request.CreateResponse(HttpStatusCode.Unauthorized);
            }
        }
    }
}
