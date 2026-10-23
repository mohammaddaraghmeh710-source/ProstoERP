using System;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Hosting;

// Real ASP.NET requests with an ordinary persisted session; no test identity injection.
public class CustomerPortalPageHost : MarshalByRefObject
{
    class Worker : SimpleWorkerRequest
    {
        readonly string path, query; byte[] body;
        public string Csrf;
        public bool Ajax;
        public override string[][] GetUnknownRequestHeaders() {
            var headers=new System.Collections.Generic.List<string[]>();
            if(!String.IsNullOrEmpty(Csrf)){headers.Add(new[]{"X-Content-CSRF",Csrf});headers.Add(new[]{"X-Circular-CSRF",Csrf});}
            if(Ajax)headers.Add(new[]{"X-MicrosoftAjax","Delta=true"});
            return headers.Count==0?null:headers.ToArray();
        }
        public string RequestType = "application/x-www-form-urlencoded";
        public readonly MemoryStream Output = new MemoryStream();
        public int Status = 200; public string Location, ContentType, ContentDisposition;
        public Worker(string path, string query, string form) : base("fixture.aspx", query, new StringWriter())
        { this.path = path; this.query = query; body = String.IsNullOrEmpty(form) ? null : Encoding.UTF8.GetBytes(form); }
        public override string GetFilePath() { return "/" + path; }
        public override string GetFilePathTranslated() { return Path.Combine(HttpRuntime.AppDomainAppPath, path.Replace('/', Path.DirectorySeparatorChar)); }
        public override string GetPathInfo() { return ""; }
        public override string GetUriPath() { return "/" + path; }
        public override string GetRawUrl() { return "/" + path + (query.Length == 0 ? "" : "?" + query); }
        public override string GetHttpVerbName() { return body == null ? "GET" : "POST"; }
        public override byte[] GetPreloadedEntityBody() { return body; }
        public override int GetPreloadedEntityBodyLength() { return body == null ? 0 : body.Length; }
        public override bool IsEntireEntityBodyIsPreloaded() { return true; }
        public override int GetTotalEntityBodyLength() { return GetPreloadedEntityBodyLength(); }
        public override string GetKnownRequestHeader(int index)
        {
            if (index == HeaderUserAgent) return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36";
            if (index == HeaderCookie) return "ASP.NET_SessionId=abcdefghijklmnopqrstuvwx";
            if (body != null && index == HeaderContentType) return RequestType;
            if (body != null && index == HeaderContentLength) return body.Length.ToString();
            return base.GetKnownRequestHeader(index);
        }
        public override void SendResponseFromMemory(byte[] data, int length) { Output.Write(data, 0, length); }
        public override void SendResponseFromFile(string filename, long offset, long length)
        {
            using (var file = File.OpenRead(filename)) {
                file.Position = offset;
                var buffer = new byte[81920];
                while (length > 0) {
                    int read = file.Read(buffer, 0, (int)Math.Min(buffer.Length, length));
                    if (read == 0) break;
                    Output.Write(buffer, 0, read); length -= read;
                }
            }
        }
        public void SetBody(byte[] value, string type) { body=value; RequestType=type; }
        public override void SendStatus(int code, string description) { Status = code; }
        public override void SendKnownResponseHeader(int index, string value)
        { if (index == HeaderLocation) Location = value; if (index == HeaderContentType) ContentType = value; if (String.Equals(GetKnownResponseHeaderName(index), "Content-Disposition", StringComparison.OrdinalIgnoreCase)) ContentDisposition = value; }
        public override void SendUnknownResponseHeader(string name, string value)
        { if (String.Equals(name, "Content-Disposition", StringComparison.OrdinalIgnoreCase)) ContentDisposition = value; }
    }
    public int Status; public string Location, ContentType, ContentDisposition; public byte[] Bytes;
    public string Request(string target, string form)
    {
        var parts = target.TrimStart('/').Split(new[] { '?' }, 2);
        var worker = new Worker(parts[0], parts.Length > 1 ? parts[1] : "", form);
        HttpRuntime.ProcessRequest(worker);
        Status = worker.Status; Location = worker.Location; ContentType = worker.ContentType; ContentDisposition = worker.ContentDisposition; Bytes = worker.Output.ToArray();
        return Encoding.UTF8.GetString(Bytes);
    }
    public string RequestWithCsrf(string target,string form,string csrf) {
        var parts=target.TrimStart('/').Split(new[]{'?'},2);
        var worker=new Worker(parts[0],parts.Length>1?parts[1]:"",form); worker.Csrf=csrf;
        HttpRuntime.ProcessRequest(worker); Status=worker.Status;Location=worker.Location;ContentType=worker.ContentType;ContentDisposition=worker.ContentDisposition;Bytes=worker.Output.ToArray();return Encoding.UTF8.GetString(Bytes);
    }
    public string RequestAsync(string target,string form) {
        var parts=target.TrimStart('/').Split(new[]{'?'},2);
        var worker=new Worker(parts[0],parts.Length>1?parts[1]:"",form);worker.Ajax=true;
        HttpRuntime.ProcessRequest(worker);Status=worker.Status;Location=worker.Location;ContentType=worker.ContentType;ContentDisposition=worker.ContentDisposition;Bytes=worker.Output.ToArray();return Encoding.UTF8.GetString(Bytes);
    }
    public string UploadCircular(string target,string payload,string filename,byte[] file,string csrf)
    {
        var parts=target.TrimStart('/').Split(new[]{'?'},2);
        var worker=new Worker(parts[0],parts.Length>1?parts[1]:"",null);worker.Csrf=csrf;
        string boundary="CircularFixture"+Guid.NewGuid().ToString("N");
        using(var bytes=new MemoryStream()) {
            Action<string> write=s=>{var b=Encoding.UTF8.GetBytes(s);bytes.Write(b,0,b.Length);};
            write("--"+boundary+"\r\nContent-Disposition: form-data; name=\"payload\"\r\n\r\n"+payload+"\r\n");
            write("--"+boundary+"\r\nContent-Disposition: form-data; name=\"file\"; filename=\""+filename+"\"\r\nContent-Type: application/pdf\r\n\r\n");
            bytes.Write(file,0,file.Length);write("\r\n--"+boundary+"--\r\n");worker.SetBody(bytes.ToArray(),"multipart/form-data; boundary="+boundary);
        }
        HttpRuntime.ProcessRequest(worker);Status=worker.Status;Location=worker.Location;ContentType=worker.ContentType;ContentDisposition=worker.ContentDisposition;Bytes=worker.Output.ToArray();return Encoding.UTF8.GetString(Bytes);
    }
    public override object InitializeLifetimeService() { return null; }
    public string Upload(string target,string form,string filename,byte[] file)
    { return Upload(target,form,filename,file,"ctl00$ContentPlaceHolder1$logoUpload","image/png"); }
    public string Upload(string target,string form,string filename,byte[] file,string fieldName,string contentType)
    {
        string boundary="CustomerFixture"+Guid.NewGuid().ToString("N");
        var parts=target.TrimStart('/').Split(new[]{'?'},2);
        var worker=new Worker(parts[0],parts.Length>1?parts[1]:"",null);
        using(var bytes=new MemoryStream()) {
            Action<string> write=s=>{var b=Encoding.UTF8.GetBytes(s);bytes.Write(b,0,b.Length);};
            foreach(var pair in form.Split('&')) {
                var kv=pair.Split(new[]{'='},2);
                write("--"+boundary+"\r\nContent-Disposition: form-data; name=\""+HttpUtility.UrlDecode(kv[0])+"\"\r\n\r\n"+HttpUtility.UrlDecode(kv.Length>1?kv[1]:"")+"\r\n");
            }
            write("--"+boundary+"\r\nContent-Disposition: form-data; name=\""+fieldName+"\"; filename=\""+filename+"\"\r\nContent-Type: "+contentType+"\r\n\r\n");
            bytes.Write(file,0,file.Length);write("\r\n--"+boundary+"--\r\n");worker.SetBody(bytes.ToArray(),"multipart/form-data; boundary="+boundary);
        }
        HttpRuntime.ProcessRequest(worker);
        Status=worker.Status;Location=worker.Location;ContentType=worker.ContentType;ContentDisposition=worker.ContentDisposition;Bytes=worker.Output.ToArray();
        return Encoding.UTF8.GetString(Bytes);
    }
}

// Only compiled into the disposable page-test host; never registered in Portal.
public class NewsPortalTestIdentity : IHttpModule
{
    public void Init(HttpApplication app)
    {
        app.PostAcquireRequestState += (sender, args) => {
            var context = HttpContext.Current; int actor;
            if (context.Session != null && Int32.TryParse(context.Request.QueryString["newsTestActor"], out actor)) {
                CRM.CustomerPortalData.Current = null;
                CRM.SessionManager.GetInstance.Users = actor == 0 ? null : new CRM.UserEntity { UserID = actor, UserType = actor == 1 ? 1 : 4, NameAr = "News test admin" };
            }
        };
    }
    public void Dispose() { }
}
