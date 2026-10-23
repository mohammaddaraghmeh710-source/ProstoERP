using System.Collections.Generic;

namespace ProstoERP.Contracts.Features.Feedback
{
    public sealed class FileRules
    {
        public int MaxFiles { get; set; }
        public int MaxFileBytes { get; set; }
        public int MaxImagePixels { get; set; }
        public string[] Extensions { get; set; }
    }
    public sealed class FeedbackStatus
    {
        public int ID { get; set; }
        public string Title { get; set; }
    }
    public sealed class FeedbackOptionsResponse
    {
        public IList<Dictionary<string, object>> Types { get; set; }
        public IList<Dictionary<string, object>> Topics { get; set; }
        public Dictionary<string, object> Permissions { get; set; }
        public IList<Dictionary<string, object>> RecipientTypes { get; set; }
        public FeedbackStatus[] Statuses { get; set; }
        public FileRules FileRules { get; set; }
        public int MaxTitleLength { get; set; }
        public int MaxDetailsLength { get; set; }
        public int MaxCommentLength { get; set; }
    }
    public sealed class FeedbackRoutingResponse
    {
        public int RecipientTypeID { get; set; }
        public IList<Dictionary<string, object>> Recipients { get; set; }
        public bool CanSend { get; set; }
        public bool IsFallback { get; set; }
        public string Message { get; set; }
    }
    public sealed class FeedbackActionOption
    {
        public string Code { get; set; }
        public string Title { get; set; }
        public bool CommentRequired { get; set; }
        public bool RecipientRequired { get; set; }
    }
    public sealed class FeedbackDetailResponse
    {
        public Dictionary<string, object> Request { get; set; }
        public Dictionary<string, object> Contact { get; set; }
        public IList<Dictionary<string, object>> Attachments { get; set; }
        public IList<Dictionary<string, object>> Workflow { get; set; }
        public IList<FeedbackActionOption> AllowedActions { get; set; }
        public IList<Dictionary<string, object>> RecipientTypes { get; set; }
        public bool Replayed { get; set; }
    }
}
