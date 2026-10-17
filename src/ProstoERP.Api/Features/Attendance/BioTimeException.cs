using System;
using System.Net;

namespace Prosto_ERP_API.Attendance
{
    public sealed class BioTimeException : Exception
    {
        public BioTimeException(HttpStatusCode status, string code, string message) : base(message)
        {
            Status = status;
            Code = code;
        }

        public HttpStatusCode Status { get; private set; }
        public string Code { get; private set; }
    }
}
