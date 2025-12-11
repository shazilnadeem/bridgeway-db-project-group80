namespace Bridgeway.Domain.DTOs
{
    public class EngineerSearchFilter
    {
        // Renamed from SkillIdList to match usage in EngineerServiceSp (filter.SkillIdsCsv)
        public string SkillIdsCsv { get; set; }

        public int? MinExperience { get; set; }
        public string Timezone { get; set; }
        public decimal? MinRating { get; set; }
        public string VetStatus { get; set; }

        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}