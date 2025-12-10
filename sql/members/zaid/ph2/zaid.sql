USE BridgewayDB;
GO

------------------------------------------------------------
-- Zaid - Vetting, Profile Integrity & Security Module
-- Responsibilities:
--   * Vetting pipeline (reviews -> vet_status)
--   * Compute vetting scores and final statuses
--   * Soft delete / archive engineer profiles
--   * Admin vetting queue views
------------------------------------------------------------

-----------------------------
-- SCHEMA EXTENSIONS (AUDIT / ARCHIVE TABLES)
-----------------------------
-- Table to store soft-deleted engineer profiles for data integrity.
IF OBJECT_ID('dbo.tbl_Engineer_Archive', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_Engineer_Archive (
        archive_id          INT IDENTITY(1,1) PRIMARY KEY,
        engineer_id         INT NOT NULL,
        full_name           NVARCHAR(150) NULL,
        email               NVARCHAR(255) NULL,
        years_experience    INT NULL,
        location            NVARCHAR(100) NULL,
        availability        NVARCHAR(50) NULL,
        vet_status          NVARCHAR(20) NULL,
        portfolio_link      NVARCHAR(255) NULL,
        archived_at         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        reason              NVARCHAR(MAX) NULL
    );
END
GO

-----------------------------
-- 5. FUNCTIONS (Vetting & Trust)
-----------------------------

-- 1. Compute Vetting Score
-- Calculates a score (0-100) based on verified flags and recommendation status.
CREATE FUNCTION dbo.fn_ComputeVettingScore (@EngineerId INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Score DECIMAL(5,2) = 0.00;
    
    DECLARE @TotalReviews INT;

    SELECT @TotalReviews = COUNT(*)
    FROM dbo.tbl_Vetting_Reviews
    WHERE engineer_id = @EngineerId;

    -- If no reviews, return 0 
    IF @TotalReviews = 0 RETURN 0.00;

    -- Logic: Average score across all reviews
    -- Base formula: (#verified_flags / 3.0) * 70  
    -- Bonus: If review_status = 'recommended' then +30 
    SELECT @Score = AVG(
        ( 
          (CAST(skills_verified AS INT) + CAST(experience_verified AS INT) + CAST(portfolio_verified AS INT)) 
          / 3.0 * 70 
        ) 
        + 
        (CASE WHEN review_status = 'recommended' THEN 30.0 ELSE 0.0 END)
    )
    FROM dbo.tbl_Vetting_Reviews
    WHERE engineer_id = @EngineerId;

    -- Cap at 100 if it exceeds for any reason
    IF @Score > 100.00 SET @Score = 100.00;
    
    RETURN ISNULL(@Score, 0.00);
END
GO

-- 2. Get Final Vetting Status
-- Determines if an engineer is 'approved', 'rejected', or 'pending'.
CREATE FUNCTION dbo.fn_GetFinalVettingStatus (@EngineerId INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    -- 1. If no reviews -> 'pending'
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Vetting_Reviews WHERE engineer_id = @EngineerId)
        RETURN 'pending';

    -- 2. If any review has "not_recommended" or "rejected" -> 'rejected' (Hard Reject Rule)
    IF EXISTS (SELECT 1 FROM dbo.tbl_Vetting_Reviews 
               WHERE engineer_id = @EngineerId 
               AND (review_status = 'not_recommended' OR review_status = 'rejected'))
        RETURN 'rejected';

    -- 3. Check the score using the function
    DECLARE @Score DECIMAL(5,2);
    SET @Score = dbo.fn_ComputeVettingScore(@EngineerId);

    -- 4. If score >= 70 -> 'approved' 
    IF @Score >= 70.00
        RETURN 'approved';

    -- 5. Else 'pending' (insufficient evidence)
    RETURN 'pending';
END
GO

-----------------------------
-- 6. VIEWS (Admin Vetting Views)
-----------------------------

-- vw_VettingQueue
-- Shows Admins a prioritized list of engineers needing review.
CREATE VIEW dbo.vw_VettingQueue
AS
SELECT 
    p.engineer_id,
    u.full_name AS engineer_name,
    u.email,
    p.vet_status AS current_vet_status,
    
    -- Call our function to get the live score
    dbo.fn_ComputeVettingScore(p.engineer_id) AS vetting_score,
    
    -- Aggregate data from reviews
    COUNT(r.review_id) AS num_reviews,
    MAX(r.submitted_at) AS last_review_date,
    
    -- Priority Logic
    CASE 
        WHEN p.vet_status = 'pending' AND COUNT(r.review_id) = 0 THEN 'High'
        WHEN p.vet_status = 'pending' THEN 'Medium'
        ELSE 'Low'
    END AS priority_level

FROM dbo.tbl_Engineer_Profile p
JOIN dbo.tbl_User u ON p.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Vetting_Reviews r ON p.engineer_id = r.engineer_id

GROUP BY 
    p.engineer_id, 
    u.full_name, 
    u.email, 
    p.vet_status;
GO

-----------------------------
-- 7. STORED PROCEDURES (Vetting Pipeline)
-----------------------------

-- 1. Finalise Vetting Decision
-- Updates the engineer's profile based on the calculated status.
CREATE PROCEDURE dbo.sp_FinaliseVettingDecision
(
    @EngineerId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate Engineer exists
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile WHERE engineer_id = @EngineerId)
    BEGIN
        PRINT 'Engineer not found.';
        RETURN;
    END

    -- Call our Function to get the calculated status
    DECLARE @NewStatus NVARCHAR(20);
    SET @NewStatus = dbo.fn_GetFinalVettingStatus(@EngineerId);

    -- Update the Engineer Profile
    UPDATE dbo.tbl_Engineer_Profile
    SET vet_status = @NewStatus,
        updated_at = SYSDATETIME()
    WHERE engineer_id = @EngineerId;

    -- Optional: If REJECTED, mark pending applications as rejected too.
    IF @NewStatus = 'rejected'
    BEGIN
        UPDATE dbo.tbl_Job_Application
        SET status = 'rejected',
            updated_at = SYSDATETIME()
        WHERE engineer_id = @EngineerId AND status = 'pending';
    END
END
GO

-- 2. Create Vetting Review
-- Allows an Admin to submit a review and auto-triggers a status update.
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

    -- Validation: Engineer must exist
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Engineer_Profile WHERE engineer_id = @EngineerId)
    BEGIN
        RAISERROR ('Engineer ID does not exist.', 16, 1);
        RETURN;
    END

    -- Validation: Reviewer must be an ADMIN
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_User WHERE user_id = @ReviewerId AND role = 'admin')
    BEGIN
        RAISERROR ('Reviewer must be an existing Admin.', 16, 1);
        RETURN;
    END

    -- Insert the Review
    INSERT INTO dbo.tbl_Vetting_Reviews
    (
        engineer_id, 
        reviewed_by, 
        review_status, 
        skills_verified, 
        experience_verified, 
        portfolio_verified, 
        review_notes, 
        rejection_reason,
        submitted_at
    )
    VALUES
    (
        @EngineerId, 
        @ReviewerId, 
        @ReviewStatus, 
        @SkillsVerified, 
        @ExperienceVerified, 
        @PortfolioVerified, 
        @ReviewNotes, 
        @RejectionReason,
        SYSDATETIME()
    );

    -- Trigger the status update immediately
    EXEC dbo.sp_FinaliseVettingDecision @EngineerId;

    -- Return success
    SELECT 'Review Submitted Successfully' AS Status;
END
GO

-----------------------------
-- 8. TRIGGERS (Soft Delete & Vetting Updates)
-----------------------------

-- 1. Auto-Update Vetting Status Trigger
-- Ensures profile status is updated whenever a review is added.
CREATE TRIGGER trg_VettingReviews_AfterInsert
ON dbo.tbl_Vetting_Reviews
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EngId INT;
    DECLARE cur_InsertedEngineers CURSOR FOR
        SELECT DISTINCT engineer_id FROM INSERTED;

    OPEN cur_InsertedEngineers;
    FETCH NEXT FROM cur_InsertedEngineers INTO @EngId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.sp_FinaliseVettingDecision @EngId;
        FETCH NEXT FROM cur_InsertedEngineers INTO @EngId;
    END

    CLOSE cur_InsertedEngineers;
    DEALLOCATE cur_InsertedEngineers;
END
GO

-- 2. Soft Delete Trigger (Archive instead of Delete)
-- Intercepts DELETE commands and moves data to Archive table instead.
CREATE TRIGGER trg_EngineerProfile_InsteadOfDelete
ON dbo.tbl_Engineer_Profile
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Archive the data
    INSERT INTO dbo.tbl_Engineer_Archive
    (
        engineer_id,
        full_name,
        email,
        years_experience,
        location,
        availability,
        vet_status,
        portfolio_link,
        reason
    )
    SELECT 
        d.engineer_id,
        u.full_name,
        u.email,
        d.years_experience,
        d.location,
        d.availability,
        d.vet_status,
        d.portfolio_link,
        'Soft deleted via INSTEAD OF trigger'
    FROM DELETED d
    JOIN dbo.tbl_User u ON d.engineer_id = u.user_id;

    -- Optional: Mark their applications as rejected
    UPDATE dbo.tbl_Job_Application
    SET status = 'rejected',
        updated_at = SYSDATETIME()
    WHERE engineer_id IN (SELECT engineer_id FROM DELETED)
      AND status IN ('pending', 'shortlisted');

    -- NOTE: We do NOT run the actual DELETE statement. 
    -- The record remains in tbl_Engineer_Profile as per project requirements ("Do not actually delete").
END
GO

-----------------------------
-- INDEX SUGGESTIONS (For Master Script)
-----------------------------
-- 1. Support fast lookups of reviews by engineer
-- CREATE INDEX IX_Vetting_Reviews_Engineer
-- ON dbo.tbl_Vetting_Reviews (engineer_id, submitted_at DESC);

-- 2. Support filtering engineers by status
-- CREATE INDEX IX_Engineer_Profile_VetStatus
-- ON dbo.tbl_Engineer_Profile (vet_status);