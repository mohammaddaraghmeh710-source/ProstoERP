using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Prosto_ERP_API.Responses;

namespace Prosto_ERP_API.Mobile
{
    [MobileTransport]
    [RoutePrefix("api")]
    public sealed class MobileController : ApiController
    {
        private Dictionary<string, object> Session => (Dictionary<string, object>)Request.Properties["MobileSession"];

        [HttpPost]
        [Route("v1/devices/status")]
        public HttpResponseMessage DeviceStatus([FromBody] MobileLoginRequest model)
        {
            return DeviceAccess(model, false);
        }

        private HttpResponseMessage DeviceAccess(MobileLoginRequest model, bool submit)
        {
            if (model == null || !ModelState.IsValid || !model.NormalizeAndValidate())
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                    "بيانات الدخول والجهاز وإصدار التطبيق مطلوبة.");
            return Execute(() =>
            {
                var result = MobileApiSupport.QueryDeviceAccess(model, submit);
                if (result.Tables.Count == 0 || result.Tables[0].Rows.Count == 0)
                    return MobileApiSupport.Error(Request, HttpStatusCode.Unauthorized, "INVALID_CREDENTIALS",
                        "بيانات الدخول غير صحيحة أو الحساب غير فعال.");
                return Success(new { Success = true, Data = MobileApiSupport.Row(result.Tables[0].Rows[0]) });
            });
        }

        [HttpPost]
        [Route("Get_News")]
        [MobileSession]
        public HttpResponseMessage Get_News([FromBody] NewsRequest model)
        {
            if (model == null || !ModelState.IsValid || model.BrandID <= 0 ||
                (model.Extra != null && model.Extra.Count > 0))
                return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_BRAND",
                    "أرسل BrandID موجبًا فقط داخل JSON Body.");
            return Execute(() =>
            {
                var result = MobileApiSupport.Query("dbo.MobileApi_News",
                    MobileApiSupport.P("@Actor", SqlDbType.Int, Session["UserID"]),
                    MobileApiSupport.P("@BrandID", SqlDbType.Int, model.BrandID));
                var news = result.Tables[0].Rows.Cast<DataRow>().Select(MobileApiSupport.Row).ToList();
                foreach (var item in news) item["Image"] = MobileApiSupport.AssetUrl(item["Image"]);
                return Success(new { Success = true, news.Count, Data = news, Session });
            });
        }

        [HttpGet]
        [Route("Get_InfoPages")]
        [MobileSession]
        public HttpResponseMessage Get_InfoPages()
        {
            return Execute(() =>
            {
                var result = MobileApiSupport.Query("dbo.MobileApi_InfoPages",
                    MobileApiSupport.P("@Actor", SqlDbType.Int, Session["UserID"]));
                var roles = result.Tables[1].Rows.Cast<DataRow>()
                    .ToLookup(r => (int)r["PageID"], r => (int)r["UserTypeID"]);
                var pages = result.Tables[0].Rows.Cast<DataRow>().Select(MobileApiSupport.Row).ToList();
                foreach (var page in pages) page["UserTypeIDs"] = roles[(int)page["ID"]].ToArray();
                return Success(new { Success = true, pages.Count, Data = pages, Session });
            });
        }

        [HttpPost]
        [Route("Logout")]
        [MobileSession]
        public HttpResponseMessage Logout()
        {
            return Execute(() =>
            {
                MobileApiSupport.Query("dbo.MobileApi_Logout",
                    MobileApiSupport.P("@TokenHash", SqlDbType.Binary, Request.Properties["MobileTokenHash"], 32));
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
            try
            {
                return action();
            }
            catch (SqlException ex) when (ex.Number == 51953)
            {
                return MobileApiSupport.Error(Request, HttpStatusCode.Forbidden, "BRAND_ACCESS_DENIED",
                    "العلامة المطلوبة غير متاحة أو لا تطابق علامة الموظف الحالية.");
            }
            catch (SqlException ex) when (ex.Number == 51710)
            {
                return MobileApiSupport.Error(Request, HttpStatusCode.Forbidden, "DEVICE_APPROVAL_REQUIRED",
                    "لا يمكنك تسجيل الدخول من جهاز غير معتمد. يمكنك إرسال طلب للسماح بهذا الجهاز إلى مدير النظام.");
            }
            catch (SqlException ex) when (ex.Number == 51713)
            {
                return MobileApiSupport.Error(Request, (HttpStatusCode)429, "DEVICE_REQUEST_LIMIT",
                    "لديك طلبات أجهزة قيد المراجعة. يرجى انتظار قرار مدير النظام.");
            }
            catch (Exception ex)
            {
                Trace.TraceError("Mobile API request failed ({0}).", ex.GetType().Name);
                return MobileApiSupport.Error(Request, HttpStatusCode.InternalServerError, "SERVER_ERROR",
                    "Unable to complete the request.");
            }
        }
    }
}
