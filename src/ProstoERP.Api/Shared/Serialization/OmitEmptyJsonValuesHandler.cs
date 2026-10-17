using System.Linq;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Serialization
{
    public sealed class OmitEmptyJsonValuesHandler : DelegatingHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var response = await base.SendAsync(request, cancellationToken);
            var content = response.Content as ObjectContent;
            var formatter = content == null ? null : content.Formatter as JsonMediaTypeFormatter;
            if (formatter == null || content.Value == null ||
                content.Value is Swashbuckle.Swagger.SwaggerDocument)
                return response;

            // Serialize once before pruning: dictionaries, DBNull and lazy collections
            // receive the same JSON representation as ordinary DTO properties.
            var token = JToken.FromObject(content.Value, formatter.CreateJsonSerializer());
            OmitEmptyProperties(token);
            var replacement = new ObjectContent<JToken>(token, formatter, content.Headers.ContentType);
            foreach (var header in content.Headers)
            {
                if (header.Key.Equals("Content-Type", System.StringComparison.OrdinalIgnoreCase) ||
                    header.Key.Equals("Content-Length", System.StringComparison.OrdinalIgnoreCase))
                    continue;
                replacement.Headers.TryAddWithoutValidation(header.Key, header.Value);
            }
            response.Content = replacement;
            content.Dispose();
            return response;
        }

        private static void OmitEmptyProperties(JToken token)
        {
            var obj = token as JObject;
            if (obj != null)
            {
                foreach (var property in obj.Properties().ToList())
                {
                    OmitEmptyProperties(property.Value);
                    if (IsEmpty(property.Value)) property.Remove();
                }
                return;
            }

            var array = token as JArray;
            if (array != null)
            {
                // Preserve indexes, record counts and ordering; omit fields within items.
                foreach (var item in array) OmitEmptyProperties(item);
            }
        }

        private static bool IsEmpty(JToken value)
        {
            return value.Type == JTokenType.Null || value.Type == JTokenType.Undefined ||
                (value.Type == JTokenType.String && value.Value<string>() == string.Empty) ||
                (value is JContainer && !value.HasValues);
        }
    }
}
