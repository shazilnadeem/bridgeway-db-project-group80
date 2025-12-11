using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Vetting_Reviews")]
    public class VettingReview
    {
        [Key]
        [Column("review_id")]
        public int ReviewId { get; set; }

        [Column("engineer_id")]
        public int EngineerId { get; set; }

        [Column("review_status")]
        [Required]
        [StringLength(50)]
        public string ReviewStatus { get; set; }

        [Column("skills_verified")]
        public bool SkillsVerified { get; set; }

        [Column("experience_verified")]
        public bool ExperienceVerified { get; set; }

        [Column("portfolio_verified")]
        public bool PortfolioVerified { get; set; }

        [Column("review_notes")]
        public string ReviewNotes { get; set; }

        [Column("rejection_reason")]
        public string RejectionReason { get; set; }

        [Column("reviewed_by")]
        public int? ReviewedBy { get; set; }

        [Column("submitted_at")]
        public DateTime SubmittedAt { get; set; }

        [Column("reviewed_at")]
        public DateTime? ReviewedAt { get; set; }
    }
}