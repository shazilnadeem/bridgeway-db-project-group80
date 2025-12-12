using Microsoft.AspNetCore.Mvc;

namespace Bridgeway.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        public IActionResult Error()
        {
            return Content("An error occurred. Please check the console logs for details.");
        }
    }
}