using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class ClientDashboardViewModel
    {
        public ClientDto Client { get; set; }
        public IList<JobDto> RecentJobs { get; set; }
    }
}
