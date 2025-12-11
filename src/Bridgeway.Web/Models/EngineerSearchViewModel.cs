//*implemented by areeba:

using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Web.Models
{
    public class EngineerSearchViewModel
    {
        public EngineerSearchFilter Filter { get; set; }
        public IList<EngineerDto> Results { get; set; }
    }
}
