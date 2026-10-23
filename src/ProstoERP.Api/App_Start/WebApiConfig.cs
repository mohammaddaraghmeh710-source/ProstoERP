using System.Web.Http;
using Prosto_ERP_API.Serialization;

namespace Prosto_ERP_API
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Web API configuration and services
            config.DependencyResolver = new Prosto_ERP_API.Composition.MobileDependencyResolver(config.DependencyResolver);
            config.MessageHandlers.Add(new OmitEmptyJsonValuesHandler());

            // Web API routes
            config.MapHttpAttributeRoutes();

            config.Routes.MapHttpRoute(
                "DefaultApi",
                "api/{controller}/{id}",
                new { id = RouteParameter.Optional }
            );
            SwaggerConfig.Register(config);
        }
    }
}
