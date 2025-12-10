-- -- -- SELECT TOP 10 * FROM dbo.tbl_Skill;
-- -- -- SELECT * FROM dbo.tbl_User WHERE role = 'admin';


-- -- -- SELECT name, type_desc 
-- -- -- FROM sys.partition_functions 
-- -- -- WHERE name = 'pf_JobApplicationByYear';

-- -- -- SELECT name 
-- -- -- FROM sys.partition_schemes 
-- -- -- WHERE name = 'ps_JobApplicationScheme';



-- -- -- EXEC sp_help 'dbo.tbl_Job_Application';




-- -- -- SELECT name, type_desc
-- -- -- FROM sys.objects
-- -- -- WHERE name IN (
-- -- --     'sp_GGenerateTestData',
-- -- --     'sp_GetMonthlyPlatformStats',
-- -- --     'sp_RebuildIndexesAndStats'
-- -- -- );




-- -- -- EXEC dbo.sp_GGenerateTestData
-- -- --     @NumEngineers           = 50,
-- -- --     @NumClients             = 10,
-- -- --     @NumJobs                = 30,
-- -- --     @AvgSkillsPerEngineer   = 5,
-- -- --     @AvgSkillsPerJob        = 3,
-- -- --     @ApplicationsPerJob     = 5;



-- -- -- SELECT COUNT(*) AS Engineers FROM dbo.tbl_Engineer_Profile;
-- -- -- SELECT COUNT(*) AS Clients FROM dbo.tbl_Client_Profile;
-- -- -- SELECT COUNT(*) AS Jobs FROM dbo.tbl_Job;
-- -- -- SELECT COUNT(*) AS Applications FROM dbo.tbl_Job_Application;




-- -- -- SELECT
-- -- --     $PARTITION.pf_JobApplicationByYear(created_at) AS partition_number,
-- -- --     COUNT(*) AS row_count
-- -- -- FROM dbo.tbl_Job_Application
-- -- -- GROUP BY $PARTITION.pf_JobApplicationByYear(created_at)
-- -- -- ORDER BY partition_number;


-- -- EXEC dbo.sp_GGenerateTestData
-- --     @NumEngineers         = 1000,
-- --     @NumClients           = 200,
-- --     @NumJobs              = 800,
-- --     @AvgSkillsPerEngineer = 5,
-- --     @AvgSkillsPerJob      = 4,
-- --     @ApplicationsPerJob   = 6;


-- -- -- SELECT COUNT(*) AS Engineers FROM dbo.tbl_Engineer_Profile;
-- -- -- SELECT COUNT(*) AS Clients FROM dbo.tbl_Client_Profile;
-- -- -- SELECT COUNT(*) AS Jobs FROM dbo.tbl_Job;
-- -- -- SELECT COUNT(*) AS Applications FROM dbo.tbl_Job_Application;
-- -- -- SELECT COUNT(*) AS VetReviews FROM dbo.tbl_Vetting_Reviews;
-- -- -- SELECT COUNT(*) AS Ratings FROM dbo.tbl_Endorsement_Ratings;


-- -- -- SELECT TOP 10 * FROM dbo.vw_EngineerSearchIndex;

-- -- -- EXEC dbo.sp_SearchEngineersByFilters
-- -- --     @SkillIdList   = '1,2',
-- -- --     @MinExperience = 3,
-- -- --     @Location      = N'Lahore',
-- -- --     @MinRating     = 3.5,
-- -- --     @VetStatus     = N'approved',
-- -- --     @Page          = 1,
-- -- --     @PageSize      = 10;

-- -- -- EXEC dbo.sp_GetEngineerStats @EngineerId = 3;

-- -- EXEC dbo.sp_CreateJob 
-- --     @ClientId = 1003,
-- --     @JobTitle = 'Backend Developer',
-- --     @JobDescription = 'API work',
-- --     @Status = 'open';


-- -- SELECT TOP 20 client_id, company_name, industry
-- -- FROM dbo.tbl_Client_Profile
-- -- ORDER BY client_id;

-- -- SELECT TOP 5 * FROM dbo.vw_JobWithClientAndSkills ORDER BY job_id DESC;
-- -- SELECT TOP 10 * FROM dbo.vw_ApplicationsSummaryByJob;


-- -- EXEC sp_help 'dbo.tbl_Engineer_Profile';
-- -- EXEC sp_help 'dbo.tbl_Availability_Status';
-- -- EXEC sp_help 'dbo.tbl_Engineer_Skills';
-- -- EXEC sp_help 'dbo.tbl_Job_Application';


-- -- SELECT * FROM dbo.tbl_Skill;
-- -- SELECT * FROM dbo.tbl_Availability_Status;
-- -- SELECT * FROM dbo.tbl_User WHERE role = 'admin';


-- -- EXEC dbo.sp_GGenerateTestData
-- --      @NumEngineers = 100,
-- --      @NumClients = 20,
-- --      @NumJobs = 50,
-- --      @AvgSkillsPerEngineer = 5,
-- --      @AvgSkillsPerJob = 3,
-- --      @ApplicationsPerJob = 5;


-- -- SELECT 
-- --     YEAR(created_at) AS yr,
-- --     COUNT(*) AS rows_per_year
-- -- FROM dbo.tbl_Job_Application
-- -- GROUP BY YEAR(created_at)
-- -- ORDER BY yr;


-- -- SELECT TOP 1 client_id FROM dbo.tbl_Client_Profile;

-- -- EXEC dbo.sp_CreateJob
-- --      @ClientId = 103,
-- --      @JobTitle = 'Backend Dev',
-- --      @JobDescription = 'Testing job creation',
-- --      @Status = 'open';

-- -- SELECT TOP 1 engineer_id FROM dbo.tbl_Engineer_Profile;

-- -- EXEC dbo.sp_ApplyToJob @EngineerId = 4, @JobId = 1;


-- -- EXEC dbo.sp_UpdateApplicationStatus
-- --      @EngineerId = 1,
-- --      @JobId = 1,
-- --      @NewStatus = 'accepted',
-- --      @UpdatedBy = 1;


-- -- SELECT status FROM dbo.tbl_Job WHERE job_id = 1;


-- -- EXEC dbo.sp_SearchEngineersByFilters
-- --      @SkillIdList = '1',
-- --      @MinExperience = 3,
-- --      @Timezone = 'UTC',
-- --      @VetStatus = 'approved',
-- --      @Page = 1,
-- --      @PageSize = 10;


-- -- EXEC dbo.sp_GetEngineerStats @EngineerId = 4;



-- USE BridgewayDB;
-- GO

-- EXEC dbo.sp_GGenerateTestData
--      @NumEngineers         = 100,
--      @NumClients           = 20,
--      @NumJobs              = 50,
--      @AvgSkillsPerEngineer = 5,
--      @AvgSkillsPerJob      = 4,
--      @ApplicationsPerJob   = 5;


-- SELECT TOP 1 job_id FROM dbo.tbl_Job;
-- -- suppose it returns 1

-- EXEC dbo.sp_MatchEngineersToJob @JobId = 21, @TopN = 10;

-- SELECT TOP 10 *
-- FROM dbo.vw_JobCandidatesRanked
-- WHERE job_id = 21
-- ORDER BY candidate_rank;


-- EXEC dbo.sp_RefreshMatchesForAllOpenJobs;

-- SELECT TOP 10 * 
-- FROM dbo.vw_OpenJobsWithTopCandidate
-- ORDER BY top_match_score DESC;



USE BridgewayDB;
GO

-- (1) Generate data if needed
-- EXEC dbo.sp_GGenerateTestData ...   -- only if tables are empty

-- (2) Refresh matches for ONE job
EXEC dbo.sp_MatchEngineersToJob @JobId = 21, @TopN = 10;

SELECT TOP 10 *
FROM dbo.vw_JobCandidatesRanked
WHERE job_id = 21
ORDER BY candidate_rank;

-- (3) Refresh ALL open jobs
EXEC dbo.sp_RefreshMatchesForAllOpenJobs;

SELECT TOP 10 *
FROM dbo.vw_OpenJobsWithTopCandidate
ORDER BY top_match_score DESC;

SELECT * FROM dbo.fn_IsEngineerEligibleForJob(3, 21);

DELETE FROM tbl_Job_Application
WHERE job_id = 21 AND engineer_id = 3;

-- 1) Check the job status
SELECT job_id, status
FROM dbo.tbl_Job
WHERE job_id = 21;

UPDATE dbo.tbl_Job
SET status = 'open'
WHERE job_id = 21;

-- Check eligibility again
SELECT * 
FROM dbo.fn_IsEngineerEligibleForJob(3, 21);

-- Check the score directly
SELECT * 
FROM dbo.fn_CalculateMatchScore(3, 21);

-- Rebuild matches for that job
EXEC dbo.sp_MatchEngineersToJob @JobId = 21, @TopN = 10;

-- See ranked candidates
SELECT TOP 10 *
FROM dbo.vw_JobCandidatesRanked
WHERE job_id = 21
ORDER BY candidate_rank;


SELECT *, 
       CASE WHEN is_eligible = 1 THEN 'YES' ELSE 'NO' END AS EligibleFlag
FROM dbo.fn_IsEngineerEligibleForJob(3, 21);


SELECT e.engineer_id, f.*
FROM tbl_Engineer_Profile e
CROSS APPLY dbo.fn_IsEngineerEligibleForJob(e.engineer_id, 21) f
WHERE f.is_eligible = 1;


SELECT *
FROM tbl_Engineer_Profile e
CROSS APPLY dbo.fn_CalculateMatchScore(e.engineer_id, 21) s
WHERE s.match_score > 0
ORDER BY s.match_score DESC;
