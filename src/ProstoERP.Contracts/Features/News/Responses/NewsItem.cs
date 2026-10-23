using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ProstoERP.Contracts.Features.News
{
    public sealed class NewsItem
    {
        public int? PID { get; set; }
        public string Title_AR { get; set; }
        public string Title_En { get; set; }
        public string Brief_Ar { get; set; }
        public string Brief_En { get; set; }
        public string Details { get; set; }
        public string Image { get; set; }
        public DateTime? Date { get; set; }
        public int? Item_Order { get; set; }
        public int? AddedUser { get; set; }
        public DateTime? AddedDate { get; set; }
        public int? ModifyUser { get; set; }
        public DateTime? ModifyDate { get; set; }
        public bool? IsDeleted { get; set; }
        public bool? IsActive { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> AdditionalFields { get; set; }
    }
}
