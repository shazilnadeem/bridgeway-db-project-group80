using System;

namespace Bridgeway.Domain.DTOs
{
    public class MonthlyStatsDto
    {
        public int MonthNumber { get; set; }
        public DateTime MonthStart { get; set; }
        public int NewEngineers { get; set; }
        public int NewClients { get; set; }
        public int NewJobs { get; set; }
        public int TotalApplications { get; set; }
        public int AcceptedApplications { get; set; }
        public decimal? AvgMatchScore { get; set; }
    }
}