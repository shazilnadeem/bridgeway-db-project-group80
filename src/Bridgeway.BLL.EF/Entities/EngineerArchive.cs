using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Engineer_Archive")]
    public class EngineerArchive
    {
        [Key]
        [Column("archive_id")]
        public int ArchiveId { get; set; }

        [Column("engineer_id")]
        public int EngineerId { get; set; }

        [Column("full_name")]
        [StringLength(150)]
        public string FullName { get; set; }

        [Column("email")]
        [StringLength(255)]
        public string Email { get; set; }

        [Column("years_experience")]
        public int? YearsExperience { get; set; }

        [Column("timezone")]
        [StringLength(64)]
        public string Timezone { get; set; }

        [Column("availability_status_id")]
        public int? AvailabilityStatusId { get; set; }

        [Column("vet_status")]
        [StringLength(20)]
        public string VetStatus { get; set; }

        [Column("portfolio_link")]
        [StringLength(255)]
        public string PortfolioLink { get; set; }

        [Column("archived_at")]
        public DateTime ArchivedAt { get; set; }

        [Column("reason")]
        public string Reason { get; set; }
    }
}