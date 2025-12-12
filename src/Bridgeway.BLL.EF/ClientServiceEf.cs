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
                var entity = db.ClientProfiles
                               .Include(c => c.User)
                               .AsNoTracking()
                               .SingleOrDefault(c => c.ClientId == clientId);

                if (entity == null) return null;

                return new ClientDto
                {
                    ClientId = entity.ClientId,
                    UserId = entity.ClientId, 
                    CompanyName = entity.CompanyName,
                    Industry = entity.Industry,
                    ContactName = entity.User?.FullName,
                    Email = entity.User?.Email
                };
            }
        }

        public ClientDto GetByUserId(int userId)
        {
            return GetById(userId);
        }

        public void RegisterClient(int userId)
        {
            using (var db = new BridgewayDbContext())
            {
                if (db.ClientProfiles.Any(c => c.ClientId == userId))
                {
                    return;
                }

                var profile = new ClientProfile
                {
                    ClientId = userId,
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
                var jobs = db.VwJobsWithClientAndSkills
                             .AsNoTracking()
                             .Where(j => j.ClientId == clientId)
                             .OrderByDescending(j => j.CreatedAt)
                             .ToList();

                return jobs.Select(j => new JobDto
                {
                    JobId = j.JobId,
                    ClientId = j.ClientId,
                    Title = j.JobTitle,
                    Description = j.JobDescription,
                    Status = j.JobStatus,
                    CreatedAt = j.CreatedAt,
                    UpdatedAt = j.UpdatedAt,
                    RequiredSkills = j.RequiredSkills,
                    ClientName = j.CompanyName,
                    ClientIndustry = j.Industry
                }).ToList();
            }
        }
    }
}