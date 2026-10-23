using ProstoERP.Application.Data;
using ProstoERP.Application.Abstractions;
using Prosto_ERP_API.Mobile;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Feedback;
using ProstoERP.Contracts.Features.CustomerFeedback;
using ProstoERP.Contracts.Features.CustomerPortal;
using FeedbackDb = ProstoERP.Application.Abstractions.IMobileDataSession;
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
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using Newtonsoft.Json;

namespace ProstoERP.Application.Features.CustomerPortal
{
    public sealed class CustomerPortalService
    {
        private readonly IMobileDataSessionFactory sessions;
        private readonly IMobileWorkflowContext context;
        private readonly IMobileFiles files;
        private readonly IMobileTokenService tokens;
        private readonly IMobileOptions options;
        public CustomerPortalService(IMobileDataSessionFactory sessions, IMobileWorkflowContext context, IMobileFiles files, IMobileTokenService tokens, IMobileOptions options)
        {
            this.sessions = sessions;
            this.context = context;
            this.files = files;
            this.tokens = tokens;
            this.options = options;
        }
        public int RetryAfter => retryAfter;

        private int retryAfter;

        private Dictionary<string, object> Session => context.CustomerSession;

        private int Account => Convert.ToInt32(Session["AccountID"]);

        private Guid Stamp => (Guid)Session["SecurityStamp"];

        // Legacy portal dates are local server dates, not UTC. Preserve their original kind.
        internal static List<Dictionary<string, object>> Rows(DataSet data, int index = 0)
        {
            return data.Tables.Count <= index
                ? new List<Dictionary<string, object>>()
                : data.Tables[index].Rows.Cast<DataRow>().Select(ProstoERP.Application.Data.MobileRowMapper.Row).ToList();
        }

        private DataSet Query(FeedbackDb db, MobileStatement proc, params object[] args)
        {
            return db.Execute(proc, new object[] { "AccountID", Account, "Stamp", Stamp }.Concat(args).ToArray());
        }

        public object Login(CustomerPortalLogin model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = sessions.Open())
                {
                    var rate = Rows(db.Execute(MobileStatement.CustomerPortal_CustomerApiCheckLoginRate, "ClientHash", ClientHash()))[0];
                    if (!Convert.ToBoolean(rate["Allowed"]))
                    {
                        retryAfter = Convert.ToInt32(rate["RetryAfterSeconds"]);
                        throw new FeedbackException((HttpStatusCode)429, "RATE_LIMIT", "حاول تسجيل الدخول لاحقًا.");
                    }

                    var credentials = Rows(db.Execute(MobileStatement.CustomerPortal_CustomerCredentials, "Username", model.Username.Trim()));
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
                        : Rows(db.Execute(MobileStatement.CustomerPortal_CustomerLoginResult, "AccountID", credential["AccountID"], "Stamp",
                            credential["SecurityStamp"], "Success", difference == 0));
                    if (logged.Count == 0)
                        throw new FeedbackException(HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                            "اسم المستخدم أو كلمة المرور غير صحيحة أو الحساب غير متاح.");
                    var identity = logged[0];
                    var token = tokens.NewToken();
                    var created = Rows(db.Execute(MobileStatement.CustomerPortal_CustomerApiCreateSession, "AccountID", identity["AccountID"],
                        "Stamp", identity["SecurityStamp"], "TokenHash", tokens.TokenHash(token)))[0];
                    return Success(new CustomerLoginResponse
                    {
                        Token = token, TokenType = "Bearer", ExpiresUtc = created["ExpiresUtc"], IdleMinutes = 480,
                        Customer = new CustomerIdentity { AccountID = identity["AccountID"], Name = identity["Name_AR"] }
                    });
                }
            });
        }

        public object Logout()
        {
            return Execute(() =>
            {
                using (var db = sessions.Open())
                {
                    db.Execute(MobileStatement.CustomerPortal_CustomerApiLogout, "TokenHash", context.CustomerTokenHash);
                }

                return Success(new CustomerLogoutResponse { LoggedOut = true });
            });
        }

        public object Me()
        {
            return Execute(() =>
            {
                using (var db = sessions.Open())
                {
                    var row = Rows(Query(db, MobileStatement.CustomerPortal_CustomerSession))[0];
                    return Success(new CustomerSessionResponse
                        { AccountID = Account, Name = row["Name_AR"], ExpiresUtc = Session["ExpiresUtc"] });
                }
            });
        }

        public object Brands()
        {
            return GuideSection("brands", 0);
        }

        public object Categories(int brandID)
        {
            return GuideSection("categories", brandID);
        }

        public object RequestOptions(int brandID)
        {
            return GuideSection("request-categories", brandID);
        }

        private object GuideSection(string section, int brand)
        {
            return Execute(() =>
            {
                if (!context.IsModelValid || brand < 0 || (section != "brands" && brand == 0))
                    throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    return Success(Rows(Query(db, MobileStatement.CustomerPortal_CustomerWorkGuide, "Section", section, "Brand", brand)));
                }
            });
        }

        public object Documents(int brandID, int categoryID = 0, string search = "", int page = 1,
            int pageSize = 20)
        {
            return Execute(() =>
            {
                Paging(page, pageSize, search);
                if (brandID <= 0 || categoryID < 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    return Paged(
                        Query(db, MobileStatement.CustomerPortal_CustomerApiGuide, "Brand", brandID, "Category", categoryID, "Search",
                            search ?? "", "Page", page, "PageSize", pageSize), page, pageSize);
                }
            });
        }

        public object Document(int id)
        {
            return Execute(() =>
            {
                using (var db = sessions.Open())
                {
                    var row = DocumentRow(db, id);
                    row.Remove("File_Path");
                    row["FileUrl"] = context.Link("CustomerGuideFile", new { id });
                    return Success(row);
                }
            });
        }

        private Dictionary<string, object> DocumentRow(FeedbackDb db, int id)
        {
            var row = Rows(Query(db, MobileStatement.CustomerPortal_CustomerGuide, "Section", "file", "DocumentID", id)).FirstOrDefault();
            if (row == null) throw Missing();
            return row;
        }

        public object GuideFile(int id, bool download = false)
        {
            return Execute(() =>
            {
                if (!context.IsModelValid) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    var row = DocumentRow(db, id);
                    if (download && !Convert.ToBoolean(row["Can_Download_Document"]))
                        throw new FeedbackException(HttpStatusCode.Forbidden, "DOWNLOAD_DENIED",
                            "التنزيل غير متاح لهذا الملف.");
                    var relative = Convert.ToString(row["File_Path"]).Replace('\\', '/');
                    if (relative.Contains(":") || relative.StartsWith("//")) throw Missing();
                    var root = options.PortalRoot;
                    if (string.IsNullOrWhiteSpace(root) || !Path.IsPathRooted(root))
                        throw new ConfigurationErrorsException("Configure CustomerApi.PortalRoot.");
                    root = Path.GetFullPath(root).TrimEnd('\\', '/') + Path.DirectorySeparatorChar;
                    var path = Path.GetFullPath(Path.Combine(root, relative.TrimStart('~', '/')));
                    if (!path.StartsWith(root, StringComparison.OrdinalIgnoreCase) ||
                        !string.Equals(Path.GetExtension(path), ".pdf", StringComparison.OrdinalIgnoreCase) ||
                        !File.Exists(path)) throw Missing();
                    Query(db, MobileStatement.CustomerPortal_CustomerLogDocument, "DocumentID", id, "Action", download ? "download" : "view");
                    return FileResponse(path, "application/pdf", "guide-" + id + ".pdf", download);
                }
            });
        }

        public object AccessRequests(int brandID = 0, string status = "P", int page = 1, int pageSize = 20)
        {
            return Execute(() =>
            {
                Paging(page, pageSize, "");
                if (brandID < 0 || !new[] { "P", "A", "R", "H" }.Contains(status)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    var rows = Rows(Query(db, MobileStatement.CustomerPortal_CustomerWorkGuide, "Section", "requests", "Brand", brandID,
                        "Status", status));
                    return Success(new
                    {
                        Total = rows.Count, Page = page, PageSize = pageSize,
                        Items = rows.Skip((page - 1) * pageSize).Take(pageSize)
                    });
                }
            });
        }

        public object RequestAccess(CustomerAccessCreate model)
        {
            return Execute(() =>
            {
                Validate(model);
                if (model.OperationID == Guid.Empty || model.CategoryIDs == null || model.CategoryIDs.Length < 1 ||
                    model.CategoryIDs.Length > 200 ||
                    model.CategoryIDs.Any(x => x < 1)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                model.CategoryIDs = model.CategoryIDs.Distinct().OrderBy(x => x).ToArray();
                byte[] hash;
                using (var sha = SHA256.Create())
                {
                    hash = sha.ComputeHash(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(model)));
                }

                using (var db = sessions.Open())
                {
                    db.Begin();
                    Lock(db, "customer-guide:" + Account + ":" + model.OperationID);
                    var previous =
                        Rows(db.Execute(MobileStatement.CustomerPortal_RequestAccessCustomerApiGuideOperations,
                            "Account", Account, "Operation", model.OperationID));
                    if (previous.Count > 0)
                    {
                        MatchHash(previous[0]["PayloadHash"], hash);
                        db.Commit();
                        return Success(new { BatchID = previous[0]["BatchID"], Replayed = true });
                    }

                    var categories = new XElement("items",
                        model.CategoryIDs.Select(id => new XElement("item", new XAttribute("id", id)))).ToString();
                    var saved = Rows(Query(db, MobileStatement.CustomerPortal_CustomerWorkGuide, "Section", "submit", "Brand", model.BrandID,
                        "Categories", categories, "Reason", model.Reason))[0];
                    db.Execute(MobileStatement.CustomerPortal_RequestAccessLock,
                        "Account", Account, "Operation", model.OperationID, "Hash", hash, "Batch", saved["Batch_ID"]);
                    db.Commit();
                    return Success(new { BatchID = saved["Batch_ID"], Replayed = false });
                }
            });
        }

        public object FeedbackOptions(int brandID = 0, int typeID = 0)
        {
            return Execute(() =>
            {
                if (!context.IsModelValid || brandID < 0 || typeID < 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    return Success(new
                    {
                        Types = Rows(Query(db, MobileStatement.CustomerPortal_CustomerFeedbackOptions, "Section", "types")),
                        Brands = Rows(Query(db, MobileStatement.CustomerPortal_CustomerFeedbackOptions, "Section", "brands")),
                        Branches = Rows(Query(db, MobileStatement.CustomerPortal_CustomerFeedbackOptions, "Section", "branches", "Brand",
                            brandID)),
                        Topics = Rows(Query(db, MobileStatement.CustomerPortal_CustomerFeedbackOptions, "Section", "topics", "Brand", brandID,
                            "Type", typeID)),
                        RecipientTitle = "إدارة النظام", MaxTitleLength = 300, MaxDetailsLength = 10000,
                        FileRules = new
                        {
                            MaxFiles = 5, MaxFileBytes = files.MaxBytes,
                            Extensions = new[] { "pdf", "png", "jpg", "jpeg", "gif" }
                        }
                    });
                }
            });
        }

        public object FeedbackHistory(int page = 1, int pageSize = 20, int status = 0, string search = "")
        {
            return Execute(() =>
            {
                Paging(page, pageSize, search);
                using (var db = sessions.Open())
                {
                    return Paged(
                        Query(db, MobileStatement.CustomerPortal_CustomerApiFeedback, "Page", page, "PageSize", pageSize, "Status", status,
                            "Search", search ?? ""), page, pageSize);
                }
            });
        }

        public object FeedbackDetail(int id)
        {
            return Execute(() =>
            {
                using (var db = sessions.Open())
                {
                    var data = Query(db, MobileStatement.CustomerPortal_CustomerApiFeedback, "ID", id);
                    var attachments = Rows(data, 1);
                    foreach (var file in attachments)
                        file["DownloadUrl"] = context.Link("CustomerFeedbackFile", new { id = file["ID"] });
                    return Success(new { Request = Rows(data)[0], Attachments = attachments });
                }
            });
        }

        public object FeedbackFile(int id)
        {
            return Execute(() =>
            {
                using (var db = sessions.Open())
                {
                    var row = Rows(Query(db, MobileStatement.CustomerPortal_CustomerApiFeedback, "AttachmentID", id)).FirstOrDefault();
                    if (row == null) throw Missing();
                    var name = Convert.ToString(row["FileName"]);
                    if (string.IsNullOrWhiteSpace(name) || name != Path.GetFileName(name) || name.Contains(":"))
                        throw Missing();
                    var path = Path.Combine(files.Root, name);
                    if (!File.Exists(path)) throw Missing();
                    return FileResponse(path, "application/octet-stream", "attachment-" + id + Path.GetExtension(name),
                        true);
                }
            });
        }

        public async Task<object> SubmitFeedback()
        {
            try
            {
                using (var upload = await files.Read())
                using (var db = sessions.Open())
                {
                    var model = JsonConvert.DeserializeObject<CustomerPortalFeedbackCreate>(upload.Data,
                        ProstoERP.Application.Validation.MobileJson.Settings);
                    Validate(model);
                    if (model.OperationID == Guid.Empty || model.Mobile.Count(c => c >= '0' && c <= '9') < 7 ||
                        model.Mobile.Count(c => c >= '0' && c <= '9') > 15) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                    var hash = upload.Hash(JsonConvert.SerializeObject(model));
                    db.Begin();
                    Lock(db, "customer-feedback:" + Account + ":" + model.OperationID.ToString().ToUpperInvariant());
                    var previous = Rows(db.Execute(MobileStatement.CustomerPortal_SubmitFeedbackCustomerPortalFeedback,
                        "Account", Account, "Operation", model.OperationID));
                    if (previous.Count > 0)
                    {
                        MatchHash(previous[0]["PayloadHash"], hash);
                        db.Commit();
                        return Success(new { RequestID = previous[0]["RequestID"], Replayed = true });
                    }

                    upload.Prepare();
                    var saved = Rows(Query(db, MobileStatement.CustomerPortal_CustomerSubmitFeedback, "OperationID", model.OperationID, "Type",
                        model.TypeID, "Topic", model.TopicID, "Brand", model.BrandID, "Branch", model.BranchID,
                        "Mobile", model.Mobile, "Title", model.Title, "Details", model.Details, "Files",
                        upload.Xml))[0];
                    db.Execute(MobileStatement.CustomerPortal_SubmitFeedbackLock,
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
            db.Execute(MobileStatement.CustomerPortal_LockLock,
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
            string address = context.ClientAddress;
            IPAddress parsed;
            address = IPAddress.TryParse(address, out parsed) ? parsed.MapToIPv6().ToString() : "unknown-connection";
            using (var hash = SHA256.Create())
            {
                return hash.ComputeHash(Encoding.UTF8.GetBytes(address));
            }
        }

        private void Validate(object model)
        {
            if (model == null || !context.IsModelValid || !ProstoERP.Application.Validation.MobileValidation.IsValidModel(model))
                throw ProstoERP.Application.Validation.MobileValidation.Invalid();
        }

        private void Paging(int page, int size, string search)
        {
            if (!context.IsModelValid || page < 1 || page > 1000000 || size < 1 || size > 100 ||
                (search ?? "").Length > 200) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
        }

        private object Paged(DataSet data, int page, int size)
        {
            return Success(new PagedItems<Dictionary<string, object>> { Total = Rows(data)[0]["Total"], Page = page, PageSize = size, Items = Rows(data, 1) });
        }

        private static FeedbackException Missing()
        {
            return new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "الطلب أو الملف غير متاح لك.");
        }

        private object FileResponse(string path, string mime, string filename, bool download)
        {
            return new MobileFileResult { Stream = File.OpenRead(path), Mime = mime, Name = filename, Download = download };
        }

        private object Success(object data) { return data; }

        private object Execute(Func<object> action) { return action(); }

        private object Failure(Exception ex)
        {
            System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(ex).Throw();
            return null;
        }
    }
}
