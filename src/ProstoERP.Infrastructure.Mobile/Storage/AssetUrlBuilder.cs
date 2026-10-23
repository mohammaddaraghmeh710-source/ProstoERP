using System;
using System.Configuration;
using ProstoERP.Application.Abstractions;
namespace ProstoERP.Infrastructure.Mobile.Storage
{
    public sealed class AssetUrlBuilder : IAssetUrlBuilder
    {
        private readonly IMobileOptions options;
        public AssetUrlBuilder(IMobileOptions options) { this.options = options; }
        public string AssetUrl(object value)
        {
            var path = Convert.ToString(value).Trim();
            if (path.Length == 0) return null;
            Uri absolute;
            if (path.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                path.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                if (!Uri.TryCreate(path, UriKind.Absolute, out absolute)) return null;
                return absolute.Scheme == Uri.UriSchemeHttps || absolute.Scheme == Uri.UriSchemeHttp
                    ? absolute.AbsoluteUri
                    : null;
            }

            if (path.Contains(":")) return null;
            var baseUrl = options.AssetBaseUrl;
            if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out absolute) || absolute.Scheme != Uri.UriSchemeHttps)
                throw new ConfigurationErrorsException("MobileApi.AssetBaseUrl must be an HTTPS URL.");
            return new Uri(new Uri(baseUrl.TrimEnd('/') + "/"), path.Replace('\\', '/').TrimStart('~', '/'))
                .AbsoluteUri;
        }
    }
}
