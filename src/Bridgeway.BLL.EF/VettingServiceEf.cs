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
                              .Where(v => v.CurrentVetStatus == "pending")
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
                var review = new VettingReview
                {
                    EngineerId = dto.EngineerId,
                    ReviewedBy = dto.ReviewerUserId,
                    ReviewStatus = dto.Decision, 
                    SkillsVerified = dto.SkillsVerified,
                    ExperienceVerified = dto.ExperienceVerified,
                    PortfolioVerified = dto.PortfolioVerified,
                    ReviewNotes = dto.ReviewNotes,
                    RejectionReason = dto.RejectionReason,
                    SubmittedAt = DateTime.UtcNow
                };

                db.VettingReviews.Add(review);
                db.SaveChanges(); 


                var engineerProfile = db.EngineerProfiles.Find(dto.EngineerId);
                if (engineerProfile != null)
                {
                    string finalStatus = (dto.Decision == "recommended") ? "approved" : dto.Decision;
                    
                    engineerProfile.VetStatus = finalStatus;
                    
                    db.Entry(engineerProfile).State = EntityState.Modified;
                    
                    db.SaveChanges();
                }
            }
        }
    }
}