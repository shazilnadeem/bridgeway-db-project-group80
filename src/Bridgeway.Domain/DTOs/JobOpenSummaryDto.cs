using System;

namespace Bridgeway.Domain.DTOs
{
    public class JobOpenSummaryDto
    {
        public int JobId { get; set; }
        public string Title { get; set; }
        public int ClientId { get; set; }
        public int? TopEngineerId { get; set; }
        public string TopEngineerName { get; set; }
        public decimal? TopMatchScore { get; set; }
    }
}