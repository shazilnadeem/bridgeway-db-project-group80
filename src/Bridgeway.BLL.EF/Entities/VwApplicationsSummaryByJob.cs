using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_ApplicationsSummaryByJob")]
    public class VwApplicationsSummaryByJob
    {
        [Column("job_id")]
        public int JobId { get; set; } // Logic Key

        [Column("job_title")]
        public string JobTitle { get; set; }

        [Column("job_status")]
        public string JobStatus { get; set; }

        [Column("total_applications")]
        public int TotalApplications { get; set; }

        [Column("pending_count")]
        public int? PendingCount { get; set; }

        [Column("shortlisted_count")]
        public int? ShortlistedCount { get; set; }

        [Column("accepted_count")]
        public int? AcceptedCount { get; set; }

        [Column("rejected_count")]
        public int? RejectedCount { get; set; }
    }
}