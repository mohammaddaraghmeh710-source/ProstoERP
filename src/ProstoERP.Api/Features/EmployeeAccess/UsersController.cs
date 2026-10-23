using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;
using System.Web.Http.Description;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.EmployeeAccess;
using Echo.Encrptor;
using Prosto_ERP_API.Authentication;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api/Users")]
    public sealed partial class UsersController : ApiController
    {
        private readonly ProstoERP.Application.Features.EmployeeAccess.EmployeeAccessService employeeAccess;

        public UsersController() : this(Prosto_ERP_API.Composition.MobileBackend.Current.EmployeeAccess) { }
        public UsersController(ProstoERP.Application.Features.EmployeeAccess.EmployeeAccessService employeeAccess)
        {
            this.employeeAccess = employeeAccess;
        }

        [HttpPost]
        [Route("Login")]
        [ResponseType(typeof(BaseResponse<EmployeeLoginResponse>))]
        public HttpResponseMessage Login([FromBody] MobileLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "Username, Password, AppVersion and valid Device information are required.");
            return Prosto_ERP_API.Features.Authentication.AuthenticationResponses.Execute(Request,
                () => Composition.MobileBackend.Current.CreateAuthentication(employeeAccess).Login(model, System.Web.HttpContext.Current == null ? "unknown" : System.Web.HttpContext.Current.Request.UserHostAddress));
        }

        [HttpPost]
        [Route("LoginViaBIO")]
        [IntegrationBasicAuthentication]
        [ResponseType(typeof(BaseResponse<EmployeeLoginResponse>))]
        [Obsolete("Use the signed biometric challenge flow.")]
        public HttpResponseMessage LoginViaBIO([FromBody] BioLoginRequest model)
        {
            return MobileApiSupport.Error(Request, HttpStatusCode.Gone, "BIOMETRIC_CHALLENGE_REQUIRED",
                "Static BIOID login has been retired. Use /api/v1/auth/biometric/challenge and /biometric/login.");
        }

        [HttpPost]
        [Route("AddNewDevices")]
        [ResponseType(typeof(BaseResponse<DeviceAccessResponse>))]
        [Obsolete("Use email-verified registration.")]
        public HttpResponseMessage Add_New_Devices([FromBody] MobileLoginRequest model)
        {
            return DeviceAccess(model, true);
        }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            return MobileApiSupport.Error(Request, HttpStatusCode.Gone, "OTP_REGISTRATION_REQUIRED", "Use /api/v1/auth/register and /verify-otp to activate one device.");
        }


        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            return MobileErrorHandler.Users(Request, action);
        }
    }
}
