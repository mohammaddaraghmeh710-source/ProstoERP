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
            return Responses.ApiResponseHandler.Error(request, status, code, message);
        }
        internal static void NoCache(HttpResponseMessage response)
        {
            response.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true, Private = true };
        }
    }

}
