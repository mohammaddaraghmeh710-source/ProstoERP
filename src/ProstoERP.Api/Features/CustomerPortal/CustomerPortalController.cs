using FeatureService = ProstoERP.Application.Features.CustomerPortal.CustomerPortalService;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Application.Abstractions;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.CustomerPortal;
using Prosto_ERP_API.Composition;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api/v1/customer")]
    public sealed class CustomerPortalController : MobileModuleController
    {
        private readonly DateTime receivedUtc = DateTime.UtcNow;
        private readonly Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService;
        private FeatureService workflow;
        public CustomerPortalController() : this(MobileBackend.Current.CreateCustomerPortal) { }
        public CustomerPortalController(Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService)
        {
            this.createService = createService;
        }
        private FeatureService Workflow => workflow ?? (workflow = createService(
            new ApiWorkflowContext(this, receivedUtc), new ApiWorkflowFiles(Request, false)));

        [HttpPost]
        [Route("login")]
        [ResponseType(typeof(BaseResponse<CustomerLoginResponse>))]
        public HttpResponseMessage Login(CustomerPortalLogin model)
        {
            return Respond(() => Workflow.Login(model));
        }

        [CustomerSession]
        [HttpPost]
        [Route("logout")]
        [ResponseType(typeof(BaseResponse<CustomerLogoutResponse>))]
        public HttpResponseMessage Logout()
        {
            return Respond(() => Workflow.Logout());
        }

        [CustomerSession]
        [HttpGet]
        [Route("me")]
        [ResponseType(typeof(BaseResponse<CustomerSessionResponse>))]
        public HttpResponseMessage Me()
        {
            return Respond(() => Workflow.Me());
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/options")]
        public HttpResponseMessage FeedbackOptions(int brandID = 0, int typeID = 0)
        {
            return Respond(() => Workflow.FeedbackOptions(brandID, typeID));
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/requests")]
        public HttpResponseMessage FeedbackHistory(int page = 1, int pageSize = 20, int status = 0, string search = "")
        {
            return Respond(() => Workflow.FeedbackHistory(page, pageSize, status, search));
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/requests/{id:int:min(1)}")]
        public HttpResponseMessage FeedbackDetail(int id)
        {
            return Respond(() => Workflow.FeedbackDetail(id));
        }

        [CustomerSession]
        [HttpGet]
        [Route("feedback/attachments/{id:int:min(1)}", Name = "CustomerFeedbackFile")]
        public HttpResponseMessage FeedbackFile(int id)
        {
            return Respond(() => Workflow.FeedbackFile(id));
        }

        [CustomerSession]
        [HttpPost]
        [Route("feedback/requests")]
        public Task<HttpResponseMessage> SubmitFeedback()
        {
            return RespondAsync(() => Workflow.SubmitFeedback());
        }

        protected override HttpResponseMessage Failure(Exception exception)
        {
            return MobileErrorHandler.CustomerPortal(Request, exception, Workflow.RetryAfter);
        }
    }
}
