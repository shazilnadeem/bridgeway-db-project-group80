using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Job_Skills")]
    public class JobSkill
    {
        [Key, Column("job_id", Order = 0)]
        public int JobId { get; set; }

        [Key, Column("skill_id", Order = 1)]
        public int SkillId { get; set; }

        [Column("importance_level")]
        [Required]
        [StringLength(20)]
        public string ImportanceLevel { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [ForeignKey("JobId")]
        public virtual Job Job { get; set; }

        [ForeignKey("SkillId")]
        public virtual Skill Skill { get; set; }
    }
}