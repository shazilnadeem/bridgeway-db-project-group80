using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IAnalyticsService
    {
        IList<MonthlyStatsDto> GetMonthlyPlatformStats(int year);
    }
}
