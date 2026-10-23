using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using ProstoERP.Contracts.Common;

namespace Prosto_ERP_API.Responses
{
    public static class ApiResponseHandler
    {
        public static HttpResponseMessage Body(HttpRequestMessage request, object body)
        {
            return NoCache(request.CreateResponse(HttpStatusCode.OK, body));
        }

        public static HttpResponseMessage Success<T>(HttpRequestMessage request, T data)
        {
            return NoCache(request.CreateResponse(HttpStatusCode.OK, BaseResponse<T>.Ok(data)));
        }

        public static HttpResponseMessage Success(HttpRequestMessage request)
        {
            return NoCache(request.CreateResponse(HttpStatusCode.OK, BaseResponse.Ok()));
        }

        public static HttpResponseMessage Error(HttpRequestMessage request, HttpStatusCode status,
            string code, string message)
        {
            var response = NoCache(request.CreateResponse(status, BaseResponse.Fail(code, message)));
            if (status == HttpStatusCode.Unauthorized)
                response.Headers.WwwAuthenticate.Add(new AuthenticationHeaderValue("Bearer"));
            return response;
        }

        private static HttpResponseMessage NoCache(HttpResponseMessage response)
        {
            response.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true, Private = true };
            return response;
        }
    }
}
