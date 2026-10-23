using FeatureService = ProstoERP.Application.Features.Correspondence.CorrespondenceService;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Application.Abstractions;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Correspondence;
using Prosto_ERP_API.Composition;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession]
    [RoutePrefix("api/v1/correspondence")]
    public sealed class CorrespondenceController : MobileModuleController
    {
        private readonly DateTime receivedUtc = DateTime.UtcNow;
        private readonly Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService;
        private FeatureService workflow;
        public CorrespondenceController() : this(MobileBackend.Current.CreateCorrespondence) { }
        public CorrespondenceController(Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService)
        {
            this.createService = createService;
        }
        private FeatureService Workflow => workflow ?? (workflow = createService(
            new ApiWorkflowContext(this, receivedUtc), new ApiWorkflowFiles(Request, true)));

        [HttpGet]
        [Route("options")]
        [ResponseType(typeof(BaseResponse<CorrespondenceOptionsResponse>))]
        public HttpResponseMessage Options(int employeeNumber, bool task = false, int brandID = 0)
        {
            return Respond(() => Workflow.Options(employeeNumber, task, brandID));
        }

        [HttpGet]
        [Route("recipients")]
        [ResponseType(typeof(BaseResponse<TotalItemsPage<Dictionary<string, object>>>))]
        public HttpResponseMessage Recipients(int employeeNumber, int brandID = 0, int branchID = 0, int shiftID = 0,
            string search = "", int page = 1, int pageSize = 30)
        {
            return Respond(() => Workflow.Recipients(employeeNumber, brandID, branchID, shiftID, search, page, pageSize));
        }

        [HttpGet]
        [Route("threads")]
        [ResponseType(typeof(BaseResponse<CountedPage<Dictionary<string, object>, Dictionary<string, object>>>))]
        public HttpResponseMessage Threads(int employeeNumber, int page = 1, int pageSize = 20,
            bool supervisory = false, string title = "", string person = "", string filter = "all", int kind = 0,
            int priorityID = 0, int brandID = 0, int branchID = 0, DateTimeOffset? from = null,
            DateTimeOffset? to = null)
        {
            return Respond(() => Workflow.Threads(employeeNumber, page, pageSize, supervisory, title, person, filter, kind, priorityID, brandID, branchID, from, to));
        }

        [HttpPost]
        [Route("threads/{id:int}/open")]
        [ResponseType(typeof(BaseResponse<CorrespondenceDetailResponse>))]
        public HttpResponseMessage Open(int id, CorrespondenceOpen model)
        {
            return Respond(() => Workflow.Open(id, model));
        }

        [HttpGet]
        [Route("threads/{id:int}/messages")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMessagesResponse>))]
        public HttpResponseMessage Messages(int id, int employeeNumber, int afterID = 0, int beforeID = 0,
            int pageSize = 30, bool supervisory = false, Guid? visitID = null)
        {
            return Respond(() => Workflow.Messages(id, employeeNumber, afterID, beforeID, pageSize, supervisory, visitID));
        }

        [HttpPost]
        [Route("threads")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public Task<HttpResponseMessage> Create()
        {
            return RespondAsync(() => Workflow.Create());
        }

        [HttpPost]
        [Route("threads/{id:int}/messages")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public Task<HttpResponseMessage> Reply(int id)
        {
            return RespondAsync(() => Workflow.Reply(id));
        }

        [HttpPost]
        [Route("threads/{id:int}/close")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public HttpResponseMessage Close(int id, CorrespondenceClose model)
        {
            return Respond(() => Workflow.Close(id, model));
        }

        [HttpPost]
        [Route("threads/{id:int}/read")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public HttpResponseMessage Read(int id, CorrespondenceRead model)
        {
            return Respond(() => Workflow.Read(id, model));
        }

        [HttpPost]
        [Route("threads/{id:int}/archive")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public HttpResponseMessage Archive(int id, CorrespondenceArchive model)
        {
            return Respond(() => Workflow.Archive(id, model));
        }

        [HttpGet]
        [Route("notifications")]
        public HttpResponseMessage Notifications(int employeeNumber, int page = 1, int pageSize = 20,
            bool unreadOnly = false)
        {
            return Respond(() => Workflow.Notifications(employeeNumber, page, pageSize, unreadOnly));
        }

        [HttpPost]
        [Route("notifications/{id:int}/read")]
        [ResponseType(typeof(BaseResponse<CorrespondenceMutationResponse>))]
        public HttpResponseMessage NotificationRead(int id, FeedbackEvent model)
        {
            return Respond(() => Workflow.NotificationRead(id, model));
        }

        protected override HttpResponseMessage Failure(Exception exception)
        {
            return MobileErrorHandler.Correspondence(Request, exception);
        }
    }
}
