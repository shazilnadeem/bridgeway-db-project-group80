USE BridgewayDB;
GO

------------------------------------------------------------
-- Haider - Application Workflow & Job Lifecycle Module
-- Responsibilities:
--   * Application pipeline (apply, shortlist, accept, reject)
--   * Job lifecycle (open/in_progress/closed)
--   * Job-level dashboards/views
-- Depends on:
--   * Core tables (tbl_Job, tbl_Job_Application, tbl_Client_Profile, tbl_Engineer_Profile)
------------------------------------------------------------

-- 6. VIEWS (your views go here)

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



CREATE VIEW dbo.vw_ApplicationsSummaryByJob
AS
SELECT
    j.job_id,
    j.job_title,
    j.status AS job_status,
    COUNT(a.job_id) AS total_applications,

    SUM(CASE WHEN a.status = 'pending' THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN a.status = 'shortlisted' THEN 1 ELSE 0 END) AS shortlisted_count,
    SUM(CASE WHEN a.status = 'accepted' THEN 1 ELSE 0 END) AS accepted_count,
    SUM(CASE WHEN a.status = 'rejected' THEN 1 ELSE 0 END) AS rejected_count
FROM dbo.tbl_Job j
LEFT JOIN dbo.tbl_Job_Application a
    ON j.job_id = a.job_id
GROUP BY j.job_id, j.job_title, j.status;
GO


-- 7. STORED PROCEDURES (your SPs go here)

CREATE OR ALTER PROCEDURE dbo.sp_CreateJob
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

    IF @Status NOT IN ('open', 'in_progress', 'closed')
    BEGIN
        THROW 50011, 'Invalid job status. Allowed values: open, in_progress, closed.', 1;
    END;

    INSERT INTO dbo.tbl_Job (client_id, job_title, job_description, status)
    VALUES (@ClientId, @JobTitle, @JobDescription, @Status);

    DECLARE @NewJobId INT = SCOPE_IDENTITY();

    -- 4. Return the new job ID
    SELECT @NewJobId AS job_id, 'Job created successfully.' AS message;
END;
GO


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
    END

    INSERT INTO dbo.tbl_Job_Application (engineer_id, job_id, status)
    VALUES (@EngineerId, @JobId, 'pending');
END
GO



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
    END

    UPDATE dbo.tbl_Job_Application
    SET 
        status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE engineer_id = @EngineerId
      AND job_id = @JobId;
END
GO



CREATE OR ALTER PROCEDURE dbo.sp_UpdateJobStatus
(
    @JobId INT,
    @NewStatus NVARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- VALIDATION BLOCK
    IF @NewStatus NOT IN ('open', 'in_progress', 'closed')
    BEGIN
        THROW 50001, 'Invalid status. Allowed values: open, in_progress, closed.', 1;
    END;

    -- MAKE SURE JOB EXISTS
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Job WHERE job_id = @JobId)
    BEGIN
        THROW 50002, 'Job not found.', 1;
    END;


    UPDATE dbo.tbl_Job
    SET status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE job_id = @JobId;

    PRINT 'Job status updated successfully.';
END
GO


-- 8. TRIGGERS (your triggers go here)

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
       AND ja.job_id = i.job_id;
END
GO



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
END
GO

------------------------------------------------------------
-- TEST BLOCK (for your own use - can stay commented)
------------------------------------------------------------
-- -- Sample usage:
-- -- EXEC dbo.sp_ApplyToJob 1, 10;
-- -- EXEC dbo.sp_UpdateApplicationStatus 1, 10, 'shortlisted', 3;
-- -- SELECT * FROM dbo.vw_ApplicationsSummaryByJob;

