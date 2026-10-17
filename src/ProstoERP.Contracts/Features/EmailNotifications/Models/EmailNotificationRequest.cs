using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Controllers
{
 public sealed class EmailNotificationRequest
 {
  [Range(1,int.MaxValue)] public int BrandID{get;set;}
  [Required,StringLength(254)] public string To{get;set;}
  [Required,StringLength(200)] public string Subject{get;set;}
  [Required,StringLength(200000)] public string Body{get;set;}
  [JsonExtensionData] public IDictionary<string,JToken> Extra{get;set;}
 }
}
