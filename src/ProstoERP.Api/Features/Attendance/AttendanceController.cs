using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using Prosto_ERP_API.Attendance;
using Prosto_ERP_ClassLibrary;

namespace Prosto_ERP_API.Controllers
{
    [AttendanceAuthentication]
    [RoutePrefix("api/attendance")]
    public sealed class AttendanceController : ApiController
    {
        private readonly AttendanceIntegration integration;
        private readonly BioTimeAttendanceService service;

        public AttendanceController() : this(new BioTimeAttendanceService())
        {
        }

        public AttendanceController(BioTimeAttendanceService service) : this(service, null)
        {
        }

        public AttendanceController(BioTimeAttendanceService service,
            AttendanceIntegration integration)
        {
            this.service = service;
            this.integration = integration;
        }

        [HttpPost]
        [Route("transactions")]
        public async Task<HttpResponseMessage> Transactions(AttendanceTransactionsRequest model,
            CancellationToken cancellationToken)
        {
            try
            {
                if (model == null || !ModelState.IsValid || !model.IsValid())
                    return Reply(HttpStatusCode.BadRequest,
                        new
                        {
                            Success = false, Code = "VALIDATION_ERROR",
                            Message =
                                "username, password and employeeCode are required; fromDate and toDate must use yyyy-MM-dd with fromDate <= toDate. Additional fields are not allowed."
                        });
                object brand;
                if (Request.Properties.TryGetValue("AttendanceBrandID", out brand))
                {
                    var store = integration ?? new AttendanceIntegration(ConfigurationManager
                        .ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString);
                    var employee = store.Query("dbo.AttendanceIntegration_ApiEmployee",
                        new SqlParameter("@BrandID", (int)brand),
                        new SqlParameter("@EmployeeCode", model.EmployeeCode));
                    if (employee.Rows.Count == 0)
                        return Reply(HttpStatusCode.Forbidden,
                            new
                            {
                                Success = false, Code = "EMPLOYEE_FORBIDDEN",
                                Message = "Employee is not available for this brand."
                            });
                }

                object bioTimeUrl;
                var selectedService = Request.Properties.TryGetValue("AttendanceBioTimeUrl", out bioTimeUrl)
                    ? service.WithBaseUrl((string)bioTimeUrl)
                    : service;
                var data = await selectedService.GetTransactionsAsync(model, cancellationToken);
                return Reply(HttpStatusCode.OK,
                    new
                    {
                        Success = true,
                        model.EmployeeCode,
                        model.FromDate,
                        model.ToDate,
                        data.Count, Data = data
                    });
            }
            catch (BioTimeException ex)
            {
                Trace.TraceWarning("Attendance integration failed: {0} ({1}).", ex.Code, (int)ex.Status);
                return Reply(ex.Status, new { Success = false, ex.Code, ex.Message });
            }
            catch (Exception ex)
            {
                Trace.TraceError("Attendance integration failed ({0}).", ex.GetType().Name);
                return Reply(HttpStatusCode.InternalServerError,
                    new
                    {
                        Success = false, Code = "INTERNAL_ERROR", Message = "Attendance request could not be completed."
                    });
            }
            finally
            {
                if (model != null)
                {
                    model.Username = null;
                    model.Password = null;
                    model.Extra = null;
                }
            }
        }

        private HttpResponseMessage Reply(HttpStatusCode status, object body)
        {
            var response = Request.CreateResponse(status, body);
            response.Headers.CacheControl = new CacheControlHeaderValue
                { NoStore = true, NoCache = true };
            return response;
        }
    }
}
