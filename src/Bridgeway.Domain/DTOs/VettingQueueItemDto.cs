using System;

namespace Bridgeway.Domain.DTOs
{
    public class VettingQueueItemDto
    {
        public int EngineerId { get; set; }
        public string EngineerName { get; set; }
        public string Email { get; set; }
        public string CurrentStatus { get; set; }
        public decimal VettingScore { get; set; }
        public int NumReviews { get; set; }
        public string PriorityLevel { get; set; }
    }
}