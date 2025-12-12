using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_User")]
    public class User
    {
        [Key]
        [Column("user_id")]
        public int UserId { get; set; }

        [Column("full_name")]
        [Required]
        [StringLength(150)]
        public string FullName { get; set; }

        [Column("email")]
        [Required]
        [StringLength(255)]
        public string Email { get; set; }

        [Column("password")]
        [Required]
        [StringLength(255)]
        public string Password { get; set; }

        [Column("role")]
        [Required]
        [StringLength(20)]
        public string Role { get; set; } 

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime? UpdatedAt { get; set; }
    }
}