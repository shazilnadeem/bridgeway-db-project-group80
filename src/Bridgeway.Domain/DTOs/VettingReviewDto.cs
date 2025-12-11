using System;

namespace Bridgeway.Domain.DTOs
{
    public class VettingReviewDto
    {
        public int EngineerId { get; set; }
        
        // FIXED: Renamed from ReviewedByUserId to match SP "ReviewerUserId"
        public int ReviewerUserId { get; set; } 

        public string Decision { get; set; }          // Maps to @ReviewStatus in SP

        // FIXED: Added missing boolean flags required by sp_CreateVettingReview
        public bool SkillsVerified { get; set; }
        public bool ExperienceVerified { get; set; }
        public bool PortfolioVerified { get; set; }

        // FIXED: Added specific notes fields used in SP
        public string ReviewNotes { get; set; }
        public string RejectionReason { get; set; }

        // Optional: Keep these if you use them in the UI, but SP doesn't use them directly
        public string EngineerName { get; set; }      
        public string CurrentStatus { get; set; }     
        public DateTime? ReviewedAt { get; set; }
    }
}