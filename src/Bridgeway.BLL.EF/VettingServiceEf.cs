using System;
using System.Collections.Generic;
using System.Linq;
using Bridgeway.BLL.EF.Entities;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class VettingServiceEf : IVettingService
    {
        public IList<VettingQueueItemDto> GetVettingQueue()
        {
            using (var db = new BridgewayDbContext())
            {
                // Query the Vetting Queue View
                // Ordered by 'LastReviewDate' ascending to show oldest pending items first
                var query = db.VwVettingQueues
                              .AsNoTracking()
                              .OrderBy(v => v.LastReviewDate)
                              .ToList();

                return query.Select(v => new VettingQueueItemDto
                {
                    EngineerId = v.EngineerId,
                    EngineerName = v.EngineerName,
                    Email = v.Email,
                    CurrentStatus = v.CurrentVetStatus,
                    VettingScore = v.VettingScore ?? 0, // Handle potential nulls from DB
                    NumReviews = v.NumReviews,
                    PriorityLevel = v.PriorityLevel
                }).ToList();
            }
        }

        public void CreateVettingReview(VettingReviewDto dto)
        {
            using (var db = new BridgewayDbContext())
            {
                // Validate constraints (optional but recommended)
                if (!db.EngineerProfiles.Any(e => e.EngineerId == dto.EngineerId))
                {
                    throw new KeyNotFoundException("Engineer not found.");
                }

                var review = new VettingReview
                {
                    EngineerId = dto.EngineerId,
                    ReviewedBy = dto.ReviewerUserId,
                    ReviewStatus = dto.Decision, // "recommended", "not_recommended", etc.
                    
                    SkillsVerified = dto.SkillsVerified,
                    ExperienceVerified = dto.ExperienceVerified,
                    PortfolioVerified = dto.PortfolioVerified,
                    
                    ReviewNotes = dto.ReviewNotes,
                    RejectionReason = dto.RejectionReason,
                    
                    SubmittedAt = DateTime.UtcNow
                };

                db.VettingReviews.Add(review);
                
                // Saving changes will fire the DB Trigger 'trg_VettingReviews_AfterInsert'
                // which automatically executes 'sp_FinaliseVettingDecision' to update 
                // the engineer's profile status.
                db.SaveChanges();
            }
        }
    }
}