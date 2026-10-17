using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Http;
using System.Web.Http.Description;
using Prosto_ERP_API.Authentication;
using Prosto_ERP_API.Mobile;
using Swashbuckle.Application;
using Swashbuckle.Swagger;

namespace Prosto_ERP_API
{
    public static class SwaggerConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Serve only the generator here; the MVC page uses locally hosted Swagger UI.
            config.EnableSwagger(c =>
            {
                c.SingleApiVersion("v1", "Prosto ERP API")
                    .Description("Explore and test the ERP API. Login returns an access token for employee endpoints. " +
                                 "Use Authorize with Bearer followed by a space and the token. " +
                                 "Integration and attendance endpoints use their configured Basic credentials. " +
                                 "JSON responses omit null, empty-string and empty-collection properties recursively; " +
                                 "false and zero remain present. Optional Data may be absent when empty.");
                c.UseFullTypeNameInSchemaIds();
                c.BasicAuth("basic").Description("Integration credentials, or brand attendance credentials for attendance endpoints.");
                c.ApiKey("bearer").Name("Authorization").In("header")
                    .Description("Enter Bearer followed by a space and the access token returned by login.");
                c.OperationFilter<SwaggerAuthenticationFilter>();
            });
        }
    }

    public sealed class SwaggerAuthenticationFilter : IOperationFilter
    {
        public void Apply(Operation operation, SchemaRegistry schemaRegistry, ApiDescription apiDescription)
        {
            // Overloaded actions (for example Values.Get) must have distinct operation IDs.
            operation.operationId += "_" + apiDescription.HttpMethod.Method + "_" +
                Regex.Replace(apiDescription.RelativePath.Split('?')[0], "[^a-zA-Z0-9_]", "_");
            var action = apiDescription.ActionDescriptor;
            var filters = action.GetFilterPipeline().Select(f => f.Instance).ToList();
            if (action.GetCustomAttributes<AllowAnonymousAttribute>().Any() ||
                action.ControllerDescriptor.GetCustomAttributes<AllowAnonymousAttribute>().Any()) return;

            string scheme = null;
            if (filters.Any(f => f is MobileSessionAttribute || f is CustomerSessionAttribute)) scheme = "bearer";
            else if (filters.Any(f => f is AuthenticationAttribute || f is AttendanceCredentialAuthenticationAttribute)) scheme = "basic";
            if (scheme == null) return;

            operation.security = new List<IDictionary<string, IEnumerable<string>>>
            {
                new Dictionary<string, IEnumerable<string>> { { scheme, new string[0] } }
            };
            if (!operation.responses.ContainsKey("401"))
                operation.responses.Add("401", new Response { description = "Missing, invalid or expired credentials." });
        }
    }
}
