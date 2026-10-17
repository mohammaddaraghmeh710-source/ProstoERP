using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Mobile
{
    public sealed class BioLoginRequest
    {
        [Required, StringLength(43, MinimumLength = 43)] public string BIOID { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> Extra { get; set; }
    }
}
