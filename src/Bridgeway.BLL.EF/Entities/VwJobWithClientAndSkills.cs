using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("vw_JobWithClientAndSkills")]
    public class VwJobWithClientAndSkills
    {
        [Column("job_id")]
        public int JobId { get; set; } 

        [Column("job_title")]
        public string JobTitle { get; set; }

        [Column("job_description")]
        public string JobDescription { get; set; }

        [Column("job_status")]
        public string JobStatus { get; set; }

        [Column("client_id")]
        public int ClientId { get; set; }

        [Column("company_name")]
        public string CompanyName { get; set; }

        [Column("industry")]
        public string Industry { get; set; }

        [Column("required_skills")]
        public string RequiredSkills { get; set; }
        
        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime? UpdatedAt { get; set; }
    }
}