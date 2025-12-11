using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_OpenJobsWithTopCandidate")]
    public class VwOpenJobsWithTopCandidate
    {
        [Column("job_id")]
        public int JobId { get; set; } // Logic Key

        [Column("job_title")]
        public string JobTitle { get; set; }

        [Column("client_id")]
        public int ClientId { get; set; }

        [Column("top_engineer_id")]
        public int TopEngineerId { get; set; }

        [Column("top_engineer_name")]
        public string TopEngineerName { get; set; }

        [Column("top_match_score")]
        public decimal? TopMatchScore { get; set; }
    }
}