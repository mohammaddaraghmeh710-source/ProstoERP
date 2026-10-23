using System.Web.Mvc;
using Prosto_ERP_API.Documentation;

namespace Prosto_ERP_API.Controllers
{
    public sealed class SwaggerController : Controller
    {
        [HttpGet]
        public ActionResult Index(string module = "mobile")
        {
            return View(SwaggerModules.Find(module));
        }
    }
}
