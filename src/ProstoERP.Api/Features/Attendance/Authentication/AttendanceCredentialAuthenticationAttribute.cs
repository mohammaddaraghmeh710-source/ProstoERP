using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Prosto_ERP_ClassLibrary;

namespace Prosto_ERP_API.Authentication
{
    public class AttendanceCredentialAuthenticationAttribute : AuthorizationFilterAttribute
    {
        private readonly AttendanceIntegration integration;

        public AttendanceCredentialAuthenticationAttribute()
        {
        }

        public AttendanceCredentialAuthenticationAttribute(AttendanceIntegration integration)
        {
            this.integration = integration;
        }

        protected AttendanceIntegration Store =>
            integration ?? new AttendanceIntegration(ConfigurationManager
                .ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);

        public override void OnAuthorization(HttpActionContext context)
        {
            if (context.Response != null) return;
            context.Request.Properties.Remove("AttendanceAuthenticatedBrandID");
            try
            {
                var header = context.Request.Headers.Authorization;
                if (header == null || !string.Equals(header.Scheme, "Basic", StringComparison.OrdinalIgnoreCase) ||
                    string.IsNullOrWhiteSpace(header.Parameter) || header.Parameter.Length > 6400)
                {
                    Reject(context, HttpStatusCode.Unauthorized);
                    return;
                }

                var pair = new UTF8Encoding(false, true).GetString(Convert.FromBase64String(header.Parameter))
                    .Split(new[] { ':' }, 2);
                if (pair.Length != 2 || string.IsNullOrWhiteSpace(pair[0]) || string.IsNullOrWhiteSpace(pair[1]) ||
                    pair[0].Length > 200 || pair[1].Length > 1000)
                {
                    Reject(context, HttpStatusCode.Unauthorized);
                    return;
                }

                var brand = Store.Authenticate(pair[0], pair[1]);
                // No fixed credential fallback, including before brand configuration exists.
                if (brand <= 0)
                {
                    Reject(context, HttpStatusCode.Unauthorized);
                    return;
                }

                context.Request.Properties["AttendanceAuthenticatedBrandID"] = brand;
            }
            catch (FormatException)
            {
                Reject(context, HttpStatusCode.Unauthorized);
            }
            catch (DecoderFallbackException)
            {
                Reject(context, HttpStatusCode.Unauthorized);
            }
            catch (SqlException)
            {
                Reject(context, HttpStatusCode.ServiceUnavailable);
            }
            catch (Exception)
            {
                Reject(context, HttpStatusCode.InternalServerError);
            }
        }

        protected static void Reject(HttpActionContext context, HttpStatusCode status)
        {
            context.Response = context.Request.CreateResponse(status,
                new
                {
                    Success = false,
                    Code = status == HttpStatusCode.Unauthorized ? "API_UNAUTHORIZED" : "API_UNAVAILABLE",
                    Message = "API authentication could not be completed."
                });
            context.Response.Headers.CacheControl = new CacheControlHeaderValue
                { NoStore = true };
        }
    }
}
