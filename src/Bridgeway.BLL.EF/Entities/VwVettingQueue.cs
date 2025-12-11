using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_VettingQueue")]
    public class VwVettingQueue
    {
        [Column("engineer_id")]
        public int EngineerId { get; set; } // Logic Key

        [Column("engineer_name")]
        public string EngineerName { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("current_vet_status")]
        public string CurrentVetStatus { get; set; }

        [Column("vetting_score")]
        public decimal? VettingScore { get; set; }

        [Column("num_reviews")]
        public int NumReviews { get; set; }

        [Column("last_review_date")]
        public DateTime? LastReviewDate { get; set; }

        [Column("priority_level")]
        public string PriorityLevel { get; set; }
    }
}