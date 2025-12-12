using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class EngineerDashboardViewModel
    {
        // The full engineer profile (name, timezone, vetting status, etc.)
        public EngineerDto Engineer { get; set; }

        // A small list of recent applications to show on the dashboard
        public IList<ApplicationDto> RecentApplications { get; set; }
        // EngineerDto and ApplicationDto are objects already defined in Bridgeway.Domain
        public ApplicationDto CurrentJob { get; set; }
    }
}
