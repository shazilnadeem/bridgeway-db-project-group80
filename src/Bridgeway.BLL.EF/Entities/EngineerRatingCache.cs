using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Engineer_RatingCache")]
    public class EngineerRatingCache
    {
        [Key]
        [Column("engineer_id")]
        public int EngineerId { get; set; }

        [Column("avg_rating")]
        public decimal AvgRating { get; set; }

        [Column("rating_count")]
        public int RatingCount { get; set; }

        [Column("last_updated")]
        public DateTime LastUpdated { get; set; }
    }
}