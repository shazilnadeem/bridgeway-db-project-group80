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
        public IList<VettingQueueItemDto> GetVettingQueue()
        {
            var list = new List<VettingQueueItemDto>();

            // Only show engineers who are still pending
            string sql = "SELECT * FROM vw_VettingQueue WHERE current_vet_status = 'pending' ORDER BY last_review_date ASC";

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
                        PriorityLevel = reader["priority_level"]?.ToString() 
                    });
                }
            }
            return list;
        }

        public void CreateVettingReview(VettingReviewDto review)
        {
            // 1. Create the Review Record
            var parameters = new[]
            {
                new SqlParameter("@EngineerId", review.EngineerId),
                new SqlParameter("@ReviewerId", review.ReviewerUserId), 
                new SqlParameter("@ReviewStatus", (object?)review.Decision ?? DBNull.Value), 
                new SqlParameter("@SkillsVerified", review.SkillsVerified),
                new SqlParameter("@ExperienceVerified", review.ExperienceVerified),
                new SqlParameter("@PortfolioVerified", review.PortfolioVerified),
                new SqlParameter("@ReviewNotes", (object?)review.ReviewNotes ?? DBNull.Value),
                new SqlParameter("@RejectionReason", (object?)review.RejectionReason ?? DBNull.Value)
            };

            SqlHelper.ExecuteNonQuery("sp_CreateVettingReview", parameters);

            // 2. FORCE UPDATE the Engineer Profile Status (The Fix)
            string updateSql = @"
                UPDATE tbl_Engineer_Profile 
                SET vet_status = @NewStatus 
                WHERE engineer_id = @EngId";

            SqlHelper.ExecuteNonQueryText(updateSql, 
                new SqlParameter("@NewStatus", review.Decision), // 'approved' or 'rejected'
                new SqlParameter("@EngId", review.EngineerId)
            );
        }
    }
}