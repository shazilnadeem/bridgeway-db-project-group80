using System;

namespace Bridgeway.Domain.DTOs
{
    public class JobDto
    {
        public int JobId { get; set; }
        public int ClientId { get; set; }

        public string Title { get; set; }
        public string Description { get; set; }

        public string Status { get; set; }   // open / in_progress / closed
        
        // FIXED: Renamed from CreatedOn to match SP "CreatedAt"
        public DateTime CreatedAt { get; set; }
        
        // FIXED: Renamed from UpdatedOn to match SP "UpdatedAt"
        public DateTime? UpdatedAt { get; set; }

        public string Timezone { get; set; }

        public string RequiredSkills { get; set; }
        public string ClientName { get; set; }
        public string ClientIndustry { get; set; }
    }
}