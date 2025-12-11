using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity;
using Bridgeway.BLL.EF.Entities;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class EngineerServiceEf : IEngineerService
    {
        // Overload 1: Maps the detailed profile view to DTO
        private EngineerDto MapToDto(VwEngineerFullProfile entity)
        {
            if (entity == null) return null;
            return new EngineerDto
            {
                EngineerId = entity.EngineerId,
                FullName = entity.FullName,
                Email = entity.Email,
                YearsExperience = entity.YearsExperience,
                Timezone = entity.Timezone,
                VetStatus = entity.VetStatus,
                AvailabilityStatus = entity.AvailabilityStatus,
                AvgRating = entity.AvgRating,
                SkillsList = entity.SkillsList
            };
        }

        // Overload 2: Maps the lighter search index view to DTO
        private EngineerDto MapToDto(VwEngineerSearchIndex entity)
        {
            if (entity == null) return null;
            return new EngineerDto
            {
                EngineerId = entity.EngineerId,
                FullName = entity.FullName,
                Email = entity.Email,
                YearsExperience = entity.YearsExperience,
                Timezone = entity.Timezone,
                VetStatus = entity.VetStatus,
                AvailabilityStatus = entity.AvailabilityStatus,
                AvgRating = entity.AvgRating,
                SkillsList = entity.SkillsList
            };
        }

        public EngineerDto GetById(int engineerId)
        {
            using (var db = new BridgewayDbContext())
            {
                // Fetch from the full profile view
                var entity = db.VwEngineerFullProfiles
                               .AsNoTracking()
                               .SingleOrDefault(e => e.EngineerId == engineerId);
                
                return MapToDto(entity);
            }
        }

        public EngineerDto GetCurrentEngineerProfile(int userId)
        {
            // UserId and EngineerId are 1:1
            return GetById(userId);
        }
        
        public void RegisterEngineer(int userId)
        {
            using (var db = new BridgewayDbContext())
            {
                if (db.EngineerProfiles.Any(p => p.EngineerId == userId)) return;

                // Insert new profile with defaults
                var profile = new EngineerProfile
                {
                    EngineerId = userId,
                    YearsExperience = 0,
                    VetStatus = "pending",
                    AvailabilityStatusId = 1, // Default to 'full-time' or similar
                    CreatedAt = DateTime.UtcNow
                };

                db.EngineerProfiles.Add(profile);
                db.SaveChanges();
            }
        }

        public void UpdateEngineerProfile(EngineerDto dto)
        {
            using (var db = new BridgewayDbContext())
            {
                // Update User table (FullName, Email)
                var user = db.Users.Find(dto.EngineerId);
                if (user != null)
                {
                    user.FullName = dto.FullName;
                    user.Email = dto.Email;
                    user.UpdatedAt = DateTime.UtcNow;
                }
                
                // Update EngineerProfile table (Experience, Timezone)
                var profile = db.EngineerProfiles.Find(dto.EngineerId);
                if (profile == null) throw new KeyNotFoundException($"Engineer {dto.EngineerId} not found.");

                profile.YearsExperience = dto.YearsExperience;
                profile.Timezone = dto.Timezone;
                profile.UpdatedAt = DateTime.UtcNow;

                db.SaveChanges();
            }
        }

        public IList<EngineerDto> SearchEngineers(EngineerSearchFilter filter)
        {
            using (var db = new BridgewayDbContext())
            {
                var query = db.VwEngineerSearchIndexes.AsNoTracking().AsQueryable();

                // 1. Basic Filters
                if (filter.MinExperience.HasValue)
                    query = query.Where(e => e.YearsExperience >= filter.MinExperience.Value);

                if (filter.MinRating.HasValue)
                    query = query.Where(e => e.AvgRating >= filter.MinRating.Value);

                if (!string.IsNullOrWhiteSpace(filter.VetStatus))
                    query = query.Where(e => e.VetStatus == filter.VetStatus);
                
                if (!string.IsNullOrWhiteSpace(filter.Timezone)) 
                    query = query.Where(e => e.Timezone.Contains(filter.Timezone));

                // 2. Skill Filtering (Engineer must have ANY of the provided skills)
                if (!string.IsNullOrWhiteSpace(filter.SkillIdsCsv))
                {
                    var skillIds = filter.SkillIdsCsv.Split(',')
                                         .Select(s => int.Parse(s.Trim()))
                                         .ToList();

                    // Subquery to find engineers with matching skills
                    var matchingIds = db.EngineerSkills
                                        .Where(es => skillIds.Contains(es.SkillId))
                                        .Select(es => es.EngineerId)
                                        .Distinct();

                    query = query.Where(e => matchingIds.Contains(e.EngineerId));
                }

                // 3. Sort & Page
                var results = query.OrderByDescending(e => e.AvgRating)
                                   .ThenByDescending(e => e.YearsExperience)
                                   .Skip((filter.Page - 1) * filter.PageSize)
                                   .Take(filter.PageSize)
                                   .ToList();

                return results.Select(MapToDto).ToList();
            }
        }
    }
}