using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Xml.Linq;
using Newtonsoft.Json;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api/v1/customer")]
    public sealed class CustomerPortalController : ApiController
    {
        private int retryAfter;

        private Dictionary<string, object> Session => (Dictionary<string, object>)Request.Properties["CustomerSession"];

        private int Account => Convert.ToInt32(Session["AccountID"]);

        private Guid Stamp => (Guid)Session["SecurityStamp"];

        // Legacy portal dates are local server dates, not UTC. Preserve their original kind.
        internal static List<Dictionary<string, object>> Rows(DataSet data, int index = 0)
        {
            return data.Tables.Count <= index
                ? new List<Dictionary<string, object>>()
                : data.Tables[index].Rows.Cast<DataRow>().Select(MobileApiSupport.Row).ToList();
        }

        private DataSet Query(FeedbackDb db, string proc, params object[] args)
        {
            return db.Proc(proc, new object[] { "AccountID", Account, "Stamp", Stamp }.Concat(args).ToArray());
        }

        [HttpPost]
        [Route("login")]
        public HttpResponseMessage Login(CustomerPortalLogin model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = new FeedbackDb())
                {
                    var rate = Rows(db.Proc("dbo.CustomerApi_CheckLoginRate", "ClientHash", ClientHash()))[0];
                    if (!Convert.ToBoolean(rate["Allowed"]))
                    {
                        retryAfter = Convert.ToInt32(rate["RetryAfterSeconds"]);
                        throw new FeedbackException((HttpStatusCode)429, "RATE_LIMIT", "حاول تسجيل الدخول لاحقًا.");
                    }

                    var credentials = Rows(db.Proc("dbo.Customer_Credentials", "Username", model.Username.Trim()));
                    var credential = credentials.FirstOrDefault();
                    byte[] actual;
                    using (var derive = new Rfc2898DeriveBytes(model.Password,
                               credential == null ? new byte[32] : (byte[])credential["Salt"],
                               credential == null ? 210000 : Convert.ToInt32(credential["Iterations"]),
                               HashAlgorithmName.SHA256))
                    {
                        actual = derive.GetBytes(32);
                    }

                    var expected = credential == null ? new byte[32] : (byte[])credential["PasswordHash"];
                    var difference = actual.Length ^ expected.Length;
                    for (var i = 0; i < actual.Length; i++) difference |= actual[i] ^ expected[i];
                    var logged = credential == null
                        ? new List<Dictionary<string, object>>()
                        : Rows(db.Proc("dbo.Customer_LoginResult", "AccountID", credential["AccountID"], "Stamp",
                            credential["SecurityStamp"], "Success", difference == 0));
                    if (logged.Count == 0)
                        throw new FeedbackException(HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                            "اسم المستخدم أو كلمة المرور غير صحيحة أو الحساب غير متاح.");
                    var identity = logged[0];
                    var token = MobileApiSupport.NewToken();
                    var created = Rows(db.Proc("dbo.CustomerApi_CreateSession", "AccountID", identity["AccountID"],
                        "Stamp", identity["SecurityStamp"], "TokenHash", MobileApiSupport.TokenHash(token)))[0];
                    return Success(new
                    {
                        Token = token, TokenType = "Bearer", ExpiresUtc = created["ExpiresUtc"], IdleMinutes = 480,
                        Customer = new { AccountID = identity["AccountID"], Name = identity["Name_AR"] }
                    });
                }
            });
        }

        [CustomerSession]
        [HttpPost]
        [Route("logout")]
        public HttpResponseMessage Logout()
        {
            return Execute(() =>
            {
                using (var db = new FeedbackDb())
                {
                    db.Proc("dbo.CustomerApi_Logout", "TokenHash", Request.Properties["CustomerTokenHash"]);
                }

                return Success(new { LoggedOut = true });
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("me")]
        public HttpResponseMessage Me()
        {
            return Execute(() =>
            {
                using (var db = new FeedbackDb())
                {
                    var row = Rows(Query(db, "dbo.Customer_Session"))[0];
                    return Success(new
                        { AccountID = Account, Name = row["Name_AR"], ExpiresUtc = Session["ExpiresUtc"] });
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/brands")]
        public HttpResponseMessage Brands()
        {
            return GuideSection("brands", 0);
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/categories")]
        public HttpResponseMessage Categories(int brandID)
        {
            return GuideSection("categories", brandID);
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/access-request-options")]
        public HttpResponseMessage RequestOptions(int brandID)
        {
            return GuideSection("request-categories", brandID);
        }

        private HttpResponseMessage GuideSection(string section, int brand)
        {
            return Execute(() =>
            {
                if (!ModelState.IsValid || brand < 0 || (section != "brands" && brand == 0))
                    throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    return Success(Rows(Query(db, "dbo.Customer_WorkGuide", "Section", section, "Brand", brand)));
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/documents")]
        public HttpResponseMessage Documents(int brandID, int categoryID = 0, string search = "", int page = 1,
            int pageSize = 20)
        {
            return Execute(() =>
            {
                Paging(page, pageSize, search);
                if (brandID <= 0 || categoryID < 0) throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    return Paged(
                        Query(db, "dbo.CustomerApi_Guide", "Brand", brandID, "Category", categoryID, "Search",
                            search ?? "", "Page", page, "PageSize", pageSize), page, pageSize);
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/documents/{id:int:min(1)}")]
        public HttpResponseMessage Document(int id)
        {
            return Execute(() =>
            {
                using (var db = new FeedbackDb())
                {
                    var row = DocumentRow(db, id);
                    row.Remove("File_Path");
                    row["FileUrl"] = Url.Link("CustomerGuideFile", new { id });
                    return Success(row);
                }
            });
        }

        private Dictionary<string, object> DocumentRow(FeedbackDb db, int id)
        {
            var row = Rows(Query(db, "dbo.Customer_Guide", "Section", "file", "DocumentID", id)).FirstOrDefault();
            if (row == null) throw Missing();
            return row;
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/documents/{id:int:min(1)}/file", Name = "CustomerGuideFile")]
        public HttpResponseMessage GuideFile(int id, bool download = false)
        {
            return Execute(() =>
            {
                if (!ModelState.IsValid) throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    var row = DocumentRow(db, id);
                    if (download && !Convert.ToBoolean(row["Can_Download_Document"]))
                        throw new FeedbackException(HttpStatusCode.Forbidden, "DOWNLOAD_DENIED",
                            "التنزيل غير متاح لهذا الملف.");
                    var relative = Convert.ToString(row["File_Path"]).Replace('\\', '/');
                    if (relative.Contains(":") || relative.StartsWith("//")) throw Missing();
                    var root = ConfigurationManager.AppSettings["CustomerApi.PortalRoot"];
                    if (string.IsNullOrWhiteSpace(root) || !Path.IsPathRooted(root))
                        throw new ConfigurationErrorsException("Configure CustomerApi.PortalRoot.");
                    root = Path.GetFullPath(root).TrimEnd('\\', '/') + Path.DirectorySeparatorChar;
                    var path = Path.GetFullPath(Path.Combine(root, relative.TrimStart('~', '/')));
                    if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase) ||
                        !string.Equals(Path.GetExtension(path), ".pdf", StringComparison.OrdinalIgnoreCase) ||
                        !File.Exists(path)) throw Missing();
                    Query(db, "dbo.Customer_LogDocument", "DocumentID", id, "Action", download ? "download" : "view");
                    return FileResponse(path, "application/pdf", "guide-" + id + ".pdf", download);
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("guide/access-requests")]
        public HttpResponseMessage AccessRequests(int brandID = 0, string status = "P", int page = 1, int pageSize = 20)
        {
            return Execute(() =>
            {
                Paging(page, pageSize, "");
                if (brandID < 0 || !new[] { "P", "A", "R", "H" }.Contains(status)) throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    var rows = Rows(Query(db, "dbo.Customer_WorkGuide", "Section", "requests", "Brand", brandID,
                        "Status", status));
                    return Success(new
                    {
                        Total = rows.Count, Page = page, PageSize = pageSize,
                        Items = rows.Skip((page - 1) * pageSize).Take(pageSize)
                    });
                }
            });
        }

        [CustomerSession]
        [HttpPost]
        [Route("guide/access-requests")]
        public HttpResponseMessage RequestAccess(CustomerAccessCreate model)
        {
            return Execute(() =>
            {
                Validate(model);
                if (model.OperationID == Guid.Empty || model.CategoryIDs == null || model.CategoryIDs.Length < 1 ||
                    model.CategoryIDs.Length > 200 ||
                    model.CategoryIDs.Any(x => x < 1)) throw FeedbackController.Invalid();
                model.CategoryIDs = model.CategoryIDs.Distinct().OrderBy(x => x).ToArray();
                byte[] hash;
                using (var sha = SHA256.Create())
                {
                    hash = sha.ComputeHash(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(model)));
                }

                using (var db = new FeedbackDb())
                {
                    db.Begin();
                    Lock(db, "customer-guide:" + Account + ":" + model.OperationID);
                    var previous =
                        Rows(db.Text(
                            "SELECT BatchID,PayloadHash FROM dbo.CustomerApi_GuideOperations WHERE AccountID=@Account AND OperationID=@Operation",
                            "Account", Account, "Operation", model.OperationID));
                    if (previous.Count > 0)
                    {
                        MatchHash(previous[0]["PayloadHash"], hash);
                        db.Commit();
                        return Success(new { BatchID = previous[0]["BatchID"], Replayed = true });
                    }

                    var categories = new XElement("items",
                        model.CategoryIDs.Select(id => new XElement("item", new XAttribute("id", id)))).ToString();
                    var saved = Rows(Query(db, "dbo.Customer_WorkGuide", "Section", "submit", "Brand", model.BrandID,
                        "Categories", categories, "Reason", model.Reason))[0];
                    db.Text(
                        "INSERT dbo.CustomerApi_GuideOperations(AccountID,OperationID,PayloadHash,BatchID) VALUES(@Account,@Operation,@Hash,@Batch)",
                        "Account", Account, "Operation", model.OperationID, "Hash", hash, "Batch", saved["Batch_ID"]);
                    db.Commit();
                    return Success(new { BatchID = saved["Batch_ID"], Replayed = false });
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/options")]
        public HttpResponseMessage FeedbackOptions(int brandID = 0, int typeID = 0)
        {
            return Execute(() =>
            {
                if (!ModelState.IsValid || brandID < 0 || typeID < 0) throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    return Success(new
                    {
                        Types = Rows(Query(db, "dbo.Customer_FeedbackOptions", "Section", "types")),
                        Brands = Rows(Query(db, "dbo.Customer_FeedbackOptions", "Section", "brands")),
                        Branches = Rows(Query(db, "dbo.Customer_FeedbackOptions", "Section", "branches", "Brand",
                            brandID)),
                        Topics = Rows(Query(db, "dbo.Customer_FeedbackOptions", "Section", "topics", "Brand", brandID,
                            "Type", typeID)),
                        RecipientTitle = "إدارة النظام", MaxTitleLength = 300, MaxDetailsLength = 10000,
                        FileRules = new
                        {
                            MaxFiles = 5, MaxFileBytes = FeedbackFiles.MaxBytes,
                            Extensions = new[] { "pdf", "png", "jpg", "jpeg", "gif" }
                        }
                    });
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/requests")]
        public HttpResponseMessage FeedbackHistory(int page = 1, int pageSize = 20, int status = 0, string search = "")
        {
            return Execute(() =>
            {
                Paging(page, pageSize, search);
                using (var db = new FeedbackDb())
                {
                    return Paged(
                        Query(db, "dbo.CustomerApi_Feedback", "Page", page, "PageSize", pageSize, "Status", status,
                            "Search", search ?? ""), page, pageSize);
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/requests/{id:int:min(1)}")]
        public HttpResponseMessage FeedbackDetail(int id)
        {
            return Execute(() =>
            {
                using (var db = new FeedbackDb())
                {
                    var data = Query(db, "dbo.CustomerApi_Feedback", "ID", id);
                    var attachments = Rows(data, 1);
                    foreach (var file in attachments)
                        file["DownloadUrl"] = Url.Link("CustomerFeedbackFile", new { id = file["ID"] });
                    return Success(new { Request = Rows(data)[0], Attachments = attachments });
                }
            });
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/attachments/{id:int:min(1)}", Name = "CustomerFeedbackFile")]
        public HttpResponseMessage FeedbackFile(int id)
        {
            return Execute(() =>
            {
                using (var db = new FeedbackDb())
                {
                    var row = Rows(Query(db, "dbo.CustomerApi_Feedback", "AttachmentID", id)).FirstOrDefault();
                    if (row == null) throw Missing();
                    var name = Convert.ToString(row["FileName"]);
                    if (string.IsNullOrWhiteSpace(name) || name != Path.GetFileName(name) || name.Contains(":"))
                        throw Missing();
                    var path = Path.Combine(FeedbackFiles.Root, name);
                    if (!File.Exists(path)) throw Missing();
                    return FileResponse(path, "application/octet-stream", "attachment-" + id + Path.GetExtension(name),
                        true);
                }
            });
        }

        [CustomerSession]
        [HttpPost]
        [Route("feedback/requests")]
        public async Task<HttpResponseMessage> SubmitFeedback()
        {
            try
            {
                using (var upload = await FeedbackFiles.Read(Request))
                using (var db = new FeedbackDb())
                {
                    var model = JsonConvert.DeserializeObject<CustomerPortalFeedbackCreate>(upload.Data,
                        FeedbackController.JsonSettings);
                    Validate(model);
                    if (model.OperationID == Guid.Empty || model.Mobile.Count(c => c >= '0' && c <= '9') < 7 ||
                        model.Mobile.Count(c => c >= '0' && c <= '9') > 15) throw FeedbackController.Invalid();
                    var hash = upload.Hash(JsonConvert.SerializeObject(model));
                    db.Begin();
                    Lock(db, "customer-feedback:" + Account + ":" + model.OperationID.ToString().ToUpperInvariant());
                    var previous = Rows(db.Text(
                        "SELECT f.RequestID,o.PayloadHash FROM dbo.Customer_Portal_Feedback f LEFT JOIN dbo.CustomerApi_FeedbackOperations o ON o.AccountID=f.AccountID AND o.OperationID=f.OperationID WHERE f.AccountID=@Account AND f.OperationID=@Operation",
                        "Account", Account, "Operation", model.OperationID));
                    if (previous.Count > 0)
                    {
                        MatchHash(previous[0]["PayloadHash"], hash);
                        db.Commit();
                        return Success(new { RequestID = previous[0]["RequestID"], Replayed = true });
                    }

                    upload.Prepare();
                    var saved = Rows(Query(db, "dbo.Customer_SubmitFeedback", "OperationID", model.OperationID, "Type",
                        model.TypeID, "Topic", model.TopicID, "Brand", model.BrandID, "Branch", model.BranchID,
                        "Mobile", model.Mobile, "Title", model.Title, "Details", model.Details, "Files",
                        upload.Xml))[0];
                    db.Text(
                        "INSERT dbo.CustomerApi_FeedbackOperations(AccountID,OperationID,PayloadHash) VALUES(@Account,@Operation,@Hash)",
                        "Account", Account, "Operation", model.OperationID, "Hash", hash);
                    upload.PreserveFiles = true;
                    try
                    {
                        db.Commit();
                    }
                    catch
                    {
                        if (db.RollbackConfirmed()) upload.PreserveFiles = false;
                        throw;
                    }

                    return Success(new { RequestID = saved["ID"], Replayed = false });
                }
            }
            catch (Exception ex)
            {
                return Failure(ex);
            }
        }

        private static void Lock(FeedbackDb db, string key)
        {
            db.Text(
                "DECLARE @Result int;EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Result<0 THROW 51802,'Operation busy.',1;",
                "Key", key);
        }

        private static void MatchHash(object previous, byte[] hash)
        {
            if (!(previous is byte[]) || !((byte[])previous).SequenceEqual(hash))
                throw new FeedbackException(HttpStatusCode.Conflict, "OPERATION_REUSED",
                    "رقم العملية مستخدم لبيانات مختلفة.");
        }

        private byte[] ClientHash()
        {
            string address = null;
            object context;
            if (Request.Properties.TryGetValue("MS_HttpContext", out context) && context is HttpContextBase)
                address = ((HttpContextBase)context).Request.UserHostAddress;
            if (string.IsNullOrWhiteSpace(address) && HttpContext.Current != null)
                address = HttpContext.Current.Request.UserHostAddress;
            IPAddress parsed;
            address = IPAddress.TryParse(address, out parsed) ? parsed.MapToIPv6().ToString() : "unknown-connection";
            using (var hash = SHA256.Create())
            {
                return hash.ComputeHash(Encoding.UTF8.GetBytes(address));
            }
        }

        private void Validate(object model)
        {
            if (model == null || !ModelState.IsValid || !Validator.TryValidateObject(model,
                    new ValidationContext(model), new List<ValidationResult>(), true))
                throw FeedbackController.Invalid();
        }

        private void Paging(int page, int size, string search)
        {
            if (!ModelState.IsValid || page < 1 || page > 1000000 || size < 1 || size > 100 ||
                (search ?? "").Length > 200) throw FeedbackController.Invalid();
        }

        private HttpResponseMessage Paged(DataSet data, int page, int size)
        {
            return Success(new { Total = Rows(data)[0]["Total"], Page = page, PageSize = size, Items = Rows(data, 1) });
        }

        private static FeedbackException Missing()
        {
            return new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "الطلب أو الملف غير متاح لك.");
        }

        private HttpResponseMessage FileResponse(string path, string mime, string filename, bool download)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK);
            response.Content = new StreamContent(File.OpenRead(path));
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(mime);
            response.Content.Headers.ContentDisposition =
                new ContentDispositionHeaderValue(download ? "attachment" : "inline") { FileName = filename };
            response.Headers.Add("X-Content-Type-Options", "nosniff");
            MobileApiSupport.NoCache(response);
            return response;
        }

        private HttpResponseMessage Success(object data)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, new { Success = true, Data = data });
            MobileApiSupport.NoCache(response);
            return response;
        }

        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            try
            {
                return action();
            }
            catch (Exception ex)
            {
                return Failure(ex);
            }
        }

        private HttpResponseMessage Failure(Exception ex)
        {
            var known = ex as FeedbackException;
            var sql = ex as SqlException;
            HttpResponseMessage response;
            if (known != null)
            {
                response = MobileApiSupport.Error(Request, known.Status, known.Code, known.Message);
            }
            else if (sql != null && sql.Number == 51911)
            {
                response = MobileApiSupport.Error(Request, HttpStatusCode.Unauthorized, "SESSION_INVALID",
                    "يلزم تسجيل الدخول مجددًا.");
            }
            else if (sql != null && sql.Number == 51912)
            {
                response = MobileApiSupport.Error(Request, HttpStatusCode.NotFound, "NOT_FOUND", "الطلب غير متاح لك.");
            }
            else if (sql != null && (sql.Number == 51910 || sql.Number == 51500 ||
                                     (sql.Number >= 51100 && sql.Number <= 51109)))
            {
                response = MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
            }
            else if (sql != null && (sql.Number == 51802 || sql.Number == 1205))
            {
                response = MobileApiSupport.Error(Request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                    "أعد المحاولة بنفس رقم العملية.");
            }
            else if (ex is JsonException || ex is ArgumentException || ex is FormatException)
            {
                response = MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من بيانات الطلب.");
            }
            else
            {
                Trace.TraceError("Customer API failed ({0}).", ex.GetType().Name);
                response = MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "تعذر إتمام العملية.");
            }

            if (retryAfter > 0)
                response.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(retryAfter));
            return response;
        }
    }
}
