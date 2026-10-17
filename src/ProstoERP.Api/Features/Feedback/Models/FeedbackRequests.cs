using System;
using System.ComponentModel.DataAnnotations;

namespace Prosto_ERP_API.Mobile
{
    public class FeedbackIdentity { [Range(1,int.MaxValue)] public int EmployeeNumber { get;set; } }
    public class FeedbackEvent : FeedbackIdentity {
        public Guid OperationID { get;set; }
        [Required,StringLength(40)] public string OccurredAt { get;set; }
    }
    public sealed class FeedbackRouting : FeedbackIdentity {
        [Range(1,int.MaxValue)] public int RecipientTypeID { get;set; }
        [Range(1,int.MaxValue)] public int? RequestID { get;set; }
    }
    public sealed class FeedbackCreate : FeedbackEvent {
        [Range(1,int.MaxValue)] public int TypeID { get;set; }
        [Range(1,int.MaxValue)] public int TopicID { get;set; }
        [Required,StringLength(300)] public string Title { get;set; }
        [Required,StringLength(10000)] public string Details { get;set; }
        [Required] public bool? DiscloseIdentity { get;set; }
        [Range(1,int.MaxValue)] public int RecipientTypeID { get;set; }
    }
    public sealed class FeedbackAction : FeedbackEvent {
        [Required] public string Action { get;set; }
        [Required,StringLength(10000)] public string Comment { get;set; }
        [Required,StringLength(12)] public string RowVersion { get;set; }
        [Range(1,int.MaxValue)] public int? RecipientTypeID { get;set; }
    }
}
