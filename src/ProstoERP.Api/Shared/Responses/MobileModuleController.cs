using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace Prosto_ERP_API.Responses
{
    public abstract class MobileModuleController : ApiController
    {
        protected abstract HttpResponseMessage Failure(Exception exception);
        protected HttpResponseMessage Respond(Func<object> action)
        {
            try { return MobileWorkflowResponse.Create(Request, action()); }
            catch (Exception ex) { return Failure(ex); }
        }
        protected async Task<HttpResponseMessage> RespondAsync(Func<Task<object>> action)
        {
            try { return MobileWorkflowResponse.Create(Request, await action()); }
            catch (Exception ex) { return Failure(ex); }
        }
    }
}
