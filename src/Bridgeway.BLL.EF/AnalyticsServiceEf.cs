using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class AnalyticsServiceEf : IAnalyticsService
    {
        public IList<MonthlyStatsDto> GetMonthlyPlatformStats(int year)
        {
            using (var db = new BridgewayDbContext())
            {
                var pYear = new SqlParameter("@Year", year);

                // Execute SP and map to a temporary class that matches the SQL column names exactly
                var rawData = db.Database.SqlQuery<MonthlyStatsSpResult>(
                    "EXEC sp_GetMonthlyPlatformStats @Year", 
                    pYear
                ).ToList();

                // Map raw SQL results to the Domain DTO
                return rawData.Select(r => new MonthlyStatsDto
                {
                    MonthNumber = r.month_num,
                    MonthStart = r.month_start,
                    NewEngineers = r.new_engineers,
                    NewClients = r.new_clients,
                    NewJobs = r.new_jobs,
                    TotalApplications = r.total_applications,
                    AcceptedApplications = r.accepted_applications,
                    AvgMatchScore = r.avg_match_score
                }).ToList();
            }
        }

        // Private helper class to match the Stored Procedure's snake_case output columns
        private class MonthlyStatsSpResult
        {
            public int month_num { get; set; }
            public DateTime month_start { get; set; }
            public int new_engineers { get; set; }
            public int new_clients { get; set; }
            public int new_jobs { get; set; }
            public int total_applications { get; set; }
            public int accepted_applications { get; set; }
            public decimal? avg_match_score { get; set; }
        }
    }
}