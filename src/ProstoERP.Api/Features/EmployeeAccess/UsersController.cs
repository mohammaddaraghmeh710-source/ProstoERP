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
            return Execute(() => ApiResponseHandler.Success(Request, employeeAccess.Login(model)));
        }

        [HttpPost]
        [Route("LoginViaBIO")]
        [IntegrationBasicAuthentication]
        [ResponseType(typeof(BaseResponse<EmployeeLoginResponse>))]
        public HttpResponseMessage LoginViaBIO([FromBody] BioLoginRequest model)
        {
            if (model == null || !ModelState.IsValid || (model.Extra != null && model.Extra.Count != 0) ||
                MobileApiSupport.TokenHash(model.BIOID) == null)
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_BIOID_FORMAT",
                    "يجب إرسال BIOID صالح فقط في جسم الطلب.");
            return Execute(() => ApiResponseHandler.Success(Request, employeeAccess.LoginViaBio(model)));
        }

        [HttpPost]
        [Route("AddNewDevices")]
        [ResponseType(typeof(BaseResponse<DeviceAccessResponse>))]
        public HttpResponseMessage Add_New_Devices([FromBody] MobileLoginRequest model)
        {
            return DeviceAccess(model, true);
        }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "بيانات الدخول والجهاز وإصدار التطبيق مطلوبة.");
            return Execute(() => ApiResponseHandler.Success(Request, employeeAccess.DeviceAccess(model, submit)));
        }



        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            return MobileErrorHandler.Users(Request, action);
        }
    }
}
