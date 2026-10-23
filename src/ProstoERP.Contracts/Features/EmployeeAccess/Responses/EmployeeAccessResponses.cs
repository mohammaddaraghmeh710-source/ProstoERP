using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ProstoERP.Contracts.Features.EmployeeAccess
{
    public sealed class EmployeeLookup
    {
        public int? ID { get; set; }
        public string Title_Ar { get; set; }
        public string Title_En { get; set; }
    }

    public sealed class EmployeeProfile
    {
        public int? ID { get; set; }
        public int? Employee_Number { get; set; }
        public string FullName_Ar { get; set; }
        public string Fullname_En { get; set; }
        public string User_Image { get; set; }
        public string PhoneNumber { get; set; }
        public string MobileNumber { get; set; }
        public string Email { get; set; }
        public string UserName { get; set; }
        public string BIOID { get; set; }
        public EmployeeLookup userType { get; set; }
        public EmployeeLookup brand { get; set; }
        public EmployeeLookup branch { get; set; }
        public EmployeeLookup department { get; set; }
        public EmployeeLookup jobTitle { get; set; }
        public EmployeeLookup shift { get; set; }
        public EmployeeLookup gender { get; set; }
        public EmployeeLookup nationality { get; set; }
    }

    public sealed class EmployeeSession
    {
        public int? UserID { get; set; }
        public int? EmployeeNumber { get; set; }
        public string AppVersion { get; set; }
        public string AppBuild { get; set; }
        public string DeviceID { get; set; }
        public string DevicePlatform { get; set; }
        public string DeviceManufacturer { get; set; }
        public string DeviceModel { get; set; }
        public string OSVersion { get; set; }
        public string MACID { get; set; }
        public DateTime? CreatedUtc { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime? AbsoluteExpiresAt { get; set; }

        // Legacy session procedures may supply additional fields; preserve their existing wire shape.
        [JsonExtensionData] public IDictionary<string, JToken> AdditionalFields { get; set; }
    }

    public sealed class EmployeeLoginResponse
    {
        public EmployeeProfile User { get; set; }
        public string AccessToken { get; set; }
        public string TokenType { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime? AbsoluteExpiresAt { get; set; }
        public int IdleTimeoutMinutes { get; set; }
        public EmployeeSession Session { get; set; }
    }

    public sealed class DeviceAccessResponse
    {
        public int? RequestID { get; set; }
        public string Status { get; set; }
        public bool? CanLogin { get; set; }
        public DateTime? CreatedUtc { get; set; }
        public DateTime? DecidedUtc { get; set; }
        [JsonExtensionData] public IDictionary<string, JToken> AdditionalFields { get; set; }
    }
}
