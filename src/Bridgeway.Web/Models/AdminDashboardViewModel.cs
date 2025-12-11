//*implemented by areeba:

namespace Bridgeway.Web.Models
{
    public class AdminDashboardViewModel
    {
        public string CurrentMode { get; set; }
        public int TotalEngineers { get; set; }
        public int PendingVetting { get; set; }
        public int OpenJobs { get; set; }
    }
}
