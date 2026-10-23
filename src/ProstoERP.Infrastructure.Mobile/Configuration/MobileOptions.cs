using System.Configuration;
using ProstoERP.Application.Abstractions;
namespace ProstoERP.Infrastructure.Mobile.Configuration
{
    // Read on use, retaining the original defaults and validation timing.
    public sealed class MobileOptions : IMobileOptions
    {
        public int IdleMinutes => Setting("MobileApi.IdleMinutes", 480);
        public int MaximumMinutes => Setting("MobileApi.MaximumMinutes", 43200);
        public string AssetBaseUrl => ConfigurationManager.AppSettings["MobileApi.AssetBaseUrl"];
        public string PortalRoot => ConfigurationManager.AppSettings["CustomerApi.PortalRoot"];
        public bool AllowHttp
        {
            get
            {
                bool enabled;
                return bool.TryParse(ConfigurationManager.AppSettings["MobileApi.AllowHttp"], out enabled) && enabled;
            }
        }
        private static int Setting(string key, int fallback)
        {
            var value = ConfigurationManager.AppSettings[key];
            int number;
            if (value == null) return fallback;
            if (!int.TryParse(value, out number) || number < 1 || number > 525600)
                throw new ConfigurationErrorsException("Invalid setting: " + key);
            return number;
        }
    }
}
