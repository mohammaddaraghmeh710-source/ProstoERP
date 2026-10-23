using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using System.Web;
using System.Web.Hosting;

// Compiled into the disposable test application only; never deployed in Portal.
public sealed class CorrespondenceWorkspaceHost : MarshalByRefObject
{
    sealed class Worker : SimpleWorkerRequest
    {
        readonly string path, query;
        readonly byte[] body;
        readonly bool ajax;
        public readonly MemoryStream Output = new MemoryStream();
        public int Status = 200;
        public string Location, ContentType;
        public Worker(string path, string query, string form, bool ajax)
            : base("fixture.aspx", query, new StringWriter())
        { this.path = path; this.query = query; this.ajax = ajax; body = form == null ? null : Encoding.UTF8.GetBytes(form); }
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
        public override string[][] GetUnknownRequestHeaders() { return ajax ? new[] { new[] { "X-MicrosoftAjax", "Delta=true" } } : null; }
        public override string GetKnownRequestHeader(int index)
        {
            if (index == HeaderUserAgent) return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36";
            if (index == HeaderCookie) return "ASP.NET_SessionId=correspondencefixtureabc";
            if (body != null && index == HeaderContentType) return "application/x-www-form-urlencoded";
            if (body != null && index == HeaderContentLength) return body.Length.ToString();
            return base.GetKnownRequestHeader(index);
        }
        public override void SendResponseFromMemory(byte[] data, int length) { Output.Write(data, 0, length); }
        public override void SendResponseFromFile(string filename, long offset, long length)
        {
            using (var file = File.OpenRead(filename)) {
                file.Position = offset;
                var buffer = new byte[81920];
                while (length > 0) { int read = file.Read(buffer, 0, (int)Math.Min(buffer.Length, length)); if (read == 0) break; Output.Write(buffer, 0, read); length -= read; }
            }
        }
        public override void SendStatus(int code, string description) { Status = code; }
        public override void SendKnownResponseHeader(int index, string value)
        { if (index == HeaderLocation) Location = value; if (index == HeaderContentType) ContentType = value; }
    }
    public int Status;
    public string Location, ContentType;
    public string Request(string target, string form, bool ajax)
    {
        var parts = target.TrimStart('/').Split(new[] { '?' }, 2);
        var worker = new Worker(parts[0], parts.Length > 1 ? parts[1] : "", form, ajax);
        HttpRuntime.ProcessRequest(worker);
        Status = worker.Status; Location = worker.Location; ContentType = worker.ContentType;
        return Encoding.UTF8.GetString(worker.Output.ToArray());
    }
    public override object InitializeLifetimeService() { return null; }
}

public sealed class CorrespondenceWorkspaceIdentity : IHttpModule
{
    public void Init(HttpApplication app)
    {
        app.PostAcquireRequestState += delegate {
            var context = HttpContext.Current;
            int actor;
            if (context.Session == null || !Int32.TryParse(context.Request.QueryString["workspaceActor"], out actor)) return;
            var connection = ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString;
            var builder = new SqlConnectionStringBuilder(connection);
            if (builder.DataSource != "localhost" && builder.DataSource != "." && builder.DataSource != "(local)") throw new HttpException(403, "Local fixture required.");
            if (!System.Text.RegularExpressions.Regex.IsMatch(builder.InitialCatalog, "^Prosto_CorrespondenceWorkspace_Test_[a-f0-9]{32}$")) throw new HttpException(403, "Isolated fixture database required.");
            CRM.CustomerPortalData.Current = null;
            if (actor == 0) { CRM.SessionManager.GetInstance.Users = null; return; }
            using (var cn = new SqlConnection(connection)) using (var cmd = cn.CreateCommand()) {
                cn.Open(); cmd.CommandText = "SELECT ID,Type,FullName_Ar FROM dbo.UsersMembers WHERE ID=@Actor AND IsActive=1 AND ISNULL(IsDeleted,0)=0"; cmd.Parameters.AddWithValue("@Actor", actor);
                using (var rows = cmd.ExecuteReader()) {
                    if (!rows.Read()) throw new HttpException(403, "Unknown synthetic actor.");
                    CRM.SessionManager.GetInstance.Users = new CRM.UserEntity { UserID = rows.GetInt32(0), UserType = Convert.ToInt32(rows[1]), NameAr = Convert.ToString(rows[2]) };
                }
            }
        };
        app.PreRequestHandlerExecute += delegate {
            var context = HttpContext.Current;
            var page = context.Handler as System.Web.UI.Page;
            var filename = context.Request.QueryString["workspaceQueue"];
            if (page == null || String.IsNullOrEmpty(filename)) return;
            page.PreLoad += delegate {
                var builder = new SqlConnectionStringBuilder(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
                if (!System.Text.RegularExpressions.Regex.IsMatch(builder.InitialCatalog, "^Prosto_CorrespondenceWorkspace_Test_[a-f0-9]{32}$")) throw new HttpException(403, "Isolated fixture database required.");
                PropertyInfo property = null;
                for (var type = page.GetType(); type != null && property == null; type = type.BaseType) property = type.GetProperty("UploadKey", BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.DeclaredOnly);
                if (property == null) throw new InvalidOperationException("Upload draft key was not found.");
                var key = Convert.ToString(property.GetValue(page, null));
                context.Session[key] = new List<CRM.FileAttribute> { new CRM.FileAttribute { NameFile = filename, Type = "application/pdf", FileByte = Encoding.ASCII.GetBytes("%PDF-1.4\nsynthetic workspace attachment") } };
            };
        };
    }
    public void Dispose() { }
}
