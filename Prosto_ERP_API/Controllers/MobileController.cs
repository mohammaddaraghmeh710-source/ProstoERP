using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api")]
    public sealed class MobileController : ApiController
    {
        [HttpPost, Route("v1/devices/status")]
        public HttpResponseMessage DeviceStatus([FromBody] MobileLoginRequest model) { return DeviceAccess(model, false); }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST", "بيانات الدخول والجهاز وإصدار التطبيق مطلوبة.");
            return Execute(() => {
                var result = MobileApiSupport.QueryDeviceAccess(model, submit);
                if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS", "بيانات الدخول غير صحيحة أو الحساب غير فعال.");
                return Success(new { Success = true, Data = MobileApiSupport.Row(result.Tables[0].Rows[0]) });
            });
        }
        [HttpGet, Route("Get_News"), MobileSession]
        public HttpResponseMessage Get_News()
        {
            return Execute(() =>
            {
                var result = MobileApiSupport.Query("dbo.MobileApi_News");
                var news = result.Tables[0].Rows.Cast<DataRow>().Select(MobileApiSupport.Row).ToList();
                foreach (var item in news) item["Image"] = MobileApiSupport.AssetUrl(item["Image"]);
                return Success(new { Success = true, Count = news.Count, Data = news, Session = Session });
            });
        }
        [HttpGet, Route("Get_InfoPages"), MobileSession]
        public HttpResponseMessage Get_InfoPages()
        {
            return Execute(() =>
            {
                var result = MobileApiSupport.Query("dbo.MobileApi_InfoPages", MobileApiSupport.P("@Actor", SqlDbType.Int, Session["UserID"]));
                var roles = result.Tables[1].Rows.Cast<DataRow>().ToLookup(r => (int)r["PageID"], r => (int)r["UserTypeID"]);
                var pages = result.Tables[0].Rows.Cast<DataRow>().Select(MobileApiSupport.Row).ToList();
                foreach (var page in pages) page["UserTypeIDs"] = roles[(int)page["ID"]].ToArray();
                return Success(new { Success = true, Count = pages.Count, Data = pages, Session = Session });
            });
        }
        [HttpPost, Route("Logout"), MobileSession]
        public HttpResponseMessage Logout()
        {
            return Execute(() =>
            {
                MobileApiSupport.Query("dbo.MobileApi_Logout", MobileApiSupport.P("@TokenHash", SqlDbType.Binary, Request.Properties["MobileTokenHash"], 32));
                return Success(new { Success = true, Data = (object)null });
            });
        }
        private Dictionary<string, object> Session { get { return (Dictionary<string, object>)Request.Properties["MobileSession"]; } }
        private HttpResponseMessage Success(object body)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK, body);
            MobileApiSupport.NoCache(response);
            return response;
        }
        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            try { return action(); }
            catch (SqlException ex) when (ex.Number == 51710)
            {
                return MobileApiSupport.Error(Request, HttpStatusCode.Forbidden, "DEVICE_APPROVAL_REQUIRED", "لا يمكنك تسجيل الدخول من جهاز غير معتمد. يمكنك إرسال طلب للسماح بهذا الجهاز إلى مدير النظام.");
            }
            catch (SqlException ex) when (ex.Number == 51713)
            {
                return MobileApiSupport.Error(Request, (HttpStatusCode)429, "DEVICE_REQUEST_LIMIT", "لديك طلبات أجهزة قيد المراجعة. يرجى انتظار قرار مدير النظام.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API request failed ({0}).", ex.GetType().Name);
                return MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR", "Unable to complete the request.");
            }
        }
    }
}
