using ProstoERP.Application.Data;
using ProstoERP.Application.Abstractions;
using Prosto_ERP_API.Mobile;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Feedback;
using ProstoERP.Contracts.Features.CustomerFeedback;
using ProstoERP.Contracts.Features.CustomerPortal;
using FeatureStore = ProstoERP.Application.Features.Feedback.IFeedbackStore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace ProstoERP.Application.Features.Feedback
{
    public sealed class FeedbackService
    {
        private readonly IFeedbackStoreFactory sessions;
        private readonly IMobileWorkflowContext context;
        private readonly IMobileFiles files;
        public FeedbackService(IFeedbackStoreFactory sessions, IMobileWorkflowContext context, IMobileFiles files)
        {
            this.sessions = sessions;
            this.context = context;
            this.files = files;
            receivedUtc = context.ReceivedUtc;
        }


        internal static readonly JsonSerializerSettings JsonSettings = ProstoERP.Application.Validation.MobileJson.Settings;

        private readonly DateTime receivedUtc;

        private int Actor =>
            context.Actor;

        public object Options(int employeeNumber, int type = 0)
        {
            return Execute(() =>
            {
                using (var db = Connect(employeeNumber))
                {
                    return Success(new FeedbackOptionsResponse
                    {
                        Types = Rows(db.SelectEmployeeFeedbackTypes("Actor", Actor)),
                        Topics =
                            Rows(db.SelectEmployeeFeedbackTopics("Actor", Actor, "Type", type)),
                        Permissions = Permissions(db), RecipientTypes = Targets(db),
                        Statuses = new[]
                        {
                            new FeedbackStatus { ID = 1, Title = "جديد" }, new FeedbackStatus { ID = 2, Title = "قيد المعالجة" },
                            new FeedbackStatus { ID = 3, Title = "منتهي" }
                        },
                        FileRules = new FileRules
                        {
                            MaxFiles = 5, MaxFileBytes = files.MaxBytes, MaxImagePixels = 20000000,
                            Extensions = new[] { "pdf", "png", "jpg", "jpeg", "gif" }
                        },
                        MaxTitleLength = 300, MaxDetailsLength = 10000, MaxCommentLength = 10000
                    });
                }
            });
        }

        public object Routing(FeedbackRouting model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = Connect(model.EmployeeNumber))
                {
                    if (model.RequestID.HasValue) RequireCanAct(db, model.RequestID.Value, true);
                    else if (!Flag(Permissions(db), "CanSubmit")) throw Forbidden();
                    var recipients = Rows(model.RequestID.HasValue
                        ? db.SelectEmployeeFeedbackTransferTargets("Actor", Actor, "ID",
                            model.RequestID.Value, "Target", model.RecipientTypeID)
                        : db.SelectEmployeeFeedbackRecipients("Actor", Actor, "Target",
                            model.RecipientTypeID));
                    var fallback = recipients.Any(r => Convert.ToBoolean(r["IsFallback"]));
                    return Success(new FeedbackRoutingResponse
                    {
                        RecipientTypeID = model.RecipientTypeID, Recipients = recipients,
                        CanSend = recipients.Count > 0, IsFallback = fallback,
                        Message = recipients.Count == 0 ? "لا يوجد مستلم متاح." :
                            fallback ? "سيتم إرسال الطلب إلى مدير النظام لعدم وجود المدير المطلوب." :
                            "تم تحديد المستلمين تلقائيًا."
                    });
                }
            });
        }

        public object Requests(int employeeNumber, int page = 1, int pageSize = 20, string search = "",
            int type = 0, int status = 0, string scope = "all")
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                if ((search ?? "").Length > 300 || type < 0 || status < 0 || status > 4 ||
                    !new[] { "all", "sent", "active", "closed", "action" }.Contains(scope)) throw Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var result = db.MobileApiFeedbackRequests("Actor", Actor, "Search", search ?? "",
                        "Type", type, "Status", status, "Scope", scope, "Page", page, "PageSize", pageSize);
                    return Success(new CountedPage<Dictionary<string, object>, Dictionary<string, object>>
                    {
                        Counts = First(result), TotalItems = First(result, 1)["TotalItems"], Page = page,
                        PageSize = pageSize, Items = Rows(result, 2)
                    });
                }
            });
        }

        public Task<object> Create()
        {
            return Upload(false, 0);
        }

        public Task<object> Action(int id)
        {
            return Upload(true, id);
        }

        private async Task<object> Upload(bool action, int id)
        {
            try
            {
                using (var upload = await files.Read())
                {
                    var model = action
                        ? (FeedbackEvent)JsonConvert.DeserializeObject<FeedbackAction>(upload.Data, JsonSettings)
                        : JsonConvert.DeserializeObject<FeedbackCreate>(upload.Data, JsonSettings);
                    Validate(model);
                    ValidateEvent(model);
                    byte[] version = null;
                    if (action)
                    {
                        var m = (FeedbackAction)model;
                        if (m.Action != "transfer" && m.Action != "close") throw Invalid();
                        if (m.Action == "transfer" && (!m.RecipientTypeID.HasValue || m.RecipientTypeID <= 0))
                            throw Invalid();
                        if (m.Action == "close" && m.RecipientTypeID.HasValue) throw Invalid();
                        try
                        {
                            version = Convert.FromBase64String(m.RowVersion);
                        }
                        catch (FormatException)
                        {
                            throw Invalid();
                        }

                        if (version.Length != 8) throw Invalid();
                    }

                    var fingerprint =
                        upload.Hash((action ? "action/" + id : "submit") + JsonConvert.SerializeObject(model));
                    using (var db = Connect(model.EmployeeNumber))
                    {
                        db.Begin();
                        var replay = FindReplay(db, model, fingerprint);
                        if (replay.HasValue)
                        {
                            db.Commit();
                            return Saved(replay.Value, true);
                        }

                        // SQL authorization precedes any file persistence. The shared procedure checks it again under locks.
                        if (action)
                        {
                            RequireAccess(db, id);
                            var row = First(db.UploadEmployeeFeedbackRequests("ID", id));
                            if (Convert.ToInt32(row["Status"]) == 3 ||
                                !((byte[])row["RowVersion"]).SequenceEqual(version))
                                throw new FeedbackException(HttpStatusCode.Conflict, "REQUEST_CHANGED",
                                    "تم تحديث الطلب أو اتخاذ إجراء عليه. أعد فتح التفاصيل.");
                            RequireCanAct(db, id, ((FeedbackAction)model).Action == "transfer");
                        }
                        else if (!Flag(Permissions(db), "CanSubmit"))
                        {
                            throw Forbidden();
                        }

                        upload.Prepare();
                        string eventType;
                        if (action)
                        {
                            var m = (FeedbackAction)model;
                            eventType = m.Action;
                            db.UpdateEmployeeFeedbackAction("Actor", Actor, "ID", id, "Version",
                                version,
                                "Action", m.Action == "transfer" ? 2 : 3, "Comment", m.Comment, "Files", upload.Xml,
                                "TargetType", m.RecipientTypeID);
                        }
                        else
                        {
                            var m = (FeedbackCreate)model;
                            eventType = "submit";
                            id = Convert.ToInt32(First(db.InsertEmployeeFeedbackRequest("Actor",
                                Actor, "Type", m.TypeID,
                                "Topic", m.TopicID, "Title", m.Title, "Details", m.Details, "Disclose",
                                m.DiscloseIdentity, "Target", m.RecipientTypeID, "Files", upload.Xml))["ID"]);
                        }

                        Record(db, model, fingerprint, id, eventType);
                        // Files are durable before commit; only a confirmed rollback can remove them.
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

                        return Saved(id, false);
                    }
                }
            }
            catch (Exception ex)
            {
                return Failure(ex);
            }
        }

        public object Open(int id, FeedbackEvent model)
        {
            return Execute(() =>
            {
                Validate(model);
                ValidateEvent(model);
                using (var db = Connect(model.EmployeeNumber))
                {
                    db.Begin();
                    RequireAccess(db, id);
                    byte[] hash;
                    using (var sha = SHA256.Create())
                    {
                        hash = sha.ComputeHash(
                            Encoding.UTF8.GetBytes("open/" + id + JsonConvert.SerializeObject(model)));
                    }

                    var replay = FindReplay(db, model, hash).HasValue;
                    if (!replay)
                    {
                        db.UpdateEmployeeFeedbackRead("Actor", Actor, "ID", id);
                        Record(db, model, hash, id, "open");
                    }

                    var details = First(db.SelectEmployeeFeedbackRequest("Actor", Actor, "ID", id));
                    var type = First(db.OpenEmployeeFeedbackTypes("Type", details["Type"]));
                    details["TypeName"] = type["Title_Ar"];
                    details["TypeNameEn"] = type["Title_En"];
                    details["StatusTitle"] = Convert.ToInt32(details["Status"]) == 3 ? "منتهي" :
                        Convert.ToInt32(details["Status"]) == 2 ? "قيد المعالجة" : "جديد";
                    var permissions = Permissions(db);
                    var canAct = Flag(details, "CanAct");
                    var attachments = Rows(db.SelectEmployeeFeedbackAttachments("Actor", Actor,
                        "ID", id));
                    foreach (var item in attachments)
                    {
                        item["FileName"] = "attachment-" + item["ID"] + "." + item["File_Type"];
                        item["PreviewUrl"] = AttachmentUrl(Convert.ToInt32(item["ID"]), model.EmployeeNumber, false);
                        item["DownloadUrl"] = AttachmentUrl(Convert.ToInt32(item["ID"]), model.EmployeeNumber, true);
                    }

                    var contact = First(db.SelectEmployeeFeedbackContact("Actor", Actor, "ID", id));
                    var recipientTypes = canAct && Flag(permissions, "CanTransfer")
                        ? Targets(db) : new List<Dictionary<string, object>>();
                    if (Convert.ToInt32(contact["SourceType"]) == 2)
                        recipientTypes = recipientTypes.Where(row => Convert.ToInt32(row["ID"]) == 1).ToList();
                    var actions = new List<FeedbackActionOption>();
                    if (recipientTypes.Count > 0)
                        actions.Add(new FeedbackActionOption
                        {
                            Code = "transfer", Title = "تحويل للمتابعة", CommentRequired = true,
                            RecipientRequired = true
                        });
                    if (canAct && Flag(permissions, "CanClose"))
                        actions.Add(new FeedbackActionOption
                        {
                            Code = "close", Title = "إغلاق الطلب", CommentRequired = true, RecipientRequired = false
                        });
                    var result = new FeedbackDetailResponse
                    {
                        Request = details,
                        Contact = contact,
                        Attachments = attachments,
                        Workflow =
                            Rows(db.SelectEmployeeFeedbackWorkflow("Actor", Actor, "ID", id)),
                        AllowedActions = actions,
                        RecipientTypes = recipientTypes,
                        Replayed = replay
                    };
                    db.Commit();
                    return Success(result);
                }
            });
        }

        public object Attachment(int id, int employeeNumber, bool download = false)
        {
            return Execute(() =>
            {
                using (var db = Connect(employeeNumber))
                {
                    var rows = Rows(db.SelectEmployeeFeedbackDownload("Actor", Actor, "File", id));
                    if (rows.Count != 1) throw NotFound();
                    string name = Convert.ToString(rows[0]["FileName"]),
                        ext = Convert.ToString(rows[0]["File_Type"]).ToLowerInvariant();
                    if (string.IsNullOrEmpty(name) || Path.GetFileName(name) != name) throw NotFound();
                    var path = Path.Combine(files.Root, name);
                    if (!File.Exists(path)) throw NotFound();
                    var stream = File.OpenRead(path);
                    var mime = files.Mime(ext);
                    return new MobileFileResult
                    {
                        Stream = stream, Mime = mime, Name = "attachment-" + id + "." + ext,
                        Download = download || mime == "application/octet-stream", Sandbox = true
                    };
                }
            });
        }

        public object Notifications(int employeeNumber, int page = 1, int pageSize = 20,
            bool unreadOnly = false)
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                using (var db = Connect(employeeNumber))
                {
                    var all = Rows(db.SelectEmployeeFeedbackNotifications("Actor", Actor));
                    var filtered = all.Where(r => !unreadOnly || !Convert.ToBoolean(r["IsRead"])).ToList();
                    return Success(new NotificationPage<Dictionary<string, object>>
                    {
                        UnreadCount = all.Count(r => !Convert.ToBoolean(r["IsRead"])), TotalItems = filtered.Count,
                        Page = page, PageSize = pageSize,
                        Items = filtered.Skip((page - 1) * pageSize).Take(pageSize).ToList()
                    });
                }
            });
        }

        private FeatureStore Connect(int employeeNumber)
        {
            if (employeeNumber <= 0 || !context.IsModelValid) throw Invalid();
            var db = sessions.Open();
            try
            {
                db.MobileApiFeedbackActor("Actor", Actor, "EmployeeNumber", employeeNumber);
                return db;
            }
            catch
            {
                db.Dispose();
                throw;
            }
        }

        private Dictionary<string, object> Permissions(FeatureStore db)
        {
            return First(db.SelectEmployeeFeedbackPermissions("Actor", Actor));
        }

        private List<Dictionary<string, object>> Targets(FeatureStore db)
        {
            return Rows(db.SelectEmployeeFeedbackTargetTypes("Actor", Actor));
        }

        private void RequireAccess(FeatureStore db, int id)
        {
            if (Rows(db.RequireAccessEmployeeFeedbackAccess("Actor", Actor, "ID",
                    id)).Count == 0) throw NotFound();
        }

        private void RequireCanAct(FeatureStore db, int id, bool transfer)
        {
            RequireAccess(db, id);
            if (!Flag(First(db.SelectEmployeeFeedbackRequest("Actor", Actor, "ID", id)),
                    "CanAct") || !Flag(Permissions(db), transfer ? "CanTransfer" : "CanClose")) throw Forbidden();
        }

        private int? FindReplay(FeatureStore db, FeedbackEvent model, byte[] hash)
        {
            db.FindReplayLock("Key", "feedback:" + Actor + ":" + model.OperationID);
            var rows = Rows(db.FindReplayMobileApiFeedbackEvents("Actor", Actor, "Operation", model.OperationID));
            if (rows.Count == 0) return null;
            if (!((byte[])rows[0]["PayloadHash"]).SequenceEqual(hash))
                throw new FeedbackException(HttpStatusCode.Conflict, "OPERATION_REUSED",
                    "رقم العملية مستخدم لبيانات مختلفة.");
            return Convert.ToInt32(rows[0]["RequestID"]);
        }

        private void Record(FeatureStore db, FeedbackEvent model, byte[] hash, int id, string eventType)
        {
            db.RecordEmployeeFeedbackWorkflow("Actor", Actor, "Operation", model.OperationID, "Hash", hash, "ID", id, "Event", eventType,
                "Occurred", ParseTime(model.OccurredAt), "Received", receivedUtc);
        }

        private string AttachmentUrl(int id, int employee, bool download)
        {
            return context.Link("FeedbackAttachment", new { id, employeeNumber = employee, download });
        }

        private void Validate(object model)
        {
            if (model == null || !context.IsModelValid || !ProstoERP.Application.Validation.MobileValidation.IsValidModel(model)) throw Invalid();
        }

        internal static DateTimeOffset ParseTime(string value)
        {
            return ProstoERP.Application.Validation.MobileValidation.ParseTime(value);
        }

        private static void ValidateEvent(FeedbackEvent model)
        {
            ValidateOperation(model.OperationID, model.OccurredAt);
        }

        internal static void ValidateOperation(Guid operation, string occurredAt)
        {
            ProstoERP.Application.Validation.MobileValidation.ValidateOperation(operation, occurredAt);
        }

        private static void Page(int page, int size)
        {
            ProstoERP.Application.Validation.MobileValidation.RequirePage(page, size, 1000000);
        }

        internal static List<Dictionary<string, object>> Rows(DataSet data, int table = 0)
        {
            return ProstoERP.Application.Data.MobileRowMapper.Rows(data, table);
        }

        private static Dictionary<string, object> First(DataSet data, int table = 0)
        {
            return Rows(data, table).FirstOrDefault() ?? new Dictionary<string, object>();
        }

        private static bool Flag(Dictionary<string, object> row, string key)
        {
            return row.ContainsKey(key) && row[key] != null && Convert.ToBoolean(row[key]);
        }

        private object Saved(int id, bool replay)
        {
            return Success(new SavedRequestResponse { RequestID = id, Replayed = replay, Message = "تم حفظ العملية بنجاح." });
        }

        private object Success(object data) { return data; }

        private object Execute(Func<object> action) { return action(); }

        private object Failure(Exception ex)
        {
            System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(ex).Throw();
            return null;
        }

        internal static FeedbackException Invalid()
        {
            return ProstoERP.Application.Validation.MobileValidation.Invalid();
        }

        private static FeedbackException Forbidden()
        {
            return new FeedbackException(HttpStatusCode.Forbidden, "ACTION_NOT_ALLOWED",
                "لا تملك صلاحية تنفيذ هذا الإجراء.");
        }

        private static FeedbackException NotFound()
        {
            return new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "الطلب أو المرفق غير متاح لك.");
        }
    }
}
