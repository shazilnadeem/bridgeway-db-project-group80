using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Client_Profile")]
    public class ClientProfile
    {
        [Key]
        [ForeignKey("User")]
        [Column("client_id")]
        public int ClientId { get; set; }

        [Column("company_name")]
        [Required]
        [StringLength(200)]
        public string CompanyName { get; set; }

        [Column("industry")]
        [StringLength(100)]
        public string Industry { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime? UpdatedAt { get; set; }

        public virtual User User { get; set; }
    }
}