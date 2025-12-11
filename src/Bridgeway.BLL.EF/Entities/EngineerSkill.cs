using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Engineer_Skills")]
    public class EngineerSkill
    {
        [Key, Column("engineer_id", Order = 0)]
        public int EngineerId { get; set; }

        [Key, Column("skill_id", Order = 1)]
        public int SkillId { get; set; }

        [Column("proficiency_score")]
        public byte ProficiencyScore { get; set; } // mapped from TINYINT

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey("EngineerId")]
        public virtual EngineerProfile Engineer { get; set; }

        [ForeignKey("SkillId")]
        public virtual Skill Skill { get; set; }
    }
}