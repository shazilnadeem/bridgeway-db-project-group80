using System.Linq;
using System.Web.Mvc;
using Bridgeway.Web.Services;
using Bridgeway.Web.Models;

namespace Bridgeway.Web.Controllers
{
    public class ClientController : Controller
    {
        // GET: /Client/Dashboard
        public ActionResult Dashboard()
        {
            int userId = AuthService.GetCurrentUserId(HttpContext);
            var clientService = ServiceFactory.CreateClientService();
            var jobService = ServiceFactory.CreateJobService();

            var client = clientService.GetByUserId(userId);
            var jobs = jobService.GetJobsForClient(client.ClientId);

            var model = new ClientDashboardViewModel
            {
                Client = client,
                RecentJobs = jobs
                    .OrderByDescending(j => j.CreatedOn)
                    .Take(5)
                    .ToList()
            };

            return View(model);
        }

        // GET: /Client/CreateJob
        // Show empty form
        public ActionResult CreateJob()
        {
            return View(new CreateJobViewModel());
        }

        // POST: /Client/CreateJob
        // Handle form submit and create the job
        [HttpPost]
        public ActionResult CreateJob(CreateJobViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            int userId = AuthService.GetCurrentUserId(HttpContext);
            var clientService = ServiceFactory.CreateClientService();
            var jobService = ServiceFactory.CreateJobService();

            var client = clientService.GetByUserId(userId);

            var dto = new Bridgeway.Domain.DTOs.JobCreateDto
            {
                ClientId = client.ClientId,
                Title = model.Title,
                Description = model.Description,
                RequiredSkills = model.RequiredSkills,
                JobType = model.JobType,
                Budget = model.Budget
            };

            var createdJob = jobService.CreateJob(dto);

            TempData["Message"] = "Job created with ID " + createdJob.JobId;
            return RedirectToAction("Jobs");
        }

        // GET: /Client/Jobs
        // List all jobs for this client
        public ActionResult Jobs()
        {
            int userId = AuthService.GetCurrentUserId(HttpContext);
            var clientService = ServiceFactory.CreateClientService();
            var jobService = ServiceFactory.CreateJobService();

            var client = clientService.GetByUserId(userId);
            var jobs = jobService.GetJobsForClient(client.ClientId);

            return View(jobs);
        }

        // POST: /Client/RunMatching
        // Trigger matching for a job
        [HttpPost]
        public ActionResult RunMatching(int jobId)
        {
            var jobService = ServiceFactory.CreateJobService();
            jobService.RunMatching(jobId, null); // null => default topN in BLL/SP

            TempData["Message"] = "Matching completed.";
            return RedirectToAction("Jobs");
        }

        // GET: /Client/Candidates
        // Show ranked candidates for a job
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
