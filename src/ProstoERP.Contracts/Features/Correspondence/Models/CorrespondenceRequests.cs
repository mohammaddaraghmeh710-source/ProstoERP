using System.ComponentModel.DataAnnotations;

namespace Prosto_ERP_API.Mobile
{
    public sealed class CorrespondenceOpen : FeedbackEvent
    {
        public bool Supervisory { get; set; }
    }

    public class CorrespondenceReply : FeedbackEvent
    {
        [StringLength(4000)] public string Body { get; set; }
    }

    public sealed class CorrespondenceCreate : CorrespondenceReply
    {
        [Required] [StringLength(200)] public string Title { get; set; }
        [StringLength(2000)] public string Brief { get; set; }
        public int[] RecipientIDs { get; set; }
        [Range(0, int.MaxValue)] public int BrandID { get; set; }
        [Range(1, int.MaxValue)] public int PriorityID { get; set; }
        public bool RequiresCompletion { get; set; }
        [StringLength(40)] public string DueDate { get; set; }
        [Range(1, int.MaxValue)] public int? RelatedThreadID { get; set; }
    }

    public sealed class CorrespondenceClose : FeedbackEvent
    {
        [Range(1, int.MaxValue)] public int ClosureReasonID { get; set; }
        public bool? IsCompleted { get; set; }
        [StringLength(1000)] public string Explanation { get; set; }
    }

    public sealed class CorrespondenceRead : FeedbackEvent
    {
        public int[] MessageIDs { get; set; }
    }

    public sealed class CorrespondenceArchive : FeedbackEvent
    {
        [Required] [StringLength(1000)] public string Explanation { get; set; }
    }
}
