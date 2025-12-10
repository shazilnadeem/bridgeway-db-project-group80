USE BridgewayDB;
GO
------------------------------------------------------------
-- Taimur - Matching Engine & Eligibility Module
-- Responsibilities:
--   * Decide which engineers are eligible for which jobs
--   * Compute match_score for engineer-job pairs
--   * Populate/refresh tbl_Job_Application with ranked candidates
--   * Provide views for top candidates per job
------------------------------------------------------------

/******************************************************************************
    MODULE OWNER: Taimur
    MODULE NAME: Matching Engine & Eligibility
    DB: BridgewayDB

    This file uses:
        tbl_Job
        tbl_Job_Skills
        tbl_Engineer_Profile
        tbl_Engineer_Skills
        tbl_Job_Application
        tbl_Endorsement_Ratings
        tbl_Engineer_RatingCache
        tbl_Skill
******************************************************************************/

/******************************************************************************
    SAFETY DROPS
******************************************************************************/
IF OBJECT_ID('dbo.vw_JobCandidatesRanked','V') IS NOT NULL DROP VIEW dbo.vw_JobCandidatesRanked;
IF OBJECT_ID('dbo.vw_OpenJobsWithTopCandidate','V') IS NOT NULL DROP VIEW dbo.vw_OpenJobsWithTopCandidate;
IF OBJECT_ID('dbo.sp_MatchEngineersToJob','P') IS NOT NULL DROP PROCEDURE dbo.sp_MatchEngineersToJob;
IF OBJECT_ID('dbo.sp_RefreshMatchesForAllOpenJobs','P') IS NOT NULL DROP PROCEDURE dbo.sp_RefreshMatchesForAllOpenJobs;
IF OBJECT_ID('dbo.fn_CalculateMatchScore','IF') IS NOT NULL DROP FUNCTION dbo.fn_CalculateMatchScore;
IF OBJECT_ID('dbo.fn_IsEngineerEligibleForJob','IF') IS NOT NULL DROP FUNCTION dbo.fn_IsEngineerEligibleForJob;
GO

/******************************************************************************
    5. FUNCTIONS (Inline TVFs)
******************************************************************************/

--------------------------------------------------------------------------------
-- 5.1 fn_IsEngineerEligibleForJob (INLINE TVF)
--     Returns one row containing eligibility + required data for scoring.
--------------------------------------------------------------------------------
CREATE FUNCTION dbo.fn_IsEngineerEligibleForJob
(
    @EngineerId INT,
    @JobId INT
)
RETURNS TABLE
AS
RETURN
(
    WITH JobInfo AS
    (
        SELECT job_id, status AS job_status, timezone AS job_timezone
        FROM dbo.tbl_Job
        WHERE job_id = @JobId
    ),
    EngInfo AS
    (
        SELECT engineer_id, vet_status, years_experience,
               availability_status_id, timezone AS eng_timezone
        FROM dbo.tbl_Engineer_Profile
        WHERE engineer_id = @EngineerId
    ),
    RequiredSkills AS
    (
        SELECT COUNT(*) AS total_required
        FROM dbo.tbl_Job_Skills
        WHERE job_id = @JobId
          AND LOWER(importance_level) = 'required'
    ),
    PreferredSkills AS
    (
        SELECT COUNT(*) AS total_preferred
        FROM dbo.tbl_Job_Skills
        WHERE job_id = @JobId
          AND LOWER(importance_level) = 'preferred'
    ),
    MatchedRequired AS
    (
        SELECT COUNT(*) AS matched_required
        FROM dbo.tbl_Engineer_Skills es
        JOIN dbo.tbl_Job_Skills js ON es.skill_id = js.skill_id
        WHERE es.engineer_id = @EngineerId
          AND js.job_id = @JobId
          AND LOWER(js.importance_level) = 'required'
    ),
    MatchedPreferred AS
    (
        SELECT COUNT(*) AS matched_preferred
        FROM dbo.tbl_Engineer_Skills es
        JOIN dbo.tbl_Job_Skills js ON es.skill_id = js.skill_id
        WHERE es.engineer_id = @EngineerId
          AND js.job_id = @JobId
          AND LOWER(js.importance_level) = 'preferred'
    ),
    Rating AS
    (
        SELECT avg_rating, rating_count
        FROM dbo.tbl_Engineer_RatingCache
        WHERE engineer_id = @EngineerId
    ),
    Rejected AS
    (
        SELECT 1 AS was_rejected
        FROM dbo.tbl_Job_Application
        WHERE job_id = @JobId
          AND engineer_id = @EngineerId
          AND LOWER(status) = 'rejected'
    )
    SELECT
        @EngineerId AS engineer_id,
        @JobId AS job_id,

        -- main eligibility
        CASE
            WHEN EngInfo.engineer_id IS NULL THEN 0
            WHEN JobInfo.job_id IS NULL THEN 0
            WHEN LOWER(JobInfo.job_status) <> 'open' THEN 0
            WHEN LOWER(EngInfo.vet_status) <> 'approved' THEN 0
            WHEN COALESCE(mr.matched_required,0) = 0
                 AND COALESCE(mp.matched_preferred,0) = 0 THEN 0
            WHEN COALESCE(rj.was_rejected,0) = 1 THEN 0
            ELSE 1
        END AS is_eligible,

        -- For scoring
        COALESCE(mr.matched_required,0)   AS matched_required,
        COALESCE(rs.total_required,0)     AS total_required,
        COALESCE(mp.matched_preferred,0)  AS matched_preferred,
        COALESCE(ps.total_preferred,0)    AS total_preferred,
        EngInfo.years_experience,
        COALESCE(rt.avg_rating,0)         AS avg_rating,
        COALESCE(rt.rating_count,0)       AS rating_count,
        EngInfo.availability_status_id,
        EngInfo.eng_timezone,
        JobInfo.job_timezone
    FROM JobInfo
    FULL JOIN EngInfo ON 1 = 1
    CROSS JOIN RequiredSkills rs
    CROSS JOIN PreferredSkills ps
    CROSS JOIN MatchedRequired mr
    CROSS JOIN MatchedPreferred mp
    LEFT JOIN Rating   rt ON 1 = 1
    LEFT JOIN Rejected rj ON 1 = 1
);
GO
--------------------------------------------------------------------------------
-- 5.2 fn_CalculateMatchScore (INLINE TVF)  -- with timezone soft factor
--------------------------------------------------------------------------------
CREATE FUNCTION dbo.fn_CalculateMatchScore
(
    @EngineerId INT,
    @JobId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        e.engineer_id,
        e.job_id,
        CASE 
            WHEN e.is_eligible = 0 THEN 0.0
            ELSE
                ROUND(
                (
                    -- Required skills (45%)
                    0.45 * CASE 
                               WHEN e.total_required = 0 THEN 1.0
                               ELSE CAST(e.matched_required AS FLOAT) /
                                    NULLIF(e.total_required, 0)
                           END

                    -- Preferred skills (20%)
                    + 0.20 * CASE
                                 WHEN e.total_preferred = 0 THEN 0.0
                                 ELSE CAST(e.matched_preferred AS FLOAT) /
                                      NULLIF(e.total_preferred, 0)
                             END

                    -- Experience factor (20%) capped at 1.0 for >=5 years
                    + 0.20 * CASE 
                                 WHEN e.years_experience IS NULL THEN 0.0
                                 ELSE 
                                     CASE 
                                         WHEN CAST(e.years_experience AS FLOAT) / 5.0 < 1.0 
                                             THEN CAST(e.years_experience AS FLOAT) / 5.0
                                         ELSE 1.0
                                     END
                             END

                    -- Rating factor (10%) scaled from 1–5 -> 0–1
                    + 0.10 * CASE 
                                 WHEN e.avg_rating <= 0 THEN 0.0
                                 ELSE ( (e.avg_rating - 1.0) / 4.0 )
                             END

                    -- Timezone factor (5%) - SOFT factor
                    + 0.05 *
                      CASE
                          -- unknown timezones → neutral-ish
                          WHEN e.eng_timezone IS NULL OR e.job_timezone IS NULL THEN 0.6

                          -- exact timezone match
                          WHEN e.eng_timezone = e.job_timezone THEN 1.0

                          -- same region (e.g. 'Asia/Karachi' vs 'Asia/Dubai')
                          WHEN LEFT(e.eng_timezone,
                                    CHARINDEX('/', e.eng_timezone + '/') - 1)
                               = 
                               LEFT(e.job_timezone,
                                    CHARINDEX('/', e.job_timezone + '/') - 1)
                          THEN 0.8

                          -- very different timezones
                          ELSE 0.4
                      END
                ) * 100, 2)
        END AS match_score
    FROM dbo.fn_IsEngineerEligibleForJob(@EngineerId, @JobId) e
);
GO


/******************************************************************************
    6. VIEWS
******************************************************************************/

--------------------------------------------------------------------------------
-- 6.1 vw_JobCandidatesRanked
--------------------------------------------------------------------------------
CREATE VIEW dbo.vw_JobCandidatesRanked
AS
SELECT
    ja.job_id,
    j.job_title,
    j.client_id,
    ja.engineer_id,

    u.full_name AS engineer_name,
    ja.match_score,
    ja.status AS application_status,

    ep.vet_status,
    ep.years_experience,
    ep.availability_status_id,
    ep.timezone AS engineer_timezone,
    ep.portfolio_link,

    ISNULL(rc.avg_rating,0)   AS avg_rating,
    ISNULL(rc.rating_count,0) AS rating_count,

    ROW_NUMBER() OVER (
        PARTITION BY ja.job_id 
        ORDER BY ja.match_score DESC, ja.updated_at DESC
    ) AS candidate_rank

FROM dbo.tbl_Job_Application ja
JOIN dbo.tbl_Job             j  ON ja.job_id = j.job_id
JOIN dbo.tbl_Engineer_Profile ep ON ja.engineer_id = ep.engineer_id
JOIN dbo.tbl_User            u  ON ep.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Engineer_RatingCache rc 
       ON rc.engineer_id = ep.engineer_id;
GO

--------------------------------------------------------------------------------
-- 6.2 vw_OpenJobsWithTopCandidate
--------------------------------------------------------------------------------
CREATE VIEW dbo.vw_OpenJobsWithTopCandidate
AS
WITH ranked AS
(
    SELECT
        ja.job_id,
        ja.engineer_id,
        ja.match_score,
        ROW_NUMBER() OVER (
            PARTITION BY ja.job_id 
            ORDER BY ja.match_score DESC
        ) AS rn
    FROM dbo.tbl_Job_Application ja
    JOIN dbo.tbl_Job j ON ja.job_id = j.job_id
    WHERE LOWER(j.status) = 'open'
)
SELECT
    j.job_id,
    j.job_title,
    j.client_id,
    r.engineer_id AS top_engineer_id,
    u.full_name   AS top_engineer_name,
    r.match_score AS top_match_score
FROM ranked r
JOIN dbo.tbl_Job j ON r.job_id = j.job_id
LEFT JOIN dbo.tbl_User u ON r.engineer_id = u.user_id
WHERE r.rn = 1;
GO


/******************************************************************************
    7. STORED PROCEDURES
******************************************************************************/

--------------------------------------------------------------------------------
-- 7.1 sp_MatchEngineersToJob
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_MatchEngineersToJob
(
    @JobId INT,
    @TopN INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        ----------------------------------------------
        -- 1. Pre-filter engineers who share any skill
        ----------------------------------------------
        ;WITH EngSkill AS
        (
            SELECT DISTINCT es.engineer_id
            FROM dbo.tbl_Engineer_Skills es
            JOIN dbo.tbl_Job_Skills js ON es.skill_id = js.skill_id
            WHERE js.job_id = @JobId
        ),
        Scores AS
        (
            SELECT 
                s.engineer_id,
                s.job_id,
                s.match_score,
                ROW_NUMBER() OVER (ORDER BY s.match_score DESC, s.engineer_id ASC) AS rn
            FROM EngSkill es
            CROSS APPLY dbo.fn_CalculateMatchScore(es.engineer_id, @JobId) s
            WHERE s.match_score > 0
        ),
        TopCandidates AS
        (
            SELECT engineer_id, job_id, match_score
            FROM Scores
            WHERE @TopN IS NULL OR rn <= @TopN
        )
        MERGE dbo.tbl_Job_Application AS tgt
        USING TopCandidates AS src
            ON tgt.engineer_id = src.engineer_id
           AND tgt.job_id     = src.job_id
        
        WHEN MATCHED AND (tgt.match_score <> src.match_score)
            THEN UPDATE SET match_score = src.match_score,
                            updated_at  = SYSUTCDATETIME()

        WHEN NOT MATCHED BY TARGET
            THEN INSERT(engineer_id, job_id, match_score, status, created_at)
                 VALUES(src.engineer_id, src.job_id, src.match_score, 'pending', SYSUTCDATETIME());
        
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('sp_MatchEngineersToJob FAILED: %s', 16, 1, @ErrMsg);
        RETURN;
    END CATCH
END;
GO

--------------------------------------------------------------------------------
-- 7.2 sp_RefreshMatchesForAllOpenJobs
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_RefreshMatchesForAllOpenJobs
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @jid INT;

    DECLARE job_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT job_id 
        FROM dbo.tbl_Job 
        WHERE LOWER(status) = 'open';

    OPEN job_cursor;
    FETCH NEXT FROM job_cursor INTO @jid;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_MatchEngineersToJob @JobId = @jid;
        FETCH NEXT FROM job_cursor INTO @jid;
    END

    CLOSE job_cursor;
    DEALLOCATE job_cursor;
END;
GO

/******************************************************************************
    END OF TAIMUR MODULE
******************************************************************************/
