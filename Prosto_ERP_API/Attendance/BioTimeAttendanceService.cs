using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Attendance
{
    public sealed class BioTimeException : Exception
    {
        public HttpStatusCode Status { get; private set; }
        public string Code { get; private set; }
        public BioTimeException(HttpStatusCode status, string code, string message) : base(message)
        { Status = status; Code = code; }
    }

    public sealed class BioTimeAttendanceService
    {
        const string TransactionsPath = "/iclock/api/transactions/";
        readonly Uri BaseUri;
        // Reuse connections; do not share cookies, credentials or authorization headers.
        static readonly HttpClient SharedClient = new HttpClient(new HttpClientHandler
            { AllowAutoRedirect = false, UseCookies = false, UseProxy = false })
            { Timeout = TimeSpan.FromSeconds(30), MaxResponseContentBufferSize = 8 * 1024 * 1024 };
        readonly HttpClient client;
        public BioTimeAttendanceService() : this(SharedClient) { }
        public BioTimeAttendanceService(HttpClient client) : this(client, "http://127.0.0.1:8089/") { }
        public BioTimeAttendanceService(string baseUrl) : this(SharedClient, baseUrl) { }
        public BioTimeAttendanceService(HttpClient client, string baseUrl) { this.client = client; BaseUri = new Uri(Prosto_ERP_ClassLibrary.AttendanceIntegration.NormalizeUrl(baseUrl, true)); }

        public BioTimeAttendanceService WithBaseUrl(string baseUrl) { return new BioTimeAttendanceService(client, baseUrl); }
        public async Task<JArray> GetTransactionsAsync(AttendanceTransactionsRequest input, CancellationToken cancellationToken)
        {
            if (input == null || !input.IsValid()) throw Error(HttpStatusCode.BadRequest, "VALIDATION_ERROR", "Invalid request fields or date range.");
            using (var deadline = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
            {
                deadline.CancelAfter(TimeSpan.FromMinutes(2));
                try { return await RetrieveAsync(input, deadline.Token).ConfigureAwait(false); }
                catch (OperationCanceledException) { throw Error(HttpStatusCode.GatewayTimeout, "BIOTIME_TIMEOUT", "BioTime request timed out or was cancelled."); }
                catch (HttpRequestException) { throw Error(HttpStatusCode.ServiceUnavailable, "BIOTIME_UNAVAILABLE", "BioTime is unavailable."); }
                catch (JsonException) { throw InvalidResponse(); }
            }
        }

        async Task<JArray> RetrieveAsync(AttendanceTransactionsRequest input, CancellationToken ct)
        {
            var token = await AuthenticateAsync(input, ct).ConfigureAwait(false);
            var query = HttpUtility.ParseQueryString(string.Empty);
            query["emp_code"] = input.EmployeeCode;
            query["start_time"] = input.FromDate + " 00:00:00";
            query["end_time"] = input.ToDate + " 23:59:59";
            var uri = new UriBuilder(new Uri(BaseUri, TransactionsPath)) { Query = query.ToString() }.Uri;
            var urls = new HashSet<string>(StringComparer.Ordinal);
            var pages = new HashSet<string>(StringComparer.Ordinal);
            var ids = new HashSet<string>(StringComparer.Ordinal);
            var result = new JArray();
            bool retried = false;
            for (int page = 0; page < 10000; page++)
            {
                if (!urls.Add(uri.AbsoluteUri)) throw PaginationError();
                JObject payload;
                using (var response = await TransactionsAsync(uri, token, ct).ConfigureAwait(false))
                {
                    if (response.StatusCode == HttpStatusCode.Unauthorized && !retried)
                    {
                        retried = true;
                        token = await AuthenticateAsync(input, ct).ConfigureAwait(false);
                        using (var retry = await TransactionsAsync(uri, token, ct).ConfigureAwait(false))
                            payload = await ReadAsync(retry).ConfigureAwait(false);
                    }
                    else payload = await ReadAsync(response).ConfigureAwait(false);
                }
                var records = payload["data"] as JArray;
                if (records == null) throw InvalidResponse();
                var code = payload["code"];
                if (code != null && code.Type != JTokenType.Null && code.ToString() != "0") throw InvalidResponse();
                if (records.Count == 0) return result;
                if (!pages.Add(records.ToString(Formatting.None))) throw PaginationError();
                foreach (var record in records)
                {
                    var transaction = record as JObject;
                    if (transaction == null) throw InvalidResponse();
                    // Preserve transaction fields; never relay credential-like fields even in unexpected upstream data.
                    RemoveSecrets(transaction);
                    var id = transaction["id"];
                    if (id != null && id.Type != JTokenType.Null && !ids.Add(id.ToString())) throw PaginationError();
                    if (result.Count >= 1000000) throw PaginationError();
                    result.Add(transaction);
                }
                var next = payload["next"];
                if (next == null || next.Type == JTokenType.Null) return result;
                if (next.Type != JTokenType.String || string.IsNullOrWhiteSpace((string)next)) throw PaginationError();
                uri = NextUri(uri, (string)next, input);
            }
            throw PaginationError();
        }

        internal Uri NextUri(Uri current, string next, AttendanceTransactionsRequest input)
        {
            Uri candidate;
            if (!Uri.TryCreate(current, next, out candidate) || candidate.Scheme != BaseUri.Scheme
                || candidate.Host != BaseUri.Host || candidate.Port != BaseUri.Port
                || candidate.AbsolutePath != TransactionsPath || candidate.UserInfo.Length != 0 || candidate.Fragment.Length != 0)
                throw PaginationError();
            var query = HttpUtility.ParseQueryString(candidate.Query);
            foreach (string key in query.AllKeys)
            {
                if (key != "emp_code" && key != "start_time" && key != "end_time" && key != "page" && key != "page_size") throw PaginationError();
                if (query.GetValues(key).Length != 1) throw PaginationError();
                int value;
                if ((key == "page" || key == "page_size") && (!int.TryParse(query[key], out value) || value < 1 || value > 100000)) throw PaginationError();
            }
            // Enforce the original filters even if BioTime's next URL omits or changes them.
            query["emp_code"] = input.EmployeeCode;
            query["start_time"] = input.FromDate + " 00:00:00";
            query["end_time"] = input.ToDate + " 23:59:59";
            return new UriBuilder(BaseUri) { Path = TransactionsPath, Query = query.ToString() }.Uri;
        }

        async Task<string> AuthenticateAsync(AttendanceTransactionsRequest input, CancellationToken ct)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Post, new Uri(BaseUri, "jwt-api-token-auth/")))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { username = input.Username, password = input.Password }), Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request, ct).ConfigureAwait(false))
                {
                    if (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.Unauthorized)
                        throw Error(HttpStatusCode.Unauthorized, "BIOTIME_INVALID_CREDENTIALS", "BioTime credentials were rejected.");
                    var payload = await ReadAsync(response).ConfigureAwait(false);
                    var token = payload["token"];
                    if (token == null || token.Type != JTokenType.String || string.IsNullOrWhiteSpace((string)token)
                        || ((string)token).Any(char.IsWhiteSpace)) throw InvalidResponse();
                    return (string)token;
                }
            }
        }

        async Task<HttpResponseMessage> TransactionsAsync(Uri uri, string token, CancellationToken ct)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("JWT", token);
                return await client.SendAsync(request, ct).ConfigureAwait(false);
            }
        }
        static async Task<JObject> ReadAsync(HttpResponseMessage response)
        {
            if (!response.IsSuccessStatusCode)
            {
                if (response.StatusCode == HttpStatusCode.Unauthorized) throw Error(HttpStatusCode.Unauthorized, "BIOTIME_UNAUTHORIZED", "BioTime authorization failed.");
                if (response.StatusCode == HttpStatusCode.Forbidden) throw Error(HttpStatusCode.Forbidden, "BIOTIME_FORBIDDEN", "BioTime access was denied.");
                if (response.StatusCode == HttpStatusCode.NotFound) throw Error(HttpStatusCode.BadGateway, "BIOTIME_NOT_FOUND", "BioTime endpoint is unavailable.");
                throw Error(HttpStatusCode.BadGateway, "BIOTIME_HTTP_ERROR", "BioTime returned an unsuccessful response.");
            }
            return JObject.Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false));
        }
        static void RemoveSecrets(JToken token)
        {
            var obj = token as JObject;
            if (obj != null)
                foreach (var property in obj.Properties().ToList())
                {
                    var name = property.Name.Replace("_", "").ToLowerInvariant();
                    if (name == "username" || name == "password" || name == "token" || name == "jwt" || name == "authorization" || name == "accesstoken" || name == "refreshtoken") property.Remove();
                    else RemoveSecrets(property.Value);
                }
            else if (token is JArray) foreach (var child in token.Children()) RemoveSecrets(child);
        }
        static BioTimeException Error(HttpStatusCode status, string code, string message) { return new BioTimeException(status, code, message); }
        static BioTimeException InvalidResponse() { return Error(HttpStatusCode.BadGateway, "BIOTIME_INVALID_RESPONSE", "BioTime returned an invalid response."); }
        static BioTimeException PaginationError() { return Error(HttpStatusCode.BadGateway, "BIOTIME_PAGINATION_ERROR", "BioTime pagination could not be completed safely."); }
    }
}
