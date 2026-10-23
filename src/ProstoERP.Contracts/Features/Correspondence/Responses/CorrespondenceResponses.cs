using System;
using System.Collections.Generic;

namespace ProstoERP.Contracts.Features.Correspondence
{
    public sealed class CorrespondencePermissions
    {
        public bool CanCreate { get; set; }
        public bool CanCreateTask { get; set; }
        public bool CanBroadcast { get; set; }
        public bool CanSupervise { get; set; }
    }
    public sealed class CorrespondenceCatalogItem
    {
        public object ID { get; set; }
        public object Title { get; set; }
        public object SortOrder { get; set; }
        public object IsUrgent { get; set; }
        public object Behavior { get; set; }
        public object IsActive { get; set; }
    }
    public sealed class CorrespondenceFileRules
    {
        public int MaxFiles { get; set; }
        public int MaxFileBytes { get; set; }
        public string[] Extensions { get; set; }
    }
    public sealed class CorrespondenceLimits
    {
        public int MaxTitle { get; set; }
        public int MaxBrief { get; set; }
        public int MaxBody { get; set; }
        public int MaxReason { get; set; }
        public int MaxRecipients { get; set; }
    }
    public sealed class CorrespondenceOptionsResponse
    {
        public Dictionary<string, object> Identity { get; set; }
        public CorrespondencePermissions Permissions { get; set; }
        public IEnumerable<CorrespondenceCatalogItem> Priorities { get; set; }
        public IEnumerable<CorrespondenceCatalogItem> ClosureReasons { get; set; }
        public IEnumerable<CorrespondenceCatalogItem> PriorityFilters { get; set; }
        public IEnumerable<Dictionary<string, object>> Brands { get; set; }
        public IEnumerable<Dictionary<string, object>> RecipientBranches { get; set; }
        public IEnumerable<Dictionary<string, object>> RecipientShifts { get; set; }
        public IEnumerable<Dictionary<string, object>> HistoricalOrganization { get; set; }
        public CorrespondenceFileRules FileRules { get; set; }
        public CorrespondenceLimits Limits { get; set; }
        public int PollIntervalSeconds { get; set; }
    }
    public sealed class CorrespondenceDetailResponse
    {
        public Dictionary<string, object> Thread { get; set; }
        public IEnumerable<Dictionary<string, object>> Organization { get; set; }
        public IEnumerable<Dictionary<string, object>> Related { get; set; }
        public Guid VisitID { get; set; }
        public IEnumerable<Dictionary<string, object>> Audit { get; set; }
    }
    public sealed class CorrespondenceMutationResponse
    {
        public int? ThreadID { get; set; }
        public int[] ThreadIDs { get; set; }
        public object MessageID { get; set; }
        public int[] MessageIDs { get; set; }
        public int? NotificationID { get; set; }
        public bool? Replayed { get; set; }
    }
    public sealed class CorrespondenceMessagesResponse
    {
        public Dictionary<string, object> Thread { get; set; }
        public IEnumerable<Dictionary<string, object>> Items { get; set; }
        public IEnumerable<Dictionary<string, object>> Attachments { get; set; }
        public object HasMore { get; set; }
        public object OldestID { get; set; }
        public object LatestID { get; set; }
    }
}
