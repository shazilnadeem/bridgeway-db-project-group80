using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Engineer_Profile")]
    public class EngineerProfile
    {
        [Key]
        [ForeignKey("User")]
        [Column("engineer_id")]
        public int EngineerId { get; set; }

        [Column("years_experience")]
        public int YearsExperience { get; set; }

        [Column("timezone")]
        [StringLength(64)]
        public string Timezone { get; set; }

        [Column("availability_status_id")]
        public int AvailabilityStatusId { get; set; }

        [Column("vet_status")]
        [Required]
        [StringLength(20)]
        public string VetStatus { get; set; }

        [Column("portfolio_link")]
        [StringLength(255)]
        public string PortfolioLink { get; set; }

        // Navigation Property
        public virtual User User { get; set; }
    }
}