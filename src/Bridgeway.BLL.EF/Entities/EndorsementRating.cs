using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Endorsement_Ratings")]
    public class EndorsementRating
    {
        [Key, Column("client_id", Order = 0)]
        public int ClientId { get; set; }

        [Key, Column("engineer_id", Order = 1)]
        public int EngineerId { get; set; }

        [Column("rating")]
        public int Rating { get; set; }

        [Column("comment")]
        public string Comment { get; set; }

        [Column("verified")]
        public bool Verified { get; set; }

        [Column("date")]
        public DateTime Date { get; set; }
    }
}