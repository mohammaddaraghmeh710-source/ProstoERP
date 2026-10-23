using Prosto_ERP_API.Responses;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession]
    [RoutePrefix("api/v1/circulars")]
    public sealed class CircularsController : ApiController
    {
        private readonly ProstoERP.Application.Features.Circulars.CircularService circulars;
        public CircularsController() : this(Prosto_ERP_API.Composition.MobileBackend.Current.Circulars) { }
        public CircularsController(ProstoERP.Application.Features.Circulars.CircularService circulars)
        {
            this.circulars = circulars;
        }

        private int Actor =>
            Convert.ToInt32(((Dictionary<string, object>)Request.Properties["MobileSession"])["UserID"]);





        [HttpGet]
        [Route("")]
        public HttpResponseMessage List(int employeeNumber, int page = 1, int pageSize = 20, string search = "",
            bool unreadOnly = false)
        {
            return Execute(() =>
            {
                if (page < 1 || page > 100000 || pageSize < 1 || pageSize > 100 || (search ?? "").Length > 250)
                    return Invalid();
                return Json(circulars.List(Actor, employeeNumber, page, pageSize, search, unreadOnly));
            });
        }

        [HttpGet]
        [Route("{id:int}")]
        public HttpResponseMessage Detail(int id, int employeeNumber)
        {
            return Execute(() =>
            {
                return Json(circulars.Detail(Actor, id, employeeNumber));
            });
        }

        [HttpPost]
        [Route("{id:int}/file")]
        public HttpResponseMessage File(int id, CircularFileEvent model)
        {
            return Execute(() =>
            {
                if (model == null || !ModelState.IsValid || model.EventID == Guid.Empty ||
                    (model.Action != "view" && model.Action != "download")) return Invalid();
                var file = circulars.File(Actor, id, model, Request.Properties["MobileTokenHash"]);
                var response = Request.CreateResponse(HttpStatusCode.OK);
                response.Content = new ByteArrayContent(file.Bytes);
                response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
                response.Content.Headers.ContentDisposition =
                    new ContentDispositionHeaderValue(model.Action == "download" ? "attachment" : "inline")
                        { FileName = "circular-" + id + ".pdf", FileNameStar = file.FileName };
                response.Headers.Add("X-Circular-Version", file.Version);
                response.Headers.Add("X-Content-Type-Options", "nosniff");
                MobileApiSupport.NoCache(response);
                return response;
            });
        }



        private HttpResponseMessage Json(object data)
        {
            return Prosto_ERP_API.Responses.ApiResponseHandler.Success(Request, data);
        }

        private HttpResponseMessage Invalid()
        {
            return MobileApiSupport.Error(Request, HttpStatusCode.BadRequest, "INVALID_REQUEST",
                "بيانات الطلب غير صحيحة.");
        }

        private HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            return MobileErrorHandler.Circulars(Request, action);
        }
    }
}
