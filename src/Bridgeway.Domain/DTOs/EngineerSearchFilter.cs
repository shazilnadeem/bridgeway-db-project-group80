// DTOs/EngineerSearchFilter.cs
namespace Bridgeway.Domain.DTOs
{
    public class EngineerSearchFilter
    {
        public string SkillIdsCsv { get; set; }      // e.g. "1,2,3"
        public int? MinExperience { get; set; }
        public string Timezone { get; set; }
        public decimal? MinRating { get; set; }
        public string VetStatus { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
