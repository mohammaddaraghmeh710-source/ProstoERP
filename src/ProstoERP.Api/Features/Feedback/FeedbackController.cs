using FeatureService = ProstoERP.Application.Features.Feedback.FeedbackService;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Application.Abstractions;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.Feedback;
using Prosto_ERP_API.Composition;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession]
    [RoutePrefix("api/v1/feedback")]
    public sealed class FeedbackController : MobileModuleController
    {
        private readonly DateTime receivedUtc = DateTime.UtcNow;
        private readonly Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService;
        private FeatureService workflow;
        public FeedbackController() : this(MobileBackend.Current.CreateFeedback) { }
        public FeedbackController(Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService)
        {
            this.createService = createService;
        }
        private FeatureService Workflow => workflow ?? (workflow = createService(
            new ApiWorkflowContext(this, receivedUtc), new ApiWorkflowFiles(Request, false)));

        [HttpGet]
        [Route("options")]
        [ResponseType(typeof(BaseResponse<FeedbackOptionsResponse>))]
        public HttpResponseMessage Options(int employeeNumber, int type = 0)
        {
            return Respond(() => Workflow.Options(employeeNumber, type));
        }

        [HttpPost]
        [Route("routing-preview")]
        [ResponseType(typeof(BaseResponse<FeedbackRoutingResponse>))]
        public HttpResponseMessage Routing(FeedbackRouting model)
        {
            return Respond(() => Workflow.Routing(model));
        }

        [HttpGet]
        [Route("requests")]
        [ResponseType(typeof(BaseResponse<CountedPage<Dictionary<string, object>, Dictionary<string, object>>>))]
        public HttpResponseMessage Requests(int employeeNumber, int page = 1, int pageSize = 20, string search = "",
            int type = 0, int status = 0, string scope = "all")
        {
            return Respond(() => Workflow.Requests(employeeNumber, page, pageSize, search, type, status, scope));
        }

        [HttpPost]
        [Route("requests")]
        [ResponseType(typeof(BaseResponse<SavedRequestResponse>))]
        public Task<HttpResponseMessage> Create()
        {
            return RespondAsync(() => Workflow.Create());
        }

        [HttpPost]
        [Route("requests/{id:int}/actions")]
        [ResponseType(typeof(BaseResponse<SavedRequestResponse>))]
        public Task<HttpResponseMessage> Action(int id)
        {
            return RespondAsync(() => Workflow.Action(id));
        }

        [HttpPost]
        [Route("requests/{id:int}/open")]
        [ResponseType(typeof(BaseResponse<FeedbackDetailResponse>))]
        public HttpResponseMessage Open(int id, FeedbackEvent model)
        {
            return Respond(() => Workflow.Open(id, model));
        }

        [HttpGet]
        [Route("attachments/{id:int}", Name = "FeedbackAttachment")]
        public HttpResponseMessage Attachment(int id, int employeeNumber, bool download = false)
        {
            return Respond(() => Workflow.Attachment(id, employeeNumber, download));
        }

        [HttpGet]
        [Route("notifications")]
        [ResponseType(typeof(BaseResponse<NotificationPage<Dictionary<string, object>>>))]
        public HttpResponseMessage Notifications(int employeeNumber, int page = 1, int pageSize = 20,
            bool unreadOnly = false)
        {
            return Respond(() => Workflow.Notifications(employeeNumber, page, pageSize, unreadOnly));
        }

        protected override HttpResponseMessage Failure(Exception exception)
        {
            return MobileErrorHandler.Feedback(Request, exception);
        }
    }
}
