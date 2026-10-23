using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using ProstoERP.Application.Abstractions;
using Prosto_ERP_API.Mobile;

namespace Prosto_ERP_API.Responses
{
    internal static class MobileWorkflowResponse
    {
        internal static HttpResponseMessage Create(HttpRequestMessage request, object result)
        {
            var file = result as MobileFileResult;
            if (file == null) return ApiResponseHandler.Success(request, result);
            var response = request.CreateResponse(HttpStatusCode.OK);
            response.Content = new StreamContent(file.Stream);
            response.Content.Headers.ContentType = new MediaTypeHeaderValue(file.Mime);
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue(file.Download ? "attachment" : "inline")
                { FileName = file.Name };
            response.Headers.Add("X-Content-Type-Options", "nosniff");
            if (file.Sandbox) response.Headers.Add("Content-Security-Policy", "sandbox");
            MobileApiSupport.NoCache(response);
            return response;
        }
    }
}
