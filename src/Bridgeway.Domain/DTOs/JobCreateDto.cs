using System;
using System.Collections.Generic;

namespace Bridgeway.Domain.DTOs
{
    public class JobCreateDto
    {
        public int ClientId { get; set; }

        public string Title { get; set; } = "";
        public string Description { get; set; } = "";

        public List<int> SkillIds { get; set; } = new();

        public string? JobType { get; set; }
        public decimal? Budget { get; set; }

        public string? Timezone { get; set; }
    }
}
