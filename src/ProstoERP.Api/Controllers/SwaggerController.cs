using System.Web.Mvc;

namespace Prosto_ERP_API.Controllers
{
    public sealed class SwaggerController : Controller
    {
        [HttpGet]
        public ActionResult Index(string module = "mobile")
        {
            ViewData["SwaggerModule"] = module == "all" ? "All APIs" : "Mobile API";
            return View();
        }
    }
}
