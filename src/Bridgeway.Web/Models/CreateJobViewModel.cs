using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.Rendering; // <--- The Correct Namespace for .NET 9

namespace Bridgeway.Web.Models
{
    public class CreateJobViewModel
    {
        public string Title { get; set; }
        public string Description { get; set; }
        
        // The list of IDs selected by the user
        public List<int> SelectedSkillIds { get; set; }

        // The list of items to populate the dropdown
        public IEnumerable<SelectListItem> AvailableSkills { get; set; }

        public string JobType { get; set; }
        public decimal? Budget { get; set; }
    }
}