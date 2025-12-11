using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class AnalyticsViewModel
    {
        public int Year { get; set; }

        // One row per month: NewJobs, Matches, AcceptedOffers, etc.
        public IList<MonthlyStatsDto> MonthlyStats { get; set; }
    }
}
