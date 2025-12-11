using System;

namespace Bridgeway.Domain.DTOs
{
    public class JobCreateDto
    {
        public int ClientId { get; set; }

        public string Title { get; set; }
        public string Description { get; set; }

        // simple CSV of skill IDs or names, depends on UI/BLL choice
        public string RequiredSkills { get; set; }

        public string JobType { get; set; }           // e.g. full-time/contract
        public decimal? Budget { get; set; }

        public string Timezone { get; set; }
    }
}
