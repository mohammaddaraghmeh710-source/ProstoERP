using ProstoERP.Application.Data;
using ProstoERP.Contracts.Features.Correspondence;
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
using Newtonsoft.Json.Linq;

namespace ProstoERP.Application.Features.Correspondence
{
    public sealed class CorrespondenceService
    {
        private readonly IMobileDataSessionFactory sessions;
        private readonly IMobileWorkflowContext context;
        private readonly IMobileFiles files;
        private readonly IAssetUrlBuilder assets;
        public CorrespondenceService(IMobileDataSessionFactory sessions, IMobileWorkflowContext context, IMobileFiles files, IAssetUrlBuilder assets)
        {
            this.sessions = sessions;
            this.context = context;
            this.files = files;
            this.assets = assets;
        }

        private int Actor =>
            context.Actor;

        private static List<Dictionary<string, object>> Rows(DataSet data, int table = 0)
        {
            return ProstoERP.Application.Data.MobileRowMapper.Rows(data, table);
        }

        private static Dictionary<string, object> First(DataSet data, int table = 0)
        {
            return Rows(data, table).FirstOrDefault() ?? new Dictionary<string, object>();
        }

        private FeedbackDb Connect(int employeeNumber)
        {
            if (employeeNumber <= 0 || !context.IsModelValid) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
            var db = sessions.Open();
            try
            {
                db.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceActor, "Actor", Actor, "EmployeeNumber", employeeNumber);
                return db;
            }
            catch
            {
                db.Dispose();
                throw;
            }
        }

        private static void Validate(object model)
        {
            if (model == null || !ProstoERP.Application.Validation.MobileValidation.IsValidModel(model)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
            var operation = model as FeedbackEvent;
            if (operation != null) ProstoERP.Application.Validation.MobileValidation.ValidateOperation(operation.OperationID, operation.OccurredAt);
        }

        private static void Page(int page, int size)
        {
            ProstoERP.Application.Validation.MobileValidation.RequirePage(page, size, 100000);
        }

        private static string IDs(int[] ids)
        {
            if (ids == null || ids.Length < 1 || ids.Length > 100 || ids.Any(i => i <= 0) ||
                ids.Distinct().Count() != ids.Length) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
            return new XElement("items", ids.Select(id => new XElement("item", new XAttribute("id", id)))).ToString(
                SaveOptions.DisableFormatting);
        }

        private Dictionary<string, object> Detail(FeedbackDb db, int id, bool supervisory)
        {
            if (id <= 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
            var access =
                Rows(db.Execute(MobileStatement.Correspondence_DetailCorrespondenceAccess,
                    "Actor", Actor, "ID", id));
            if (access.Count == 0 || (supervisory
                    ? !Convert.ToBoolean(access[0]["IsAdmin"])
                    : !Convert.ToBoolean(access[0]["IsParticipant"])))
                throw new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "المراسلة غير متاحة ضمن هذا النطاق.");
            return First(db.Execute(MobileStatement.Correspondence_CorrespondenceDetail, "Actor", Actor, "ThreadID", id, "Supervisory",
                supervisory));
        }

        private void Visit(FeedbackDb db, int id, bool supervisory, Guid? visitID)
        {
            if (!supervisory) return;
            if (!visitID.HasValue || visitID == Guid.Empty) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
            if (Rows(db.Execute(MobileStatement.Correspondence_VisitCorrespondenceAudit,
                    "ID", id, "Actor", Actor, "Event", visitID)).Count == 0)
                throw new FeedbackException(HttpStatusCode.Forbidden, "OPEN_REQUIRED",
                    "افتح المراسلة إداريًا قبل جلب الرسائل.");
        }

        private Dictionary<string, object> ThreadItem(Dictionary<string, object> row)
        {
            foreach (var key in new[] { "SenderImage", "ReceiverImage", "OtherImage" })
                if (row.ContainsKey(key))
                    row[key] = assets.AssetUrl(row[key]);
            return row;
        }

        public object Options(int employeeNumber, bool task = false, int brandID = 0)
        {
            return Execute(() =>
            {
                if (brandID < 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var role = First(db.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceActor, "Actor", Actor, "EmployeeNumber",
                        employeeNumber));
                    var type = Convert.ToInt32(role["UserType"]);
                    var priorities = Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceCatalogList, "Actor", Actor, "Kind", "P"));
                    var reasons = Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceCatalogList, "Actor", Actor, "Kind", "R", "Task",
                        task));
                    var filters =
                        Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceCatalogList, "Actor", Actor, "Kind", "P", "Mode", 1));
                    return Success(new CorrespondenceOptionsResponse
                    {
                        Identity = role,
                        Permissions = new CorrespondencePermissions
                        {
                            CanCreate = new[] { 1, 2, 3, 4 }.Contains(type),
                            CanCreateTask = new[] { 1, 2, 3 }.Contains(type),
                            CanBroadcast = new[] { 1, 2, 3 }.Contains(type), CanSupervise = type == 1
                        },
                        Priorities = priorities.Select(CatalogItem), ClosureReasons = reasons.Select(CatalogItem),
                        PriorityFilters = filters.Select(CatalogItem),
                        Brands = type == 1
                            ? Rows(db.Execute(MobileStatement.Correspondence_OptionsBrands))
                            : new List<Dictionary<string, object>>(),
                        RecipientBranches =
                            Rows(db.Execute(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients,
                                "Actor", Actor, "Brand", brandID)),
                        RecipientShifts =
                            Rows(db.Execute(MobileStatement.Correspondence_OptionsCorrespondenceAllowedRecipients2,
                                "Actor", Actor, "Brand", brandID)),
                        HistoricalOrganization = Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceOptions, "Actor", Actor))
                            .Where(r => Convert.ToString(r["Kind"]) != "role"),
                        FileRules = new CorrespondenceFileRules
                        {
                            MaxFiles = 5, MaxFileBytes = files.MaxBytes,
                            Extensions = new[] { "pdf", "doc", "docx", "xls", "xlsx", "png", "jpg", "jpeg", "gif" }
                        },
                        Limits = new CorrespondenceLimits
                        {
                            MaxTitle = 200, MaxBrief = 2000, MaxBody = 4000, MaxReason = 1000,
                            MaxRecipients = type == 4 ? 1 : 100
                        },
                        PollIntervalSeconds = 30
                    });
                }
            });
        }

        private static CorrespondenceCatalogItem CatalogItem(Dictionary<string, object> row)
        {
            return new CorrespondenceCatalogItem
            {
                ID = row["ID"], Title = row["Title"], SortOrder = row["SortOrder"], IsUrgent = row["IsUrgent"],
                Behavior = row["Behavior"], IsActive = row["IsActive"]
            };
        }

        public object Recipients(int employeeNumber, int brandID = 0, int branchID = 0, int shiftID = 0,
            string search = "", int page = 1, int pageSize = 30)
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                if (brandID < 0 || branchID < 0 || shiftID < 0 || (search ?? "").Length > 200)
                    throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var data = db.Execute(MobileStatement.Correspondence_RecipientsCorrespondenceAllowedRecipients,
                        "Actor", Actor, "Brand", brandID, "Branch", branchID, "Shift", shiftID, "Search", search ?? "",
                        "Skip", (page - 1) * pageSize, "Size", pageSize);
                    return Success(new TotalItemsPage<Dictionary<string, object>>
                    {
                        TotalItems = First(data)["TotalItems"], Page = page, PageSize = pageSize, Items = Rows(data, 1)
                    });
                }
            });
        }

        public object Threads(int employeeNumber, int page = 1, int pageSize = 20,
            bool supervisory = false, string title = "", string person = "", string filter = "all", int kind = 0,
            int priorityID = 0, int brandID = 0, int branchID = 0, DateTimeOffset? from = null,
            DateTimeOffset? to = null)
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                if ((title ?? "").Length > 200 || (person ?? "").Length > 200 || kind < 0 || kind > 2 ||
                    priorityID < 0 || brandID < 0 || branchID < 0 ||
                    !new[]
                    {
                        "all", "active", "overdue", "closed", "archived", "unread", "noReply", "followup", "legacy"
                    }.Contains(filter) ||
                    (from.HasValue && from.Value.Year < 1753) || (to.HasValue && to.Value.Year < 1753) ||
                    (from.HasValue && to.HasValue && from >= to)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var data = db.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceList, "Actor", Actor, "All", supervisory, "Page",
                        page, "PageSize", pageSize, "Title", title, "Person", person, "Filter", filter,
                        "Kind", kind, "Priority", priorityID, "Brand", brandID, "Branch", branchID, "From",
                        from.HasValue ? (object)from.Value.UtcDateTime : null, "To",
                        to.HasValue ? (object)to.Value.UtcDateTime : null);
                    return Success(new CountedPage<Dictionary<string, object>, Dictionary<string, object>>
                    {
                        TotalItems = First(data)["TotalItems"], Counts = First(data, 1), Page = page,
                        PageSize = pageSize, Items = Rows(data, 2).Select(ThreadItem)
                    });
                }
            });
        }

        public object Open(int id, CorrespondenceOpen model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = Connect(model.EmployeeNumber))
                {
                    var detail = Detail(db, id, model.Supervisory);
                    if (model.Supervisory)
                        db.Execute(MobileStatement.Correspondence_CorrespondenceLogView, "Actor", Actor, "ThreadID", id, "EventID",
                            model.OperationID);
                    return Success(new CorrespondenceDetailResponse
                    {
                        Thread = ThreadItem(detail),
                        Organization = Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceOrganization, "Actor", Actor, "ThreadID", id)),
                        Related = Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceRelated, "Actor", Actor, "ThreadID", id)),
                        VisitID = model.OperationID,
                        Audit = model.Supervisory
                            ? Rows(db.Execute(MobileStatement.Correspondence_CorrespondenceAuditList, "Actor", Actor, "ThreadID", id))
                            : new List<Dictionary<string, object>>()
                    });
                }
            });
        }

        public object Messages(int id, int employeeNumber, int afterID = 0, int beforeID = 0,
            int pageSize = 30, bool supervisory = false, Guid? visitID = null)
        {
            return Execute(() =>
            {
                Page(1, pageSize);
                if (afterID < 0 || beforeID < 0 || (afterID > 0 && beforeID > 0)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var detail = Detail(db, id, supervisory);
                    Visit(db, id, supervisory, visitID);
                    var data = db.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceMessages, "Actor", Actor, "ThreadID", id,
                        "AfterID", afterID, "BeforeID", beforeID, "PageSize", pageSize);
                    var messages = Rows(data, 1);
                    var files = Rows(data, 2);
                    foreach (var file in files)
                        file["Url"] = assets.AssetUrl("FileManager/Correspondence/" +
                                                                Uri.EscapeDataString(
                                                                    Path.GetFileName(
                                                                        Convert.ToString(file["FileName"]))));
                    return Success(new CorrespondenceMessagesResponse
                    {
                        Thread = ThreadItem(detail), Items = messages, Attachments = files,
                        HasMore = First(data)["HasMore"],
                        OldestID = messages.Count == 0 ? (int?)null : Convert.ToInt32(messages[0]["ID"]),
                        LatestID = messages.Count == 0 ? (int?)null : Convert.ToInt32(messages.Last()["ID"])
                    });
                }
            });
        }

        public Task<object> Create()
        {
            return Upload(0);
        }

        public Task<object> Reply(int id)
        {
            return id <= 0 ? Task.FromResult(Failure(ProstoERP.Application.Validation.MobileValidation.Invalid())) : Upload(id);
        }

        private async Task<object> Upload(int id)
        {
            try
            {
                using (var upload = await files.Read())
                {
                    var model = id == 0
                        ? (FeedbackEvent)JsonConvert.DeserializeObject<CorrespondenceCreate>(upload.Data,
                            ProstoERP.Application.Validation.MobileJson.Settings)
                        : JsonConvert.DeserializeObject<CorrespondenceReply>(upload.Data,
                            ProstoERP.Application.Validation.MobileJson.Settings);
                    Validate(model);
                    var create = model as CorrespondenceCreate;
                    string recipients = null;
                    if (create != null)
                    {
                        recipients = IDs(create.RecipientIDs);
                        if (create.DueDate != null && ProstoERP.Application.Validation.MobileValidation.ParseTime(create.DueDate).Year < 2000)
                            throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                        if (!create.RequiresCompletion && create.DueDate != null) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                    }

                    var action = id == 0 ? "create" : "reply";
                    var hash = upload.Hash(action + "/" + id + "/" + JsonConvert.SerializeObject(model));
                    using (var db = Connect(model.EmployeeNumber))
                    {
                        db.Begin();
                        var replay = Replay(db, model, hash);
                        if (replay != null)
                        {
                            db.Commit();
                            return Saved(replay, true);
                        }

                        // Authorize before any persistent files. The shared mutation rechecks under transaction locks.
                        if (id > 0)
                        {
                            if (!Convert.ToBoolean(Detail(db, id, false)["CanReply"]))
                                throw new FeedbackException(HttpStatusCode.Conflict, "THREAD_CLOSED",
                                    "المراسلة منتهية أو مؤرشفة.");
                        }
                        else
                        {
                            var role = Convert.ToInt32(First(db.Execute(MobileStatement.Correspondence_MobileApiCorrespondenceActor, "Actor",
                                Actor, "EmployeeNumber", model.EmployeeNumber))["UserType"]);
                            if (!new[] { 1, 2, 3, 4 }.Contains(role) || (role == 4 &&
                                                                         (create.RequiresCompletion ||
                                                                          create.RecipientIDs.Length != 1)))
                                throw new FeedbackException(HttpStatusCode.Forbidden, "ACTION_NOT_ALLOWED",
                                    "غير مسموح بإنشاء هذا التكليف.");
                            var allowed = Rows(db.Execute(MobileStatement.Correspondence_UploadCorrespondenceAllowedRecipients,
                                "Actor", Actor, "Brand", create.BrandID, "IDs", recipients)).Count;
                            if (allowed != create.RecipientIDs.Length)
                                throw new FeedbackException(HttpStatusCode.Forbidden, "RECIPIENT_NOT_ALLOWED",
                                    "أحد المستلمين غير متاح لك.");
                        }

                        upload.Prepare();
                        object result;
                        if (create != null)
                        {
                            var rows = db.Execute(MobileStatement.Correspondence_InsertCorrespondenceThread, "Actor", Actor, "Brand",
                                create.BrandID, "Recipients", recipients, "Title", create.Title.Trim(), "Brief",
                                create.Brief, "Body", create.Body,
                                "RequiresCompletion", create.RequiresCompletion, "DueDate",
                                create.DueDate == null
                                    ? null
                                    : (object)ProstoERP.Application.Validation.MobileValidation.ParseTime(create.DueDate).UtcDateTime,
                                "Files", upload.Xml, "Priority", create.PriorityID, "RelatedThreadID",
                                create.RelatedThreadID);
                            result = new { ThreadIDs = Rows(rows).Select(r => Convert.ToInt32(r["ID"])).ToArray() };
                        }
                        else
                        {
                            var row = First(db.Execute(MobileStatement.Correspondence_InsertCorrespondenceThreadMessage, "Actor", Actor,
                                "ThreadID", id, "Body", ((CorrespondenceReply)model).Body, "Files", upload.Xml));
                            result = new { ThreadID = id, MessageID = row["ID"] };
                        }

                        var json = JsonConvert.SerializeObject(result);
                        Record(db, model, hash, action, json);
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

                        return Saved(json, false);
                    }
                }
            }
            catch (Exception ex)
            {
                return Failure(ex);
            }
        }

        public object Close(int id, CorrespondenceClose model)
        {
            return Mutation("close", id, model, db =>
            {
                var detail = Detail(db, id, false);
                if (!Convert.ToBoolean(detail["CanClose"]))
                    throw new FeedbackException(HttpStatusCode.Conflict, "CANNOT_CLOSE",
                        "الإنهاء غير متاح؛ حدّث تفاصيل المراسلة.");
                db.Execute(MobileStatement.Correspondence_UpdateCorrespondenceThreadClose, "Actor", Actor, "ThreadID", id, "IsCompleted",
                    model.IsCompleted, "ClosureReasonID", model.ClosureReasonID, "CloseReason", model.Explanation);
                return new { ThreadID = id };
            });
        }

        public object Read(int id, CorrespondenceRead model)
        {
            return Mutation("read", id, model, db =>
            {
                Detail(db, id, false);
                var xml = IDs(model.MessageIDs);
                var valid = Rows(db.Execute(MobileStatement.Correspondence_ReadCorrespondenceThreadMessages,
                    "IDs", xml, "ID", id, "Actor", Actor));
                if (valid.Count != model.MessageIDs.Length) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                db.Execute(MobileStatement.Correspondence_UpdateCorrespondenceMessagesRead, "Actor", Actor, "ThreadID", id, "MessageIDs", xml);
                return new { ThreadID = id, model.MessageIDs };
            });
        }

        public object Archive(int id, CorrespondenceArchive model)
        {
            return Mutation("archive", id, model, db =>
            {
                Detail(db, id, true);
                db.Execute(MobileStatement.Correspondence_CorrespondenceArchive, "Actor", Actor, "ThreadID", id, "Reason", model.Explanation);
                return new { ThreadID = id };
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
                    var data = db.Execute(MobileStatement.Correspondence_NotificationsCorrespondenceNotifications,
                        "Actor", Actor, "Unread", unreadOnly, "Skip", (page - 1) * pageSize, "Size", pageSize);
                    return Success(new
                    {
                        TotalItems = First(data)["TotalItems"],
                        UnreadNotifications = First(data, 1)["UnreadNotifications"],
                        UnreadThreads =
                            First(db.Execute(MobileStatement.Correspondence_SelectCorrespondenceUnreadCount, "Actor", Actor))["UnreadThreads"],
                        Page = page, PageSize = pageSize, Items = Rows(data, 2)
                    });
                }
            });
        }

        public object NotificationRead(int id, FeedbackEvent model)
        {
            return Mutation("notification-read", id, model, db =>
            {
                var changed = Rows(db.Execute(MobileStatement.Correspondence_NotificationReadN,
                    "Actor", Actor, "ID", id));
                if (changed.Count == 0)
                    throw new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "التنبيه غير متاح لك.");
                return new { NotificationID = id };
            });
        }

        private object Mutation(string action, int id, FeedbackEvent model,
            Func<FeedbackDb, object> operation)
        {
            return Execute(() =>
            {
                if (id <= 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                Validate(model);
                byte[] hash;
                using (var sha = SHA256.Create())
                {
                    hash = sha.ComputeHash(
                        Encoding.UTF8.GetBytes(action + "/" + id + "/" + JsonConvert.SerializeObject(model)));
                }

                using (var db = Connect(model.EmployeeNumber))
                {
                    db.Begin();
                    var replay = Replay(db, model, hash);
                    if (replay != null)
                    {
                        db.Commit();
                        return Saved(replay, true);
                    }

                    var json = JsonConvert.SerializeObject(operation(db));
                    Record(db, model, hash, action, json);
                    db.Commit();
                    return Saved(json, false);
                }
            });
        }

        private string Replay(FeedbackDb db, FeedbackEvent model, byte[] hash)
        {
            db.Execute(MobileStatement.Correspondence_ReplayLock,
                "Key", "correspondence:" + Actor + ":" + model.OperationID);
            var rows = Rows(db.Execute(MobileStatement.Correspondence_ReplayMobileApiCorrespondenceEvents,
                "Actor", Actor, "Operation", model.OperationID));
            if (rows.Count == 0) return null;
            if (!((byte[])rows[0]["PayloadHash"]).SequenceEqual(hash))
                throw new FeedbackException(HttpStatusCode.Conflict, "OPERATION_REUSED",
                    "رقم العملية مستخدم لبيانات مختلفة.");
            return Convert.ToString(rows[0]["ResultJson"]);
        }

        private void Record(FeedbackDb db, FeedbackEvent model, byte[] hash, string action, string json)
        {
            db.Execute(MobileStatement.Correspondence_RecordLock,
                "Actor", Actor, "Operation", model.OperationID, "Hash", hash, "Action", action, "Json", json,
                "Occurred", ProstoERP.Application.Validation.MobileValidation.ParseTime(model.OccurredAt));
        }

        private object Saved(string json, bool replay)
        {
            var result = JObject.Parse(json);
            result["Replayed"] = replay;
            return Success(result);
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
