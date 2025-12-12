using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_EngineerFullProfile")]
    public class VwEngineerFullProfile
    {
        [Column("engineer_id")]
        public int EngineerId { get; set; } 

        [Column("full_name")]
        public string FullName { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("years_experience")]
        public int YearsExperience { get; set; }

        [Column("timezone")]
        public string Timezone { get; set; }

        [Column("availability_status")]
        public string AvailabilityStatus { get; set; }

        [Column("vet_status")]
        public string VetStatus { get; set; }

        [Column("avg_rating")]
        public decimal AvgRating { get; set; }

        [Column("total_ratings")]
        public int TotalRatings { get; set; }

        [Column("skills_list")]
        public string SkillsList { get; set; }
    }
}