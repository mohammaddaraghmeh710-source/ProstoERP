using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession]
    [RoutePrefix("api/v1/correspondence")]
    public sealed class CorrespondenceController : ApiController
    {
        private int Actor =>
            Convert.ToInt32(((Dictionary<string, object>)Request.Properties["MobileSession"])["UserID"]);

        private static List<Dictionary<string, object>> Rows(DataSet data, int table = 0)
        {
            return FeedbackController.Rows(data, table);
        }

        private static Dictionary<string, object> First(DataSet data, int table = 0)
        {
            return Rows(data, table).FirstOrDefault() ?? new Dictionary<string, object>();
        }

        private FeedbackDb Connect(int employeeNumber)
        {
            if (employeeNumber <= 0 || !ModelState.IsValid) throw FeedbackController.Invalid();
            var db = new FeedbackDb();
            try
            {
                db.Proc("dbo.MobileApi_CorrespondenceActor", "Actor", Actor, "EmployeeNumber", employeeNumber);
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
            if (model == null || !Validator.TryValidateObject(model, new ValidationContext(model),
                    new List<ValidationResult>(), true)) throw FeedbackController.Invalid();
            var operation = model as FeedbackEvent;
            if (operation != null) FeedbackController.ValidateOperation(operation.OperationID, operation.OccurredAt);
        }

        private static void Page(int page, int size)
        {
            if (page < 1 || page > 100000 || size < 1 || size > 100) throw FeedbackController.Invalid();
        }

        private static string IDs(int[] ids)
        {
            if (ids == null || ids.Length < 1 || ids.Length > 100 || ids.Any(i => i <= 0) ||
                ids.Distinct().Count() != ids.Length) throw FeedbackController.Invalid();
            return new XElement("items", ids.Select(id => new XElement("item", new XAttribute("id", id)))).ToString(
                SaveOptions.DisableFormatting);
        }

        private Dictionary<string, object> Detail(FeedbackDb db, int id, bool supervisory)
        {
            if (id <= 0) throw FeedbackController.Invalid();
            var access =
                Rows(db.Text("SELECT IsParticipant,IsAdmin FROM dbo.Correspondence_Access(@Actor) WHERE ID=@ID",
                    "Actor", Actor, "ID", id));
            if (access.Count == 0 || (supervisory
                    ? !Convert.ToBoolean(access[0]["IsAdmin"])
                    : !Convert.ToBoolean(access[0]["IsParticipant"])))
                throw new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "المراسلة غير متاحة ضمن هذا النطاق.");
            return First(db.Proc("dbo.Correspondence_Detail", "Actor", Actor, "ThreadID", id, "Supervisory",
                supervisory));
        }

        private void Visit(FeedbackDb db, int id, bool supervisory, Guid? visitID)
        {
            if (!supervisory) return;
            if (!visitID.HasValue || visitID == Guid.Empty) throw FeedbackController.Invalid();
            if (Rows(db.Text(
                    "SELECT 1 Found FROM dbo.Correspondence_Audit WHERE ThreadID=@ID AND ActorID=@Actor AND EventID=@Event AND Action='view'",
                    "ID", id, "Actor", Actor, "Event", visitID)).Count == 0)
                throw new FeedbackException(HttpStatusCode.Forbidden, "OPEN_REQUIRED",
                    "افتح المراسلة إداريًا قبل جلب الرسائل.");
        }

        private static Dictionary<string, object> ThreadItem(Dictionary<string, object> row)
        {
            foreach (var key in new[] { "SenderImage", "ReceiverImage", "OtherImage" })
                if (row.ContainsKey(key))
                    row[key] = MobileApiSupport.AssetUrl(row[key]);
            return row;
        }

        [HttpGet]
        [Route("options")]
        public HttpResponseMessage Options(int employeeNumber, bool task = false, int brandID = 0)
        {
            return Execute(() =>
            {
                if (brandID < 0) throw FeedbackController.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var role = First(db.Proc("dbo.MobileApi_CorrespondenceActor", "Actor", Actor, "EmployeeNumber",
                        employeeNumber));
                    var type = Convert.ToInt32(role["UserType"]);
                    var priorities = Rows(db.Proc("dbo.Correspondence_CatalogList", "Actor", Actor, "Kind", "P"));
                    var reasons = Rows(db.Proc("dbo.Correspondence_CatalogList", "Actor", Actor, "Kind", "R", "Task",
                        task));
                    var filters =
                        Rows(db.Proc("dbo.Correspondence_CatalogList", "Actor", Actor, "Kind", "P", "Mode", 1));
                    return Success(new
                    {
                        Identity = role,
                        Permissions = new
                        {
                            CanCreate = new[] { 1, 2, 3, 4 }.Contains(type),
                            CanCreateTask = new[] { 1, 2, 3 }.Contains(type),
                            CanBroadcast = new[] { 1, 2, 3 }.Contains(type), CanSupervise = type == 1
                        },
                        Priorities = priorities.Select(CatalogItem), ClosureReasons = reasons.Select(CatalogItem),
                        PriorityFilters = filters.Select(CatalogItem),
                        Brands = type == 1
                            ? Rows(db.Text(
                                "SELECT ID,Title_Ar Title FROM dbo.Brands WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY Title_Ar"))
                            : new List<Dictionary<string, object>>(),
                        RecipientBranches =
                            Rows(db.Text(
                                "SELECT DISTINCT b.ID,b.Title_Ar Title FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) r JOIN dbo.Branches b ON b.ID=r.Branch_ID ORDER BY Title",
                                "Actor", Actor, "Brand", brandID)),
                        RecipientShifts =
                            Rows(db.Text(
                                "SELECT DISTINCT s.ID,s.Title_Ar Title FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) r JOIN dbo.Shift s ON s.ID=r.Shif_ID ORDER BY Title",
                                "Actor", Actor, "Brand", brandID)),
                        HistoricalOrganization = Rows(db.Proc("dbo.Correspondence_Options", "Actor", Actor))
                            .Where(r => Convert.ToString(r["Kind"]) != "role"),
                        FileRules = new
                        {
                            MaxFiles = 5, MaxFileBytes = CorrespondenceFiles.MaxBytes,
                            Extensions = new[] { "pdf", "doc", "docx", "xls", "xlsx", "png", "jpg", "jpeg", "gif" }
                        },
                        Limits = new
                        {
                            MaxTitle = 200, MaxBrief = 2000, MaxBody = 4000, MaxReason = 1000,
                            MaxRecipients = type == 4 ? 1 : 100
                        },
                        PollIntervalSeconds = 30
                    });
                }
            });
        }

        private static object CatalogItem(Dictionary<string, object> row)
        {
            return new
            {
                ID = row["ID"], Title = row["Title"], SortOrder = row["SortOrder"], IsUrgent = row["IsUrgent"],
                Behavior = row["Behavior"], IsActive = row["IsActive"]
            };
        }

        [HttpGet]
        [Route("recipients")]
        public HttpResponseMessage Recipients(int employeeNumber, int brandID = 0, int branchID = 0, int shiftID = 0,
            string search = "", int page = 1, int pageSize = 30)
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                if (brandID < 0 || branchID < 0 || shiftID < 0 || (search ?? "").Length > 200)
                    throw FeedbackController.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var data = db.Text(
                        @"SELECT ID,FullName_Ar,Type,Brand_ID,Branch_ID,Shif_ID INTO #Recipients FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand)
WHERE (@Branch=0 OR Branch_ID=@Branch) AND (@Shift=0 OR Shif_ID=@Shift) AND (@Search='' OR FullName_Ar LIKE N'%'+@Search+N'%');
SELECT COUNT(*) TotalItems FROM #Recipients;
SELECT * FROM #Recipients ORDER BY FullName_Ar,ID OFFSET @Skip ROWS FETCH NEXT @Size ROWS ONLY;",
                        "Actor", Actor, "Brand", brandID, "Branch", branchID, "Shift", shiftID, "Search", search ?? "",
                        "Skip", (page - 1) * pageSize, "Size", pageSize);
                    return Success(new
                    {
                        TotalItems = First(data)["TotalItems"], Page = page, PageSize = pageSize, Items = Rows(data, 1)
                    });
                }
            });
        }

        [HttpGet]
        [Route("threads")]
        public HttpResponseMessage Threads(int employeeNumber, int page = 1, int pageSize = 20,
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
                    (from.HasValue && to.HasValue && from >= to)) throw FeedbackController.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var data = db.Proc("dbo.MobileApi_CorrespondenceList", "Actor", Actor, "All", supervisory, "Page",
                        page, "PageSize", pageSize, "Title", title, "Person", person, "Filter", filter,
                        "Kind", kind, "Priority", priorityID, "Brand", brandID, "Branch", branchID, "From",
                        from.HasValue ? (object)from.Value.UtcDateTime : null, "To",
                        to.HasValue ? (object)to.Value.UtcDateTime : null);
                    return Success(new
                    {
                        TotalItems = First(data)["TotalItems"], Counts = First(data, 1), Page = page,
                        PageSize = pageSize, Items = Rows(data, 2).Select(ThreadItem)
                    });
                }
            });
        }

        [HttpPost]
        [Route("threads/{id:int}/open")]
        public HttpResponseMessage Open(int id, CorrespondenceOpen model)
        {
            return Execute(() =>
            {
                Validate(model);
                using (var db = Connect(model.EmployeeNumber))
                {
                    var detail = Detail(db, id, model.Supervisory);
                    if (model.Supervisory)
                        db.Proc("dbo.Correspondence_LogView", "Actor", Actor, "ThreadID", id, "EventID",
                            model.OperationID);
                    return Success(new
                    {
                        Thread = ThreadItem(detail),
                        Organization = Rows(db.Proc("dbo.Correspondence_Organization", "Actor", Actor, "ThreadID", id)),
                        Related = Rows(db.Proc("dbo.Correspondence_Related", "Actor", Actor, "ThreadID", id)),
                        VisitID = model.OperationID,
                        Audit = model.Supervisory
                            ? Rows(db.Proc("dbo.Correspondence_AuditList", "Actor", Actor, "ThreadID", id))
                            : new List<Dictionary<string, object>>()
                    });
                }
            });
        }

        [HttpGet]
        [Route("threads/{id:int}/messages")]
        public HttpResponseMessage Messages(int id, int employeeNumber, int afterID = 0, int beforeID = 0,
            int pageSize = 30, bool supervisory = false, Guid? visitID = null)
        {
            return Execute(() =>
            {
                Page(1, pageSize);
                if (afterID < 0 || beforeID < 0 || (afterID > 0 && beforeID > 0)) throw FeedbackController.Invalid();
                using (var db = Connect(employeeNumber))
                {
                    var detail = Detail(db, id, supervisory);
                    Visit(db, id, supervisory, visitID);
                    var data = db.Proc("dbo.MobileApi_CorrespondenceMessages", "Actor", Actor, "ThreadID", id,
                        "AfterID", afterID, "BeforeID", beforeID, "PageSize", pageSize);
                    var messages = Rows(data, 1);
                    var files = Rows(data, 2);
                    foreach (var file in files)
                        file["Url"] = MobileApiSupport.AssetUrl("FileManager/Correspondence/" +
                                                                Uri.EscapeDataString(
                                                                    Path.GetFileName(
                                                                        Convert.ToString(file["FileName"]))));
                    return Success(new
                    {
                        Thread = ThreadItem(detail), Items = messages, Attachments = files,
                        HasMore = First(data)["HasMore"],
                        OldestID = messages.Count == 0 ? (int?)null : Convert.ToInt32(messages[0]["ID"]),
                        LatestID = messages.Count == 0 ? (int?)null : Convert.ToInt32(messages.Last()["ID"])
                    });
                }
            });
        }

        [HttpPost]
        [Route("threads")]
        public Task<HttpResponseMessage> Create()
        {
            return Upload(0);
        }

        [HttpPost]
        [Route("threads/{id:int}/messages")]
        public Task<HttpResponseMessage> Reply(int id)
        {
            return id <= 0 ? Task.FromResult(Failure(FeedbackController.Invalid())) : Upload(id);
        }

        private async Task<HttpResponseMessage> Upload(int id)
        {
            try
            {
                using (var upload = await CorrespondenceFiles.Read(Request))
                {
                    var model = id == 0
                        ? (FeedbackEvent)JsonConvert.DeserializeObject<CorrespondenceCreate>(upload.Data,
                            FeedbackController.JsonSettings)
                        : JsonConvert.DeserializeObject<CorrespondenceReply>(upload.Data,
                            FeedbackController.JsonSettings);
                    Validate(model);
                    var create = model as CorrespondenceCreate;
                    string recipients = null;
                    if (create != null)
                    {
                        recipients = IDs(create.RecipientIDs);
                        if (create.DueDate != null && FeedbackController.ParseTime(create.DueDate).Year < 2000)
                            throw FeedbackController.Invalid();
                        if (!create.RequiresCompletion && create.DueDate != null) throw FeedbackController.Invalid();
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
                            var role = Convert.ToInt32(First(db.Proc("dbo.MobileApi_CorrespondenceActor", "Actor",
                                Actor, "EmployeeNumber", model.EmployeeNumber))["UserType"]);
                            if (!new[] { 1, 2, 3, 4 }.Contains(role) || (role == 4 &&
                                                                         (create.RequiresCompletion ||
                                                                          create.RecipientIDs.Length != 1)))
                                throw new FeedbackException(HttpStatusCode.Forbidden, "ACTION_NOT_ALLOWED",
                                    "غير مسموح بإنشاء هذا التكليف.");
                            var allowed = Rows(db.Text(
                                "DECLARE @x xml=@IDs; SELECT ID FROM dbo.Correspondence_AllowedRecipients(@Actor,@Brand) WHERE ID IN(SELECT n.value('@id','int') FROM @x.nodes('/items/item')x(n))",
                                "Actor", Actor, "Brand", create.BrandID, "IDs", recipients)).Count;
                            if (allowed != create.RecipientIDs.Length)
                                throw new FeedbackException(HttpStatusCode.Forbidden, "RECIPIENT_NOT_ALLOWED",
                                    "أحد المستلمين غير متاح لك.");
                        }

                        upload.Prepare();
                        object result;
                        if (create != null)
                        {
                            var rows = db.Proc("dbo.Insert_Correspondence_Thread", "Actor", Actor, "Brand",
                                create.BrandID, "Recipients", recipients, "Title", create.Title.Trim(), "Brief",
                                create.Brief, "Body", create.Body,
                                "RequiresCompletion", create.RequiresCompletion, "DueDate",
                                create.DueDate == null
                                    ? null
                                    : (object)FeedbackController.ParseTime(create.DueDate).UtcDateTime,
                                "Files", upload.Xml, "Priority", create.PriorityID, "RelatedThreadID",
                                create.RelatedThreadID);
                            result = new { ThreadIDs = Rows(rows).Select(r => Convert.ToInt32(r["ID"])).ToArray() };
                        }
                        else
                        {
                            var row = First(db.Proc("dbo.Insert_Correspondence_Thread_Message", "Actor", Actor,
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

        [HttpPost]
        [Route("threads/{id:int}/close")]
        public HttpResponseMessage Close(int id, CorrespondenceClose model)
        {
            return Mutation("close", id, model, db =>
            {
                var detail = Detail(db, id, false);
                if (!Convert.ToBoolean(detail["CanClose"]))
                    throw new FeedbackException(HttpStatusCode.Conflict, "CANNOT_CLOSE",
                        "الإنهاء غير متاح؛ حدّث تفاصيل المراسلة.");
                db.Proc("dbo.Update_Correspondence_Thread_Close", "Actor", Actor, "ThreadID", id, "IsCompleted",
                    model.IsCompleted, "ClosureReasonID", model.ClosureReasonID, "CloseReason", model.Explanation);
                return new { ThreadID = id };
            });
        }

        [HttpPost]
        [Route("threads/{id:int}/read")]
        public HttpResponseMessage Read(int id, CorrespondenceRead model)
        {
            return Mutation("read", id, model, db =>
            {
                Detail(db, id, false);
                var xml = IDs(model.MessageIDs);
                var valid = Rows(db.Text(
                    "DECLARE @x xml=@IDs; SELECT ID FROM dbo.Correspondence_Thread_Messages WHERE ThreadID=@ID AND ReceivedID=@Actor AND ID IN(SELECT n.value('@id','int') FROM @x.nodes('/items/item')x(n))",
                    "IDs", xml, "ID", id, "Actor", Actor));
                if (valid.Count != model.MessageIDs.Length) throw FeedbackController.Invalid();
                db.Proc("dbo.Update_Correspondence_Messages_Read", "Actor", Actor, "ThreadID", id, "MessageIDs", xml);
                return new { ThreadID = id, model.MessageIDs };
            });
        }

        [HttpPost]
        [Route("threads/{id:int}/archive")]
        public HttpResponseMessage Archive(int id, CorrespondenceArchive model)
        {
            return Mutation("archive", id, model, db =>
            {
                Detail(db, id, true);
                db.Proc("dbo.Correspondence_Archive", "Actor", Actor, "ThreadID", id, "Reason", model.Explanation);
                return new { ThreadID = id };
            });
        }

        [HttpGet]
        [Route("notifications")]
        public HttpResponseMessage Notifications(int employeeNumber, int page = 1, int pageSize = 20,
            bool unreadOnly = false)
        {
            return Execute(() =>
            {
                Page(page, pageSize);
                using (var db = Connect(employeeNumber))
                {
                    var data = db.Text(
                        @"SELECT n.ID,n.ThreadID,n.MessageID,n.SendDate,n.IsRead,t.Title INTO #Notices FROM dbo.Correspondence_Notifications n
JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=n.ThreadID AND a.IsParticipant=1 JOIN dbo.Correspondence_Threads t ON t.ID=n.ThreadID WHERE n.UserID=@Actor;
SELECT COUNT(*) TotalItems FROM #Notices WHERE @Unread=0 OR ISNULL(IsRead,0)=0;
SELECT COUNT(*) UnreadNotifications FROM #Notices WHERE ISNULL(IsRead,0)=0;
SELECT * FROM #Notices WHERE @Unread=0 OR ISNULL(IsRead,0)=0 ORDER BY ID DESC OFFSET @Skip ROWS FETCH NEXT @Size ROWS ONLY;",
                        "Actor", Actor, "Unread", unreadOnly, "Skip", (page - 1) * pageSize, "Size", pageSize);
                    return Success(new
                    {
                        TotalItems = First(data)["TotalItems"],
                        UnreadNotifications = First(data, 1)["UnreadNotifications"],
                        UnreadThreads =
                            First(db.Proc("dbo.Select_Correspondence_UnreadCount", "Actor", Actor))["UnreadThreads"],
                        Page = page, PageSize = pageSize, Items = Rows(data, 2)
                    });
                }
            });
        }

        [HttpPost]
        [Route("notifications/{id:int}/read")]
        public HttpResponseMessage NotificationRead(int id, FeedbackEvent model)
        {
            return Mutation("notification-read", id, model, db =>
            {
                var changed = Rows(db.Text(
                    @"UPDATE n SET IsRead=1 OUTPUT inserted.ID FROM dbo.Correspondence_Notifications n
JOIN dbo.Correspondence_Access(@Actor) a ON a.ID=n.ThreadID AND a.IsParticipant=1 WHERE n.ID=@ID AND n.UserID=@Actor;",
                    "Actor", Actor, "ID", id));
                if (changed.Count == 0)
                    throw new FeedbackException(HttpStatusCode.NotFound, "NOT_FOUND", "التنبيه غير متاح لك.");
                return new { NotificationID = id };
            });
        }

        private HttpResponseMessage Mutation(string action, int id, FeedbackEvent model,
            Func<FeedbackDb, object> operation)
        {
            return Execute(() =>
            {
                if (id <= 0) throw FeedbackController.Invalid();
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
            db.Text(
                "DECLARE @Result int;EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;IF @Result<0 THROW 51802,'Operation busy.',1;",
                "Key", "correspondence:" + Actor + ":" + model.OperationID);
            var rows = Rows(db.Text(
                "SELECT PayloadHash,ResultJson FROM dbo.MobileApi_CorrespondenceEvents WHERE ActorID=@Actor AND OperationID=@Operation",
                "Actor", Actor, "Operation", model.OperationID));
            if (rows.Count == 0) return null;
            if (!((byte[])rows[0]["PayloadHash"]).SequenceEqual(hash))
                throw new FeedbackException(HttpStatusCode.Conflict, "OPERATION_REUSED",
                    "رقم العملية مستخدم لبيانات مختلفة.");
            return Convert.ToString(rows[0]["ResultJson"]);
        }

        private void Record(FeedbackDb db, FeedbackEvent model, byte[] hash, string action, string json)
        {
            db.Text(
                "INSERT dbo.MobileApi_CorrespondenceEvents(ActorID,OperationID,PayloadHash,Action,ResultJson,OccurredAt) VALUES(@Actor,@Operation,@Hash,@Action,@Json,@Occurred)",
                "Actor", Actor, "Operation", model.OperationID, "Hash", hash, "Action", action, "Json", json,
                "Occurred", FeedbackController.ParseTime(model.OccurredAt));
        }

        private HttpResponseMessage Saved(string json, bool replay)
        {
            var result = JObject.Parse(json);
            result["Replayed"] = replay;
            return Success(result);
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
            if (known != null) return MobileApiSupport.Error(Request, known.Status, known.Code, known.Message);
            var sql = ex as SqlException;
            if (sql != null)
            {
                if (sql.Number == 51801)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Forbidden, "EMPLOYEE_MISMATCH", sql.Message);
                if (sql.Number == 51400)
                    return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "BUSINESS_RULE", sql.Message);
                if (sql.Number == 51802 || sql.Number == 1205)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Conflict, "RETRY_OPERATION",
                        "أعد المحاولة بنفس رقم العملية.");
            }

            if (ex is JsonException || ex is ArgumentException || ex is FormatException)
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "تحقق من الحقول وصيغة التاريخ والملفات.");
            Trace.TraceError("Correspondence API failed ({0}).", ex.GetType().Name);
            return MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                "تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
        }
    }
}
