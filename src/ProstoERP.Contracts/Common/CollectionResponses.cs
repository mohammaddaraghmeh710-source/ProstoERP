using System.Collections.Generic;

namespace ProstoERP.Contracts.Common
{
    // These preserve the existing distinct envelopes; do not silently normalize Total/TotalItems/Count.
    public sealed class CountResponse<T, TSession>
    {
        public bool Success { get; set; }
        public int Count { get; set; }
        public IList<T> Data { get; set; }
        public TSession Session { get; set; }
    }

    public sealed class PagedItems<T>
    {
        public object Total { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public IEnumerable<T> Items { get; set; }
    }

    public sealed class CountedPage<T, TCounts>
    {
        public TCounts Counts { get; set; }
        public object TotalItems { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public IEnumerable<T> Items { get; set; }
    }

    public sealed class NotificationPage<T>
    {
        public int UnreadCount { get; set; }
        public int TotalItems { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public IEnumerable<T> Items { get; set; }
    }

    public sealed class SavedRequestResponse
    {
        public int RequestID { get; set; }
        public bool Replayed { get; set; }
        public string Message { get; set; }
    }

    public sealed class SavedCustomerFeedbackResponse
    {
        public int RequestID { get; set; }
        public int SourceType { get; set; }
        public bool Replayed { get; set; }
        public string Message { get; set; }
    }

    public sealed class TotalItemsPage<T>
    {
        public object TotalItems { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public IEnumerable<T> Items { get; set; }
    }
}
