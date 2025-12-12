using Microsoft.AspNetCore.Mvc;          // Correct for Controller, ActionResult
using Microsoft.AspNetCore.Mvc.Rendering; // Correct for SelectListItem
using System.Linq;
using System.Collections.Generic;
using Bridgeway.Web.Services;
using Bridgeway.Web.Models;
using Bridgeway.Domain.DTOs;
using Bridgeway.BLL.EF; // Needed for accessing DbContext directly for skills

namespace Bridgeway.Web.Controllers
{
    public class ClientController : Controller
    {
        private void PopulateSkills(CreateJobViewModel model)
        {
            using (var db = new BridgewayDbContext())
            {
                model.AvailableSkills = db.Skills
                    .OrderBy(s => s.SkillName)
                    .Select(s => new SelectListItem
                    {
                        Value = s.SkillId.ToString(),
                        Text = s.SkillName
                    })
                    .ToList();
            }
        }

        // GET: /Client/Dashboard
        public ActionResult Dashboard()
        {
            int userId = AuthService.GetCurrentUserId(HttpContext);
            var clientService = ServiceFactory.CreateClientService();
            var jobService = ServiceFactory.CreateJobService();

            var client = clientService.GetByUserId(userId);
            if (client == null) return RedirectToAction("Login", "Account");

            var jobs = jobService.GetJobsForClient(client.ClientId);

            var model = new ClientDashboardViewModel
            {
                Client = client,
                RecentJobs = jobs.OrderByDescending(j => j.CreatedAt).Take(5).ToList()
            };

            return View(model);
        }

        // GET: /Client/CreateJob
        public ActionResult CreateJob()
        {
            var model = new CreateJobViewModel();
            PopulateSkills(model);
            return View(model);
        }

        // POST: /Client/CreateJob
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CreateJob(CreateJobViewModel model)
        {
            // If invalid, reload skills for re-render
            if (!ModelState.IsValid)
            {
                PopulateSkills(model);
                return View(model);
            }

            int userId = AuthService.GetCurrentUserId(HttpContext);
            var clientService = ServiceFactory.CreateClientService();
            var jobService = ServiceFactory.CreateJobService();

            var client = clientService.GetByUserId(userId);
            if (client == null) return RedirectToAction("Login", "Account");

            var dto = new JobCreateDto
            {
                ClientId = client.ClientId,
                Title = model.Title,
                Description = model.Description,
                SkillIds = model.SelectedSkillIds ?? new List<int>(),
                JobType = model.JobType,
                Budget = model.Budget
            };

            var createdJob = jobService.CreateJob(dto);

            // Optional: auto-run matching immediately after job is created
            // (only if your BLL supports it safely)
            jobService.RunMatching(createdJob.JobId, 10);

            return RedirectToAction("Candidates", new { jobId = createdJob.JobId });
        }


        // POST: /Client/RunMatching
        [HttpPost]
        public ActionResult RunMatching(int jobId)
        {
            var jobService = ServiceFactory.CreateJobService();
            jobService.RunMatching(jobId, null); 
            return RedirectToAction("Candidates", new { jobId = jobId });
        }

        // GET: /Client/Candidates
        public ActionResult Candidates(int jobId)
        {
            var jobService = ServiceFactory.CreateJobService();
            var candidates = jobService.GetRankedCandidates(jobId);

            var vm = new JobCandidatesViewModel
            {
                JobId = jobId,
                Candidates = candidates
            };

            return View(vm);
        }
    }
}