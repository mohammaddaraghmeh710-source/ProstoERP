using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Newtonsoft.Json;

namespace Prosto_ERP_API.Mobile
{
    // Public submission only. Viewing or downloading a request still requires the employee session and access checks.
    [MobileTransport]
    [RoutePrefix("api/v1/customer-feedback")]
    public sealed class CustomerFeedbackController : ApiController
    {
        private readonly DateTime receivedUtc = DateTime.UtcNow;
        private int retryAfter;

        [HttpGet]
        [Route("options")]
        public HttpResponseMessage Options(int brandID = 0, int typeID = 0)
        {
            try
            {
                if (!ModelState.IsValid || brandID < 0 || typeID < 0) throw FeedbackController.Invalid();
                using (var db = new FeedbackDb())
                {
                    CheckRate(db, "options");
                    var result = db.Proc("dbo.Select_Customer_Feedback_Options", "Brand", brandID, "Type", typeID);
                    return Success(new
                    {
                        Types = FeedbackController.Rows(result), Brands = FeedbackController.Rows(result, 1),
                        Branches = FeedbackController.Rows(result, 2), Topics = FeedbackController.Rows(result, 3),
                        SourceType = 2, RecipientTitle = "إدارة النظام",
                        FileRules = new
                        {
                            MaxFiles = 5, MaxFileBytes = FeedbackFiles.MaxBytes, MaxImagePixels = 20000000,
                            Extensions = new[] { "pdf", "png", "jpg", "jpeg", "gif" }
                        },
                        RequiredContactFields = new[] { "Name", "Mobile" }, MaxTitleLength = 300,
                        MaxDetailsLength = 10000
                    });
                }
            }
            catch (Exception ex)
            {
                return Failure(ex);
            }
        }

        [HttpPost]
        [Route("requests")]
        public async Task<HttpResponseMessage> Create()
        {
            try
            {
                using (var db = new FeedbackDb())
                {
                    // Checked before buffering attachments; only the actual connection address is used.
                    CheckRate(db, "submit");
                    using (var upload = await FeedbackFiles.Read(Request))
                    {
                        var model = JsonConvert.DeserializeObject<CustomerFeedbackCreate>(upload.Data,
                            FeedbackController.JsonSettings);
                        if (model == null || !Validator.TryValidateObject(model, new ValidationContext(model),
                                new List<ValidationResult>(), true)) throw FeedbackController.Invalid();
                        var phoneDigits = model.Mobile.Count(c => c >= '0' && c <= '9');
                        if (phoneDigits < 7 || phoneDigits > 15) throw FeedbackController.Invalid();
                        FeedbackController.ValidateOperation(model.OperationID, model.OccurredAt);
                        var hash = upload.Hash("customer-submit/" + JsonConvert.SerializeObject(model));
                        db.Begin();
                        db.Text(
                            "DECLARE @Result int; EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000; IF @Result<0 THROW 51802,'Operation busy.',1;",
                            "Key", "customer-feedback:" + model.OperationID);
                        var previous = FeedbackController.Rows(db.Text(
                            "SELECT RequestID,PayloadHash FROM dbo.Customer_Feedback_Submissions WHERE OperationID=@Operation",
                            "Operation", model.OperationID));
                        if (previous.Count > 0)
                        {
                            if (!((byte[])previous[0]["PayloadHash"]).SequenceEqual(hash))
                                throw new FeedbackException(HttpStatusCode.Conflict, "OPERATION_REUSED",
                                    "رقم العملية مستخدم لبيانات مختلفة.");
                            var previousID = Convert.ToInt32(previous[0]["RequestID"]);
                            db.Commit();
                            return Saved(previousID, true);
                        }

                        upload.Prepare();
                        var saved = FeedbackController.Rows(db.Proc("dbo.Insert_Customer_Feedback_Request",
                            "Type", model.TypeID, "Topic", model.TopicID, "Brand", model.BrandID, "Branch",
                            model.BranchID,
                            "Name", model.Name, "Mobile", model.Mobile, "Email", model.Email, "Title", model.Title,
                            "Details", model.Details, "Disclose", model.DiscloseIdentity, "Files", upload.Xml));
                        var id = Convert.ToInt32(saved[0]["ID"]);
                        db.Text(
                            @"INSERT dbo.Customer_Feedback_Submissions(OperationID,PayloadHash,RequestID,OccurredAt,ReceivedUtc,WorkflowGroupID)
                            SELECT @Operation,@Hash,@ID,@Occurred,@Received,GroupID FROM
                            (SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC) w;",
                            "Operation", model.OperationID, "Hash", hash, "ID", id, "Occurred",
                            FeedbackController.ParseTime(model.OccurredAt), "Received", receivedUtc);
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

        private void CheckRate(FeedbackDb db, string scope)
        {
            string address = null;
            object context;
            if (Request.Properties.TryGetValue("MS_HttpContext", out context) && context is HttpContextBase)
                address = ((HttpContextBase)context).Request.UserHostAddress;
            if (string.IsNullOrWhiteSpace(address) && HttpContext.Current != null)
                address = HttpContext.Current.Request.UserHostAddress;
            // Non-IIS hosts without connection context share a restrictive bucket, rather than trusting caller headers.
            IPAddress parsed;
            address = IPAddress.TryParse(address, out parsed) ? parsed.MapToIPv6().ToString() : "unknown-connection";
            byte[] hash;
            using (var sha = SHA256.Create())
            {
                hash = sha.ComputeHash(Encoding.UTF8.GetBytes(address));
            }

            var row = FeedbackController.Rows(db.Proc("dbo.Customer_Feedback_CheckRate", "ClientHash", hash, "Scope",
                scope))[0];
            if (!Convert.ToBoolean(row["Allowed"]))
            {
                retryAfter = Convert.ToInt32(row["RetryAfterSeconds"]);
                throw new FeedbackException((HttpStatusCode)429, "RATE_LIMIT",
                    "تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقًا.");
            }
        }

        private HttpResponseMessage Saved(int id, bool replay)
        {
            return Success(new
            {
                RequestID = id, SourceType = 2, Replayed = replay, Message = "تم تقديم طلبك بنجاح إلى إدارة النظام."
            });
        }

        private HttpResponseMessage Success(object data)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, new { Success = true, Data = data });
            MobileApiSupport.NoCache(response);
            return response;
        }

        private HttpResponseMessage Failure(Exception ex)
        {
            HttpResponseMessage response;
            var known = ex as FeedbackException;
            var sql = ex as SqlException;
            if (known != null)
            {
                response = MobileApiSupport.Error(Request, known.Status, known.Code, known.Message);
            }
            else if (sql != null && sql.Number == 51500)
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
                    "تحقق من بيانات الطلب والملفات.");
            }
            else
            {
                Trace.TraceError("Customer feedback API failed ({0}).", ex.GetType().Name);
                response = MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "تعذر إتمام العملية. أعد المحاولة بنفس رقم العملية.");
            }

            if (retryAfter > 0)
                response.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(retryAfter));
            return response;
        }
    }
}
