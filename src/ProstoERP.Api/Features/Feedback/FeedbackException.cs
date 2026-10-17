using System;
using System.Net;

namespace Prosto_ERP_API.Mobile
{
    internal sealed class FeedbackException : Exception {
        internal readonly HttpStatusCode Status; internal readonly string Code;
        internal FeedbackException(HttpStatusCode status,string code,string message):base(message) { Status=status; Code=code; }
    }
}
