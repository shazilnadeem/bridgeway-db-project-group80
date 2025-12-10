namespace Bridgeway.Web.Models
{
    public class EngineerProfileViewModel
    {
        public int EngineerId { get; set; }
        public string FullName { get; set; }
        public int YearsExperience { get; set; }
        public string Timezone { get; set; }
        public string AvailabilityStatus { get; set; }
        public string SkillsList { get; set; } // simple comma-separated list for now
    }
}

//  basically just a form model, this is what we want the engineers to edit