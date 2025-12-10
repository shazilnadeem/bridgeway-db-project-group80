------------------------------------------------------------
-- group80_p2_master.sql (Base Schema)
-- Bridgeway Database - Phase 2
-- Muhammad Shazil Nadeem (27100183), Taimur Jahanzeb (27100028), Haider Wajahat (27100252), Areeba Naveed (27100239), Syed Zaid Ahmed (27100192)
------------------------------------------------------------

------------------------------------------------------------
-- 0. Create / Reset Database
-- Purpose: Recreate BridgewayDB from scratch for clean runs
------------------------------------------------------------
USE master;
GO

IF DB_ID('BridgewayDB') IS NOT NULL
BEGIN
    ALTER DATABASE BridgewayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BridgewayDB;
END
GO

CREATE DATABASE BridgewayDB;
GO

USE BridgewayDB;
GO

------------------------------------------------------------
-- 1. Table Definitions (Schema)
-- Owner: Base Schema (do not edit in individual files)
------------------------------------------------------------

-----------------------------
-- tbl_User
-- Stores all platform users (engineers, clients, admins)
-----------------------------
CREATE TABLE dbo.tbl_User (
    user_id      INT IDENTITY(1,1) CONSTRAINT PK_User PRIMARY KEY,
    full_name    NVARCHAR(150) NOT NULL,
    email        NVARCHAR(255) NOT NULL UNIQUE,
    password     NVARCHAR(255) NOT NULL,
    role         NVARCHAR(20)  NOT NULL,   -- 'engineer' / 'client' / 'admin'
    created_at   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2     NULL,
    CONSTRAINT CK_User_Role CHECK (role IN ('engineer','client','admin'))
);

-----------------------------
-- tbl_Availability_Status
-- Lookup for engineer availability types
-----------------------------
CREATE TABLE dbo.tbl_Availability_Status (
    status_id   INT IDENTITY(1,1) PRIMARY KEY,
    status_name NVARCHAR(50) NOT NULL UNIQUE
        -- examples: 'full-time', 'part-time', 'contract',
        --           'immediately available', 'open to offers', 'unavailable'
);

-----------------------------
-- tbl_Engineer_Profile
-- 1:1 extension of tbl_User for engineers
-----------------------------
CREATE TABLE dbo.tbl_Engineer_Profile (
    engineer_id           INT        NOT NULL,  -- 1:1 with tbl_User.user_id
    years_experience      INT        NOT NULL,
    timezone              NVARCHAR(64) NULL,
    availability_status_id INT      NOT NULL,
    vet_status            NVARCHAR(20)  NOT NULL,  -- 'pending','approved','rejected'
    portfolio_link        NVARCHAR(255) NULL,
    created_at            DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    updated_at            DATETIME2     NULL,
    CONSTRAINT PK_Engineer_Profile PRIMARY KEY (engineer_id),
    CONSTRAINT FK_ENGINEER_Availability
        FOREIGN KEY (availability_status_id) REFERENCES dbo.tbl_Availability_Status(status_id),
    CONSTRAINT FK_Engineer_Profile_User
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_User(user_id),
    CONSTRAINT CK_Engineer_Profile_VetStatus
        CHECK (vet_status IN ('pending','approved','rejected'))
);

-----------------------------
-- tbl_Client_Profile
-- 1:1 extension of tbl_User for clients
-----------------------------
CREATE TABLE dbo.tbl_Client_Profile (
    client_id     INT           NOT NULL,  -- 1:1 with tbl_User.user_id
    company_name  NVARCHAR(200) NOT NULL,
    industry      NVARCHAR(100) NULL,
    created_at    DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    updated_at    DATETIME2     NULL,
    CONSTRAINT PK_Client_Profile PRIMARY KEY (client_id),
    CONSTRAINT FK_Client_Profile_User
        FOREIGN KEY (client_id) REFERENCES dbo.tbl_User(user_id)
);

-----------------------------
-- tbl_Skill
-- Master list of skills used for engineers and jobs
-----------------------------
CREATE TABLE dbo.tbl_Skill (
    skill_id    INT IDENTITY(1,1) CONSTRAINT PK_Skill PRIMARY KEY,
    skill_name  NVARCHAR(100) NOT NULL,
    category    NVARCHAR(100) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

-----------------------------
-- tbl_Engineer_Skills
-- Bridge table between engineers and skills
-----------------------------
CREATE TABLE dbo.tbl_Engineer_Skills (
    engineer_id       INT      NOT NULL,
    skill_id          INT      NOT NULL,
    proficiency_score TINYINT  NOT NULL,  -- 1..10
    created_at        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Engineer_Skills PRIMARY KEY (engineer_id, skill_id),
    CONSTRAINT FK_Engineer_Skills_Engineer
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_Engineer_Profile(engineer_id),
    CONSTRAINT FK_Engineer_Skills_Skill
        FOREIGN KEY (skill_id) REFERENCES dbo.tbl_Skill(skill_id)
);

-----------------------------
-- tbl_Job
-- Job postings created by clients
-----------------------------
CREATE TABLE dbo.tbl_Job (
    job_id          INT IDENTITY(1,1) CONSTRAINT PK_Job PRIMARY KEY,
    client_id       INT            NOT NULL,  -- FK to client profile
    job_title       NVARCHAR(200)  NOT NULL,
    job_description NVARCHAR(MAX) NULL,
    status          NVARCHAR(20)   NOT NULL,  -- 'open','in_progress','closed'
    timezone        NVARCHAR(64)   NULL,
    created_at      DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2      NULL,
    CONSTRAINT FK_Job_Client
        FOREIGN KEY (client_id) REFERENCES dbo.tbl_Client_Profile(client_id),
    CONSTRAINT CK_Job_Status
        CHECK (status IN ('open','in_progress','closed'))
);

-----------------------------
-- tbl_Job_Skills
-- Required / preferred skills for each job
-----------------------------
CREATE TABLE dbo.tbl_Job_Skills (
    job_id           INT          NOT NULL,
    skill_id         INT          NOT NULL,
    importance_level NVARCHAR(20) NOT NULL,  -- 'required','preferred'
    created_at       DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Job_Skills PRIMARY KEY (job_id, skill_id),
    CONSTRAINT FK_Job_Skills_Job
        FOREIGN KEY (job_id) REFERENCES dbo.tbl_Job(job_id),
    CONSTRAINT FK_Job_Skills_Skill
        FOREIGN KEY (skill_id) REFERENCES dbo.tbl_Skill(skill_id),
    CONSTRAINT CK_Job_Skills_Importance
        CHECK (importance_level IN ('required','preferred'))
);

-----------------------------
-- tbl_Job_Application
-- Applications / matches between engineers and jobs
-- (Base definition; later replaced by partitioned version)
-----------------------------
CREATE TABLE dbo.tbl_Job_Application (
    engineer_id  INT          NOT NULL,
    job_id       INT          NOT NULL,
    match_score  DECIMAL(5,2) NULL,   -- 0.00 - 999.99
    status       NVARCHAR(20) NOT NULL,  -- 'pending','shortlisted','accepted','rejected'
    created_at   DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2    NULL,
    CONSTRAINT PK_Job_Application PRIMARY KEY (engineer_id, job_id),
    CONSTRAINT FK_Job_Application_Engineer
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_Engineer_Profile(engineer_id),
    CONSTRAINT FK_Job_Application_Job
        FOREIGN KEY (job_id) REFERENCES dbo.tbl_Job(job_id),
    CONSTRAINT CK_Job_Application_Status
        CHECK (status IN ('pending','shortlisted','accepted','rejected'))
);

-----------------------------
-- tbl_Vetting_Reviews
-- Stores admin vetting decisions and checks for engineers
-----------------------------
CREATE TABLE dbo.tbl_Vetting_Reviews (
    review_id           INT IDENTITY(1,1) CONSTRAINT PK_Vetting_Reviews PRIMARY KEY,
    engineer_id         INT           NOT NULL,
    review_status       NVARCHAR(50)  NOT NULL,
    skills_verified     BIT           NOT NULL DEFAULT 0,
    experience_verified BIT           NOT NULL DEFAULT 0,
    portfolio_verified  BIT           NOT NULL DEFAULT 0,
    review_notes        NVARCHAR(MAX) NULL,
    rejection_reason    NVARCHAR(MAX) NULL,
    reviewed_by         INT           NULL,  -- FK to tbl_User (admin)
    submitted_at        DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    reviewed_at         DATETIME2     NULL,
    CONSTRAINT FK_Vetting_Reviews_Engineer
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_Engineer_Profile(engineer_id),
    CONSTRAINT FK_Vetting_Reviews_Reviewer
        FOREIGN KEY (reviewed_by) REFERENCES dbo.tbl_User(user_id)
);

-----------------------------
-- tbl_Endorsement_Ratings
-- Client feedback and ratings for engineers
-----------------------------
CREATE TABLE dbo.tbl_Endorsement_Ratings (
    client_id   INT           NOT NULL,
    engineer_id INT           NOT NULL,
    rating      INT           NOT NULL,        -- e.g. 1-5
    comment     NVARCHAR(MAX) NULL,
    verified    BIT           NOT NULL DEFAULT 0,
    [date]      DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Endorsement_Ratings PRIMARY KEY (client_id, engineer_id),
    CONSTRAINT FK_Endorsement_Ratings_Client
        FOREIGN KEY (client_id)   REFERENCES dbo.tbl_Client_Profile(client_id),
    CONSTRAINT FK_Endorsement_Ratings_Engineer
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_Engineer_Profile(engineer_id),
    CONSTRAINT CK_Endorsement_Ratings_Rating
        CHECK (rating BETWEEN 1 AND 5)
);

-----------------------------
-- tbl_Engineer_RatingCache
-- Denormalised cache of average rating per engineer
-----------------------------
CREATE TABLE dbo.tbl_Engineer_RatingCache (
    engineer_id  INT PRIMARY KEY,
    avg_rating   DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    rating_count INT          NOT NULL DEFAULT 0,
    last_updated DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
);

------------------------------------------------------------
-- tbl_Engineer_Archive (Schema Extension)
-- Owner: Zaid
-- Purpose: Soft-delete storage for engineer profiles
------------------------------------------------------------
IF OBJECT_ID('dbo.tbl_Engineer_Archive', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_Engineer_Archive (
        archive_id             INT IDENTITY(1,1) PRIMARY KEY,
        engineer_id            INT NOT NULL,
        full_name              NVARCHAR(150) NULL,
        email                  NVARCHAR(255) NULL,
        years_experience       INT NULL,
        timezone               NVARCHAR(64) NULL,
        availability_status_id INT NULL,
        vet_status             NVARCHAR(20) NULL,
        portfolio_link         NVARCHAR(255) NULL,
        archived_at            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        reason                 NVARCHAR(MAX) NULL
    );
END
GO

------------------------------------------------------------
-- 2. Lookup / Enum Seed Data
-- Purpose: Shared static data needed by all features
-- Owner: Shazil
-- Notes:
--   - Only this section should insert base lookup values
--   - Other members can request new rows if required
------------------------------------------------------------

-- Seed availability statuses
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Availability_Status)
BEGIN
    INSERT INTO dbo.tbl_Availability_Status (status_name)
    VALUES
        (N'full-time'),
        (N'part-time'),
        (N'contract'),
        (N'immediately available'),
        (N'open to offers'),
        (N'unavailable');
END;
GO

-- Seed base skills
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Skill)
BEGIN
    INSERT INTO dbo.tbl_Skill (skill_name, category)
    VALUES
        (N'Python',             N'Backend'),
        (N'Java',               N'Backend'),
        (N'C#',                 N'Backend'),
        (N'JavaScript',         N'Frontend'),
        (N'TypeScript',         N'Frontend'),
        (N'HTML',               N'Frontend'),
        (N'CSS',                N'Frontend'),
        (N'React',              N'Frontend'),
        (N'Next.js',            N'Frontend'),
        (N'Angular',            N'Frontend'),
        (N'Node.js',            N'Backend'),
        (N'Express.js',         N'Backend'),
        (N'Django',             N'Backend'),
        (N'Flask',              N'Backend'),
        (N'.NET Core',          N'Backend'),
        (N'SQL',                N'Database'),
        (N'PostgreSQL',         N'Database'),
        (N'MySQL',              N'Database'),
        (N'MongoDB',            N'NoSQL'),
        (N'Azure',              N'Cloud'),
        (N'AWS',                N'Cloud'),
        (N'GCP',                N'Cloud'),
        (N'Docker',             N'DevOps'),
        (N'Kubernetes',         N'DevOps'),
        (N'CI/CD',              N'DevOps'),
        (N'Data Engineering',   N'Data'),
        (N'SQL Server',         N'Database'),
        (N'Machine Learning',   N'Data/ML'),
        (N'Deep Learning',      N'Data/ML'),
        (N'Computer Vision',    N'Data/ML'),
        (N'NLP',                N'Data/ML'),
        (N'Power BI',           N'Analytics'),
        (N'Tableau',            N'Analytics'),
        (N'Business Analysis',  N'Business'),
        (N'Product Management', N'Business');
END;
GO

-- Seed admin users (for vetting and platform management)
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_User WHERE role = 'admin')
BEGIN
    INSERT INTO dbo.tbl_User (full_name, email, password, role)
    VALUES
        (N'Bridgeway Admin 1', N'admin1@bridgeway.test', N'adminpass', 'admin'),
        (N'Bridgeway Admin 2', N'admin2@bridgeway.test', N'adminpass', 'admin');
END;
GO

------------------------------------------------------------
-- 3. Partitioning & Large-Table Design
-- Feature Owner: Shazil
-- Purpose:
--   - Partition tbl_Job_Application by year (created_at)
--   - Enable efficient archival and date-range queries
------------------------------------------------------------

-- Drop tbl_Job_Application if it already exists (base version from Section 1)
IF OBJECT_ID('dbo.tbl_Job_Application','U') IS NOT NULL
BEGIN
    DROP TABLE dbo.tbl_Job_Application;
END;
GO

-- Drop partition scheme and function if they exist
IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'ps_JobApplicationScheme')
BEGIN
    DROP PARTITION SCHEME ps_JobApplicationScheme;
END;
GO

IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'pf_JobApplicationByYear')
BEGIN
    DROP PARTITION FUNCTION pf_JobApplicationByYear;
END;
GO

-- Partition function by YEAR of created_at
CREATE PARTITION FUNCTION pf_JobApplicationByYear (DATETIME2)
AS RANGE RIGHT FOR VALUES
(
    ('2022-01-01'),
    ('2023-01-01'),
    ('2024-01-01'),
    ('2025-01-01'),
    ('2026-01-01'),
    ('2027-01-01'),
    ('2028-01-01'),
    ('2029-01-01'),
    ('2030-01-01')
);
GO

-- Partition scheme on PRIMARY filegroup
CREATE PARTITION SCHEME ps_JobApplicationScheme
AS PARTITION pf_JobApplicationByYear
ALL TO ([PRIMARY]);
GO

-- Recreate tbl_Job_Application on the partition scheme
CREATE TABLE dbo.tbl_Job_Application (
    engineer_id  INT          NOT NULL,
    job_id       INT          NOT NULL,
    match_score  DECIMAL(5,2) NULL,
    status       NVARCHAR(20) NOT NULL,  -- 'pending','shortlisted','accepted','rejected'
    created_at   DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2    NULL,
    CONSTRAINT PK_Job_Application 
        PRIMARY KEY (engineer_id, job_id, created_at),
    CONSTRAINT FK_Job_Application_Engineer
        FOREIGN KEY (engineer_id) REFERENCES dbo.tbl_Engineer_Profile(engineer_id),
    CONSTRAINT FK_Job_Application_Job
        FOREIGN KEY (job_id) REFERENCES dbo.tbl_Job(job_id),
    CONSTRAINT CK_Job_Application_Status
        CHECK (status IN ('pending','shortlisted','accepted','rejected'))
) ON ps_JobApplicationScheme (created_at);
GO

------------------------------------------------------------
-- 4. Core Indexes
-- Owners: Shazil (core), Areeba (search-optimised extensions)
-- Purpose:
--   - Speed up core joins and search operations
--   - Support matching, vetting, and analytics queries
------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Engineer_Skills_skill_engineer')
BEGIN
    CREATE INDEX IX_Engineer_Skills_skill_engineer
        ON dbo.tbl_Engineer_Skills (skill_id, engineer_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Job_Skills_job_skill')
BEGIN
    CREATE INDEX IX_Job_Skills_job_skill
        ON dbo.tbl_Job_Skills (job_id, skill_id);
END;
GO

-- Application searching & ranking
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Job_Application_Job_Status')
BEGIN
    CREATE INDEX IX_Job_Application_Job_Status
        ON dbo.tbl_Job_Application (job_id, status);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Job_Application_Job_MatchScore')
BEGIN
    CREATE INDEX IX_Job_Application_Job_MatchScore
        ON dbo.tbl_Job_Application (job_id, match_score DESC, created_at);
END;
GO

-- Vetting & search indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Vetting_Reviews_Engineer')
BEGIN
    CREATE INDEX IX_Vetting_Reviews_Engineer
        ON dbo.tbl_Vetting_Reviews (engineer_id, submitted_at DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Engineer_Profile_VetStatus')
BEGIN
    CREATE INDEX IX_Engineer_Profile_VetStatus
        ON dbo.tbl_Engineer_Profile (vet_status);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Engineer_Profile_Timezone_VetStatus')
BEGIN
    CREATE INDEX IX_Engineer_Profile_Timezone_VetStatus
        ON dbo.tbl_Engineer_Profile (timezone, vet_status);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Endorsement_Ratings_Engineer_Date')
BEGIN
    CREATE INDEX IX_Endorsement_Ratings_Engineer_Date
        ON dbo.tbl_Endorsement_Ratings (engineer_id, [date]);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Job_Client_Status')
BEGIN
    CREATE INDEX IX_Job_Client_Status
        ON dbo.tbl_Job (client_id, status, created_at);
END;
GO

------------------------------------------------------------
-- 5. Functions (Shared Logic)
-- Owner: All (grouped by feature area)
--
--  5.1 Matching & Eligibility (Owner: Taimur)
--       - fn_IsEngineerEligibleForJob(engineer_id, job_id)
--       - fn_CalculateMatchScore(engineer_id, job_id)
------------------------------------------------------------

-- Safety drops (ensure clean redeploy)
IF OBJECT_ID('dbo.fn_CalculateMatchScore','IF') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_CalculateMatchScore;
END;
GO

IF OBJECT_ID('dbo.fn_IsEngineerEligibleForJob','IF') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_IsEngineerEligibleForJob;
END;
GO

--------------------------------------------------------------------------------
-- fn_IsEngineerEligibleForJob (inline TVF)
-- Purpose:
--   Returns eligibility and context metrics for (engineer, job)
--   Used as the basis for match score calculation.
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
-- fn_CalculateMatchScore (inline TVF)
-- Purpose:
--   Computes weighted match score for (engineer, job) pair
--   based on skills, experience, rating, and timezone alignment.
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
                    0.45 * CASE 
                               WHEN e.total_required = 0 THEN 1.0
                               ELSE CAST(e.matched_required AS FLOAT) /
                                    NULLIF(e.total_required, 0)
                           END

                    + 0.20 * CASE
                                 WHEN e.total_preferred = 0 THEN 0.0
                                 ELSE CAST(e.matched_preferred AS FLOAT) /
                                      NULLIF(e.total_preferred, 0)
                             END

                    + 0.20 * CASE 
                                 WHEN e.years_experience IS NULL THEN 0.0
                                 ELSE 
                                     CASE 
                                         WHEN CAST(e.years_experience AS FLOAT) / 5.0 < 1.0 
                                             THEN CAST(e.years_experience AS FLOAT) / 5.0
                                         ELSE 1.0
                                     END
                             END

                    + 0.10 * CASE 
                                 WHEN e.avg_rating <= 0 THEN 0.0
                                 ELSE ( (e.avg_rating - 1.0) / 4.0 )
                             END

                    + 0.05 *
                      CASE
                          WHEN e.eng_timezone IS NULL OR e.job_timezone IS NULL THEN 0.6
                          WHEN e.eng_timezone = e.job_timezone THEN 1.0
                          WHEN LEFT(e.eng_timezone,
                                    CHARINDEX('/', e.eng_timezone + '/') - 1)
                               = 
                               LEFT(e.job_timezone,
                                    CHARINDEX('/', e.job_timezone + '/') - 1)
                          THEN 0.8
                          ELSE 0.4
                      END
                ) * 100, 2)
        END AS match_score
    FROM dbo.fn_IsEngineerEligibleForJob(@EngineerId, @JobId) e
);
GO

------------------------------------------------------------
-- 5.2 Vetting & Trust (Owner: Zaid)
--   - fn_ComputeVettingScore(engineer_id)
--   - fn_GetFinalVettingStatus(engineer_id)
------------------------------------------------------------

------------------------------------------------------------
-- fn_ComputeVettingScore
-- Purpose:
--   Aggregates vetting reviews into a 0–100 score
------------------------------------------------------------
CREATE FUNCTION dbo.fn_ComputeVettingScore (@EngineerId INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Score DECIMAL(5,2) = 0.00;
    DECLARE @TotalReviews INT;

    SELECT @TotalReviews = COUNT(*)
    FROM dbo.tbl_Vetting_Reviews
    WHERE engineer_id = @EngineerId;

    IF @TotalReviews = 0 RETURN 0.00;

    SELECT @Score = AVG(
        ((CAST(skills_verified AS INT) 
        + CAST(experience_verified AS INT) 
        + CAST(portfolio_verified AS INT)) / 3.0 * 70)
        + (CASE WHEN review_status = 'recommended' THEN 30.0 ELSE 0 END)
    )
    FROM dbo.tbl_Vetting_Reviews
    WHERE engineer_id = @EngineerId;

    IF @Score > 100.00 SET @Score = 100.00;

    RETURN ISNULL(@Score, 0.00);
END
GO

------------------------------------------------------------
-- fn_GetFinalVettingStatus
-- Purpose:
--   Translates vetting score and flags into final vet_status
------------------------------------------------------------
CREATE FUNCTION dbo.fn_GetFinalVettingStatus (@EngineerId INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Vetting_Reviews WHERE engineer_id = @EngineerId)
        RETURN 'pending';

    IF EXISTS (SELECT 1 FROM dbo.tbl_Vetting_Reviews 
               WHERE engineer_id = @EngineerId
               AND (review_status = 'not_recommended' OR review_status = 'rejected'))
        RETURN 'rejected';

    DECLARE @Score DECIMAL(5,2) = dbo.fn_ComputeVettingScore(@EngineerId);

    IF @Score >= 70 RETURN 'approved';

    RETURN 'pending';
END
GO

------------------------------------------------------------
-- 5.3 Search & Ratings (Owner: Areeba)
--   - fn_AverageEngineerRating
--   - fn_SplitSkillListToTable
------------------------------------------------------------

IF OBJECT_ID('dbo.fn_AverageEngineerRating','FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_AverageEngineerRating;
END;
GO

------------------------------------------------------------
-- fn_AverageEngineerRating
-- Purpose:
--   Returns average numeric rating for a given engineer
------------------------------------------------------------
CREATE FUNCTION dbo.fn_AverageEngineerRating
(
    @EngineerId INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Avg DECIMAL(5,2);

    SELECT @Avg = AVG(CAST(rating AS DECIMAL(5,2)))
    FROM dbo.tbl_Endorsement_Ratings
    WHERE engineer_id = @EngineerId;

    RETURN ISNULL(@Avg, 0.00);     -- return 0.00 if no ratings
END;
GO

IF OBJECT_ID('dbo.fn_SplitSkillListToTable') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_SplitSkillListToTable;
END;
GO

------------------------------------------------------------
-- fn_SplitSkillListToTable
-- Purpose:
--   Utility splitter: turns comma-separated skill IDs into a table
------------------------------------------------------------
CREATE FUNCTION dbo.fn_SplitSkillListToTable
(
    @SkillIdList NVARCHAR(MAX)
)
RETURNS @SkillIds TABLE (skill_id INT NOT NULL)
AS
BEGIN
    DECLARE @Pos INT = 0;
    DECLARE @Next INT;
    DECLARE @Value NVARCHAR(50);

    SET @SkillIdList = @SkillIdList + ',';

    WHILE CHARINDEX(',', @SkillIdList, @Pos + 1) > 0
    BEGIN
        SET @Next = CHARINDEX(',', @SkillIdList, @Pos + 1);
        SET @Value = SUBSTRING(@SkillIdList, @Pos + 1, @Next - @Pos - 1);

        INSERT INTO @SkillIds SELECT CAST(@Value AS INT);

        SET @Pos = @Next;
    END

    RETURN;
END;
GO

------------------------------------------------------------
-- 5.4 Platform / Misc (Owner: Shazil)
--   - Utility functions used by reports / maintenance
------------------------------------------------------------

IF OBJECT_ID('dbo.fn_StartOfMonth','FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_StartOfMonth;
END;
GO

------------------------------------------------------------
-- fn_StartOfMonth
-- Purpose:
--   Normalises any date to the first day of its month
------------------------------------------------------------
CREATE FUNCTION dbo.fn_StartOfMonth (@Date DATETIME2)
RETURNS DATE
AS
BEGIN
    RETURN DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1);
END;
GO

------------------------------------------------------------
-- 6. Views (Read Models / Projected Data)
-- Owners:
--   - Areeba: Talent discovery & search
--   - Haider: Job & application dashboards
--   - Zaid / Taimur: Vetting & matching dashboards
------------------------------------------------------------

------------------------------------------------------------
-- 6.1 Talent Discovery & Profiles (Owner: Areeba)
--   - vw_EngineerFullProfile
--   - vw_EngineerSearchIndex
------------------------------------------------------------

IF OBJECT_ID('dbo.vw_EngineerFullProfile','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_EngineerFullProfile;
END;
GO

------------------------------------------------------------
-- vw_EngineerFullProfile
-- Purpose:
--   Rich denormalised view of engineer profiles,
--   including availability, vet status, ratings, and skills list.
------------------------------------------------------------
CREATE VIEW dbo.vw_EngineerFullProfile AS
SELECT
    ep.engineer_id,
    u.full_name,
    u.email,
    ep.years_experience,
    ep.timezone,
    av.status_name AS availability_status,
    ep.vet_status,
    ep.portfolio_link,

    dbo.fn_AverageEngineerRating(ep.engineer_id) AS avg_rating,
    -- total distinct client ratings (count of feedback rows)
    (
        SELECT COUNT(*)
        FROM dbo.tbl_Endorsement_Ratings er
        WHERE er.engineer_id = ep.engineer_id
    ) AS total_ratings,

    STRING_AGG(s.skill_name, ', ') AS skills_list
FROM dbo.tbl_Engineer_Profile ep
JOIN dbo.tbl_User u
    ON ep.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Availability_Status av
    ON ep.availability_status_id = av.status_id
LEFT JOIN dbo.tbl_Engineer_Skills es
    ON ep.engineer_id = es.engineer_id
LEFT JOIN dbo.tbl_Skill s
    ON es.skill_id = s.skill_id
GROUP BY
    ep.engineer_id,
    u.full_name,
    u.email,
    ep.years_experience,
    ep.timezone,
    av.status_name,
    ep.vet_status,
    ep.portfolio_link;
GO

IF OBJECT_ID('dbo.vw_EngineerSearchIndex','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_EngineerSearchIndex;
END;
GO

------------------------------------------------------------
-- vw_EngineerSearchIndex
-- Purpose:
--   Simplified projection used by search stored procedures
------------------------------------------------------------
CREATE VIEW dbo.vw_EngineerSearchIndex AS
SELECT
    engineer_id,
    full_name,
    email,
    years_experience,
    timezone,
    availability_status,
    vet_status,
    avg_rating,
    skills_list,
    total_ratings
FROM dbo.vw_EngineerFullProfile;
GO

------------------------------------------------------------
-- 6.2 Job & Application Dashboards (Owner: Haider)
--   - vw_JobWithClientAndSkills
--   - vw_ApplicationsSummaryByJob
------------------------------------------------------------

IF OBJECT_ID('dbo.vw_JobWithClientAndSkills','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_JobWithClientAndSkills;
END;
GO

------------------------------------------------------------
-- vw_JobWithClientAndSkills
-- Purpose:
--   Job listing view with client info and aggregated skill requirements
------------------------------------------------------------
CREATE VIEW dbo.vw_JobWithClientAndSkills
AS
SELECT
    j.job_id,
    j.job_title,
    j.job_description,
    j.status AS job_status,
    j.created_at,
    j.updated_at,

    c.client_id,
    c.company_name,
    c.industry,

    STRING_AGG(s.skill_name + ' (' + js.importance_level + ')', ', ') 
        WITHIN GROUP (ORDER BY s.skill_name) AS required_skills
FROM dbo.tbl_Job j
JOIN dbo.tbl_Client_Profile c
    ON j.client_id = c.client_id
LEFT JOIN dbo.tbl_Job_Skills js
    ON j.job_id = js.job_id
LEFT JOIN dbo.tbl_Skill s
    ON js.skill_id = s.skill_id
GROUP BY
    j.job_id, j.job_title, j.job_description, j.status, j.created_at, j.updated_at,
    c.client_id, c.company_name, c.industry;
GO

IF OBJECT_ID('dbo.vw_ApplicationsSummaryByJob','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_ApplicationsSummaryByJob;
END;
GO

------------------------------------------------------------
-- vw_ApplicationsSummaryByJob
-- Purpose:
--   Aggregated counts of applications per job by status
------------------------------------------------------------
CREATE VIEW dbo.vw_ApplicationsSummaryByJob
AS
SELECT
    j.job_id,
    j.job_title,
    j.status AS job_status,
    COUNT(a.job_id) AS total_applications,
    SUM(CASE WHEN a.status = 'pending'      THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN a.status = 'shortlisted'  THEN 1 ELSE 0 END) AS shortlisted_count,
    SUM(CASE WHEN a.status = 'accepted'     THEN 1 ELSE 0 END) AS accepted_count,
    SUM(CASE WHEN a.status = 'rejected'     THEN 1 ELSE 0 END) AS rejected_count
FROM dbo.tbl_Job j
LEFT JOIN dbo.tbl_Job_Application a
    ON j.job_id = a.job_id
GROUP BY j.job_id, j.job_title, j.status;
GO

------------------------------------------------------------
-- 6.3 Vetting & Admin Monitoring (Owner: Zaid)
--   - vw_VettingQueue
------------------------------------------------------------

IF OBJECT_ID('dbo.vw_VettingQueue','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_VettingQueue;
END;
GO

------------------------------------------------------------
-- vw_VettingQueue
-- Purpose:
--   Admin view of engineers waiting for vetting,
--   including priority level based on status and review count.
------------------------------------------------------------
CREATE VIEW dbo.vw_VettingQueue
AS
SELECT 
    p.engineer_id,
    u.full_name AS engineer_name,
    u.email,
    p.vet_status AS current_vet_status,
    dbo.fn_ComputeVettingScore(p.engineer_id) AS vetting_score,
    COUNT(r.review_id) AS num_reviews,
    MAX(r.submitted_at) AS last_review_date,
    CASE 
        WHEN p.vet_status = 'pending' AND COUNT(r.review_id) = 0 THEN 'High'
        WHEN p.vet_status = 'pending' THEN 'Medium'
        ELSE 'Low'
    END AS priority_level
FROM dbo.tbl_Engineer_Profile p
JOIN dbo.tbl_User u ON p.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Vetting_Reviews r ON p.engineer_id = r.engineer_id
GROUP BY p.engineer_id, u.full_name, u.email, p.vet_status;
GO

------------------------------------------------------------
-- 6.4 Matching Dashboards (Owner: Taimur)
--   - vw_JobCandidatesRanked
--   - vw_OpenJobsWithTopCandidate
------------------------------------------------------------

IF OBJECT_ID('dbo.vw_JobCandidatesRanked','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_JobCandidatesRanked;
END;
GO

------------------------------------------------------------
-- vw_JobCandidatesRanked
-- Purpose:
--   Lists all candidates per job ordered by match score,
--   including vetting and rating context.
------------------------------------------------------------
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
JOIN dbo.tbl_Job              j  ON ja.job_id = j.job_id
JOIN dbo.tbl_Engineer_Profile ep ON ja.engineer_id = ep.engineer_id
JOIN dbo.tbl_User             u  ON ep.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Engineer_RatingCache rc 
       ON rc.engineer_id = ep.engineer_id;
GO

IF OBJECT_ID('dbo.vw_OpenJobsWithTopCandidate','V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_OpenJobsWithTopCandidate;
END;
GO

------------------------------------------------------------
-- vw_OpenJobsWithTopCandidate
-- Purpose:
--   Shows each open job along with its top-ranked candidate
------------------------------------------------------------
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

------------------------------------------------------------
-- 7. Stored Procedures (Behaviour / Workflows)
-- Owners by feature:
--   7.1 Matching Engine & Recommendations (Taimur)
--   7.2 Application & Job Lifecycle (Haider)
--   7.3 Vetting Pipeline (Zaid)
--   7.4 Search & Analytics (Areeba)
--   7.5 Platform / Infra (Shazil)
------------------------------------------------------------

------------------------------------------------------------
-- 7.1 Matching Engine & Recommendations (Owner: Taimur)
--   - sp_MatchEngineersToJob
--   - sp_RefreshMatchesForAllOpenJobs
------------------------------------------------------------

IF OBJECT_ID('dbo.sp_MatchEngineersToJob','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_MatchEngineersToJob;
END;
GO

IF OBJECT_ID('dbo.sp_RefreshMatchesForAllOpenJobs','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_RefreshMatchesForAllOpenJobs;
END;
GO

------------------------------------------------------------
-- sp_MatchEngineersToJob
-- Purpose:
--   Calculates and upserts match scores for all relevant engineers
--   for a single job. Optionally limits to top N candidates.
------------------------------------------------------------
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

------------------------------------------------------------
-- sp_RefreshMatchesForAllOpenJobs
-- Purpose:
--   Rebuilds match scores for every open job on the platform
------------------------------------------------------------
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

------------------------------------------------------------
-- 7.2 Application & Job Lifecycle (Owner: Haider)
--   - sp_CreateJob
--   - sp_ApplyToJob
--   - sp_UpdateApplicationStatus
--   - sp_UpdateJobStatus
------------------------------------------------------------

IF OBJECT_ID('dbo.sp_CreateJob','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_CreateJob;
END;
GO

------------------------------------------------------------
-- sp_CreateJob
-- Purpose:
--   Validates client and creates a new job record
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_CreateJob
(
    @ClientId INT,
    @JobTitle NVARCHAR(200),
    @JobDescription NVARCHAR(MAX),
    @Status NVARCHAR(20) = 'open'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Client_Profile WHERE client_id = @ClientId)
    BEGIN
        THROW 50010, 'Client does not exist.', 1;
    END;

    IF @Status NOT IN ('open','in_progress','closed')
    BEGIN
        THROW 50011, 'Invalid job status.', 1;
    END;

    INSERT INTO dbo.tbl_Job (client_id, job_title, job_description, status)
    VALUES (@ClientId, @JobTitle, @JobDescription, @Status);

    DECLARE @NewJobId INT = SCOPE_IDENTITY();

    SELECT @NewJobId AS job_id, 'Job created successfully.' AS message;
END;
GO

IF OBJECT_ID('dbo.sp_ApplyToJob','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_ApplyToJob;
END;
GO

------------------------------------------------------------
-- sp_ApplyToJob
-- Purpose:
--   Allows an engineer to apply to a job once (creates pending app)
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_ApplyToJob
(
    @EngineerId INT,
    @JobId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.tbl_Job_Application
        WHERE engineer_id = @EngineerId AND job_id = @JobId
    )
    BEGIN
        RAISERROR('Engineer has already applied to this job.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.tbl_Job_Application (engineer_id, job_id, status)
    VALUES (@EngineerId, @JobId, 'pending');
END;
GO

IF OBJECT_ID('dbo.sp_UpdateApplicationStatus','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_UpdateApplicationStatus;
END;
GO

------------------------------------------------------------
-- sp_UpdateApplicationStatus
-- Purpose:
--   Updates the status of an existing job application
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_UpdateApplicationStatus
(
    @EngineerId INT,
    @JobId INT,
    @NewStatus NVARCHAR(20),
    @UpdatedBy INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NewStatus NOT IN ('pending','shortlisted','accepted','rejected')
    BEGIN
        RAISERROR('Invalid application status.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.tbl_Job_Application
    SET 
        status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE engineer_id = @EngineerId
      AND job_id = @JobId;
END;
GO

IF OBJECT_ID('dbo.sp_UpdateJobStatus','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_UpdateJobStatus;
END;
GO

------------------------------------------------------------
-- sp_UpdateJobStatus
-- Purpose:
--   Changes job status (open / in_progress / closed) with validation
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_UpdateJobStatus
(
    @JobId INT,
    @NewStatus NVARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NewStatus NOT IN ('open', 'in_progress', 'closed')
    BEGIN
        THROW 50001, 'Invalid status. Allowed values: open, in_progress, closed.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Job WHERE job_id = @JobId)
    BEGIN
        THROW 50002, 'Job not found.', 1;
    END;

    UPDATE dbo.tbl_Job
    SET status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE job_id = @JobId;
END;
GO

------------------------------------------------------------
-- 7.3 Vetting Pipeline (Owner: Zaid)
--   - sp_FinaliseVettingDecision
--   - sp_CreateVettingReview
------------------------------------------------------------

------------------------------------------------------------
-- sp_FinaliseVettingDecision
-- Purpose:
--   Recomputes vet_status for an engineer and cascades to applications
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_FinaliseVettingDecision
(
    @EngineerId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile WHERE engineer_id = @EngineerId)
        RETURN;

    DECLARE @NewStatus NVARCHAR(20) = dbo.fn_GetFinalVettingStatus(@EngineerId);

    UPDATE dbo.tbl_Engineer_Profile
    SET vet_status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE engineer_id = @EngineerId;

    IF @NewStatus = 'rejected'
    BEGIN
        UPDATE dbo.tbl_Job_Application
        SET status = 'rejected', updated_at = SYSDATETIME()
        WHERE engineer_id = @EngineerId AND status = 'pending';
    END
END
GO

------------------------------------------------------------
-- sp_CreateVettingReview
-- Purpose:
--   Inserts a vetting review and refreshes final vet_status
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_CreateVettingReview
(
    @EngineerId INT,
    @ReviewerId INT,
    @ReviewStatus NVARCHAR(50), 
    @SkillsVerified BIT,
    @ExperienceVerified BIT,
    @PortfolioVerified BIT,
    @ReviewNotes NVARCHAR(MAX) = NULL,
    @RejectionReason NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile WHERE engineer_id = @EngineerId)
        RAISERROR ('Engineer ID does not exist.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_User WHERE user_id = @ReviewerId AND role = 'admin')
        RAISERROR ('Reviewer must be an Admin.', 16, 1);

    INSERT INTO dbo.tbl_Vetting_Reviews
    (
        engineer_id, reviewed_by, review_status,
        skills_verified, experience_verified, portfolio_verified,
        review_notes, rejection_reason, submitted_at
    )
    VALUES
    (
        @EngineerId, @ReviewerId, @ReviewStatus,
        @SkillsVerified, @ExperienceVerified, @PortfolioVerified,
        @ReviewNotes, @RejectionReason, SYSDATETIME()
    );

    EXEC dbo.sp_FinaliseVettingDecision @EngineerId;

    SELECT 'Review Submitted Successfully' AS Status;
END
GO

------------------------------------------------------------
-- 7.4 Search & Analytics (Owner: Areeba)
--   - sp_SearchEngineersByFilters
--   - sp_GetEngineerStats
------------------------------------------------------------

IF OBJECT_ID('dbo.sp_SearchEngineersByFilters','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_SearchEngineersByFilters;
END;
GO

------------------------------------------------------------
-- sp_SearchEngineersByFilters
-- Purpose:
--   Flexible search over engineers by skills, experience,
--   timezone, rating, vet_status, with basic pagination.
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_SearchEngineersByFilters
(
    @SkillIdList      NVARCHAR(MAX) = NULL,
    @MinExperience    INT           = NULL,
    @Timezone         NVARCHAR(64)  = NULL,
    @MinRating        DECIMAL(5,2)  = NULL,
    @VetStatus        NVARCHAR(20)  = NULL,
    @Page             INT           = 1,
    @PageSize         INT           = 20
)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Filtered AS
    (
        SELECT *
        FROM dbo.vw_EngineerSearchIndex
        WHERE (@VetStatus   IS NULL OR vet_status = @VetStatus)
          AND (@MinExperience IS NULL OR years_experience >= @MinExperience)
          AND (@Timezone   IS NULL OR timezone LIKE '%' + @Timezone + '%')
          AND (@MinRating  IS NULL OR avg_rating >= @MinRating)
    ),
    SkillFiltered AS
    (
        SELECT f.*
        FROM Filtered f
        WHERE @SkillIdList IS NULL
           OR EXISTS (
                SELECT 1
                FROM dbo.fn_SplitSkillListToTable(@SkillIdList) s
                JOIN dbo.tbl_Engineer_Skills es
                    ON es.engineer_id = f.engineer_id
                   AND es.skill_id = s.skill_id
            )
    ),
    Paged AS
    (
        SELECT *,
               ROW_NUMBER() OVER (ORDER BY avg_rating DESC, years_experience DESC) AS rn
        FROM SkillFiltered
    )
    SELECT *
    FROM Paged
    WHERE rn BETWEEN (@Page - 1) * @PageSize + 1
               AND @Page * @PageSize;
END;
GO

IF OBJECT_ID('dbo.sp_GetEngineerStats','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_GetEngineerStats;
END;
GO

------------------------------------------------------------
-- sp_GetEngineerStats
-- Purpose:
--   Returns application stats, rating summary, and skills
--   for a single engineer (used for dashboards)
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_GetEngineerStats
    @EngineerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ep.engineer_id,
        COUNT(ja.job_id) AS total_applications,
        SUM(CASE WHEN ja.status = 'pending'      THEN 1 ELSE 0 END) AS pending_applications,
        SUM(CASE WHEN ja.status = 'shortlisted'  THEN 1 ELSE 0 END) AS shortlisted_applications,
        SUM(CASE WHEN ja.status = 'accepted'     THEN 1 ELSE 0 END) AS accepted_applications,
        SUM(CASE WHEN ja.status = 'rejected'     THEN 1 ELSE 0 END) AS rejected_applications,
        MIN(ja.created_at) AS first_application_date,
        MAX(ja.created_at) AS last_application_date,
        
        dbo.fn_AverageEngineerRating(@EngineerId) AS avg_rating,
        COUNT(er.rating) AS total_ratings,
        AVG(ja.match_score) AS avg_match_score,

        STRING_AGG(s.skill_name, ', ') WITHIN GROUP (ORDER BY s.skill_name) AS skills_list,

        ep.years_experience,
        ep.timezone,
        ep.vet_status
    FROM dbo.tbl_Engineer_Profile ep
    LEFT JOIN dbo.tbl_Job_Application ja
            ON ep.engineer_id = ja.engineer_id
    LEFT JOIN dbo.tbl_Endorsement_Ratings er
            ON ep.engineer_id = er.engineer_id
    LEFT JOIN dbo.tbl_Engineer_Skills es
            ON ep.engineer_id = es.engineer_id
    LEFT JOIN dbo.tbl_Skill s
            ON es.skill_id = s.skill_id

    WHERE ep.engineer_id = @EngineerId
    GROUP BY 
        ep.engineer_id,
        ep.years_experience,
        ep.timezone,
        ep.vet_status;
END;
GO

------------------------------------------------------------
-- 7.5 Platform / Infra (Owner: Shazil)
--   - sp_GGenerateTestData
--   - sp_GetMonthlyPlatformStats
--   - sp_RebuildIndexesAndStats
------------------------------------------------------------

IF OBJECT_ID('dbo.sp_GGenerateTestData','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_GGenerateTestData;
END;
GO

------------------------------------------------------------
-- sp_GGenerateTestData
-- Purpose:
--   synthetic data generator:
--     Engineers, clients, profiles
--     Skills, jobs, job skills
--     Applications, vetting reviews, ratings
--   Used for performance / analytics testing.
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_GGenerateTestData
(
    @NumEngineers           INT,
    @NumClients             INT,
    @NumJobs                INT,
    @AvgSkillsPerEngineer   INT,
    @AvgSkillsPerJob        INT,
    @ApplicationsPerJob     INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Guard: avoid accidental double-population
    IF EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile)
    BEGIN
        RAISERROR('Engineer data already exists. Aborting sp_GGenerateTestData to avoid duplicates.', 16, 1);
        RETURN;
    END;

    DECLARE @SkillCount INT;
    SELECT @SkillCount = COUNT(*) FROM dbo.tbl_Skill;

    IF @SkillCount = 0
    BEGIN
        RAISERROR('No skills in tbl_Skill. Seed skills before calling sp_GGenerateTestData.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 2. Engineer + Client Users
    --------------------------------------------------------
    ;WITH N_E AS (
        SELECT TOP (@NumEngineers)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.tbl_User (full_name, email, password, role)
    SELECT CONCAT(N'Engineer ', n),
           CONCAT(N'engineer', n, N'@bridgeway.test'),
           N'pass',
           'engineer'
    FROM N_E;

    ;WITH N_C AS (
        SELECT TOP (@NumClients)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    )
    INSERT INTO dbo.tbl_User (full_name, email, password, role)
    SELECT CONCAT(N'Client ', n),
           CONCAT(N'client', n, N'@bridgeway.test'),
           N'pass',
           'client'
    FROM N_C;

    --------------------------------------------------------
    -- 3. Engineer & Client Profiles
    --------------------------------------------------------
    DECLARE @AvailCount INT;
    SELECT @AvailCount = COUNT(*) FROM dbo.tbl_Availability_Status;

    IF @AvailCount = 0
    BEGIN
        RAISERROR('No rows in tbl_Availability_Status. Seed availability statuses first.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.tbl_Engineer_Profile
    (
        engineer_id,
        years_experience,
        timezone,
        availability_status_id,
        vet_status,
        portfolio_link
    )
    SELECT
        u.user_id,
        ABS(CHECKSUM(NEWID())) % 16,  -- 0–15 years
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN N'UTC'
            WHEN 1 THEN N'UTC+3'
            WHEN 2 THEN N'UTC+5'
            ELSE N'UTC+1'
        END,
        ((ABS(CHECKSUM(NEWID())) % @AvailCount) + 1), -- random availability status
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN N'pending'
            WHEN 1 THEN N'rejected'
            ELSE N'approved'
        END,
        CONCAT(N'https://portfolio.bridgeway.test/engineer/', u.user_id)
    FROM dbo.tbl_User u
    WHERE u.role = 'engineer';

    INSERT INTO dbo.tbl_Client_Profile
    (
        client_id,
        company_name,
        industry
    )
    SELECT
        u.user_id,
        CONCAT(N'Company ', u.user_id),
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN N'FinTech'
            WHEN 1 THEN N'E-Commerce'
            WHEN 2 THEN N'Healthcare'
            ELSE N'SaaS'
        END
    FROM dbo.tbl_User u
    WHERE u.role = 'client';

    --------------------------------------------------------
    -- 4. Engineer Skills
    --------------------------------------------------------
    DECLARE @Engineers INT, @Clients INT;
    SELECT @Engineers = COUNT(*) FROM dbo.tbl_Engineer_Profile;
    SELECT @Clients   = COUNT(*) FROM dbo.tbl_Client_Profile;

    ;WITH Eng AS (
        SELECT engineer_id
        FROM dbo.tbl_Engineer_Profile
    ),
    NumSkill AS (
        SELECT TOP (@AvgSkillsPerEngineer)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    ),
    Comb AS (
        SELECT
            e.engineer_id,
            ns.n,
            ((ABS(CHECKSUM(CONCAT(CAST(e.engineer_id AS NVARCHAR(20)),
                                  N'-',
                                  CAST(ns.n AS NVARCHAR(20))))) % @SkillCount) + 1) AS skill_id
        FROM Eng e
        CROSS JOIN NumSkill ns
    ),
    DistinctComb AS (
        SELECT engineer_id, skill_id, MIN(n) AS n
        FROM Comb
        GROUP BY engineer_id, skill_id
    )
    INSERT INTO dbo.tbl_Engineer_Skills (engineer_id, skill_id, proficiency_score)
    SELECT
        engineer_id,
        skill_id,
        ((n - 1) % 10) + 1   -- 1..10 rating
    FROM DistinctComb;

--------------------------------------------------------
-- 5. Jobs
--------------------------------------------------------
    IF @Clients = 0
    BEGIN
        RAISERROR('No clients created; cannot generate jobs.', 16, 1);
        RETURN;
    END;

    ;WITH N_J AS (
        SELECT TOP (@NumJobs)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    ),
    ClientsCTE AS (
        SELECT client_id,
            ROW_NUMBER() OVER (ORDER BY client_id) AS rn
        FROM dbo.tbl_Client_Profile
    ),
    Assign AS (
        SELECT
            nj.n,
            c.client_id
        FROM N_J nj
        JOIN ClientsCTE c
        ON ((nj.n - 1) % @Clients) + 1 = c.rn
    )
    INSERT INTO dbo.tbl_Job (client_id, job_title, job_description, status, created_at)
    SELECT
        a.client_id,
        CASE ABS(CHECKSUM(a.n)) % 7
            WHEN 0 THEN N'Backend Engineer'
            WHEN 1 THEN N'Frontend Developer'
            WHEN 2 THEN N'Full-Stack Developer'
            WHEN 3 THEN N'DevOps Engineer'
            WHEN 4 THEN N'Data Scientist'
            WHEN 5 THEN N'ML Engineer'
            WHEN 6 THEN N'QA Automation Engineer'
        END AS job_title,
        CASE ABS(CHECKSUM(a.n * 13)) % 5
            WHEN 0 THEN N'Looking for strong problem-solving skills and experience with cloud systems.'
            WHEN 1 THEN N'Requires expertise in modern frameworks and CI/CD tooling.'
            WHEN 2 THEN N'Candidate must be familiar with distributed systems and SQL.'
            WHEN 3 THEN N'Ideal candidate has leadership experience and solid architecture knowledge.'
            WHEN 4 THEN N'Must be comfortable working remotely and collaborating across timezones.'
        END AS job_description,
        N'open' AS status,
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 365), SYSDATETIME()) AS created_at
    FROM Assign a;


    --------------------------------------------------------
    -- 6. Job Skills
    --------------------------------------------------------
    DECLARE @Jobs INT;
    SELECT @Jobs = COUNT(*) FROM dbo.tbl_Job;

    ;WITH JobCTE AS (
        SELECT job_id
        FROM dbo.tbl_Job
    ),
    NumJobSkill AS (
        SELECT TOP (@AvgSkillsPerJob)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    ),
    CombJS AS (
        SELECT
            j.job_id,
            njs.n,
            ((ABS(CHECKSUM(CONCAT(CAST(j.job_id AS NVARCHAR(20)),
                                  N'-',
                                  CAST(njs.n AS NVARCHAR(20))))) % @SkillCount) + 1) AS skill_id
        FROM JobCTE j
        CROSS JOIN NumJobSkill njs
    ),
    DistinctJS AS (
        SELECT job_id, skill_id, MIN(n) AS n
        FROM CombJS
        GROUP BY job_id, skill_id
    )
    INSERT INTO dbo.tbl_Job_Skills (job_id, skill_id, importance_level)
    SELECT
        job_id,
        skill_id,
        CASE (n % 2)
            WHEN 0 THEN N'required'
            ELSE N'preferred'
        END
    FROM DistinctJS;

    --------------------------------------------------------
    -- 7. Job Applications (partitioned by created_at)
    --------------------------------------------------------
    DECLARE @EngineerCount INT;
    SELECT @EngineerCount = COUNT(*) FROM dbo.tbl_Engineer_Profile;

    IF @EngineerCount = 0 OR @Jobs = 0
    BEGIN
        RAISERROR('Need engineers and jobs before generating applications.', 16, 1);
        RETURN;
    END;

    ;WITH JobsCTE AS (
        SELECT job_id,
               ROW_NUMBER() OVER (ORDER BY job_id) AS job_row
        FROM dbo.tbl_Job
    ),
    NumApp AS (
        SELECT TOP (@ApplicationsPerJob)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    ),
    EngCTE AS (
        SELECT engineer_id,
               ROW_NUMBER() OVER (ORDER BY engineer_id) AS rn
        FROM dbo.tbl_Engineer_Profile
    ),
    CombApp AS (
        SELECT
            j.job_id,
            j.job_row,
            na.n,
            (( (j.job_row - 1) * @ApplicationsPerJob + na.n - 1) % @EngineerCount) + 1 AS eng_offset
        FROM JobsCTE j
        CROSS JOIN NumApp na
    ),
    AppRows AS (
        SELECT
            e.engineer_id,
            ca.job_id,
            CASE (ca.n % 10)
                WHEN 0 THEN N'shortlisted'
                WHEN 1 THEN N'accepted'
                WHEN 2 THEN N'rejected'
                ELSE N'pending'
            END AS status,
            CAST((ABS(CHECKSUM(NEWID())) % 10000) / 100.0 AS DECIMAL(5,2)) AS match_score,
            DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % (365*3)), SYSDATETIME()) AS created_at
        FROM CombApp ca
        JOIN EngCTE e
          ON e.rn = ca.eng_offset
    )
    INSERT INTO dbo.tbl_Job_Application (engineer_id, job_id, match_score, status, created_at)
    SELECT engineer_id, job_id, match_score, status, created_at
    FROM AppRows;

    --------------------------------------------------------
    -- 8. Vetting Reviews
    --------------------------------------------------------
    DECLARE @AdminId INT;
    SELECT TOP 1 @AdminId = user_id
    FROM dbo.tbl_User
    WHERE role = 'admin'
    ORDER BY user_id;

    ;WITH EngV AS (
        SELECT engineer_id,
               vet_status,
               ROW_NUMBER() OVER (ORDER BY engineer_id) AS rn
        FROM dbo.tbl_Engineer_Profile
        WHERE vet_status <> 'pending'
    ),
    NumReview AS (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    CombV AS (
        SELECT
            ev.engineer_id,
            ev.vet_status,
            nr.n
        FROM EngV ev
        CROSS JOIN NumReview nr
        WHERE (ev.rn + nr.n) % 2 = 0
    )
    INSERT INTO dbo.tbl_Vetting_Reviews
    (
        engineer_id,
        review_status,
        skills_verified,
        experience_verified,
        portfolio_verified,
        review_notes,
        rejection_reason,
        reviewed_by,
        submitted_at,
        reviewed_at
    )
    SELECT
        engineer_id,
        CASE vet_status
            WHEN 'approved' THEN N'approved'
            ELSE N'rejected'
        END,
        CASE vet_status
            WHEN 'approved' THEN 1 ELSE 0 END,
        CASE vet_status
            WHEN 'approved' THEN 1 ELSE 0 END,
        1,
        N'Auto-generated vetting review.',
        CASE vet_status
            WHEN 'rejected' THEN N'Insufficient experience (auto-generated).'
            ELSE NULL
        END,
        @AdminId,
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 365), SYSDATETIME()),
        SYSDATETIME()
    FROM CombV;

    --------------------------------------------------------
    -- 9. Endorsement Ratings Based on Accepted Applications
    --------------------------------------------------------
    ;WITH Accepted AS (
        SELECT
            ja.engineer_id,
            j.client_id,
            ja.created_at,
            ROW_NUMBER() OVER (PARTITION BY ja.engineer_id, j.client_id
                               ORDER BY ja.created_at) AS rn
        FROM dbo.tbl_Job_Application ja
        JOIN dbo.tbl_Job j
          ON ja.job_id = j.job_id
        WHERE ja.status = 'accepted'
    )
    INSERT INTO dbo.tbl_Endorsement_Ratings
    (
        client_id,
        engineer_id,
        rating,
        comment,
        verified,
        [date]
    )
    SELECT
        client_id,
        engineer_id,
        (ABS(CHECKSUM(NEWID())) % 5) + 1 AS rating,
        N'Auto-generated rating.',
        1,
        DATEADD(DAY, 1, created_at)
    FROM Accepted
    WHERE rn = 1;
END;
GO

IF OBJECT_ID('dbo.sp_GetMonthlyPlatformStats','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_GetMonthlyPlatformStats;
END;
GO

------------------------------------------------------------
-- sp_GetMonthlyPlatformStats
-- Purpose:
--   Monthly summary for a given year:
--     New engineers / clients / jobs
--     Application counts and average match score
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_GetMonthlyPlatformStats
(
    @Year INT
)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Months AS (
        SELECT 1 AS month_num UNION ALL
        SELECT 2 UNION ALL
        SELECT 3 UNION ALL
        SELECT 4 UNION ALL
        SELECT 5 UNION ALL
        SELECT 6 UNION ALL
        SELECT 7 UNION ALL
        SELECT 8 UNION ALL
        SELECT 9 UNION ALL
        SELECT 10 UNION ALL
        SELECT 11 UNION ALL
        SELECT 12
    )
    SELECT
        m.month_num,
        dbo.fn_StartOfMonth(DATEFROMPARTS(@Year, m.month_num, 15)) AS month_start,
        -- New engineers
        (
            SELECT COUNT(*)
            FROM dbo.tbl_Engineer_Profile ep
            WHERE YEAR(ep.created_at) = @Year
              AND MONTH(ep.created_at) = m.month_num
        ) AS new_engineers,
        -- New clients
        (
            SELECT COUNT(*)
            FROM dbo.tbl_Client_Profile cp
            WHERE YEAR(cp.created_at) = @Year
              AND MONTH(cp.created_at) = m.month_num
        ) AS new_clients,
        -- New jobs
        (
            SELECT COUNT(*)
            FROM dbo.tbl_Job j
            WHERE YEAR(j.created_at) = @Year
              AND MONTH(j.created_at) = m.month_num
        ) AS new_jobs,
        -- Total applications
        (
            SELECT COUNT(*)
            FROM dbo.tbl_Job_Application ja
            WHERE YEAR(ja.created_at) = @Year
              AND MONTH(ja.created_at) = m.month_num
        ) AS total_applications,
        -- Accepted applications
        (
            SELECT COUNT(*)
            FROM dbo.tbl_Job_Application ja
            WHERE YEAR(ja.created_at) = @Year
              AND MONTH(ja.created_at) = m.month_num
              AND ja.status = 'accepted'
        ) AS accepted_applications,
        -- Average match score
        (
            SELECT AVG(ja.match_score)
            FROM dbo.tbl_Job_Application ja
            WHERE YEAR(ja.created_at) = @Year
              AND MONTH(ja.created_at) = m.month_num
              AND ja.match_score IS NOT NULL
        ) AS avg_match_score
    FROM Months m
    ORDER BY m.month_num;
END;
GO

IF OBJECT_ID('dbo.sp_RebuildIndexesAndStats','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_RebuildIndexesAndStats;
END;
GO

------------------------------------------------------------
-- sp_RebuildIndexesAndStats
-- Purpose:
--   Periodic maintenance: rebuilds indexes and updates statistics
--   for key tables (jobs, applications, engineer profiles).
------------------------------------------------------------
CREATE PROCEDURE dbo.sp_RebuildIndexesAndStats
AS
BEGIN
    SET NOCOUNT ON;

    ALTER INDEX ALL ON dbo.tbl_Job_Application REBUILD;
    UPDATE STATISTICS dbo.tbl_Job_Application;

    ALTER INDEX ALL ON dbo.tbl_Job REBUILD;
    UPDATE STATISTICS dbo.tbl_Job;

    ALTER INDEX ALL ON dbo.tbl_Engineer_Profile REBUILD;
    UPDATE STATISTICS dbo.tbl_Engineer_Profile;
END;
GO

------------------------------------------------------------
-- 8. Triggers (Automatic Reactions to Data Changes)
-- Owners: Zaid & Haider
------------------------------------------------------------

------------------------------------------------------------
-- 8.1 Application Workflow Triggers (Owner: Haider)
--   - trg_JobApplication_AfterInsert
--   - trg_JobApplication_AfterUpdate
------------------------------------------------------------

IF OBJECT_ID('dbo.trg_JobApplication_AfterInsert','TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trg_JobApplication_AfterInsert;
END;
GO

------------------------------------------------------------
-- trg_JobApplication_AfterInsert
-- Purpose:
--   Ensures new applications always have a non-NULL match_score
------------------------------------------------------------
CREATE TRIGGER trg_JobApplication_AfterInsert
ON dbo.tbl_Job_Application
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ja
    SET match_score = 0
    FROM dbo.tbl_Job_Application ja
    JOIN inserted i
        ON ja.engineer_id = i.engineer_id
       AND ja.job_id     = i.job_id
    WHERE i.match_score IS NULL;
END;
GO

IF OBJECT_ID('dbo.trg_JobApplication_AfterUpdate','TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trg_JobApplication_AfterUpdate;
END;
GO

------------------------------------------------------------
-- trg_JobApplication_AfterUpdate
-- Purpose:
--   When an application becomes 'accepted', mark the job in_progress
------------------------------------------------------------
CREATE TRIGGER trg_JobApplication_AfterUpdate
ON dbo.tbl_Job_Application
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE j
    SET j.status = 'in_progress',
        j.updated_at = SYSDATETIME()
    FROM dbo.tbl_Job j
    JOIN inserted i
        ON j.job_id = i.job_id
    WHERE i.status = 'accepted';
END;
GO

------------------------------------------------------------
-- 8.2 Vetting & Security Triggers (Owner: Zaid)
--   - trg_VettingReviews_AfterInsert
--   - trg_EngineerProfile_InsteadOfDelete
------------------------------------------------------------

IF OBJECT_ID('dbo.trg_VettingReviews_AfterInsert','TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trg_VettingReviews_AfterInsert;
END;
GO

------------------------------------------------------------
-- trg_VettingReviews_AfterInsert
-- Purpose:
--   After a vetting review is created, recompute vet_status
------------------------------------------------------------
CREATE TRIGGER trg_VettingReviews_AfterInsert
ON dbo.tbl_Vetting_Reviews
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EngId INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT engineer_id FROM inserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @EngId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_FinaliseVettingDecision @EngId;
        FETCH NEXT FROM cur INTO @EngId;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END
GO

IF OBJECT_ID('dbo.trg_EngineerProfile_InsteadOfDelete','TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trg_EngineerProfile_InsteadOfDelete;
END;
GO

------------------------------------------------------------
-- trg_EngineerProfile_InsteadOfDelete
-- Purpose:
--   Implements soft delete:
--     Archives engineer profile + user info
--     Rejects their pending/shortlisted applications
------------------------------------------------------------
CREATE TRIGGER trg_EngineerProfile_InsteadOfDelete
ON dbo.tbl_Engineer_Profile
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Archive the profile data into tbl_Engineer_Archive
    INSERT INTO dbo.tbl_Engineer_Archive
    (
        engineer_id,
        full_name,
        email,
        years_experience,
        timezone,
        availability_status_id,
        vet_status,
        portfolio_link,
        reason
    )
    SELECT 
        d.engineer_id,
        u.full_name,
        u.email,
        d.years_experience,
        d.timezone,
        d.availability_status_id,
        d.vet_status,
        d.portfolio_link,
        'Soft deleted via INSTEAD OF trigger'
    FROM deleted d
    JOIN dbo.tbl_User u ON d.engineer_id = u.user_id;

    -- Cascade: mark their relevant applications as rejected
    UPDATE dbo.tbl_Job_Application
    SET status = 'rejected',
        updated_at = SYSDATETIME()
    WHERE engineer_id IN (SELECT engineer_id FROM deleted)
      AND status IN ('pending', 'shortlisted');
END
GO

------------------------------------------------------------
-- 9. Bulk Data Generation & Performance Testing
-- Primary Owner: Shazil
-- Support: Areeba (search), whole group for extra workload tests
------------------------------------------------------------

PRINT '------------------------------------------------------------';
PRINT '9. Bulk Data Generation & Performance Testing';
PRINT '------------------------------------------------------------';

------------------------------------------------------------
-- 9.1 Large-Scale Test Data Generation
------------------------------------------------------------
IF OBJECT_ID('dbo.sp_GGenerateTestData', 'P') IS NOT NULL
BEGIN
    PRINT 'Starting bulk data generation via sp_GGenerateTestData ...';

    EXEC dbo.sp_GGenerateTestData
        @NumEngineers           = 150000,
        @NumClients             = 50000,
        @NumJobs                = 200000,
        @AvgSkillsPerEngineer   = 3,
        @AvgSkillsPerJob        = 2,
        @ApplicationsPerJob     = 3;

    PRINT 'Finished bulk data generation.';
END
ELSE
BEGIN
    PRINT 'WARNING: sp_GGenerateTestData not found. Skipping bulk data generation.';
END;
GO

------------------------------------------------------------
-- 9.2 Additional Nonclustered / Filtered Indexes
------------------------------------------------------------

-- 9.2.1 User role + created_at
IF OBJECT_ID('dbo.tbl_User', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.indexes
       WHERE name = 'IX_tbl_User_role_created_at'
         AND object_id = OBJECT_ID('dbo.tbl_User')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_tbl_User_role_created_at
        ON dbo.tbl_User (role, created_at);
END;
GO

-- 9.2.2 Jobs by client + status
IF OBJECT_ID('dbo.tbl_Job', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.indexes
       WHERE name = 'IX_tbl_Job_client_status'
         AND object_id = OBJECT_ID('dbo.tbl_Job')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_tbl_Job_client_status
        ON dbo.tbl_Job (client_id, status)
        INCLUDE (created_at);
END;
GO

-- 9.2.3 Applications by job + status
IF OBJECT_ID('dbo.tbl_Job_Application', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.indexes
       WHERE name = 'IX_tbl_JobApp_job_status'
         AND object_id = OBJECT_ID('dbo.tbl_Job_Application')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_tbl_JobApp_job_status
        ON dbo.tbl_Job_Application (job_id, status)
        INCLUDE (engineer_id, created_at);
END;
GO

-- 9.2.4 Filtered index for "active" applications
IF OBJECT_ID('dbo.tbl_Job_Application', 'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.indexes
       WHERE name = 'IX_tbl_JobApp_active'
         AND object_id = OBJECT_ID('dbo.tbl_Job_Application')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_tbl_JobApp_active
        ON dbo.tbl_Job_Application (job_id)
        WHERE status IN ('pending', 'shortlisted');
END;
GO