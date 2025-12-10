// DTOs/EngineerDto.cs
namespace Bridgeway.Domain.DTOs
{
    public class EngineerDto
    {
        public int EngineerId { get; set; }
        public string FullName { get; set; }
        public string Email { get; set; }

        public int YearsExperience { get; set; }
        public string Timezone { get; set; }
        public string VetStatus { get; set; }
        public string AvailabilityStatus { get; set; }
        public decimal AvgRating { get; set; }
        public string SkillsList { get; set; }
    }
}
