using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Http;
using System.Web.Http.Routing;
using ProstoERP.Application.Abstractions;

namespace Prosto_ERP_API.Composition
{
    internal sealed class ApiWorkflowContext : IMobileWorkflowContext
    {
        private readonly ApiController controller;
        public DateTime ReceivedUtc { get; private set; }
        internal ApiWorkflowContext(ApiController controller, DateTime receivedUtc)
        {
            this.controller = controller;
            ReceivedUtc = receivedUtc;
        }
        public bool IsModelValid => controller.ModelState.IsValid;
        public int Actor => Convert.ToInt32(((Dictionary<string, object>)controller.Request.Properties["MobileSession"])["UserID"]);
        public Dictionary<string, object> CustomerSession => (Dictionary<string, object>)controller.Request.Properties["CustomerSession"];
        public object CustomerTokenHash => controller.Request.Properties["CustomerTokenHash"];
        public string Link(string route, object values) { return controller.Url.Link(route, values); }
        public string ClientAddress
        {
            get
            {
                string address = null;
                object context;
                if (controller.Request.Properties.TryGetValue("MS_HttpContext", out context) && context is HttpContextBase)
                    address = ((HttpContextBase)context).Request.UserHostAddress;
                if (string.IsNullOrWhiteSpace(address) && HttpContext.Current != null)
                    address = HttpContext.Current.Request.UserHostAddress;
                return address;
            }
        }
    }
}
