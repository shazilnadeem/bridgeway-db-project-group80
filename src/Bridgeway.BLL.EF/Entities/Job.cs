using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Bridgeway.BLL.EF.Entities
{
    [Table("tbl_Job")]
    public class Job
    {
        [Key]
        [Column("job_id")]
        public int JobId { get; set; }

        [Column("client_id")]
        public int ClientId { get; set; }

        [Column("job_title")]
        [Required]
        [StringLength(200)]
        public string JobTitle { get; set; }

        [Column("job_description")]
        public string JobDescription { get; set; }

        [Column("status")]
        [Required]
        [StringLength(20)]
        public string Status { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }


    }
}