// Optional audit-only timing, used by isolated integration tests. No credentials/bodies are recorded.
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;
internal static class ApiPerformanceProbe {
 class Sample {public string Route;public int Status;public double Milliseconds;}
 static readonly ConcurrentBag<Sample> samples=new ConcurrentBag<Sample>();
 internal static async Task<HttpResponseMessage> Send(HttpClient client,HttpRequestMessage request) {
  var timer=Stopwatch.StartNew();var response=await client.SendAsync(request);
  var path=request.RequestUri.ToString().Split('?')[0];
  path=System.Text.RegularExpressions.Regex.Replace(path,"/\\d+(?=/|$)","/{id}");
  samples.Add(new Sample{Route=request.Method+" "+path,Status=(int)response.StatusCode,Milliseconds=timer.Elapsed.TotalMilliseconds});return response;
 }
 internal static void Save(string suite) {
  var directory=Environment.GetEnvironmentVariable("API_AUDIT_TIMING_DIRECTORY");if(string.IsNullOrEmpty(directory))return;
  var root=Path.GetFullPath(directory).TrimEnd('\\','/')+Path.DirectorySeparatorChar;
  var allowed=Path.GetFullPath("C:/Projects/ERPProsto/tmp/api-audit").TrimEnd('\\','/')+Path.DirectorySeparatorChar;
  if(!root.StartsWith(allowed,StringComparison.OrdinalIgnoreCase))throw new InvalidOperationException("Only audit workspace timings allowed.");
  Directory.CreateDirectory(root);
  var summary=samples.GroupBy(s=>s.Route).Select(g=>{var a=g.Select(s=>s.Milliseconds).OrderBy(v=>v).ToArray();return new{Route=g.Key,Count=a.Length,Statuses=g.Select(s=>s.Status).Distinct().OrderBy(s=>s).ToArray(),MedianMs=Math.Round(a[a.Length/2],2),P95Ms=Math.Round(a[Math.Max(0,(int)Math.Ceiling(a.Length*.95)-1)],2),MaxMs=Math.Round(a.Last(),2)};}).OrderBy(g=>g.Route).ToArray();
  File.WriteAllText(Path.Combine(root,suite+"-timings.json"),JsonConvert.SerializeObject(new{Scope="In-memory HTTP pipeline with disposable SQL fixture; excludes IIS/network/real external services. Mixed successful/negative tests; small sample groups are not load-test percentiles.",Samples=samples.Count,Routes=summary},Formatting.Indented));
 }
}
