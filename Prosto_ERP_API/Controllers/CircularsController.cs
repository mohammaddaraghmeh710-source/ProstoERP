using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;

namespace Prosto_ERP_API.Mobile
{
    [MobileSession, RoutePrefix("api/v1/circulars")]
    public sealed class CircularsController : ApiController
    {
        int Actor { get { return Convert.ToInt32(((Dictionary<string,object>)Request.Properties["MobileSession"])["UserID"]); } }
        static SqlParameter P(string name,SqlDbType type,object value,int size=0) { return MobileApiSupport.P(name,type,value,size); }
        void Employee(int number)
        {
            MobileApiSupport.Query("dbo.Circular_Identity",P("@Actor",SqlDbType.Int,Actor),P("@EmployeeNumber",SqlDbType.Int,number));
        }
        [HttpGet,Route("")]
        public HttpResponseMessage List(int employeeNumber,int page=1,int pageSize=20,string search="",bool unreadOnly=false)
        {
            return Execute(()=>{
                if(page<1||page>100000||pageSize<1||pageSize>100||(search??"").Length>250) return Invalid();
                Employee(employeeNumber);
                var data=MobileApiSupport.Query("dbo.Circular_List",P("@Actor",SqlDbType.Int,Actor),P("@Page",SqlDbType.Int,page),P("@PageSize",SqlDbType.Int,pageSize),P("@Search",SqlDbType.NVarChar,search??"",250),P("@UnreadOnly",SqlDbType.Bit,unreadOnly));
                return Json(new {Counts=MobileApiSupport.Row(data.Tables[0].Rows[0]),TotalItems=data.Tables[1].Rows[0]["TotalItems"],Page=page,PageSize=pageSize,
                    Items=data.Tables[2].Rows.Cast<DataRow>().Select(Item).ToList()});
            });
        }
        [HttpGet,Route("{id:int}")]
        public HttpResponseMessage Detail(int id,int employeeNumber)
        {
            return Execute(()=>{
                Employee(employeeNumber);
                var data=MobileApiSupport.Query("dbo.Circular_Detail",P("@Actor",SqlDbType.Int,Actor),P("@ID",SqlDbType.Int,id));
                return Json(Item(data.Tables[0].Rows[0]));
            });
        }
        [HttpPost,Route("{id:int}/file")]
        public HttpResponseMessage File(int id,CircularFileEvent model)
        {
            return Execute(()=>{
                if(model==null||!ModelState.IsValid||model.EventID==Guid.Empty||(model.Action!="view"&&model.Action!="download")) return Invalid();
                Employee(model.EmployeeNumber);
                var data=MobileApiSupport.Query("dbo.Circular_File",P("@Actor",SqlDbType.Int,Actor),P("@ID",SqlDbType.Int,id),
                    P("@Action",SqlDbType.VarChar,model.Action,16),P("@Source",SqlDbType.VarChar,"Mobile",10),P("@EventID",SqlDbType.UniqueIdentifier,model.EventID),
                    P("@OccurredAtUtc",SqlDbType.DateTime2,model.OccurredAt.HasValue?(object)model.OccurredAt.Value.UtcDateTime:null),
                    P("@TokenHash",SqlDbType.Binary,Request.Properties["MobileTokenHash"],32));
                var row=data.Tables[0].Rows[0];
                var response=Request.CreateResponse(HttpStatusCode.OK);
                response.Content=new ByteArrayContent((byte[])row["FileBytes"]);
                response.Content.Headers.ContentType=new MediaTypeHeaderValue("application/pdf");
                response.Content.Headers.ContentDisposition=new ContentDispositionHeaderValue(model.Action=="download"?"attachment":"inline")
                    {FileName="circular-"+id+".pdf",FileNameStar=Convert.ToString(row["FileName"])};
                response.Headers.Add("X-Circular-Version",Convert.ToString(row["Version"]));
                response.Headers.Add("X-Content-Type-Options","nosniff");
                MobileApiSupport.NoCache(response);
                return response;
            });
        }
        Dictionary<string,object> Item(DataRow row)
        {
            var item=MobileApiSupport.Row(row);
            item["CircularDate"]=Convert.ToDateTime(row["CircularDate"]).ToString("yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture);
            item["FileEndpoint"]="/api/v1/circulars/"+row["ID"]+"/file";
            return item;
        }
        HttpResponseMessage Json(object data)
        {
            var response=Request.CreateResponse(HttpStatusCode.OK,new {Success=true,Data=data});
            MobileApiSupport.NoCache(response);return response;
        }
        HttpResponseMessage Invalid() { return MobileApiSupport.Error(Request,HttpStatusCode.BadRequest,"INVALID_REQUEST","بيانات الطلب غير صحيحة."); }
        HttpResponseMessage Execute(Func<HttpResponseMessage> action)
        {
            try { return action(); }
            catch(SqlException e) when(e.Number>=51800&&e.Number<=51809)
            {
                if(e.Number==51804) return MobileApiSupport.Error(Request,HttpStatusCode.NotFound,"CIRCULAR_UNAVAILABLE","التعميم غير متاح أو خارج فترة الصلاحية.");
                if(e.Number==51803) return MobileApiSupport.Error(Request,HttpStatusCode.Forbidden,"DOWNLOAD_NOT_ALLOWED","تنزيل هذا التعميم غير مسموح.");
                if(e.Number==51801) return MobileApiSupport.Error(Request,HttpStatusCode.Forbidden,"ACCESS_DENIED","لا تملك صلاحية الوصول بهذه الهوية.");
                if(e.Number==51809) return MobileApiSupport.Error(Request,HttpStatusCode.Conflict,"EVENT_CONFLICT","معرف العملية مستخدم لعملية مختلفة. حدّث البيانات.");
                return Invalid();
            }
            catch(Exception e)
            {
                System.Diagnostics.Trace.TraceError("Circular API failed ({0}).",e.GetType().Name);
                return MobileApiSupport.Error(Request,HttpStatusCode.InternalServerError,"SERVER_ERROR","تعذر تنفيذ الطلب.");
            }
        }
    }
    public sealed class CircularFileEvent
    {
        [Range(1,int.MaxValue)] public int EmployeeNumber {get;set;}
        [Required] public string Action {get;set;}
        public Guid EventID {get;set;}
        public DateTimeOffset? OccurredAt {get;set;}
    }
}
