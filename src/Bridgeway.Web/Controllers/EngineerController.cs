using System.Linq;      //so we can use Take and ToList()
using Microsoft.AspNetCore.Mvc;
using Bridgeway.Web.Models;     // for EngineerDashboardViewModel
using Bridgeway.Web.Services;   // AuthService and ServiceFactory
using Bridgeway.Domain.DTOs;


namespace Bridgeway.Web.Controllers
{
    public class EngineerController : Controller
    {
        public ActionResult Dashboard()
        {
            // Find which user is currently logged in.
            int userId = AuthService.GetCurrentUserId(HttpContext);

            //  Ask the ServiceFactory for the services we need.
            // (Under the hood this will be EF or Stored Procedures.)
            var engineerService = ServiceFactory.CreateEngineerService();
            var applicationService = ServiceFactory.CreateApplicationService();

            // Get the engineer profile for this logged-in user.
            var engineerProfile = engineerService.GetCurrentEngineerProfile(userId);

            // Get all applications made by this engineer.
            var applications = applicationService.GetApplicationsForEngineer(engineerProfile.EngineerId);

            var currentJob = applications.FirstOrDefault(a => 
            string.Equals(a.Status, "accepted", System.StringComparison.OrdinalIgnoreCase));

            // Build a view model to pass to the Razor view.
            var model = new EngineerDashboardViewModel
            {
                Engineer = engineerProfile,
                // Only show top 5 on the dashboard
                RecentApplications = applications.Take(5).ToList(),
                CurrentJob = currentJob
            };

            // Render the Dashboard view with this model.
            return View(model);
        }

        // GET: /Engineer/Profile
        public ActionResult Profile()
        {
            int userId = AuthService.GetCurrentUserId(HttpContext);
            var engineerService = ServiceFactory.CreateEngineerService();

            var engineerDto = engineerService.GetCurrentEngineerProfile(userId);

            var model = new EngineerProfileViewModel
            {
                EngineerId = engineerDto.EngineerId,
                FullName = engineerDto.FullName,
                YearsExperience = engineerDto.YearsExperience,
                Timezone = engineerDto.Timezone,
                AvailabilityStatus = engineerDto.AvailabilityStatus,
                SkillsList = engineerDto.SkillsList
            };

            return View(model);
        }

        // POST: /Engineer/Profile
        [HttpPost]
        public ActionResult Profile(EngineerProfileViewModel model)
        {
            if (!ModelState.IsValid)
            {
                // If validation fails, redisplay the form with entered values
                return View(model);
            }

            var engineerService = ServiceFactory.CreateEngineerService();

            var dto = new EngineerDto
            {
                EngineerId = model.EngineerId,
                FullName = model.FullName,
                YearsExperience = model.YearsExperience,
                Timezone = model.Timezone,
                AvailabilityStatus = model.AvailabilityStatus,
                SkillsList = model.SkillsList
            };

            engineerService.UpdateEngineerProfile(dto);
            TempData["Message"] = "Profile updated successfully.";

            // Redirect so refresh doesn't resubmit the form
            return RedirectToAction("Profile");
        }
        public ActionResult MyApplications()
        {
            int userId = AuthService.GetCurrentUserId(HttpContext);
            var engineerService = ServiceFactory.CreateEngineerService();
            var applicationService = ServiceFactory.CreateApplicationService();

            var engineer = engineerService.GetCurrentEngineerProfile(userId);
            var applications = applicationService.GetApplicationsForEngineer(engineer.EngineerId);

            // Directly pass the list of ApplicationDto objects to the view
            return View(applications);
        }
    }
}
