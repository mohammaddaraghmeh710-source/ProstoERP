using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Net;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Prosto_ERP_API.Mobile
{
    // Deliberately separate from MobileSession: customer tokens never create an employee identity.
    public sealed class CustomerSessionAttribute : AuthorizationFilterAttribute
    {
        public override void OnAuthorization(HttpActionContext context)
        {
            if(context.Response!=null) return;
            if(!MobileApiSupport.TransportAllowed(context.Request)) {
                context.Response=MobileApiSupport.Error(context.Request,HttpStatusCode.Forbidden,"HTTPS_REQUIRED","Use HTTPS.");return;
            }
            var auth=context.Request.Headers.Authorization;
            var hash=auth!=null && string.Equals(auth.Scheme,"Bearer",StringComparison.OrdinalIgnoreCase) ? MobileApiSupport.TokenHash(auth.Parameter) : null;
            try {
                var rows=hash==null ? new List<Dictionary<string,object>>() : CustomerPortalController.Rows(MobileApiSupport.Query("dbo.CustomerApi_Authenticate",MobileApiSupport.P("@TokenHash",SqlDbType.Binary,hash,32)));
                if(rows.Count==0) { context.Response=MobileApiSupport.Error(context.Request,HttpStatusCode.Unauthorized,"SESSION_INVALID","يلزم تسجيل دخول العميل مجددًا.");return; }
                context.Request.Properties["CustomerSession"]=rows[0];
                context.Request.Properties["CustomerTokenHash"]=hash;
            } catch(Exception ex) {
                Trace.TraceError("Customer authentication failed ({0}).",ex.GetType().Name);
                context.Response=MobileApiSupport.Error(context.Request,HttpStatusCode.InternalServerError,"SERVER_ERROR","تعذر التحقق من الجلسة.");
            }
        }
    }

}
