using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class JobCandidatesViewModel
    {
        public int JobId { get; set; }
        public IList<EngineerDto> Candidates { get; set; }
    }
}
