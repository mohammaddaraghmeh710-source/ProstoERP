using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using Prosto_ERP_API.Composition;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    internal static class MobileApiSupport
    {
        internal static byte[] TokenHash(string token) { return MobileBackend.Current.Tokens.TokenHash(token); }
        internal static bool TransportAllowed(HttpRequestMessage request)
        {
            if (request.RequestUri.Scheme == Uri.UriSchemeHttps) return true;
            return request.RequestUri.Scheme == Uri.UriSchemeHttp && MobileBackend.Current.Options.AllowHttp;
        }
        internal static HttpResponseMessage Error(HttpRequestMessage request, HttpStatusCode status, string code, string message)
        {
            return ApiResponseHandler.Error(request, status, code, message);
        }
        internal static void NoCache(HttpResponseMessage response)
        {
            response.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true, Private = true };
        }
    }
}
