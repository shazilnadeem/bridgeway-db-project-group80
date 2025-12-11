using System;

namespace Bridgeway.Domain.DTOs
{
    public class ClientDto
    {
        public int ClientId { get; set; }
        public int UserId { get; set; }

        public string CompanyName { get; set; }
        public string Industry { get; set; }

        public string ContactName { get; set; }  // from tbl_User.full_name or explicit contact
        public string Email { get; set; }
    }
}
