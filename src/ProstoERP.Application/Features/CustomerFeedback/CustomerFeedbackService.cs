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
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace ProstoERP.Application.Features.CustomerFeedback
{
    // Public submission only. Viewing or downloading a request still requires the employee session and access checks.
    public sealed class CustomerFeedbackService
    {
        private readonly IMobileDataSessionFactory sessions;
        private readonly IMobileWorkflowContext context;
        private readonly IMobileFiles files;
        public CustomerFeedbackService(IMobileDataSessionFactory sessions, IMobileWorkflowContext context, IMobileFiles files)
        {
            this.sessions = sessions;
            this.context = context;
            this.files = files;
            receivedUtc = context.ReceivedUtc;
        }
        public int RetryAfter => retryAfter;

        private readonly DateTime receivedUtc;
        private int retryAfter;

        public object Options(int brandID = 0, int typeID = 0)
        {
            try
            {
                if (!context.IsModelValid || brandID < 0 || typeID < 0) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                using (var db = sessions.Open())
                {
                    CheckRate(db, "options");
                    var result = db.Execute(MobileStatement.CustomerFeedback_SelectCustomerFeedbackOptions, "Brand", brandID, "Type", typeID);
                    return Success(new CustomerFeedbackOptions
                    {
                        Types = ProstoERP.Application.Data.MobileRowMapper.Rows(result), Brands = ProstoERP.Application.Data.MobileRowMapper.Rows(result, 1),
                        Branches = ProstoERP.Application.Data.MobileRowMapper.Rows(result, 2), Topics = ProstoERP.Application.Data.MobileRowMapper.Rows(result, 3),
                        SourceType = 2, RecipientTitle = "إدارة النظام",
                        FileRules = new FileRules
                        {
                            MaxFiles = 5, MaxFileBytes = files.MaxBytes, MaxImagePixels = 20000000,
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

        public async Task<object> Create()
        {
            try
            {
                using (var db = sessions.Open())
                {
                    // Checked before buffering attachments; only the actual connection address is used.
                    CheckRate(db, "submit");
                    using (var upload = await files.Read())
                    {
                        var model = JsonConvert.DeserializeObject<CustomerFeedbackCreate>(upload.Data,
                            ProstoERP.Application.Validation.MobileJson.Settings);
                        if (model == null || !ProstoERP.Application.Validation.MobileValidation.IsValidModel(model)) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                        var phoneDigits = model.Mobile.Count(c => c >= '0' && c <= '9');
                        if (phoneDigits < 7 || phoneDigits > 15) throw ProstoERP.Application.Validation.MobileValidation.Invalid();
                        ProstoERP.Application.Validation.MobileValidation.ValidateOperation(model.OperationID, model.OccurredAt);
                        var hash = upload.Hash("customer-submit/" + JsonConvert.SerializeObject(model));
                        db.Begin();
                        db.Execute(MobileStatement.CustomerFeedback_CreateLock,
                            "Key", "customer-feedback:" + model.OperationID);
                        var previous = ProstoERP.Application.Data.MobileRowMapper.Rows(db.Execute(MobileStatement.CustomerFeedback_CreateCustomerFeedbackSubmissions,
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
                        var saved = ProstoERP.Application.Data.MobileRowMapper.Rows(db.Execute(MobileStatement.CustomerFeedback_InsertCustomerFeedbackRequest,
                            "Type", model.TypeID, "Topic", model.TopicID, "Brand", model.BrandID, "Branch",
                            model.BranchID,
                            "Name", model.Name, "Mobile", model.Mobile, "Email", model.Email, "Title", model.Title,
                            "Details", model.Details, "Disclose", model.DiscloseIdentity, "Files", upload.Xml));
                        var id = Convert.ToInt32(saved[0]["ID"]);
                        db.Execute(MobileStatement.CustomerFeedback_CreateEmployeeFeedbackWorkflow,
                            "Operation", model.OperationID, "Hash", hash, "ID", id, "Occurred",
                            ProstoERP.Application.Validation.MobileValidation.ParseTime(model.OccurredAt), "Received", receivedUtc);
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
            string address = context.ClientAddress;
            // Non-IIS hosts without connection context share a restrictive bucket, rather than trusting caller headers.
            IPAddress parsed;
            address = IPAddress.TryParse(address, out parsed) ? parsed.MapToIPv6().ToString() : "unknown-connection";
            byte[] hash;
            using (var sha = SHA256.Create())
            {
                hash = sha.ComputeHash(Encoding.UTF8.GetBytes(address));
            }

            var row = ProstoERP.Application.Data.MobileRowMapper.Rows(db.Execute(MobileStatement.CustomerFeedback_CustomerFeedbackCheckRate, "ClientHash", hash, "Scope",
                scope))[0];
            if (!Convert.ToBoolean(row["Allowed"]))
            {
                retryAfter = Convert.ToInt32(row["RetryAfterSeconds"]);
                throw new FeedbackException((HttpStatusCode)429, "RATE_LIMIT",
                    "تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقًا.");
            }
        }

        private object Saved(int id, bool replay)
        {
            return Success(new SavedCustomerFeedbackResponse
            {
                RequestID = id, SourceType = 2, Replayed = replay, Message = "تم تقديم طلبك بنجاح إلى إدارة النظام."
            });
        }

        private object Success(object data) { return data; }

        private object Failure(Exception ex)
        {
            System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(ex).Throw();
            return null;
        }
    }
}
