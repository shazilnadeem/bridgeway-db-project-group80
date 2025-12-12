using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class JobServiceSp : IJobService
    {
        // ------------------------------------------------------------
        // 1. Create Job (sp_CreateJob)
        // ------------------------------------------------------------
        public JobDto CreateJob(JobCreateDto dto)
        {
            var parameters = new[]
            {
                new SqlParameter("@ClientId", dto.ClientId),
                new SqlParameter("@JobTitle", dto.Title),
                new SqlParameter("@JobDescription", (object?)dto.Description ?? DBNull.Value),
                new SqlParameter("@Status", "open")
            };

            JobDto createdJob = null;

            using (var reader = SqlHelper.ExecuteReader("sp_CreateJob", parameters))
            {
                if (reader.Read())
                {
                    int jobId = Convert.ToInt32(reader["job_id"]);
                    createdJob = GetJob(jobId);
                }
            }

            return createdJob;
        }

        // ------------------------------------------------------------
        // 2. Get Job by id (vw_JobWithClientAndSkills)
        // ------------------------------------------------------------
        public JobDto GetJob(int jobId)
        {
            string sql = @"
                SELECT *
                FROM vw_JobWithClientAndSkills
                WHERE job_id = @JobId";

            using (var reader = SqlHelper.ExecuteReaderText(sql,
                new SqlParameter("@JobId", jobId)))
            {
                if (!reader.Read())
                    return null;

                return MapJob(reader);
            }
        }

        // ------------------------------------------------------------
        // 3. Get jobs for a client (vw_JobWithClientAndSkills)
        // ------------------------------------------------------------
        public IList<JobDto> GetJobsForClient(int clientId)
        {
            IList<JobDto> list = new List<JobDto>();

            string sql = @"
                SELECT *
                FROM vw_JobWithClientAndSkills
                WHERE client_id = @ClientId
                ORDER BY created_at DESC";

            using (var reader = SqlHelper.ExecuteReaderText(sql,
                new SqlParameter("@ClientId", clientId)))
            {
                while (reader.Read())
                {
                    list.Add(MapJob(reader));
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // 4. Get all open jobs (vw_OpenJobsWithTopCandidate)
        // ------------------------------------------------------------
        public IList<JobOpenSummaryDto> GetOpenJobs()
        {
            IList<JobOpenSummaryDto> list = new List<JobOpenSummaryDto>();

            string sql = @"SELECT * FROM vw_OpenJobsWithTopCandidate";

            using (var reader = SqlHelper.ExecuteReaderText(sql))
            {
                while (reader.Read())
                {
                    list.Add(new JobOpenSummaryDto
                    {
                        JobId            = Convert.ToInt32(reader["job_id"]),
                        Title            = reader["job_title"].ToString(),
                        ClientId         = Convert.ToInt32(reader["client_id"]),
                        TopEngineerId    = reader["top_engineer_id"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["top_engineer_id"]),
                        TopEngineerName  = reader["top_engineer_name"]?.ToString(),
                        TopMatchScore    = reader["top_match_score"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(reader["top_match_score"])
                    });
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // 5. Run Matching (sp_MatchEngineersToJob)
        // ------------------------------------------------------------
        public void RunMatching(int jobId, int? topN)
        {
            var parameters = new List<SqlParameter>
            {
                new SqlParameter("@JobId", jobId)
            };

            if (topN.HasValue)
                parameters.Add(new SqlParameter("@TopN", topN.Value));
            else
                parameters.Add(new SqlParameter("@TopN", DBNull.Value));

            SqlHelper.ExecuteNonQuery("sp_MatchEngineersToJob", parameters.ToArray());
        }

        // ------------------------------------------------------------
        // 6. Get ranked candidates (vw_JobCandidatesRanked)
        // ------------------------------------------------------------
        public IList<EngineerDto> GetRankedCandidates(int jobId)
        {
            IList<EngineerDto> list = new List<EngineerDto>();

            string sql = @"
                SELECT *
                FROM vw_JobCandidatesRanked
                WHERE job_id = @JobId
                ORDER BY match_score DESC, candidate_rank ASC";

            using (var reader = SqlHelper.ExecuteReaderText(sql,
                new SqlParameter("@JobId", jobId)))
            {
                while (reader.Read())
                {
                    list.Add(new EngineerDto
                    {
                        EngineerId        = Convert.ToInt32(reader["engineer_id"]),
                        FullName          = reader["engineer_name"].ToString(),
                        YearsExperience   = Convert.ToInt32(reader["years_experience"]),
                        VetStatus         = reader["vet_status"].ToString(),
                        AvgRating         = reader["avg_rating"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["avg_rating"]),
                        TotalRatings       = reader["rating_count"] == DBNull.Value ? 0 : Convert.ToInt32(reader["rating_count"]),
                        PortfolioLink     = reader["portfolio_link"]?.ToString(),
                        MatchScore        = reader["match_score"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["match_score"]),
                        ApplicationStatus = reader["application_status"]?.ToString(),
                        Timezone          = reader["engineer_timezone"]?.ToString()
                    });
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // HELPER: Map job (vw_JobWithClientAndSkills)
        // ------------------------------------------------------------
        private JobDto MapJob(SqlDataReader reader)
        {
            return new JobDto
            {
                JobId          = Convert.ToInt32(reader["job_id"]),
                Title          = reader["job_title"].ToString(),
                Description    = reader["job_description"]?.ToString(),
                Status         = reader["job_status"].ToString(),
                CreatedAt      = Convert.ToDateTime(reader["created_at"]),
                UpdatedAt      = reader["updated_at"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["updated_at"]),
                RequiredSkills = reader["required_skills"]?.ToString(),

                ClientId       = Convert.ToInt32(reader["client_id"]),
                ClientName     = reader["company_name"]?.ToString(),
                ClientIndustry = reader["industry"]?.ToString()
            };
        }
    }
}
