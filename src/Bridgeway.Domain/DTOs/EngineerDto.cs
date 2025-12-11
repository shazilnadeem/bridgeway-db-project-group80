using System;

namespace Bridgeway.Domain.DTOs
{
    public class EngineerDto
    {
        public int EngineerId { get; set; }
        public int UserId { get; set; }

        public string FullName { get; set; }
        public string Email { get; set; }

        public int YearsExperience { get; set; }
        public string Timezone { get; set; }

        public string AvailabilityStatus { get; set; }
        public int AvailabilityStatusId { get; set; } // Added to support Update logic if needed

        public string VetStatus { get; set; }

        public string PortfolioLink { get; set; }

        public decimal AvgRating { get; set; }
        
        // Renamed from RatingCount to match EngineerServiceSp usage ("total_ratings")
        public int TotalRatings { get; set; }

        public string SkillsList { get; set; }
        public decimal? MatchScore { get; set; }
        public string ApplicationStatus { get; set; } // Added for GetRankedCandidates mapping
    }
}