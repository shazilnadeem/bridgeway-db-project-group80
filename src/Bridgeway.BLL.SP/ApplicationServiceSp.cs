using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class ApplicationServiceSp : IApplicationService
    {
        // ------------------------------------------------------------
        // 1. Apply to Job (sp_ApplyToJob)
        // ------------------------------------------------------------
        public void ApplyToJob(int engineerId, int jobId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EngineerId", engineerId),
                new SqlParameter("@JobId", jobId)
            };

            SqlHelper.ExecuteNonQuery("sp_ApplyToJob", parameters);
        }

        // ------------------------------------------------------------
        // 2. Update job application status (sp_UpdateApplicationStatus)
        // ------------------------------------------------------------
        public void UpdateApplicationStatus(int engineerId, int jobId, string newStatus, int updatedByUserId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EngineerId", engineerId),
                new SqlParameter("@JobId", jobId),
                new SqlParameter("@NewStatus", newStatus),
                new SqlParameter("@UpdatedBy", updatedByUserId)
            };

            SqlHelper.ExecuteNonQuery("sp_UpdateApplicationStatus", parameters);
        }

        // ------------------------------------------------------------
        // 3. Get applications for an engineer
        //    (Custom SELECT — no SP exists for this in phase 2 SQL)
        // ------------------------------------------------------------
        public IList<ApplicationDto> GetApplicationsForEngineer(int engineerId)
        {
            var list = new List<ApplicationDto>();

            string sql = @"
                SELECT 
                    ja.engineer_id,
                    ja.job_id,
                    ja.status,
                    ja.match_score,
                    ja.created_at,
                    ja.updated_at,
                    j.job_title
                FROM tbl_Job_Application ja
                JOIN tbl_Job j ON ja.job_id = j.job_id
                WHERE ja.engineer_id = @EngineerId
                ORDER BY ja.created_at DESC";

            using (var reader = SqlHelper.ExecuteReaderText(sql,
                new SqlParameter("@EngineerId", engineerId)))
            {
                while (reader.Read())
                {
                    list.Add(MapApplication(reader));
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // 4. Get applications for a job
        // ------------------------------------------------------------
        public IList<ApplicationDto> GetApplicationsForJob(int jobId)
        {
            var list = new List<ApplicationDto>();

            string sql = @"
                SELECT 
                    ja.engineer_id,
                    ja.job_id,
                    ja.status,
                    ja.match_score,
                    ja.created_at,
                    ja.updated_at,
                    u.full_name AS engineer_name
                FROM tbl_Job_Application ja
                JOIN tbl_Engineer_Profile ep ON ja.engineer_id = ep.engineer_id
                JOIN tbl_User u ON ep.engineer_id = u.user_id
                WHERE ja.job_id = @JobId
                ORDER BY ja.match_score DESC";

            using (var reader = SqlHelper.ExecuteReaderText(sql,
                new SqlParameter("@JobId", jobId)))
            {
                while (reader.Read())
                {
                    list.Add(MapApplicationWithEngineer(reader));
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // HELPER: Map application row
        // ------------------------------------------------------------
        private ApplicationDto MapApplication(SqlDataReader reader)
        {
            return new ApplicationDto
            {
                EngineerId   = Convert.ToInt32(reader["engineer_id"]),
                JobId        = Convert.ToInt32(reader["job_id"]),
                JobTitle     = reader["job_title"].ToString(),
                Status       = reader["status"].ToString(),
                MatchScore   = reader["match_score"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["match_score"]),
                CreatedAt    = Convert.ToDateTime(reader["created_at"]),
                UpdatedAt    = reader["updated_at"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["updated_at"])
            };
        }

        private ApplicationDto MapApplicationWithEngineer(SqlDataReader reader)
        {
            return new ApplicationDto
            {
                EngineerId   = Convert.ToInt32(reader["engineer_id"]),
                JobId        = Convert.ToInt32(reader["job_id"]),
                EngineerName = reader["engineer_name"].ToString(),
                Status       = reader["status"].ToString(),
                MatchScore   = reader["match_score"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["match_score"]),
                CreatedAt    = Convert.ToDateTime(reader["created_at"]),
                UpdatedAt    = reader["updated_at"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["updated_at"])
            };
        }
    }
}
