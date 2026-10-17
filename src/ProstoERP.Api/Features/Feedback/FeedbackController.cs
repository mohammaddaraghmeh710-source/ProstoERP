using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession, RoutePrefix("api/v1/feedback")]
    public sealed class FeedbackController : ApiController
    {
        int Actor { get { return Convert.ToInt32(((Dictionary<string, object>)Request.Properties["MobileSession"])["UserID"]); } }
        const string Prefix = "dbo.";
        readonly DateTime receivedUtc=DateTime.UtcNow;

        [HttpGet, Route("options")]
        public HttpResponseMessage Options(int employeeNumber, int type = 0)
        {
            return Execute(() => {
                using (var db = Connect(employeeNumber)) {
                    return Success(new {
                        Types = Rows(db.Proc(Prefix+"Select_Employee_Feedback_Types", "Actor",Actor)),
                        Topics = Rows(db.Proc(Prefix+"Select_Employee_Feedback_Topics", "Actor",Actor,"Type",type)),
                        Permissions = Permissions(db), RecipientTypes = Targets(db),
                        Statuses = new[] { new { ID=1,Title="جديد" },new { ID=2,Title="قيد المعالجة" },new { ID=3,Title="منتهي" } },
                        FileRules = new { MaxFiles=5,MaxFileBytes=FeedbackFiles.MaxBytes,MaxImagePixels=20000000,Extensions=new[]{"pdf","png","jpg","jpeg","gif"} },
                        MaxTitleLength=300,MaxDetailsLength=10000,MaxCommentLength=10000
                    });
                }
            });
        }

        [HttpPost, Route("routing-preview")]
        public HttpResponseMessage Routing(FeedbackRouting model)
        {
            return Execute(() => {
                Validate(model);
                using(var db=Connect(model.EmployeeNumber)) {
                    if(model.RequestID.HasValue) RequireCanAct(db,model.RequestID.Value,true);
                    else if(!Flag(Permissions(db),"CanSubmit")) throw Forbidden();
                    var recipients=Rows(model.RequestID.HasValue
                        ? db.Proc(Prefix+"Select_Employee_Feedback_TransferTargets","Actor",Actor,"ID",model.RequestID.Value,"Target",model.RecipientTypeID)
                        : db.Proc(Prefix+"Select_Employee_Feedback_Recipients","Actor",Actor,"Target",model.RecipientTypeID));
                    bool fallback=recipients.Any(r=>Convert.ToBoolean(r["IsFallback"]));
                    return Success(new { RecipientTypeID=model.RecipientTypeID,Recipients=recipients,CanSend=recipients.Count>0,IsFallback=fallback,
                        Message=recipients.Count==0 ? "لا يوجد مستلم متاح." : fallback ? "سيتم إرسال الطلب إلى مدير النظام لعدم وجود المدير المطلوب." : "تم تحديد المستلمين تلقائيًا." });
                }
            });
        }

        [HttpGet, Route("requests")]
        public HttpResponseMessage Requests(int employeeNumber,int page=1,int pageSize=20,string search="",int type=0,int status=0,string scope="all")
        {
            return Execute(() => {
                Page(page,pageSize);
                if((search??"").Length>300 || type<0 || status<0 || status>4 || !new[]{"all","sent","active","closed","action"}.Contains(scope)) throw Invalid();
                using(var db=Connect(employeeNumber)) {
                    var result=db.Proc(Prefix+"MobileApi_FeedbackRequests","Actor",Actor,"Search",search??"","Type",type,"Status",status,"Scope",scope,"Page",page,"PageSize",pageSize);
                    return Success(new { Counts=First(result,0),TotalItems=First(result,1)["TotalItems"],Page=page,PageSize=pageSize,Items=Rows(result,2) });
                }
            });
        }

        [HttpPost, Route("requests")]
        public Task<HttpResponseMessage> Create() { return Upload(false,0); }

        [HttpPost, Route("requests/{id:int}/actions")]
        public Task<HttpResponseMessage> Action(int id) { return Upload(true,id); }

        async Task<HttpResponseMessage> Upload(bool action,int id)
        {
            try {
                using(var upload=await FeedbackFiles.Read(Request)) {
                    FeedbackEvent model=action ? (FeedbackEvent)JsonConvert.DeserializeObject<FeedbackAction>(upload.Data,JsonSettings)
                        : JsonConvert.DeserializeObject<FeedbackCreate>(upload.Data,JsonSettings);
                    Validate(model); ValidateEvent(model);
                    byte[] version=null;
                    if(action) {
                        var m=(FeedbackAction)model;
                        if(m.Action!="transfer" && m.Action!="close") throw Invalid();
                        if(m.Action=="transfer" && (!m.RecipientTypeID.HasValue || m.RecipientTypeID<=0)) throw Invalid();
                        if(m.Action=="close" && m.RecipientTypeID.HasValue) throw Invalid();
                        try { version=Convert.FromBase64String(m.RowVersion); } catch(FormatException) { throw Invalid(); }
                        if(version.Length!=8) throw Invalid();
                    }
                    var fingerprint=upload.Hash((action ? "action/"+id : "submit")+JsonConvert.SerializeObject(model));
                    using(var db=Connect(model.EmployeeNumber)) {
                        db.Begin();
                        int? replay=FindReplay(db,model,fingerprint);
                        if(replay.HasValue) { db.Commit(); return Saved(replay.Value,true); }
                        // SQL authorization precedes any file persistence. The shared procedure checks it again under locks.
                        if(action) {
                            RequireAccess(db,id);
                            var row=First(db.Text("SELECT Status,RowVersion FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID","ID",id));
                            if(Convert.ToInt32(row["Status"])==3 || !((byte[])row["RowVersion"]).SequenceEqual(version))
                                throw new FeedbackException(HttpStatusCode.Conflict,"REQUEST_CHANGED","تم تحديث الطلب أو اتخاذ إجراء عليه. أعد فتح التفاصيل.");
                            RequireCanAct(db,id,((FeedbackAction)model).Action=="transfer");
                        } else if(!Flag(Permissions(db),"CanSubmit")) throw Forbidden();
                        upload.Prepare();
                        string eventType;
                        if(action) {
                            var m=(FeedbackAction)model; eventType=m.Action;
                            db.Proc(Prefix+"Update_Employee_Feedback_Action","Actor",Actor,"ID",id,"Version",version,
                                "Action",m.Action=="transfer"?2:3,"Comment",m.Comment,"Files",upload.Xml,"TargetType",m.RecipientTypeID);
                        } else {
                            var m=(FeedbackCreate)model; eventType="submit";
                            id=Convert.ToInt32(First(db.Proc(Prefix+"Insert_Employee_Feedback_Request","Actor",Actor,"Type",m.TypeID,
                                "Topic",m.TopicID,"Title",m.Title,"Details",m.Details,"Disclose",m.DiscloseIdentity,"Target",m.RecipientTypeID,"Files",upload.Xml))["ID"]);
                        }
                        Record(db,model,fingerprint,id,eventType);
                        // Files are durable before commit; only a confirmed rollback can remove them.
                        upload.PreserveFiles=true;
                        try { db.Commit(); }
                        catch { if(db.RollbackConfirmed()) upload.PreserveFiles=false; throw; }
                        return Saved(id,false);
                    }
                }
            } catch(Exception ex) { return Failure(ex); }
        }

        [HttpPost, Route("requests/{id:int}/open")]
        public HttpResponseMessage Open(int id,FeedbackEvent model)
        {
            return Execute(() => {
                Validate(model); ValidateEvent(model);
                using(var db=Connect(model.EmployeeNumber)) {
                    db.Begin(); RequireAccess(db,id);
                    byte[] hash;
                    using(var sha=SHA256.Create()) hash=sha.ComputeHash(Encoding.UTF8.GetBytes("open/"+id+JsonConvert.SerializeObject(model)));
                    bool replay=FindReplay(db,model,hash).HasValue;
                    if(!replay) {
                        db.Proc(Prefix+"Update_Employee_Feedback_Read","Actor",Actor,"ID",id);
                        Record(db,model,hash,id,"open");
                    }
                    var details=First(db.Proc(Prefix+"Select_Employee_Feedback_Request","Actor",Actor,"ID",id));
                    var type=First(db.Text("SELECT Title_Ar,Title_En FROM dbo.Employee_Feedback_Types WHERE ID=@Type","Type",details["Type"]));
                    details["TypeName"]=type["Title_Ar"]; details["TypeNameEn"]=type["Title_En"];
                    details["StatusTitle"]=Convert.ToInt32(details["Status"])==3 ? "منتهي" : Convert.ToInt32(details["Status"])==2 ? "قيد المعالجة" : "جديد";
                    var permissions=Permissions(db);
                    bool canAct=Flag(details,"CanAct");
                    var attachments=Rows(db.Proc(Prefix+"Select_Employee_Feedback_Attachments","Actor",Actor,"ID",id));
                    foreach(var item in attachments) {
                        item["FileName"]="attachment-"+item["ID"]+"."+item["File_Type"];
                        item["PreviewUrl"]=AttachmentUrl(Convert.ToInt32(item["ID"]),model.EmployeeNumber,false);
                        item["DownloadUrl"]=AttachmentUrl(Convert.ToInt32(item["ID"]),model.EmployeeNumber,true);
                    }
                    var actions=new List<object>();
                    if(canAct && Flag(permissions,"CanTransfer")) actions.Add(new { Code="transfer",Title="تحويل للمتابعة",CommentRequired=true,RecipientRequired=true });
                    if(canAct && Flag(permissions,"CanClose")) actions.Add(new { Code="close",Title="إغلاق الطلب",CommentRequired=true,RecipientRequired=false });
                    var result=new { Request=details,
                        Contact=First(db.Proc(Prefix+"Select_Employee_Feedback_Contact","Actor",Actor,"ID",id)),
                        Attachments=attachments,Workflow=Rows(db.Proc(Prefix+"Select_Employee_Feedback_Workflow","Actor",Actor,"ID",id)),
                        AllowedActions=actions,RecipientTypes=canAct && Flag(permissions,"CanTransfer") ? Targets(db) : new List<Dictionary<string,object>>(),
                        Replayed=replay };
                    db.Commit(); return Success(result);
                }
            });
        }

        [HttpGet, Route("attachments/{id:int}",Name="FeedbackAttachment")]
        public HttpResponseMessage Attachment(int id,int employeeNumber,bool download=false)
        {
            return Execute(() => {
                using(var db=Connect(employeeNumber)) {
                    var rows=Rows(db.Proc(Prefix+"Select_Employee_Feedback_Download","Actor",Actor,"File",id));
                    if(rows.Count!=1) throw NotFound();
                    string name=Convert.ToString(rows[0]["FileName"]),ext=Convert.ToString(rows[0]["File_Type"]).ToLowerInvariant();
                    if(string.IsNullOrEmpty(name) || Path.GetFileName(name)!=name) throw NotFound();
                    string path=Path.Combine(FeedbackFiles.Root,name);
                    if(!File.Exists(path)) throw NotFound();
                    var response=new HttpResponseMessage(HttpStatusCode.OK) { Content=new StreamContent(File.OpenRead(path)) };
                    string mime=FeedbackFiles.Mime(ext);
                    response.Content.Headers.ContentType=new MediaTypeHeaderValue(mime);
                    response.Content.Headers.ContentDisposition=new ContentDispositionHeaderValue(download || mime=="application/octet-stream" ? "attachment" : "inline") { FileName="attachment-"+id+"."+ext };
                    response.Headers.Add("X-Content-Type-Options","nosniff");
                    response.Headers.Add("Content-Security-Policy","sandbox");
                    MobileApiSupport.NoCache(response); return response;
                }
            });
        }

        [HttpGet, Route("notifications")]
        public HttpResponseMessage Notifications(int employeeNumber,int page=1,int pageSize=20,bool unreadOnly=false)
        {
            return Execute(() => {
                Page(page,pageSize);
                using(var db=Connect(employeeNumber)) {
                    var all=Rows(db.Proc(Prefix+"Select_Employee_Feedback_Notifications","Actor",Actor));
                    var filtered=all.Where(r=>!unreadOnly || !Convert.ToBoolean(r["IsRead"])).ToList();
                    return Success(new { UnreadCount=all.Count(r=>!Convert.ToBoolean(r["IsRead"])),TotalItems=filtered.Count,
                        Page=page,PageSize=pageSize,Items=filtered.Skip((page-1)*pageSize).Take(pageSize).ToList() });
                }
            });
        }

        FeedbackDb Connect(int employeeNumber) {
            if(employeeNumber<=0 || !ModelState.IsValid) throw Invalid();
            var db=new FeedbackDb();
            try { db.Proc(Prefix+"MobileApi_FeedbackActor","Actor",Actor,"EmployeeNumber",employeeNumber); return db; }
            catch { db.Dispose(); throw; }
        }
        Dictionary<string,object> Permissions(FeedbackDb db) { return First(db.Proc(Prefix+"Select_Employee_Feedback_Permissions","Actor",Actor)); }
        List<Dictionary<string,object>> Targets(FeedbackDb db) { return Rows(db.Proc(Prefix+"Select_Employee_Feedback_TargetTypes","Actor",Actor)); }
        void RequireAccess(FeedbackDb db,int id) {
            if(Rows(db.Text("SELECT ID FROM dbo.Employee_Feedback_Access(@Actor,0) WHERE ID=@ID","Actor",Actor,"ID",id)).Count==0) throw NotFound();
        }
        void RequireCanAct(FeedbackDb db,int id,bool transfer) {
            RequireAccess(db,id);
            if(!Flag(First(db.Proc(Prefix+"Select_Employee_Feedback_Request","Actor",Actor,"ID",id)),"CanAct") || !Flag(Permissions(db),transfer ? "CanTransfer" : "CanClose")) throw Forbidden();
        }
        int? FindReplay(FeedbackDb db,FeedbackEvent model,byte[] hash) {
            db.Text("DECLARE @Result int; EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000; IF @Result<0 THROW 51802,'Operation busy.',1;",
                "Key","feedback:"+Actor+":"+model.OperationID);
            var rows=Rows(db.Text("SELECT RequestID,PayloadHash FROM dbo.MobileApi_FeedbackEvents WHERE ActorID=@Actor AND OperationID=@Operation","Actor",Actor,"Operation",model.OperationID));
            if(rows.Count==0) return null;
            if(!((byte[])rows[0]["PayloadHash"]).SequenceEqual(hash)) throw new FeedbackException(HttpStatusCode.Conflict,"OPERATION_REUSED","رقم العملية مستخدم لبيانات مختلفة.");
            return Convert.ToInt32(rows[0]["RequestID"]);
        }
        void Record(FeedbackDb db,FeedbackEvent model,byte[] hash,int id,string eventType) {
            db.Text(@"INSERT dbo.MobileApi_FeedbackEvents(ActorID,OperationID,PayloadHash,RequestID,EventType,OccurredAt,ReceivedUtc,WorkflowGroupID,ViewID)
                SELECT @Actor,@Operation,@Hash,@ID,@Event,@Occurred,@Received,
                CASE WHEN @Event='open' THEN NULL ELSE (SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC) END,
                CASE WHEN @Event='open' THEN (SELECT MAX(ID) FROM dbo.Employee_Feedback_Views WHERE Request_ID=@ID AND UserID=@Actor) ELSE NULL END;",
                "Actor",Actor,"Operation",model.OperationID,"Hash",hash,"ID",id,"Event",eventType,
                "Occurred",ParseTime(model.OccurredAt),"Received",receivedUtc);
        }
        string AttachmentUrl(int id,int employee,bool download) {
            return Url.Link("FeedbackAttachment",new { id=id,employeeNumber=employee,download=download });
        }
        internal static readonly JsonSerializerSettings JsonSettings=new JsonSerializerSettings { MissingMemberHandling=MissingMemberHandling.Error,TypeNameHandling=TypeNameHandling.None,MaxDepth=16 };
        void Validate(object model) {
            if(model==null || !ModelState.IsValid || !Validator.TryValidateObject(model,new ValidationContext(model),new List<ValidationResult>(),true)) throw Invalid();
        }
        internal static DateTimeOffset ParseTime(string value) {
            DateTimeOffset parsed;
            if(value==null || !Regex.IsMatch(value,@"(?:Z|[+-]\d{2}:\d{2})$") || !DateTimeOffset.TryParse(value,CultureInfo.InvariantCulture,DateTimeStyles.None,out parsed)) throw Invalid();
            return parsed;
        }
        static void ValidateEvent(FeedbackEvent model) {
            ValidateOperation(model.OperationID,model.OccurredAt);
        }
        internal static void ValidateOperation(Guid operation,string occurredAt) {
            var time=ParseTime(occurredAt);
            if(operation==Guid.Empty || time.Year<2000 || time>DateTimeOffset.UtcNow.AddMinutes(5)) throw Invalid();
        }
        static void Page(int page,int size) { if(page<1 || page>1000000 || size<1 || size>100) throw Invalid(); }
        internal static List<Dictionary<string,object>> Rows(DataSet data,int table=0) {
            if(data.Tables.Count<=table) return new List<Dictionary<string,object>>();
            return data.Tables[table].Rows.Cast<DataRow>().Select(r=> {
                var result=MobileApiSupport.Row(r);
                foreach(var key in result.Keys.ToList()) if(result[key] is DateTime) result[key]=DateTime.SpecifyKind((DateTime)result[key],DateTimeKind.Utc);
                return result;
            }).ToList();
        }
        static Dictionary<string,object> First(DataSet data,int table=0) { return Rows(data,table).FirstOrDefault() ?? new Dictionary<string,object>(); }
        static bool Flag(Dictionary<string,object> row,string key) { return row.ContainsKey(key) && row[key]!=null && Convert.ToBoolean(row[key]); }
        HttpResponseMessage Saved(int id,bool replay) { return Success(new { RequestID=id,Replayed=replay,Message="تم حفظ العملية بنجاح." }); }
        HttpResponseMessage Success(object data) {
            var response=Request.CreateResponse(HttpStatusCode.OK,new { Success=true,Data=data });
            MobileApiSupport.NoCache(response); return response;
        }
        HttpResponseMessage Execute(Func<HttpResponseMessage> action) { try { return action(); } catch(Exception ex) { return Failure(ex); } }
        HttpResponseMessage Failure(Exception ex) {
            var known=ex as FeedbackException;
            if(known!=null) return MobileApiSupport.Error(Request,known.Status,known.Code,known.Message);
            var sql=ex as SqlException;
            if(sql!=null) {
                if(sql.Number==51801) return MobileApiSupport.Error(Request,HttpStatusCode.Forbidden,"EMPLOYEE_MISMATCH",sql.Message);
                if(sql.Number==51500) return MobileApiSupport.Error(Request,HttpStatusCode.BadRequest,"BUSINESS_RULE",sql.Message);
                if(sql.Number==51802 || sql.Number==1205) return MobileApiSupport.Error(Request,HttpStatusCode.Conflict,"RETRY_OPERATION","أعد المحاولة بنفس رقم العملية.");
            }
            if(ex is JsonException || ex is ArgumentException || ex is FormatException) return MobileApiSupport.Error(Request,HttpStatusCode.BadRequest,"INVALID_REQUEST","تحقق من البيانات وصيغة الملفات والتاريخ.");
            Trace.TraceError("Feedback API failed ({0}).",ex.GetType().Name);
            return MobileApiSupport.Error(Request,HttpStatusCode.InternalServerError,"SERVER_ERROR","تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
        }
        internal static FeedbackException Invalid() { return new FeedbackException(HttpStatusCode.BadRequest,"INVALID_REQUEST","تحقق من الحقول المطلوبة والقيم المرسلة."); }
        static FeedbackException Forbidden() { return new FeedbackException(HttpStatusCode.Forbidden,"ACTION_NOT_ALLOWED","لا تملك صلاحية تنفيذ هذا الإجراء."); }
        new static FeedbackException NotFound() { return new FeedbackException(HttpStatusCode.NotFound,"NOT_FOUND","الطلب أو المرفق غير متاح لك."); }
    }

}
