using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace Bridgeway.Web.Models
{
    public class CreateJobViewModel
    {
        [Required]
        public string Title { get; set; } = "";

        [Required]
        public string Description { get; set; } = "";

        // Multi-select binds to this on POST
        public List<int> SelectedSkillIds { get; set; } = new();

        // UI-only (not posted)
        [BindNever]
        public IEnumerable<SelectListItem> AvailableSkills { get; set; } = new List<SelectListItem>();

        public string? JobType { get; set; }
        public decimal? Budget { get; set; }
    }
}
