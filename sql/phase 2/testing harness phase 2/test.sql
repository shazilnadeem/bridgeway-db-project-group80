------------------------------------------------------------
-- BridgewayDB - test.sql (Smoke / Demo Script)
-- Purpose:
--   1) Verify schema + constraints compile & run
--   2) Sanity-check generated data and relationships
--   3) Demonstrate key views, functions, and procedures
--
-- Run this AFTER: group80_p2_master.sql
------------------------------------------------------------

------------------------------------------------------------
-- 0. Use database
------------------------------------------------------------
USE BridgewayDB;
GO

SET NOCOUNT ON;
GO

PRINT '============================================================';
PRINT 'BridgewayDB Smoke Test Starting...';
PRINT '============================================================';

------------------------------------------------------------
-- 1. Ensure We Have Some Test Data (small + safe)
--    NOTE:
--      - master script may already generate HUGE data.
--      - This block only runs if there are NO engineers.
------------------------------------------------------------
-- IF OBJECT_ID('dbo.sp_GGenerateTestData','P') IS NOT NULL
--    AND NOT EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile)
-- BEGIN
--     PRINT 'No engineer data found. Generating SMALL test dataset via sp_GGenerateTestData...';

--     EXEC dbo.sp_GGenerateTestData
--         @NumEngineers           = 50,
--         @NumClients             = 20,
--         @NumJobs                = 80,
--         @AvgSkillsPerEngineer   = 3,
--         @AvgSkillsPerJob        = 2,
--         @ApplicationsPerJob     = 5;

--     PRINT 'Small synthetic dataset generated.';
-- END
-- ELSE
-- BEGIN
--     PRINT 'Engineer data already exists. Skipping test data generation.';
-- END;
-- GO

------------------------------------------------------------
-- 2. Basic Volume Checks
------------------------------------------------------------

PRINT '== 2.1 User counts by role ==';
SELECT role, COUNT(*) AS total_users
FROM dbo.tbl_User
GROUP BY role;

PRINT '== 2.2 Core entity counts ==';
SELECT COUNT(*) AS total_engineer_profiles FROM dbo.tbl_Engineer_Profile;
SELECT COUNT(*) AS total_client_profiles   FROM dbo.tbl_Client_Profile;
SELECT COUNT(*) AS total_jobs              FROM dbo.tbl_Job;
SELECT COUNT(*) AS total_applications      FROM dbo.tbl_Job_Application;
SELECT COUNT(*) AS total_vetting_reviews   FROM dbo.tbl_Vetting_Reviews;
SELECT COUNT(*) AS total_ratings           FROM dbo.tbl_Endorsement_Ratings;
SELECT COUNT(*) AS total_engineer_skills   FROM dbo.tbl_Engineer_Skills;
SELECT COUNT(*) AS total_job_skills        FROM dbo.tbl_Job_Skills;
SELECT COUNT(*) AS total_rating_cache_rows FROM dbo.tbl_Engineer_RatingCache;
SELECT COUNT(*) AS total_archived_engineers FROM dbo.tbl_Engineer_Archive;

------------------------------------------------------------
-- 3. Relationship Integrity Checks (Orphans)
------------------------------------------------------------

PRINT '== 3.1 Engineer profiles without a valid tbl_User row ==';
SELECT ep.engineer_id, ep.years_experience
FROM dbo.tbl_Engineer_Profile ep
LEFT JOIN dbo.tbl_User u ON ep.engineer_id = u.user_id
WHERE u.user_id IS NULL;

PRINT '== 3.2 Client profiles without a valid tbl_User row ==';
SELECT cp.client_id, cp.company_name
FROM dbo.tbl_Client_Profile cp
LEFT JOIN dbo.tbl_User u ON cp.client_id = u.user_id
WHERE u.user_id IS NULL;

PRINT '== 3.3 Users with role = engineer but missing tbl_Engineer_Profile ==';
SELECT u.user_id, u.full_name, u.role
FROM dbo.tbl_User u
LEFT JOIN dbo.tbl_Engineer_Profile ep ON u.user_id = ep.engineer_id
WHERE u.role = 'engineer' AND ep.engineer_id IS NULL;

PRINT '== 3.4 Users with role = client but missing tbl_Client_Profile ==';
SELECT u.user_id, u.full_name, u.role
FROM dbo.tbl_User u
LEFT JOIN dbo.tbl_Client_Profile cp ON u.user_id = cp.client_id
WHERE u.role = 'client' AND cp.client_id IS NULL;

PRINT '== 3.5 Jobs with missing client profile ==';
SELECT j.job_id, j.job_title, j.client_id
FROM dbo.tbl_Job j
LEFT JOIN dbo.tbl_Client_Profile cp ON j.client_id = cp.client_id
WHERE cp.client_id IS NULL;

PRINT '== 3.6 Applications with missing job or engineer profile ==';
SELECT a.engineer_id, a.job_id, a.status
FROM dbo.tbl_Job_Application a
LEFT JOIN dbo.tbl_Job j ON a.job_id = j.job_id
LEFT JOIN dbo.tbl_Engineer_Profile ep ON a.engineer_id = ep.engineer_id
WHERE j.job_id IS NULL OR ep.engineer_id IS NULL;

PRINT '== 3.7 Vetting reviews referencing missing engineer profiles ==';
SELECT vr.review_id, vr.engineer_id
FROM dbo.tbl_Vetting_Reviews vr
LEFT JOIN dbo.tbl_Engineer_Profile ep ON vr.engineer_id = ep.engineer_id
WHERE ep.engineer_id IS NULL;

PRINT '== 3.8 Endorsement ratings referencing missing client or engineer ==';
SELECT er.client_id, er.engineer_id, er.rating
FROM dbo.tbl_Endorsement_Ratings er
LEFT JOIN dbo.tbl_Client_Profile cp ON er.client_id = cp.client_id
LEFT JOIN dbo.tbl_Engineer_Profile ep ON er.engineer_id = ep.engineer_id
WHERE cp.client_id IS NULL OR ep.engineer_id IS NULL;

PRINT '== 3.9 Rating cache rows without matching engineer profile ==';
SELECT rc.engineer_id, rc.avg_rating, rc.rating_count
FROM dbo.tbl_Engineer_RatingCache rc
LEFT JOIN dbo.tbl_Engineer_Profile ep ON rc.engineer_id = ep.engineer_id
WHERE ep.engineer_id IS NULL;

PRINT '== 3.10 Archived engineers without matching user row ==';
SELECT ea.engineer_id, ea.full_name, ea.email
FROM dbo.tbl_Engineer_Archive ea
LEFT JOIN dbo.tbl_User u ON ea.engineer_id = u.user_id
WHERE u.user_id IS NULL;

------------------------------------------------------------
-- 4. Data Variety / Distribution Checks
------------------------------------------------------------

PRINT '== 4.1 Applications per job (top 20 by application_count) ==';
SELECT TOP 20
    j.job_id,
    j.job_title,
    COUNT(a.engineer_id) AS application_count
FROM dbo.tbl_Job j
LEFT JOIN dbo.tbl_Job_Application a
    ON j.job_id = a.job_id
GROUP BY j.job_id, j.job_title
ORDER BY application_count DESC;

PRINT '== 4.2 Vetting status distribution for engineers ==';
SELECT vet_status, COUNT(*) AS total
FROM dbo.tbl_Engineer_Profile
GROUP BY vet_status;

PRINT '== 4.3 Application status distribution ==';
SELECT status, COUNT(*) AS total
FROM dbo.tbl_Job_Application
GROUP BY status;

PRINT '== 4.4 Skills per engineer (top 20 by skill_count) ==';
SELECT TOP 20
    ep.engineer_id,
    u.full_name,
    COUNT(es.skill_id) AS skill_count
FROM dbo.tbl_Engineer_Profile ep
JOIN dbo.tbl_User u ON ep.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Engineer_Skills es ON ep.engineer_id = es.engineer_id
GROUP BY ep.engineer_id, u.full_name
ORDER BY skill_count DESC;

PRINT '== 4.5 Ratings distribution (if any) ==';
SELECT 
    rating,
    COUNT(*) AS rating_count
FROM dbo.tbl_Endorsement_Ratings
GROUP BY rating
ORDER BY rating;

PRINT '== 4.6 Applications per engineer (top 20) ==';
SELECT TOP 20
    a.engineer_id,
    u.full_name,
    COUNT(a.job_id) AS applications_count
FROM dbo.tbl_Job_Application a
JOIN dbo.tbl_Engineer_Profile ep ON a.engineer_id = ep.engineer_id
JOIN dbo.tbl_User u ON ep.engineer_id = u.user_id
GROUP BY a.engineer_id, u.full_name
ORDER BY applications_count DESC;

------------------------------------------------------------
-- 5. Views & Read Models (Feature Demos)
------------------------------------------------------------

PRINT '== 5.1 Sample rows from vw_EngineerFullProfile ==';
SELECT TOP 20 *
FROM dbo.vw_EngineerFullProfile
ORDER BY engineer_id;

PRINT '== 5.2 Sample rows from vw_EngineerSearchIndex (for search layer) ==';
SELECT TOP 20 *
FROM dbo.vw_EngineerSearchIndex
ORDER BY avg_rating DESC, years_experience DESC;

PRINT '== 5.3 Job listing with client + skills (vw_JobWithClientAndSkills) ==';
SELECT TOP 20 *
FROM dbo.vw_JobWithClientAndSkills
ORDER BY job_id;

PRINT '== 5.4 Application summary per job (vw_ApplicationsSummaryByJob) ==';
SELECT TOP 20 *
FROM dbo.vw_ApplicationsSummaryByJob
ORDER BY total_applications DESC;

PRINT '== 5.5 Vetting queue (vw_VettingQueue) ==';
SELECT TOP 20 *
FROM dbo.vw_VettingQueue
ORDER BY priority_level, vetting_score DESC;

PRINT '== 5.6 Ranked candidates per job (vw_JobCandidatesRanked) ==';
SELECT TOP 20 *
FROM dbo.vw_JobCandidatesRanked
ORDER BY job_id, candidate_rank;

PRINT '== 5.7 Open jobs with top candidate (vw_OpenJobsWithTopCandidate) ==';
SELECT TOP 20 *
FROM dbo.vw_OpenJobsWithTopCandidate
ORDER BY job_id;

------------------------------------------------------------
-- 6. Stored Procedure Smoke Tests
------------------------------------------------------------

-----------------------------
-- 6.1 SearchEngineersByFilters
-----------------------------
PRINT '== 6.1 sp_SearchEngineersByFilters: vet_status = ''approved'', min rating 3.0 ==';
IF OBJECT_ID('dbo.sp_SearchEngineersByFilters','P') IS NOT NULL
BEGIN
    EXEC dbo.sp_SearchEngineersByFilters
        @SkillIdList   = NULL,
        @MinExperience = 2,
        @Timezone      = NULL,
        @MinRating     = 3.0,
        @VetStatus     = 'approved',
        @Page          = 1,
        @PageSize      = 20;
END
ELSE
BEGIN
    PRINT 'sp_SearchEngineersByFilters not found.';
END;

-----------------------------
-- 6.2 Create a test job and apply
-----------------------------
PRINT '== 6.2 sp_CreateJob + sp_ApplyToJob + triggers ==';

DECLARE @TestClientId INT;
DECLARE @TestEngineerId INT;
DECLARE @NewJobId INT;

SELECT TOP 1 @TestClientId = client_id
FROM dbo.tbl_Client_Profile
ORDER BY client_id;

SELECT TOP 1 @TestEngineerId = engineer_id
FROM dbo.tbl_Engineer_Profile
ORDER BY engineer_id;

IF @TestClientId IS NOT NULL AND @TestEngineerId IS NOT NULL
BEGIN
    PRINT 'Creating a new test job for client ' + CAST(@TestClientId AS NVARCHAR(20));

    EXEC dbo.sp_CreateJob
        @ClientId       = @TestClientId,
        @JobTitle       = N'Test Job from test.sql',
        @JobDescription = N'Smoke-test job created by test.sql',
        @Status         = N'open';

    -- Get latest job_id (the one we just created)
    SELECT @NewJobId = MAX(job_id)
    FROM dbo.tbl_Job
    WHERE client_id = @TestClientId;

    PRINT 'New job created with job_id = ' + CAST(@NewJobId AS NVARCHAR(20));

    PRINT 'Engineer ' + CAST(@TestEngineerId AS NVARCHAR(20)) + ' applying to that job via sp_ApplyToJob...';
    EXEC dbo.sp_ApplyToJob
        @EngineerId = @TestEngineerId,
        @JobId      = @NewJobId;

    PRINT 'Marking this application as accepted via sp_UpdateApplicationStatus (should trigger job status change)...';
    EXEC dbo.sp_UpdateApplicationStatus
        @EngineerId = @TestEngineerId,
        @JobId      = @NewJobId,
        @NewStatus  = N'accepted',
        @UpdatedBy  = @TestClientId;  -- just any valid user id

    PRINT 'Check job status (should be in_progress due to trigger trg_JobApplication_AfterUpdate):';
    SELECT job_id, job_title, status, updated_at
    FROM dbo.tbl_Job
    WHERE job_id = @NewJobId;
END
ELSE
BEGIN
    PRINT 'SKIPPING 6.2: Could not find a client or engineer to run the workflow.';
END;

SELECT TOP 1 *
FROM dbo.tbl_Job
ORDER BY job_id DESC;

SELECT *
FROM dbo.tbl_Job_Application
WHERE job_id = 200001;


SELECT job_id, client_id, job_title, job_description, status, created_at
FROM dbo.tbl_Job
WHERE client_id = 150003
ORDER BY job_id DESC;

-----------------------------
-- 6.3 Matching engine: sp_MatchEngineersToJob
-----------------------------
PRINT '== 6.3 sp_MatchEngineersToJob on a random open job ==';
DECLARE @AnyOpenJobId INT;

SELECT TOP 1 @AnyOpenJobId = job_id
FROM dbo.tbl_Job
WHERE status = 'open'
ORDER BY job_id;

IF @AnyOpenJobId IS NOT NULL AND OBJECT_ID('dbo.sp_MatchEngineersToJob','P') IS NOT NULL
BEGIN
    PRINT 'Running sp_MatchEngineersToJob for job_id = ' + CAST(@AnyOpenJobId AS NVARCHAR(20));
    EXEC dbo.sp_MatchEngineersToJob
        @JobId = @AnyOpenJobId,
        @TopN  = 10;

    PRINT 'Top candidates for that job (from vw_JobCandidatesRanked):';
    SELECT *
    FROM dbo.vw_JobCandidatesRanked
    WHERE job_id = @AnyOpenJobId
    ORDER BY candidate_rank;
END
ELSE
BEGIN
    PRINT 'SKIPPING 6.3: No open job or sp_MatchEngineersToJob missing.';
END;

-----------------------------
-- 6.4 Vetting pipeline: sp_CreateVettingReview + sp_FinaliseVettingDecision
-----------------------------
PRINT '== 6.4 Vetting pipeline check (sp_CreateVettingReview / sp_FinaliseVettingDecision) ==';
DECLARE @PendingEngineerId INT;
DECLARE @AdminReviewerId INT;

SELECT TOP 1 @PendingEngineerId = engineer_id
FROM dbo.tbl_Engineer_Profile
WHERE vet_status = 'pending';

SELECT TOP 1 @AdminReviewerId = user_id
FROM dbo.tbl_User
WHERE role = 'admin'
ORDER BY user_id;

IF @PendingEngineerId IS NOT NULL AND @AdminReviewerId IS NOT NULL
BEGIN
    PRINT 'Submitting a positive vetting review for pending engineer ' + CAST(@PendingEngineerId AS NVARCHAR(20));

    EXEC dbo.sp_CreateVettingReview
        @EngineerId         = @PendingEngineerId,
        @ReviewerId         = @AdminReviewerId,
        @ReviewStatus       = N'recommended',
        @SkillsVerified     = 1,
        @ExperienceVerified = 1,
        @PortfolioVerified  = 1,
        @ReviewNotes        = N'Test review via test.sql',
        @RejectionReason    = NULL;

    PRINT 'Engineer vet_status after review:';
    SELECT engineer_id, vet_status, updated_at
    FROM dbo.tbl_Engineer_Profile
    WHERE engineer_id = @PendingEngineerId;
END
ELSE
BEGIN
    PRINT 'SKIPPING 6.4: Could not find a pending engineer or admin reviewer.';
END;

-----------------------------
-- 6.5 sp_GetEngineerStats
-----------------------------
PRINT '== 6.5 sp_GetEngineerStats for a sample engineer ==';
DECLARE @StatsEngineerId INT;

SELECT TOP 1 @StatsEngineerId = engineer_id
FROM dbo.tbl_Engineer_Profile
ORDER BY engineer_id;

IF @StatsEngineerId IS NOT NULL AND OBJECT_ID('dbo.sp_GetEngineerStats','P') IS NOT NULL
BEGIN
    EXEC dbo.sp_GetEngineerStats @EngineerId = @StatsEngineerId;
END
ELSE
BEGIN
    PRINT 'SKIPPING 6.5: sp_GetEngineerStats or engineer not found.';
END;

-----------------------------
-- 6.6 sp_GetMonthlyPlatformStats
-----------------------------
PRINT '== 6.6 sp_GetMonthlyPlatformStats for current year ==';
IF OBJECT_ID('dbo.sp_GetMonthlyPlatformStats','P') IS NOT NULL
BEGIN
    DECLARE @CurrentYear INT = YEAR(SYSDATETIME());
    EXEC dbo.sp_GetMonthlyPlatformStats @Year = @CurrentYear;
END
ELSE
BEGIN
    PRINT 'sp_GetMonthlyPlatformStats not found.';
END;

------------------------------------------------------------
-- 7. Time sanity checks (no future-created rows)
------------------------------------------------------------

PRINT '== 7.1 tbl_User.created_at in the future ==';
SELECT TOP 50 *
FROM dbo.tbl_User
WHERE created_at > SYSDATETIME();

PRINT '== 7.2 tbl_Job_Application.created_at in the future ==';
SELECT TOP 50 *
FROM dbo.tbl_Job_Application
WHERE created_at > SYSDATETIME();

PRINT '== 7.3 tbl_Job.created_at in the future ==';
SELECT TOP 50 *
FROM dbo.tbl_Job
WHERE created_at > SYSDATETIME();

------------------------------------------------------------
-- End
------------------------------------------------------------

PRINT '============================================================';
PRINT 'BridgewayDB Smoke Test Completed.';
PRINT '============================================================';

SET NOCOUNT OFF;
GO
