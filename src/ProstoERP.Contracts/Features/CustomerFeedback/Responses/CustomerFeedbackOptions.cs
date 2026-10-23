using System.Collections.Generic;
using ProstoERP.Contracts.Features.Feedback;

namespace ProstoERP.Contracts.Features.CustomerFeedback
{
    public sealed class CustomerFeedbackOptions
    {
        public IList<Dictionary<string, object>> Types { get; set; }
        public IList<Dictionary<string, object>> Brands { get; set; }
        public IList<Dictionary<string, object>> Branches { get; set; }
        public IList<Dictionary<string, object>> Topics { get; set; }
        public int SourceType { get; set; }
        public string RecipientTitle { get; set; }
        public FileRules FileRules { get; set; }
        public string[] RequiredContactFields { get; set; }
        public int MaxTitleLength { get; set; }
        public int MaxDetailsLength { get; set; }
    }
}
