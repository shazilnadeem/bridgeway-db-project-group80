using Microsoft.AspNetCore.Mvc;
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
            // 1. Initialize Services
            var vettingService = ServiceFactory.CreateVettingService();
            var jobService = ServiceFactory.CreateJobService();
            // Note: We don't have a simple "GetTotalEngineers" method yet, so we'll leave that as 0 for now
            // or you can add a method to IEngineerService to fetching the count.

            // 2. Fetch Real Data
            var pendingVettingCount = vettingService.GetVettingQueue().Count;
            var openJobsCount = jobService.GetOpenJobs().Count;

            // 3. Pass Data to Model
            var model = new AdminDashboardViewModel
            {
                CurrentMode = ServiceFactory.CurrentMode.ToString(),
                
                TotalEngineers = 0, // Placeholder: You need to add GetTotalCount() to IEngineerService to fix this
                
                PendingVetting = pendingVettingCount, // REAL DATA
                OpenJobs = openJobsCount              // REAL DATA
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
                ReviewNotes = Comment,       // Changed from Comment = Comment
                ReviewerUserId = adminUserId // Changed from ReviewedByUserId = adminUserId
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
