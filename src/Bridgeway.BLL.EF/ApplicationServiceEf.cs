using System;
using System.Collections.Generic;
using System.Linq;
using Bridgeway.BLL.EF.Entities;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class ApplicationServiceEf : IApplicationService
    {
        public void ApplyToJob(int engineerId, int jobId)
        {
            using (var db = new BridgewayDbContext())
            {
                if (db.JobApplications.Any(a => a.EngineerId == engineerId && a.JobId == jobId))
                {
                    throw new InvalidOperationException("Engineer has already applied to this job.");
                }

                var application = new JobApplication
                {
                    EngineerId = engineerId,
                    JobId = jobId,
                    Status = "pending",
                    CreatedAt = DateTime.UtcNow
                };

                db.JobApplications.Add(application);
                db.SaveChanges();
            }
        }

        public void UpdateApplicationStatus(int engineerId, int jobId, string newStatus, int updatedByUserId)
        {
            using (var db = new BridgewayDbContext())
            {
                var app = db.JobApplications.Find(engineerId, jobId);

                if (app == null)
                {
                    throw new KeyNotFoundException("Application not found.");
                }

                var validStatuses = new[] { "pending", "shortlisted", "accepted", "rejected" };
                if (!validStatuses.Contains(newStatus.ToLower()))
                {
                    throw new ArgumentException("Invalid application status.");
                }

                app.Status = newStatus;
                app.UpdatedAt = DateTime.UtcNow;

                db.SaveChanges();
            }
        }

        public IList<ApplicationDto> GetApplicationsForEngineer(int engineerId)
        {
            using (var db = new BridgewayDbContext())
            {
                var query = from ja in db.JobApplications
                            join j in db.Jobs on ja.JobId equals j.JobId
                            join c in db.ClientProfiles on j.ClientId equals c.ClientId
                            where ja.EngineerId == engineerId
                            orderby ja.CreatedAt descending
                            select new
                            {
                                ja.EngineerId,
                                ja.JobId,
                                ja.Status,
                                ja.MatchScore,
                                ja.CreatedAt,
                                ja.UpdatedAt,
                                j.JobTitle,
                                c.CompanyName
                            };

                return query.ToList().Select(x => new ApplicationDto
                {
                    EngineerId = x.EngineerId,
                    JobId = x.JobId,
                    JobTitle = x.JobTitle,
                    CompanyName = x.CompanyName,
                    Status = x.Status,
                    MatchScore = x.MatchScore,
                    CreatedAt = x.CreatedAt,
                    UpdatedAt = x.UpdatedAt
                }).ToList();
            }
        }

        public IList<ApplicationDto> GetApplicationsForJob(int jobId)
        {
            using (var db = new BridgewayDbContext())
            {
                var query = from ja in db.JobApplications
                            join u in db.Users on ja.EngineerId equals u.UserId
                            where ja.JobId == jobId
                            orderby ja.MatchScore descending
                            select new
                            {
                                ja.EngineerId,
                                ja.JobId,
                                ja.Status,
                                ja.MatchScore,
                                ja.CreatedAt,
                                ja.UpdatedAt,
                                EngineerName = u.FullName
                            };

                return query.ToList().Select(x => new ApplicationDto
                {
                    EngineerId = x.EngineerId,
                    JobId = x.JobId,
                    EngineerName = x.EngineerName,
                    Status = x.Status,
                    MatchScore = x.MatchScore,
                    CreatedAt = x.CreatedAt,
                    UpdatedAt = x.UpdatedAt
                }).ToList();
            }
        }
    }
}