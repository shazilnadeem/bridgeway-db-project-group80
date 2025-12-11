//*implemented by areeba:

using System;
using System.Web.Mvc;
using Bridgeway.Web.Models;
using Bridgeway.Web.Services;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Controllers
{
    public class AdminController : Controller
    {
        // -----------------------
        // ADMIN DASHBOARD (GET)
        // -----------------------
        public ActionResult Dashboard()
        {
            // Empty for now — UI design comes later
            var model = new AdminDashboardViewModel();
            return View(model);
        }

        // -----------------------
        // VETTING QUEUE (GET)
        // -----------------------
        public ActionResult VettingQueue()
        {
            // Empty for now — backend comes later
            return View();
        }

        // -----------------------
        // SUBMIT VETTING REVIEW (POST)
        // -----------------------
        [HttpPost]
        public ActionResult SubmitVettingReview(int EngineerId, string Decision, string Comment)
        {
            // Logic will be added later
            return RedirectToAction("VettingQueue");
        }

        // -----------------------
        // ENGINEER SEARCH (GET)
        // -----------------------
        public ActionResult EngineerSearch()
        {
            var model = new EngineerSearchViewModel
            {
                Filter = new EngineerSearchFilter(),
                Results = new System.Collections.Generic.List<EngineerDto>()
            };

            return View(model);
        }

        // -----------------------
        // ENGINEER SEARCH (POST)
        // -----------------------
        [HttpPost]
        public ActionResult EngineerSearch(EngineerSearchViewModel model)
        {
            // Backend search logic will be added later
            model.Results = new System.Collections.Generic.List<EngineerDto>();
            return View(model);
        }

        // -----------------------
        // ANALYTICS PAGE (GET)
        // -----------------------
        public ActionResult Analytics(int? year)
        {
            var model = new AnalyticsViewModel
            {
                Year = year ?? DateTime.UtcNow.Year,
                MonthlyStats = new System.Collections.Generic.List<MonthlyStatsDto>()
            };

            return View(model);
        }

        // -----------------------
        // CHANGE BACKEND MODE (POST)
        // -----------------------
        [HttpPost]
        public ActionResult ChangeBackendMode(string mode)
        {
            // Will be implemented later
            return RedirectToAction("Dashboard");
        }
    }
}
