using System;
using System.Data;
using System.Data.SqlClient;
using Newtonsoft.Json;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Features.Authentication;
using ProstoERP.Contracts.Features.Authentication;
using ProstoERP.Infrastructure.Mobile.Data;

namespace ProstoERP.Infrastructure.Mobile.Features.Authentication
{
    public sealed class AuthenticationStore : IAuthenticationStore
    {
        private readonly IMobileQueryStore queries;
        public AuthenticationStore(IMobileQueryStore queries) { this.queries = queries; }
        private static SqlParameter P(string name, object value) { return new SqlParameter("@" + name, value ?? DBNull.Value); }
        private DataSet Query(string procedure, params SqlParameter[] parameters) { return queries.Query(procedure, parameters); }
        private static DataRow First(DataSet rows) { return rows.Tables.Count == 0 || rows.Tables[0].Rows.Count == 0 ? null : rows.Tables[0].Rows[0]; }
        private static string Device(DeviceContextRequest model) { return JsonConvert.SerializeObject(new { model.AppVersion, model.AppBuild, model.Device }); }

        public void CheckRate(string scope, byte[] account, byte[] source)
        {
            Query("dbo.MobileAuth_Limit", P("Scope", scope), P("AccountHash", account), P("SourceHash", source));
        }
        public OtpRecipient BeginRegistration(Guid id, MobileLoginRequest model, string encryptedPassword, byte[] otpHash, string purpose)
        {
            var row = First(Query("dbo.MobileAuth_Register", P("ID", id), P("Username", model.Username), P("EncryptedPassword", encryptedPassword),
                P("OtpHash", otpHash), P("Purpose", purpose), P("DeviceJson", Device(new DeviceContextRequest { AppVersion = model.AppVersion, AppBuild = model.AppBuild, Device = model.Device }))));
            return new OtpRecipient { BrandID = (int)row["BrandID"], Email = (string)row["Email"], EmployeeName = Convert.ToString(row["EmployeeName"]), BrandName = Convert.ToString(row["BrandName"]) };
        }
        public void RegistrationDelivery(Guid id, bool sent) { Query("dbo.MobileAuth_Delivery", P("ID", id), P("Sent", sent)); }
        public void VerifyRegistration(Guid id, byte[] otpHash, string purpose) { Query("dbo.MobileAuth_Verify", P("ID", id), P("OtpHash", otpHash), P("Purpose", purpose)); }
        public void Logout(byte[] tokenHash) { Query("dbo.MobileApi_Logout", P("TokenHash", tokenHash)); }
        public void UpdateDevice(byte[] tokenHash, DeviceContextRequest model) { Query("dbo.MobileAuth_UpdateDevice", P("TokenHash", tokenHash), P("DeviceJson", Device(model))); }
        public void EnrollBiometric(Guid credential, byte[] tokenHash, string encryptedPassword, string modulus, string exponent)
        {
            Query("dbo.MobileAuth_EnrollBiometric", P("CredentialID", credential), P("TokenHash", tokenHash), P("EncryptedPassword", encryptedPassword), P("Modulus", modulus), P("Exponent", exponent));
        }
        public void BeginBiometric(Guid id, Guid credential, byte[] binding, string challenge, DeviceContextRequest device)
        {
            Query("dbo.MobileAuth_BiometricChallenge", P("ID", id), P("CredentialID", credential), P("Binding", binding), P("Challenge", challenge), P("DeviceID", device.Device.DeviceID), P("Platform", device.Device.Platform));
        }
        public DataRow ConsumeBiometric(Guid id, Guid credential, byte[] binding)
        {
            return First(Query("dbo.MobileAuth_ConsumeBiometric", P("ID", id), P("CredentialID", credential), P("Binding", binding)));
        }
        public DataSet BiometricLogin(Guid credential, byte[] tokenHash, int idleMinutes, int maximumMinutes, DeviceContextRequest device)
        {
            return Query("dbo.MobileAuth_BiometricLogin", P("CredentialID", credential), P("TokenHash", tokenHash), P("IdleMinutes", idleMinutes), P("MaximumMinutes", maximumMinutes), P("DeviceJson", Device(device)));
        }
    }
}
