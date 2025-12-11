using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Skill")]
    public class Skill
    {
        [Key]
        [Column("skill_id")]
        public int SkillId { get; set; }

        [Column("skill_name")]
        [Required]
        [StringLength(100)]
        public string SkillName { get; set; }

        [Column("category")]
        [StringLength(100)]
        public string Category { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
    }
}