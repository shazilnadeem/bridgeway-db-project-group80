USE BridgewayDB;
GO

------------------------------------------------------------
-- Shazil - Infra, Partitioning, Bulk Data & Global Metrics
-- Responsibilities:
--   * Seed lookup data (skills, base users)
--   * Partitioning for big tables (Job_Application)
--   * Core global indexes
--   * Bulk data generator (1M+ rows)
--   * Global monthly stats & maintenance
--   * Final master script integration and testing
------------------------------------------------------------

-- 2. LOOKUP SEED DATA (your inserts)

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

-- Seed ADMIN users
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_User WHERE role = 'admin')
BEGIN
    INSERT INTO dbo.tbl_User (full_name, email, password, role)
    VALUES
        (N'Bridgeway Admin 1', N'admin1@bridgeway.test', N'adminpass', 'admin'),
        (N'Bridgeway Admin 2', N'admin2@bridgeway.test', N'adminpass', 'admin');
END;
GO





-- 3. PARTITION FUNCTION & SCHEME (pf_JobApplicationByYear, ps_JobApplicationScheme)

IF OBJECT_ID('dbo.tbl_Job_Application','U') IS NOT NULL
BEGIN
    DROP TABLE dbo.tbl_Job_Application;
END;
GO

-- 3.2 Drop scheme and function if they exist
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

-- 3.3 Recreate function & scheme
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

CREATE PARTITION SCHEME ps_JobApplicationScheme
AS PARTITION pf_JobApplicationByYear
ALL TO ([PRIMARY]);
GO

-- 3.4 Recreate tbl_Job_Application ON the partition scheme
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




-- 4. CORE INDEXES (collected + cleaned)

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

-- Vetting & search indexes (from other members’ modules)
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

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Engineer_Profile_Location_VetStatus')
BEGIN
    CREATE INDEX IX_Engineer_Profile_Location_VetStatus
        ON dbo.tbl_Engineer_Profile (location, vet_status);
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



-- 5.4 PLATFORM FUNCTIONS (fn_StartOfMonth, etc.)

IF OBJECT_ID('dbo.fn_StartOfMonth','FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.fn_StartOfMonth;
END;
GO

CREATE FUNCTION dbo.fn_StartOfMonth (@Date DATETIME2)
RETURNS DATE
AS
BEGIN
    RETURN DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1);
END;
GO



/***********************************************************
  7.5 INFRA STORED PROCS
    - sp_GGenerateTestData
    - sp_GetMonthlyPlatformStats
    - sp_RebuildIndexesAndStats
************************************************************/

------------------------------------------------------------
-- 7.5.1 sp_GGenerateTestData
------------------------------------------------------------
IF OBJECT_ID('dbo.sp_GGenerateTestData','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_GGenerateTestData;
END;
GO

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

    -- Basic guard: don’t double-populate if data is already there
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
    -- 1. Admins already seeded in Section 2
    --------------------------------------------------------

    --------------------------------------------------------
    -- 2. Engineer + Client USERS
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
    -- 3. Engineer & Client profiles (1:1 with users)
    --------------------------------------------------------
    INSERT INTO dbo.tbl_Engineer_Profile
    (
        engineer_id,
        years_experience,
        location,
        availability,
        vet_status,
        portfolio_link
    )
    SELECT
        u.user_id,
        ABS(CHECKSUM(NEWID())) % 16,  -- 0-15 years
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN N'Lahore'
            WHEN 1 THEN N'Karachi'
            WHEN 2 THEN N'Islamabad'
            ELSE N'Remote'
        END,
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN N'full-time'
            WHEN 1 THEN N'part-time'
            ELSE N'contract'
        END,
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
    -- 4. Engineer skills
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
    INSERT INTO dbo.tbl_Engineer_Skills (engineer_id, skill_id, proficiency_level)
    SELECT
        engineer_id,
        skill_id,
        CASE (n % 3)
            WHEN 1 THEN N'beginner'
            WHEN 2 THEN N'intermediate'
            ELSE N'expert'
        END
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
        CONCAT(N'Backend Engineer ', a.n),
        CONCAT(N'Auto-generated job description #', a.n),
        N'open',
        DATEADD(DAY, - (ABS(CHECKSUM(NEWID())) % 365), SYSDATETIME())
    FROM Assign a;

    --------------------------------------------------------
    -- 6. Job skills
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
    -- 7. Job applications (partitioned by created_at)
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
    -- 8. Vetting reviews
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
        WHERE (ev.rn + nr.n) % 2 = 0   -- some engineers get 1-2 reviews
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
    -- 9. Endorsement ratings based on accepted applications
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
    WHERE rn = 1;  -- one rating per client-engineer pair

END;
GO

------------------------------------------------------------
-- 7.5.2 sp_GetMonthlyPlatformStats
------------------------------------------------------------
IF OBJECT_ID('dbo.sp_GetMonthlyPlatformStats','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_GetMonthlyPlatformStats;
END;
GO

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
        DATEFROMPARTS(@Year, m.month_num, 1) AS month_start,
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
        -- Average match score for that month (all apps)
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

------------------------------------------------------------
-- 7.5.3 sp_RebuildIndexesAndStats
------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RebuildIndexesAndStats','P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_RebuildIndexesAndStats;
END;
GO

CREATE PROCEDURE dbo.sp_RebuildIndexesAndStats
AS
BEGIN
    SET NOCOUNT ON;

    -- Basic maintenance for big tables
    ALTER INDEX ALL ON dbo.tbl_Job_Application REBUILD;
    UPDATE STATISTICS dbo.tbl_Job_Application;

    ALTER INDEX ALL ON dbo.tbl_Job REBUILD;
    UPDATE STATISTICS dbo.tbl_Job;

    ALTER INDEX ALL ON dbo.tbl_Engineer_Profile REBUILD;
    UPDATE STATISTICS dbo.tbl_Engineer_Profile;
END;
GO

/***********************************************************
  9. BULK DATA INVOCATION & TEST QUERIES
************************************************************/

-- Example invocation: adjust numbers to hit ~1M+ rows total
-- (Start with smaller numbers while testing)

-- EXEC dbo.sp_GGenerateTestData
--     @NumEngineers         = 20000,
--     @NumClients           = 5000,
--     @NumJobs              = 30000,
--     @AvgSkillsPerEngineer = 6,
--     @AvgSkillsPerJob      = 5,
--     @ApplicationsPerJob   = 10;
-- GO

-- Optional maintenance after big load
-- EXEC dbo.sp_RebuildIndexesAndStats;
-- GO

-- Optional sanity checks
-- SELECT COUNT(*) AS EngineerCount      FROM dbo.tbl_Engineer_Profile;
-- SELECT COUNT(*) AS ClientCount        FROM dbo.tbl_Client_Profile;
-- SELECT COUNT(*) AS JobCount           FROM dbo.tbl_Job;
-- SELECT COUNT(*) AS ApplicationCount   FROM dbo.tbl_Job_Application;

-- Example monthly stats
-- EXEC dbo.sp_GetMonthlyPlatformStats @Year = 2024;
-- GO

-- Check how many rows fall in each partition for Job_Application
-- (helps prove that partitioning is working)
-- SELECT
--     $PARTITION.pf_JobApplicationByYear(created_at) AS partition_number,
--     COUNT(*) AS row_count
-- FROM dbo.tbl_Job_Application
-- GROUP BY $PARTITION.pf_JobApplicationByYear(created_at)
-- ORDER BY partition_number;
