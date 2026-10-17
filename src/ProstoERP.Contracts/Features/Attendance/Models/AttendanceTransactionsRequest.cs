using System;
using System.Collections.Generic;
using System.Globalization;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Attendance
{
    public sealed class AttendanceTransactionsRequest
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public string EmployeeCode { get; set; }
        public string FromDate { get; set; }
        public string ToDate { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> Extra { get; set; }

        public bool IsValid()
        {
            DateTime from, to;
            return !string.IsNullOrWhiteSpace(Username) && !string.IsNullOrWhiteSpace(Password)
                                                        && !string.IsNullOrWhiteSpace(EmployeeCode) &&
                                                        EmployeeCode.Length <= 200
                                                        && DateTime.TryParseExact(FromDate, "yyyy-MM-dd",
                                                            CultureInfo.InvariantCulture, DateTimeStyles.None, out from)
                                                        && DateTime.TryParseExact(ToDate, "yyyy-MM-dd",
                                                            CultureInfo.InvariantCulture, DateTimeStyles.None, out to)
                                                        && from <= to && (Extra == null || Extra.Count == 0);
        }
    }
}
