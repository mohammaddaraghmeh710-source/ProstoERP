using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Mobile
{
    internal static class MobileApiSupport
    {
        internal static int IdleMinutes { get { return Setting("MobileApi.IdleMinutes", 480); } }
        internal static int MaximumMinutes { get { return Setting("MobileApi.MaximumMinutes", 43200); } }
        private static int Setting(string key, int fallback)
        {
            string value = ConfigurationManager.AppSettings[key];
            int number;
            if (value == null) return fallback;
            if (!int.TryParse(value, out number) || number < 1 || number > 525600)
                throw new ConfigurationErrorsException("Invalid setting: " + key);
            return number;
        }

        internal static DataSet Query(string procedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString))
            using (var command = new SqlCommand(procedure, connection))
            using (var adapter = new SqlDataAdapter(command))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddRange(parameters);
                var result = new DataSet();
                adapter.Fill(result);
                return result;
            }
        }
        internal static DataSet QueryDeviceAccess(MobileLoginRequest model, bool submit)
        {
            return MobileApiSupport.Query("dbo.MobileApi_DeviceAccess",
                    MobileApiSupport.P("@Username", SqlDbType.NVarChar, model.Username, 250),
                    MobileApiSupport.P("@EncryptedPassword", SqlDbType.NVarChar, new Echo.Encrptor.TripleDesEncryptor().Encrypt(model.Password), -1),
                    MobileApiSupport.P("@AppVersion", SqlDbType.NVarChar, model.AppVersion, 50),
                    MobileApiSupport.P("@AppBuild", SqlDbType.NVarChar, model.AppBuild, 50),
                    MobileApiSupport.P("@DeviceID", SqlDbType.NVarChar, model.Device.DeviceID, 128),
                    MobileApiSupport.P("@DevicePlatform", SqlDbType.NVarChar, model.Device.Platform, 16),
                    MobileApiSupport.P("@DeviceManufacturer", SqlDbType.NVarChar, model.Device.Manufacturer, 100),
                    MobileApiSupport.P("@DeviceModel", SqlDbType.NVarChar, model.Device.Model, 150),
                    MobileApiSupport.P("@OSVersion", SqlDbType.NVarChar, model.Device.OSVersion, 50),
                    MobileApiSupport.P("@MACID", SqlDbType.VarChar, model.Device.MACID, 17),
                    MobileApiSupport.P("@Submit", SqlDbType.Bit, submit));
        }
        internal static SqlParameter P(string name, SqlDbType type, object value, int size = 0)
        {
            return new SqlParameter(name, type) { Size = size, Value = value ?? DBNull.Value };
        }
        internal static Dictionary<string, object> Row(DataRow row)
        {
            return row.Table.Columns.Cast<DataColumn>().ToDictionary(c => c.ColumnName, c =>
            {
                object value = row[c];
                if (value == DBNull.Value) return null;
                if (value is DateTime && (c.ColumnName.EndsWith("Utc") || c.ColumnName.EndsWith("ExpiresAt")))
                    return (object)DateTime.SpecifyKind((DateTime)value, DateTimeKind.Utc);
                return value;
            });
        }
        internal static string NewToken()
        {
            byte[] bytes = new byte[32];
            using (var random = RandomNumberGenerator.Create()) random.GetBytes(bytes);
            return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }
        internal static byte[] TokenHash(string token)
        {
            if (token == null || !Regex.IsMatch(token, @"\A[A-Za-z0-9_-]{43}\z")) return null;
            byte[] bytes;
            try { bytes = Convert.FromBase64String(token.Replace('-', '+').Replace('_', '/') + "="); }
            catch (FormatException) { return null; }
            if (Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_') != token) return null;
            using (var hash = SHA256.Create()) return hash.ComputeHash(bytes);
        }
        internal static bool TransportAllowed(HttpRequestMessage request)
        {
            if (request.RequestUri.Scheme == Uri.UriSchemeHttps) return true;
            bool enabled;
            // Temporary deployment setting; missing or false requires HTTPS.
            return request.RequestUri.Scheme == Uri.UriSchemeHttp &&
                bool.TryParse(ConfigurationManager.AppSettings["MobileApi.AllowHttp"], out enabled) && enabled;
        }
        internal static string AssetUrl(object value)
        {
            string path = Convert.ToString(value).Trim();
            if (path.Length == 0) return null;
            Uri absolute;
            if (path.StartsWith("http://", StringComparison.OrdinalIgnoreCase) || path.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                if (!Uri.TryCreate(path, UriKind.Absolute, out absolute)) return null;
                return absolute.Scheme == Uri.UriSchemeHttps || absolute.Scheme == Uri.UriSchemeHttp ? absolute.AbsoluteUri : null;
            }
            if (path.Contains(":")) return null;
            string baseUrl = ConfigurationManager.AppSettings["MobileApi.AssetBaseUrl"];
            if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out absolute) || absolute.Scheme != Uri.UriSchemeHttps)
                throw new ConfigurationErrorsException("MobileApi.AssetBaseUrl must be an HTTPS URL.");
            return new Uri(new Uri(baseUrl.TrimEnd('/') + "/"), path.Replace('\\', '/').TrimStart('~', '/')).AbsoluteUri;
        }
        internal static HttpResponseMessage Error(HttpRequestMessage request, HttpStatusCode status, string code, string message)
        {
            var response = request.CreateResponse(status, new { Success = false, Error = new { Code = code, Message = message } });
            NoCache(response);
            if (status == HttpStatusCode.Unauthorized) response.Headers.WwwAuthenticate.Add(new AuthenticationHeaderValue("Bearer"));
            return response;
        }
        internal static void NoCache(HttpResponseMessage response)
        {
            response.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true, Private = true };
        }
    }

    public sealed class MobileTransportAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            // Never trust caller-supplied forwarding headers as proof of TLS.
            if (!MobileApiSupport.TransportAllowed(context.Request))
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Forbidden, "HTTPS_REQUIRED", "Use HTTPS for mobile API requests.");
        }
    }

    public sealed class MobileSessionAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            if (context.Response != null) return;
            if (!MobileApiSupport.TransportAllowed(context.Request))
            {
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Forbidden, "HTTPS_REQUIRED", "Use HTTPS for mobile API requests.");
                return;
            }
            var authorization = context.Request.Headers.Authorization;
            byte[] hash = authorization != null && string.Equals(authorization.Scheme, "Bearer", StringComparison.OrdinalIgnoreCase)
                ? MobileApiSupport.TokenHash(authorization.Parameter) : null;
            if (hash == null) { Unauthorized(context); return; }
            try
            {
                var result = MobileApiSupport.Query("dbo.MobileApi_Authenticate",
                    MobileApiSupport.P("@TokenHash", SqlDbType.Binary, hash, 32),
                    MobileApiSupport.P("@IdleMinutes", SqlDbType.Int, MobileApiSupport.IdleMinutes));
                if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0) { Unauthorized(context); return; }
                var session = result.Tables[0].Rows[0];
                var identity = new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier,
                    Convert.ToString(session["UserID"], CultureInfo.InvariantCulture)) }, "Bearer");
                var principal = new ClaimsPrincipal(identity);
                context.RequestContext.Principal = principal;
                Thread.CurrentPrincipal = principal;
                if (HttpContext.Current != null) HttpContext.Current.User = principal;
                context.Request.Properties["MobileSession"] = MobileApiSupport.Row(session);
                context.Request.Properties["MobileTokenHash"] = hash;
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API authentication failed ({0}).", ex.GetType().Name);
                context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.InternalServerError, "SERVER_ERROR", "Unable to authenticate the request.");
            }
        }
        private static void Unauthorized(HttpActionContext context)
        {
            context.Response = MobileApiSupport.Error(context.Request, HttpStatusCode.Unauthorized,
                "SESSION_INVALID", "Sign in again. The session is missing, expired, or revoked.");
        }
    }

    public sealed class MobileLoginRequest
    {
        [Required, StringLength(250)] public string Username { get; set; }
        [Required, StringLength(1024)] public string Password { get; set; }
        [Required, StringLength(50)] public string AppVersion { get; set; }
        [StringLength(50)] public string AppBuild { get; set; }
        [Required] public MobileLoginDevice Device { get; set; }

        internal bool NormalizeAndValidate()
        {
            if (!Validator.TryValidateObject(this,new ValidationContext(this),new List<ValidationResult>(),true) ||
                Device == null || !Validator.TryValidateObject(Device,new ValidationContext(Device),new List<ValidationResult>(),true)) return false;
            Username=Username.Trim(); AppVersion=AppVersion.Trim(); AppBuild=Clean(AppBuild);
            Device.DeviceID=Device.DeviceID.Trim(); Device.Model=Device.Model.Trim(); Device.OSVersion=Device.OSVersion.Trim();
            Device.Manufacturer=Clean(Device.Manufacturer);
            if (string.Equals(Device.Platform,"Android",StringComparison.OrdinalIgnoreCase)) Device.Platform="Android";
            else if (string.Equals(Device.Platform,"iOS",StringComparison.OrdinalIgnoreCase)) Device.Platform="iOS";
            else return false;
            string mac=Clean(Device.MACID);
            if (mac!=null)
            {
                if (!Regex.IsMatch(mac,@"\A(?:[0-9a-fA-F]{12}|(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2})\z")) return false;
                mac=mac.Replace(":","").Replace("-","").ToUpperInvariant();
                // Common OS privacy placeholders are not real device MAC addresses.
                Device.MACID=new[]{"000000000000","020000000000","FFFFFFFFFFFF"}.Contains(mac) ? null :
                    string.Join(":",Enumerable.Range(0,6).Select(i=>mac.Substring(i*2,2)));
            }
            else Device.MACID=null;
            return true;
        }
        static string Clean(string value) { return string.IsNullOrWhiteSpace(value) ? null : value.Trim(); }
    }
    public sealed class MobileLoginDevice
    {
        [Required,StringLength(128)] public string DeviceID { get; set; }
        [Required,StringLength(16)] public string Platform { get; set; }
        [StringLength(100)] public string Manufacturer { get; set; }
        [Required,StringLength(150)] public string Model { get; set; }
        [Required,StringLength(50)] public string OSVersion { get; set; }
        [StringLength(32)] public string MACID { get; set; }
    }
}
