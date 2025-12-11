using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Job_Application")]
    public class JobApplication
    {
        [Key, Column("engineer_id", Order = 0)]
        public int EngineerId { get; set; }

        [Key, Column("job_id", Order = 1)]
        public int JobId { get; set; }

        [Column("match_score")]
        public decimal? MatchScore { get; set; }

        [Column("status")]
        [Required]
        [StringLength(20)]
        public string Status { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime? UpdatedAt { get; set; }
    }
}