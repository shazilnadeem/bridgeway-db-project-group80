//*implemented by areeba:

using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class AnalyticsViewModel
    {
        public int Year { get; set; }
        public IList<MonthlyStatsDto> MonthlyStats { get; set; }
    }
}
