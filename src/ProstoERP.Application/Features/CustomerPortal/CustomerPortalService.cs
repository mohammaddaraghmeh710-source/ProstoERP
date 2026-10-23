using ProstoERP.Application.Data;
using ProstoERP.Application.Abstractions;
using Prosto_ERP_API.Mobile;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Feedback;
using ProstoERP.Contracts.Features.CustomerFeedback;
using ProstoERP.Contracts.Features.CustomerPortal;
using FeatureStore = ProstoERP.Application.Features.CustomerPortal.ICustomerPortalStore;
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
        private readonly ICustomerPortalStoreFactory sessions;
        private readonly IMobileWorkflowContext context;
        private readonly IMobileFiles files;
        private readonly IMobileTokenService tokens;
        private readonly IMobileOptions options;
        public CustomerPortalService(ICustomerPortalStoreFactory sessions, IMobileWorkflowContext context, IMobileFiles files, IMobileTokenService tokens, IMobileOptions options)
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

        private DataSet Query(Func<object[], DataSet> query, params object[] args)
        {
            return query(new object[] { "AccountID", Account, "Stamp", Stamp }.Concat(args).ToArray());
        }

        public object Login(CustomerPortalLogin model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = sessions.Open())
                {
                    var rate = Rows(db.CustomerApiCheckLoginRate("ClientHash", ClientHash()))[0];
                    if (!Convert.ToBoolean(rate["Allowed"]))
                    {
                        retryAfter = Convert.ToInt32(rate["RetryAfterSeconds"]);
                        throw new FeedbackException((HttpStatusCode)429, "RATE_LIMIT", "حاول تسجيل الدخول لاحقًا.");
                    }

                    var credentials = Rows(db.CustomerCredentials("Username", model.Username.Trim()));
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
                        : Rows(db.CustomerLoginResult("AccountID", credential["AccountID"], "Stamp",
                            credential["SecurityStamp"], "Success", difference == 0));
                    if (logged.Count == 0)
                    {
                        db.CustomerLogLoginFailure("Username", model.Username.Trim());
                        throw new FeedbackException(HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                            "اسم المستخدم أو كلمة المرور غير صحيحة أو الحساب غير متاح.");
                    }
                    var identity = logged[0];
                    var token = tokens.NewToken();
                    var created = Rows(db.CustomerApiCreateSession("AccountID", identity["AccountID"],
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
                    db.CustomerApiLogout("TokenHash", context.CustomerTokenHash);
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
                    var row = Rows(Query(db.CustomerSession))[0];
                    return Success(new CustomerSessionResponse
                        { AccountID = Account, Name = row["Name_AR"], ExpiresUtc = Session["ExpiresUtc"] });
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
                        Types = Rows(Query(db.CustomerFeedbackOptions, "Section", "types")),
                        Brands = Rows(Query(db.CustomerFeedbackOptions, "Section", "brands")),
                        Branches = Rows(Query(db.CustomerFeedbackOptions, "Section", "branches", "Brand",
                            brandID)),
                        Topics = Rows(Query(db.CustomerFeedbackOptions, "Section", "topics", "Brand", brandID,
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
                        Query(db.CustomerApiFeedback, "Page", page, "PageSize", pageSize, "Status", status,
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
                    var data = Query(db.CustomerApiFeedback, "ID", id);
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
                    var row = Rows(Query(db.CustomerApiFeedback, "AttachmentID", id)).FirstOrDefault();
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
                    var previous = Rows(db.SubmitFeedbackCustomerPortalFeedback("Account", Account, "Operation", model.OperationID));
                    if (previous.Count > 0)
                    {
                        MatchHash(previous[0]["PayloadHash"], hash);
                        db.Commit();
                        return Success(new { RequestID = previous[0]["RequestID"], Replayed = true });
                    }

                    upload.Prepare();
                    var saved = Rows(Query(db.CustomerSubmitFeedback, "OperationID", model.OperationID, "Type",
                        model.TypeID, "Topic", model.TopicID, "Brand", model.BrandID, "Branch", model.BranchID,
                        "Mobile", model.Mobile, "Title", model.Title, "Details", model.Details, "Files",
                        upload.Xml))[0];
                    db.SubmitFeedbackLock("Account", Account, "Operation", model.OperationID, "Hash", hash);
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

        private static void Lock(FeatureStore db, string key)
        {
            db.LockLock("Key", key);
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
