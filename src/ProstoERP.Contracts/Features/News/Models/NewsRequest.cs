using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Mobile
{
    public sealed class NewsRequest
    {
        [Range(1, int.MaxValue)] public int BrandID { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> Extra { get; set; }
    }
}
