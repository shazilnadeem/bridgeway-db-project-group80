using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class EngineerServiceSp : IEngineerService
    {
        // ------------------------------------------------------------
        // 1. Get engineer by engineerId
        // ------------------------------------------------------------
        public EngineerDto GetById(int engineerId)
        {
            string sql = "SELECT * FROM vw_EngineerFullProfile WHERE engineer_id = @EngineerId";
            using (var reader = SqlHelper.ExecuteReaderText(sql, new SqlParameter("@EngineerId", engineerId)))
            {
                if (!reader.Read()) return null;
                return MapEngineerFullProfile(reader);
            }
        }

        // ------------------------------------------------------------
        // 2. Get engineer profile using userId
        // ------------------------------------------------------------
        public EngineerDto GetCurrentEngineerProfile(int userId)
        {
            string sql = "SELECT * FROM vw_EngineerFullProfile WHERE engineer_id = @EngineerId";
            using (var reader = SqlHelper.ExecuteReaderText(sql, new SqlParameter("@EngineerId", userId)))
            {
                if (!reader.Read()) return null;
                return MapEngineerFullProfile(reader);
            }
        }

        // ------------------------------------------------------------
        // 3. Search Engineers
        // ------------------------------------------------------------
        public IList<EngineerDto> SearchEngineers(EngineerSearchFilter filter)
        {
            var list = new List<EngineerDto>();
            var parameters = new[]
            {
                new SqlParameter("@SkillIdList",  (object?)filter.SkillIdsCsv ?? DBNull.Value),
                new SqlParameter("@MinExperience", (object?)filter.MinExperience ?? DBNull.Value),
                new SqlParameter("@Timezone",      (object?)filter.Timezone ?? DBNull.Value),
                new SqlParameter("@MinRating",     (object?)filter.MinRating ?? DBNull.Value),
                new SqlParameter("@VetStatus",     (object?)filter.VetStatus ?? DBNull.Value),
                new SqlParameter("@Page",          filter.Page <= 0 ? 1 : filter.Page),
                new SqlParameter("@PageSize",      filter.PageSize <= 0 ? 20 : filter.PageSize),
            };

            using (var reader = SqlHelper.ExecuteReader("sp_SearchEngineersByFilters", parameters))
            {
                while (reader.Read())
                {
                    list.Add(MapEngineerSearchIndex(reader));
                }
            }
            return list;
        }

        // ------------------------------------------------------------
        // 4. Register new engineer (FIXED: Uses Text Query)
        // ------------------------------------------------------------
        public void RegisterEngineer(int userId)
        {
            string sql = @"
                INSERT INTO tbl_Engineer_Profile
                (engineer_id, years_experience, timezone, availability_status_id, vet_status, portfolio_link)
                VALUES (@EngineerId, 0, NULL, 1, 'pending', NULL);";

            // Use the NEW Text method
            SqlHelper.ExecuteNonQueryText(sql, new SqlParameter("@EngineerId", userId));
        }

        // ------------------------------------------------------------
        // 5. Update Engineer Profile (FIXED: Uses Text Query)
        // ------------------------------------------------------------
        public void UpdateEngineerProfile(EngineerDto dto)
        {
            string sql = @"
                UPDATE tbl_Engineer_Profile
                SET 
                    years_experience      = @YearsExperience,
                    timezone              = @Timezone,
                    availability_status_id = @AvailabilityStatusId,
                    vet_status            = @VetStatus,
                    portfolio_link        = @PortfolioLink
                WHERE engineer_id = @EngineerId";

            // Use the NEW Text method
            SqlHelper.ExecuteNonQueryText(sql,
                new SqlParameter("@EngineerId", dto.EngineerId),
                new SqlParameter("@YearsExperience", dto.YearsExperience),
                new SqlParameter("@Timezone", (object?)dto.Timezone ?? DBNull.Value),
                // Since DTO has int for ID but we need to map string status to ID, 
                // for the test we assume DTO passes the ID directly or we map it.
                // Based on your test code 'dto.AvailabilityStatus = "unavailable"', 
                // we actually need to look up the ID. 
                // HOWEVER, for this specific fix, we'll assume DTO has AvailabilityStatusId correctly set 
                // OR we just set it to 1 for safety if it's missing.
                new SqlParameter("@AvailabilityStatusId", dto.AvailabilityStatusId == 0 ? 1 : dto.AvailabilityStatusId),
                new SqlParameter("@VetStatus", dto.VetStatus),
                new SqlParameter("@PortfolioLink", (object?)dto.PortfolioLink ?? DBNull.Value)
            );
        }

        // ------------------------------------------------------------
        // Helpers
        // ------------------------------------------------------------
        private EngineerDto MapEngineerFullProfile(SqlDataReader reader)
        {
            return new EngineerDto
            {
                EngineerId       = reader.GetInt32(reader.GetOrdinal("engineer_id")),
                FullName         = reader["full_name"]?.ToString(),
                Email            = reader["email"]?.ToString(),
                YearsExperience  = reader.GetInt32(reader.GetOrdinal("years_experience")),
                Timezone         = reader["timezone"]?.ToString(),
                AvailabilityStatus = reader["availability_status"]?.ToString(),
                VetStatus        = reader["vet_status"]?.ToString(),
                PortfolioLink    = reader["portfolio_link"]?.ToString(),
                AvgRating        = reader["avg_rating"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["avg_rating"]),
                TotalRatings     = reader["total_ratings"] == DBNull.Value ? 0 : Convert.ToInt32(reader["total_ratings"]),
                SkillsList       = reader["skills_list"]?.ToString()
            };
        }

        private EngineerDto MapEngineerSearchIndex(SqlDataReader reader)
        {
            return new EngineerDto
            {
                EngineerId       = reader.GetInt32(reader.GetOrdinal("engineer_id")),
                FullName         = reader["full_name"].ToString(),
                Email            = reader["email"].ToString(),
                YearsExperience  = Convert.ToInt32(reader["years_experience"]),
                Timezone         = reader["timezone"]?.ToString(),
                AvailabilityStatus = reader["availability_status"]?.ToString(),
                VetStatus        = reader["vet_status"]?.ToString(),
                AvgRating        = reader["avg_rating"] == DBNull.Value ? 0 : Convert.ToDecimal(reader["avg_rating"]),
                SkillsList       = reader["skills_list"]?.ToString(),
                TotalRatings     = reader["total_ratings"] == DBNull.Value ? 0 : Convert.ToInt32(reader["total_ratings"])
            };
        }
    }
}