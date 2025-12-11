using System;

namespace Bridgeway.Domain.DTOs
{
    public class ApplicationDto
    {
        public int EngineerId { get; set; }
        public int JobId { get; set; }

        public string JobTitle { get; set; }
        public string CompanyName { get; set; }
        
        // Added property required by MapApplicationWithEngineer in ApplicationServiceSp
        public string EngineerName { get; set; }

        public decimal? MatchScore { get; set; }
        public string Status { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}