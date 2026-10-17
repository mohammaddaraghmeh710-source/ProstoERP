using System;
using System.Net;
using System.Web.Http.Controllers;
using Prosto_ERP_API.Authentication;

namespace Prosto_ERP_API.Controllers
{
    // Attendance shares database-backed ERP credentials, then selects the same brand BioTime root.
    public sealed class AttendanceAuthenticationAttribute : AttendanceCredentialAuthenticationAttribute
    {
        public AttendanceAuthenticationAttribute() { }
        public AttendanceAuthenticationAttribute(Prosto_ERP_ClassLibrary.AttendanceIntegration integration) : base(integration) { }
        public override void OnAuthorization(HttpActionContext context)
        {
            context.Request.Properties.Remove("AttendanceBrandID");
            context.Request.Properties.Remove("AttendanceBioTimeUrl");
            base.OnAuthorization(context);
            if (context.Response != null) return;
            try
            {
                context.Request.Properties["AttendanceBrandID"] = context.Request.Properties["AttendanceAuthenticatedBrandID"];
                context.Request.Properties["AttendanceBioTimeUrl"] = Store.BioTimeUrl((int)context.Request.Properties["AttendanceAuthenticatedBrandID"]);
            }
            catch (Exception) { Reject(context,HttpStatusCode.ServiceUnavailable); }
        }
    }
}
