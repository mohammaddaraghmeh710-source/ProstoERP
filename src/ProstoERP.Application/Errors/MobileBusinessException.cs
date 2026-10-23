using System;
using System.Net;

namespace ProstoERP.Application.Errors
{
    public class MobileBusinessException : Exception
    {
        public string Code { get; private set; }
        public HttpStatusCode Status { get; private set; }
        public MobileBusinessException(HttpStatusCode status, string code, string message) : base(message)
        {
            Status = status;
            Code = code;
        }
    }
}
