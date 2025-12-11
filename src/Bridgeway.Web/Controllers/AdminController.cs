using System.Web.Mvc;
using Bridgeway.Web.Services;
using Bridgeway.Web.Models;
// using Bridgeway.Domain.Interfaces;  // only if you need interface types later
using Bridgeway.Domain.DTOs;
using System.Collections.Generic;


namespace Bridgeway.Web.Controllers
{
    public class AdminController : Controller
    {
        // GET: /Admin/Dashboard
        public ActionResult Dashboard()
        {
            // These services will be useful once EF/SP guys expose methods:
            var analyticsService = ServiceFactory.CreateAnalyticsService();
            var vettingService = ServiceFactory.CreateVettingService();
            var engineerService = ServiceFactory.CreateEngineerService();

            // TODO: when available, call:
            // var counters = analyticsService.GetBasicCounters();
            // var queue = vettingService.GetVettingQueue();
            // var approvedEngineers = engineerService
            //     .SearchEngineers(new EngineerSearchFilter { VetStatus = "approved" });

            var model = new AdminDashboardViewModel
            {
                // "Ef" or "StoredProcedure" depending on current mode
                CurrentMode = ServiceFactory.CurrentMode.ToString(),

                // For now, use placeholders. Later you can replace with real values.
                TotalEngineers = 0,
                PendingVetting = 0,
                OpenJobs = 0
            };

            return View(model);
        }
        // Other actions (VettingQueue, SubmitVettingReview, EngineerSearch, Analytics,
        // ChangeBackendMode) will be added below this later.
        // GET: /Admin/VettingQueue
        public ActionResult VettingQueue()
        {
            var vettingService = ServiceFactory.CreateVettingService();
            var queue = vettingService.GetVettingQueue();
            // queue is IList<VettingReviewDto> coming from IVettingService / SP view
            return View(queue);
        }

        [HttpPost]
        // POST: /Admin/SubmitVettingReview
        public ActionResult SubmitVettingReview(int EngineerId, string Decision, string Comment)
        {
            // Which admin is taking this decision?
            int adminUserId = AuthService.GetCurrentUserId(HttpContext);

            var vettingService = ServiceFactory.CreateVettingService();

            var dto = new VettingReviewDto
            {
                EngineerId = EngineerId,
                Decision = Decision,
                Comment = Comment,
                ReviewedByUserId = adminUserId
            };

            vettingService.CreateVettingReview(dto);

            TempData["Message"] = "Review submitted.";
            return RedirectToAction("VettingQueue");
        }


        // GET: /Admin/EngineerSearch
        public ActionResult EngineerSearch()
        {
            // Show empty filter and no results initially
            var vm = new EngineerSearchViewModel
            {
                Filter = new EngineerSearchFilter(),
                Results = new List<EngineerDto>()
            };

            return View(vm);
        }


        // POST: /Admin/EngineerSearch
        [HttpPost]
        public ActionResult EngineerSearch(EngineerSearchViewModel model)
        {
            var engineerService = ServiceFactory.CreateEngineerService();

            // Call into EF/SP via the service using the filter
            var results = engineerService.SearchEngineers(model.Filter);

            // Attach results back to the model so the view can render them
            model.Results = results;

            return View(model);
        }


        // GET: /Admin/Analytics
        public ActionResult Analytics(int? year)
        {
            // If year is null (no query parameter), default to current UTC year
            int effectiveYear = year ?? System.DateTime.UtcNow.Year;

            var analyticsService = ServiceFactory.CreateAnalyticsService();
            var stats = analyticsService.GetMonthlyPlatformStats(effectiveYear);

            var vm = new AnalyticsViewModel
            {
                Year = effectiveYear,
                MonthlyStats = stats
            };

            return View(vm);
        }

        [HttpPost]
        public ActionResult ChangeBackendMode(string mode)
        {
            if (mode == "Ef")
            {
                ServiceFactory.CurrentMode = BllMode.Ef;
            }
            else if (mode == "Sp")
            {
                ServiceFactory.CurrentMode = BllMode.StoredProcedure;
            }

            // After switching, go back to the dashboard
            return RedirectToAction("Dashboard");
        }


    }
}
