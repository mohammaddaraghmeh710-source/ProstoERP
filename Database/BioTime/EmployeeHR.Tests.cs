using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using CRM;
using Newtonsoft.Json.Linq;

class EmployeeHRTests
{
    sealed class Fake : HttpMessageHandler
    {
        public Func<HttpRequestMessage, Task<HttpResponseMessage>> Reply;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token) { return Reply(request); }
    }
    static int passed;
    static void Check(bool condition, string label) { if (!condition) throw new Exception(label); passed++; Console.WriteLine("PASS: " + label); }
    static void Denied(Action action, string label)
    {
        try { action(); } catch (HRDisplayException) { Check(true, label); return; }
        catch (Newtonsoft.Json.JsonException) { Check(true, label); return; }
        throw new Exception("Expected rejection: " + label);
    }
    static HttpResponseMessage Json(string json) { return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(json, Encoding.UTF8, "application/json") }; }
    static void Main() { Run().GetAwaiter().GetResult(); Console.WriteLine(passed + " HR contract checks passed."); }
    static async Task Run()
    {
        foreach (var json in new[] {"[{\"EmpNo\":5}]", "{\"EmpNo\":5}", "{\"Success\":true,\"Data\":[{\"EmpNo\":5}]}", "{\"Table\":[{\"EmpNo\":5}]}", "{\"d\":\"[{\\\"EmpNo\\\":5}]\"}"})
            Check(EmployeeHRClient.Decode(json, "EmpNo").Count == 1, "Explicit response shape");
        Check(EmployeeHRClient.Decode("{\"Data\":[]}", "EmpNo").Count == 0, "Empty collection");
        foreach (var json in new[] {"{\"Success\":false,\"Data\":[]}", "[{\"EmpNo\":5,\"Success\":false}]", "{\"Error\":\"private upstream detail\"}", "{\"unexpected\":[]}", "{\"Data\":[],\"Table\":[]}", "[7]", "null", "{} {}"})
            Denied(() => EmployeeHRClient.Decode(json, "EmpNo"), "Unknown/error response rejected");
        Check(EmployeeHRData.FileUrl("javascript:alert(1)") == "", "Script attachment URL blocked");
        Check(EmployeeHRData.FileUrl("file:///c:/secret") == "", "Local attachment URL blocked");
        Check(EmployeeHRData.FileUrl("https://user:secret@example.test/a") == "", "Credential-bearing attachment URL blocked");
        Check(EmployeeHRData.FileUrl("https://files.example.test/a.pdf") == "https://files.example.test/a.pdf", "HTTP file URL accepted");
        var fields = typeof(HRProfile).GetMethod("Fields", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
        var rendered = (string)fields.Invoke(null, new object[] { JObject.Parse("{\"Email\":\"<script>secret</script>\",\"Password\":\"must-not-appear\"}"), new[] {"Email|البريد"}, true });
        Check(rendered.Contains("&lt;script&gt;") && !rendered.Contains("<script>") && !rendered.Contains("must-not-appear"), "Output encodes HTML and only projects selected fields");
        var salaryRenderer = typeof(HRProfile).GetMethod("SalaryDetails", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
        var salaryHtml = (string)salaryRenderer.Invoke(null, new object[] { JObject.Parse("{\"EssSalary\":800,\"TotalAllowance\":50,\"Allow1\":0,\"DedLate\":5,\"TotalDeduction\":5,\"NetSalary\":845,\"Password\":\"private-marker\"}") });
        Check(salaryHtml.Contains("800") && salaryHtml.Contains("50") && salaryHtml.Contains("845") && salaryHtml.Contains("العلاوة 1") && salaryHtml.Contains("اقتطاع التأخير") && !salaryHtml.Contains("private-marker"), "Salary renders API summary allowances deductions and zero entries without unknown fields");
        Check((string)salaryRenderer.Invoke(null, new object[] { JObject.Parse("{\"EmpNo\":5}") }) == "", "Unknown salary fields do not fabricate totals");
        using (var handler = new Fake()) using (var http = new HttpClient(handler))
        {
            var api = new EmployeeHRClient(http, "https://hr.example.test/bonanza/", "synthetic-user", "synthetic-password");
            handler.Reply = async request => {
                var body = JObject.Parse(await request.Content.ReadAsStringAsync());
                Check(request.Method == HttpMethod.Get && request.RequestUri.AbsolutePath == "/bonanza/api/values/GetPayEmployers", "GET body preserves HR virtual application path");
                Check(request.Headers.Authorization.Scheme == "Basic" && Encoding.UTF8.GetString(Convert.FromBase64String(request.Headers.Authorization.Parameter)) == "synthetic-user:synthetic-password", "Request-local configured Basic credentials");
                Check((int)body["BodyParam"]["EmpNo"] == 5 && (int)body["BodyParam"]["Lang"] == 1 && (int)body["BodyParam"]["OperNo"] == 2, "Employee request scoped to server employee number");
                return Json("[{\"EmpNo\":5,\"ArEmployeeName\":\"Synthetic\"}]");
            };
            Check((int)(await api.Employee(5))["EmpNo"] == 5, "Employee retrieval");
            handler.Reply = request => Task.FromResult(Json("null"));
            Check((await api.Attachments(5)).Count == 0, "Live null files response handled as no returned records");
            Check((await api.Custody(5)).Count == 0, "Null custody handled as no returned records");
            Check((await api.Salary(5,10,2026)).Count == 0, "Live null salary response handled as no returned records");
            Denied(() => api.Employee(5).GetAwaiter().GetResult(), "Null employee card still rejected");
            handler.Reply = request => Task.FromResult(Json("{\"Success\":false,\"Data\":null}"));
            Denied(() => api.Attachments(5).GetAwaiter().GetResult(), "Null error envelope still rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":6}]"));
            Denied(() => api.Employee(5).GetAwaiter().GetResult(), "Foreign employee card rejected");
            Denied(() => api.Attachments(5).GetAwaiter().GetResult(), "Foreign employee files rejected");
            Denied(() => api.Custody(5).GetAwaiter().GetResult(), "Foreign employee custody rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5},{\"EmpNo\":6}]"));
            Denied(() => api.Attachments(5).GetAwaiter().GetResult(), "Mixed employee files rejected as a whole");
            handler.Reply = request => Task.FromResult(Json("[{\"AttachName\":\"unverified\"}]"));
            Denied(() => api.Attachments(5).GetAwaiter().GetResult(), "Missing employee identity rejected");
            handler.Reply = async request => {
                var body = JObject.Parse(await request.Content.ReadAsStringAsync())["BodyParam"];
                Check((int)body["FromEmpNo"] == 5 && (int)body["ToEmpNo"] == 5 && (int)body["Months"] == 10 && (int)body["Years"] == 2026 && (int)body["Rate"] == 1 && (int)body["CurrencyNo"] == 1, "Salary bounded to one employee and selected month");
                return Json("{\"Data\":[{\"EmpNo\":5,\"Months\":10,\"Years\":2026,\"EssSalary\":800}]}");
            };
            Check((await api.Salary(5,10,2026)).Count == 1, "Salary retrieval");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5,\"EmpMonth\":10,\"EmpYear\":2026,\"TotalAllowance\":50,\"TotalDeduction\":5}]"));
            Check((await api.Salary(5,10,2026)).Count == 1, "Live EmpMonth EmpYear salary fields accepted");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5,\"EmpMonth\":9,\"EmpYear\":2026}]"));
            Denied(() => api.Salary(5,10,2026).GetAwaiter().GetResult(), "Live month field mismatch rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5,\"EmpMonth\":10,\"EmpYear\":2025}]"));
            Denied(() => api.Salary(5,10,2026).GetAwaiter().GetResult(), "Live year field mismatch rejected");
            handler.Reply = async request => {
                var body = JObject.Parse(await request.Content.ReadAsStringAsync())["BodyParam"];
                Check(request.RequestUri.AbsolutePath.EndsWith("/GetPayContracts") && (int)body["EmpNo"] == 5 && (int)body["OperNo"] == 2 && (int)body["Lang"] == 1, "Custody uses documented employee-scoped GET contract");
                return Json("[{\"EmpNo\":5,\"SrNo\":1,\"ContractNo\":2,\"NoOfContract\":1,\"Status\":\"<script>\",\"UnitCost\":10,\"Cost\":10}]");
            };
            var custody = await api.Custody(5);
            Check(custody.Count == 1 && (int)custody[0]["ContractNo"] == 2, "Custody rows retrieved");
            var custodySpecs = (string[])typeof(HRProfile).GetField("CustodyFields", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static).GetValue(null);
            Check(((string)fields.Invoke(null, new object[] { custody[0], custodySpecs, true })).Contains("&lt;script&gt;"), "Custody state HTML is encoded");
            var routes = new Dictionary<string,string> { {"children","GetPayChildrens"},{"wives","GetPayWifes"},{"references","GetPayReferences"},{"education","GetPayLearning"},{"experience","GetPayExperienceYears"} };
            foreach (var entry in routes)
            {
                handler.Reply = async request => {
                    var body = JObject.Parse(await request.Content.ReadAsStringAsync())["BodyParam"];
                    Check(request.Method == HttpMethod.Get && request.RequestUri.AbsolutePath.EndsWith("/"+entry.Value) && (int)body["EmpNo"] == 5, "Related section uses employee-scoped documented route: "+entry.Key);
                    return Json("[{\"EmpNo\":5,\"SrNo\":1}]");
                };
                Check((await api.Related(5,entry.Key)).Count == 1, "Related records returned: "+entry.Key);
                handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":6}]"));
                Denied(() => api.Related(5,entry.Key).GetAwaiter().GetResult(), "Related foreign employee rejected: "+entry.Key);
            }
            handler.Reply = request => Task.FromResult(Json("[{\"QualificationNo\":8,\"ArName\":\"Synthetic\"}]"));
            Check((int)(await api.Catalog("qualification",8))["QualificationNo"] == 8, "Employee qualification lookup");
            Denied(() => api.Catalog("qualification",9).GetAwaiter().GetResult(), "Foreign qualification lookup rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"SpecializationNo\":3}]"));
            Check((int)(await api.Catalog("specialization",3))["SpecializationNo"] == 3, "Employee specialization lookup");
            handler.Reply = async request => {
                var body = JObject.Parse(await request.Content.ReadAsStringAsync())["BodyParam"];
                Check(request.RequestUri.AbsolutePath.EndsWith("/GetPayTransAllPenalties") && (int)body["PenaltyNo"] == 9 && (int)body["EmpNo"] == 5, "Penalty exact documented keys");
                return Json("[{\"EmpNo\":5,\"PenaltyNo\":9}]");
            };
            Check((await api.Penalty(5,9)).Count == 1, "Penalty records returned");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5,\"PenaltyNo\":8}]"));
            Denied(() => api.Penalty(5,9).GetAwaiter().GetResult(), "Wrong penalty record rejected");
            handler.Reply = async request => {
                var body = JObject.Parse(await request.Content.ReadAsStringAsync())["BodyParam"];
                Check(request.RequestUri.AbsolutePath.EndsWith("/GetPayOffDates") && (int)body["EmpNo"] == 5 && (int)body["SrNo"] == 1 && (int)body["MonthNo"] == 6 && (int)body["YearNo"] == 2026 && body["OffDate"].ToString() == "2026-06-05" && body["StartDate"].ToString() == "2026-06-01", "Off-date exact documented filters");
                return Json("[{\"EmpNo\":5,\"SrNo\":1,\"MonthNo\":6,\"YearNo\":2026,\"OffDate\":\"2026-06-05T00:00:00\",\"StartDate\":\"2026-06-01T00:00:00\"}]");
            };
            Check((await api.OffDates(5,1,new DateTime(2026,6,1),new DateTime(2026,6,5),new DateTime(2026,6,1))).Count == 1, "Off-date record returned");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":6}]"));
            Denied(() => api.OffDates(5,1,new DateTime(2026,6,1),new DateTime(2026,6,5),new DateTime(2026,6,1)).GetAwaiter().GetResult(), "Foreign employee off-date rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":5,\"Months\":9}]"));
            Denied(() => api.Salary(5,10,2026).GetAwaiter().GetResult(), "Wrong salary month rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"EmpNo\":6}]"));
            Denied(() => api.Salary(5,10,2026).GetAwaiter().GetResult(), "Foreign salary rejected");
            handler.Reply = request => Task.FromResult(Json("[{\"ShiftNo\":3}]"));
            Denied(() => api.Shift(2).GetAwaiter().GetResult(), "Wrong shift rejected");
            handler.Reply = request => Task.FromResult(new HttpResponseMessage(HttpStatusCode.Redirect) { Content = new StringContent("secret detail") });
            Denied(() => api.Employee(5).GetAwaiter().GetResult(), "Redirect response rejected");
            handler.Reply = request => Task.FromResult(Json(new string('x', 4*1024*1024+1)));
            Denied(() => api.Employee(5).GetAwaiter().GetResult(), "Oversized response rejected");
            handler.Reply = request => { throw new Exception("Invalid parameters reached upstream"); };
            Denied(() => api.Related(5,"GetAnything").GetAwaiter().GetResult(), "Arbitrary related route rejected before network");
            Denied(() => api.Penalty(5,0).GetAwaiter().GetResult(), "Penalty record number required before network");
            Denied(() => api.Employee(0).GetAwaiter().GetResult(), "Invalid employee rejected before network");
            Denied(() => api.Salary(5,13,2026).GetAwaiter().GetResult(), "Invalid month rejected before network");
        }
        await RealTransport();
    }

    static async Task RealTransport()
    {
        // Exercise the production Windows handler: .NET Framework's default backend
        // cannot send GET bodies. Never send these tests to an external HR service.
        var socket = new System.Net.Sockets.TcpListener(IPAddress.Loopback, 0);
        socket.Start(); int port = ((IPEndPoint)socket.LocalEndpoint).Port; socket.Stop();
        using (var listener = new HttpListener())
        using (var handler = EmployeeHRData.CreateHandler())
        using (var http = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(5) })
        {
            Check(!handler.AutomaticRedirection && handler.CookieUsePolicy == CookieUsePolicy.IgnoreCookies && handler.WindowsProxyUsePolicy == WindowsProxyUsePolicy.DoNotUseProxy, "Production transport disables redirects cookies and proxies");
            string root = "http://127.0.0.1:" + port + "/";
            listener.Prefixes.Add(root); listener.Start();
            var server = Task.Run(async () => {
                for (int index = 0; index < 2; index++)
                {
                    var context = await listener.GetContextAsync();
                    string content = new System.IO.StreamReader(context.Request.InputStream).ReadToEnd();
                    Check(context.Request.HttpMethod == "GET" && (int)JObject.Parse(content)["BodyParam"]["EmpNo"] == 5, "Wire-level GET JSON body received");
                    Check(context.Request.Headers["Authorization"] != null && context.Request.Headers["Cookie"] == null, "Wire-level Basic without cookies");
                    if(index == 0)
                    {
                        byte[] bytes = Encoding.UTF8.GetBytes("[{\"EmpNo\":5}]");
                        context.Response.ContentType = "application/json";
                        context.Response.ContentLength64 = bytes.Length;
                        context.Response.AddHeader("Set-Cookie", "synthetic=must-not-return");
                        await context.Response.OutputStream.WriteAsync(bytes, 0, bytes.Length);
                    }
                    else { context.Response.StatusCode = 302; context.Response.RedirectLocation = root + "forbidden-redirect"; }
                    context.Response.Close();
                }
            });
            var api = new EmployeeHRClient(http, root, "synthetic-user", "synthetic-password");
            Check((int)(await api.Employee(5))["EmpNo"] == 5, "Real WinHTTP GET body round trip on .NET Framework");
            Denied(() => api.Employee(5).GetAwaiter().GetResult(), "Wire-level redirect rejected");
            await server;
        }
    }
}
