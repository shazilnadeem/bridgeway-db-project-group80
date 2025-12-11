using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class EngineerSearchViewModel
    {
        // The search criteria the admin can fill in
        public EngineerSearchFilter Filter { get; set; }

        // The results returned from the service
        public IList<EngineerDto> Results { get; set; }
    }
}