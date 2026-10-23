using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ProstoERP.Contracts.Features.EmployeeAccess
{
    public sealed class InformationPage
    {
        public int? ID { get; set; }
        public string Title_Ar { get; set; }
        public string Title_En { get; set; }
        public string Summary_Ar { get; set; }
        public string Summary_En { get; set; }
        public string Details_Ar { get; set; }
        public string Details_En { get; set; }
        public int? Item_Order { get; set; }
        public bool? IsPublished { get; set; }
        public string PublishMode { get; set; }
        public DateTime? StartUtc { get; set; }
        public DateTime? EndUtc { get; set; }
        public int? VersionNumber { get; set; }
        public DateTime? CreatedUtc { get; set; }
        public DateTime? ModifiedUtc { get; set; }
        public bool? AllUserTypes { get; set; }
        public int? AccessRevision { get; set; }
        public int[] UserTypeIDs { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> AdditionalFields { get; set; }
    }
}
