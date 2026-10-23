using System;
using System.Net;

namespace Prosto_ERP_API.Mobile
{
    public sealed class FeedbackException : Exception
    {
        public readonly string Code;
        public readonly HttpStatusCode Status;

        public FeedbackException(HttpStatusCode status, string code, string message) : base(message)
        {
            Status = status;
            Code = code;
        }
    }
}
