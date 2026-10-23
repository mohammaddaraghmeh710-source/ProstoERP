using System.Configuration;

namespace Prosto_ERP_API.Authentication
{
    internal static class IntegrationCredentials
    {
        internal static string Username => ConfigurationManager.AppSettings["Integration.BasicUsername"];
        internal static string Password => ConfigurationManager.AppSettings["Integration.BasicPassword"];
    }
}
