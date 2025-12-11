using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_JobCandidatesRanked")]
    public class VwJobCandidatesRanked
    {
        // This view has no single unique ID, so we might need a composite key in OnModelCreating
        // typically (JobId, EngineerId) is unique.
        
        [Column("job_id")]
        public int JobId { get; set; }

        [Column("job_title")]
        public string JobTitle { get; set; }

        [Column("client_id")]
        public int ClientId { get; set; }

        [Column("engineer_id")]
        public int EngineerId { get; set; }

        [Column("engineer_name")]
        public string EngineerName { get; set; }

        [Column("match_score")]
        public decimal? MatchScore { get; set; }

        [Column("application_status")]
        public string ApplicationStatus { get; set; }

        [Column("vet_status")]
        public string VetStatus { get; set; }

        [Column("years_experience")]
        public int YearsExperience { get; set; }

        [Column("availability_status_id")]
        public int AvailabilityStatusId { get; set; }

        [Column("engineer_timezone")]
        public string EngineerTimezone { get; set; }

        [Column("portfolio_link")]
        public string PortfolioLink { get; set; }

        [Column("avg_rating")]
        public decimal AvgRating { get; set; }

        [Column("rating_count")]
        public int RatingCount { get; set; }

        [Column("candidate_rank")]
        public long? CandidateRank { get; set; }
    }
}