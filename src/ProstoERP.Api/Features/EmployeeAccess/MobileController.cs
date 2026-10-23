using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.EmployeeAccess;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api")]
    public sealed class MobileController : ApiController
    {
        private readonly ProstoERP.Application.Features.EmployeeAccess.EmployeeAccessService employeeAccess;
        public MobileController() : this(Prosto_ERP_API.Composition.MobileBackend.Current.EmployeeAccess,
            Prosto_ERP_API.Composition.MobileBackend.Current.Content) { }
        private readonly ProstoERP.Application.Features.EmployeeAccess.MobileContentService content;
        public MobileController(ProstoERP.Application.Features.EmployeeAccess.EmployeeAccessService employeeAccess,
            ProstoERP.Application.Features.EmployeeAccess.MobileContentService content)
        {
            this.employeeAccess = employeeAccess;
            this.content = content;
        }

        private Dictionary<string, object> Session => (Dictionary<string, object>)Request.Properties["MobileSession"];

        [HttpPost]
        [Route("v1/devices/status")]
        [ResponseType(typeof(BaseResponse<DeviceAccessResponse>))]
        [Obsolete("Use email-verified registration.")]
        public HttpResponseMessage DeviceStatus([FromBody] MobileLoginRequest model)
        {
            return DeviceAccess(model, false);
        }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            return MobileApiSupport.Error(Request, HttpStatusCode.Gone, "OTP_REGISTRATION_REQUIRED", "Use /api/v1/auth/register and /verify-otp to activate one device.");
        }

        [HttpPost]
        [Route("Get_News")]
        [MobileSession]
        [ResponseType(typeof(CountResponse<ProstoERP.Contracts.Features.News.NewsItem, Dictionary<string, object>>))]
        public HttpResponseMessage Get_News([FromBody] NewsRequest model)
        {
            if (model == null || !ModelState.IsValid || model.BrandID <= 0 ||
                (model.Extra != null && model.Extra.Count > 0))
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_BRAND",
                    "أرسل BrandID موجبًا فقط داخل JSON Body.");
            return Execute(() => Success(content.News(Session, model.BrandID)));
        }

        [HttpGet]
        [Route("Get_InfoPages")]
        [MobileSession]
        [ResponseType(typeof(CountResponse<InformationPage, Dictionary<string, object>>))]
        public HttpResponseMessage Get_InfoPages()
        {
            return Execute(() => Success(content.InformationPages(Session)));
        }

        [HttpPost]
        [Route("Logout")]
        [MobileSession]
        [ResponseType(typeof(BaseResponse))]
        public HttpResponseMessage Logout()
        {
            return Execute(() =>
            {
                content.Logout(Request.Properties["MobileTokenHash"]);
                return ApiResponseHandler.Success(Request);
            });
        }

        private HttpResponseMessage Success(object body)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, body);
            MobileApiSupport.NoCache(response);
            return response;
        }

        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            return MobileErrorHandler.Mobile(Request, action);
        }
    }
}
