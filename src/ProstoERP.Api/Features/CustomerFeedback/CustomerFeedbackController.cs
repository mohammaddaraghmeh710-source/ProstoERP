using FeatureService = ProstoERP.Application.Features.CustomerFeedback.CustomerFeedbackService;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Application.Abstractions;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.CustomerFeedback;
using Prosto_ERP_API.Composition;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    // Public submission only. Viewing or downloading a request still requires the employee session and access checks.
    [MobileTransport]
    [RoutePrefix("api/v1/customer-feedback")]
    public sealed class CustomerFeedbackController : MobileModuleController
    {
        private readonly DateTime receivedUtc = DateTime.UtcNow;
        private readonly Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService;
        private FeatureService workflow;
        public CustomerFeedbackController() : this(MobileBackend.Current.CreateCustomerFeedback) { }
        public CustomerFeedbackController(Func<IMobileWorkflowContext, IMobileFiles, FeatureService> createService)
        {
            this.createService = createService;
        }
        private FeatureService Workflow => workflow ?? (workflow = createService(
            new ApiWorkflowContext(this, receivedUtc), new ApiWorkflowFiles(Request, false)));

        [HttpGet]
        [Route("options")]
        [ResponseType(typeof(BaseResponse<CustomerFeedbackOptions>))]
        public HttpResponseMessage Options(int brandID = 0, int typeID = 0)
        {
            return Respond(() => Workflow.Options(brandID, typeID));
        }

        [HttpPost]
        [Route("requests")]
        [ResponseType(typeof(BaseResponse<SavedCustomerFeedbackResponse>))]
        public Task<HttpResponseMessage> Create()
        {
            return RespondAsync(() => Workflow.Create());
        }

        protected override HttpResponseMessage Failure(Exception exception)
        {
            return MobileErrorHandler.CustomerFeedback(Request, exception, Workflow.RetryAfter);
        }
    }
}
