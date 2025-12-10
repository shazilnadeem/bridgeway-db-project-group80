using System.Web.Mvc;
using Bridgeway.Web.Models;

namespace Bridgeway.Web.Controllers
{
    public class AccountController : Controller
    {
        // GET: /Account/Login
        public ActionResult Login()
        {
            return View(new LoginViewModel());
        }

        [HttpPost]
        public ActionResult Login(LoginViewModel model)
        {
            // TODO: Shazil: implement authenticate using tbl_User
            return RedirectToAction("Dashboard", "Admin"); // temp
        }

        public ActionResult RegisterEngineer()
        {
            return View(new RegisterEngineerViewModel());
        }

        [HttpPost]
        public ActionResult RegisterEngineer(RegisterEngineerViewModel model)
        {
            // TODO: create user row + engineer profile
            return RedirectToAction("Login");
        }

        public ActionResult RegisterClient()
        {
            return View(new RegisterClientViewModel());
        }

        [HttpPost]
        public ActionResult RegisterClient(RegisterClientViewModel model)
        {
            // TODO: create user row + client profile
            return RedirectToAction("Login");
        }

        public ActionResult Logout()
        {
            // TODO: clear session
            return RedirectToAction("Login");
        }
    }
}
