using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity; // Required for EntityState
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
                var query = db.VwVettingQueues
                              .AsNoTracking()
                              .Where(v => v.CurrentVetStatus == "pending") // Filter only pending
                              .OrderBy(v => v.LastReviewDate)
                              .ToList();

                return query.Select(v => new VettingQueueItemDto
                {
                    EngineerId = v.EngineerId,
                    EngineerName = v.EngineerName,
                    Email = v.Email,
                    CurrentStatus = v.CurrentVetStatus,
                    VettingScore = v.VettingScore ?? 0,
                    NumReviews = v.NumReviews,
                    PriorityLevel = v.PriorityLevel
                }).ToList();
            }
        }

        public void CreateVettingReview(VettingReviewDto dto)
        {
            using (var db = new BridgewayDbContext())
            {
                // --- STEP 1: Insert the Review ---
                // We save this FIRST so the trigger fires now. 
                // Even if the trigger calculates a low score and sets 'pending', we don't care yet.
                var review = new VettingReview
                {
                    EngineerId = dto.EngineerId,
                    ReviewedBy = dto.ReviewerUserId,
                    ReviewStatus = dto.Decision, // "recommended" or "rejected"
                    SkillsVerified = dto.SkillsVerified,
                    ExperienceVerified = dto.ExperienceVerified,
                    PortfolioVerified = dto.PortfolioVerified,
                    ReviewNotes = dto.ReviewNotes,
                    RejectionReason = dto.RejectionReason,
                    SubmittedAt = DateTime.UtcNow
                };

                db.VettingReviews.Add(review);
                db.SaveChanges(); // <--- Transaction 1 (Trigger fires here)

                // --- STEP 2: Force Update the Profile ---
                // Now we overwrite whatever the trigger did with the Admin's final decision.
                var engineerProfile = db.EngineerProfiles.Find(dto.EngineerId);
                if (engineerProfile != null)
                {
                    // Map "recommended" -> "approved" to match DB Constraint
                    string finalStatus = (dto.Decision == "recommended") ? "approved" : dto.Decision;
                    
                    engineerProfile.VetStatus = finalStatus;
                    
                    // Explicitly mark as modified
                    db.Entry(engineerProfile).State = EntityState.Modified;
                    
                    db.SaveChanges(); // <--- Transaction 2 (Final Authority)
                }
            }
        }
    }
}