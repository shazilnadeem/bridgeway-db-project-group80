using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity;
using System.Data.SqlClient;
using Bridgeway.BLL.EF.Entities;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class JobServiceEf : IJobService
    {
        public JobDto CreateJob(JobCreateDto dto)
        {
            using (var db = new BridgewayDbContext())
            {
                // 1. Create the Job
                var job = new Job
                {
                    ClientId = dto.ClientId,
                    JobTitle = dto.Title,
                    JobDescription = dto.Description,
                    Status = "open",
                    CreatedAt = DateTime.UtcNow
                };

                db.Jobs.Add(job);
                db.SaveChanges();

                if (dto.SkillIds != null && dto.SkillIds.Count > 0)
                {
                    foreach (var skillId in dto.SkillIds)
                    {
                        var jobSkill = new JobSkill
                        {
                            JobId = job.JobId,
                            SkillId = skillId,
                            ImportanceLevel = "required", 
                            CreatedAt = DateTime.UtcNow
                        };
                        db.JobSkills.Add(jobSkill);
                    }
                    db.SaveChanges();
                }

                return GetJob(job.JobId);
            }
        }

        public JobDto GetJob(int jobId)
        {
            using (var db = new BridgewayDbContext())
            {
                var entity = db.VwJobsWithClientAndSkills
                               .AsNoTracking()
                               .SingleOrDefault(j => j.JobId == jobId);

                if (entity == null) return null;

                return new JobDto
                {
                    JobId = entity.JobId,
                    ClientId = entity.ClientId,
                    Title = entity.JobTitle,
                    Description = entity.JobDescription,
                    Status = entity.JobStatus,
                    CreatedAt = entity.CreatedAt,
                    UpdatedAt = entity.UpdatedAt,
                    RequiredSkills = entity.RequiredSkills,
                    ClientName = entity.CompanyName,
                    ClientIndustry = entity.Industry
                };
            }
        }

        public IList<JobDto> GetJobsForClient(int clientId)
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

        public IList<JobOpenSummaryDto> GetOpenJobs()
        {
            using (var db = new BridgewayDbContext())
            {
                var data = db.VwOpenJobsWithTopCandidates
                             .AsNoTracking()
                             .ToList();

                return data.Select(x => new JobOpenSummaryDto
                {
                    JobId = x.JobId,
                    Title = x.JobTitle,
                    ClientId = x.ClientId,
                    TopEngineerId = x.TopEngineerId == 0 ? (int?)null : x.TopEngineerId,
                    TopEngineerName = x.TopEngineerName,
                    TopMatchScore = x.TopMatchScore
                }).ToList();
            }
        }

        public void RunMatching(int jobId, int? topN)
        {
            using (var db = new BridgewayDbContext())
            {
                var pJobId = new SqlParameter("@JobId", jobId);
                var pTopN = new SqlParameter("@TopN", (object)topN ?? DBNull.Value);

                db.Database.ExecuteSqlCommand("EXEC sp_MatchEngineersToJob @JobId, @TopN", pJobId, pTopN);
            }
        }

        public IList<EngineerDto> GetRankedCandidates(int jobId)
        {
            using (var db = new BridgewayDbContext())
            {
                var candidates = db.VwJobCandidatesRanked
                                   .AsNoTracking()
                                   .Where(c => c.JobId == jobId)
                                   .OrderByDescending(c => c.MatchScore)
                                   .ThenBy(c => c.CandidateRank)
                                   .ToList();

                return candidates.Select(c => new EngineerDto
                {
                    EngineerId = c.EngineerId,
                    FullName = c.EngineerName,
                    YearsExperience = c.YearsExperience,
                    VetStatus = c.VetStatus,
                    AvgRating = c.AvgRating,
                    TotalRatings = c.RatingCount,
                    MatchScore = c.MatchScore,
                    ApplicationStatus = c.ApplicationStatus,
                    Timezone = c.EngineerTimezone,
                    PortfolioLink = c.PortfolioLink
                }).ToList();
            }
        }
    }
}