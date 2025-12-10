using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class AnalyticsServiceSp : IAnalyticsService
    {
        // ------------------------------------------------------------
        // Get monthly analytics for admin dashboard
        // Calls: sp_GetMonthlyPlatformStats
        // ------------------------------------------------------------
        public IList<MonthlyStatsDto> GetMonthlyPlatformStats(int year)
        {
            IList<MonthlyStatsDto> list = new List<MonthlyStatsDto>();

            var parameters = new[]
            {
                new SqlParameter("@Year", year)
            };

            using (var reader = SqlHelper.ExecuteReader("sp_GetMonthlyPlatformStats", parameters))
            {
                while (reader.Read())
                {
                    list.Add(new MonthlyStatsDto
                    {
                        MonthNumber         = Convert.ToInt32(reader["month_num"]),
                        MonthStart          = Convert.ToDateTime(reader["month_start"]),
                        NewEngineers        = Convert.ToInt32(reader["new_engineers"]),
                        NewClients          = Convert.ToInt32(reader["new_clients"]),
                        NewJobs             = Convert.ToInt32(reader["new_jobs"]),
                        TotalApplications   = Convert.ToInt32(reader["total_applications"]),
                        AcceptedApplications = Convert.ToInt32(reader["accepted_applications"]),
                        AvgMatchScore       = reader["avg_match_score"] == DBNull.Value 
                                                ? (decimal?)null 
                                                : Convert.ToDecimal(reader["avg_match_score"])
                    });
                }
            }

            return list;
        }
    }
}
