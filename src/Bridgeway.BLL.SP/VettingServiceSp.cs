using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class VettingServiceSp : IVettingService
    {
        // ------------------------------------------------------------
        // 1. Get Vetting Queue (vw_VettingQueue)
        // ------------------------------------------------------------
        public IList<VettingQueueItemDto> GetVettingQueue()
        {
            var list = new List<VettingQueueItemDto>();

            string sql = "SELECT * FROM vw_VettingQueue ORDER BY last_review_date ASC";

            using (var reader = SqlHelper.ExecuteReaderText(sql))
            {
                while (reader.Read())
                {
                    list.Add(new VettingQueueItemDto
                    {
                        EngineerId    = Convert.ToInt32(reader["engineer_id"]),
                        EngineerName  = reader["engineer_name"]?.ToString(),
                        Email         = reader["email"]?.ToString(),
                        CurrentStatus = reader["current_vet_status"]?.ToString(),
                        VettingScore  = reader["vetting_score"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["vetting_score"]),
                        NumReviews    = Convert.ToInt32(reader["num_reviews"]),
                        // FIXED: Read as String, do not Convert.ToInt32
                        PriorityLevel = reader["priority_level"]?.ToString() 
                    });
                }
            }

            return list;
        }

        // ------------------------------------------------------------
        // 2. Create Vetting Review (sp_CreateVettingReview)
        // ------------------------------------------------------------
        public void CreateVettingReview(VettingReviewDto review)
        {
            var parameters = new[]
            {
                new SqlParameter("@EngineerId", review.EngineerId),
                new SqlParameter("@ReviewerId", review.ReviewerUserId), // Matches SQL param name
                new SqlParameter("@ReviewStatus", (object?)review.Decision ?? DBNull.Value), // Map Decision -> ReviewStatus
                new SqlParameter("@SkillsVerified", review.SkillsVerified),
                new SqlParameter("@ExperienceVerified", review.ExperienceVerified),
                new SqlParameter("@PortfolioVerified", review.PortfolioVerified),
                new SqlParameter("@ReviewNotes", (object?)review.ReviewNotes ?? DBNull.Value),
                new SqlParameter("@RejectionReason", (object?)review.RejectionReason ?? DBNull.Value)
            };

            SqlHelper.ExecuteNonQuery("sp_CreateVettingReview", parameters);
        }
    }
}