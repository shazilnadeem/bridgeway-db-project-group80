namespace Bridgeway.Web.Models
{
    public class CreateJobViewModel
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string RequiredSkills { get; set; } // e.g. "Python, ML, Azure"
        public string JobType { get; set; }        // optional
        public decimal? Budget { get; set; }       // optional
    }
}
