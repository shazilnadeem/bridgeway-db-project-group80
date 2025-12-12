using System.Data.Entity;
using Bridgeway.BLL.EF.Entities;

namespace Bridgeway.BLL.EF
{
    public class BridgewayDbContext : DbContext
    {
        public static string ConnectionString { get; set; }

        public BridgewayDbContext() : base(ConnectionString ?? "name=BridgewayDb")
        {
            Database.SetInitializer<BridgewayDbContext>(null);
        }

        // =========================================================
        // Table DbSets
        // =========================================================
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<AvailabilityStatus> AvailabilityStatuses { get; set; }
        public virtual DbSet<EngineerProfile> EngineerProfiles { get; set; }
        public virtual DbSet<ClientProfile> ClientProfiles { get; set; }
        public virtual DbSet<Skill> Skills { get; set; }
        public virtual DbSet<EngineerSkill> EngineerSkills { get; set; }
        public virtual DbSet<Job> Jobs { get; set; }
        public virtual DbSet<JobSkill> JobSkills { get; set; }
        public virtual DbSet<JobApplication> JobApplications { get; set; }
        public virtual DbSet<VettingReview> VettingReviews { get; set; }
        public virtual DbSet<EndorsementRating> EndorsementRatings { get; set; }
        public virtual DbSet<EngineerRatingCache> EngineerRatingCache { get; set; }
        public virtual DbSet<EngineerArchive> EngineerArchive { get; set; }

        // =========================================================
        // View DbSets
        // =========================================================
        public virtual DbSet<VwEngineerFullProfile> VwEngineerFullProfiles { get; set; }
        public virtual DbSet<VwEngineerSearchIndex> VwEngineerSearchIndexes { get; set; }
        public virtual DbSet<VwJobWithClientAndSkills> VwJobsWithClientAndSkills { get; set; }
        public virtual DbSet<VwApplicationsSummaryByJob> VwApplicationsSummaries { get; set; }
        public virtual DbSet<VwVettingQueue> VwVettingQueues { get; set; }
        public virtual DbSet<VwJobCandidatesRanked> VwJobCandidatesRanked { get; set; }
        public virtual DbSet<VwOpenJobsWithTopCandidate> VwOpenJobsWithTopCandidates { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            // --- Composite Keys ---
            modelBuilder.Entity<EngineerSkill>().HasKey(es => new { es.EngineerId, es.SkillId });
            modelBuilder.Entity<JobSkill>().HasKey(js => new { js.JobId, js.SkillId });
            modelBuilder.Entity<JobApplication>().HasKey(ja => new { ja.EngineerId, ja.JobId });
            modelBuilder.Entity<EndorsementRating>().HasKey(er => new { er.ClientId, er.EngineerId });

            // --- Keys for Views ---
            modelBuilder.Entity<VwEngineerFullProfile>().HasKey(v => v.EngineerId);
            modelBuilder.Entity<VwEngineerSearchIndex>().HasKey(v => v.EngineerId);
            modelBuilder.Entity<VwJobWithClientAndSkills>().HasKey(v => v.JobId);
            modelBuilder.Entity<VwApplicationsSummaryByJob>().HasKey(v => v.JobId);
            modelBuilder.Entity<VwVettingQueue>().HasKey(v => v.EngineerId);
            modelBuilder.Entity<VwJobCandidatesRanked>().HasKey(v => new { v.JobId, v.EngineerId });
            modelBuilder.Entity<VwOpenJobsWithTopCandidate>().HasKey(v => v.JobId);

            // --- Explicit Table Mapping (Standard Tables) ---
            modelBuilder.Entity<User>().ToTable("tbl_User");
            modelBuilder.Entity<AvailabilityStatus>().ToTable("tbl_Availability_Status");
            modelBuilder.Entity<EngineerProfile>().ToTable("tbl_Engineer_Profile");
            modelBuilder.Entity<ClientProfile>().ToTable("tbl_Client_Profile");
            modelBuilder.Entity<Skill>().ToTable("tbl_Skill");
            modelBuilder.Entity<EngineerSkill>().ToTable("tbl_Engineer_Skills");
            modelBuilder.Entity<Job>().ToTable("tbl_Job");
            modelBuilder.Entity<JobSkill>().ToTable("tbl_Job_Skills");
            modelBuilder.Entity<JobApplication>().ToTable("tbl_Job_Application");
            modelBuilder.Entity<VettingReview>().ToTable("tbl_Vetting_Reviews");
            modelBuilder.Entity<EndorsementRating>().ToTable("tbl_Endorsement_Ratings");
            modelBuilder.Entity<EngineerRatingCache>().ToTable("tbl_Engineer_RatingCache");
            modelBuilder.Entity<EngineerArchive>().ToTable("tbl_Engineer_Archive");

            // --- FIX START: Explicit View Mapping ---
            // These lines map the C# classes to your SQL Views (which start with 'vw_')
            modelBuilder.Entity<VwEngineerFullProfile>().ToTable("vw_EngineerFullProfile");
            modelBuilder.Entity<VwEngineerSearchIndex>().ToTable("vw_EngineerSearchIndex");
            modelBuilder.Entity<VwJobWithClientAndSkills>().ToTable("vw_JobWithClientAndSkills");
            modelBuilder.Entity<VwApplicationsSummaryByJob>().ToTable("vw_ApplicationsSummaryByJob");
            modelBuilder.Entity<VwVettingQueue>().ToTable("vw_VettingQueue");
            modelBuilder.Entity<VwJobCandidatesRanked>().ToTable("vw_JobCandidatesRanked");
            modelBuilder.Entity<VwOpenJobsWithTopCandidate>().ToTable("vw_OpenJobsWithTopCandidate");

            base.OnModelCreating(modelBuilder);
        }
    }
}