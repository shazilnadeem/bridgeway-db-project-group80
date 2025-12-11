using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity;
using Bridgeway.BLL.EF.Entities;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class ClientServiceEf : IClientService
    {
        public ClientDto GetById(int clientId)
        {
            using (var db = new BridgewayDbContext())
            {
                // Eager load User to get FullName (ContactName) and Email
                var entity = db.ClientProfiles
                               .Include(c => c.User)
                               .AsNoTracking()
                               .SingleOrDefault(c => c.ClientId == clientId);

                if (entity == null) return null;

                return new ClientDto
                {
                    ClientId = entity.ClientId,
                    UserId = entity.ClientId, // 1:1 relationship
                    CompanyName = entity.CompanyName,
                    Industry = entity.Industry,
                    ContactName = entity.User?.FullName,
                    Email = entity.User?.Email
                };
            }
        }

        public ClientDto GetByUserId(int userId)
        {
            // Since ClientId is 1:1 with UserId, we strictly reuse GetById
            return GetById(userId);
        }

        public void RegisterClient(int userId)
        {
            using (var db = new BridgewayDbContext())
            {
                if (db.ClientProfiles.Any(c => c.ClientId == userId))
                {
                    return; // Profile already exists
                }

                var profile = new ClientProfile
                {
                    ClientId = userId,
                    // Default values as allowed by schema
                    CompanyName = "New Company", 
                    Industry = "N/A",
                    CreatedAt = DateTime.UtcNow
                };

                db.ClientProfiles.Add(profile);
                db.SaveChanges();
            }
        }

        public IList<JobDto> GetClientJobs(int clientId)
        {
            using (var db = new BridgewayDbContext())
            {
                // Query the view that joins Job + Client + Skills
                var jobs = db.VwJobsWithClientAndSkills
                             .AsNoTracking()
                             .Where(j => j.ClientId == clientId)
                             .OrderByDescending(j => j.CreatedAt)
                             .ToList();

                return jobs.Select(j => new JobDto
                {
                    JobId = j.JobId,
                    ClientId = j.ClientId,
                    Title = j.JobTitle,             // Maps DB 'job_title' to DTO 'Title'
                    Description = j.JobDescription,
                    Status = j.JobStatus,
                    CreatedAt = j.CreatedAt,
                    UpdatedAt = j.UpdatedAt,        // Mapped as per your latest update
                    RequiredSkills = j.RequiredSkills,
                    ClientName = j.CompanyName,
                    ClientIndustry = j.Industry
                }).ToList();
            }
        }
    }
}